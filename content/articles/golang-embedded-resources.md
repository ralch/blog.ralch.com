+++
comments = "yes"
date = "2015-11-08T08:35:11Z"
share = "yes"
title = "Embedded resources in Golang"
categories = ["programming languages"]
tags = ["go", "embedded resources"]
+++

### What's an Embedded Resource?

An embedded resource in a application is a file that is included as part of
the application. The file is not compiled, but is accessable from the code at
run-time. Embedded resources can be any file type.

Languages as [JAVA](https://www.java.com) and
[C#](https://msdn.microsoft.com/en-us/library/67ef8sbd.aspx) support resources
out of box. However, this is not the case for [Golang](http://golang.org/). In
order to emebed resource, we need to develop our own solution. Thankfully,
there are couple of tools that are doing this for us.

### Bindata

This [package](https://github.com/jteeuwen/go-bindata) converts any file into
embedding binary data for a go program. The file data is optionally gzip
compressed before being converted to a raw byte slice.

It provides a command line tool `go-bindata` that offers a set of command line options, used
to customize the output being generated:

- `ignore` value Regex pattern to ignore
- `mode` uint Optional file mode override for all files.
- `modtime` int Optional modification unix timestamp override for all files.
- `nocompress` Assets will _not_ be GZIP compressed when this flag is specified.
- `nomemcopy` Use a .rodata hack to get rid of unnecessary memcopies. Refer to the documentation to see what implications this carries.
- `nometadata` Assets will not preserve size, mode, and modtime info.
- `o` string Optional name of the output file to be generated. (default "./bindata.go")
- `pkg` string Package name to use in the generated code. (default "main")
- `prefix` string Optional path prefix to strip off asset names.
- `tags` string Optional set of build tags to include.

#### Installation

To install the package and command line tool, use the following:

```
$ go get -u github.com/jteeuwen/go-bindata/...
```

#### Getting started

The simplest execution generates a `bindata.go` file in the current working
directory. It includes all assets from the data directory:

```
$ go-bindata data/
```

The operation is done on one or more sets of files. All of them are embedded in
a the Go source file, along with a table of contents and an `Asset(string)
([]byte, error)` function, which allows quick access to the assets. It should
be used in the following way:

```
resource, err := Asset("path/to/the/resource/file.txt")
if err != nil {
    // Asset was not found.
}
```

Note that the generated code lives in the `main` package. However, this can be
changed with `pkg` flag.

By default all embedded resources are compressed. If your resource is already
optmized you can disable the compression by providing `nocompress` flag.

Another handy flag is `debug` argument, which causes the command line tool to not
actually include the asset data as embedded resources. Instead of that it generates
a `Asset` function implementation that loads the data from the original file on
disk. This is very useful during development, when the assets are changed very
often.

### Go.rice

[Go.rice](https://github.com/GeertJohan/go.rice) takes similar to `gobindata`.
It provides even more advanced features to handle your embeded resources.
During the development phase it loads required assets directly from disk.
Afterwards upon deployment the resource files could be included to a executable
using the rice command line tool, without changing the source code for your
package.

#### Installation

To install the package and the command line tool use `go get`:

```
$ go get github.com/GeertJohan/go.rice
$ go get github.com/GeertJohan/go.rice/rice
```

#### Getting started

Prior using `rice` you should import the package:

```
import "github.com/GeertJohan/go.rice"
```

Then you can use `FindBox` funcation to access a particular resource bundler
(directory). The function is finding the correct absolute path
for your resource files.

```
// find a rice.Box
templateBox, err := rice.FindBox("your-resource-directory")
if err != nil {
    log.Fatal(err)
}
// get file contents as string
tmpl, err := templateBox.String("your_asset.tmpl")
if err != nil {
    log.Fatal(err)
}
```

If you are executing go binary in your home directory, but your resource
directory is located rice will lookup the correct path for that directory
(relative to the location of yourApplication). This only works when the source
is available to the machine executing the binary and was installed with `go get`
or `go install`.

You can add assets by generating go source code, or append the resources to the
executable as zip file:

Both methods require execution of `rice` command line tool before building the
actual application.

##### Embedded resource as source code

It generates a source code that contains the embedded resources.
Note that the generate files could be very large. The following commands are doing
this for us:

```
$ rice embed-go
```

The invocation scans the current directory files for `rice.FindBox` call and
identifies the directories that should be included as embedded resources in the
generate files. The command generates a files per directory. They are named in the
following format:

```
<directory-name>.rice-box.go
```

##### Embedded resource as an archive

The method appends a resource as a zip file to already built executable:

```
$ go build -o <program>
$ rice append --exec <program>
```

It makes compilation a lot faster and can be used with large resource files.

##### Embedded resource as an syso resource

This is experimental method that generates `.syso` file that is compiled by `Go`
compiler. The following command generates the `coff syso` resource files per directory:

```
$ rice embed-syso
```

##### Appending resource

In a case when you provide a binary, without source. The rice tool analyses
source code and finds call's to `rice.FindBox` and adds the required
directories to the executable binary.

You can serve a static resources over `HTTP` with the following code snippet:

```
http.Handle("/", http.FileServer(rice.MustFindBox("http-files").HTTPBox()))
http.ListenAndServe(":8080", nil)
```

### Conclusion

I am glad to find out two friendly packages that manage embedded resources in
`Go` applications. This gives a hudge advantage to use the approach that fits
our product requirements.
