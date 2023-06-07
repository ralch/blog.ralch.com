+++
Description = ""
comments = "yes"
date = "2015-10-18T05:00:00+01:00"
share = "yes"
title = "Generics in Golang"
categories = ["programming languages", "tutorial"]
tags = ["go", "generics", "code generation"]
+++

In the article we will take the advantage of [generics] even that they are not
first citizen in `Go`. We will explore [gen](http://clipperhouse.github.io/gen) and
[genny](https://github.com/cheekybits/genny) command line tools.

### Gen

`Gen` is a code generation tool that brings some generic query functions. It uses
annotations to add this functionality to any structure. The generated code is
part of your package and does not have any external dependencies. This approach
avoids any reflection and produces an efficient concrete implementation for any
annotated type.

By default the package generates various query functions. They can be used to
project, filter, sort and group slices of the annotated types.

#### Installation

We should use `go get` command to install `gen`:

```
$ go get clipperhouse.github.io/gen
```

#### Usage

As any other `Go` generation tool, `Gen` requires a specific annoation comment
declared before the desired type declaration.

```
// +gen [*] tag:"Value, Value[T,T]" anothertag
type AnnotatedType
```

It begins with the `+gen` directive. Optionally it is followed by a `[*]`,
indicating that the generated type should be a pointer. Tags and values are
interpreted by the available type writers. They are responsible for the actual
code generation. We will learn more about them in the next section. For now we
will use the default slice type writer.

Lets use it to generate functions for filtering, distincting, sorting and projecting
a `Company` struct:

```
// filename: company.go
package company

// +gen slice:"Where,GroupBy[string],DistinctBy,SortBy,Select[string]"
type Company struct {
	Name    string
	Country string
	City    string
}
```

After declaring the type annoation, we should execute `gen`:

```
$ gen
```

It produces `comapany_slice.go` file that contains the concrete implementation
for any listed function in the comment.

Lets use the generated functions with the following slice:

```
companies := company.CompanySlice{
	company.Company{Name: "Microsoft", Country: "USA", City: "Redmond"},
	company.Company{Name: "Google", Country: "USA", City: "Palo Alto"},
	company.Company{Name: "Facebook", Country: "USA", City: "Palo Alto"},
	company.Company{Name: "Uber", Country: "USA", City: "San Francisco"},
	company.Company{Name: "Tweeter", Country: "USA", City: "San Francisco"},
	company.Company{Name: "SoundCloud", Country: "Germany", City: "Berlin"},
}
```

Lets get all companies that are based on USA. For that you should use the `Where`
function, which receives predicate function as an argument.

The clojure function receives a company object as argument and returns
boolean value. It is executed for every item in the slice. It should retun
`true` for all objects that meets our criteria:

```
allUSCompanies := companies.Where(func(comp company.Company) bool {
	return comp.Country == "USA"
})
```

If we distinct all companies by their country of origin, we should use the
`DistinctBy` function that uses a function that checks two company objects
for equaty:

```
uniqueCompanies := companies.DistinctBy(func(compA company.Company, compB company.Company) bool {
	return compA.Country == compB.Country
})
```

If we want to sort the companies by their name, we should use `SortBy` function
that receives as an argument a function that determines whether its first argument
is less that second one:

```
// In our case we can use strings.Compare to compare to strings. It returns -1
// the first string is less than the second.
sortedCompanies := companies.SortBy(func(compA company.Company, compB company.Company) bool {
	return strings.Compare(compA.Name, compB.Name) == -1
})
```

If we want to group the companies by their country of residence, we can use
`GroupByString` function that returns a `map[string]company.CompanySlice` object.
The key of every entry is determined by its clojure function.

```
groupedCompanies := companies.GroupByString(func(comp company.Company) string {
	return comp.Country
})

fmt.Println("US Companies: ", groupedCompanies["USA"])
fmt.Println("German Companies: ", groupedCompanies["Germany"])
```

The company slice can be projected as a string by using generated `Select`
function. The following code snippet projects the list of companies as a list
of company names:

```
companyNames := companies.SelectString(func(comp company.Company) string {
	return comp.Name
})

fmt.Println(companyNames)
```

```
// This slice of strings is produced by the code snippet
[Microsoft Google Facebook Uber Tweeter SoundCloud]
```

A great `Gen` feature is that most of the functions can be chained. Lets select
all companies based in USA then order them by their name and format their name
in the following format:

```
%COMPANY_NAME% is based in %CITY%
```

We can simply chain `Where`, `SortBy` and `SelectString` functions:

```
result := companies.Where(func(comp company.Company) bool {
	return comp.Country == "USA"
}).SortBy(func(compA company.Company, compB company.Company) bool {
	return strings.Compare(compA.Name, compB.Name) == -1
}).SelectString(func(comp company.Company) string {
	return fmt.Sprintf("%s's is based in %s", comp.Name, comp.City)
})

for _, text := range result {
	fmt.Println(text)
}
```

You can read more about another auxiliary function in the [official documentation](http://clipperhouse.github.io/gen/slice/).

#### Implementing a type writer

The type writers are responsible for interpreting the annotated tags and
generating go code. They are implementing the following interface:

```
type Interface interface {
	Name() string
	Imports(t Type) []ImportSpec
	Write(w io.Writer, t Type) error
}
```

- `Name` returns the writer's name
- `Imports` function returns a slice of packages that are required and written
  as imports in the generated file
- `Write` function writes the actual generated code

Lets implement a writer that generates the `Stack` data structure. `Gen` uses
[text/template](https://golang.org/pkg/text/template/) as a templating format.

```
// A structure that represents a stack data structure
// for {{.Name}} type
//
// Example:
// stack := &stack.Stack{}
// stack.Push(new(TValue))
// value, err := stack.Pop()
type {{.Name}}Stack struct {
	data []{{.Pointer}}{{.Name}}
}

// Adds an element on top of the stack
func (s *{{.Name}}Stack) Push(value {{.Pointer}}{{.Name}}) {
	s.data = append(s.data, value)
}

// Removes an element from top of the stack.
// If the stack is empty, it returns an error.
func (s *{{.Name}}Stack) Pop() ({{.Pointer}}{{.Name}}, error) {
	length := len(s.data)
	if length == 0 {
		return nil, errors.New("Stack is empty")
	}

	value := s.data[length-1]
	s.data = s.data[:length-1]
	return value, nil
}
```

The template declared by `typewriter.Template` instance. The `templateContent`
variable contains the actual `text/template` string:

```
// filename: templates.go
package stack

import "github.com/clipperhouse/typewriter"

var templates = typewriter.TemplateSlice{
	stackTmpl,
}

var stackTmpl = &typewriter.Template{
	Name: "Stack",
	Text: templateContent,
}
```

The following structure implements a type writer responsible for code generation
of declared template:

```
// filename: stack.go
package stack

import (
	"io"

	"github.com/clipperhouse/typewriter"
)

func init() {
	if err := typewriter.Register(NewWriter()); err != nil {
		panic(err)
	}
}

type writer struct{}

// Creates a new stack type writer
func NewWriter() typewriter.Interface {
	return &writer{}
}

func (tw *writer) Name() string {
	return "stack"
}

func (tw *writer) Imports(t typewriter.Type) (result []typewriter.ImportSpec) {
	return
}

func (tw *writer) Write(w io.Writer, t typewriter.Type) error {
  // retrieve that for this type writer a tag is declared in the annoation
	// if it's not found the writer won't be generate anything
	tag, found := t.FindTag(tw)

	if !found {
		return nil
	}

  // Write a header commend in the generated file
	header := "// DO NOT MODIFY. Auto-generated code."
	if _, err := w.Write([]byte(header)); err != nil {
		return err
	}

	// A template for the exact tag is retrieved
	tmpl, err := templates.ByTag(t, tag)
	if err != nil {
		return err
	}

  // Write out the template substitution to the writer
	if err := tmpl.Execute(w, t); err != nil {
		return err
	}
	return nil
}
```

In ored to use the template we should declare annotation. Lets annotate
`company.Company` struct:

```
// +gen * stack
type Company struct {
	Name    string
	Country string
	City    string
}
```

After executing `$ gen` command a `company_stack.go` file is placed in the package
directory. It contains an actual implementation of `CompanyStack` structure,
which can be used in the following way:

```
stack := &StudentStack{}
stack.Push(&Student{FirstName: "John", LastName: "Smith"})
student, err := stack.Pop()
```

A complete implementation of the custom type writer can be pulled from
[this repository](https://github.com/iamralch/gen).

### Genny

`Genny` is a code-generation tool that replaces usage of generics. It allows
to transform a Go source code into specific implementation by replacing its
generic types.

#### Installation

Install by executing `go get`:

```
$ go get github.com/cheekybits/genny
```

#### Usage

The tool uses a similar approach as `gotemplate`. A special comment should be
provided in order to be recognised by `go generate`:

```
//go:generate genny -in=$GOFILE -out=gen-$GOFILE gen "KeyType=string,int ValueType=string,int"
```

Parameters:

- `-in` specifies the input file (template)
- `-out` specifies the output file
- `$GOFILE` refers to the current file
- `KeyType` and `ValueType` are the parameter names in the specified template

As the other tools, we should just call `go generate` to produce a file that is
result of substition between the template and provided parameters.

### Declaring generics

The template can contains as many as we require parameters. They should be defined
using the special genny type `generic.Type`:

```
type KeyType generic.Type
type ValueType generic.Type
```

Lets port the `Stack` data struct in `genny`:

```
//go:generate genny -in=$GOFILE -out=gen-$GOFILE gen "ValueType=*Student"
type ValueType generic.Type

type Stack struct {
	data []ValueType
}

func (s *Stack) Push(value TValueType) {
	s.data = append(s.data, value)
}

func (s *Stack) Pop() (TValueType, error) {
	length := len(s.data)
	if length == 0 {
		return nil, errors.New("Stack is empty")
	}

	value := s.data[length-1]
	s.data = s.data[:length-1]
	return value, nil
}
```

Significant difference from `gotemplate` is that in `genny` the special `go:generate`
comment should be placed in the actual template. This can be avoid by executing
`genny` from the command line shell:

```
$ cat ./stack.go | genny gen "ValueType=*Student" > student_stack.go
```

### Conclusion

Do you still complain that `Go` does not support generics?

`Gen` and `genny` are great tools for automating a common development tasks. Because of their
template nature, we can focus on what should be generated instead of how to generate it.
