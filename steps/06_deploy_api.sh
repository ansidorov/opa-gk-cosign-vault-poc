#!/bin/bash

cd terraform_vault/
VAULT_TOKEN=$(terraform output cosign-token | tr -d '"')
cd -
cd api
cat docker-compose | sed 's/%VAULT_TOKEN%/'"$VAULT_TOKEN"'/' > docker-compose.yml
docker-compose up -d
cd -

docker network connect --alias api "kind" "api_api_1" || true
