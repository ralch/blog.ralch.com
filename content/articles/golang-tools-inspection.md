+++
Description = ""
comments = "yes"
date = "2015-09-13T08:55:41+01:00"
share = "yes"
title = "Golang code inspection tools"
tags = ["go"]
categories = ["programming languages", "tutorial", "tools"]
+++

As a software engineer, you always try to improve the quality of your programs.
We are looking for the best software development practices and TDD techniques.

```
"Have no fear of perfection - you'll never reach it."
― Salvador Dalí
```

In this article we will explore different code inspection tools in `Go` ecosystem.
We will increase our code quality and engineering skills by running tools
that will do analysis on our code base and report the suspicious parts of it.

## Govet

`Vet` does analysis on Go source code and reports suspicious constructs.
It uses heuristics that do not guarantee all reports are genuine problems.
`Vet` can find errors not caught by the compilers.

It can be invoked in three different ways:

```
// for go package
$ go tool vet package/path/name
// for files
$ go tool vet source/directory/*.go
// for directory
$ go tool vet source/directory
```

What should be analysed can be controlled with these flags (extraced from help doc):

- `-all` check everything; disabled if any explicit check is requested (default true)
- `-asmdecl` check assembly against Go declarations (default unset)
- `-assign` check for useless assignments (default unset)
- `-atomic` check for common mistaken usages of the sync/atomic package (default unset)
- `-bool` check for mistakes involving boolean operators (default unset)
- `-buildtags` check that +build tags are valid (default unset)
- `-composites` check that composite literals used field-keyed elements (default unset)
- `-compositewhitelist` use composite white list; for testing only (default true)
- `-copylocks` check that locks are not passed by value (default unset)
- `-methods` check that canonically named methods are canonically defined (default unset)
- `-nilfunc` check for comparisons between functions and nil (default unset)
- `-printf` check printf-like invocations (default unset)
- `-printfuncs` string comma-separated list of print function names to check
- `-rangeloops` check that range loop variables are used correctly (default unset)
- `-shadow` check for shadowed variables (experimental; must be set explicitly) (default unset)
- `-shadowstrict` whether to be strict about shadowing; can be noisy
- `-shift` check for useless shifts (default unset)
- `-structtags` check that struct field tags have canonical format and apply to exported fields as needed (default unset)
- `-tags` string comma-separated list of build tags to apply when parsing
- `-test` for testing only: sets -all and -shadow
- `-unreachable` check for unreachable code (default unset)
- `-unsafeptr` check for misuse of unsafe.Pointer (default unset)
- `-unusedfuncs` string comma-separated list of functions whose results must be used (default "errors.New,fmt.Errorf,fmt.Sprintf,fmt.Sprint,sort.Reverse")
- `-unusedresult` check for unused result of calls to functions in -unusedfuncs list and methods in -unusedstringmethods list (default unset)
- `-unusedstringmethods` string comma-separated list of names of methods of type func() string whose results must be used (default "Error,String")

