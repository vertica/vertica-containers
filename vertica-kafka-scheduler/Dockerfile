FROM wal-artifactory.rocketsoftware.com:6642/rfcurated/rockylinux:rl9-rfcurated
RUN dnf -y update \
	&& dnf -y --setopt=obsoletes=0 install java-17-openjdk-headless bash shadow-utils \
	&& dnf clean all \
	&& rm -rf /var/cache/dnf

RUN mkdir -p /opt/vertica/log
RUN chmod 777 /opt/vertica/log

COPY kafka /opt/vertica/packages/kafka
RUN rm -rf /opt/vertica/packages/kafka/bin/kafkacat /opt/vertica/packages/kafka/lib/*.so /opt/vertica/packages/kafka/ddl /opt/vertica/packages/kafka/examples

COPY java /opt/vertica/java

RUN touch /etc/vkconfig.conf
RUN touch /etc/keystore.jks
RUN touch /etc/truststore.jks

RUN useradd --create-home --shell /bin/bash vksched
USER vksched

ENV PATH=/opt/vertica/packages/kafka/bin:$PATH
