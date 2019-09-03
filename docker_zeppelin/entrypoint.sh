#!/bin/bash

# Zeppelin
mkdir -p $ZEPPELIN_HOME/logs/
nohup zeppelin-daemon.sh start > $ZEPPELIN_HOME/logs/zeppelin.log

# Blocking call to view all logs. This is what won't let container exit right away.
tail -f /dev/null $ZEPPELIN_HOME/logs/*

# Stop all
zeppelin-daemon.sh stop