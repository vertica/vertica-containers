#!/bin/bash

# this is a full example of configuring and running a scheduler.  It uses
# docker-compose to create a kafka and vertica service, then it

# first chose a unique project name for docker-compose
export COMPOSE_PROJECT_NAME=vkconfig
NETWORK=${COMPOSE_PROJECT_NAME}_scheduler
VOLUMES="${COMPOSE_PROJECT_NAME}_zookeeper_data ${COMPOSE_PROJECT_NAME}_kafka_data"

########################
# Debugging and Colors #
########################

# TO only run certain steps, export steps variable like so:
# steps="start setup run write" ./example.sh
: ${steps=start setup run write stop clean}

# see if sed can make the log output green to make it easier to diferentiate
green='sed --unbuffered -e s/\(.*\)/\o033[32m\1\o033[39m/' # for normal output
red='sed --unbuffered -e s/\(.*\)/\o033[31m\1\o033[39m/'   # for errors
blue='sed --unbuffered -e s/\(.*\)/\o033[34m\1\o033[39m/'  # for log output
if ! echo | $green >/dev/null 2>&1; then
  green=cat
  red=cat
  blue=cat
fi

##########################
# SETUP TEST ENVIRONMENT #
##########################
if [[ $steps =~ start ]]; then

# start servers
# docker-compose uses colors, so don't override
docker-compose up -d --force-recreate

# create a directory for log output
mkdir -p log

# create and start a database
docker-compose exec vertica /opt/vertica/bin/admintools -t create_db --database=example --password= --hosts=localhost || \
  docker-compose exec vertica /opt/vertica/bin/admintools -t start_db --database=example --password= --hosts=localhost | $green

# create a simple table to store messages
docker-compose exec vertica vsql -c 'create flex table KafkaFlex()' | $green

# create an operator
docker-compose exec vertica vsql -c 'create user JimmyKafka' | $green

# create a resource pool
docker-compose exec vertica vsql -c 'create resource pool Scheduler_pool plannedconcurrency 1' | $green

# create a couple topics
docker-compose exec kafka kafka-run-class.sh kafka.admin.TopicCommand --create --partitions 10 --replication-factor 1 --topic KafkaTopic1 --bootstrap-server kafka:9092 | $green
docker-compose exec kafka kafka-run-class.sh kafka.admin.TopicCommand --create --partitions 10 --replication-factor 1 --topic KafkaTopic2 --bootstrap-server kafka:9092 | $green

fi
###################
# SETUP SCHEDULER #
###################
if [[ $steps =~ setup ]]; then

# create scheduler
# set the target table
# set the parser
# set the kafka server
# define a couple sources (topics)
# define a couple microbatches
# (using one "docker run" because the startup costs add up)
docker run \
  -v $PWD/example.conf:/etc/vkconfig.conf \
  --network $NETWORK \
  vertica/kafka-scheduler bash -c "
    vkconfig scheduler \
      --conf /etc/vkconfig.conf \
      --frame-duration 00:00:10 \
      --create \
      --operator JimmyKafka \
      --eof-timeout-ms 2000 \
      --config-refresh 00:01:00 \
      --new-source-policy START \
      --resource-pool Scheduler_pool; \
    vkconfig target --add \
      --conf /etc/vkconfig.conf \
      --target-schema public \
      --target-table KafkaFlex; \
    vkconfig load-spec --add \
      --conf /etc/vkconfig.conf \
      --load-spec KafkaSpec \
      --parser kafkajsonparser \
      --load-method DIRECT \
      --message-max-bytes 1000000; \
    vkconfig cluster --add \
      --conf /etc/vkconfig.conf \
      --cluster KafkaCluster \
      --hosts kafka:9092; \
    vkconfig source --add \
      --conf /etc/vkconfig.conf \
      --source KafkaTopic1 \
      --cluster KafkaCluster \
      --partitions 10; \
    vkconfig source --add \
      --conf /etc/vkconfig.conf \
      --source KafkaTopic2 \
      --cluster KafkaCluster \
      --partitions 10; \
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
    vkconfig microbatch --add \
      --conf /etc/vkconfig.conf \
      --microbatch KafkaBatch2 \
      --add-source KafkaTopic2 \
      --add-source-cluster KafkaCluster \
      --target-schema public \
      --target-table KafkaFlex \
      --rejection-schema public \
      --rejection-table KafkaFlex_rej \
      --load-spec KafkaSpec; \
  " | $green

fi
#####################
# RUN THE SCHEDULER #
#####################
if [[ $steps =~ run ]]; then

