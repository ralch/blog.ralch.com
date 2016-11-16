+++
comments = "yes"
date = "2015-12-21T08:15:16Z"
share = "yes"
title = "Reflection in Golang"
categories = ["programming languages"]
tags = ["go", "reflection", "metadata"]

+++

#### What is reflection?

> In computer science, reflection is the ability of a computer program to examine
> and modify its own structure and behavior (specifically the values,
> meta-data, properties and functions) at runtime.

*source: [Wikipedia](http://bit.ly/1Rpm16G)*

Reflection can be used for observing and modifying program execution at
runtime. A reflection-oriented program component can monitor the execution of
an enclosure of code and can modify itself according to a desired goal related
to that enclosure. This is typically accomplished by dynamically assigning
program code at runtime.

In `Golang` reflection allows inspection of struct, interfaces, fields and
methods at runtime without knowing the names of the interfaces, fields, methods
at compile time. It also allows instantiation of new objects and invocation of
methods.

#### Reflection in action

Reflection objects are used for obtaining type information at runtime. The
structs that give access to the metadata of a running program are in the
`reflect` package. The package contains structs that allow you to obtain
information about the application and to dynamically emits types, values, and
objects to the program.

Even that reflection is not idiomatic for Golang. We will explore in details some
of `reflect` package capabilities.

#### Example: QueryBuilder

Lets assume that we are developing an object-relation mapping packages like
[gorm](https://github.com/jinzhu/gorm). We will implement `QueryBuilder` struct
that is responsible for generating `SQL` queries for update, delete and insert.

The `QueryBuilder` has a field `Type` that keep a metadata information about the
type that builder generates `SQL` queries for:

```golang
type QueryBuilder struct {
	Type reflect.Type
}
```

Typically the metadata for particular type could be accessed by instaciating the
`reflect.Type`. Lets have the followin struct:

```golang
type Employee struct {
	ID        uint32
	FirstName string
	LastName  string
	Birthday  time.Time
}
```


We need to instaciate `reflection.Type` in order to access its type metadata.
It is the representation of a Go type. We should use the following code snippet:

```golang
t := reflect.TypeOf(&Employee{}).Elem()
builder := &QueryBuilder{Type: t}
```

Note in case of pointer type, we should retrieve the underlying actual type by
getting the result from the `Elem` function. It panics if the type's
Kind is not Array, Chan, Map, Ptr, or Slice.

Lets inspect the implementation of `QueryBuilder` function `CreateSelectQuery`:

```golang
func (qb *QueryBuilder) CreateSelectQuery() string {
	buffer := bytes.NewBufferString("")

	for index := 0; index < qb.Type.NumField(); index++ {
		field := qb.Type.Field(index)

		if index == 0 {
			buffer.WriteString("SELECT ")
		} else {
			buffer.WriteString(", ")
		}
		column := field.Name
		buffer.WriteString(column)
	}

	if buffer.Len() > 0 {
		fmt.Fprintf(buffer, " FROM %s", qb.Type.Name())
	}

	return buffer.String()
}
```

The type `NumField` function returns the struct type's field count. The `for-loop`
interates over that count and obtain every field by index. The type's `Field` function
returns a `StructField` value that describes the field owned by the underlying struct:

```golang
// A StructField describes a single field in a struct.
type StructField struct {
	// Name is the field name.
	// PkgPath is the package path that qualifies a lower case (unexported)
	// field name.  It is empty for upper case (exported) field names.
	// See https://golang.org/ref/spec#Uniqueness_of_identifiers
	Name    string
	PkgPath string

	Type      Type      // field type
	Tag       StructTag // field tag string
	Offset    uintptr   // offset within struct, in bytes
	Index     []int     // index sequence for Type.FieldByIndex
	Anonymous bool      // is an embedded field
}
```

Then we are appending the field name to the select query. The final implementation
produces the following result for `Employee` struct:

```SQL
SELECT ID, FirstName, LastName, Birthday FROM Employee
```

But how to handle the case when our field are represented with different names
in underlying database. Lets say that we want to represent `ID` field as
`id_pk`, `FirstName` field as `first_name` and `LastName` field as `last_name`.

We can implement that kind of mapping by using [field
tags](https://golang.org/pkg/reflect/#example_StructTag).

The use of tags strongly depends on how your struct is used. A typical use is
to add specifications or constraints for persistence or serialisation.  For
example, when using the [JSON
parser/encoder](https://golang.org/pkg/encoding/json/), tags are used to
specify how the struct will be read from JSON or written in JSON, when the
default encoding scheme (i.e. the name of the field) isn't to be used.

Lets change the `Employee` struct declaration to use tags that carries additional
information about how the field should be mapped into the underlying database:

```golang
type Employee struct {
	ID        uint32 `orm:"id_pk"`
	FirstName string `orm:"first_name"`
	LastName  string `orm:"last_name"`
	Birthday  time.Time
}
```

Then we can access the associated tags by using `field.Tag` field. It provides
a `Get` function that allows access to any of the tags by name:

```golang
column := field.Name
if tag := field.Tag.Get("orm"); tag != "" {
	column = tag
}

buffer.WriteString(column)
```

Then the generated select query would be:

```SQL
SELECT id_pk, first_name, last_name, Birthday FROM Employee
```

#### Example: Validating fields

In the following example, we will explore how to read and validate fields values.
Lets assume that we have the following `PaymentTransaction` struct:

```golang
type PaymentTransaction struct {
	Amount      float64 `validate:"positive"`
	Description string  `validate:"max_length:250"`
}
```

Like the previous example, we will use the tag annotation. The implementation of
`Validate` function is the following code snippet:

```golang
func Validate(obj interface{}) error {
	v := reflect.ValueOf(obj).Elem()
	t := v.Type()

	for index := 0; index < v.NumField(); index++ {
		vField := v.Field(index)
		tField := t.Field(index)

		tag := tField.Tag.Get("validate")
		if tag == "" {
			continue
		}

		switch vField.Kind() {
		case reflect.Float64:
			value := vField.Float()
			if tag == "positive" && value < 0 {
				value = math.Abs(value)
				vField.SetFloat(value)
			}
		case reflect.String:
			value := vField.String()
			if tag == "upper_case" {
				value = strings.ToUpper(value)
				vField.SetString(value)
			}
		default:
			return fmt.Errorf("Unsupported kind '%s'", vField.Kind())
		}
	}

	return nil
}
```

The `reflect.Value` is the reflection interface to a Go value. It is used to
access all member for particular object (fields, function and interfaces). By
invoking the `Kind` function we determine the field type. Then we could access
the actual value with the appropriate type function (such as `Float` or `String`).
To change the field value we should use some of the setters functions.

#### Example: Recognising interfaces and calling functions

The `reflect` package can used to identify whether a particular interface is
implemented.

Lets have the `Validator` interface which provide a `Validate` function called
every time when an object is validated:

```golang
type Validator interface {
	Validate() error
}
```

We will extend the implementation of `PaymentTransaction` struct by implementing
the `Validator` interface:

```golang
func (p *PaymentTransaction) Validate() error {
	fmt.Println("Validating payment transaction")
	return nil
}
```

In order to determine whether the `PaymentTransaction` implements the interface,
we should call the `reflect.Type` function `Implements`. It returns `true` if
the type obeys the interface signature.

To call a particular function, we could either case the object to the `Validator`
interface or retrieve the method via `MethodByName` function:

```golang
func CustomValidate(obj interface{}) error {
	v := reflect.ValueOf(obj)
	t := v.Type()

	interfaceT := reflect.TypeOf((*Validator)(nil)).Elem()
	if !t.Implements(interfaceT) {
		return fmt.Errorf("The Validator interface is not implemented")
	}

	validateFunc := v.MethodByName("Validate")
	validateFunc.Call(nil)
	return nil
}
```

You can read more about different features provided by the `reflect` package
in [the official documentation](https://golang.org/pkg/reflect/).

#### Conclusion

The `reflect` package is great way to make descision at runtime. However, we
should be aware that it gives us some performance penalties. I would try to
avoid using reflection. It's not idiomatic, but it's very powerfull in
particular cases. Do not forget to follow [the laws of
reflection](http://blog.golang.org/laws-of-reflection).
