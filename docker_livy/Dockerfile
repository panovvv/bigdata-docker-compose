#FROM bigdata-docker-compose_master:latest
FROM panovvv/bigdata-base-image:2.1

ARG LIVY_VERSION=0.6.0-incubating
ENV LIVY_HOME /usr/livy
ENV LIVY_CONF_DIR ${LIVY_HOME}/conf
RUN curl --progress-bar -L --retry 3 \
    "http://archive.apache.org/dist/incubator/livy/${LIVY_VERSION}/apache-livy-${LIVY_VERSION}-bin.zip" \
    -o ./apache-livy-${LIVY_VERSION}-bin.zip \
  && unzip -qq ./apache-livy-${LIVY_VERSION}-bin.zip -d /usr \
  && mv /usr/apache-livy-${LIVY_VERSION}-bin ${LIVY_HOME} \
  && rm -rf ./apache-livy-${LIVY_VERSION}-bin.zip \
  && mkdir ${LIVY_HOME}/logs \
  && chown -R root:root ${LIVY_HOME}

ENV LIVY_PORT 8998
ENV MASTER yarn
ENV DEPLOY_MODE client
COPY conf/livy.conf ${LIVY_CONF_DIR}/livy.conf

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

HEALTHCHECK CMD curl -f http://host.docker.internal:${LIVY_PORT}/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]