Lets use this code snippet from [@francesc](https://twitter.com/francesc):

```
// extracted from tweet: https://twitter.com/francesc/status/491699441506586627
// filename: sample.go
package main

import "fmt"

func main() {
	a := 0
	if a != 1 || a != 2 {
		 a++
	}

	fmt.Printf("a = %s\n", a)
}
```

Lets see the tool in action:

```
$ go tool vet sample.go
```

`Vet` reports two suspicious constructions. First it reports that the if-condition
is suspicious. It's always `true` since cannot be both. The second warning reports
that `%s` is used with `integer` type instead of `string`.

```
sample.go:10: suspect or: a != 1 || a != 2
sample.go:14: arg a for printf verb %s of wrong type: int
```

## Golint

[Golint](http://github.com/golang/lint) differs from `gofmt` and `govet`. It prints out style mistakes.
`Golint` is concerned with coding style. It is in use at Google, and it seeks
to match the accepted style of the open source Go project.

`Golint` make suggestions regarding source code. It is not perfect,
and has both false positives and false negatives. Do not consider its output as a truth.
It will never be trustworthy enough to be enforced automatically as part of a build process.

#### Installation

```
go get -u github.com/golang/lint/golint
```

#### Usage

```
// analysis a particular package
$ golint package
// analysis a particular directory
$ golint directory
// analyses a particualr files
$ golint files
```

Lets `lint` the following code snippet:

```
// filename: hr.go
package hr

import "errors"

const MaxAge int = 70

type Person struct {
	Name string
	Age  int
}

func NewPerson(name string) (*Person, error) {
	if name == "" {
		return nil, errors.New("Name is required")
	} else {
		return &Person{Name: name}, nil
	}
}
```

The command tool give us the following sugestion to improve our source code:

```
hr.go:5:6: exported type Person should have comment or be unexported
hr.go:9:1: exported function NewPerson should have comment or be unexported
hr.go:12:9: if block ends with a return statement, so drop this else and outdent its block
```

Neat. Isn't it?

## Errcheck

The [errcheck](http://github.com/kisielk/errcheck) command tools is a program that checks whether a source code has
unhandled errors.

#### Installation

```
$ go get github.com/kisielk/errcheck
```

#### Usage

The following flags can control the tool behavior (extracted from help doc):

- `-abspath` print absolute paths to files
- `-asserts` if true, check for ignored type assertion results
- `-blank` if true, check for errors assigned to blank identifier. By default is false.
- `-ignore` value comma-separated list of pairs in pkg:regex format.
- `-ignorepkg` string comma-separated list of package paths to ignore
- `-tags` value space-separated list of build tags to include (default "")
- `-verbose` produce more verbose logging

Lets have the following snippet:

```
// filename: logger.go
package logger

import "os"

func Log(path, data string) {
	file, _ := os.Open(path)
	file.Write([]byte(data))
	file.Close()
}
```

Lets do error handling analysis with `errcheck` tool:

```
// Note that analyses of _ errors is skipped by default.
// We enable that by providing -blank flag.
$ errcheck -blank app.go
```

The following lines are reported as problematic:

```
web/logger.go:6:8        file, _ := os.Open(path)
web/logger.go:7:12       file.Write([]byte(data))
web/logger.go:8:12       file.Close()
```

## SafeSQL

[SafeSQL](https://github.com/stripe/safesql) is a static analysis command line
tool that protects against [SQL injections](https://en.wikipedia.org/wiki/SQL_injection).

#### Installation

```
$ go get github.com/stripe/safesql
```

#### Usage

If SafeSQL passes, your application is safe from SQL injections, however there
are many safe programs which SafeSQL will declare potentially unsafe. There are
false positives due to the fact that `SafeSQL` does not recursively trace down
query arguments through every function. Second there are many SQL statement to
represent compile time constants required for the static analysis algorithm.

Lets see the tool in action with this code snippet:

```
package database

import (
	"database/sql"
	"log"
)

func Status(username string) string {
	db, err := sql.Open("mysql", "user:password@tcp(127.0.0.1:3306)/hello")
	if err != nil {
		log.Fatal(err)
	}

	defer db.Close()
	sql := "SELECT * FROM user WHERE username='" + username + "'"
	row := db.QueryRow(sql)

	var isLogged bool
	row.Scan(&isLogged)
	if isLogged {
		return "online"
	}

	return "offline"
}
```

It reports the following SQL injection:

```
Found 1 potentially unsafe SQL statements:
- /$GOPATH/db/database.go:16:20
```

It gives the following recommendation:

```
Please ensure that all SQL queries you use are compile-time constants.
You should always use parameterized queries or prepared statements
instead of building queries from strings.
```

## Defercheck

[Defercheck](http://github.com/opennota/check/) is command tool that checks for repeating `defer` statements.

#### Installation

```
$ go get github.com/opennota/check/cmd/defercheck
```

#### Usage

```
$ defercheck go/parser
```

It reports the following suspicious defer statement in parser package:

```
/usr/.../go/parser/parser.go:1929: Repeating defer p.closeScope() inside function parseSwitchStmt
```

## Structcheck

[Structcheck](http://github.com/opennota/check/) is command tool that checks for unused field in structs.

#### Installation

```
$ go get github.com/opennota/check/cmd/structcheck
```

#### Usage

Lets check the `hr` codesnippet that we used previously.

```
$ structcheck -e hr
```

Available command line flags are:

- `-a` Count assignments only
- `-e` Report exported fields
- `-t` Load test files too

It reports that the `Age` field of `Person` struct is unused:

```
hr: /$GOPATH/src/hr/hr.go:7:2: hr/hr.Person.Age
```

## Varcheck

[Varcheck](http://github.com/opennota/check/) command is doing the same analysis as `Structcheck` but on global
variables and constants.

#### Installation

```
$ go get github.com/opennota/check/cmd/varcheck
```

#### Usage

Lets inspect the `hr` package again:

```
// -e Report exported variables and constants
$ varcheck -e hr
```

It finds that the `Age` constant is not used:

```
hr: /$GOPATH/src/hr/hr.go:5:7: MaxAge
```

## Conclusion

[Static single-assignment package](https://godoc.org/golang.org/x/tools/go/ssa)
provides a very powerful framework for code analysis. It gives the opportunity
to build different tools that may increase the code quality and durability of
every `Go` program. I am looking forward to see more and more command tools
that will bring our source code to the next level.

The previous articles regarding tools in `Go`:

- [Golang refactoring tools](http://blog.ralch.com/tutorial/golang-tools-refactoring/)
- [Golang code comprehension tools](http://blog.ralch.com/tutorial/golang-tools-comprehension/)
