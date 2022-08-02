[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](https://opensource.org/licenses/Apache-2.0)

# Vertica Wasm UDx experimental container

[Vertica](https://www.vertica.com/) is a massively scalable analytics data warehouse that stores your data and performs analytics on it all in one place.

This repository creates an image that provides tools to experiment with developing User-Defined Extensions (UDxs) for Vertica using WebAssembly.

For additional details about developing Vertica UDxs, see [Extending Vertica](https://www.vertica.com/docs/latest/HTML/Content/Authoring/ExtendingVertica/ExtendingVertica.htm).

Note that this container just packages WebAssembly tools for generating .wasm files in C, C++, and Rust.  To do actual UDx development requires a Vertica SDK (which is packaged with your Vertica version).  It is admittedly a little clumsy to hop into this container to compile to Wasm, then move to another environment to link the Wasm into an actual UDx, but this is (at the moment), just a minimal proof-of-concept.

## Prerequisites
- [Docker Desktop](https://www.docker.com/get-started) or [Docker Engine](https://docs.docker.com/engine/install/).
- `make`: a program for building programs.

# Supported Platforms

We use an Ubuntu container primarily because we found it easier to install the WebAssembly tools we need in Ubuntu.

# Overview

This container packages:

- `llvm` --- the `llvm` compiler components capable of creating WebAssembly output 
- `emscripten` --- a compiler package for compiling to WebAssembly
- `wasmer` --- WebAssembly tools
- `rust` --- a version of the Rust compiler that can compile to WebAssembly
- some scripts to make it easier to use the contents of this container
- `/usr/WebAssembly/vertica` --- a collection of functions exploiting WebAssembly to make unfenced Vertica UDxes in C and Rust.  This is a work in progress.  Also included are some "scaffolding" --- functions written to explore features of the C Wasm API.

# Building the container

The container is built using the command `make`.  `make` will create a Docker image called `wasm-playground:ubuntu`.

# Using the container

## Setting up the container environment

## Setting up the environment to use Wasm tools inside the container

When executing a shell inside the container, you need to set things up to find the `wasmer` and `rust` installations in the container.

`wasmer` and rust installations are designed to be placed in a user's home directory.  This Dockerfile places them in a directory called `/usr/WebAssembly/template/.cargo` (Rust) and `/usr/WebAssembly/template/.wasmer` (`wasmer`).

To use this installation, before you the container interactively, use it to run the shell script `/usr/WebAssembly/tools/copy-template-to-sandbox` with an argument specifying the location of your WebAssembly toolbox (refered to as `$WASMHOME` above), .e.g.,

```shell
# Define $WASMHOME for this inside-the-container shell
user_id=`id -u`
WASMHOME=$HOME/WebAssembly
mkdir $WASMHOME
docker run \
        -e HOME \
        -u $user_id \
        -v $HOME:$HOME:rw \
        wasm-playground:ubuntu \
        `/bin/pwd` \
        "/usr/WebAssembly/template/tools/copy-template-to-sandbox $WASMHOME"

export WASMHOME
docker run \
        -e HOME \
        -e WASMHOME \
        -u $user_id \
        -v $HOME:$HOME:rw \
        wasm-playground:ubuntu \
        "/usr/WebAssembly/template/tools/copy-template-to-toolbox"
```
(The arguments to `docker` will be explained in detail in the next section.)

The above puts the `.cargo` and `.wasmer` directories into `$WASMHOME`.  Putting these into `$WASMHOME` avoids interfering with any non-wasm Rust work you might be doing.  It also creates the `$HOME/WebAssembly/.env` file.

After you have created your `$WASMHOME` toolbox, you can run the container interactively.

## Running the container interactively 

### Launching the container

I start the container interactively using a command like this:

```shell
user_id=`id -u`
SANDBOX=/data/dmankins/WebAssembly
docker run \
        -u $user_id \
        -v $SANDBOX:$SANDBOX \
        -v $HOME:$HOME \
        -e HOME \
        -it \
        wasm-playground:ubuntu
```

The arguments to `docker` are:

- `-u $user_id`: By initializeing `user_id` with the output of the `id -u` command, processes inside the container run with your UID so you can edit and modify files in your working directories.
- `-v $SANDBOX:$SANDBOX`: mounts the host computer's `$SANDBOX` directory inside the container with the name `$SANDBOX` (you must, of course, define `$SANDBOX` first).  This argument is optional (e.g., if your sandbox is in your `$HOME` directory).
- `-v $HOME:$HOME`: mounts the host computer's `$HOME` directory inside the container with the naem `$HOME`.
- `-e HOME` : passes the `$HOME` environment variable into the interactive shell in the container
- `-it`: run an interactive shell inside the container
- `wasm-playground:ubuntu`: the name of the container image

### Setting up the in-container environment

In the container interactive shell, create the necessary path, Rust and `wasmer` environment by sourcing `$WASMHOME/.env-setup`:

```shell
# .env-setup requires $WASMHOME to be defined since it defines
# environment variables that depend on its value
source $WASMHOME/.env-setup
```

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



