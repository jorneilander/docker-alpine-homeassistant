# Home Assistant Docker Image

## Description

Small docker image with [Home Assistant](https://home-assistant.io/) based on [Alpine Linux](https://hub.docker.com/_/alpine/).

This image should be available ~~(unless a problem happened on my side) for the following architectures~~:

* `amd64`
* `armhf`
* `arm64`

I'm using a proper manifest so you can use the main tags directly (no need for amd64-X.X.X).

## Usage

```
docker run --rm --detach --name homeassistant --publish 80:8123 failfr8er/home-assistant:latest
```

### Configuration

It's recommended to map a directory into the container to configure Home Assistant.

```
-v /etc/homeassistant:/config \
```

By default this container run as `hass` with uid 8123 and gid 0.
This allows it to be run inside a cluster (e.g., `OpenShift`, `K8S`) with appropriate privilege limitations.

### Plugins

Please check the [components.list](components.list) for the list of components installed.
~~Any other will be downloaded automatically by Home Assistant.~~

## License

This project is licensed under `GPLv2`.
