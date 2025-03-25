#!/usr/bin/env bash

# Start k8s cluster
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy' sh -
until kubectl get nodes &>/dev/null; do sleep 3; done
echo "K3s ready"

# Export environment variables
sudo chown $USER:$USER /etc/rancher/k3s/k3s.yaml 
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install helm repositories
helm repo add cilium https://helm.cilium.io/
helm repo add custom-chart-repo https://nelsonjanusson.github.io/portfolio_chart_repo/
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install CDRs for k8s gateway api
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml
kubectl wait --for=condition=Established crds --all --timeout=60s

# Ensure k3s nodes are ready
kubectl wait --for=condition=Ready node --all --timeout=120s
echo "All nodes are Ready."

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
  --set hubble.metrics.enableOpenMetrics=true \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}"\
  --set gatewayAPI.enabled=true \
  --set prometheus.enabled=true \
  --set operator.prometheus.enabled=true \
  --wait

# Install prometheus
helm install prometheus prometheus-community/prometheus \
    --namespace monitoring \
    --create-namespace \
    --set alertmanager.persistence.storageClass="local-path" \
    --set server.persistentVolume.storageClass="local-path" \
    --wait
  
# Install CloudNativePG operator
helm install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system \
  --create-namespace \
  --wait

# Install custom helm charts  
helm install application-deployment custom-chart-repo/application-deployment

# Install cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
