#!/bin/bash
set -o errexit

docker_registry_name='kind-registry'
docker_registry_port='5000'
REGISTRY_IP="$(docker inspect -f '{{.NetworkSettings.Networks.kind.IPAddress}}' "kind-registry" 2>/dev/null || true)"
# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."${REGISTRY_IP}:${docker_registry_port}"]
    endpoint = ["http://${docker_registry_name}:${docker_registry_port}"]
EOF

# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "${REGISTRY_IP}:${docker_registry_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

sleep 35
kubectl --context kind-kind get nodes
