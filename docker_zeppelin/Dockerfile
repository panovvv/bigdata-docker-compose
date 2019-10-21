#FROM bigdata-docker-compose_master:latest
FROM panovvv/bigdata-base-image:2.1

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG ZEPPELIN_VERSION=0.8.2
ENV ZEPPELIN_HOME /usr/zeppelin
ENV ZEPPELIN_PACKAGE zeppelin-${ZEPPELIN_VERSION}-bin-all
RUN curl --progress-bar -L --retry 3 \
  "https://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/${ZEPPELIN_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/${ZEPPELIN_PACKAGE} ${ZEPPELIN_HOME} \
 && chown -R root:root ${ZEPPELIN_HOME}

ENV MASTER=yarn-client
ENV PATH="${PATH}:${ZEPPELIN_HOME}/bin"
ENV ZEPPELIN_CONF_DIR ${ZEPPELIN_HOME}/conf
COPY conf/interpreter.json ${ZEPPELIN_CONF_DIR}
ENV ZEPPELIN_ADDR=0.0.0.0

# Clean up
RUN rm -rf ${ZEPPELIN_HOME}/interpreter/alluxio \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/angular \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/bigquery \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/cassandra \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/elasticsearch \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/flink \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/groovy \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/hbase \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/ignite \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/kylin \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/lens \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/neo4j \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/pig \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/sap \
    && rm -rf ${ZEPPELIN_HOME}/interpreter/scio

HEALTHCHECK CMD curl -f http://host.docker.internal:${ZEPPELIN_PORT}/ || exit 1

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]