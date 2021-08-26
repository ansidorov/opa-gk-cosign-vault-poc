#!/bin/bash

API_IP="$(docker inspect -f '{{.NetworkSettings.Networks.kind.IPAddress}}' "api_api_1" 2>/dev/null || true)"
cat manifests/template.yaml | sed 's/%API_IP%/'"${API_IP}"'/' | kubectl --context kind-kind apply -f -
sleep 3
kubectl --context kind-kind apply -f manifests/constraints.yaml
