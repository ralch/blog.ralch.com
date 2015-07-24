+++
Description = ""
comments = "yes"
date = "2015-07-27T23:14:12+01:00"
share = "yes"
title = "SSH tunneling in Golang"
tags = ["go", "ssh", "devops"]
categories = ["programming languages", "tutorial"]
+++

In my [previous post](/tutorial/golang-ssh-connection), I illustrated the basic usage of [ssh](https://godoc.org/golang.org/x/crypto/ssh) package. In this article
I will demonstrate how we should use it to implement `SSH tunneling`. We will
forward connection to `localhost:9000` through `example.com:22` to `localhost:8080`.

The tunneling protocol allows a network user to access or provide a network 
service that the underlying network does not support or provide directly. 

We have four actors in this scenario:

- `client` - the client that needs resource from `remote server`
- `local server` - a server accessible by the client
- `intermediate server` - a server accessible by the local server and `remote/target` server
- `remote/target server` - a server running behind the `intermediate server` network

Each of this server endpoints can be represented by the following struct:

```
type Endpoint struct {
  // Server host address
	Host string
	// Server port
	Port int
}

func (endpoint *Endpoint) String() string {
	return fmt.Sprintf("%s:%d", endpoint.Host, endpoint.Port)
}
```

Lets instanciate the each endpoint for these servers:

```
localEndpoint := &Endpoint{
	Host: "localhost",
	Port: 9000,
}

serverEndpoint := &Endpoint{
	Host: "example.com",
	Port: 22,
}

remoteEndpoint := &Endpoint{
	Host: "localhost",
	Port: 8080,
}
```

The `client` is connecting to `local endpoint`. Then the `server endpoint` 
mediates between `local endpoint` and `remote endpoint`.

The algorithms is encapsulated in `SSHTunnel` struct:

```
type SSHTunnel struct {
	Local  *Endpoint
	Server *Endpoint
	Remote *Endpoint

	Config *ssh.ClientConfig
}
```

We should establish our own `local server` by using [net](http://golang.org/pkg/net/)
package and `net.Listen` function. For any client accepted by the listener, 
we are forwarding its request to the intermediate server via `forward` go routine function:

```
func (tunnel *SSHTunnel) Start() error {
	listener, err := net.Listen("tcp", tunnel.Local.String())
	if err != nil {
		return err
	}
	defer listener.Close()

	for {
		conn, err := listener.Accept()
		if err != nil {
			return err
		}
		go tunnel.forward(conn)
	}
}

```

Port forwarding is processed by establishing an `SSH` connection to the intermediate
server. When we are connected to the intermediate server, we are able to acces the target server. 
The data tansfer between the `client` and the `remote server` is processed by `io.Copy` function:

```
func (tunnel *SSHTunnel) forward(localConn net.Conn) {
	serverConn, err := ssh.Dial("tcp", tunnel.Server.String(), tunnel.Config)
	if err != nil {
		fmt.Printf("Server dial error: %s\n", err)
		return
	}

	remoteConn, err := serverConn.Dial("tcp", tunnel.Remote.String())
	if err != nil {
		fmt.Printf("Remote dial error: %s\n", err)
		return
	}

	copyConn:=func(writer, reader net.Conn) {
		_, err:= io.Copy(writer, reader)
		if err != nil {
			fmt.Printf("io.Copy error: %s", err)
		}
	}

	go copyConn(localConn, remoteConn)
	go copyConn(remoteConn, localConn)
}
```

### Usage

You can start the tunneling server in the following way:

```
tunnel := &SSHTunnel{
		Config: sshConfig,
		Local:  localEndpoint,
		Server: serverEndpoint,
		Remote: remoteEndpoint,
	}

tunnel.Start()
```
*Note `tunnel.Start` function is blocking. if you want to enable tunneling for
your client application, you should start the function as a go routine.*

You can simple establish an connection to your local server `localhost:9000` in
the following manner:

```
conn, err := net.Dial("tcp", "localhost:9000")
if err != nil {
	// handle error
}
reader := bufio.NewReader(conn)
// ...
```

You can download the example source code from [here](https://gist.github.com/svett/5d695dcc4cc6ad5dd275).
