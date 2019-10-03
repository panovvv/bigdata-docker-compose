#!/bin/bash

# Hadoop and YARN
if [ ! -z "${HADOOP_DATANODE_UI_PORT}" ]; then
  echo "Replacing default datanode UI port 9864 with ${HADOOP_DATANODE_UI_PORT}"
  sed -i "$ i\<property><name>dfs.datanode.http.address</name><value>0.0.0.0:${HADOOP_DATANODE_UI_PORT}</value></property>" ${HADOOP_CONF_DIR}/hdfs-site.xml
fi
if [ "${HADOOP_NODE}" == "namenode" ]; then
  hdfs namenode -format
  hdfs --daemon start namenode
  hdfs --daemon start secondarynamenode
  yarn --daemon start resourcemanager
#  mapred --daemon start historyserver
fi
if [ "${HADOOP_NODE}" == "datanode" ]; then
  hdfs --daemon start datanode
  yarn --daemon start nodemanager
fi

# Hive
if [ ! -z "${HIVE_CONFIGURE}" ]; then
  schematool -dbType postgres -initSchema

  # Start metastore service.
  hive --service metastore &

  # JDBC Server.
  hiveserver2 &
fi

# Spark
if [ -z "${SPARK_MASTER_ADDRESS}" ]; then
  # Spark on YARN
  SPARK_JARS_HDFS_PATH=/spark-jars
  hadoop fs -test -d ${SPARK_JARS_HDFS_PATH}
  if [ $? -ne 0 ]; then
    hadoop dfs -copyFromLocal ${SPARK_HOME}/jars ${SPARK_JARS_HDFS_PATH}
  fi
  ${SPARK_HOME}/sbin/start-master.sh -h master &
else
  ${SPARK_HOME}/sbin/start-slave.sh ${SPARK_MASTER_ADDRESS} &
fi

# Blocking call to view all logs. This is what won't let container exit right away.
tail -f /dev/null ${HADOOP_LOG_DIR}/* ${SPARK_HOME}/logs/*

# Stop all
if [ "${HADOOP_NODE}" == "namenode" ]; then
  hdfs namenode -format
  hdfs --daemon stop namenode
  hdfs --daemon stop secondarynamenode
  yarn --daemon stop resourcemanager
#  mapred --daemon stop historyserver
fi
if [ "${HADOOP_NODE}" == "datanode" ]; then
  hdfs --daemon stop datanode
  yarn --daemon stop nodemanager
fi