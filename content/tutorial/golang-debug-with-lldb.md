+++
Description = ""
comments = "yes"
date = "2015-08-01T16:47:06+01:00"
share = "yes"
title = "Debug Golang applications: LLDB"
tags = ["go", "debug"]
categories = ["programming languages", "tutorial"]

+++

Even that ease and simplicity of using `go` are one of its main advanatages,
there are difficulties in debugging applications written in `go`.

The lack of mature tools (like supported `vim` plugin) push most of us to use
logging techniques to inspect and track down issues.

In this article, I will demonstrates how you can use `vim` and `lldb` to debug
a go application. Before that you should make the application capable for debugging.

### Prerequisites
You should compile the application by emitting the debug information and disable inlining.
The `-N` flag enables debug information emitting and `-l` disables compiler inlining:

```
go build -gcflag '-N -l' <file_or_package>
```

The compiled binary supports [DWARF](https://en.wikipedia.org/wiki/DWARF) debugging
data format, which is supported by debuggers as [GDB](https://en.wikipedia.org/wiki/GNU_Debugger) 
and [LLDB](https://goo.gl/fgiab0).

You should install `vim-lldb` plugin from [here](https://github.com/gilligan/vim-lldb).
The easiest way to install it by using package manager as `bundle`. You should
add `Bundle "gilligan/vim-lldb"` in your bundle list.


Then you can use the following commands and shortcuts:

- `Ltarget` specifies the binary that we are going to debug
- `Lbreakpoint` sets a breakpoint in file on particular line (`<leader>lb`)
- `Lrun` starts the debugger (`<leader>lr`)
- `Lstep` does a source level single step in the current thread. (`<leader>ls`)
- `Lfinish` steps out of the currently selected frame. (`<leader>lo`)
- `Lnext` does a source level single step over in the current thread. (`<leader>ln`)
- `Lcontinue` continues execution until next breakpoint. (`<leader>lc`)
- `Lprint` evaluates a generalized expression in the current frame. (`<leader>lp`)
- `Lframe variable` prints the frame local variables (`<leader>lv`)

You can add my extra shortcuts in your `.vimrc` file:

```
nnoremap <silent> <leader>lr :Lrun<CR>
nnoremap <silent> <leader>lb :Lbreakpoint<CR>
nnoremap <silent> <leader>lc :Lcontinue<CR>
nnoremap <silent> <leader>ln :Lnext<CR>
nnoremap <silent> <leader>ls :Lstep<CR>
nnoremap <silent> <leader>li :Lstepin<CR>
nnoremap <silent> <leader>lo :Lfinish<CR>
nnoremap <silent> <leader>lp :Lprint<CR>
nnoremap <silent> <leader>lv :Lframe variable<CR>
```

Lets have the following source code that we are aiming to debug:

```
// main.go
package main

import "fmt"

type User struct {
	FirstName string
	LastName  string
}

func (user User) String() string {
	return fmt.Sprintf("%s %s", user.FirstName, user.LastName)
}

func main() {
	user := User{
		FirstName: "John",
		LastName:  "Smith",
	}

	message := FormatMessage(user, "Golang Weekly Newsletter #756")

	for index := 0; index < 3; index++ {
		fmt.Printf("Sending #%d message with %s\n", index, message)
	}
}

func FormatMessage(user User, message string) string {
	return fmt.Sprintf("body: %s by %s", message, user.String())
}

```

1. Compile the application:
	```
	$ go build -gcflag '-N -l' -o app main.go
	```
2. Open the source code:
	```
	$ vim main.go
	```
3. Set the `LLDB` target to be the compiled binary:
	```
	:Ltarget app
	```
4. Set a breakpoint on desired line by using `Lbreakpoint` command or `<leader>lb`
shortcut.
5. Then you can run the application in debug mode by using `Lrun` command or `<leader>lr` shortcut.

You can watch the illustrates steps in the following video:

[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/7Sw29wGbsJY/0.jpg)](http://www.youtube.com/watch?v=7Sw29wGbsJY)

### Conclusion 

Even though `LLDB` is very powerful and commonly used debugger, it does not work properly in the context of `Go`.
It crashes sometimes. It made for `C\C++` not for `Go`.  It cannot follow the execution 
flow properly due to the fact that the debugger is not aware about `defer` statement. 
In addition sometimes `go scheduler` changes the context of current executing `go routine`. 
It changes the stack frame by moving `go routine` from one thread to another.
