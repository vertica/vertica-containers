[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](https://opensource.org/licenses/Apache-2.0)

# Vertica Containers

This repository has the sources for container-based projects using Vertica.

For Vertica on Kubernetes containers and resources, see [vertica-kubernetes](https://github.com/vertica/vertica-kubernetes).

## [One-Node CE](https://github.com/vertica/vertica-containers/tree/main/one-node-ce)

The One-Node CE directory gives instructions to build the containerized version of the [Vertica Community Edition (CE)](https://www.vertica.com/landing-page/start-your-free-trial-today/), a free, limited license that Vertica provides users as a hands-on introduction to the platform. For an overview, see the [Vertica documentation](https://www.vertica.com/docs/latest/HTML/Content/Authoring/GettingStartedGuide/DownloadingAndStartingVM/DownloadingAndStartingVM.htm).

To build the One-Node CE, you must have a a licensed Vertica RPM or .deb file.

Vertica publishes the binary version of this container on [DockerHub](https://hub.docker.com/u/vertica) as the [vertica/vertica-ce](https://hub.docker.com/r/vertica/vertica-ce) container.


## [UDx-container](https://github.com/vertica/vertica-containers/tree/main/UDx-container)

The UDx-container directory packages in a container the following resources required to build User-Defined eXtensions:
- C++-compiler
- Libraries
- Google protobuf compiler
- Python interpreter
- Tools to invoke the UDx

As noted above, to build and install this container you need a copy of the Vertica RPM or .deb file used at your site for your Vertica installation.

To build the UDx-container, you must have a a licensed Vertica RPM or .deb file.