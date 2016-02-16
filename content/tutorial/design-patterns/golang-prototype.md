+++
Description = ""
comments = "yes"
date = "2016-02-06T16:01:29Z"
share = "yes"
title = "Design Patterns in Golang: Prototype"
categories = ["programming languages", "design patterns"]
tags = ["go", "prototype", "creational design patterns"]

+++

#### Preface

`The Prototype Pattern` creates duplicate objects while keeping performance
in mind. It's a part of the creational patterns and provides one of the best
ways to create an object.

In the mainstream languages (like C# and JAVA), it requires implementing a
prototype interface which tells to create a clone of the current object. It is
used when creation of object directly is costly.

For instance, an object is to be created after a costly database operation. We
can cache the object, returns its clone on next request and update the database
as and when needed thus reducing database calls.

#### Purpose

- Specify the kind of objects to create using a prototypical instance, and
	create new objects by copying this prototype.

#### Desing Pattern Diagram

{{< figure src="/media/golang/design-patterns/prototype.gif" alt="Prototype Class Diagram" >}}

- `Prototype` declares an interface for cloning itself
- `ConcretePrototype` implements an operation for cloning itself
- `Client` creates a new object by asking a prototype to clone itself

#### Implementation

In Golang, the pattern is applicable only in situation that we want to
customize how the object is cloned. We will explore two examples regarding
both situations.

Lets build a system that generates a different configuration files depending on
our needs. In first place, we have a struct `Config` that looks like:

```Golang
package configurer

// Config provides a configuration of microservice
type Config struct {
	workDir string
	user    string
}

// NewConfig create a new config
func NewConfig(user string, workDir string) Config {
	return Config{
		user:    user,
		workDir: workDir,
	}
}

// WithWorkDir creates a copy of Config with the provided working directory
func (c Config) WithWorkDir(dir string) Config {
	c.workDir = dir
	return c
}

// WithUser creates a copy of Config with the provided user
func (c Config) WithUser(user string) Config {
	c.user = user
	return c
}
```

We want to be able to mutate the object without affecting its initial instance.
The goal is to be able to generate different configuration files without loosing
the flexibility of customizing them without mutation of the initial default
configuration.

As you can see the functions `WithWorkDir`, `WithUserID` and `WithGroupID` are
declared for the struct `Config` (not for `*Config`). At the time, when they are
called the object is copied by the `Golang` runtime. This allows us to modify it
without affecting the original object.

Lets see it's usage in action:

```Golang
config := configurer.NewConfig(10, 10, "/home/guest")
rootConfig := config.WithUserID(0).WithGroupID(0).WithWorkDir("/root")

fmt.Println("Guest Config", config)
fmt.Println("Root Config", rootConfig)
```

Now lets explore the classic implementation of `The Prototype Design Pattern`.
We will assume that we are developing again document object model for a custom
document format. The core object is an `Element` structure which has parent and
children.

```Golang
// Element represents an element in document object model
type Element struct {
	text     string
	parent   *Element
	children []*Element
}

// NewElement makes a new element
func NewElement(text string) *Element {
	return &Element{
		text:     text,
		parent:   nil,
		children: make([]*Element, 0),
	}
}

// String returns string representation of element
func (e *Element) String() string {
	buffer := bytes.NewBufferString(e.text)

	for _, c := range e.children {
		text := c.String()
		fmt.Fprintf(buffer, "\n %s", text)
	}

	return buffer.String()
}

// Add adds child to the root
func (e *Element) Add(child *Element) {
	copy := child.Clone()
	copy.parent = e
	e.children = append(e.children, copy)
}

// Clone makes a copy of particular element. Note that the element becomes a
// root of new orphan tree
func (e *Element) Clone() *Element {
	copy := &Element{
		text:     e.text,
		parent:   nil,
		children: make([]*Element, 0),
	}
	for _, child := range e.children {
		copy.Add(child)
	}
	return copy
}
```

We want to extract a particular subtree of concrete element hierary. We want to
use it as independent document object model. In order to do that, we should use
the clone function:

```Golang
directorNode := dom.NewElement("Director of Engineering")

engManagerNode := dom.NewElement("Engineering Manager")
engManagerNode.Add(dom.NewElement("Lead Software Engineer"))

directorNode.Add(engManagerNode)
directorNode.Add(engManagerNode)

officeManagerNode := dom.NewElement("Office Manager")
directorNode.Add(officeManagerNode)

fmt.Println("")
fmt.Println("# Company Hierarchy")
fmt.Print(directorNode)
fmt.Println("")
fmt.Println("# Team Hiearachy")
fmt.Print(engManagerNode.Clone())
```

The sample above creates a tree from the subtree pointed by `engManagerNode`
variable.

#### Verdict

One of the disadvantages of this pattern is that the process of copying an object
can be complicated. In addition, structs that have circular references to other
classes are difficult to clone. Its overuse could affect performance, as the
prototype object itself would need to be instantiated if you use a registry of
prototypes.

In the context of `Golang`, I don't see any particular reason to adopt it.
`Golang` already provides builtin mechanism for cloning objects.

