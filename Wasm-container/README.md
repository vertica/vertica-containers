[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](https://opensource.org/licenses/Apache-2.0)

# Vertica Wasm UDx experimental container

[Vertica](https://www.vertica.com/) is a massively scalable analytics data warehouse that stores your data and performs analytics on it all in one place.

This repository creates an image that makes it reasonably easy to experiment with developing User-Defined Extensions (UDxes) for Vertica using WebAssembly.

Vertica has long supported UDxes in a number of languages:

- C++
- Java
- Python
- R

Java, Python and R UDxes are loaded into auxiliary programs implementing the appropriate runtime.  C++ UDxes may be loaded into a separate program (known as "fenced"), or may be linked directly into the Vertica binary (known as "unfenced").  (All Java, Python, and R UDxes are fenced.)

Unfenced UDxes have a performance advantage over fenced since functions are implemented as function calls instead of as remote procedure calls.  There is a corresponding savings in the cost of data movement (data are pushed onto or popped off of the stack instead of transmitted through a socket).  However, Unfenced UDxes are a little risky: a bug in an unfenced UDx risks crashing the Vertica server.

Safe programming in C++ can be a challenge.

Enter Web Assembly (Wasm).  Wasm code runs in a sandbox with clearly-defined interaction between the Wasm and the host program.  Wasm code accesses memory in its sandbox, and cannot access memory outside its sandbox.  

Supporting Web Assembly IDxes lets us support unfenced UDxes in any language that can compile to Wasm, confident that the user-defined code cannot corrupt Vertica's data structures.

For details about developing Vertica UDxes, see [Extending Vertica](https://www.vertica.com/docs/latest/HTML/Content/Authoring/ExtendingVertica/ExtendingVertica.htm).

This container just packages WebAssembly tools for generating .wasm files in C and Rust, though we anticipate adding other languages (particularly Golang).

## Prerequisites
- [Docker Desktop](https://www.docker.com/get-started) or [Docker Engine](https://docs.docker.com/engine/install/).
- `make`: a program for building programs.

# Supported Platforms

We use an Ubuntu container primarily because we found it easier to install the WebAssembly tools we need in Ubuntu.

# Overview

This container packages:

- the Vertica SDK for developing UDxes
- a Vertica runtime to use to test your UDx
- `llvm` --- the `llvm` compiler components capable of creating WebAssembly output 
- `emscripten` --- a compiler package for compiling to WebAssembly
- `wasmer` --- WebAssembly tools
- `rust` --- a version of the Rust compiler that can compile to WebAssembly
- some scripts to make it easier to use the contents of this container
- `/usr/WebAssembly/vertica` --- a collection of functions exploiting WebAssembly to make unfenced Vertica UDxes in C and Rust.  This is a work in progress.  Also included are some "scaffolding" --- functions written to explore features of the C Wasm API.

# Building the container

The container is built using the command `make`.  `make` will create a Docker image called `wasm-playground:ubuntu`.

# Using the container

## Setting up your Web Assembly toolbox

To use this installation, before you run the container interactively, use it to run the shell script `/usr/WebAssembly/tools/copy-template-to-sandbox` with an argument specifying the location of your WebAssembly toolbox (refered to as `$WASMHOME` above), .e.g.,

```shell
# Define $WASMHOME for this inside-the-container shell
user_id=`id -u`
export WASMHOME=$HOME/WebAssembly
mkdir $WASMHOME
docker run \
        -e HOME \
        -u $user_id \
        -v $HOME:$HOME:rw \
        vwasmsdk:ubuntu-12.0.1-0 \
        $WASMHOME \
        "/usr/WebAssembly/template/tools/copy-template-to-sandbox $WASMHOME"
```
(The arguments to `docker` will be explained in detail in the next section.)

The above puts the `.cargo` and `.wasmer` directories into `$WASMHOME`.  Putting these into `$WASMHOME` instead of your home directory avoids interfering with any non-wasm Rust work you might be doing.  It also creates the `$HOME/WebAssembly/.env-setup` file.

After you have used the above command to create your `$WASMHOME` toolbox, you can run the container interactively.

## Launching an interactive shell to do Web Assembly development

The shell-script `./vwasm-bash` starts an interactive shell inside the container.  

When executing a shell inside the container, you need to set up your in-container PATH so the shell can find the `wasmer` and `rust` installations in the container.

`wasmer` and rust installations are designed to be placed in a user's home directory.  This `copy-template-to-sandbox` command copied them to `$WASMHOME`.

To set up your environment appropriately, run
```shell
source $WASMHOME/.env-setup
```

`./vwasm-bash` does the following:

```shell
user_id=`id -u`
SANDBOX=/data/dmankins/WebAssembly
docker run \
        -u $user_id \
        -v $SANDBOX:$SANDBOX \
        -v $HOME:$HOME \
        -e HOME \
        -it \
        vwasmsdk:ubuntu-12.0.1-0 
```

The `docker run` options are:

- `-u $user_id`: By initializeing `user_id` with the output of the `id -u` command, processes inside the container run with your UID so you can edit and modify files in your working directories.
- `-v $SANDBOX:$SANDBOX`: mounts the host computer's `$SANDBOX` directory inside the container with the name `$SANDBOX` (you must, of course, define `$SANDBOX` first).  This argument is optional (e.g., if your sandbox is in your `$HOME` directory).
- `-v $HOME:$HOME`: mounts the host computer's `$HOME` directory inside the container with the naem `$HOME`.
- `-e HOME` : passes the `$HOME` environment variable into the interactive shell in the container
- `-it`: run an interactive shell inside the container
- `wasm-playground:ubuntu`: the name of the container image

### An annoying thing about Rust

The primary role of the container is to provide a place to install
those components that require privileges to install.

Rust and wasmer are designed to be installed privately, in one's
home directory.

While we play games in the Dockerfile with installing those tools in
`/usr/WebAssembly/template`, and provide a script to copy them into
one's home directory, the changes don't always seem to stick between
container invocations.  This manifests for me as the following:

   error: toolchain 'stable-x86_64-unknown-linux-gnu' is not installed

when I try to use `rustc` to compile a rust file to wasm.

So, there is a `./reinstall-rust` command provided to run inside the
container to run the rust installation commands  

# An experiment with compiling to Wasm

In the container's `/usr/WebAssembly/vertica` directory are some simple files used as a proof-of-concept for creating unfenced Vertica UDxes in C and Rust using Wasm.

Copy the directory to your own sandbox (so the files are in a directory you can modify).

There is a `Makefile` with commands to build the example programs.

Make targets are:

- `clean`: remove the constructed files
- `wasmer-hello`: compile a simple "hello, world" C program to Wasm
- `run-hello`: execute the `wasmer-hello` program by specifying the dynamically-linked library path.
- `sum.rs.wasm`: compile the Rust module `sum.rs` to a Wasm module that can be linked into a Vertica UDx.
- `sum.c.wasm`: compile the C `sum.c` module to a Wasm module that can be linked into a Vertica UDx.
- `udx_wasm.o`: compile the C++ wrapper for Wasm UDxes.
- `libudx_wasm.a`, `libudx_wasm.so`: static and dynamic libraries containing `udx_wasm.o`
- `abstract_runner`: a test program that loads a `wasm` file containing a function that accepts two 32-bit integers and returns one 32-bit integer.

- `run_abstract_runner`: invokes `abstract_runner` with both the `sum.c.wasm` and `sum.rs.wasm` files, invoking the `sum` function in them.  Prints "happy, happy, joy, joy" if the module returns the sum of the two arguments the program passes in.

# An experiment with creating Wasm UDxes

In the `examples/UDx` directory you will find prototype UDxes written
in C-compiled-to-Wasm and Rust-compiled-to-Wasm.

There is a `Makefile` in that directory with the following `make`
targets:

- cWasmUDxlib --- A UDx which loads a `sum` function from `sum.c.wasm`
- rustWasmUDxlib --- A UDx which loads a `sum` function from `sum.rs.wasm`
- nonWasmUDxlib --- A UDx which does the `sum` calculation directly

These UDxes consist largely of boilerplate.  There are different files
to make it easy to compare the performance of the three UDx
implemenations against one another in the same Vertica instance.

### An example Rust UDx

Here is a sample Rust implementation of a simple `sum` function:

```rust
#[no_mangle]
pub extern "C" fn sum(a: u32, b: u32) -> u32 {
    return a + b;
}
```

Tthec corresponding C++ boilerplate is in
`examples/UDx/rustWasmUDx.cpp`.  For an explanation of the
boilerplate, see [Extending
Vertica](https://www.vertica.com/docs/latest/HTML/Content/Authoring/ExtendingVertica/ExtendingVertica.htm).

What we're doing here is telling Vertica that we've produced a C++
UDx.  That the C++ UDx happens to load and interpret another file to
do the bulk of its computation isn't important to Vertica.

As with other C++ UDxes, one creates a factory class (here called
`rustWasmUDx_sumFactory`) and a function class (here called `rustWasmUDx_sum`).  In this case, the factory class exists
primarily to tell Vertica the function prototype for the
`rustWasmUDx_sum` function --- that it takes two integer arguments
(`argTypes.addInit()`) and returns an integer `returnType.addInt()`).

Function classes can be complicated, but for our simple function, it
has three methods:

- `setup`: performed once when Vertica is informed of the function.
  In this case we call `udx_get_wasm_state()` to get a `wasm_state` to
  hold information about the Wasm C API, and to attach that state to
  the Wasm bytecode file with `udx_setup()`.  Note that `udx_setup`
  binds this `wasm_state` to the "sum" function.

- `destroy`: called to deallocate the `wasm_state` data structures.

- `processBlock`: called once for each row of the table being
  processed.  In this case, the function reads the arguments (using
  `argReader.getIntRef`, then calls the function with the two
  arguments (using `udx_call_func_2i_1i`, since this is a
  2-int-argument, 1-int-return function, and then uses
  `resWriter.setInt` to return the result.  `resWriter.next` is used
  to indicate that we've written all the results for this row, and
  `argReader.next` is used to read the next row.

# Loading and executing the UDx

## Starting a test Vertica using the container

Having defined `$WASMHOME` in my login shell, I start a Vertica to use
in testing my UDx in the following way:

```shell
VERTICA_VERSION=12.0.1-0 VWASM_MOUNT=$WASMHOME ./vwasm-vertica 
```
This runs teh `vwasm-vertica` shell script with the following
environment variables defined:

- `VERTICA_VERSION` -- what Vertica version the container was built
  with.  If you look inside the shell script you'll see that the script
  has a default value for the `VERTICA_VERSION`:
  `${VERTICA_VERSION:-12.0.1-0}` (in this case, defining
  `VERTICA_VERSION` on the command line is redundant).

- `VWASM_MOUNT` -- is a list of directories, separated by colons, that
  the container should mount.

When the `vwasm-vertica` container starts, it will print a message:

```
Run
      docker logs vwasmsdk-vertica
to view startup progress

Don't stop container until above command prints 'Vertica is now running'
To stop:
    docker stop vwasmsdk-vertica

When executing outside of a VWasm container, you can connect to this vertica
using
    vsql -p 8331

If executing inside a VWasm container (where you did your Wasm development),
just 'vsql' should suffice

```

The port number in `vsql -p 8331` changes with each invocation, and is only
meaningful outside of any containers.  If you start `vsql` from 
within a `vwasm-bash` shell you don't need to specify the port number
(since, inside the container, Vertica's default port number is
available with its default "name", 5433).

It will take several seconds for Vertica to start (longer the first
time you start the container, as it will be initializing the
database).  `docker log vwasmsdk-vertica` will give you a peek into
the container startup.

You can leave the container running for a long time as you test, you
don't need to start and stop it.

## Loading your UDx into your test Vertica

### C version

The C UDx is loaded in the following fashion:

```sql
\set clibfile '\'PATH_TO_WASM/examples/UDx/build/cWasmUDx.so\''
CREATE OR REPLACE LIBRARY cWasmUDx AS :clibfile LANGUAGE 'C++';
```

The first line defines the absolute path of the `cWasmUDx.so` file as
a `vsql` variable (substitute the pathname of your `.so` file).

The second line has Vertica initialize the library.

```sql
CREATE OR REPLACE FUNCTION cWasmUDx_sum AS LANGUAGE 'C++'
       NAME 'cWasmUDx_sumFactory' LIBRARY cWasmUDx NOT FENCED;
```
This command tells Vertica the name of the factory function.  The
factory function, once invoked, will tell Vertica the name and
prototype of the actual function.

### Rust version

The Rust UDx is loaded in the following fashion:

```sql
\set rustlibfile '\'PATH_TO_WASM/examples/UDx/build/cWasmUDx.so\''
CREATE OR REPLACE LIBRARY rustWasmUDx AS :rustlibfile LANGUAGE 'C++';
```

The first line defines the absolute path of the `rustWasmUDx.so` file as
a `vsql` variable (substitute the pathname of your `.so` file).

The second line has Vertica initialize the library.  Yes, even though
the Wasm came from Rust, as far as Vertica is concerned this is a C++ UDx.

```sql
CREATE OR REPLACE FUNCTION rustWasmUDx_sum AS LANGUAGE 'C++'
       NAME 'rustWasmUDx_sumFactory' LIBRARY rustWasmUDx NOT FENCED;
```

## Invoking the function

First, creat a table to operate on:

```sql
create table t2 (a int, b int);
copy t2 from stdin delimiter ',' direct;
3, 1
4, 1
5, 9
2, 6
\.
```

Now we can invoke the functions on the table:

```sql

select cWasmUDx_sum(a, b) from t2;
select rustWasmUDx_sum(a, b) from t2;
select nonWasmUDx_sum(a, b) from t2;
select a + b from t2;
```
The first two SQL commands will add the `a` and `b` columns of the table `t2`
together, returning a sum for each row of the table.

The third SQL command uses the UDx-without-Wasm `nonWasmUDx.so`
function to establish a "cost of UDx" baseline.

The fourth SQL command does the same calculation using native SQL.

To make things a little more interesting, create a table `t3` with,
say, a million rows.  Then you can run these commands:

```sql

\timing on
create table ct4 as select cWasmUDx_sum(c0, c1) from t3;
create table rst4 as select rustWasmUDx_sum(c0, c1) from t3;
create table nont4 as select nonWasmUDx_sum(c0, c1) from t3;
create table dt4 as select c0 + c1 from t3;
\timing off
```

When I run these on my machine, I get results that show an 8% penalty
from raw SQL to the `nonWasm` (the "UDx tax") and a 10% penalty going
from pure-C++ UDx (`nonWasm`) to either of the Wasm-based UDxes (on my
system the Rust module is slightly faster than the C module, for some
reason). 

# Shortcomings of this implementation

The following are shortcomings of this Proof-of-concept implementation that we plan to
address in the near future

#### Should generate the C++ boilerplate automatically 

The UDx for using `sum.c.wasm` is the same as for `sum.rs.wasm`, save for:
- a change in the name of the Wasm file to load
- the name of the class changes
- the name of the factory class changes

#### `udx_call_func_2i_1i`

(C++ has mangled names for close to forty years, perhaps we can do
better?)  If we're generating boilerplate, the `udx_call_func` routine
can perhaps be inlined instead of a function call, which means we
don't have to tiptoe around C calling conventions.

#### Absolute path on all nodes needed for `.wasm` files

Vertica is a distributed database that runs on a cluster of machines.
Copies of the Wasm files need to be at a well-known place in all nodes
of the cluster.  While Vertica has a mechanism for copying library
files around, it does not appear to work for non-library files (such
as `sum.c.wasm`, `sum.rs.wasm`).

So: you need to place your Wasm code on all the nodes with the same
pathname on each node.  

Worse: you need to compile the absolute pathname of the Wasm code into
your UDx.  You will see these paths specified by definitions of the
`SUM_C_WASM` and `SUM_RS_WASM` `make` variables.

(One might work around these pathname shenanigans by using `wasm2wat`
to "decompile" the Wasm code to a text form, which is then compiled as
a C-string in the C++ source, then use the `wasmer` C-API to convert
the WAT to Wasm binary.)

For fixed Vertica installations this is not so terrible, but Vertica
can be run on the cloud, with nodes being added and dropped
dynamically.  Vertica has mechanisms to maintain UDx dependencies,
they just need to be modified to permit their use on Wasm files.



