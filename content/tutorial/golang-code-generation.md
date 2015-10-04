+++
Description = ""
comments = "yes"
date = "2015-10-4T08:49:59+01:00"
share = "yes"
title = "Golang code generation"
categories = ["programming languages", "tutorial"]
tags = ["go", "code generation"]

+++

Programs that produce source code are important elements in software engineering.
Since Go 1.4, the language ecosystem includes a command line tool that makes 
it easier to run such tools.

It's called `go generate`. It scans for special comments in Go 
source code that identify general commands to run:

```
//go:generate <subcommand> <arguments> 
```

`Go generate` is not part of go build. It does not do dependency analysis and 
must be run explicitly before running go build. It is intended to be used by 
the author of the Go package, not its consumers.

The `go generate` command is easy to use. Usually it is executed in the following way:

```
// it scans all 
$ go generate ./...
```

After identifying all `go:generate` comments it will execute the specified commands.

In this article, we will explore a various tools that produce source code for us.



### JSON Enums

Have you ever had an enum that you want to serialize in JSON as a string instead of integer?
Are you bored of developing a `switch` cases that handle that? It is time to automate this
task by using `jsonenums`.

[jsonenums](http://github.com/campoy/jsonenums) is a code generation tool to automate the creation of methods 
that satisfy the [json.Marshaler](https://golang.org/pkg/encoding/json/#Marshaler) and [json.Unmarshaler](https://golang.org/pkg/encoding/json/#Unmarshaler) interfaces.

#### Installing

```
$ go get github.com/campoy/jsonenums
```

#### Usage

Lets have this enum definition:

``` 
//go:generate jsonenums -type=Status
type Status int

const (
	Pending Status = iota
	Sent
	Received
	Rejected
)
```

Running `go generate` produces `status_jsonenums.go` file in the same package.
It contains the actual implementation for JSON serialization of `Status` enum.
Then we can serialize an enum variable in the following way:

```
status := Received
data, err := status.MarshalJSON()
if err != nil {
	panic(err)
}

statusCopy := new(Status)
err = statusCopy.UnmarshalJSON(data)
if err != nil {
	panic(err)
}
```

You can download the whole code snippet from [here](https://gist.github.com/svett/0053bab033a581f7675a).

### Fast JSON

[ffjson](http://github.com/pquerna/ffjson)  generates `MarshalJSON` and `UnmarshalJSON` functions for struct types.
These functions reduce the reliance unpon runtime reflection to do serialization. 
According to the author notes, it is generally 2 to 3 times faster than 
`encoding/json` package.

#### Installing

```
$ go get github.com/pquerna/ffjson 
```

#### Usage

The generated code is baed upon existing struct types. Lets have `education.go` file.
`ffjson` will generate a new file `education_ffjson.go` that contains serialization 
functions for all structs found in `education.go`. In order to do that we should
add the following `go:generate` comment in `education.go`:

```
//go:generate ffjson $GOFILE
```

This is a sample version of `education.go`:

```
//go:generate ffjson $GOFILE
package education

type Student struct {
	FirstName string
	LastName  string
}

type University struct {
	Name     string
	Students []Student
}
```

Executing `go generate ./...` produces `education_ffjson.go` that contains all
json serialization code for `Student` and `University` structs. Then we can use
`ffjson` package to marshal these types and unmasrshal their `JSON` representation:

```
package main

import (
	"spike/education"

	"github.com/pquerna/ffjson/ffjson"
)

func main() {
	student := education.Student{
		FirstName: "John",
		LastName:  "Smith",
	}

	university := education.University{
		Name:     "MIT",
		Students: []education.Student{student},
	}

	json, err := ffjson.Marshal(&university)
	if err != nil {
		panic(err)
	}

	var universityCopy education.University
	err = ffjson.Unmarshal(json, &universityCopy)
	if err != nil {
		panic(err)
	}
}
```

The sample code can be downloaded from [here](https://gist.github.com/svett/053b3bd64612a8677389).

### Stringer

[Stringer](https://godoc.org/golang.org/x/tools/cmd/stringer) is a similar to `jsonenums`. 
But it generates a [fmt.Stringer interface](https://golang.org/pkg/fmt/#Stringer) implementation for enums.

#### Installing

```
$ go get golang.org/x/tools/cmd/stringer
```

#### Usage

Lets auto-generate `fmt.Stringer` interface for `MessageStatus` enum:

```
//go:generate stringer -type=MessageStatus
type MessageStatus int

const (
	Sent MessageStatus = iota
	Received
	Rejected
)
```

`Go generate` produces `messagestatus_string.go` file which contains the actual
implementation. Then the following snippet prints out `Message is Sent` instead
of `Message is 0`:

```
func main() {
	status := Sent
	fmt.Printf("Message is %s", status)
}
```

Full source code can be download from [here](https://gist.github.com/svett/b5194dfb109626579e77).

## Conclusion

`Go generate` is great opportunity to automate many implementation tasks
that are very common in our day to day job. I am really pleased to see more and 
more tools coming up.
