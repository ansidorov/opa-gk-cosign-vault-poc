#!/bin/bash

export VAULT_ADDR="http://localhost:8200"
cd terraform_vault/
export VAULT_TOKEN=$(terraform output cosign-token | tr -d '"')
cd -
#export TRANSIT_SECRET_ENGINE_PATH="cosign-space"

echo "Generate root key pair for cosign"
cosign generate-key-pair -kms hashivault://testkey
echo "Signing hello-app with cosign"
cosign sign -key hashivault://testkey localhost:5000/hello-app:1.0
echo "Verify hello-app image with cosign"
cosign verify -key hashivault://testkey localhost:5000/hello-app:1.0

cosign verify -key hashivault://testkey localhost:5000/ubuntu:20.04
