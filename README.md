# Big data playground: Cluster with Hadoop, Hive, Spark, Zeppelin and Livy via Docker-compose.

I wanted to have the ability to play around with various big data
applications as effortlessly as possible,
namely those found in Amazon EMR.
Ideally, that would be something that can be brought up and torn down
in one command. This is how this repository came to be!

*Software:*

[Hadoop 3.2.0 in Fully Distributed (Multi-node) Mode](https://hadoop.apache.org/) 

[Hive 3.1.2 ](https://hadoop.apache.org/) 

[Spark 2.4.4 in YARN mode](https://spark.apache.org/) 

[Zeppelin 0.8.1](https://zeppelin.apache.org/) 

[Livy 0.6.0-incubating](https://livy.incubator.apache.org/docs/latest/rest-api.html)

## Usage

Clone:
```bash
git clone https://github.com/panovvv/bigdata-docker-compose.git
```
You should dedicate more RAM to Docker than it does by default
(2Gb on my machine with 16Gb RAM). Otherwise applications (ResourceManager in my case)
will quit sporadically and you'll see messages like this one in logs:
<pre>
current-datetime INFO org.apache.hadoop.util.JvmPauseMonitor: Detected pause in JVM or host machine (eg GC): pause of approximately 1234ms
No GCs detected
</pre>
Increasing memory to 8G solved all those mysterious problems for me.

Bring everything up:
```bash
cd bigdata-docker-compose
docker-compose up -d
```

To shut the whole thing down, run this from the same folder:
```bash
docker-compose down
```

## Checking if everything plays well together
* Hadoop and YARN:

Check [YARN Web UI (localhost:8088)](http://localhost:8088/). You should see 2 active nodes there.

Then, [Hadoop Master Node UI (localhost:9870)](http://localhost:9870), worker UIs at
[http://localhost:9864](http://localhost:9864) 
( TODO and [http://localhost:9865](http://localhost:9865)): all of those
URLs should result in a page.

Open up a shell in the master node.
```bash
docker-compose exec master bash
jps
```
Jps command outputs a list of running Java processes,
which on Hadoop Namenode/Spark Master node should include those
(not necessarily in this order and those IDs):
<pre>
123 SecondaryNameNode
456 ResourceManager
789 Jps
234 Master
567 NameNode
</pre>

Then let's see if YARN can see all resources we have (2 worker nodes):
```bash
yarn node -list
```
<pre>
current-datetime INFO client.RMProxy: Connecting to ResourceManager at master/172.28.1.1:8032
Total Nodes:2
         Node-Id	     Node-State	Node-Http-Address	Number-of-Running-Containers
   worker1:45019	        RUNNING	     worker1:8042	                           0
   worker2:41001	        RUNNING	     worker2:8042	                           0
</pre>

HDFS (Hadoop distributed file system) condition:
```bash
hdfs dfsadmin -report
```
<pre>
Live datanodes (2):
Name: 172.28.1.2:9866 (worker1)
...
Name: 172.28.1.3:9866 (worker2)
</pre>

Now we'll upload a file into HDFS and see that it's visible from all
nodes:
```bash
hadoop fs -put /data/grades.csv /
hadoop fs -ls /
```
<pre>
Found 1 items
-rw-r--r--   2 root supergroup  ... /grades.csv
</pre>

Ctrl+D out of master now. Repeat for remaining nodes 
(there's 3 total: master, worker1 and worker2):

```bash
docker-compose exec worker1 bash
hadoop fs -ls /
```
<pre>
Found 1 items
-rw-r--r--   2 root supergroup  ... /grades.csv
</pre>

While we're on nodes other than Hadoop Namenode/Spark Master node,
jps command output should include DataNode and Worker now instead of
NameNode and Master:
```bash
jps
```
<pre>
123 NodeManager
456 RunJar
789 Worker
234 Jps
567 DataNode
</pre>

* Hive
Prereqisite: there's a file grades.csv stored in HDFS ( hadoop fs -put /data/grades.csv / )
```bash
docker-compose exec master bash
hive
```
```sql
CREATE TABLE grades(
    `Last name` STRING,
    `First name` STRING,
    `SSN` STRING,
    `Test1` DOUBLE,
    `Test2` INT,
    `Test3` DOUBLE,
    `Test4` DOUBLE,
    `Final` DOUBLE,
    `Grade` STRING)
COMMENT 'https://people.sc.fsu.edu/~jburkardt/data/csv/csv.html'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
tblproperties("skip.header.line.count"="1");

LOAD DATA INPATH '/grades.csv' INTO TABLE grades;

SELECT * FROM grades;
-- OK
-- Alfalfa	Aloysius	123-45-6789	40.0	90	100.0	83.0	49.0	D-
-- Alfred	University	123-12-1234	41.0	97	96.0	97.0	48.0	D+
-- Gerty	Gramma	567-89-0123	41.0	80	60.0	40.0	44.0	C
-- Android	Electric	087-65-4321	42.0	23	36.0	45.0	47.0	B-
-- Bumpkin	Fred	456-78-9012	43.0	78	88.0	77.0	45.0	A-
-- Rubble	Betty	234-56-7890	44.0	90	80.0	90.0	46.0	C-
-- Noshow	Cecil	345-67-8901	45.0	11	-1.0	4.0	43.0	F
-- Buff	Bif	632-79-9939	46.0	20	30.0	40.0	50.0	B+
-- Airpump	Andrew	223-45-6789	49.0	1	90.0	100.0	83.0	A
-- Backus	Jim	143-12-1234	48.0	1	97.0	96.0	97.0	A+
-- Carnivore	Art	565-89-0123	44.0	1	80.0	60.0	40.0	D+
-- Dandy	Jim	087-75-4321	47.0	1	23.0	36.0	45.0	C+
-- Elephant	Ima	456-71-9012	45.0	1	78.0	88.0	77.0	B-
-- Franklin	Benny	234-56-2890	50.0	1	90.0	80.0	90.0	B-
-- George	Boy	345-67-3901	40.0	1	11.0	-1.0	4.0	B
-- Heffalump	Harvey	632-79-9439	30.0	1	20.0	30.0	40.0	C
-- Time taken: 3.324 seconds, Fetched: 16 row(s)
```

Ctrl+D back to bash. Check if the file's been loaded to Hive warehouse
directory:

```bash
hadoop fs -ls /usr/hive/warehouse/grades
```
<pre>
Found 1 items
-rw-r--r--   2 root supergroup  ... /usr/hive/warehouse/grades/grades.csv
</pre>

The table we just created should be accessible from all nodes, let's
verify that now:
```bash
docker-compose exec worker2 bash
hive
```
```sql
SELECT * FROM grades;
```
You should be able to see the same table.
* Spark
Open up [Spark Master Web UI (localhost:8080)](http://localhost:8080/):
<pre>
Workers (2)
Worker Id	Address	State	Cores	Memory
worker-timestamp-172.28.1.3-8882	172.28.1.3:8882	ALIVE	2 (0 Used)	1024.0 MB (0.0 B Used)
worker-timestamp-172.28.1.2-8881	172.28.1.2:8881	ALIVE	2 (0 Used)	1024.0 MB (0.0 B Used)
</pre>

,also worker UIs at  [localhost:8081](http://localhost:8081/)
and  [localhost:8082](http://localhost:8082/). All those pages should be
accessible.

Let's run some sample jobs now:
```bash
docker-compose exec master bash
run-example SparkPi 10
#, or you can do the same via spark-submit:
spark-submit --class org.apache.spark.examples.SparkPi \
    --master yarn \
    --deploy-mode client \
    --driver-memory 4g \
    --executor-memory 2g \
    --executor-cores 1 \
    $SPARK_HOME/examples/jars/spark-examples*.jar \
    10
```
<pre>
INFO spark.SparkContext: Running Spark version 2.4.4
INFO spark.SparkContext: Submitted application: Spark Pi
...
INFO yarn.Client: Application report for application_1567375394688_0001 (state: ACCEPTED)
...
INFO yarn.Client: Application report for application_1567375394688_0001 (state: RUNNING)
...
INFO scheduler.DAGScheduler: Job 0 finished: reduce at SparkPi.scala:38, took 1.102882 s
Pi is roughly 3.138915138915139
...
INFO util.ShutdownHookManager: Deleting directory /tmp/spark-81ea2c22-d96e-4d7c-a8d7-9240d8eb22ce
</pre>

```bash
hadoop fs -put /data/grades.csv /
spark-shell
```
```scala
spark.range(1000 * 1000 * 1000).count()
val df = spark.read.format("csv").option("header", "true").load("/grades.csv")
df.show()
```
<pre>
res0: Long = 1000000000

df: org.apache.spark.sql.DataFrame = [Last name: string, First name: string ... 7 more fields]

+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
|Last name|First name|        SSN|Test1|Test2|Test3|Test4|Final|Grade|
+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
|  Alfalfa|  Aloysius|123-45-6789|   40|   90|  100|   83|   49|   D-|
...
|Heffalump|    Harvey|632-79-9439|   30|    1|   20|   30|   40|    C|
+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
</pre>
```bash
pyspark
```
```python
spark.range(1000 * 1000 * 1000).count()
df = spark.read.format("csv").option("header", "true").load("/grades.csv")
df.show()
```
<pre>
1000000000

$same_table_as_above
</pre>
```python
# TODO SELECT TABLE from hive - dont create a new one
spark = SparkSession.builder.enableHiveSupport().getOrCreate()
spark.sql("SHOW DATABASES")
spark.sql("CREATE TABLE grades2( \
    `Last name` STRING,  \
    `First name` STRING,  \
    `SSN` STRING,  \
    `Test1` DOUBLE, \
    `Test2` INT, \
    `Test3` DOUBLE, \
    `Test4` DOUBLE, \
    `Final` DOUBLE, \
    `Grade` STRING) \
USING hive")
spark.sql("LOAD DATA INPATH '/grades.csv' INTO TABLE grades2")
spark.sql("SELECT * FROM grades2").show()
```
* Zeppelin
Zeppelin interface should be available at [http://localhost:8890](http://localhost:8890).
* Livy
Livy is at [http://localhost:8998](http://localhost:8998).
Try to poll the REST API:
```bash
curl --request GET \
  --url http://localhost:8998/sessions
```
>{"from": 0,"total": 0,"sessions": []}

## Doing a thing in ...

* Zeppelin:

create a new notebook in Zeppelin UI,
,paste this code and run the resulting paragraph:

```
%spark.pyspark

import sys;
df = sc.parallelize(range(10))
print(df.collect())
print(sys.version)
```
It should yield something like this:
```
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
3.5.2 (default, Nov 12 2018, 13:43:14) 
[GCC 5.4.0 20160609]
```

* Livy:

1) Create a session
```bash
curl --request POST \
  --url http://localhost:8998/sessions \
  --header 'content-type: application/json' \
  --data '{
	"kind": "pyspark"
}'
```

2) Post a statement
```bash
curl --request POST \
  --url http://localhost:8998/sessions/0/statements \
  --header 'content-type: application/json' \
  --data '{
	"code": "import sys;df = sc.parallelize(range(10));print(df.collect());print(sys.version)"
}'
```
3) Get the result:
```bash
curl --request GET \
  --url http://localhost:8998/sessions/0/statements
```
Here's what you're supposed to see in response:
```
{
  "total_statements": 1,
  "statements": [
    {
      "id": 0,
      "state": "available",
      "output": {
        "status": "ok",
        "execution_count": 0,
        "data": {
          "text/plain": "TODO"
        }
      }
    }
  ]
}
```

## TODO
docker run --rm -i hadolint/hadolint < Dockerfile
alpine
hive on spark https://cwiki.apache.org/confluence/display/Hive/Hive+on+Spark%3A+Getting+Started
generate ssh keys on the fly
remove all unnecessary conf properties.
try newer version of hive when 2.3.6 works with spark