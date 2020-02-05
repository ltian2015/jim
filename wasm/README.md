# Jim

Jim is a DSL (domain specific language) for interacting with home automation devices.
It allows users to create rules and scenes for how devices should behave given various events that can occur.


## Design

Jim is an abstaction over an event bus.
Users can listen for events and trigger new behavior when an event occurs.
The events can be sourced from any external system.
The expectation is that an MQQT bus following the smarthome-mqtt spec is used.

## Implementation

Jim is implemented on top of WASM.
Jim source code is compiled to WASM and a runtime executes the compiled modules.

### Runtime

The runtime must provide the following functions to the compiled WASM modules:

* get : (path: i64, ) -> i64 - Get returns the string value of the given key. See note about how strings are handled.
* set : (path: i64, value: i64) -> () - Set stores the value at the provided path.
* now : () -> i64 : Now reports the current time as nanoseconds since the epoch.
* at : (at: i64, func: i32) -> () : At schedules the function to run at the specified time as a unix epoch in nanoseconds.
* watch : (path: i64, value: i64, func: i32) : Watch registers a watcher for when the given path is equal to a value the function will trigger.
* wait : () -> i32 - Wait blocks until an event has occurred on the bus. The return value is the table index of the next function to call.
* exec : (func: i32) -> () - Exec calls the function (as a table index) and returns.
* loop: () -> () - Loop calls wait and exec in a loop until the exit signal is recieved
* alloc: () -> i32 - New returns an address that has 1024 bytes available
* free: (i32) -> - Marks the previously used address as free.

The runtime should implement an event loop that calls `wait` followed by `exec` with the return value of `wait`.
If `wait` returns a negative value the loop should exit:

```
while:
    f = wait()
    if f < 0:
        break
    exec(f)
```


Maybe this loop can be compiled into the modules?

#### Precompiled runtime

A precompiled runtime written using a pure WASM implementation is provied for the following functions:

* exec
* loop
* alloc
* free



#### Strings

What follows is a hack to implement very basic strings inside of the WASM module.
Strings are represented as an i32 offset and an i32 length. Since we can't easily represent tuples nor can we easily return multiple values we choose to implement strings as a single i64.
The first 32 bits are the offset and the last 32 bits are the length.
Additionally since values are little endian 

Memory is allocated in 1024 byte chunks. As such the maximum string length is 1024 bytes.
