+++
Description = ""
comments = "yes"
date = "2015-07-06T21:11:59+01:00"
share = "yes"
tags = ["go"]
categories = ["programming languages", "tutorial"]
title = "Golang: Using user defined type as flag in terminal applications"

+++

As we saw in the [previous article](http://blog.ralch.com/tutorial/golang-subcommands/) 
[the flag](https://golang.org/pkg/flag/) package gives us flexibility to develop
command-line applications that suite our needs. 

In this post, I will show how you can develop a flag argument for user
defined type.

Lets develop application that should be executed in the following ways:

```
healthcheck -url=http://www.example.com,http://mail.example.com/inbox
healthcheck -url=http://www.example.com -url=http://mail.example.com/inbox
```

We can use the predefined `url.URL` struct in `net/url` package as type of the
arguments that are expected. Nevertheless, there is not predefined function
in `flag` package that instaciate that kind of flag for us.

Forthunately, it provides an easy way to extend that by using `flag.Var` function.
It creates a flag for any type that obey `flag.Value` interface:

```
type Value interface {
    String()
    Set(string) error
}
```

Lets declare the type `UrlFlag`:

```
type UrlFlag struct {
    urls []*url.URL
}
```

Then you should define `String()` function that converts this struct as a string: 

```
func (arr *UrlFlag) String() string {
    return fmt.Sprint(arr.urls)
}
```

The `Set(string)` is called by `flag.Parse`
function. It initializes this flag from command line arguments. 
In our case, we will expect comma-separated list of values:

```
func (arr *UrlFlag) Set(value string) error {
    urls := strings.Split(value, ",")
    for _, item := range urls {
    	if parsedUrl, err := url.Parse(item); err != nil {
    		return err
    	} else {
    		arr.urls = append(arr.urls, parsedUrl)
    	}
    }
    return nil
}
```

Note that if you do not want to allow multiple occurance of this flag, you should
return an error if the flag is already set:

```
func (arr *UrlFlag) Set(value string) error {
    if len(arr.urls) > 0 {
    	return fmt.Errorf("The url flag is already set")
    }
    
    urls := strings.Split(value, ",")
    for _, item := range urls {
    	if parsedUrl, err := url.Parse(item); err != nil {
    		return err
    	} else {
    		arr.urls = append(arr.urls, parsedUrl)
    	}
    }
    return nil
}
```

Eventually, you should declare the flag in the `main` function:

```
var arg UrlFlag
flag.Var(&arg, "url", "URL comma-separated list")
```

and parse it:

```
flag.Parse()

for _, item := range arg.Urls() {
	fmt.Printf("scheme: %s url: %s path: %s\n", item.Scheme, item.Host, item.Path)
}
```

You can get the sample from [here](https://gist.github.com/iamralch/53a288bd5250b4d443ef).
