[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](https://opensource.org/licenses/Apache-2.0)

# Vertica Containers

This repository has the sources for container-based projects using Vertica.

For Vertica on Kubernetes containers and resources, see [vertica-kubernetes](https://github.com/vertica/vertica-kubernetes).

> **IMPORTANT**: To build the projects in this repository, you must have a licensed Vertica RPM or DEB file.

## [One-Node CE](https://github.com/vertica/vertica-containers/tree/main/one-node-ce)

The One-Node CE directory provides instructions to build the containerized version of the [Vertica Community Edition (CE)](https://www.vertica.com/landing-page/start-your-free-trial-today/), a free, limited license that Vertica provides as a hands-on introduction to the platform. For an overview, see the [Vertica documentation](https://www.vertica.com/docs/latest/HTML/Content/Authoring/GettingStartedGuide/DownloadingAndStartingVM/DownloadingAndStartingVM.htm).

Vertica publishes the binary version of this container on [DockerHub](https://hub.docker.com/u/opentext) as the [vertica/vertica-ce](https://hub.docker.com/r/opentext/vertica-ce) container.


## [UDx-container](https://github.com/vertica/vertica-containers/tree/main/UDx-container)

The UDx-container directory packages in a container the following resources required to build User-Defined eXtensions (UDxs):
- C++-compiler
- Libraries
- Google protobuf compiler
- Python interpreter
- Tools to invoke the UDx

## [Kafka Scheduler](vertica-kafka-scheduler)

The kafka-scheduler directory provides tools to maintain the official [vertica/kafka-scheduler](https://hub.docker.com/r/opentext/kafka-scheduler) container, or build a custom containerized version of the [Vertica Kafka Scheduler](https://www.vertica.com/docs/latest/HTML/Content/Authoring/KafkaIntegrationGuide/AutomaticallyCopyingDataFromKafka.htm), a standalone Java application that automatically consumes data from one or more Kafka topics and then loads the structured data into Vertica.

The Kafka Scheduler provides the following advantages over manually loading data with COPY statements:
- Streamed data automatically loads in your database according to the [frame duration](https://www.vertica.com/docs/latest/HTML/Content/Authoring/KafkaIntegrationGuide/ChoosingFrameDuration.htm).
- The Kafka Scheduler manages offsets to ensure an exactly-once message consumption process from Kafka topics.
- You can configure backup schedulers to provide high-availability. If the primary scheduler fails, the backup scheduler begins loading Kafka data where the failed scheduler left off.
