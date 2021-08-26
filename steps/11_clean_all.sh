#!/bin/bash

cd api/
docker-compose down
rm docker-compose.yml
cd ..
docker stop vault
docker rm vault
docker stop kind-registry
docker rm kind-registry
kind delete cluster
docker network rm kind
rm -rf terraform_vault/.terraform*
rm -rf terraform_vault/terraform.tfstate*