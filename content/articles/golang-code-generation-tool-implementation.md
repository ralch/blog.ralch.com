+++
Description = ""
comments = "yes"
date = "2015-10-31T08:41:39+01:00"
share = "yes"
title = "Develop code generation tool for Golang"
categories = ["programming languages", "tutorial", "tools"]
tags = ["go", "code generation"]
+++

In my previous blog post, we discussed one of my favourite code generation tools
for Go. We found that they can be used to automate our trivial development tasks
or even introduce features like generics and queries. Lets explore how to
create our own tool.

#### Introduction

The Go generate subcommand is a program that scans for special comments in your
Go source code. The comment declares a command that should be executed. The
tools is not part of Go build toolbelt. Usually it's used by packaged
developers.

This is the format of `go:generate` comments:

```
//go:generate <subcommand> <arguments>
```

After identifying all `go:generate` comments it will execute the specified
commands.

#### Implementation

We will build a command line tool that generates an implementation of
[io.WriterTo](https://golang.org/pkg/io/#WriterTo) interface for concrete type
and format.

Lets name the tool `wordsmith`. Note that in the sample we will use only `json`.

`io.WriterTo` provides a function that writes data to a writer. The return value
n is the number of bytes written. Any error encountered during the write is
also returned:

```
type WriterTo interface {
        WriteTo(w Writer) (n int64, err error)
}
```

Lets have a Point struct that is annotated with special `go:generate` comment:

```
type Point struct {
	X float64
	Y float64
}
```

If we implement the funcationality manually, we should end up with the following
code snippet:

```
func (obj Point) WriteTo(writer io.Writer) (int64, error) {
	data, err := json.Marshal(&obj)
	if err != nil {
		return 0, err
	}
	length, err := writer.Write(data)
	return int64(length), err
}
```

We can trainsform it into a `text/template` file:

```
package {{ .PackageName }}

import (
	"encoding/json"
	"io"
)

func ({{ .Object }} {{ .Type }}) WriteTo(writer io.Writer) (int64, error) {
  data, err := json.Marshal({{ .MarshalObject }})
  if err != nil {
  	return 0, err
  }
  length, err := writer.Write(data)
  return int64(length), err
}
```

The `wordsmith` generation tools is a command line application that has the
following arguments:

- `pointer` determines whether a type is a pointer
- `type` defines the name of the type that implements `io.WriterTo` interface
- `package` defines the package that contains this type
- `format` defines the serialization format that `io.WriterTo` is providing

The function initial reads the arguments, locates the package directory and
creates the output file in the following format `<type_name>_writer.go`.

```
func main() {
	typePointer := flag.Bool("pointer", false, "Determines whether a type is a pointer or not")
	typeName := flag.String("type", "", "Type that hosts io.WriterTo interface implementation")
	packageName := flag.String("package", "", "Package name")
	format := flag.String("format", "json", "Encoding format")

	flag.Parse()

	if *typeName == "" || *format != "json" {
		flag.Usage()
		return
	}

	pkgDir, err := packageDir(*packageName)
	if err != nil {
		panic(err)
	}

	outputFile := formatFileName(*typeName)
	writer, err := os.Create(filepath.Join(pkgDir, outputFile))
	if err != nil {
		panic(err)
	}
	defer writer.Close()

	generator := &Generator{Format: JSON}

	m := metadata(*typeName, *typePointer, pkgDir)
	if err := generator.Generate(writer, m); err != nil {
		panic(err)
	}

	fmt.Printf("Generated %s %s\n", *format, outputFile)
}
```

The `wordsmith.Generator` type is responsible to execute the text template and
generate the output file. It instaciates text template object from the template
file and substitute it with the `Metadata` object properties:

```
type Metadata struct {
	PackageName   string
	Object        string
	MarshalObject string
	Type          string
}

type Generator struct {
	Format Format
}

func (g *Generator) Generate(writer io.Writer, metadata Metadata) error {
	tmpl, err := g.template()
	if err != nil {
		return nil
	}

	return tmpl.Execute(writer, metadata)
}

func (g *Generator) template() (*template.Template, error) {
	if g.Format != JSON {
		return nil, errors.New("Unsupported format")
	}

	resource, err := Asset("templates/writeto_json.tmpl")
	if err != nil {
		return nil, err
	}

	tmpl := template.New("template")
	return tmpl.Parse(string(resource))
}
```

You can read more about text templates in [the official golang
documentation](https://golang.org/pkg/text/template/).

The `wordsmith` can be used from command line prompt or by annotating `Point`
struct with the following comment:

```
//go:generate wordsmith -type=Point -format=json
```

The following command identifies the `go:generate comment` and executes
declared `wordsmith` submcommand:

```
// it scans all
$ go generate ./...
```

You can use the download the full source code from [github](http://github.com/iamralch/wordsmith)
or install it immediatelly:

```
$ go get github.com/iamralch/wordsmith
```

#### Conclusion

I am looking forward to see more tools in the Go ecosystem. Hopefully this
blog post will encourage more go developers to build such a tools that will boost
our productivity.
