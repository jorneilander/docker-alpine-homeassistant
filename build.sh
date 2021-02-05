#!/bin/bash
# set -x

HASS_VERSION=2021.2.0
ALPINE_VERSION=3.12
IMAGE_NAME=failfr8er/home-assistant

docker buildx build \
  --file Dockerfile \
  --cache-from=type=local,src=/tmp/.buildx \
  --cache-to=type=local,dest=/tmp/.buildx \
  --tag ${IMAGE_NAME}:${HASS_VERSION} \
  --tag ${IMAGE_NAME}:latest \
  --push \
  --build-arg ALPINE_VERSION=${ALPINE_VERSION} \
  --build-arg HASS_VERSION=${HASS_VERSION} \
  --platform=linux/amd64,linux/arm64,linux/arm/v7 \
  --progress plain \
  .

# ,linux/arm64,linux/arm/v7