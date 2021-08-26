#!/bin/bash

REGISTRY_IP="$(docker inspect -f '{{.NetworkSettings.Networks.kind.IPAddress}}' "kind-registry" 2>/dev/null || true)"

kubectl create ns test-opa
kubectl --context kind-kind apply -f manifests/deployment.yaml

cat manifests/signed_deployment.yaml | sed 's/%DOCKER_REGISTRY%/'"${REGISTRY_IP}"'/' | kubectl --context kind-kind apply -f -