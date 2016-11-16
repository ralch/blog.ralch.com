+++
comments = "yes"
date = "2016-02-03T13:34:23Z"
share = "yes"
title = "Design Patterns in Golang: The Good, the Bad and the Ugly"
categories = ["programming languages", "design patterns"]
tags = ["go", "opinion"]

+++

Recently I started a series of articles about [Gang of Four Design
Patterns](https://en.wikipedia.org/wiki/Design_Patterns) and their adoption in
Golang. They made a lot of noise in the community. I read a lot
of contradictionary opionions whether should be used or not. I am publishing those
articles as show case how the common design patterns can be adopted and implemented
in Golang. I don't encourage or promote their usage. Every developer has own style
of programming, architecture desing and problem solving solutions.

Well, I don't have a strong opionion about that. However, I have my own angle
of view about this topic. I have never been a strong believer that they should
be used intensively in any project. For me they have always been a language for
communication among development teams. Yes, they solve particular problems. But
I don't think we should use them, because they exist and ar good practice.

Particular pattern should be used only in concrete case, when we gain benefit of
that. I don't encourage applying it by the book.

The `Design Patterns` have never been something encourage by the Golang community.
They are not idiomatic for the language. Everybody knows that the language itself
is very opioninated and idiomatic. There are no so many ways to achieve particular
task or solve particular problem.

But let's explore. Are they used in the existing Golang packages? I will give
you a few examples how they are used in Golang libraries:

#### Singleton Design Pattern

The [net/http](https://golang.org/pkg/net/http/) package has
[http.DefaultClient](https://golang.org/src/net/http/client.go?s=76:76#L76) and
[http.DefaultServeMux](https://golang.org/src/net/http/server.go?s=1595:1595#L1595)
objects that are alive during the application lifecycle. The `DefaultClient` is
used by [Get](https://golang.org/src/net/http/client.go?s=9198:9246#L270),
[Head](https://golang.org/src/net/http/client.go?s=15901:15950#L500) and
[Post](https://golang.org/src/net/http/client.go?s=13816:13898#L443) functions
to send request to http server.

Those variables contains a single instances that can be used accros the application.
The implementation does not follow the same as most of the mainstream language. It's
still Golang idiomatic.

#### Factory Design Pattern

Did you used [PostrgreSQL](https://github.com/lib/pq) library like that?

```Golang
import (
	"database/sql"
	_ "github.com/lib/pq"
)

func main() {
	db, err := sql.Open("postgres", "user=pqgotest dbname=pqgotest sslmode=verify-full")
	if err != nil {
		log.Fatal(err)
	}

	age := 21
	rows, err := db.Query("SELECT name FROM users WHERE age = $1", age)
	...
}
```

Well in order to connect to `PostgreSQL` server the `sql` package instaciate the
registered driver via `Factory` Design Pattern. The driver is registered by
[this function](https://golang.org/src/database/sql/sql.go?s=805:853#L24).

The `Factory` function is [db.Open](https://golang.org/src/database/sql/sql.go?s=805:853#L468).

#### Iterator Design Pattern

Golang has a [token package](https://golang.org/pkg/go/token/) that defines
constants representing the lexical tokens of the Go programming language and
basic operations on tokens (printing, predicates).

The package has a
[token.FileSet](https://golang.org/src/go/token/position.go?s=9878:10118#L312)
struct that represents a set of source files. The struct implements [The
Interator Design Pattern](https://en.wikipedia.org/wiki/Iterator_pattern).

```Golang
func printStats(d time.Duration) {
 	fileCount := 0
 	lineCount := 0
 	fset.Iterate(func(f *token.File) bool {
 		fileCount++
 		lineCount += f.LineCount()
 		return true
 	})
 	fmt.Printf(
 		"%s (%d files, %d lines, %d lines/s)\n",
 		d, fileCount, lineCount, int64(float64(lineCount)/d.Seconds()),
 	)
 }
```

It has an
[Iterate](https://golang.org/src/go/token/position.go?s=11886:11931#L378)
function that calls a function for the files in the file set in the order they
were added until it returns false.

#### Builder or Strategy Design Pattern

The Golang has an [image](https://golang.org/pkg/image/) package that can
generate and manipulate different formats of images. The package exposes
interfaces [image.Image](https://golang.org/pkg/image/#Image) and
subpackage [draw](https://golang.org/pkg/image/draw/) that has
[draw.Drawer](https://golang.org/pkg/image/draw/#Drawer) interface.

These interfaces allow composition of different shapes and draw strategies:

```Golang
// Example from: http://blog.golang.org/go-imagedraw-package
type circle struct {
    p image.Point
    r int
}

func (c *circle) ColorModel() color.Model {
    return color.AlphaModel
}

func (c *circle) Bounds() image.Rectangle {
    return image.Rect(c.p.X-c.r, c.p.Y-c.r, c.p.X+c.r, c.p.Y+c.r)
}

func (c *circle) At(x, y int) color.Color {
    xx, yy, rr := float64(x-c.p.X)+0.5, float64(y-c.p.Y)+0.5, float64(c.r)
    if xx*xx+yy*yy < rr*rr {
        return color.Alpha{255}
    }
    return color.Alpha{0}
}

draw.DrawMask(dst, dst.Bounds(), src, image.ZP, &circle{p, r}, image.ZP, draw.Over)
```

For me it looks more like [Builder Design
Pattern](http://blog.ralch.com/tutorial/design-patterns/golang-builder/) or
[Strategy Design Pattern](https://en.wikipedia.org/wiki/Strategy_pattern).

You can read more about it in this [Golang blog
post](http://blog.golang.org/go-imagedraw-package).

*PS. Please share your finding regarding any other examples of GoF Desing
Pattern usage. I will be glad to publish them as well.*

#### Verdict

The Desing Patterns do exist in Golang. Their implementation does not align with
the one that we have used to see in the mainstream languages like C#, JAVA and etc.

But what should we consider as idiomatic for Golang?

*As my colleague George said:*

> After all we (as users) define the idioms in the language.

It's true, isn't it?
