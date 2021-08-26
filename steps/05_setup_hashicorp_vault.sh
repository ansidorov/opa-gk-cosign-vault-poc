#!/bin/bash

docker_vault_name='vault'

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN="$(docker logs ${docker_vault_name} 2>&1 | grep '^Root Token' | awk '{print $NF}')"
cd terraform_vault/
terraform init
terraform plan
terraform apply
cd ../
