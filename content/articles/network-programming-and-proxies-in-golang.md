+++
title = "Network Programming and Proxies in Golang"
date = 2017-08-22T14:17:48+01:00
description = "Learn how to use Proxy to establish TCP connections in Golang"
comments = "yes"
share = "yes"
categories = ["programming languages", "network programming"]
tags = ["go"]
+++

Have you used any proxy servers in your infrastructure? There are a lot of
different scenarios in which you may use a proxy in order to control access to
your machines and resources. I am not saying that it's the best approach but
some companies use that.

Recently, I have been working on a TCP service that has to connect via SOCK5
proxy server. But before we dig into that, I would like to show what Golang
offers for the regular HTTP user.

By default http.Client checks the `HTTP_PROXY` and `HTTPS_PROXY` variables before
processes any http.Request. Those variables affect any request made via
[http.DefaultClient](https://golang.org/pkg/net/http/#Client).

If you want to customize that you have to create a new instance of http.Client
that has pre-configured Transport property. The
[http.Transport](https://golang.org/pkg/net/http/#Transport) struct has a Proxy
property that by default is set to
[http.ProxyFromEnvironment](https://golang.org/pkg/net/http/#ProxyFromEnvironment)
function that reads the environment variable.

We can change that by implementing our own function or using
[http.ProxyURL](https://golang.org/pkg/net/http/#ProxyURL) function that
returns the provided proxy URL.

```golang
fixedURL, err:= url.Parse("https://user:pass@proxy.com")
if err != nil {
  panic(err)
}
tr := &http.Transport{
    Proxy: http.ProxyURL(fixedURL),
}
client := &http.Client{Transport: tr}
resp, err := client.Get("https://example.com")
```

That was easy. But how we should use a proxy for our own TCP server requests.
Luckily there is an experimental package that enables us to do it very elegant
without making so many changes in our codebase.

Let's see how we can use it by installing it first.

```bash
$ go get -u http://golang.org/x/net/proxy
```

The package is very small and it's compatible with the http package. It reads
the `ALL_PROXY` and `NO_PROXY` environment variables to distinguish which hosts
require a proxy.

Presently it provides `SOCKS5` support only. However, it's very extensible by
allowing us to register new proxy dialers for particular schema. You have to
implement the [proxy.Dialer](https://godoc.org/golang.org/x/net/proxy#Dialer)
interface:

```golang
type Dialer interface {
    // Dial connects to the given address via the proxy.
    Dial(network, addr string) (c net.Conn, err error)
}
```

and to register with [proxy.RegisterDialerType]().

There are multiple ways to instantiated the dialer proxy.

#### Environment Variables

You can do it by setting the `ALL_PROXY` environment variable and use the
[proxy.FromEnvironment](https://godoc.org/golang.org/x/net/proxy#FromEnvironment)
function.

```golang
dialer := proxy.FromEnvironment()
```

#### URL

If you want to use concrete URL in a specific case, you can use the
[proxy.FromURL](https://godoc.org/golang.org/x/net/proxy#FromURL) function:

```golang
uri, err := url.Parse("socks5://demo:demo@192.168.99.100:1080")
if err != nil {
    panic(err)
}

dialer, err := proxy.FromURL(uri, forwardDialer)
if err != nil {
    // handle error
    panic(err)
}
```

The *forwardDialer* is the dialer that will be used internally by the proxy to
establish a connection to the remote host. In our case, we use a
[proxy.Direct](https://godoc.org/golang.org/x/net/proxy#Variables) dialer which
establishes direct connections:

```golang
type direct struct{}
 
// Direct is a direct proxy: one that makes network connections directly.
var Direct = direct{}
 
func (direct) Dial(network, addr string) (net.Conn, error) {
     return net.Dial(network, addr)
}
```

#### Advanced usage
If you need more control over the dialer, you can instantiate [proxy.PerHost]()
struct that allows you to specify different rules. It requires a default dialer
and bypass dialer. The default dialer is used when the request does not obey
some of the specified rules, otherwise, the bypass dialer is used.

```golang
perHostDialer := proxy.NewPerHost(dialer, proxy.Direct)
perHostDialer.AddFromString("192.168.99.100")
perHostDialer.AddZone("*.example.com")
perHostDialer.AddNetwork(your_network)

dialer = perHostDialer
```

After we know how to instantiate the proxy dialer, we should use it in the same
way as [net.Dialer](https://golang.org/pkg/net/#Dialer):

```golang
conn, err := dialer.Dial("tcp", "golang.org:80")
if err != nil {
    // handle error
    panic(err)
}

fmt.Fprintf(conn, "GET / HTTP/1.0\r\n\r\n")
status, err := bufio.NewReader(conn).ReadString('\n')
if err != nil {
    panic(err)
}

fmt.Println(status)
```



