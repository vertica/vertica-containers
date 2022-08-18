
# Vertica-Kafka Scheduler

This repository provides the tools to maintain and test a containerized version of the [Vertica Kafka Scheduler](https://www.vertica.com/docs/latest/HTML/Content/Authoring/KafkaIntegrationGuide/AutomaticallyCopyingDataFromKafka.htm), a standalone Java application that automatically consumes data from one or more Kafka topics, and then loads it as structured data into Vertica. The scheduler is controlled by the `vkconfig` command line script.

You can use the official [vertica/kafka-scheduler](https://hub.docker.com/r/vertica/kafka-scheduler) image, or you can use the Dockerfile in this repo to build a custom vkconfig image. The Docker image is based on [alpine:3.14](https://hub.docker.com/_/alpine) and includes the [openjdk8-jre](https://hub.docker.com/_/openjdk).

## Prerequisites

- [Docker Desktop](https://www.docker.com/get-started/), [Docker Engine](https://docs.docker.com/engine/install/), or another container runtime
- [Vertica installation](https://www.vertica.com/docs/latest/HTML/Content/Authoring/InstallationGuide/Other/InstallingManually.htm) or [Vertica server image](https://hub.docker.com/r/vertica/vertica-k8s)
- [vertica/kafka-scheduler](https://hub.docker.com/r/vertica/kafka-scheduler) image
- (Optional) [Docker Compose](https://docs.docker.com/compose/install/) to run `example.sh`

## Setting up a scheduler 

A scheduler is composed of individual components that define the load frequency, data type, and Vertica and Kafka configurations. After you create the scheduler, run the vertica/kafka-scheduler container with `vkconfig` to launch the scheduler with local files and directories mounted as volumes.

### Configuration file

The configuration file provides the scheduler the following options that persist regardless of the other scheduler components:
- `username`
- `dbhost`
- `dbport`
- `config-schema`

To provide the scheduler process access to these configuration values, you must mount the configuration file as a [volume](https://docs.docker.com/storage/volumes/) named vkconfig.conf in the /etc vertica/kafka-scheduler container filesystem. For example:

```bash
docker run -v <local-config.conf>:/etc/vkconfig.conf <options> ...
```

For an example configuration file, see [example.conf](example.conf) in this repository.



### Scheduler components

To set up a scheduler, use a single `docker run` command in the following format to mount the configuration file, select the scheduler image and version, and define the scheduler components:

```bash
$ docker run -v <local-config.conf>:/etc/vkconfig.conf <image-name>:<version> bash -c "<scheduler-configuration>"
```

In the preceding command, `<scheduler-configuration>` is a string that defines options on the following scheduler components:
- `scheduler`: The scheduler itself
- `target`: The Vertica table that receives the streaming data
- `load-spec`: Defines the parser for the streaming data
- `cluster`: Details about the Kafka server
- `source`: A Kafka topic that sends data to Vertica
- `microbatch`: Combines each of the preceding components into a single COPY statement that the Scheduler executes to load data into Vertica

This repository contains the [example.sh](example.sh) script. The **Set up Scheduler** section in this script contains a complete example of how to pass a string of scheduler components and their configuration options to the `docker run` command. Each component uses the following format:

```bash 
vkconfig <component> --add \
--conf /etc/vkconfig.conf \
--<option> <value> [\ 
... ]
```

> **NOTE**
> You must pass the `--conf /etc/vkconfig.conf` option to each component in the scheduler.

For example, the following snippet defines the first microbatch component, which combines previously defined components into one COPY statement definition:

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

For a list of all available options for each component, navigate to the top-level directory in this repository and run the following command:

```bash
docker run vertica/kafka-scheduler vkconfig <component> --help
```

For example, to view the description of each component in the preceding `vkconfig microbatch --add \ ...` command, enter the following: 

```bash
docker run vertica/kafka-scheduler vkconfig microbatch --help
```

> **NOTE**
> Additionally, this container includes the `statistics` component that queries the [stream_microbatch_history table](https://www.vertica.com/docs/latest/HTML/Content/Authoring/KafkaIntegrationGuide/KafkaTables/stream_microbatch_history.htm) for runtime statistics.

## Launching the scheduler

After you define a scheduler and the required components, use the `vkconfig launch` command to instruct the scheduler to start scheduling microbatches.

When you execute the following `docker run` command from the top-level directory of this repository, it executes the `vkconfig launch` command to start the scheduler as a background process:

```bash
docker run -it \
    -v $PWD/vkconfig.conf:/etc/vkconfig.conf vertica/kafka-scheduler \
    -v $PWD/vkafka-log-config-debug.xml:/opt/vertica/packages/kafka/config/vkafka-log-config.xml \
    -v $PWD/log:/opt/vertica/log \
    --user $(perl -E '@s=stat "'"$PWD/log"'"; say "$s[4]:$s[5]"') \
        vkconfig launch --conf /etc/vkconfig.conf &
```
The preceding command mounts the following files and directories in the scheduler container filesystem:
- Local `vkconfig.conf` file in the container's `/etc` directory
- Local `vkafka-log-config-debug.xml` file in the container's `/opt/vertica/packages/kafka/config` directory. This file structures log messages to help troubleshoot scheduler issues.
- Local `/log` directory in the container's `/opt/vertica/log` directory to store logs to troubleshoot scheduler issues.

Additionally, the command defines the following:
- Passes the Docker `--user` command to define user that executes this `docker run` command as the default user within the scheduler container.
- Executes the `vkconfig launch` command as a background process, passing the configuration file as an option.

# Building a custom scheduler container

In some circumstances, you might want to build a custom vertica/kafka-scheduler container. You can build a custom scheduler container if you have access to a Vertica binary and the associated Java libraries for your Vertica installation. By default, the Makefile assumes that you installed Vertica in the `/opt` directory. If you installed Vertica in a different directory, set the `VERTICA_INSTALL` configuration option when you build the container:

```bash
$ make build VERTICA_INSTALL=/path/to/vertica
```

## Build variables

| Variable        | Description |
|:----------------|:------------|
| VERTICA_INSTALL | The location of your Vertica binary installation. Define this variable if you want to copy the local install of the Java libraries.<br>**Default**: `/opt/vertica`. |
| VERTICA_VERSION | The Vertica version that you want to use to build the vkconfig container.<br>**Default**: `latest`.|
| VERSION | ?????????? |

# Repository contents overview

This repository contains the following artifacts to help [test](#testing-the-container) and [build](#building-the-vertica-kafka-container) a vkconfig container

### Makefile

The Makefile contains the following targets:
- `make help`: Displays the help for the Makefile.
- `make version`: Displays the Vertica version that will be used in the build process.
- `make java`: Copy the local install of the Java libraries from `/opt/vertica/java`.
- `make kafka`: Copy the local install of the Kafka Scheduler from `/opt/vertica/packages/kafka`.
- `make build`: Builds the container image.
- `make push`: Pushes the custom container image to the remote Docker Hub repository.
- `make test`: Runs [example.sh](#examplesh) to validate the vkconfig configuration.

### docker-compose.yaml

A [Compose file](https://docs.docker.com/compose/compose-file/) that starts the following services, each as a container:
- [Zookeeper](https://hub.docker.com/r/bitnami/zookeeper)
- [Kafka broker](https://hub.docker.com/r/bitnami/kafka/)
- [Vertica](https://hub.docker.com/r/vertica/vertica-k8s)

The Compose file creates the `scheduler` network so that the containers can communicate with each other.

### example.conf

A sample [configuration file](https://www.vertica.com/docs/latest/HTML/Content/Authoring/KafkaIntegrationGuide/SettingUpAScheduler.htm#1). You can customize this file by replacing the default values or adding more [vkconfig script options](https://www.vertica.com/docs/latest/HTML/Content/Authoring/KafkaIntegrationGuide/UtilityOptions/SharedUtilityOptions.htm).

### example.sh

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

# Vertica-Kafka Scheduler

This github repo builds a Vertica-Kafka scheduler docker container for the
purposes of streaming data from Kafka to Vertica.  It requires Docker or some
compatible container environment.

## Quickstart

```
# Commands to configure a scheduler
docker run vertica/kafka-scheduler vkconfig scheduler --help
docker run vertica/kafka-scheduler vkconfig cluster --help
docker run vertica/kafka-scheduler vkconfig source --help
docker run vertica/kafka-scheduler vkconfig target --help
docker run vertica/kafka-scheduler vkconfig load-spec --help
docker run vertica/kafka-scheduler vkconfig microbatch --help
docker run vertica/kafka-scheduler vkconfig statistics --help

# Launching the scheduler with some useful docker options
# use "-v" to map the optional conf file to the container's /etc/vconfig.conf
# use "-v" to map the log config file to the container's /opt/vertica/packages/kafka/config/vkafka-log-config.xml
# use "-v" to map the writable log directory to the internal /opt/vertica/log
# use "--user" to run with the credentials of the log directory
docker run -it \
    -v $PWD/vkconfig.conf:/etc/vkconfig.conf vertica/kafka-scheduler \
    -v $PWD/vkafka-log-config-debug.xml:/opt/vertica/packages/kafka/config/vkafka-log-config.xml \
    -v $PWD/log:/opt/vertica/log \
    --user $(perl -E '@s=stat "'"$PWD/log"'"; say "$s[4]:$s[5]"') \
        vkconfig launch --conf /etc/vkconfig.conf
```

## Example
`example.sh` is a full example of configuring and running a scheduler.  It uses
docker-compose to create a kafka and vertica service, then it posts some kafka
JSON messages, waits, then shows the messages in vertica tables.

## Building docker container

This is how you rebuild the docker image to customize it or update it and test it.
This requres the vertica package installed in /opt/vertica or specified in the `make`
command with `VERTICA_INSTALL=/wherever/opt/vertica`
1. Clone this repository.
2. Open a terminal in the `vertica-kafka-scheduler` directory.
3. Install Vertica (or use rpm2cpio vertica.rpm |cpio -idmv and export VERTICA_INSTALL=./opt/vertica)
4. Build the kafka scheduler container with
    ```
    make build
    ```

## Push to docker hub

1. Clone this repository.
2. Open a terminal in the `vertica-kafka-scheduler` directory.
3. Install Vertica (or use rpm2cpio vertica.rpm |cpio -idmv and export VERTICA_INSTALL=./opt/vertica)
4. Build and push containers
    ```
    VERTICA_VERSION=latest make push
    ```
