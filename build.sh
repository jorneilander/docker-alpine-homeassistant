#!/bin/bash
# set -x

ALPINE_VERSION=3.12
IMAGE_NAME=failfr8er/home-assistant
HASS_RAW=$(curl -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/home-assistant/core/releases/latest)
HASS_VERSION=$(echo "${HASS_RAW}" | jq -r '.tag_name')
echo "::set-output name=HASS_VERSION::${HASS_VERSION}"

docker buildx build \
  --file Dockerfile \
  --cache-from=type=local,src=/tmp/.buildx-cache \
  --cache-to=type=local,dest=/tmp/.buildx-cache \
  --tag ${IMAGE_NAME}:${HASS_VERSION} \
  --tag ${IMAGE_NAME}:latest \
  --"${1:-load}" \
  --build-arg ALPINE_VERSION=${ALPINE_VERSION} \
  --build-arg HASS_VERSION=${HASS_VERSION} \
  --platform=linux/amd64,linux/arm64 \
  --progress plain \
  .
