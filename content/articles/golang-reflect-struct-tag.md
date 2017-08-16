+++
Description = ""
comments = "yes"
date = "2017-03-21T12:33:56+01:00"
share = "yes"
title = "Golang: Extending reflect.StructTag to support duplicates"
tags = ["go", "reflect", "json"]
categories = ["programming languages"]
+++

Presently, [Golang](www.golang.org) has limited support of
[reflection](https://en.wikipedia.org/wiki/Reflection_(computer_programming))
comparing to the mainstream languages like C# and JAVA. It's not intended to
match or beat that languages.

In practice, we are using
[StructTag](https://golang.org/pkg/reflect/#StructTag) to add some metadata for
the defined struct fields. Such an example is
[json](https://golang.org/pkg/encoding/json/#Marshal) package, where you can
customize the field marshaling. 

In example below, we customize the json representation of `User` struct
fields:

```Golang
type User struct {
  ID         string    `json:"id"`
  Name       string    `json:"name"`
  CreatedAt  time.Time `json:"created_at"`
  UpdatedAt  time.Time `json:"updated_at"`
}
```

The struct above is marshalled to the following `JSON` object:

```Golang
data, err := json.Marshal(&User{
	ID:        "root",
	Name:      "Phogo Robot",
	UpdatedAt: time.Now(),
	CreatedAt: time.Now(),
})
```

```JSON
{
  "id": "root",
  "name": "Phogo Robot",
  "created_at": "2009-11-10T23:00:00Z",
  "updated_at": "2009-11-10T23:00:00Z"
}
```

Internally, the JSON package uses
[StructTag](https://golang.org/pkg/reflect/#StructTag) to read the json metadata
and marshal fields based on that. However, presently the tags cannot be
declared more than once per field. They are unique, which make sense in most cases.

At [Phogo Labs](www.phogolabs.com), we faced that limitation when in development of
[sqlutil](https://github.com/phogolabs/sqlutil) package for which we we will
talk about in some of the next articles. 

Briefly, [sqlutil](https://github.com/phogolabs/sqlutil) is lightweight
minimalistic ORM package that allows CRUD operations and creation of tables
(including constraints and indexes).

So we thought that will be much friendly if we allow the package user to define
multiple SQL indexes by using tags. However, one column can be in more than one index.

So we wanted this:

```Golang
type User struct {
  ID         string    `sqlindex:"search_idx"`
  Name       string    `sqlindex:"name" sqlindex:"search_indx"`
}
```

Fortunately, Golang is completely open source and didn't have to reinvent the wheel
to accomplish that. By changing the original implementation we accomplished the
following:

```Golang
package sqlutil

import (
	"reflect"
	"strconv"
)

type Tag reflect.StructTag

func (tag Tag) Get(key string) []string {
	v, _ := tag.Lookup(key)
	return v
}

func (tag Tag) Lookup(key string) ([]string, bool) {
	// When modifying this code, also update the validateStructTag code
	// in cmd/vet/structtag.go.

	exist := false
	values := []string{}

	for tag != "" {
		// Skip leading space.
		i := 0
		for i < len(tag) && tag[i] == ' ' {
			i++
		}
		tag = tag[i:]
		if tag == "" {
			break
		}

		i = 0
		for i < len(tag) && tag[i] > ' ' && tag[i] != ':' && tag[i] != '"' && tag[i] != 0x7f {
			i++
		}
		if i == 0 || i+1 >= len(tag) || tag[i] != ':' || tag[i+1] != '"' {
			break
		}
		name := string(tag[:i])
		tag = tag[i+1:]

		// Scan quoted string to find value.
		i = 1
		for i < len(tag) && tag[i] != '"' {
			if tag[i] == '\\' {
				i++
			}
			i++
		}
		if i >= len(tag) {
			break
		}
		qvalue := string(tag[:i+1])
		tag = tag[i+1:]

		if key == name {
			exist = true
			value, err := strconv.Unquote(qvalue)
			if err != nil {
				break
			}

			values = append(values, value)
		}
	}

	return values, exist
}
```

The code can be found
[here](https://github.com/phogolabs/sqlutil/blob/master/metadata_tag.go).

The LICENSE is removed in the code snippet above in order to lower its size.

So how to use it? Well, in the same way as the original implementation:

```Golang
type User struct {
	ID string `sqlindex:"gopher" sqlindex:"blue"`
}

u := User{}
typ := reflect.TypeOf(u)
field := typ.Field(0)
tags:= field.Tag.Get("sqlindex")

fmt.Println(tags[0])
fmt.Println(tags[1])
```

We are looking for any other crazy ideas. [Say
HI](https://www.phogolabs.com/#contact)
