## Minipipe
Minipipe - a minimal end-to-end pipeline.

### Local Deployment
1. Install [minikube](https://github.com/kubernetes/minikube). Note that you need a beefy machine and the use of vmware is **highly** recommended.
2. Fire up a Kubernetes cluster with e.g. `minikube start --cpus=4 --memory=8192 --vm-driver=vmwarefusion`.
3. Deploy minipipe with `./minipipe.sh --create`.
4. Track the deployment progress from the Kubernetes dashboard with `minikube dashboard`.
5. Note that it might take a while until the cluster is usable, even after all the pods are up and running.


### Example Use Case
1. Send some data through the REST API. The JSON representation of the data is `{"name": "alice"}`:
```
curl -X POST -H "Content-Type: application/vnd.kafka.avro.v1+json" \
      --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", 
               "records": [{"value": {"name": "alice"}}]}' \
      "http://$(minikube ip):32767/topics/connect_test"
```
2. Query the data with Presto from redash: `open http://$(minikube ip):32766`.
3. Schema evolution is supported as well! For example, we can add a new (nullable) field `lastname`:
```
curl -X POST -H "Content-Type: application/vnd.kafka.avro.v1+json" \
      --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}, {\"name\": \"lastname\", \"type\": [\"null\", \"string\"], \"default\": null}]}", 
               "records": [{"value": {"name": "bob", "lastname": {"string": "smith"}}}]}' \
      "http://$(minikube ip):32767/topics/connect_test"
```
