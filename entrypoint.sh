#!/bin/bash

# Hadoop
service ssh start
yes Y | hdfs namenode -format
start-dfs.sh
start-yarn.sh

# Hive
if [ ! -z "$HIVE_CONFIGURE" ]; then
  schematool -dbType postgres -initSchema
  hive --service metastore &
fi

# Spark
if [ -z "$SPARK_MASTER_ADDRESS" ]; then
  nohup $SPARK_HOME/bin/spark-class org.apache.spark.deploy.master.Master -h master > $SPARK_HOME/spark.log &
else
  nohup $SPARK_HOME/bin/spark-class org.apache.spark.deploy.worker.Worker $SPARK_MASTER_ADDRESS > $SPARK_HOME/spark.log &
fi


# Blocking call to view all logs. This is what won't let container exit right away.
tail -f /dev/null ${HADOOP_HOME}/logs/* $SPARK_HOME/spark.log

# Stop Hadoop
stop-yarn.sh
stop-dfs.sh
