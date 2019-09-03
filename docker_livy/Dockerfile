FROM docker-spark-zeppelin-livy

ARG LIVY_VERSION=0.6.0-incubating

ENV LIVY_HOME /usr/apache-livy-${LIVY_VERSION}-bin
ENV LIVY_CONF_DIR ${LIVY_HOME}/conf
ENV LIVY_PORT 8998
ENV MASTER spark://master:7077
RUN echo "Installing Livy..." && \
  curl --progress-bar -sL --retry 3 \
    "http://archive.apache.org/dist/incubator/livy/${LIVY_VERSION}/apache-livy-${LIVY_VERSION}-bin.zip" \
    -o ./apache-livy-${LIVY_VERSION}-bin.zip && \
  unzip ./apache-livy-${LIVY_VERSION}-bin.zip -d /usr && \
  rm -rf ./apache-livy-${LIVY_VERSION}-bin.zip && \
  mkdir ${LIVY_HOME}/logs && \
  chown -R root:root ${LIVY_HOME}
RUN echo "Configuring Livy..." && \
  echo "livy.server.port = ${LIVY_PORT}" >> ${LIVY_HOME}/conf/livy.conf && \
  echo "livy.spark.master = ${MASTER}" >> ${LIVY_HOME}/conf/livy.conf && \
  echo "livy.spark.deployMode = ${DEPLOY_MODE}" >> ${LIVY_HOME}/conf/livy.conf && \
  echo "livy.repl.enable-hive-context = true" >> ${LIVY_HOME}/conf/livy.conf && \
  echo "#!/bin/sh" >> ${LIVY_HOME}/conf/livy-env.sh && \
  echo "export JAVA_HOME=${JAVA_HOME}" >> ${LIVY_HOME}/conf/livy-env.sh && \
  echo "export SPARK_HOME=${SPARK_HOME}" >> ${LIVY_HOME}/conf/livy-env.sh && \
  echo "export SPARK_CONF_DIR=${SPARK_CONF_DIR}" >> ${LIVY_HOME}/conf/livy-env.sh && \
  echo "export HADOOP_HOME=${HADOOP_HOME}" >> ${LIVY_HOME}/conf/livy-env.sh && \
  echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> ${LIVY_HOME}/conf/livy-env.sh && \
  chmod 755 ${LIVY_HOME}/conf/livy-env.sh

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 8998

ENTRYPOINT ["/entrypoint.sh"]


