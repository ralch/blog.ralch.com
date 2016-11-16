+++
Description = ""
comments = "yes"
date = "2015-09-06T08:52:51+01:00"
share = "yes"
title = "Golang code comprehension tools"
tags = ["go"]
categories = ["programming languages", "tutorial", "tools"]

+++

Software engineers spend a greater part of time reading and understanding programs. 
Indeed, most of the time it takes to develop a program is spent reading it and 
making logical conclusion about what it does.  

`Go` programmers are no exception. Thanks to [gofmt](http://blog.ralch.com/tutorial/golang-tools-refactoring/) 
they should not worry about source code formatting. The machines are 
better suited to analyse source code and accomplish comprehension tasks than us. 

In this article we will explore several of `Go` comprehension tools that are 
responsible for locating definitions, ascertaining types of expressions, deducing implementation
relation, computing method sets, finding callers/callees, jumping through channels, 
understanding aliasing.

## Oracle
The `oralce` is a source analysis tool that answers question about your Go source code.
It is installed by executing this command:

```
$ go get golang.org/x/tools/cmd/oracle
```

A `-pos` flag is always required. It defines the current cursor position that
should be analysed. The expected value is a bytes offset from the beginning of 
the file.

These are the subcommands that determines the query to perform:

- `callees` show possible targets of selected function call
- `callers` show possible callers of selected function
- `callstack` show path from callgraph root to selected function
- `definition` show declaration of selected identifier
- `describe` describe selected syntax: definition, methods, etc
- `freevars` show free variables of selection
- `implements` show relation for selected type or method
- `peers` show send/receive corresponding to selected channel op
- `referrers` show all refs to entity denoted by selected identifier
- `what` show basic information about the selected syntax node

The `-format` flag set the output format to:

- `plain` an editor-friendly format in which every line of output
- `json` structured data in JSON syntax.
- `xml` structured data in XML syntax.

Overall, the tools provides an friendly interface for adopting it in different
development editor: [Vim](https://github.com/fatih/vim-go), [Emacs](https://www.gnu.org/software/emacs/), 
[Atom](https://atom.io), IntelliJ and etc.

Let see `oracle` in action:

{{< youtube F0ZLIxKWSYo >}}

## Pythia

`Pythia` is a browser based user interface for oracle. It is based on 
the following packages:

- [oracle](https://godoc.org/golang.org/x/tools/oracle)
- [godoc](https://godoc.org/golang.org/x/tools/godoc/static)

`Pythia` is installed with the following command:

```
$ go get github.com/fzipp/pythia
```

The `pythia` command tool now can be found in `$GOPATH/bin/pythia`. A specific
package can be opened with the following command:

```
$ pythia net/http 
```

By default the command opens your default browser: 

{{< figure src="/media/golang/golang-pythia-in-action.png" alt="Pythia in Action" >}}

This can be disabled with `-open` flag:

```
$ pythia -open=false net/http
```

The default listening port is `:8080`. It can be changed via `-http` flag: 

```
$ pythia -http :9876 net/http
```

The packages can be filtered out on their [build tags](http://blog.ralch.com/tutorial/golang-conditional-compilation/):

```
$ pythia -tags=unix net/http
```

## Godepgraph

`Godepgraph` is a program for generating a dependency graph of Go packages. 
Use `go get` command to install it:

```
$ go get github.com/kisielk/godepgraph
```

Usually the tool is combined with `dot` command (graphviz CLI):

```
// this command will generate dependency graph as svg image
// -s ingores the builtin packages
// -horizontal layout the graphics horizontally
$ godepgraph -s -horizontal github.com/codegangsta/gin | dot -Tsvg -o gin-godepgraph.svg
```

The command above will produce the following graphics:

{{< figure src="/media/golang/golang-godepgraph.svg" alt="Godepgraph in Action" >}}

The `godepgraph` tools can be controlled with these flags:

- `-d` show dependencies of packages in the Go standard library
- `-horizontal` lay out the dependency graph horizontally instead of vertically
- `-i` string a comma-separated list of packages to ignore
- `-p` string a comma-separated list of prefixes to ignore
- `-s` ignore packages in the Go standard library
- `-t` include test packages
- `-tags` string a comma-separated list of build tags to consider satisfied during the build

## Conclusion

Even though Golang does not have dedicated development environment, software engineers
can be very product by adopting some of the comprehensive tools mentioned in this article.
