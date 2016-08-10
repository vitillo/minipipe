## Minipipe
Minipipe - a minimal end-to-end pipeline.

### Development
1. Install [minikube](https://github.com/kubernetes/minikube). Note that you need a beefy machine and the use of vmware is *highly* recommended.
2. Fire up a Kubernetes cluster with e.g. `minikube start --cpus=4 --memory=8192 --vm-driver=vmwarefusion`.
3. Deploy minipipe with `./minipipe.sh --start`.
4. Track the progress from the Kubernetes dashboard with `minikube dashboard`.
