# Portfolio Description
explanation of the architecture of my portfolio website and instructions for how to set it upp locally

## Backend Architecture
The backend is running on a k3s kubernetes cluster and uses cilium for observabillity and networking. The cluster also uses helm for managing deployments and pulls charts from a custom [helm chart repository](https://github.com/nelsonJanusson/portfolio_chart_repo). 
The backend microservices are written using the springboot framework and kotlin language. The complete list of microservices are as follows:  
- [Project Service](https://github.com/nelsonJanusson/portfolio_project_service).

All the custom images required to run the application can be found at in this [dockerhub container registry](https://hub.docker.com/repository/docker/nelsonjanusson/portfolio_project/general).

## Frontend Architecture



### Setup script explanation
Follow these steps in order to set up the k8s cluster

##### 1. Install helm
```console
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```
##### 2. Install helm repositories
```console
helm repo add cilium https://helm.cilium.io/
helm repo add custom-charts https://nelsonjanusson.github.io/portfolio_chart_repo/
helm repo update
```
##### 3. Start k8s cluster
```console
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy' sh -
```
##### 4. Export environment variables
```console
sudo chown $USER:$USER /etc/rancher/k3s/k3s.yaml  
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```
##### 5. Install CDRs for k8s gateway api
```console
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml
```
##### 6. Install cilium
```console
helm install cilium cilium/cilium \
  --version 1.17.2 \
  --namespace kube-system \
  --set operator.replicas=1 \
  --set kubeProxyReplacement=true \
  --set serviceMesh.enabled=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set gatewayAPI.enabled=true
```
##### 7. Install custom helm charts
```console
helm install project-service custom-charts/project-service
```
##### 8. Install cilium CLI
```console
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```
### Full setup script
```console
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm repo add cilium https://helm.cilium.io/
helm repo add custom-charts https://nelsonjanusson.github.io/portfolio_chart_repo/
helm repo update
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy' sh -
sudo chown $USER:$USER /etc/rancher/k3s/k3s.yaml 
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml
helm install cilium cilium/cilium \
  --version 1.17.2 \
  --namespace kube-system \
  --set operator.replicas=1 \
  --set kubeProxyReplacement=true \
  --set serviceMesh.enabled=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set gatewayAPI.enabled=true
helm install project-service custom-charts/project-service
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```
