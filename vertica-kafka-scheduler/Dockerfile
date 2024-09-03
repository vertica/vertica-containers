FROM alpine:3.20
RUN apk add --no-cache openjdk8-jre bash

RUN mkdir -p /opt/vertica/log
RUN chmod 777 /opt/vertica/log

COPY kafka /opt/vertica/packages/kafka
RUN rm -rf /opt/vertica/packages/kafka/bin/kafkacat /opt/vertica/packages/kafka/lib/*.so /opt/vertica/packages/kafka/ddl /opt/vertica/packages/kafka/examples

COPY java /opt/vertica/java

RUN touch /etc/vkconfig.conf
RUN touch /etc/keystore.jks
RUN touch /etc/truststore.jks

RUN adduser -D -s /bin/bash vksched
USER vksched

ENV PATH=/opt/vertica/packages/kafka/bin:$PATH
