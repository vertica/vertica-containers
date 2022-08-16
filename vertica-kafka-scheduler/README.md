There are two use cases for the github project – building the scheduler and running a demo.  Customers don’t need to build the scheduler unless they want to make their own private tweaks (like embedding their own config files in it, but that’s probably overengineering).  However, they may want to run the demo which can be done with “make test”.

# Vertica-Kafka Scheduler

This repository creates a containerized version of the Vertica Kafka Scheduler, a standalone Java application that automatically consumes data from one or more Kafka topics and loads structured data into Vertica.

The Docker image is based on [alpine:3.14](https://hub.docker.com/_/alpine) and includes the [openjdk8-jre](https://hub.docker.com/_/openjdk).

## Prerequisites

- [Docker Desktop](https://www.docker.com/get-started/), [Docker Engine](https://docs.docker.com/engine/install/), or another container runtime
- [Vertica installation](https://www.vertica.com/docs/latest/HTML/Content/Authoring/InstallationGuide/Other/InstallingManually.htm)
- Docker Compose


## Supported Platforms



## Repository overview

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



## Testing the container

If you build a 


## Building the vertica-kafka container

This repository provides a Makefile to build the vertica-kafka-scheduler with build conditions.

When you build the container, the build process requires access to the Java libraries for your Vertica installation. By default, the Makefile assumes that you installed Vertica in the `/opt` directory. If you installed Vertica in a different directory, set the `VERTICA_INSTALL` configuration option when you build the container:

```bash
$ make build VERTICA_INSTALL=/path/to/vertica
```

### Build variables

| Variable        | Description |
|:----------------|:------------|
| VERTICA_INSTALL | The location of your Vertica binary installation. Define this variable if you want to copy the local install of the Java libraries.<br>**Default**: `/opt/vertica`. |
| VERTICA_VERSION | The Vertica version that you want to use to build the vkconfig container.<br>**Default**: `latest`.|
| VERSION | ?????????? |

## Environment setup

### Configuration file 

### Log configuration file 

### Writable log directory 



## Quickstart





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
