#!/bin/bash

kubectl --context kind-kind apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.5/deploy/gatekeeper.yaml
sleep 20
kubectl --context kind-kind -n gatekeeper-system get pod
