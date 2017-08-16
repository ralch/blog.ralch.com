+++
comments = "yes"
date = "2015-08-30T12:41:34+01:00"
share = "yes"
title = "Golang refactoring tools"
Description = ""
tags = ["go"]
categories = ["programming languages", "tutorial", "tools"]

+++

[Go](https://golang.org) language provides many useful tools as part of its 
development eco system. We will explore most of them in the upcoming blog posts.
But in the article lets focus on refactoring tools. 

## Gofmt

In average programming languages developers can adapt to different formatting 
styles. Common problem is how to approach unknown code base without a long 
prescriptive style guide.

Go takes an unusual approach and keep this responsibility to format the source code
for you. The `gofmt` program (available as `go fmt`, which examines
on the package level rather than source file level) reads a Go syntax and reformat
your program in a standard coding style. In addition, it provides some additional
refactoring capabilities, which will explore in detail.

```
// The -w flag overwrites the files instead of prints out the result on the screen
$ gofmt -w message.go
```

It formats the following code snippet:

```
// filename: message.go
package message
import "fmt"
func FormatMessage(name string) string{
if len(name) == 0 { return "Welcome" } else { return fmt.Sprintf("Hi, %s", name) }
}
```

Output:

```
// filename: message.go
package message

import "fmt"

func FormatMessage(name string) string {
	if len(name) == 0 {
		return "Welcome"
	} else {
		return fmt.Sprintf("Hi, %s", name)
	}
}
```

*Note that `gofmt` uses tabs for indentation and
blanks for alignment.*

The code is reformatted to obey all `Go` coding style standards. It does not rename
any variables and functions. There is a tool that do static analyses on your code. 
We will talk about it in one of the next articles.

These are the flags supported by `gofmt`:

- `-d` prints diffs to standard out when file formatting is changed
- `-e` print all errors
- `-l` prints the filename to standard out when file formatting is changed
- `-r` applies the rewrite rule to the source before reformatting.
- `-s` simplifies code 
- `-w` overwrites file with its formatted version

In the next two paragraphs we will explore how to simplify and apply rewrites rules
to a source code.

Simplifing source code is applied when `-s` flag is presented. It improves the
code readability by replacing blocks of code with their sipliefied syntax version.

Executing `go fmt -s -w transport.go`:

```
// filename: transport.go
package transport

import "fmt"

type Endpoint struct {
	Protocol string
	Host     string
	Port     int
}

var endpoints []Endpoint = []Endpoint{
	Endpoint{
		Protocol: "HTTP",
		Host:     "localhost",
		Port:     80},
	Endpoint{
		Protocol: "SSH",
		Host:     "10.10.5.9.xip.io",
		Port:     22}}

func ListEndpoints(startIndex int) {
	for index, _ := range endpoints[startIndex:len(endpoints)] {
		endpoint := endpoints[index]
		fmt.Printf("Priority: %d Procotol: %s Address: %s:%d\n",
			index, endpoint.Protocol, endpoint.Host, endpoint.Port)
	}
}
```

The package will be simplified to: 

```
// filename: transport.go
package transport

import "fmt"

type Endpoint struct {
	Protocol string
	Host     string
	Port     int
}

var endpoints []Endpoint = []Endpoint{
	{Protocol: "HTTP",
		Host: "localhost",
		Port: 80},
	{Protocol: "SSH",
		Host: "10.10.5.9.xip.io",
		Port: 22}}

func ListEndpoints(startIndex int) {
	for index := range endpoints[startIndex:] {
		endpoint := endpoints[index]
		fmt.Printf("Priority: %d Procotol: %s Address: %s:%d\n",
			index, endpoint.Protocol, endpoint.Host, endpoint.Port)
	}
}
```

These are the applied rules:

- An array, slice, or map composite literal of the form `[]T{T{}, T{}}`
will be simplified to `[]T{{}, {}}`.
- A slice expression of the form `s[a:len(s)]` will be simplified to `s[a:]`.
- A range of the form `for x, _ = range v {...}` will be simplified to `for x = range v {...}`.
- A range of the form `for _ = range v {...}` will be simplified to `for range v {...}`.

To define specified rewrite rule the `-r` flag must be used. It should be in
the following format:

```
pattern -> replacement
```

Both pattern and replacement must be valid `Go` expressions. The pattern serves 
as wildcards matching arbitrary sub-expressions. They will be substituted for 
the same identifiers in the replacement.

Lets rename `Endpoint` struct to `Server` in `transport` package:

```
$ gofmt -r 'Endpoint -> Server' -w transport.go
$ gofmt -r 'endpoints -> servers' -w transport.go
$ gofmt -r 'ListEndpoints -> ListServers' -w transport.go
```

The result of this operation:

```
// filename: transport.go
package transport

import "fmt"

type Server struct {
	Protocol string
	Host     string
	Port     int
}

var servers []Server = []Server{
	{Protocol: "HTTP",
		Host: "localhost",
		Port: 80},
	{Protocol: "SSH",
		Host: "10.10.5.9.xip.io",
		Port: 22}}

func ListServers(startIndex int) {
	for index := range servers[startIndex:] {
		endpoint := servers[index]
		fmt.Printf("Priority: %d Procotol: %s Address: %s:%d\n",
			index, endpoint.Protocol, endpoint.Host, endpoint.Port)
	}
}
```

## Gorename

The `gorename` is another tool for code refactoring. It command performs precise 
type-safe renaming of identifiers in Go source code. It is installed with 
the following command:

```
$ go get golang.org/x/tools/refactor/rename
```

Lets use the tool with the following code snippet:

```
// package: university
package main

import "fmt"

type Student struct {
	Firstname string
	Surename  string
}

func (s *Student) Fullname() string {
	return fmt.Sprintf("%s %s", s.Firstname, s.Surename)
}

func main() {
	students := []Student{
		{Firstname: "John",
			Surename: "Freeman"},
		{Firstname: "Jack",
			Surename: "Numan"},
	}

	for _, s := range students {
		fmt.Println(s.Fullname())
	}
}
```

Renaming `Fullname` function of `Student` struct to `String` can be done by
executing `gorename`:

```
$ gorename -from '"university".Student.Fullname' -to String
```

The `-from` flag must obey the following format specifies the object to rename 
using a query notation like that:

```
"encoding/json".Decoder.Decode        method of package-level named type
(*"encoding/json".Decoder).Decode     ditto, alternative syntax
"encoding/json".Decoder.buf           field of package-level named struct type
"encoding/json".HTMLEscape            package member (const, func, var, type)
"encoding/json".Decoder.Decode::x     local object x within a method
"encoding/json".HTMLEscape::x         local object x within a function
"encoding/json"::x                    object x anywhere within a package
json.go::x                            object x within file json.go
```

The `-to` flag defines the new name of the object.

## Eg 

The `Eg` command is a tool that implements example-based refactoring of expressions.
The transformation is specified as a Go file defining two functions,
`before` and `after` of identical types. The parameters of both functions are 
wildcards that may match any expression assignable to that type:

```
package P
import ( "errors"; "fmt" )
// specifies a match pattern like:
func before(s string) error { return fmt.Errorf("%s", s) }
// specifies its replacement like:
func after(s string)  error { return errors.New(s) }
```

The tool analyses all Go code in the packages specified by the
arguments, replacing all occurrences of the pattern with the
substitution.

Lets apply the below example to `university` package:

```
// filename: stringfix.go
package P

import "fmt"

// specifies a match pattern like:
func before(x, y string) string { return fmt.Sprintf("%s %s", x, y) }

// specifies its replacement like:
func after(x, y string) string { return x + " " + y }
```

To do that we should execute `eg` command:

```
// -t specifies the template file
// -w specifies that the matched files must be overwritten
$ eg -t stringfix.go -w  -- university
```

The tool changes the implementation of `String` function of `Student` package:

```
// package: university
// struct: Student
// filename: main.go
func (s *Student) Fullname() string {
	return s.Firstname + " " + s.Surename
}
```

## Conclusion

As part of our job is not only to develop new features, but also improve
existing code base. `Gofmt`, `gorename` and `eg` are tools that can help to 
boost the productivity and keep source code in well formatted shape 
that fits the `Go` coding style standard.

