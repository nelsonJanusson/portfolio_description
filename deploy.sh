#!/usr/bin/env bash

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install helm repositories
helm repo add cilium https://helm.cilium.io/
helm repo add custom-chart-repo https://nelsonjanusson.github.io/portfolio_chart_repo/
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

# Start k8s cluster
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy' sh -

# Export environment variables
sudo chown $USER:$USER /etc/rancher/k3s/k3s.yaml 
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Install CDRs for k8s gateway api
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml

# Install cilium
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

# Install cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Install CloudNativePG operator
helm install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system \
  --create-namespace

# Verify that required CloudNativePG services are running
echo "⏳ Waiting for CloudNativePG webhook service to be created..."
until kubectl get svc cnpg-webhook-service -n cnpg-system >/dev/null 2>&1; do
  echo "⏳ Waiting for cnpg-webhook-service to appear..."
  sleep 5
done
echo "⏳ Waiting for CloudNativePG webhook service to have endpoints..."
until [[ $(kubectl get endpoints cnpg-webhook-service -n cnpg-system -o jsonpath='{.subsets}') ]]; do
  echo "⏳ Waiting for cnpg-webhook-service to have endpoints..."
  sleep 5
done

# Install custom helm charts  
helm install application-deployment custom-chart-repo/application-deployment

