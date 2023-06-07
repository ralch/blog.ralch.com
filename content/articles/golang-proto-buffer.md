+++
date = "2016-01-12T08:02:19Z"
share = "yes"
comments = "yes"
title = "Serialization objects with protocol buffers in Golang"
categories = ["programming languages"]
tags = ["go", "serialization", "protobuffer"]
+++

#### What is protocol buffers?

Protocol Buffers is a method of serializing structured data. It is useful in
developing programs to communicate with each other over a wire or for storing
data. The method involves an interface description language that describes the
structure of some data and a program that generates source code from that
description for generating or parsing a stream of bytes that represents the
structured data.

Google developed Protocol Buffers for use internally and has made protocol
compilers for C++, Java and Python available to the public under a free
software, open source license. Various other language implementations are also
available, including C#, JavaScript, Go, Perl, PHP, Ruby, Scala and Julia.

The design goals for Protocol Buffers emphasized simplicity and performance. In
particular, it was designed to be smaller and faster than XML.

Protocol Buffers is widely used at Google for storing and interchanging all
kinds of structured information. The method serves as a basis for a custom
remote procedure call (RPC) system that is used for nearly all inter-machine
communication at Google.

A software developer defines data structures (called messages) and services in
a proto definition file (.proto) and compiles it with protoc. This compilation
generates code that can be invoked by a sender or recipient of these data
structures.

The messages are serialized into a binary wire format which is
compact, forward- and backward-compatible, but not self-describing (that is,
there is no way to tell the names, meaning, or full datatypes of fields without
an external specification).

Though the primary purpose of Protocol Buffers is to facilitate network
communication.

#### Installation

1. Install the C++ implementation of protocol buffers from
   [here](https://github.com/google/protobuf):

```bash
$ git clone https://github.com/google/protobuf
$ cd protobuf
$ ./autogen.sh
$ ./configure
$ make
$ make check
$ make install
```

2. Install the Golang packages to work with protocol buffers. I recommend using
   the `gogo` protocol buffers [fork](https://github.com/gogo/protobuf) that is
   performance optimized. Like most of the go package, we should install it by
   executing the following commands:

```bash
$ go get github.com/gogo/protobuf/proto
$ go get github.com/gogo/protobuf/protoc-gen-gogo
$ go get github.com/gogo/protobuf/gogoproto
$ go get github.com/gogo/protobuf/protoc-gen-gofast
```

#### Creating a protocol buffer data structure

Lets create a `Company` structure that has `Name`, `Address` and `Employees`
fields. Also, we should create the corresponding objects as well.

```Golang
syntax = 'proto2';

package example;

enum CompanyType {
  Private = 17;
  Public = 18;
  NonProfit = 19;
};

message Company {
  required string Name = 1;
  repeated Employee Employees = 2;
  required CompanyType Type = 3;
  optional group Address = 4 {
    required string Country = 5;
    required string City = 6;
    optional string Street = 7;
  }
}

message Employee {
  required string Name = 1;
  optional string SSN = 2;
}
```

Lets keep the declaration in
[spec.proto](https://gist.github.com/iamralch/acdbc1b1429d97371609) file.

In order to use protocol buffers, you should define a protocol buffer file that
declare the messages that are going to be serialized. The protocol buffers
provide a syntax for doing that. You can specify whether a field should be optional
or required as well. Enumeration types can be defined as well. If you have a message
that is used only as property of another message, you can inline the define it
by using `group` declaration.

The protocol buffers supports the common scalar types, strings, enums and slices.
Slice fields can be defined as `repeated` fields.

You can read more about the supported types and syntax in [the official
documentation](https://developers.google.com/protocol-buffers/docs/proto).

After we define our messages in `spec.proto` file, we should generate their
`Golang` representation by executing the following command:

```bash
$ protoc --go_out=. spec.proto
```

The command will generate a `spec.pb.go` that implements all messages as `Golang`
structs and types:

```Golang
type CompanyType int32

const (
	CompanyType_Private   CompanyType = 17
	CompanyType_Public    CompanyType = 18
	CompanyType_NonProfit CompanyType = 19
)

type Company struct {
	Name             *string          `protobuf:"bytes,1,req,name=Name" json:"Name,omitempty"`
	Employees        []*Employee      `protobuf:"bytes,2,rep,name=Employees" json:"Employees,omitempty"`
	Type             *CompanyType     `protobuf:"varint,3,req,name=Type,enum=example.CompanyType" json:"Type,omitempty"`
	Address          *Company_Address `protobuf:"group,4,opt,name=Address" json:"address,omitempty"`
	XXX_unrecognized []byte           `json:"-"`
}

func (m *Company) Reset()                    { *m = Company{} }
func (m *Company) String() string            { return proto.CompactTextString(m) }
func (*Company) ProtoMessage()               {}
func (*Company) Descriptor() ([]byte, []int) { return fileDescriptor0, []int{0} }

func (m *Company) GetName() string {
	if m != nil && m.Name != nil {
		return *m.Name
	}
	return ""
}

func (m *Company) GetEmployees() []*Employee {
	if m != nil {
		return m.Employees
	}
	return nil
}

func (m *Company) GetType() CompanyType {
	if m != nil && m.Type != nil {
		return *m.Type
	}
	return CompanyType_Private
}

func (m *Company) GetAddress() *Company_Address {
	if m != nil {
		return m.Address
	}
	return nil
}
```

You can download the full implementation from
[here](https://gist.github.com/iamralch/7632c3628ded96a1fc60).

#### Serialization objects

The serialization and deserialization is processed by the `proto` package,
which provides `Marshal` and `Unmarshal` functions:

```Golanog
comp := &example.Company{
  Name: proto.String("Example Corp"),
  Address: &example.Company_Address{
    City:    proto.String("London"),
    Country: proto.String("UK"),
  },
  Type: example.CompanyType_Public.Enum(),
  Employees: []*example.Employee{
    &example.Employee{
      Name: proto.String("John"),
    },
  },
}

data, err := proto.Marshal(comp)
if err != nil {
  log.Fatal("marshaling error: ", err)
}
serialized := &example.Company{}
err = proto.Unmarshal(data, serialized)
if err != nil {
  log.Fatal("unmarshaling error: ", err)
}
```

#### Conclusion

The advantage of using protocol buffers is that you can develop heterogeneous
system in multiple languages and technologies which are communicating via known
protocol. It has better performance than standar serialization like JSON.
