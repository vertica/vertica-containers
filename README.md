[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](https://opensource.org/licenses/Apache-2.0)

# Vertica Containers

This repository has the sources for container-based projects using Vertica.

For Vertica on Kubernetes containers and resources, see [vertica-kubernetes](https://github.com/vertica/vertica-kubernetes).

> **IMPORTANT**: To build the projects in this repository, you must have a licensed Vertica RPM or DEB file.

## [One-Node CE](https://github.com/vertica/vertica-containers/tree/main/one-node-ce)

The One-Node CE directory provides instructions to build the containerized version of the [Vertica Community Edition (CE)](https://www.vertica.com/landing-page/start-your-free-trial-today/), a free, limited license that Vertica provides users as a hands-on introduction to the platform. For an overview, see the [Vertica documentation](https://www.vertica.com/docs/latest/HTML/Content/Authoring/GettingStartedGuide/DownloadingAndStartingVM/DownloadingAndStartingVM.htm).

Vertica publishes the binary version of this container on [DockerHub](https://hub.docker.com/u/vertica) as the [vertica/vertica-ce](https://hub.docker.com/r/vertica/vertica-ce) container.


## [UDx-container](https://github.com/vertica/vertica-containers/tree/main/UDx-container)

The UDx-container directory packages in a container the following resources required to build User-Defined eXtensions:
- C++-compiler
- Libraries
- Google protobuf compiler
- Python interpreter
- Tools to invoke the UDx

## [Kafka Scheduler](vertica-kafka-scheduler)

This is a container for [the Vertica Kafka Scheduler](https://hub.docker.com/repository/docker/vertica/kafka-scheduler)
on Docker Hub.  The Kafka Scheduler is a stanalone java app that automatically
consumes data from one or more Kafka topics, and loads structured data into
Vertica.  Automatically loading streaming data has a number of advantages over
manually using COPY:

The streamed data automatically appears in your database. The frequency with
which new data appears in your database is governed by the scheduler's frame
duration.
The scheduler provides an exactly-once consumption process. The schedulers
manage offsets for you so that each message sent by Kafka is consumed once.
You can configure backup schedulers to provide high-availability. Should the
primary scheduler fail for some reason, the backup scheduler automatically
takes over loading data.
