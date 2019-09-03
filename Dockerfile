FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

# Java, Python and OS utils to download and exract images
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl=7.58.0-2ubuntu3.7 \
        unzip=6.0-21ubuntu1 \
        ssh=1:7.6p1-4ubuntu0.3 \
        python3.7=3.7.3-2~18.04.1 \
        libpython3.7=3.7.3-2~18.04.1 \
        python3.7-dev=3.7.3-2~18.04.1 \
        openjdk-8-jdk-headless=8u222-b10-1ubuntu1~18.04.1 \
 && ln -s /usr/bin/python3.7 /usr/bin/python \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Hadoop
ARG HADOOP_VERSION=3.2.0
ENV HADOOP_HOME /usr/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl --progress-bar -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && mv /usr/hadoop-$HADOOP_VERSION $HADOOP_HOME \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R root:root $HADOOP_HOME

# Hive
ARG HIVE_VERSION=2.3.6
#3.1.2
ENV HIVE_HOME=/usr/hive
ENV HIVE_CONF_DIR=$HIVE_HOME/conf
ENV PATH $PATH:$HIVE_HOME/bin
RUN curl --progress-bar -sL \
  "https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz" \
    | gunzip \
    | tar -x -C /usr/ \
  && mv /usr/apache-hive-${HIVE_VERSION}-bin $HIVE_HOME \
  && chown -R root:root $HIVE_HOME \
  && mkdir -p $HIVE_HOME/hcatalog/var/log \
  && mkdir -p $HIVE_HOME/var/log \
  && mkdir -p /data/hive/ \
  && mkdir -p $HIVE_CONF_DIR \
  && chmod 777 $HIVE_HOME/hcatalog/var/log \
  && chmod 777 $HIVE_HOME/var/log

# Spark
ARG SPARK_VERSION=2.4.4
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /usr/spark
RUN curl --progress-bar -sL --retry 3 \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME
#RUN git clone https://github.com/apache/spark.git \
#    && mv ./spark $SPARK_HOME \
#    && cd $SPARK_HOME \
#    && rm ./sql/hive/src/test/java/org/apache/spark/sql/hive/JavaDataFrameSuite.java \
#    && ./build/mvn -Pyarn -Phadoop-3.2 -Dhadoop.version=$HADOOP_VERSION -Dhive.version=$HIVE_VERSION -Dhive.version.short=$HIVE_VERSION   \
#        -Phive -DskipTests clean package
#RUN git clone https://github.com/apache/spark.git
#ENV MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=512m"
#RUN rm /spark/sql/hive/src/test/java/org/apache/spark/sql/hive/JavaDataFrameSuite.java \
#    && sed -i 's/<maven.version>3.6.1/<maven.version>3.6.2/g' /spark/pom.xml \
#    && /spark/dev/make-distribution.sh -Pyarn -Punix \
#        -Phadoop-provided -Phadoop-3.2 -Dhadoop.version=$HADOOP_VERSION \
#        -Phive-provided -Dhive.version=$HIVE_VERSION -Dhive.version.short=$HIVE_VERSION \
#        -DskipTests \
#    && mv /spark/dist $SPARK_HOME \
#    && rm -rf /spark

# Common settings
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# Hadoop setup
ENV PATH="$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin"
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"
ENV LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH
COPY conf/hadoop/core-site.xml $HADOOP_HOME/etc/hadoop/
COPY conf/hadoop/hadoop-env.sh $HADOOP_HOME/etc/hadoop/
COPY conf/hadoop/hdfs-site.xml $HADOOP_HOME/etc/hadoop/
COPY conf/hadoop/mapred-site.xml $HADOOP_HOME/etc/hadoop/
COPY conf/hadoop/workers $HADOOP_HOME/etc/hadoop/
COPY conf/hadoop/yarn-site.xml $HADOOP_HOME/etc/hadoop/
RUN mkdir $HADOOP_HOME/logs
#RUN export HADOOP_DATANODE_OPTS="$HADOOP_DATANODE_OPTS"

# Hive setup
ENV PATH="$PATH:$HIVE_HOME/bin"
ENV HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$HIVE_HOME/lib/*
COPY conf/hive/hive-site.xml $HIVE_CONF_DIR/

# Spark setup
ENV PATH="$PATH:$SPARK_HOME/bin"
ENV SPARK_CONF_DIR="$SPARK_HOME/conf"
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/yarn:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*"
COPY conf/hadoop/core-site.xml $SPARK_CONF_DIR/
COPY conf/hadoop/hdfs-site.xml $SPARK_CONF_DIR/
COPY conf/spark/spark-defaults.conf $SPARK_CONF_DIR/

# Hive on Spark
# https://cwiki.apache.org/confluence/display/Hive/Hive+on+Spark%3A+Getting+Started
#ENV SPARK_DIST_CLASSPATH=$SPARK_DIST_CLASSPATH:$HIVE_HOME/lib/*
#COPY conf/hive/hive-site.xml $SPARK_CONF_DIR/
#RUN ln -s $SPARK_HOME/jars/scala-library-*.jar $HIVE_HOME/lib \
#    && ln -s $SPARK_HOME/jars/spark-core_*.jar $HIVE_HOME/lib \
#    && ln -s $SPARK_HOME/jars/spark-network-common_*.jar $HIVE_HOME/lib
#ARG SCALA_VERSION=2.12
#RUN curl --progress-bar -sL \
#    "https://repo1.maven.org/maven2/org/apache/spark/spark-hive_$SCALA_VERSION/${SPARK_VERSION}/spark-hive_$SCALA_VERSION-${SPARK_VERSION}.jar" \
#    --output "$SPARK_HOME/jars/spark-hive_$SCALA_VERSION-${SPARK_VERSION}.jar"

# If YARN Web UI is up, then returns 0, 1 otherwise.
HEALTHCHECK CMD curl -f http://host.docker.internal:8088/ || exit 1

# Entry point: start all services and applications.
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]