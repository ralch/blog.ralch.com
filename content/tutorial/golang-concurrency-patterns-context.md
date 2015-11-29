+++
comments = "yes"
date = "2015-11-29T08:50:48Z"
share = "yes"
title = "Concurrent patterns in Golang: Context"
categories = ["programming languages", "design patterns"]
tags = ["go", "concurrency"]
+++

#### What is concurrency?

Concurrent applications have multiple computations executing during overlapping
periods of time. Respectively sequential programs in which no computations can
be executed in overlapping periods of time.

#### Getting started with `Context` package

The [Context](https://godoc.org/golang.org/x/net/context) package is responsible
for signal cancelation and operation deadlines for processes and server requests.

The package has an `context.Context` interface:

```
type Context interface {
	Deadline() (deadline time.Time, ok bool)
	Done() <-chan struct{}
	Err() error
	Value(key interface{}) interface{}
}
```

The interface provides four functions to observe the context state:

- `Deadline` returns the time when work done on behalf of this context should be canceled. It returns `false` when no deadline is set.
- `Done` returns a channel that's closed when work done on behalf of this context should be canceled.
- `Err` returns a non-nil error value after Done is closed. It returns `Canceled` if the context was canceled or `DeadlineExceeded` if the context's deadline passed.
- `Value` returns the value associated with this context for key, or nil

There are two types of contexts:

- `context.TODO` should be used `context.TODO` when it's unclear which Context to use.
- `context.Background` is typically used by the main function, initialization, and tests, and as the top-level Context for incoming requests.

Both are never canceled, have no values, and has no deadline.

In order to setup a deadline you should use one of the following constructors:

- `context.WithDeadline` returns a copy of the parent context with the deadline adjusted
to be no later than a specified `time.Time`. The returned context's Done
channel is closed when the deadline expires, when the returned cancel function
is called, or when the parent context's Done channel is closed, whichever
happens first.
- `context.WithTimeout` just calls `context.WithDeadline` for particular `time.Duration`

If you want to have a context that could be canceled only, you should use
`context.WithCancel` function. Canceling this context releases resources
associated with it, so code should call cancel as soon as the operations
running in this Context complete.

#### `Context` package in practice

Lets have an application that process a payment transactions like that:

```
type Payment struct {
	Payee  string
	Amount float64
}
```

The program is asking the user to `[C]onfirm` or `[A]bort` his payment transaction
within a 1 minute. If he does not anything, it will be terminated automacitally.

The `ProcessPayment` function is started as go routine that is waiting for user
input.

```
go ProcessPayment(ctx, &Payment{
	Payee:  "John Doe",
	Amount: 128.54})
```

The function is observing the context state to terminate, cancel or proceed the
payment:

```
func ProcessPayment(ctx context.Context, payment *Payment) {
	confirmed := ctx.Value("confirmed").(chan struct{})

	for {
		select {
		case <-confirmed:
			fmt.Printf("Your payment of %f GBP has been completed succefully.\n", payment.Amount)
			return
		case <-ctx.Done():
			if ctx.Err() == context.Canceled {
				fmt.Printf("Your payment transaction is canceled. The amount of %f GBP has been refunded.\n", payment.Amount)
				return
			} else if ctx.Err() == context.DeadlineExceeded {
				fmt.Println("Your payment transaction expired. You can complete it later.")
				os.Exit(0)
			}
		default:
			time.Sleep(1 * time.Second)
		}
	}
}
```

The confirmation channel is used to notify the function that the payment should
be processed. If the `Done` channel returns a value before that the operation
is aborted due to canceleation or exceeded deadline.

The `ctx` variable is a background context that has a deadline of 1 minute:

```
var (
	ctx    context.Context
	cancel context.CancelFunc
)

confirmed := make(chan struct{})
ctx = context.WithValue(context.Background(), "confirmed", confirmed)
ctx, cancel = context.WithTimeout(ctx, 1*time.Minute)
```

The full implementation of the example could be downloaded from [here](http://bit.ly/1Mrqkeo).

#### Recommended usage

Usually the incomming request should create a `context.Context` object that underlying
algorithm comply with.

- Do not store Contexts inside a struct type; instead, pass a `Context` explicitly to each function that needs it.
- Do not pass a nil Context, even if a function permits it. Pass context.TODO if you are unsure about which Context to use.
- Do not use `context.WithValue` for passing optional parameters to functions. Use it for request data only.

#### Working with HTTP Request

On top of `Context` API there is a [ctxhttp](https://godoc.org/golang.org/x/net/context/ctxhttp) package that
provides helper functions for performing context-aware HTTP requests. All of them are calling internally
the `Do` function that is performing an http request that could be canceled or expired via the provided context.

```
func Do(ctx context.Context, client *http.Client, req *http.Request)
func Get(ctx context.Context, client *http.Client, url string)
func Head(ctx context.Context, client *http.Client, url string)
func PostForm(ctx context.Context, client *http.Client, url string, data url.Values)
```


