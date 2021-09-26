+++
Description = ""
comments = "yes"
date = "2015-07-11T11:58:15+01:00"
share = "yes"
tags = ["go"]
categories = ["programming languages", "tutorial"]
title = "Golang: Pipes and redirection in command line applications"
+++

Powerful features of the Linux command line shell are redirection and 
pipes that allow the output and even input of a program to be sent to a file
or another program.

In this article, I will demonstrates how we can pipe a file into a `go` application.

## Pipes
Pipes allow you to funnel the output from one command into another where it
will be used as the input. We should use `|` symbol to redirect the output.

A good way to see how many devices are available is the following command:

```
ls -l /dev | wc -l
```

We are counting the number of devices by sending the `ls` output to world count 
command `wc` input. The `-l` parameter display only the number of lines.

## Implementation

Every application in `unix` and `linux` has a three file descriptors associated
to it: standard input `0`, standard output `1` and standard error `2`.

In `go` you can access them by using the following fields:

```
os.Stdin
os.Stdout
os.Stderr
```

Lets develop an application `searchr` that is looking for a concrete `pattern`
in a text. The application should highlight in `red` the lines that contains
the specified pattern:

```
cat yourfile.txt | searchr -pattern=<your_pattern>
```

The following snippet implements this matching functionality:

```
func match(pattern string, reader *bufio.Reader) {
	line := 1
	for {
		input, err := reader.ReadString('\n')
		if err != nil && err == io.EOF {
			break
		}

		color := "\x1b[39m"
		if strings.Contains(input, pattern) {
			color = "\x1b[31m"
		}

		fmt.Printf("%s%2d: %s", color, line, input)
		line++
	}
}
```

We should be able to use this application with different text source. To do that
we should make sure that `os.Stdin` file descriptor points to a pipe. For this
purpose we should get `os.FileInfo` metadata for the standard input:

```
info, _ := os.Stdin.Stat()
```

The `Stat` function returns a `os.FileInfo` object that keeps information about
the file mode and file size. We should validate that the `os.Stdin` is not a
character device.

```
if (info.Mode() & os.ModeCharDevice) == os.ModeCharDevice {
	fmt.Println("The command is intended to work with pipes.")
	fmt.Println("Usage:")
	fmt.Println("  cat yourfile.txt | searchr -pattern=<your_pattern>")
} else if info.Size() > 0 {
	reader := bufio.NewReader(os.Stdin)
	match(*pattern, reader)
}
```

You can check whether there is a content to read from by comparing `info.Size()`.

*Note: Character devices in Linux/Unix are unbuffered devices that have direct
access to underlying hardware. They do not necessarily allow you to read or 
write single character at a time. Example: audio or graphics cards, 
or input devices like keyboard and mouse.*

You can get the sample source code from [here](https://gist.github.com/iamralch/a95595069e560173a3c8).



