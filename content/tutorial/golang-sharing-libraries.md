+++
Description = ""
comments = "yes"
date = "2015-08-23T11:04:50+01:00"
share = "yes"
title = "Sharing Golang packages in C and Go"
tags = ["go", "cgo", "c", "compilation"]
categories = ["programming languages", "tutorial"]

+++

The latest [Go 1.5](https://blog.golang.org/go1.5) version is out. As part of 
the [new features](https://golang.org/doc/go1.5), `Go compiler` can compile 
packages as a shared libraries. 

It accepts `-buildmode` argument that determines how a package is compiled. 
These are the following options:

- `archive`: Build the listed non-main packages into .a files. Packages named 
  main are ignored.
- `c-archive`: Build the listed main package, plus all packages it imports, 
  into a C archive file. 
- `c-shared`: Build the listed main packages, plus all packages that they import, 
  into C shared libraries.
- `shared`: Combine all the listed non-main packages into a single shared library.
- `exe`: Build the listed main packages and everything they import into executables. 
  Packages not named main are ignored.

By default, listed main packages are built into executables
and listed non-main packages are built into .a files.

In this article we will explore two major ways to share libraries between Go and C:

## Using shared library in Go

Assume that `GOPATH` contains this structure:

```
.
├── calc
│   └── calc.go
└── cashier
    └── main.go
```

The `calc` package contains a set of functions that do arithmetic opertaions:

```
// filename: calc.go
package calc

func Sum(x, y int) int {
    return x + y
}
```


Before compile any shared library, the standard builtin packages should be installed 
as shared library. This will allow any other shared library to link with them.

```
$ go install -buildmode=shared -linkshared std
```

Then the `calc` package can be compiled as shared library linked to `std` libraries:

```
$ go install -buildmode=shared -linkshared calc
```

*Due to a [issue](https://github.com/golang/go/issues/12236), building and installing
shared library should be from `$GOPATH/src`.*

Lets use the shared library `calc` in the `cashier` application:

```
// package: cashier
// filename: main.go
package main

import "calc"
import "fmt"

func main() {
  fmt.Println("Cashier Application")
    fmt.Printf("Result: %d\n", calc.Sum(5, 10))
}
```

The application should be compiled and linked with `calc` library 
with the following command:

```
$ go build -linkshared -o app cashier
```

The output of executing the application is:
```
$ ./app
Cashier Application
Result: 15
```

*Note that this feature is available on `linux/amd64` platform or when `gccgo`
compiler is used.*

## Using shared Go library in C

Go functions can be executed from C applications. They should be
exported by using the following comment line:

```
//export <your_function_name>
```

In the code snippet below, the function `SayHello` and `SayBye` are exported:

```
// package name: nautilus
package main

import "C"
import "fmt"

//export SayHello
func SayHello(name string) {
	fmt.Printf("Nautilus says: Hello, %s!\n", name)
}

//export SayBye
func SayBye() {
	fmt.Println("Nautilus says: Bye!")
}

func main() {
	// We need the main function to make possible
	// CGO compiler to compile the package as C shared library
}
```

The packaged should be compiled with `buildmode` flags `c-shared` or `c-archive`:

```
// as c-shared library
$ go build -buildmode=c-shared -o nautilus.a nautilus.go
```

```
// as c-archive 
$ go build -buildmode=c-archive -o nautilus.a nautilus.go
```

As result the `GO` compiler will produce a static/dynamic `C` library `nautilus.a` and
header file `nautilus.h`. The header file contains type definitions that marshall 
and unmarshall data between `Go` and `C`:

```
typedef signed char GoInt8;
typedef unsigned char GoUint8;
typedef short GoInt16;
typedef unsigned short GoUint16;
typedef int GoInt32;
typedef unsigned int GoUint32;
typedef long long GoInt64;
typedef unsigned long long GoUint64;
typedef GoInt64 GoInt;
typedef GoUint64 GoUint;
typedef __SIZE_TYPE__ GoUintptr;
typedef float GoFloat32;
typedef double GoFloat64;
typedef __complex float GoComplex64;
typedef __complex double GoComplex128;
typedef struct { char *p; GoInt n; } GoString;
typedef void *GoMap;
typedef void *GoChan;
typedef struct { void *t; void *v; } GoInterface;
typedef struct { void *data; GoInt len; GoInt cap; } GoSlice;

#endif

/* End of boilerplate cgo prologue.  */

#ifdef __cplusplus
extern "C" {
#endif


extern void SayHello(GoString p0);

extern void SayBye();

#ifdef __cplusplus
}
#endif
```

The header file `nautilus.h` shoulde be imported from every `C` application
that executed `SayHello` and `SayBye` functions. 

In the example below, the `SayHello` function is called with parameter of type
`GoString`. It includes `char*` field and its length.

```
// filename: _wale.c
#include "nautilus.h"
#include <stdio.h>

int main() {
  printf("This is a C Application.\n");
  GoString name = {"Jack", 4};
  SayHello(name);
  SayBye();
  return 0;
}
```

The `_wale.c` file is compiled with the following command:

```
$ gcc -o _wale _wale.c nautilus.a
```

Execution produce the following output:

```
$ ./wale
This is a C Application.
Nautilus says: Hello, Jack!
Nautilus says: Bye!
```

## Conclusion

Sharing libraries between `C` and `Go` gives opportunity to build greater and better
application by using the best from both worlds. This provides to a legacy system
a modern language that can improve their maintainance costs and business needs.
It maximize code reusability in the `Go` ecosystem.
