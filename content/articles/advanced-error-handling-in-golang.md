+++
title = "Advanced Error Handling in Golang"
date = 2017-09-25T16:28:10+01:00
description = ""
comments = "yes"
share = "yes"
categories = ["programming languages"]
tags = ["go"]
+++

If you have ever written any Golang code you have probably noticed the built-in
error type interface. Golang uses error values to indicate an abnormal state.
The error type represents any value that can describe itself as a string. Here
is the interface's declaration:

```golang
type error interface {
    Error() string
}
```

The most commonly-used error implementation is the errors package's
implementation that allows you to instantiate errors by using the following
code snippet:

```golang
err: = errors.New("http: operation is not allowed")
```

However, the error handling is so simplified that does not provide us with
information about where the error occurred in the source code. This can cause
some difficulties in tracing errors in your application log.  Also, there are
some particular situations that you have multiple errors that you want to
correlate with particular operation step.

We can still have all that by just adopting a few Golang third-party packages
in our application.

### Stack tracing errors with status codes

The [errorx](github.com/goware/errorx) is a package that provides an error
interface implementation inspired by [PostgreSQL
styleguide](http://www.postgresql.org/docs/devel/static/error-style-guide.html). 

By installing it with the following command:

```bash
$ go get github.com/goware/errorx
```

It provides us with stack trace, error codes and nesting of errors:

```golang
if err := step(); err != nil {
  errx := errorx.New(http.StatusInternalServerError, "Operation failed")
  errx.Wrap(err)
}
```

### Handling multiple errors

The [go-multierror](https://github.com/hashicorp/go-multierror) is a package
for Go that provides a mechanism for representing a list of error values as a
single error.

Let's first install it:

```bash
$ go get github.com/hashicorp/go-multierror
```

Then we can use it in the following way:

```golang
var result error

if err := step1(); err != nil {
    result = multierror.Append(result, err)
}
if err := step2(); err != nil {
    result = multierror.Append(result, err)
}

return result
```
