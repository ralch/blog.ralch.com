+++
Description = ""
comments = "yes"
date = "2015-08-16T08:40:35+01:00"
share = "yes"
title = "Conditional compilation in Golang"
tags = ["go", "clang", "preprocessor", "compilation"]
categories = ["programming languages", "tutorial"]
+++

When developing Go package or application that depends on specific features 
of the underlying platform or architecture it is often necessary 
to use a specialised implementation.

There are two parts of Go conditional compilation system, which we will now 
explore in more detail.

## Build constraints 

A build constraints (known as build tags) is an optional top line comment that 
starts with

```
// +build

package api 
```

The following rules are applied to build constraints:

1. Each tag is alphanumeric word
2. Tag preceded by `!` defines its negation.
3. A build constraint is evaluated as the OR of space-separated options.
4. Each option evaluates as the AND of its comma-separated terms.

That means if we have the following build constraint:

```
// +build linux,386 darwin,!cgo
```

It will be evaluated by the compilation system as:

```
(linux AND 386) OR (darwin AND (NOT cgo))
```

A file can have multiple build constraints:

```
// +build linux freebsd
// +build 386

package api
```

The evaluated constraint is a logical `AND` of the individual build tags:

```
(linux OR freebsd) AND 386
```

*Note that the build tag line should be associated with a trailing new line. That makes
it non-associated with any declaration. You can verify this by using `go vet` tool.*

## File suffixes

The second option for conditional compilation is the name of the 
source file itself. This approach is simpler than build tags, and allows 
the Go build system to exclude files without having to process the file.

We should add one of the following suffixes to desired files: 

```
*_GOOS // operation system
*_GOARCH // platform architecture
*_GOOS_GOARCH // both combined
```

These are all available architectures and operation system supported by Go
build system:

| GOOS      | GOARCH  |
|-----------|---------|
| darwin    | 386     |
| darwin    | amd64   |
| dragonfly | 386     |
| dragonfly | amd64   |
| freebsd   | 386     |
| freebsd   | amd64   |
| freebsd   | arm     |
| linux     | 386     |
| linux     | amd64   |
| linux     | arm     |
| netbsd    | 386     |
| netbsd    | amd64   |
| netbsd    | arm     |
| openbsd   | 386     |
| openbsd   | amd64   |
| plan9     | 386     |
| plan9     | amd64   |
| solaris   | amd64   |
| windows   | 386     |
| windows   | amd64   |

Examples for such a files:

```
container_windows.go // only builds on windows system
container_linux.go // only builds on linux system
container_freebsd_386.go // only builds on FreeBSD system with 386 architecture
```

If you want to exclude a file from compilation, you should use `ignore` build
constraint:

```
// +build ignore

package api
```

### Test files

Test files also support build constraints and file suffixes. They behave in the same 
manner as other Go source files. 

```
container_windows_test.go // windows specific container tests
container_linux_test.go // linux specific container tests
```

## Using C/C++ preprocessor in Go

Go does not have a preprocessor to control the inclusion of platform specific code. 
The C preprocessor is intended to be used only with C, C++, and Objective-C source code. 
We will use `cpp` macro processor as a general text processor of Go source code.

Lets have the following code snippet:

```
// filename: app.pgo
package main

import "fmt"
#ifdef PRINT_DATE
import "time"
#endif

func main() {
  fmt.Println("Application is executed.")
#ifdef PRINT_DATE
  fmt.Printf("Current Date: %s\n", time.Now().String())
#endif
}
```

If we execute the C preprocessor on `app.pgo` file:

```
cpp -P app.pgo app.go
```

We will produce a new file `app.go`:

```
// filename: app.go
package main

import "fmt"

func main() {
  fmt.Println("Application is executed.")
}
```

If we define `PRINT_DATE` variable for the preprocessor by using `-D` flag:

```
cpp -DPRINT_DATE -P app.pgo app.go
```

We will produce a new file `app.go` that has includes additional print statment:

```
// filename: app.go
package main

import "fmt"
import "time"

func main() {
  fmt.Println("Application is executed.")
  fmt.Printf("Current Date: %s\n", time.Now().String())
}
```

We can combine the preprocessor operation with go build step:

```
cpp -DPRINT_DATE -P app.pgo app.go | go build app.go
```

## Verdict

We should aim to develop and build our Go application by following all Go idioms.
If the source file targets a specific platform, we should choose file suffix 
approach. Otherwise, if the source file is applicable for multiple platforms and
we want to exclude a specific feature or platform, we should use build constraints instead.
