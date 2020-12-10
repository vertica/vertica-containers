# How to UDx (Internal Vertica version)
 
## Retrieve the UDx container package 

Go here: https://github.com/vertica/vertica-containers and use the
download-code method of your choice.  Github clones/downloads entire
repositories, so you'll be retrieving the vertica-containers
repository, which has the UDx-container directory as a subdirectory.  

## Build the wrapper program

```shell
make wrapper
```

## Do you need to make a container image?

(If you are at Vertica, you probably don't need to make a container
image, since one is already in our Docker repository.)  

Building a Docker container image is done by your local Docker
daemon.  The Daemon may already have 

Run the command:

```shell
docker images | grep verticasdk
```

To see whether the repository has a VerticaSDK container image.

## If you need to make a container image

If you need to build a container image, follow 

*** First, Get a Vertica RPM 

Internally to Vertica, perhaps the best way is to retrieve one from
one of these places:

 - http://vdev.verticacorp.com/kits/daily/ 
 - http://vdev.verticacorp.com/kits/releases/

I will refer to the retrieved Vertica RPM as 'the.rpm' in what
follows.

The Vertica RPM needs to be in the same directory as the Dockerfile so
that the Docker build process can find it (the RPM is processed by the
the partially-built container, which has limited access to the host
filesystem).

If you need to make a container image, run docker build using make: 

#+BEGIN_SRC shell
make docker-image VERTICA_RPM=the.rpm
#+END_SRC

## Using the container

You will see that there are several files in this directory:
 * vsdk-bash --- a command that runs an interactive shell inside the
 container, this exists primarily as a tool for debugging the container
 * vsdk-g++ --- this is a g++ that executes inside the container (this
 is really only good for compiling single .cpp files)
 * vsdk-make --- this is a make that executes inside the container.

vsdk-make and vsdk-g++ are symbolic links to vsdk-bash, so if you copy
them to another directory, they should move together.

Put the directory housing these vsdk- commands in your path.

```shell
PATH=the-vsdk-directory:$PATH
```

Then try compiling the examples in vertica/VerticaSDK/examples using
your vsdk-make.

### The container has a restricted view of your host filesystem

When the container executes, vsdk-make arranges for the following
directories to be accessible using their names in the container:

* Your home directory
* The directory vsdk-make is being executed in

Relative pathnames won't work.


 
