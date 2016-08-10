## Minipipe
Minipipe - a minimal end-to-end pipeline.

### Development
1. Install [minikube](https://github.com/kubernetes/minikube). Note that you need a beefy machine and the use of vmware is *highly* recommended.
2. Fire up a Kubernetes cluster with e.g. `minikube start --cpus=4 --memory=8192 --vm-driver=vmwarefusion`.
3. Deploy minipipe with `./minipipe.sh --start`.
4. Track the progress from the Kubernetes dashboard with `minikube dashboard`.
5. Send some data about an user through the HTTP REST API. The JSON representation of the data would be `{"name": "alice"}`:
```
curl -X POST -H "Content-Type: application/vnd.kafka.avro.v1+json" \
      --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", 
               "records": [{"value": {"name": "alice"}}]}' \
      "http://$(minikube ip):32767/topics/connect_test"
```