# run this in the background
# don't color the log output becasue it can mess up the formatting
docker run \
  -v $PWD/example.conf:/etc/vkconfig.conf \
  -v $PWD/vkafka-log-config-debug.xml:/opt/vertica/packages/kafka/config/vkafka-log-config.xml \
  -v $PWD/log:/opt/vertica/log \
  --network $NETWORK \
  --user $(id -u):$(id -g) \
  --name kafka_scheduler \
  vertica/kafka-scheduler \
    vkconfig launch \
      --conf /etc/vkconfig.conf | $blue &
SCHEDULER_PID=$!

fi
#####################
# SEND TO KAFKA AND #
# SEE IT IN VERTICA #
#####################
if [[ $steps =~ write ]]; then

# fake loop so we can 'break'
while true; do

# write a test subject with a caffine addiction
docker-compose exec kafka bash -c 'echo "{\"Test Subject\":\"98101\", \"Diagnosis\":\"Caffine Addiction\"}" | kafka-console-producer.sh \
  --topic KafkaTopic1 \
  --bootstrap-server localhost:9092' | grep . | $green

# Make sure it's there
# This produces an eroneous error message, so grep is used to only print messages
docker-compose exec kafka kafka-console-consumer.sh --topic KafkaTopic1 --bootstrap-server localhost:9092 --from-beginning --timeout-ms 1000 | grep '^{' | $green

# wait for it to appear in vertica
delay=0
while ! docker-compose exec vertica vsql -t -c "select compute_flextable_keys_and_build_view('KafkaFlex'); select Diagnosis from KafkaFlex_view where \"Test Subject\" = '98101'" | grep Caffine >/dev/null 2>&1; do
  if ((delay++ > 20)); then
    echo "ERROR: Should have appeared within the ~10 second frame duration." | $red
    break 2
  fi
  echo "Waiting ($delay) for Kafka test message containing 'Caffine'..." | $green
  sleep 1;
done

docker-compose exec vertica vsql -c "select * from KafkaFlex_view" | $green

# write a test subject with a cold feet problem
docker-compose exec kafka bash -c 'echo "{\"Test Subject\":\"99782\", \"Diagnosis\":\"Cold Feet\"}" | kafka-console-producer.sh \
  --topic KafkaTopic2 \
  --bootstrap-server localhost:9092' | grep . | $green

# Make sure it's there
docker-compose exec kafka kafka-console-consumer.sh --topic KafkaTopic2 --bootstrap-server localhost:9092 --from-beginning --timeout-ms 1000 | grep '^{' | $green

delay=0
while ! docker-compose exec vertica vsql -t -c "select compute_flextable_keys_and_build_view('KafkaFlex'); select Diagnosis from KafkaFlex_view where \"Test Subject\" = '99782'" | grep Cold >/dev/null 2>&1; do
  if ((delay++ > 20)); then
    echo "ERROR: Should have appeared within the ~10 second frame duration." | $red
    break 2
  fi
  echo "Waiting ($delay) for Kafka test message containing 'Cold Feet'..." | $green
  sleep 1;
done

break
done

docker-compose exec vertica vsql -c "select * from KafkaFlex_view" | $green
if (( $(docker-compose exec vertica vsql -t -c "select count(*) from KafkaFlex_rej" | head -1 | sed 's/\s//g') )); then
  docker-compose exec vertica vsql -c "select * from KafkaFlex_rej" | $red
fi

fi
######################
# STOP THE SCHEDULER #
######################
if [[ $steps =~ stop ]]; then

echo SHUTTING DOWN... | $green

# a graceful shutdown request
docker exec \
  --user $(id -u):$(id -g) \
  kafka_scheduler \
    killall java 2>&1 | $red

delay=0
: ${SCHEDULER_PID=$(ps -ef | grep 'vkconfig_scheduler\ .*vkconfig launch' | awk '{ print $2 }')}
while kill -0 $SCHEDULER_PID >/dev/null 2>&1; do
  sleep 1;
  if ((delay++ > 20)); then
    # not so graceful
    echo "Scheduler didn't stop gracefully" | $red
    docker stop kafka_scheduler 2>&1 | $red
    break;
  fi
done

docker rm kafka_scheduler 2>&1 | $green

fi
###############################
# DELETE THE TEST ENVIRONMENT #
###############################
if [[ $steps =~ clean ]]; then

# docker-compose uses colors, so don't override
docker-compose down
docker volume rm $VOLUMES 2>&1 | $green
fi
