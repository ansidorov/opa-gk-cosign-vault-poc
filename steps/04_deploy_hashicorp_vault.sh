#!/bin/bash

# create HashiCorp Vault container unless it already exists
docker_vault_name='vault'

running="$(docker inspect -f '{{.State.Running}}' "${docker_vault_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
    docker run \
        -d --restart=always \
        --cap-add=IPC_LOCK \
        -p "8200:8200" \
        --name "${docker_vault_name}" \
        -e 'VAULT_DEV_LISTE_ADDRESS=0.0.0.0:8200' \
        -e 'VAULT_DEV_ROOT_TOKEN_ID=TEST' \
        vault:1.8.1
    docker network connect --alias vault "kind" "vault" || true
elif [ "${running}" == 'true' ]; then
    echo "Vault already running"
    docker ps --filter name="${docker_vault_name}"
fi