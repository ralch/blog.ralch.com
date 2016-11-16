+++
Description = ""
comments = "yes"
date = "2016-03-10T08:52:29Z"
share = "yes"
title = "Errors handling in Golang"
categories = ["programming languages", "tutorial"]
tags = ["go", "errors"]

+++

`Go` does not have an `Exception` handling model as most of the main stream
languages. However, it uses the error interface type as the return type for any
error that is going to be returned from a function or method:

```Golang
type error interface {
    Error() string
}
```

It is an interface type. An error variable represents any value
that can describe itself as a string. The most commonly-used error
implementation is in the [errors](https://golang.org/pkg/errors/) package.

It can be instaciated in the following way:

```Golang
func DivideBy(divider float64) (float64, error) {
    if divider <= 0 {
        return 0, errors.New("Divider cannot be zero or negative number.")
    }
    // implementation
}
```

The `errors.New` functions constructs an exported type `errorString` that
implements the `Error` interface:

```Golang
// Copyright 2011 The Go Authors.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package errors implements functions to manipulate errors.
package errors

// New returns an error that formats as the given text.
func New(text string) error {
	return &errorString{text}
}

// errorString is a trivial implementation of error.
type errorString struct {
	s string
}

func (e *errorString) Error() string {
	return e.s
}
```

It is pretty straighforward to implement your own error type that has additional
data.

The error model in `Golang` does not provide a way to find out, which function
returned the error. We should be aware and log the errors very carefully in
order to understand where this error occurred.

Fortunately, the `Golang` runtime provides a set of functions that we can use to
generate a stacktrace that we can trace down easily.

In the following paragraphs, we will explore the Planatir
[stacktrace](https://github.com/palantir/stacktrace) package that does this for
us.

### Getting Started

The package captures a strategic places along the call stack and attaches relevant
contextual information like messages and variables. It is keeping stack traces
compact and maximally useful.

### Installation

In order to use the package, we should install it first by using the well known
`go get` command:

```Bash
$ go get github.com/palantir/stacktrace
```

### Usage

The package provides a various functions to propagate and generate that
contextual information.

##### Error propagation

`stacktrace.Propagate` function replaces the usage of `fmt.Errorf` function. It
wraps an error to include line number information. This is going to be your
most common stacktrace call.

```Golang
db, err := sql.Open("postgres", conninfo)
if err != nil {
   return stacktrace.Propagate(err, "Failed to connect %v", conninfo)
}
```

#### Creating errors

`stacktrace.NewError` creates a new error that includes line number information:

```Golang
if amount <= 0 {
    return stacktrace.NewError("Expected amount %v to be positive number", arg)
}
```

##### Error Codes

Sometimes it's useful to propagate an error code while unwinding the
stack. For instance, a RESTful API may use the error code to set the HTTP status
code. The type `stacktrace.ErrorCode` is used to name the set of error codes
relevant to your application:

```Golang
const (
    ConnectionTimeout = stacktrace.ErrorCode(iota)
		ConnectionLost
)
```

The value `stacktrace.NoCode` is equal to `math.MaxUint16`, so avoid using
that. `NoCode` is the default value of errors that does not have explicitly set
error code.

You can use `stacktrace.PropagateWithCode` and `stacktrace.NewErrorWithCode` to
instaciated an error that has specific code:

```Golang
db, err := sql.Open("postgres", conninfo)
if err != nil {
   return stacktrace.PropagateWithCode(err, ConnectionTimeout, "Failed to connect %v", conninfo)
}
```

You can extract the error code from the error by using `stacktrace.GetCode`
function:

```Golang
data, err := fetch()
if err != nil {
  code := stacktrace.GetCode(err)
	if code == ConnectionTimeout {
	   return nil
	}
}
```

### Verdict

The `stacktrace` package is very pleasant and easy to use. It comforms the Golang
idiomatic way of handling errors and provides us with additional contextual information
about the file and the line where the error occurred.

