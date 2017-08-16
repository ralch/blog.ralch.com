+++
comments = "yes"
date = "2015-11-22T19:28:31Z"
share = "yes"
title = "Data validation in Golang"
categories = ["programming languages"]
tags = ["go", "model", "data", "validation"]

+++

Almost every application requires high data integrirty and quality. Very likely
is its algorithms to behave weird and produce unexpected results due to invalid
input.

An important aspect of software development is data validation. In this article
we will explore [govalidate](https://github.com/asaskevich/govalidator) package
that helps us to validate and sanitize any string, struct and slice in `Go`.

The package itself is very infulenced by its javascript predaccessor
[validator.js](https://github.com/chriso/validator.js).

#### Installation

Like any other `Go` package we should install it first:

```
$ go get github.com/asaskevich/govalidator
```

#### Getting started

The package provides a set of built-in function for validating all built-in `Go`
type, user structs and collections.

First we should import the package:

```
import "github.com/asaskevich/govalidator"
```

#### Validating built-in types

We will explore some of the built in functions that validates some untrivial but
common types:

If you want to validate whether a string is a URL:

```
// the function returns an boolean field
isValid := govalidator.IsURL(`http://user@pass:example.come`)
```

For IP address you should use `IsIP` function:

```
// the function returns an boolean field
isValid := govalidator.IsIP(`127.0.0.1`)
```

#### Validating struct

The validation functions have a tag representation that could be used as part of
property definition in particular struct.

Lets have the following sruct:

```
type Server struct {
	ID         string `valid:"uuid,required"`
	Name       string `valid:"machine_id"`
	HostIP     string `valid:"ip"`
	MacAddress string `valid:"mac,required"`
	WebAddress string `valid:"url"`
	AdminEmail string `valid:"email"`
}
```

Every of its fields has a validation tag that specifies its format:

- `ID` field should be in UUID format and should not be empty
- `HostIP` field should be a valid IP address
- `MacAddress` field should be a valid MAC address and should not be empty
- `WebAddress` field should be a valid URL
- `AdminEmail` field should be a valida email address

The `Name` field is different from the other. It uses `machine_id` tag which is
not built-in `govalidator` package. This is a custom validation tag defined by
registered callback validation function for `machine_id` key in `govalidator.TagMap`
hashmap:

```
govalidator.TagMap["machine_id"] = govalidator.Validator(func(str string) bool {
	return strings.HasPrefix(str, "IX")
})
```

The function is called for all fields that has `valid:"machine_id"` tag. It checks
whether their value is compliant with desired format.

Then we can validate an instance of `Server` struct:

```
server := &Server{
	ID:         "123e4567-e89b-12d3-a456-426655440000",
	Name:       "IX01",
	HostIP:     "127.0.0.1",
	MacAddress: "01:23:45:67:89:ab",
	WebAddress: "www.example.com",
	AdminEmail: "admin@exmaple.com",
}
```

For that purpose we should use `govalidator.ValidateStruct` function which
returns an error and boolean value as result of validation:

```
if ok, err := govalidator.ValidateStruct(server); err != nil {
	panic(err)
} else {
	fmt.Printf("OK: %v\n", ok)
}
```

#### Documentation

You can read [the official
documentation](https://github.com/asaskevich/govalidator) for the rest of the
functions.
