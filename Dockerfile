# syntax =  docker/dockerfile:experimental
ARG ALPINE_VERSION

FROM --platform=${TARGETPLATFORM} alpine:${ALPINE_VERSION}
LABEL maintainer="Jorn Eilander <jorn.eilander@azorion.com>"
LABEL Description="Home Assistant"

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG ALPINE_VERSION
ARG HASS_VERSION=2021.1.5
ARG WHEELS_BASE_URL="https://wheels.hass.io/alpine-${ALPINE_VERSION}"

ARG TIMEZONE=Europe/Amsterdam
ARG UID=8123
ARG GID=8123

ADD "https://raw.githubusercontent.com/home-assistant/core/${HASS_VERSION}/requirements.txt" /tmp/requirements.txt
ADD "https://raw.githubusercontent.com/home-assistant/core/${HASS_VERSION}/requirements_all.txt" /tmp/requirements_all.txt
ADD "https://raw.githubusercontent.com/home-assistant/core/${HASS_VERSION}/homeassistant/package_constraints.txt" /tmp/homeassistant/package_constraints.txt

ADD components.list /tmp/components.list

    # Install required base packages and remove any cache
RUN apk add --no-cache \
        python3 \
        py3-pip \
        git \
        ca-certificates \
        nmap \
        iputils \
        ffmpeg \
        tini \
        libxml2 \
        libxslt \
        tiff \
        libressl && \
    rm -rf /var/tmp/* /var/cache/apk/* && \
    # Create the 'hass' user and ensure it's part of group 'hass'
    addgroup -g ${GID} hass && \
    adduser -D -G hass -s /bin/sh -u ${UID} hass && \
    mkdir /config; chown -R ${UID}:${GID} /config

    # Mount this cache to enable sharing between the buildx jobs (e.g., amd64, arm64)
    # Export make flags to speed up compiling of packages
RUN --mount=type=cache,target=/root/.cache/pip MAKEFLAGS="-j$(nproc)"; export MAKEFLAGS && \
    GNUMAKEFLAGS="-j$(nproc)"; export GNUMAKEFLAGS && \
    # Install some temporary build dependencies
    apk add --no-cache --virtual=build-dependencies \
        python3-dev \
        pcre-tools \
        cython \
        autoconf \
        openzwave-dev \
        eudev-dev \
        cmake \
        build-base \
        linux-headers \
        tzdata \
        libffi-dev \
        libressl-dev \
        libxml2-dev \
        libxslt-dev \
        jpeg-dev \
        ffmpeg-dev \
        glib-dev && \
    cp "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime && echo "${TIMEZONE}" > /etc/timezone && \
    pip install wheel && \
    # Set appropriate variable depending on target architecture to collect wheels from wheels.hass.io
    [ "${TARGETPLATFORM}" = 'linux/amd64' ] && ALPINE_ARCH=amd64; \
    [ "${TARGETPLATFORM}" = 'linux/arm64' ] && ALPINE_ARCH=aarch64; \
    [ "${TARGETPLATFORM}" = 'linux/arm/v7' ] && ALPINE_ARCH=armv7; \
    # Install base requirements for Home Assistant
    pip install --find-links \
        "${WHEELS_BASE_URL}/${ALPINE_ARCH}" \
        --requirement /tmp/requirements.txt && \
    # Create a '|'-seperated list of components from components.list
    for COMPONENT in $(grep -v -e "^$" -e "^#" /tmp/components.list); do \
        COMPONENTS="${COMPONENTS:+${COMPONENTS}|}${COMPONENT}"; \
    done && \
    # Use '|'-seperated list to create the dependency set for requested components and install them
    pcregrep --multiline --only-matching \
        "^# homeassistant\.components\.(${COMPONENTS})\$(.|\n)*?\n\n" /tmp/requirements_all.txt >> /tmp/requirements_components.txt && \
    pip install --find-links \
        "${WHEELS_BASE_URL}/${ALPINE_ARCH}" \
        --requirement /tmp/requirements_components.txt && \
    pip install ujson && \
    pip install homeassistant=="${HASS_VERSION}"  && \
    apk del build-dependencies && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/cache/apk/*

WORKDIR /config
VOLUME /config
USER ${UID}

EXPOSE 8123

ENTRYPOINT ["/sbin/tini", "--"]

CMD [ "hass", "--config=/config", "--debug" ]
