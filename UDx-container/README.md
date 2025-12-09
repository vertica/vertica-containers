[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](https://opensource.org/licenses/Apache-2.0)

# Vertica User-Defined Extensions (UDx) Container

[Vertica](https://www.vertica.com/) is a massively scalable analytics data warehouse that stores your data and performs analytics on it all in one place.

This repository creates an image that provides tools to develop C++ User-Defined Extensions (UDxs) for Vertica.

For additional details about developing Vertica UDxs, see [Extending Vertica](https://www.vertica.com/docs/latest/HTML/Content/Authoring/ExtendingVertica/ExtendingVertica.htm).

## Prerequisites
- [Docker Desktop](https://www.docker.com/get-started) or [Docker Engine](https://docs.docker.com/engine/install/)
- Vertica RPM or DEB file
- A running Vertica database: In case you want to test your UDx
- [Python 3](https://www.python.org/downloads/)

# Supported Platforms

Container techology provides the freedom to run environments independently of the host operating system. For example, you can run an AlmaLinux container on an Ubuntu workstation, and vice versa.

Vertica provides a Dockerfile for different distributions so that you can create an containerized development environment that matches your production environment. By

## AlmaLinux
- 8

## Ubuntu
- 20.04


# Overview

The Vertica UDx container packages the binaries, libraries, and compilers required to create C++ Vertica UDx extensions. Use this repository with your Vertica binary to develop UDxs on any host system that meets the [Prerequisites](#prerequisites).

In addition, this repository provides `vsdk-*` commmand line tools to simplify the development process. You can develop UDxs on your host machine, compile them within the UDx container, and then save the object files on your host machine to load into Vertica.

Use your running database to test the UDx.

# Build the UDx container

Use the repository [Makefile](Makefile) to build your container. The `Makefile` requires that you store a Vertica RPM or DEB file in the top level of the `UDx-container/` directory in your cloned repository. The container inherits the privileges and user ID from the user executing the container.

## Build variables

You can include build variables in the build process to customize the container. The following table describes the available variables:

| Name                      | Definition |
|:--------------------------|:-----------|
| `CONTAINER_OS_TAG` | The container operating system distribution, either `alma` or `ubuntu`. This variable is required to build a container that runs an OS that is different from the host OS. |
| `PACKAGE` | When there is more than one Vertica RPM or DEB file in the top-level directory, this variable specifies which file to use in the build process. |
| `TARGET` | Required. The file type of the Vertica binary that you use in the build process.<br>Accepts `rpm` or `deb`. |
| `VERTICA_VERSION` | The version number of the Vertica binary used in the build process. This value is optional for a [canonically-named Vertica binary](#building-with-a-canonically-named-vertica-binary).<br> You can use this variable to build containers for different Vertica versions. |

You might build multiple containers to develop UDxs for multiple Vertica versions. To help distinguish among containers, define `CONTAINER_OS_TAG` and `VERTICA_VERSION` in the build command. If you set `CONTAINER_OS_TAG=alma` and `VERTICA_VERSION=25.4.0-0`, the full container specification is `verticasdk:alma-25.4.0-0`.

## Building with a canonically-named Vertica binary

The build process requires the Vertica version. The `Makefile` can extract this information automatically from a canonically-named RPM or DEB file in one of the following formats:

```shell
$ vertica-25.4.0-0.x86_64.RHEL8.rpm
```

```shell
$ vertica_25.4.0-0_amd64.deb
```

The `Makefile` extracts the Vertica version (`25.4.0-0`) and the OS distribution version (`RHEL8`). If the Vertica binary uses this format, run `make` with the `TARGET` variable to build the container. For example, the following command builds a UDx container with a canonically-named RPM file:

```shell
$ make TARGET=rpm
```
If there is more than one RPM (or DEB) file in the directory, you will have to specify which one to use using the PACKAGE variable:

```shell
make PACKAGE=verticaXXX.rpm
```

## Build with variables

If the RPM or DEB file does not use the canonical-naming convention, define the `VERTICA_VERSION` variable in the make command:

```shell
$ make TARGET=deb VERTICA_VERSION=11.0.0-0
```

# Test the UDx container

The `make test` target calls a few `vsdk-*` scripts to test that your container was built correctly. Then, it mounts the following directories in the UDx container filesystem to replicate your local development environment:
- `/home/<user-name>`
- The current working directory and its child directories

For an illustration of the mounted directories, see [Host and container filesystem views](#host-and-container-filesystem-views).

Because the contents of the UDx container are not writable, `make test` calls `vsdk-cp` to copy the `/opt/vertica/sdk/examples` UDx directory into a new directory named `./tmp-test` that is available on your host machine. Next, it builds the examples in that directory with `vsdk-make`.

Run `make test` with the `TARGET` environment variable:

```shell
$ make test TARGET=deb
```
> **NOTE**: The scripts require the container tag, which is derived from the `VERTICA_VERSION` environment variable. If you have a canonically-named RPM or DEB file, the `Makefile` extracts the `VERTICA_VERSION` from the filename. Otherwise you must specify the tag the same way that you did when you created the container.
>
>You can also simply set the container tag through the `VSDK_IMAGE` variable 

# Develop UDxs

This repository provides `vsdk-*` scripts to help you test and compile your UDx in a multi-environment compilation. You invoke the following scripts on your host machine, and they execute in the UDx container:

| Script&nbsp;name | Description |
|:-----------------|:------------|
| `vsdk-bash` | Opens a bash shell in the UDx container. This script is useful for debugging. |
| `vsdk-cp` | Invokes `cp` inside the UDx container. This is a helper script used in the `make test` command, and included because the UDx container is not writable and you might need to copy UDx files to your host for editing. |
| `vsdk-g++` | Executes the g++ compiler in the UDx container. |
| `vsdk-make` | Executes `make` in the current working directory in the UDx container. This allows you to develop UDxs locally and compile them with the tools available in the UDx container. |

These scripts use the contents of `/etc/os-release` to determine whether the container has a `centos` or `ubuntu` tag. If your host uses a different distribution than your development environment, you can edit `vsdk-bash` directly to change the default setting.

Alternatively, you can interactively define the operating system with the `CONTAINER_OS_TAG` [environment variable](#environment-variables) when you execute `vsdk-make`. To simplify this workflow, you can create a shell alias that defines `CONTAINER_OS_TAG`:

```shell
alias vsdk-make='CONTAINER_OS_TAG=ubuntu path/to/vsdk-make'
```
For additional details, see [Compile UDxs](#compile-udxs).

## Environment variables

The following table describes the environment variables that you can set to provide additional information to the `vsdk-*` commands:

| Environment&nbsp;Variable | Description |
|:--------------------------|:------------|
| `VSDK_IMAGE` | The container image to use to run the container. When set, you do not need to set OS. If you locally built the image, it is better to use this variable to run a container. |
| `CONTAINER_OS_TAG` | The container operating system distribution, either `centos` or `ubuntu`. This variable is if you use a container that runs an OS that is different from the host OS. If you do not define this variable, `vsdk-make` reads `/etc/os-release` to determine the OS. |
| `VERTICA_VERSION` | The version number of the Vertica binary used in the build process. |
| `VSDK_ENV` | Optional file that defines environment variables for `vsdk-*` commands that run in the container. For formatting details, see [Declare default environment variables in file](https://docs.docker.com/compose/env-file/) in the Docker documentation.|
| `VSDK_MOUNT` | A list of one or more directories that you want to mount in the UDx container filesystem. To mount multiple directories, separate each path with a space. For additional details, see [Mounting additional files](#mounting-additional-files). |

## Compile UDxs

After you [test your UDx container](#test-the-udx-container), you can develop UDxs in the current working directory on the host machine and compile them in the UDx container.

We use a build process based on the `make` paradigm, with build instructions encapsulated in a `Makefile`.  Use the `vsdk-make` script to execute your `Makefile` and compile your UDx. This script behaves exactly like GNU `make`, but it compiles your files in the development environment mounted in the UDx container:

1. Add `UDx-container` repository to the `PATH` so you can execute the `vsdk-*` scripts from your development directory:
   ```shell 
   $ export PATH=/path/to/vertica-containers/UDx-container:$PATH
   ```
2. Change into your UDx development directory:
   ```shell 
   $ cd /path/to/dev-dir
   ```
3. Run `vsdk-make` with the required environment variables:
   ```shell 
   $ VERTICA_VERSION=<vertica-version> CONTAINER_OS_TAG=ubuntu vsdk-make TARGET=deb
   ```
   Additionally, you can use `VSDK_ENV` to pass a file that contains the environment variables:
   ```shell
   $ VSDK_ENV=env-vars-file vsdk-make
   ```

## Mount additional files 

`vsdk-make` mounts the current working directory and its child directories in the container filesystem. In some circumstances, your compilation process might require additional files that are not available in the mounted directories. 

One solution is to execute `vsdk-make` in a higher directory that includes all of the necessary files. A less intrusive solution is using `VSDK_MOUNT` to mount one or more additional directories:  

```shell
$ VSDK_MOUNT='/usr/share/lib /usr/share/toolB' vsdk-make
```

The previous command mounts `/usr/share/lib` and `/usr/share/toolB` in the UDx container. `VSDK_MOUNT` mounts directories in the container in the same filesystem location as the host. Maintaining the filesystem location helps `vsdk-make` locate the files during compilation.

You can also use `VSDK_MOUNT` with the `make test` command:

```shell
$ VSDK_MOUNT='/usr/share/lib /usr/share/toolB' make test
```

## Host and container filesystem views

By default, the UDx container has the following directories:
- `/bin`
- `/lib`
- `/opt/vertica`

To access these tools, `vsdk-make` mounts your `/home` and local UDx directory tree in the UDx container filesystem. If your build process requires files that are not available in your directory tree, you can mount additional directories with the `VSDK_MOUNT` [environment variable](#environment-variables).

The following image describes a sample filesystem for the host and the UDx container with two additional mounted directories:

![filesystem diagram](udx-dir-structure.svg "Development directory structure")

In the previous diagram:
- `/home`: The host's `/home` directory.
- `/udx`: The current working directory, or the directory where the user develops and compiles UDxs from. This is the root of the UDx development directory tree. This directory tree is mounted in the container, including `/vtoolA`.
- `/tmp-test`: Directory generated by the `vsdk-test` command that contains the compiled UDxs copied from the UDx container.
- `/usr/share/lib` and `usr/share/vtoolB`: Included in this diagram to illustrate how `VSDK_MOUNT` mounts additional development tools. The following command mounts these example directories so that the build process can access its contents:
   ```shell
   $ VSDK_MOUNT='/usr/share/lib /usr/share/vtoolB' vsdk-make
   ```

# Load the UDx into a test Vertica server

## Make the UDx available to the test Vertica server

To test your UDx, you now need access to a running Vertica server. The UDx must be in a folder that is accessible by the Vertica server. If your Vertica server is running in a containerized environment (such as Docker or Kubernetes), you need to mount your UDx directory into the Vertica server container or pod so Vertica can access the UDx shared library and related files.


## Load your UDx into the test Vertica server

When the test Vertica server is ready, you can use `vsql` to load the UDx. The following commands load dblink library (previously compiled):

```sql
CREATE OR REPLACE LIBRARY dblink AS '/tmp/ldblink.so' LANGUAGE 'C++';
   CREATE OR REPLACE TRANSFORM FUNCTION dblink AS LANGUAGE 'C++' NAME 'DBLinkFactory' LIBRARY dblink ;
  GRANT EXECUTE ON TRANSFORM FUNCTION dblink() TO PUBLIC ;
  GRANT USAGE ON LIBRARY dblink TO PUBLIC ;
```
To view `AggregateFunctions.sql` and other example library SQL files, see `/opt/vertica/sdk/examples`.

For additional details about loading a library containing user-defined extensions (UDxs) into the database catalog, see [User-Defined Extensions](https://docs.vertica.com/25.4.x/en/sql-reference/statements/create-statements/create-library/).

