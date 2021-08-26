#!/bin/bash

docker pull ubuntu:20.04
docker tag ubuntu:20.04 localhost:5000/ubuntu:20.04
docker push localhost:5000/ubuntu:20.04

docker pull nginx:1.14.2
docker tag nginx:1.14.2 localhost:5000/nginx:1.14.2
docker push localhost:5000/nginx:1.14.2

docker pull gcr.io/google-samples/hello-app:1.0
docker tag gcr.io/google-samples/hello-app:1.0 localhost:5000/hello-app:1.0
docker push localhost:5000/hello-app:1.0
