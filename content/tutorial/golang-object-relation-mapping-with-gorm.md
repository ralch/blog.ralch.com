+++
comments = "yes"
date = "2015-11-15T08:54:02Z"
share = "yes"
title = "Object relation mapping with GORM"
categories = ["programming languages", "object relation mapping", "database"]

+++

### What is object-relation mapping (ORM, O/RM, and O/R mapping)?

> Object-relational mapping in computer science is a programming technique for
> converting data between incompatible type systems in object-oriented
> programming languages. This creates, in effect, a "virtual object database"
> that can be used from within the programming language.

*source: [Wikipedia](https://en.wikipedia.org/wiki/Object-relational_mapping)*

### What is GORM?

[GORM](https://github.com/jinzhu/gorm) is object-relation package for `Go`. It
supports the following databases:

- [FoundationDB](http://www.foundationdb.com)
- [PostgreSQL](http://www.postgresql.org)
- [MySQL](http://dev.mysql.com)
- [SQLite](https://www.sqlite.org)

#### Installation

It is easy to install by invoking `go get` command:

```
$ go get -u github.com/jinzhu/gorm
```

#### Model declaration

Models in `GORM` are a simple `Go` structs that declare a set of public fields.
Every model is representent as table and every field is column in this table.

In this blog we will define all models illustrated on the following diagram:

{{< figure src="/media/golang/gorm-diagram.png" alt="ORM Diagram" >}}

The actual representation of the diagram are three structs. Each of them has
different fields that define a database column mapping via `sql` and `gorm`
[tags](https://golang.org/pkg/reflect/#example_StructTag). In this examples, we
will explore some of them.

```
type Company struct {
	ID        int        `sql:"AUTO_INCREMENT" gorm:"primary_key"`
	Name      string     `sql:"size:255;unique;index"`
	Employees []Employee // one-to-many relationship
	Address   Address    // one-to-one relationship
}
```

The `Company` struct has an auto incremental primary key defined by
`sql:"AUTO_INCREMENT" gorm:"primary_key"`.

Its string `Name` field should contain a value that is unique for all rows in
the `Company` table. The column is indexed, which improves the performance on
any queries that uses it in their `where` clause.

`GORM` automatically creates for the rest of the fields:

- one-to-many relationship between `Company` and `Employee`
- one to one relationship between `Company` and `Address` tables

```
type Employee struct {
	FirstName        string    `sql:"size:255;index:name_idx"`
	LastName         string    `sql:"size:255;index:name_idx"`
	SocialSecurityNo string    `sql:"type:varchar(100);unique" gorm:"column:ssn"`
	DateOfBirth      time.Time `sql:"DEFAULT:current_timestamp"`
	Address          *Address  // one-to-one relationship
	Deleted          bool      `sql:"DEFAULT:false"`
}
```

The `Employee` struct is defined in similar to way.

The `FirstName` and `LastName` field have maximum length 255. In additionl a
`name_idx` index is created for both fields.

The `SocialSecurityNo` field is
renamed to `ssn` column (by declaring `gorm:"column:ssn` tag) that has values
that should be unique and do not exceed 100 characters.

The `Employee` struct has one-to-one relationship with the `Address` struct.

The fields `DateOfBirth` and `Deleted` has default values declared by
`sql:"DEFAULT:<default_value>"` tag. For the `DateOfBirth` column we are using
the postgres function `current_timestamp` to set the default value.

```
type Address struct {
	Country  string `gorm:"primary_key"`
	City     string `gorm:"primary_key"`
	PostCode string `gorm:"primary_key"`
	Line1    sql.NullString
	Line2    sql.NullString
}
```

The `Address` struct has a primary key that consists three fields `Country`, `City`
and `PostCode`. In fact it has two columns `Line1` and `Line2` that are using
`sql.NullString` type to allow null values.

In order to access your database you should open a new connection to it. In this
article I am using `PostgreSQL`. Therefore, any thoughts will be related to
`PostgreSQL` and relational databases.

You should install its driver for `GO` with the following command:

### Establishing connection

```
$ go get "github.com/lib/pq"
```

The driver should be registered to make it available for `GORM`:

```
import _ "github.com/lib/pq"
```

Then we should establish the connection:

```
db, err := gorm.Open("postgres", "postgresql://myapp:dbpass@localhost:15432/myapp")
if err != nil {
	panic(err)
}

// Ping function checks the database connectivity
err = db.DB().Ping()
if err != nil {
	panic(err)
}
```

#### Creating tables

Every struct type is presented as a table in the underlying database. Respectively
every property is represented as a column in the database table.

Lets create the declared models by invoking `db.CreateTable` function:

```
db.CreateTable(&company.Address{})
db.CreateTable(&company.Company{})
db.CreateTable(&company.Employee{})
```

The function will create underlying tables if they do not exists. They have a schema
based on the property definitions. A properties that contain `int `sql:"-"` tag
are not emitted as a table columns.

By default the created table names are in plural. If you want to disable that
you should use the following code snippet before any table create and table
migrate task.

```
db.SingularTable(true)
```

#### Migrating tables

If you want to change an existing table schema for your models, `GORM` provides
a set of features. You could automatically use the `AutoMigrate` function to
migrate the existing database schema to the new model changes.

```
db.AutoMigrate(&company.Address{})
db.AutoMigrate(&company.Company{})
db.AutoMigrate(&company.Employee{})
```

Unfortunately, the migration adds only a new columns and new indexes, but does
not alter existing columns and existing indexes.

If you want to do that you should use the functions provided by `gorm.Model`
object.

- `ModifyColumn` change columns type
- `DropColumn` drops an existing column
- `AddIndex` creates an index
- `AddUniqueIndex` creates a unique index
- `RemoveIndex` removes an existings index

Lets change the `Name` columns type of `Company` table to a `text`:

```
db.Model(&company.Company{}).ModifyColumn("name", "text")
```

#### Dropping tables

Tables could be dropped by using `db.DropTable` function:

```
db.DropTable(&company.Address{})
db.DropTable(&company.Company{})
db.DropTable(&company.Employee{})
```

The operation destroys the tables schema and all records.

#### Create, Update and Delete records

In this section we will explore the `CRUD` operations for this company:

```
sampleCompany := company.Company{
	Name: "Google",
	Address: company.Address{
		Country:  "USA",
		City:     "Moutain View",
		PostCode: "1600",
	},
	Employees: []company.Employee{
		company.Employee{
			FirstName:        "John",
			LastName:         "Doe",
			SocialSecurityNo: "00-000-0000",
		},
	},
}
```

##### Create

Lets create an new company by executing the `db.Create` function:

```
// It creates a single Company record and all associations (Address and Employees)
db.Create(&sampleCompany)
```

##### Delete

To delete the created company, you should use `db.Delete` function:

```
db.Delete(&sampleCompany)
```

You could do a batch delete. In the following example we are deleting all companies
that contains letter `G` in their name:

```
db.Where("Name LIKE ?", "%G%").Delete(company.Company{})
```

##### Update

To update an existing record you should simple change its property and use
`db.Save` command to persist the change:

```
model.Country = "USA"
db.Save(&sampleCompany)
```

For batch updates we should use simiplar to `Delete` operation approach, but this
time we should use `Updates` function instead. Lets update all `USA` addresses:

```
db.Table("addresses").Where("Country = ?", "USA").Updates(map[string]interface{}{"Country": "North America"})
```

#### Query data records

`GORM` provides a very intuitive way to query your data. It brings all power of
underlying database by providing the following functions:

```
var firstComp company.Company

// fetch a company by primary key
db.First(&firstComp, 1)

// fetch a company by name
db.Find(&firstComp, "name = ?", "Google")

// fetch all companies
var comapnies []company.Company
db.Find(&companies)

// fetch all companies that starts with G
db.Where("name = ?", "%G%").Find(&companies)
```

I cannot manage to cover in a single post. You can read more about them in the
[official documentation](https://github.com/jinzhu/gorm).

### Conclusion

`GORM` is great object relation mapping package that unifies the access to
different data base. The provides all query capabilities that we are familiar
with in `SQL` like languages. I would like to see a code generation package
that generates a models from existing data base.
