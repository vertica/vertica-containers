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
docker run vertica/kafka-scheduler vkconfig microbatch--help
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
