+++
Description = ""
comments = "yes"
date = "2015-10-11T20:42:57+01:00"
share = "yes"
title = "Reusing source code with Go templates"
categories = ["programming languages", "tutorial"]
tags = ["go", "code generation"]

+++

In one of my previous blog posts, we discovered `go generate` command line
tool. Lets take the next step and evaluate its advanced benefits to generate a source code 
by using our own templates. We will explore [gotemplate](https://github.com/ncw/gotemplate) 
command line tool.

### Overview

This command line tool manages package based `Go` templates using `go generate`.
By default it provides a set of templates that can be used out of the box:

- [set](http://godoc.org/github.com/ncw/gotemplate/set) - a template that generates a `set` struct for a type
- [list](http://godoc.org/github.com/ncw/gotemplate/list) - a template that generates a `list` struct for a type
- [sort](http://godoc.org/github.com/ncw/gotemplate/sort) - a template that provides a sort primitivies for a type
- [heap](http://godoc.org/github.com/ncw/gotemplate/heap) - a template that provides `heap` operations for a type

### Installation

It is simple to install by using `go get` command.
Note that the command installs the predefined templates as well.

```
$ go get github.com/ncw/gotemplate/...
```


### Usage

To instaciate a particular template, you must use it using a special comment in your code: 

```
//go:generate gotemplate "github.com/ncw/gotemplate/list" StudentList(Student)
type Student struct {
	FirstName string
	LastName  string
	BirthDate time.Time
}
```

Afte executing `go generate` command, a file [gotemplate_StudentList.go](https://gist.github.com/86acbeea21c02af69e70) 
is generated. It contains the `StudentList` type that defines a list struct
that works with `Student` type. It has the following methods and functions:

```
+StudentList : struct
  [methods]
  +Back() : *StudentListElement
  +Front(): *StudentListElement
  +Init() : *StudentList
  +InsertAfter(v Student, mark *StudentListElement) : *StudentListElement
  +InsertBefore(v Student, mark *StudentListElement) : *StudentListElement
  +Len() : int
  +MoveToBack(e *StudentListElement)
  +MoveToFront(e *StudentListElement)
  +PushBack(v Student) : *StudentListElement
  +PushBackList(other *StudentList)
  +PushFront(v Student) : *StudentListElement
  +PushFrontList(other *StudentList)
  +Remove(e *StudentListElement) : Student
  [functions]
  +NewStudentList() : *StudentList
```

You can use it in the following manner:

```
package main

import (
	"fmt"
	"spike/education"
)

func main() {
	student := education.Student{
		FirstName: "John",
		LastName:  "Smith",
	}

	list := education.NewStudentList()
	list.PushFront(student)

	fmt.Println(list.Front().Value.FirstName)
}
```

Using an initial capital when you name your template instantiation will make 
any external functions and types public. If you want to generate them as private
you must use lower case like:

```
//go:generate gotemplate "github.com/ncw/gotemplate/set" stringSet(string)
//go:generate gotemplate "github.com/ncw/gotemplate/set" floatSet(float64)
```

Then code generation produces `gotemplate_stringSet.go` and `gotemplate_floateSet.go` files.
```
$ go generate
substituting "github.com/ncw/gotemplate/set" with stringSet(string) into package main
Written 'gotemplate_stringSet.go'
substituting "github.com/ncw/gotemplate/set" with floatSet(float64) into package main
Written 'gotemplate_floatSet.go'
```

### Creating a custom templates

Templates must be valid go packages. They should compile and have tests and be usable as-is. 

To make the package a valid template it should have one or more declarations and 
a special comment that declares the its template name and parameters.

The line below indicates that the base name for the template is `TemplateType` 
and it has one type parameter `TParameter`. Supported parameterized declarations
are type, const, var and func.

```
// template type TemplateType(TParameter)
type TParameter int
```

Lets implement a template for [Stack data structure](http://bit.ly/1Pwvd5W).

```
package stack

import "errors"

// template type Stack(TValue)
type TValue *int

type Stack struct {
	data []TValue
}

func (s *Stack) Push(value TValue) {
	s.data = append(s.data, value)
}

func (s *Stack) Pop() (TValue, error) {
	length := len(s.data)
	if length == 0 {
		return nil, errors.New("Stack is empty")
	}

	value := s.data[length-1]
	s.data = s.data[:length-1]
	return value, nil
}
```

Lets declare it for `Student` struct:

```
//go:generate gotemplate "github.com/iamralch/gotemplate/stack" StudentStack(*Student)
type Student struct {
	FirstName string
	LastName  string
	BirthDate time.Time
}
```

Then you can instatiate:

```
$ go get github.com/iamralch/gotemplate/stack
$ go generate
```

When the template is instantiated, a new file `gotemplate_StudentStack.go` is create. 
It is a result of substition of actual template with `StudentStack(*Student)` declaration. 
All `TValue` occurances are replaced with `Student`. The `Stack` struct is changed to `StudentStack`.

The template can be downloaded from [here](https://github.com/iamralch/gotemplate/).

### Conclusion

`Gotemplate` is great tool for automatic a common development tasks. Because of its
extensibility, we can focus on what should be generated instead of how to generate it.



