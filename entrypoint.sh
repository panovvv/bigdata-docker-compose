#!/bin/bash

# Hadoop and YARN
service ssh start
yes Y | hdfs namenode -format
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

# Hive
if [ ! -z "$HIVE_CONFIGURE" ]; then
  schematool -dbType postgres -initSchema
  hive --service metastore &
fi

# Spark on YARN
SPARK_JARS_HDFS_PATH=/spark-jars
hadoop fs -test -d $SPARK_JARS_HDFS_PATH
if [ $? -ne 0 ]; then
  hadoop fs -put $SPARK_HOME/jars /spark-jars
fi

# Spark
if [ -z "$SPARK_MASTER_ADDRESS" ]; then
  nohup $SPARK_HOME/sbin/start-master.sh -h master > $SPARK_HOME/spark.log &
else
  nohup $SPARK_HOME/sbin/start-slave.sh $SPARK_MASTER_ADDRESS > $SPARK_HOME/spark.log &
fi

# Blocking call to view all logs. This is what won't let container exit right away.
tail -f /dev/null ${HADOOP_HOME}/logs/* $SPARK_HOME/logs/* $SPARK_HOME/spark.log

# Stop all
$HADOOP_HOME/sbin/stop-yarn.sh
$HADOOP_HOME/sbin/stop-dfs.sh
$SPARK_HOME/sbin/stop-all.sh