+++
Description = ""
comments = "yes"
date = "2015-10-25T07:35:49+01:00"
share = "yes"
title = "Query data with Golang and LINQ"
categories = ["programming languages", "tutorial"]
tags = ["go", "LINQ", "query"]

+++

Query langauges provide a set of features to querying, projecting and retrieving
data (usually relational data). But how to introduces these standard,
easily-learned patterns for querying data? 

In this article we will explore [Go LINQ](http://ahmetalpbalkan.github.io/go-linq/)
packages that bridges the gap between the world of objects and the world of data.

### LINQ 

For first time is introduced by [Microsoft in their programming language C#](https://msdn.microsoft.com/en-us/library/bb397926.aspx).
Its purpose is to bridge the gap between query languages such as SQL and 
programming languages. 

`Go LINQ` is a query package for Go. Essentially it has ability to apply 
queries to slices and collections using SQL-like methods. 

#### Installation

As any other `go package` we should execute `go get` command:

``` 
$ go get ahmetalpbalkan.github.io/go-linq 
```

#### Usage

The package consists two query structs that have a set of functions for querying,
projection, grouping, filtering, sorting, aggregation and many more which will
explore in detail. Queries are processed synchronously and asynchronously as well. It
does not evaluate the data lazily. No deferred execution due to lack of enumeration
abstraction. The package works only with slices.

Lets work with a slice of `Company` struct:

```
type Company struct {
	Name    string
	Country string
	City    string
}
```

```
companies := []company.Company{
	company.Company{Name: "Microsoft", Country: "USA", City: "Redmond"},
	company.Company{Name: "Google", Country: "USA", City: "Palo Alto"},
	company.Company{Name: "Facebook", Country: "USA", City: "Palo Alto"},
	company.Company{Name: "Uber", Country: "USA", City: "San Francisco"},
	company.Company{Name: "Tweeter", Country: "USA", City: "San Francisco"},
	company.Company{Name: "SoundCloud", Country: "Germany", City: "Berlin"},
}
```

The package itself uses `reflection` to work any slice or collection of data. It
declares `linq.T` interface that used by most of the package functions. In order to work
with a concrete type, it must be casted:

```
var value linq.T
obj := value.(yourType)
```

##### Examples

The example are pretty similar to my previous blog post where I am using [Gen]().
The difference between both libraries is that `Gen` relies on code generation
while `LINQ` works by using reflection. I haven't done any performance comparisions
to evaluate how slow LINQ is.

Most of the clojure functions receive `linq.T` object as arguments. 

```
// selects all companies located at USA
allUSCompanies := From(companies).Where(func(c T) (bool, error) {
	return c.(company.Company).Country == "USA", nil
})
```

```
// distincts the companies by their country of origin
uniqueCompanies := From(companies).DistinctBy(func(compA T, compB T) (bool, error) {
	return compA.(company.Company).Country == compB.(company.Company).Country, nil
})
```

```
// sorts the companies by their name
sortedCompanies := From(companies).OrderBy(func(compA T, compB T) bool {
	return strings.Compare(compA.(company.Company).Name, compB.(company.Company).Name) == -1
})
```

Grouping a slice is processed by `GroupBy` function which accepts as argument 
two selector functions. The first clojure selects the group key, while the second
returns the object for that key. The result is again a `map[T]T`.

```
groupedCompanies, err := From(companies).GroupBy(func(comp T) T {
	return comp.(company.Company).Country
}, func(c T) T {
	return c
})

if err != nil {
	panic(err)
}

fmt.Println("US Companies: ", groupedCompanies["USA"])
fmt.Println("German Companies: ", groupedCompanies["Germany"])
```

```
// projects a slice of companies into a slice of company names
companyNames := From(companies).Select(func(comp T) (T, error) {
	return comp.(company.Company).Name, nil
})
```

#### Advanced Samples

The `LINQ` package provides some advanced features that are very first citizen
in the query langauges. 

You can intersect two slices by using the following code snippet:

```
intersectedCompanies := From(companies).Intersect([]company.Company{
	company.Company{Name: "Microsoft",
		Country: "USA",
		City:    "Redmond"},
})
```

If you want to combine two slice into one, you should use the `Union` function:

```
unionCompanies := From(companies).Union([]company.Company{
	company.Company{Name: "Skyp",
		Country: "Latvia",
		City:    "Talin"},
})
```

Lets check whether the slice has at least one company that is
in Germany. For that purpose we can use `AnyOf` function:

```
hasGermanCompany, err := From(companies).AnyWith(func(comp T) (bool, error) {
	return strings.Compare(comp.(company.Company).Country, "Germany") == 0, nil
})
```

If you want to get all companies that are different than Microsoft, you should
consider using `Except` function:

```
openSourceCompanies := From(companies).Except([]company.Company{
	company.Company{Name: "Microsoft",
		Country: "USA",
		City:    "Redmond"},
})
```

The package provides us with a `join` function that correlates the elements of
collections based on their equality. The first two clojure functions extract the
key for every item in each slice. The third functions extracts the result that
we want.

In the example below the inner join is between `companies` and `countries` slice
based on `company.Counutry` and `country.Name` properties. Objects that have the
same property value are correlated.

```
countries := []company.Country{
	company.Country{Name: "USA",
		Wikipedia: "https://en.wikipedia.org/wiki/United_States"},
	company.Country{Name: "Germany",
		Wikipedia: "https://en.wikipedia.org/wiki/Germany"},
}

// The join function produces a slice of struct that has two properties
// Company name and Countr Info
companiesWithCountryInfo := From(companies).Join(countries, func(comp T) T {
	return comp.(company.Company).Country
}, func(cntry T) T {
	return cntry.(company.Country).Name
}, func(outer, inner T) T {
	var result struct {
		Company     string
		CountryInfo string
	}

	result.Company = outer.(company.Company).Name
	result.CountryInfo = inner.(company.Country).Wikipedia
	return result
})
```

The code snippet above produces a slice of objects that have `Company` and `CountryInfo`
properties:

```
{[{Microsoft https://en.wikipedia.org/wiki/United_States} 
{Google https://en.wikipedia.org/wiki/United_States} 
{Facebook https://en.wikipedia.org/wiki/United_States} 
{Uber https://en.wikipedia.org/wiki/United_States} 
{Tweeter https://en.wikipedia.org/wiki/United_States} 
{SoundCloud https://en.wikipedia.org/wiki/Germany}] <nil>}
```

If you want to get top 3 companies in the slice you can use `Take` function:

```
top3comapnies := From(companies).Take(3)
```

If you want to get all companies except the first 3 you can use `Skip` function:

```
restOfComapnies := From(companies).Skip(3)
```

These functions are very handy in implementing paging:

```
pageNumber := 1
pageItemCount := 20

pagedCompanies := From(companies).
	Skip(pageNumber * pageItemCount).
	Take(pageItemCount)
```

You can read more about the rest of features in the [official documentation](https://godoc.org/github.com/ahmetalpbalkan/go-linq).

#### Verdict

LINQ package is not very `Go` idiomatic due to its reflection. However, it provides
us with great set of features which does not require any code generation and can be
use out of the box.

