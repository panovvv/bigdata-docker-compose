# Big data playground: Cluster with Hadoop, Hive, Spark, Zeppelin and Livy via Docker-compose.

Base image: [![Docker Build Status: Base](https://img.shields.io/docker/cloud/build/panovvv/bigdata-base-image.svg)](https://cloud.docker.com/repository/docker/panovvv/bigdata-base-image/builds)
[![Docker Pulls](https://img.shields.io/docker/pulls/panovvv/bigdata-base-image.svg)](https://hub.docker.com/r/panovvv/bigdata-base-image)
[![Docker Stars](https://img.shields.io/docker/stars/panovvv/bigdata-base-image.svg)](https://hub.docker.com/r/panovvv/bigdata-base-image)

Zeppelin image: [![Docker Build Status: Zeppelin](https://img.shields.io/docker/cloud/build/panovvv/bigdata-zeppelin.svg)](https://cloud.docker.com/repository/docker/panovvv/bigdata-zeppelin/builds)
[![Docker Pulls](https://img.shields.io/docker/pulls/panovvv/bigdata-zeppelin.svg)](https://hub.docker.com/r/panovvv/bigdata-zeppelin)
[![Docker Stars](https://img.shields.io/docker/stars/panovvv/bigdata-zeppelin.svg)](https://hub.docker.com/r/panovvv/bigdata-zeppelin)

Livy image: [![Docker Build Status: Livy](https://img.shields.io/docker/cloud/build/panovvv/bigdata-livy.svg)](https://cloud.docker.com/repository/docker/panovvv/bigdata-livy/builds)
[![Docker Pulls](https://img.shields.io/docker/pulls/panovvv/bigdata-livy.svg)](https://hub.docker.com/r/panovvv/bigdata-livy)
[![Docker Stars](https://img.shields.io/docker/stars/panovvv/bigdata-livy.svg)](https://hub.docker.com/r/panovvv/bigdata-livy)

I wanted to have the ability to play around with various big data
applications as effortlessly as possible,
namely those found in Amazon EMR.
Ideally, that would be something that can be brought up and torn down
in one command. This is how this repository came to be!

*Software:*

[Hadoop 3.2.0](http://hadoop.apache.org/docs/r3.2.0/) in Fully Distributed (Multi-node) Mode

[Hive 3.1.2](http://hive.apache.org/) with JDBC Server exposed

[Spark 2.4.4](https://spark.apache.org/docs/2.4.4/) in YARN mode (Spark Scala, PySpark and SparkR)

[Zeppelin 0.8.2](https://zeppelin.apache.org/docs/0.8.2/) 

[Livy 0.6.0-incubating](https://livy.apache.org/docs/0.6.0-incubating/rest-api.html)

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

* **data/** directory is mounted into every container, you can use this as
a storage both for files you want to process using Hive/Spark/whatever
and results of those computations.
* **livy_batches/** directory is where you have some sample code for
Livy batch processing mode. It's mounted to the node where Livy
is running. You can store your code there as well, or make use of the
universal **data/**.
* **zeppelin_notebooks/** contains, quite predictably, notebook files
for Zeppelin. Thanks to that, all your notebooks persist across runs.

Hive JDBC port is exposed to host:
* URI: `jdbc:hive2://localhost:10000`
* Driver: `org.apache.hive.jdbc.HiveDriver` (org.apache.hive:hive-jdbc:3.1.2)
* User and password: unused.

To shut the whole thing down, run this from the same folder:
```bash
docker-compose down
```

## Checking if everything plays well together
You can quickly check everything by opening the
[bundled Zeppelin notebook](http://localhost:8890/#/notebook/2EKGZ25MS)
and running all paragraphs.

Alternatively, to get a sense of
how it all works under the hood, follow the instructions below:

* Hadoop and YARN:

Check [YARN (Hadoop ResourceManager) Web UI
(localhost:8088)](http://localhost:8088/).
You should see 2 active nodes there.

Then, [Hadoop Name Node UI (localhost:9870)](http://localhost:9870),
Hadoop Data Node UIs at
[http://localhost:9864](http://localhost:9864) and [http://localhost:9865](http://localhost:9865):
all of those URLs should result in a page.

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
Found N items
...
-rw-r--r--   2 root supergroup  ... /grades.csv
...
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

Prerequisite: there's a file grades.csv stored in HDFS ( `hadoop fs -put /data/grades.csv /` )
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
, also worker UIs at  [localhost:8081](http://localhost:8081/)
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
    --driver-memory 2g \
    --executor-memory 1g \
    --executor-cores 1 \
    $SPARK_HOME/examples/jars/spark-examples*.jar \
    10
```
<pre>
INFO spark.SparkContext: Running Spark version 2.4.4
INFO spark.SparkContext: Submitted application: Spark Pi
..
INFO client.RMProxy: Connecting to ResourceManager at master/172.28.1.1:8032
INFO yarn.Client: Requesting a new application from cluster with 2 NodeManagers
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

Spark has 3 interactive shells: spark-shell to code in Scala,
pyspark for Python and sparkR for R. Let's try them all out:
```bash
hadoop fs -put /data/grades.csv /
spark-shell
```
```scala
spark.range(1000 * 1000 * 1000).count()

val df = spark.read.format("csv").option("header", "true").load("/grades.csv")
df.show()

df.createOrReplaceTempView("df")
spark.sql("SHOW TABLES").show()
spark.sql("SELECT * FROM df WHERE Final > 50").show()

//TODO SELECT TABLE from hive - not working for now.
spark.sql("SELECT * FROM grades").show()
```
<pre>
Spark context Web UI available at http://localhost:4040
Spark context available as 'sc' (master = yarn, app id = application_N).
Spark session available as 'spark'.

res0: Long = 1000000000

df: org.apache.spark.sql.DataFrame = [Last name: string, First name: string ... 7 more fields]

+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
|Last name|First name|        SSN|Test1|Test2|Test3|Test4|Final|Grade|
+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
|  Alfalfa|  Aloysius|123-45-6789|   40|   90|  100|   83|   49|   D-|
...
|Heffalump|    Harvey|632-79-9439|   30|    1|   20|   30|   40|    C|
+---------+----------+-----------+-----+-----+-----+-----+-----+-----+

+--------+---------+-----------+
|database|tableName|isTemporary|
+--------+---------+-----------+
|        |       df|       true|
+--------+---------+-----------+

+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
|Last name|First name|        SSN|Test1|Test2|Test3|Test4|Final|Grade|
+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
|  Airpump|    Andrew|223-45-6789|   49|    1|   90|  100|   83|    A|
|   Backus|       Jim|143-12-1234|   48|    1|   97|   96|   97|   A+|
| Elephant|       Ima|456-71-9012|   45|    1|   78|   88|   77|   B-|
| Franklin|     Benny|234-56-2890|   50|    1|   90|   80|   90|   B-|
+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
</pre>
Ctrl+D out of Scala shell now.

```bash
pyspark
```
```python
spark.range(1000 * 1000 * 1000).count()

df = spark.read.format('csv').option('header', 'true').load('/grades.csv')
df.show()

df.createOrReplaceTempView('df')
spark.sql('SHOW TABLES').show()
spark.sql('SELECT * FROM df WHERE Final > 50').show()

# TODO SELECT TABLE from hive - not working for now.
spark.sql('SELECT * FROM grades').show()
```
<pre>
1000000000

$same_tables_as_above
</pre>
Ctrl+D out of PySpark.

```bash
sparkR
```
```R
df <- as.DataFrame(list("One", "Two", "Three", "Four"), "This is as example")
head(df)

df <- read.df("/grades.csv", "csv", header="true")
head(df)
```
<pre>
  This is as example
1                One
2                Two
3              Three
4               Four

$same_tables_as_above
</pre>

* Amazon S3

From Hadoop:
```bash
hadoop fs -Dfs.s3a.impl="org.apache.hadoop.fs.s3a.S3AFileSystem" -Dfs.s3a.access.key="classified" -Dfs.s3a.secret.key="classified" -ls "s3a://bucket"
```

Then from PySpark:

```python
sc._jsc.hadoopConfiguration().set('fs.s3a.impl', 'org.apache.hadoop.fs.s3a.S3AFileSystem')
sc._jsc.hadoopConfiguration().set('fs.s3a.access.key', 'classified')
sc._jsc.hadoopConfiguration().set('fs.s3a.secret.key', 'classified')

df = spark.read.format('csv').option('header', 'true').option('sep', '\t').load('s3a://bucket/tabseparated_withheader.tsv')
df.show(5)
```

None of the commands above stores your credentials anywhere
(i.e. as soon as you'd shut down the cluster your creds are safe). More
persistent ways of storing the credentials are out of scope of this
readme.

* Zeppelin

Zeppelin interface should be available at [http://localhost:8890](http://localhost:8890).

You'll find a notebook called "test" in there, containing commands
to test integration with bash, Spark and Livy.

* Livy

Livy is at [http://localhost:8998](http://localhost:8998) (and yes,
there's a web UI as well as REST API on that port - just click the link).

* Livy Sessions:

Try to poll the REST API:
```bash
curl --request GET \
  --url http://localhost:8998/sessions
```
>{"from": 0,"total": 0,"sessions": []}

1) Create a session
```bash
curl --request POST \
  --url http://localhost:8998/sessions \
  --header 'content-type: application/json' \
  --data '{
	"kind": "pyspark"
}'
```

2) Wait for session to start (state will transition from "starting"
to "idle"):
```bash
curl --request GET \
  --url http://localhost:8998/sessions/0 | python -mjson.tool
```
>{"id":0, ... "state":"idle", ...

3) Post some statements
```bash
curl --request POST \
  --url http://localhost:8998/sessions/0/statements \
  --header 'content-type: application/json' \
  --data '{
	"code": "import sys;print(sys.version)"
}'
curl --request POST \
  --url http://localhost:8998/sessions/0/statements \
  --header 'content-type: application/json' \
  --data '{
	"code": "spark.range(1000 * 1000 * 1000).count()"
}'
```

4) Get the result:
```bash
curl --request GET \
  --url http://localhost:8998/sessions/0/statements | python -mjson.tool
```
```json
{
  "total_statements": 2,
  "statements": [
    {
      "id": 0,
      "code": "import sys;print(sys.version)",
      "state": "available",
      "output": {
        "status": "ok",
        "execution_count": 0,
        "data": {
          "text/plain": "3.7.3 (default, Apr  3 2019, 19:16:38) \n[GCC 8.0.1 20180414 (experimental) [trunk revision 259383]]"
        }
      },
      "progress": 1.0
    },
    {
      "id": 1,
      "code": "spark.range(1000 * 1000 * 1000).count()",
      "state": "available",
      "output": {
        "status": "ok",
        "execution_count": 1,
        "data": {
          "text/plain": "1000000000"
        }
      },
      "progress": 1.0
    }
  ]
}
```
* Livy Batches:
```bash
curl --request POST \
  --url http://localhost:8998/batches \
  --header 'content-type: application/json' \
  --data '{
	"file": "local:/livy_batches/example.py",
	"pyFiles": [
		"local:/livy_batches/example.py"
	],
	"args": [
		"10"
	]
}'
curl --request GET \
  --url http://localhost:8998/batches/0 | python -mjson.tool
# You can manipulate 'to' and 'from' params to get all log lines,
# no more than 100 at a time is supported.
curl --request GET \
  --url 'http://localhost:8998/batches/0/log?from=100&to=200' | python -mjson.tool
```
```json
{
  "id": 0,
  "from": 100,
  "total": 149,
  "log": [
    "...",
    "INFO scheduler.DAGScheduler: Job 0 finished: reduce at /livy_batches/example.py:28, took 1.733666 s",
    "Pi is roughly 3.142788",
    "3.7.3 (default, Apr  3 2019, 19:16:38) ",
    "[GCC 8.0.1 20180414 (experimental) [trunk revision 259383]]",
    "INFO server.AbstractConnector: Stopped Spark@3a1aa7a3{HTTP/1.1,[http/1.1]}{0.0.0.0:4040}"
    "...",
    "\nstderr: "
  ]
}
```

## Version compatibility notes:
* Hadoop 3.2.1 and Hive 3.1.2 are incompatible due to Guava version
mismatch (Hadoop: Guava 27.0, Hive: Guava 19.0). Hive fails with
`java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument(ZLjava/lang/String;Ljava/lang/Object;)`
* Spark 2.4.4 can not 
[use Hive higher than 1.2.2 as a SparkSQL engine](https://spark.apache.org/docs/2.4.4/sql-data-sources-hive-tables.html)
because of this bug: [Spark need to support reading data from Hive 2.0.0 metastore](https://issues.apache.org/jira/browse/SPARK-13446)
and associated issue [Dealing with TimeVars removed in Hive 2.x](https://issues.apache.org/jira/browse/SPARK-27349).
Trying to make it happen results in this exception:
`java.lang.NoSuchFieldError: HIVE_STATS_JDBC_TIMEOUT`.
When this is fixed in Spark 3.0, it will be able to use Hive as a
backend for SparkSQL. Alternatively you can try to downgrade Hive :)

## TODO
* Trim the fat `https://github.com/wagoodman/dive`
* Lint `./lint.sh`
* Upgrade spark to 3.0
* When upgraded, enable Spark-Hive integration.