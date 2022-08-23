
# Vertica-Kafka Scheduler

This repository provides the tools to build and maintain a containerized version of the [Vertica Kafka Scheduler](https://www.vertica.com/docs/latest/HTML/Content/Authoring/KafkaIntegrationGuide/AutomaticallyCopyingDataFromKafka.htm), a standalone Java application that automatically consumes data from one or more Kafka topics and then loads the structured data into Vertica. The scheduler is controlled by the `vkconfig` command line script.

You can use the official [vertica/kafka-scheduler](https://hub.docker.com/r/vertica/kafka-scheduler) image, or you can use the Dockerfile in this repo to build a custom vkconfig image. The official image is based on [alpine:3.14](https://hub.docker.com/_/alpine) and includes the [openjdk8-jre](https://hub.docker.com/_/openjdk).

## Prerequisites

- [Docker Desktop](https://www.docker.com/get-started/), [Docker Engine](https://docs.docker.com/engine/install/), or another container runtime
- [Vertica installation](https://www.vertica.com/docs/latest/HTML/Content/Authoring/InstallationGuide/Other/InstallingManually.htm) or [Vertica server image](https://hub.docker.com/r/vertica/vertica-k8s)
- [vertica/kafka-scheduler](https://hub.docker.com/r/vertica/kafka-scheduler) image
- (Optional) [Docker Compose](https://docs.docker.com/compose/install/) to run `example.sh`

## Configure a scheduler 

A scheduler is composed of [individual components](#defining-scheduler-components) that define the load frequency, data type, and Vertica and Kafka environments. After you define properties for each component, [launch the scheduler](#launching-the-scheduler) with configuration and logging utilities mounted as volumes.

### Configuration file

Each component and the running scheduler process require access to the same database and environment settings. To provide these settings, create a configuration file that provides the following:
- `username`: Vertica database user that runs the scheduler.
- `dbhost`: Vertica database host or IP address.
- `dbport`: Port used to connect to the Vertica database.
- `config-schema`: Name of the scheduler's schema.

The components and running scheduler process access configuration file values from within the scheduler container filesystem, so you must mount the configuration file as a [volume](https://docs.docker.com/storage/volumes/). The scheduler expects the configuration file to be named `vkconfig.conf` and stored in the `/etc` directory. For example: 

```bash
$ docker run -v <local-config.conf>:/etc/vkconfig.conf vertica/kafka-scheduler <options> ...
```

For a sample configuration file, see [example.conf](example.conf) in this repository.

### Scheduler components

Vertica recommends that you create a scheduler and define its components as a separate step from launching the scheduler. This ensures that the scheduler configuration persists in the event of a power outage or other system failure.

A scheduler requires the following components:
- `scheduler`: The scheduler itself
- `target`: The Vertica table that receives the streaming data
- `load-spec`: Defines the parser for the streaming data
- `cluster`: Details about the Kafka server
- `source`: A Kafka topic that sends data to Vertica
- `microbatch`: Combines each of the preceding components into a single COPY statement that the Scheduler executes to load data into Vertica

> **NOTE**
> Additionally, the scheduler container includes the `statistics` component. This component queries the [stream_microbatch_history table](https://www.vertica.com/docs/latest/HTML/Content/Authoring/KafkaIntegrationGuide/KafkaTables/stream_microbatch_history.htm) for runtime statistics.

The following command returns a list of all available options for a component:

```bash
$ docker run vertica/kafka-scheduler vkconfig <component> --help
```

For example, to view the description of each `microbatch` option, enter the following: 

```bash
$ docker run vertica/kafka-scheduler vkconfig microbatch --help
```

### Create a scheduler

To create a scheduler and its components, execute a `docker run` command that does the following:
- Mounts a configuration file as a volume.
- Defines the scheduler image name and version.
- Defines scheduler components as a single string with the `bash -c` script option.

The scheduler component string must first define the `scheduler` itself, and then add the additional required components with the `--add` option. Each component is separated by a semi-colon. You must pass the `--conf /etc/vkconfig.conf` option to each component definition to provide environment settings.

The following command provides an example format:

```bash
$ docker run \
    -v <local-config.conf>:/etc/vkconfig.conf \
    vertica/kafka-scheduler:<version> bash -c "
        vkconfig scheduler \ 
          -- conf /etc/vkconfig.conf \
          <scheduler-options> ...; \
        vkconfig <component-1> --add \
          -- conf /etc/vkconfig.conf \
          <component-1-options> ...; \
        vkconfig <component-2> --add \
          -- conf /etc/vkconfig.conf \
          <component-2-options> ...; \
        ...
        "
```

For a complete example, see the **Set up Scheduler** section in the [example.sh](example.sh) script in this repository. The following snippet from that section defines the first `microbatch` component:

```bash
$ docker run \
...
vkconfig microbatch --add \  
  --conf /etc/vkconfig.conf \
  --microbatch KafkaBatch1 \ 
  --add-source KafkaTopic1 \ 
  --add-source-cluster KafkaCluster \
  --target-schema public \   
  --target-table KafkaFlex \ 
  --rejection-schema public \
  --rejection-table KafkaFlex_rej \
  --load-spec KafkaSpec; \
...
```

## Launching the scheduler

After you [create a scheduler](#create-a-scheduler), launch the scheduler to begin scheduling microbatches. To launch a scheduler, execute a `docker run` command that does the following:
- Mounts a configuration file as a volume.
- Specifies the scheduler image name.
- Mounts the local `vkafka-log-config-debug.xml` file in the container's `/opt/vertica/packages/kafka/config` directory. This file configures log messages to help troubleshoot scheduler issues.
- Mounts the local `/log` directory in the container's `/opt/vertica/log` directory to write logs to help troubleshoot scheduler issues.
- Passes the Docker `--user` command to specify the user.

The following command provides an example format when executed from the top-level directory of your cloned repository:

```bash
$ docker run -it \
    -v $PWD/vkconfig.conf:/etc/vkconfig.conf vertica/kafka-scheduler \
    -v $PWD/vkafka-log-config-debug.xml:/opt/vertica/packages/kafka/config/vkafka-log-config.xml \
    -v $PWD/log:/opt/vertica/log \
    --user $(perl -E '@s=stat "'"$PWD/log"'"; say "$s[4]:$s[5]"') \
        vkconfig launch --conf /etc/vkconfig.conf &
```
Additionally, the preceding command does the following:
- Defines the `--user` with a Perl script that extracts the `/log` file owner and group information, and then formats those values in `user:group` format.
- Executes `vkconfig launch` as a background process.

## Building a custom scheduler container

In some circumstances, you might want to build a custom vertica/kafka-scheduler container. This repository provides a [Makefile](./Makefile) with a `build` target, and build variables that build a custom scheduler container that requires the following:
- Vertica binary or rpm2cpio vertica.rpm | cpio -idmv and export VERTICA_INSTALL=./opt/vertica
- Java SDK in `vertica/bin/VerticaSDK.jar`
- Java version information in `vertica/sdk/BuildInfor.java`

For additional information about Vertica and Java development, see [Java SDK](https://www.vertica.com/docs/latest/HTML/Content/Authoring/ExtendingVertica/Java/DevelopingInJava.htm).

### `build` make target

This repository provides a Makefile with a build target for creating a custom container:

```bash
$ make build
```

By default, the [Makefile](./Makefile) assumes that you installed Vertica in the `/opt` directory. If you installed Vertica in a different directory, set the `VERTICA_INSTALL` configuration option with the `build` target:

```bash
$ make build VERTICA_INSTALL=/path/to/vertica
```

## Build variables

| Variable        | Description |
|:----------------|:------------|
| VERTICA_INSTALL | The location of your Vertica binary installation. Define this variable if you want to copy the local install of the Java libraries.<br>**Default**: `/opt/vertica` |
| VERTICA_VERSION | The Vertica version that you want to use to build the scheduler container. The scheduler version must match the Vertica database version. <br>**Default**: `latest` |

## Push to Docker Hub

This repository provides the `push` make target that builds and pushes your custom scheduler container:

```bash
$ VERTICA_VERSION=latest make push
```

## Repository contents overview

This repository contains the following artifacts to help [test](#testing-the-container) and [build](#building-the-vertica-kafka-container) a vkconfig container

## Makefile

The Makefile contains the following targets:
- `make help`: Displays the help for the Makefile.
- `make version`: Displays the Vertica version that will be used in the build process.
- `make java`: Copy the local install of the Java libraries from `/opt/vertica/java`.
- `make kafka`: Copy the local install of the Kafka Scheduler from `/opt/vertica/packages/kafka`.
- `make build`: Builds the container image.
- `make push`: Pushes the custom container image to the remote Docker Hub repository.
- `make test`: Runs [example.sh](#examplesh) to validate the vkconfig configuration.

## docker-compose.yaml

A [Compose file](https://docs.docker.com/compose/compose-file/) that starts the following services, each as a container:
- [Zookeeper](https://hub.docker.com/r/bitnami/zookeeper)
- [Kafka broker](https://hub.docker.com/r/bitnami/kafka/)
- [Vertica](https://hub.docker.com/r/vertica/vertica-k8s)

The Compose file creates the `scheduler` network so that the containers can communicate with each other.

## example.conf

A sample [configuration file](https://www.vertica.com/docs/latest/HTML/Content/Authoring/KafkaIntegrationGuide/SettingUpAScheduler.htm#1). You can customize this file by replacing the default values or adding more [vkconfig script options](https://www.vertica.com/docs/latest/HTML/Content/Authoring/KafkaIntegrationGuide/UtilityOptions/SharedUtilityOptions.htm).

## example.sh

A bash script that configures and runs a scheduler with test data, and logs the entire process to the console. The process involves the following steps: 
1. Sets up a test environment using the [docker-compose.yaml](#docker-composeyaml) file. The environment includes the following:
   - A Vertica database
   - Required database packages
   - Database table
   - Database user
   - Resource pool
   - Two Kafka topics
2. Creates a scheduler container with the [vertica/kafka-scheduler](https://hub.docker.com/r/vertica/kafka-scheduler) image, then creates the following components:
   - Target Flex table 
   - Parser
   - Kafka source 
   - Two Kafka topics 
   - Two microbatches (one for each Kafka topic)
3. Runs the scheduler.
4. Sends JSON-formatted test data to Kafka.
5. Displays the test data in the Flex table.
6. Gracefully shuts down the scheduler.
7. Removes the images pulled with the Compose file.