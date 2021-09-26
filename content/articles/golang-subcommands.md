+++
Description = ""
comments = "yes"
date = "2015-07-04T14:08:25+01:00"
share = "yes"
tags = ["go"]
categories = ["programming languages", "tutorial"]
title = "Golang: Implementing subcommands for command line applications"

+++

Golang [flag](https://golang.org/pkg/flag/) package provides flag and
subcommand parsing of command line arguments.

Basic flags are available for most of the buildin data types (`string`, `integer`,
`boolean` and `time.Duration`). To declare a string flag `username` with a default
value `root` and short description, you should use the following code:

```
package main

import "flag"
import "fmt"

func main() {
    username := flag.String("user", "root", "Username for this server")
    flag.Parse()
    fmt.Printf("Your username is %q.", *username)
}
```

Once all flags are declared, call `flag.Parse()` to execute 
the command-line parsing.

Good way to organize an command line arguments are `subcommands`. They are 
an auxiliary commands of the main application. They group an application 
functionalities in logical units. 

`git` is an simple example: 

```
git log
git status
```

Lets a develop an application called `siri` that has a
multiple *subcommans* and additional `flags`:

```
siri send -recipient=john@example.com -message="Call me?" 
siri ask -question="What is the whether in London?"
```

We have these subcommands: `send` and `ask`. For each of them,
we should create a `flag.FlagSet` object that represents a set of defined flags:

```
askCommand := flag.NewFlagSet("ask", flag.ExitOnError)
questionFlag := askCommand.String("question", "", "Question that you are asking for")

sendCommand := flag.NewFlagSet("send", flag.ExitOnError)
recipientFlag := sendCommand.String("recipient", "", "Recipient of your message")
messageFlag := sendCommand.String("message", "", "Text message")
```

The `name` argument defines the command name. The second argument defines the 
error handling behavior:

- `flag.ContinueOnError` - continue on parsing error
- `flag.ExitOnError` - application exits with status code 2 on parsing error
- `flag.PanicOnError` - application panics on parsing error

Each application has `os.Args` array that includes all arguments passed to it. 
The first item is always the application name. 

We are using `os.Args` to determine, which subcommand should be executed:

```
if len(os.Args) == 1 {
	fmt.Println("usage: siri <command> [<args>]")
	fmt.Println("The most commonly used git commands are: ")
	fmt.Println(" ask   Ask questions")
	fmt.Println(" send  Send messages to your contacts")
	return
}

switch os.Args[1] {
case "ask":
	askCommand.Parse(os.Args[2:])
case "send":
	sendCommand.Parse(os.Args[2:])
default:
	fmt.Printf("%q is not valid command.\n", os.Args[1])
	os.Exit(2)
}
```

If the mandatory arguments are provided, we execute the parsed commands:

```
if askCommand.Parsed() {
	if *questionFlag == "" {
		fmt.Println("Please supply the question using -question option.")
		return
	}
	fmt.Printf("You asked: %q\n", *questionFlag)
}

if sendCommand.Parsed() {
	if *recipientFlag == "" {
		fmt.Println("Please supply the recipient using -recipient option.")
		return
	}

	if *messageFlag == "" {
		fmt.Println("Please supply the message using -message option.")
		return
	}

	fmt.Printf("Your message is sent to %q.\n", *recipientFlag)
	fmt.Printf("Message: %q.\n", *messageFlag)
}
```

You can get the sample from [here](https://gist.github.com/iamralch/a6f02026270b443d5e46).

If you want more advanced features, there are many third party packages:

- [Cobra](https://github.com/spf13/cobra)
- [Codegangsta CLI](https://github.com/codegangsta/cli)
- [Goptions](https://github.com/voxelbrain/goptions)
