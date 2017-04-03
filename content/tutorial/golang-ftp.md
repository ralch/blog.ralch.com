+++
date = "2017-04-03T14:10:06+01:00"
share = "yes"
title = "Working with FTP protocol in Golang"
tags: [golang, backend]
categories: ['golang', 'ftp', 'package']
+++

One of the benefits of using [Golang](www.golang.org) is its
[http](https://golang.org/pkg/net/http/) package that provides an easy way to
build robust REST APIs. 

Unfortunately, it does not provide out of the box away to build FTP server or
connect to FTP server.

In this article, we will explore that by demonstrating the usage of two third
party packages that allow that.

### Connecting to FTP server

The most robust and broadly used package that provides an FTP client build by
[Julien](https://github.com/jlaffaye). 

##### Installation

```bash
go get -u github.com/jlaffaye/ftp
```

##### Usage

You can connect the targeted FTP server as it's shown in the following code
snippet:

```golang
client, err := fto.Dial("localhost:21")
if err != nil {
  return err
}

if err := client.Login("root", "password"); err != nil {
  return err
}
```

The following code snippet lists, download and delete all files that matches
the wild card.

```golang
entries, _ := client.List(wildcard)

for _, entry := range entries {
  name := entry.Name
  reader, err := client.Retr(name)
  if err != nil {
    panic(err)
  }
  client.Delete(name)
}
```
For more advanced use cases, you can read the
[documentation](https://godoc.org/github.com/jlaffaye/ftp).

### Building an FTP Server

It's very easy to build an FTP Server by using
[goftp/server](https://github.com/goftp/server) package that provides a
framework for building FTP server with any kind of data
store (file system, AWS3 and so on).

##### Installation

```bash
go get github.com/goftp/server
```

##### Usage

In order to run the server, you have to develop or use a driver that implements 
an interface that acts as bridge between the FTP protocol and your desired
backing store:

```golang
type Driver interface {
    Init(*Conn)
    Stat(string) (FileInfo, error)
    ChangeDir(string) error
    ListDir(string, func(FileInfo) error) error
    DeleteDir(string) error
    DeleteFile(string) error
    Rename(string, string) error
    MakeDir(string) error
    GetFile(string, int64) (int64, io.ReadCloser, error)
    PutFile(string, io.Reader, bool) (int64, error)
}
```

Presently, the following drivers are available:

- [FileSystem](https://github.com/goftp/file-driver)
- [Postfix FileSystem](https://github.com/goftp/posixfs-driver)

Let's see how we can use the file system driver to build our own ftp server. We
should install the package:

```bash
go get github.com/goftp/file-driver
```

Then we have to initialise and start the ftp server with the following code
snippet:

```golang
factory := &filedriver.FileDriverFactory{
  RootPath: "path_to_directory_that_will_store_all_files",
  Perm: server.NewSimplePerm("root", "root")
}

opts := &server.ServerOpts{
  Factory: factory,
  Port: 2001,
  Hostname: "127.0.0.1",
}
server  := server.NewServer(opts)
server.ListenAndServe()
```

The `RootPath` defines where the files will be stored, while the `Perm` field
defines how the user are going to be authenticated. Presently, the package
support single user authentication by using `SimplePerm` or you can use more
advanced [LevelDB](https://github.com/goftp/leveldb-perm) authentication.

It's so easy, right?

