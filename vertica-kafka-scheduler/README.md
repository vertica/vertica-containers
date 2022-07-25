# Vertica-Kafka Scheduler

This Docker image runs the Vertica-Kafka Scheduler.  It requires Docker or
some compatible container environment.  

## Quickstart

If you're just trying to run the scheduler in a docker container, you don't
need this repo.  Install docker and run it.
```
#Command line help messages
docker run vertica/kafka-scheduler vkconfig help
docker run vertica/kafka-scheduler vkconfig scheduler --help
docker run vertica/kafka-scheduler vkconfig cluster --help
docker run vertica/kafka-scheduler vkconfig source --help
docker run vertica/kafka-scheduler vkconfig target --help
docker run vertica/kafka-scheduler vkconfig load-spec --help
docker run vertica/kafka-scheduler vkconfig microbatch--help
# using a conf file
docker run -it -v $PWD/vkconfig.conf:/tmp/vkconfig.conf vertica/kafka-scheduler vkconfig scheduler --conf /tmp/vkconfig.conf ...
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
