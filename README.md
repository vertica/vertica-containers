[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](https://opensource.org/licenses/Apache-2.0)

# Vertica containers

This repository has the sources for some container-based projects using Vertica
(other than the containers used in
[vertica-kubernetes](https://github.com/vertica/vertica-kubernetes),
which has its own repository).

These containers are incomplete in themselves: at the moment (November
2021) they require a licensed Vertica RPM or .deb file to build.

## [One-Node "CE"](https://github.com/vertica/vertica-containers/tree/main/one-node-ce)

This directory gives the instructions for building the containerized
version of our Community Edition
virtual-machine-based [Community Edition (CE)](https://www.vertica.com/landing-page/start-your-free-trial-today/).

As noted above, to build and install this container you need a Vertica RPM (or Vertica
.deb file).  However, do not despair!  We also publish a binary version of this
container, see our [Vertica Dockerhub vertica-ce download](https://hub.docker.com/r/vertica/vertica-ce).

## [UDx-container](https://github.com/vertica/vertica-containers/tree/main/UDx-container)

This container packages the pieces needed to build User-Defined
eXtensions --- C++-compiler, libraries, the appropriate version of the Google protobuf compiler,
Python interpreter, and tools to invoke them.  As noted above, to build and install this container you need a copy of the Vertica RPM (or Vertica .deb file) used at your site for your Vertica installation.

