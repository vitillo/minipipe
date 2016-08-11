## Minipipe
Minipipe: a minimal data pipeline. 

The goal of this project is to demonstrate how to build a simple pipeline that accepts data over HTTP, stores it under HDFS (or potentially S3), and makes it queryable from analytic tool like Spark or Presto. As it's often the case with software, once the right storage mechanism has been chosen the problem becomes considerably easier to solve. [Parquet](https://parquet.apache.org/) is a columnar storage system optimized for analytic workloads and arguably the lingua franca of the Hadoop ecosystem, which is the reason minipipe is based around it. Even though minipipe is meant to be a simple demo, all the main pieces are there to build a pipeline that can be used in production.

### Local Deployment
1. Install [minikube](https://github.com/kubernetes/minikube). Note that you will need a **beefy** machine and the use of vmware is **highly** recommended.

2. Install `kubectl` if you don't have it already. You can grab a copy of the binary for [Linux](https://storage.googleapis.com/kubernetes-release/release/v1.2.4/bin/linux/amd64/kubectl) or [OS X](https://storage.googleapis.com/kubernetes-release/release/v1.2.4/bin/darwin/amd64/kubectl) and put it somewhere in your `PATH`. On OS X you can also install the binary using brew (`brew install kubectl`).

3. Fire up a Kubernetes cluster:
   ```bash
   minikube start --cpus=4 --memory=8192 --vm-driver=vmwarefusion
   ```

4. Deploy minipipe:
   ```bash
   ./minipipe.sh --create
   ```

5. Track the deployment progress from the Kubernetes dashboard:
   ```bash
   minikube dashboard
   ```

6. Grab a coffee or something; it might take a while until the cluster is up and running since the first time round many Docker images have to be downloaded.

### Example Use Case
1. Send some data through the REST API. The JSON representation of the data is `{"name": "alice"}`:
   ```bash
   curl -X POST -H "Content-Type: application/vnd.kafka.avro.v1+json" \
         --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", 
                  "records": [{"value": {"name": "alice"}}]}' \
         "http://$(minikube ip):32767/topics/connect_test"
   ```

2. Query the data with [Presto](http://prestodb.io/) from [redash](http://redash.io/):
   ```bash
   open http://$(minikube ip):32766
   ```
   The username and password for the redash instance are respectively *admin* & *admin*.

3. Schema evolution is supported as well! For example, we can add a new (nullable) field `lastname` and send a record that reflects the updated schema:
   ```bash
   curl -X POST -H "Content-Type: application/vnd.kafka.avro.v1+json" \
         --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}, {\"name\": \"lastname\", \"type\": [\"null\", \"string\"], \"default\": null}]}", 
                  "records": [{"value": {"name": "bob", "lastname": {"string": "smith"}}}]}' \
         "http://$(minikube ip):32767/topics/connect_test"
   ```

#### What happens under the hood
0. The [Kubernetes](http://kubernetes.io/) cluster is populated with containers for:
   - ZooKeeper
   - HDFS Namenode
   - HDFS Datanodes
   - Kafka
   - Kafka Schema Registry
   - Kafka Rest Proxy
   - Kafka Connect
   - PostgreSQL
   - Hive Metastore
   - Presto DB
   - Redash

  While Docker provides the lifecycle management of containers, Kubernetes takes it to the next level by providing orchestration and managing clusters of containers, which simplifies development and end-to-end testing of a data pipeline. Note that even though this demo runs on a local machine, it's fairly easy to run it on [AWS](http://kubernetes.io/docs/getting-started-guides/aws/) or on Google Cloud.

1. A payload is sent to the [Kafka REST Proxy](http://docs.confluent.io/2.0.0/kafka-rest/docs/index.html) with an HTTP request, specifying the Kafka topic the message belongs to, i.e connect_test. The content type is set to [Avro](https://avro.apache.org/) with [JSON encoding](https://avro.apache.org/docs/1.7.7/spec.html#json_encoding) (`Content-Type: application/vnd.kafka.avro.v1+json`). The main benefit of using Avro is that it supports schemas. The payload contains the schema and a set of records that adhere to it.

2. The proxy talks to the [Schema Registry](http://docs.confluent.io/1.0/schema-registry/docs/intro.html) to verify that the payload respects the schema for the topic, if there is one, otherwise it registers a new schema. In case the schema evolved, e.g. a new field was added, the Schema Registry checks that it is backward compatible. Then, the proxy forwards the message to Kafka.

3. The [HDFS Connector](http://docs.confluent.io/2.0.0/connect/connect-hdfs/docs/index.html) reads data from that topic and dumps it on HDFS regularly in Parquet files according to some configurable parameters (e.g. every N records) and partitions (e.g. date). It also creates or updates the schema definition of the corresponding table in the Hive metastore. Note that an equivalent [Connector](https://github.com/qubole/streamx) exists for S3 as well.

4. [Presto](https://prestodb.io/), or any other tool that can read table definitions from the [Hive metastore](https://hive.apache.org/), can then read the Parquet files from HDFS.
