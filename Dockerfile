FROM alpine:3.10.2

# Java and OS utils to download and exract images
RUN apk add --no-cache \
    curl=7.66.0-r0 \
    unzip=6.0-r4 \
    openjdk8=8.222.10-r0 \
    bash=5.0.0-r0 \
    coreutils=8.31-r0 \
    gawk=5.0.1-r0 \
    sed=4.7-r0 \
    grep=3.3-r0 \
    bc=1.07.1-r1 \
    procps=3.3.15-r0 \
    findutils=4.6.0-r1

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Hadoop
ARG HADOOP_VERSION=3.1.2
ENV HADOOP_HOME /usr/hadoop
RUN curl --progress-bar -L --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && mv /usr/hadoop-$HADOOP_VERSION $HADOOP_HOME \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R root:root $HADOOP_HOME

# Hive
ARG HIVE_VERSION=2.3.6
ENV HIVE_HOME=/usr/hive
ENV HIVE_CONF_DIR=$HIVE_HOME/conf
ENV PATH $PATH:$HIVE_HOME/bin
RUN curl --progress-bar -L \
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
RUN curl --progress-bar -L --retry 3 \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME
# For inscrutable reasons, Spark distribution doesn't include spark-hive.jar
# Livy attempts to load it though, and will throw
# java.lang.ClassNotFoundException: org.apache.spark.sql.hive.HiveContext
ARG SCALA_VERSION=2.11
RUN curl --progress-bar -L \
    "https://repo1.maven.org/maven2/org/apache/spark/spark-hive_$SCALA_VERSION/${SPARK_VERSION}/spark-hive_$SCALA_VERSION-${SPARK_VERSION}.jar" \
    --output "$SPARK_HOME/jars/spark-hive_$SCALA_VERSION-${SPARK_VERSION}.jar"

# Alternative to Spark setup above: clone from version branch and build a distribution.
#RUN git clone --progress --single-branch --branch branch-2.4 \
#    https://github.com/apache/spark.git
#ENV MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=512m"
#RUN /spark/dev/make-distribution.sh -Pyarn -Phadoop-3.2 -Dhadoop.version=$HADOOP_VERSION -Dhive.version=$HIVE_VERSION -Dhive.version.short=$HIVE_VERSION   \
#    -Phive -DskipTests clean package
#    && mv /spark/dist $SPARK_HOME \
#    && rm -rf /spark

# PySpark - comment out if you don't want it to save image space
RUN apk add --no-cache \
    python3=3.7.4-r0 \
    python3-dev=3.7.4-r0 \
 && ln -s /usr/bin/python3 /usr/bin/python

# SparkR - comment out if you don't want it to save image space
RUN apk add --no-cache \
    R=3.6.0-r1 \
    R-dev=3.6.0-r1 \
    libc-dev=0.7.1-r0 \
    g++=8.3.0-r0 \
 && R -e 'install.packages("knitr", repos = "http://cran.us.r-project.org")'

# Common settings
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH="$PATH:$JAVA_HOME/bin"
# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# Hadoop setup
ENV PATH="$PATH:$HADOOP_HOME/bin"
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"
ENV LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV HADOOP_LOG_DIR=${HADOOP_HOME}/logs
COPY conf/hadoop/core-site.xml $HADOOP_CONF_DIR
COPY conf/hadoop/hadoop-env.sh $HADOOP_CONF_DIR
COPY conf/hadoop/hdfs-site.xml $HADOOP_CONF_DIR
COPY conf/hadoop/mapred-site.xml $HADOOP_CONF_DIR
COPY conf/hadoop/workers $HADOOP_CONF_DIR
COPY conf/hadoop/yarn-site.xml $HADOOP_CONF_DIR
# Hadoop JVM crashes on Alpine when it tries to load native libraries.
# Alternatively, we can compile them https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/NativeLibraries.html
RUN mkdir $HADOOP_LOG_DIR  \
 && rm -rf $HADOOP_HOME/lib/native

# Hive setup
ENV PATH="$PATH:$HIVE_HOME/bin"
ENV HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$HIVE_HOME/lib/*
COPY conf/hive/hive-site.xml $HIVE_CONF_DIR/

# Spark setup
ENV PATH="$PATH:$SPARK_HOME/bin"
ENV SPARK_CONF_DIR="${SPARK_HOME}/conf"
ENV SPARK_LOG_DIR="${SPARK_HOME}/logs"
ENV SPARK_DIST_CLASSPATH="$HADOOP_CONF_DIR:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/yarn:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*"
COPY conf/hadoop/core-site.xml $SPARK_CONF_DIR/
COPY conf/hadoop/hdfs-site.xml $SPARK_CONF_DIR/
COPY conf/spark/spark-defaults.conf $SPARK_CONF_DIR/

# Spark with Hive
# TODO enable when they remove HIVE_STATS_JDBC_TIMEOUT
# https://github.com/apache/spark/commit/1d95dea30788b9f64c5e304d908b85936aafb238#diff-842e3447fc453de26c706db1cac8f2c4
# https://issues.apache.org/jira/browse/SPARK-13446
#ENV SPARK_DIST_CLASSPATH=$SPARK_DIST_CLASSPATH:$HIVE_HOME/lib/*
#COPY conf/hive/hive-site.xml $SPARK_CONF_DIR/
#RUN ln -s $SPARK_HOME/jars/scala-library-*.jar $HIVE_HOME/lib \
#    && ln -s $SPARK_HOME/jars/spark-core_*.jar $HIVE_HOME/lib \
#    && ln -s $SPARK_HOME/jars/spark-network-common_*.jar $HIVE_HOME/lib

# If YARN Web UI is up, then returns 0, 1 otherwise.
HEALTHCHECK CMD curl -f http://host.docker.internal:8080/ || exit 1

# Entry point: start all services and applications.
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]