+++
comments = "yes"
date = "2015-12-06T08:47:15Z"
share = "yes"
title = "Expose application metrics with expvar"
categories = ["programming languages"]
tags = ["go", "metrics", "expvar"]

+++

To determine whether your application meets its performance objectives and to
help identify bottlenecks, you need to measure your program's performance
and collect metrics. They tend to be response time, throughput, and resource
utilization (how much CPU, memory, disk I/O, and network bandwidth your
application consumes while performing its tasks).

#### Metrics

Metrics provide information about how close your program is to your
performance goals. In addition, they also help you identify problem areas and
bottlenecks within your application. Metric types could be grouped under
the following categories:

- `Network` metric related to network bandwidth usage.
- `System` metrics are related to processor, memory, disk I/O, and network I/O.
- `Platform` metrics are related to execution runtime.
- `Application` metrics include custom performance counters.

#### How Measuring Applies to Life Cycle

You should start to measure as soon as you have a defined set of performance
objectives for your program. This should be early in the application design
phase.

You must continue to measure application performance throughout the
life cycle to determine whether your application is trending toward or away
from its performance objectives.

#### Exposing and collecting metrics in Golang

`Golang` provides a variety of packages for exposing metrics, application
monitoring and performance analysis.

In the article, we will explore `expvar` package that can provide command line
arguments, allocation stats, heap stats and garbage collection metrics. In
addition, it allows you to define variables to export and publish over http.

The package should be imported to register http handler into the default http mux:

```
import _ "expvar"
```

Also it publishes 'cmdline' and 'memstats' variables for the current process.
If you don't run an HTTP server, you should the following code snippet to make
available an HTTP endpoint:

```
http.ListenAndServe(":8080", http.DefaultServeMux)
```

You could access the exported variables on `http://127.0.0.1:8080/debug/vars`:

```
{
  "cmdline": [
    "/var/folders/74/8nd9swvj2rs7j3phs34tw7lm0000gq/T/go-build109647759/command-line-arguments/_obj/exe/main"
  ],
  "memstats": {
    "Alloc": 204728,
    "TotalAlloc": 204728,
    "Sys": 4720888,
    "Lookups": 6,
    "Mallocs": 887,
    "Frees": 0,
    "HeapAlloc": 204728,
    "HeapSys": 1671168,
    "HeapIdle": 966656,
    "HeapInuse": 704512,
    "HeapReleased": 0,
    "HeapObjects": 887,
    "StackInuse": 425984,
    "StackSys": 425984,
    "MSpanInuse": 9520,
    "MSpanSys": 16384,
    "MCacheInuse": 9664,
    "MCacheSys": 16384,
    "BuckHashSys": 1443053,
    "GCSys": 65536,
    "OtherSys": 1082379,
    "NextGC": 4194304,
    "LastGC": 0,
    "PauseTotalNs": 0,
    "PauseNs": [],
    "PauseEnd": [],
    "NumGC": 0,
    "GCCPUFraction": 0,
    "EnableGC": true,
    "DebugGC": false,
    "BySize": [
      {
        "Size": 17664,
        "Mallocs": 0,
        "Frees": 0
      }
    ]
  }
}
```

In addtion exported variables could be accessed by using `expvar.Get` function:

```
memstatsFunc := expvar.Get("memstats").(expvar.Func)
memstats := memstatsFunc().(runtime.MemStats)
fmt.Println(memstats.Alloc)
```

If you want to collect all exported variables you should consider using `expvar.Do`
function which invokes the provided callback function for every variable in thread
safe way. The `expvar.KeyValue` type has `Key` and `Value` field that returns the
variable name and variable value.

The sample below prints out all exported variables:

```
expvar.Do(func(variable expvar.KeyValue) {
	fmt.Printf("expvar.Key: %s expvar.Value: %s", variable.Key, variable.Value)
})
```

The package allows exporting of integers, floats and string variables.
```
var (
	orderCounter      *expvar.Int
	balanceCounter    *expvar.Float
	transactionMetric *expvar.String
)

func init() {
	orderCounter = expvar.NewInt("counter")
	balanceCounter = expvar.NewFloat("balance")
	transactionMetrics = expvar.NewString("transaction")
}
```

> Note that it's recommended to register the new exported variables in the init
> function of your package.

Then you should the variables in the similar way as their counterparts:

```
// Adds an integer value to expvar.Int counter
orderCounter.Add(2)
// Sets a float value to expvar.Float metrics
balanceCounter.Set(1000)
// Sets a string to expvar.String metrics
transactionMetrics.Set("this is my transaction")
```

If you want to do something more complex you should use the `expvar.Publish`
function which register any type that obeys `expvar.Var` interface:

```
type Var interface {
  String() string
}
```

Lets define our own metrics that exports `time.Time` type:

```
type TimeVar struct {
	value time.Time
}

// Sets a time.Time as time metrics value
func (v *TimeVar) Set(date time.Time) {
	v.value = date
}

// Adds a time.Duration to current time metrics value
func (v *TimeVar) Add(duration time.Duration) {
	v.value = v.value.Add(duration)
}

// Converts the TimeVar metrics to string
func (v *TimeVar) String() string {
	return v.value.Format(time.UnixDate)
}
```

Then we should use `expvar.Publish` function to export this type:

```
var (
	timeMetrics        *TimeVar
)

func init() {
	timeMetrics = &TimeVar{value: time.Now()}
	expvar.Publish("Time", timeMetrics)
}
```

We can use the exported variable in the following way:

```
// Adds an hour to the initial time metrics value
timeMetrics.Add(1 * time.Hour)
```

#### Verdict

Having set metrics objects early in your application's design phase, you
begin to measure by collecting them. You continue to measure throughout the
application life cycle to determine whether your application's performance is
trending toward or away from its performance goals.

In `Golang` this goal is considered as important part of every application. The
ease of use and out of the box support give us confidence to build scalable
and performan programs.
