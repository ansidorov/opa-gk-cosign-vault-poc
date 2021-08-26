#!/bin/bash
set -o errexit

# create registry container unless it already exists
docker_registry_name='kind-registry'
docker_registry_port='5000'

if ! docker network inspect kind 2>/dev/null >/dev/null ; then
    docker network create kind
    sleep 5
fi
running="$(docker inspect -f '{{.State.Running}}' "${docker_registry_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
    docker run \
        -d --restart=always \
        -p "${docker_registry_port}:5000" \
        --name "${docker_registry_name}" \
        registry:2
    sleep 5
    docker network connect --alias registry "kind" "${docker_registry_name}" || true
    REGISTRY_IP="$(docker inspect -f '{{.NetworkSettings.Networks.kind.IPAddress}}' "kind-registry" 2>/dev/null || true)"
    echo "Docker registry runnin on ${REGISTRY_IP}"
elif [ "${running}" == 'true' ]; then
    echo "Registry already running"
    docker ps --filter name="${docker_registry_name}"
    REGISTRY_IP="$(docker inspect -f '{{.NetworkSettings.Networks.kind.IPAddress}}' "kind-registry" 2>/dev/null || true)"
    echo "Docker registry runnin on ${REGISTRY_IP}"
fi