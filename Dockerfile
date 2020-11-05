FROM python:3.8-alpine
LABEL maintainer="Philipp Hellmich <phil@hellmi.de>"
LABEL Description="Home Assistant"

ARG TIMEZONE=Europe/Paris
ARG UID=1000
ARG GUID=1000
ARG VERSION=0.117.5

ADD "https://raw.githubusercontent.com/home-assistant/core/${VERSION}/requirements.txt" /tmp/requirements.txt
ADD "https://raw.githubusercontent.com/home-assistant/core/${VERSION}/requirements_all.txt" /tmp/requirements_all.txt
ADD "https://raw.githubusercontent.com/home-assistant/core/${VERSION}/homeassistant/package_constraints.txt" /tmp/homeassistant/package_constraints.txt

RUN apk add --no-cache git ca-certificates nmap iputils ffmpeg mariadb-client mariadb-connector-c tini libxml2 libxslt && \
    rm -rf /var/tmp/* /var/cache/apk/* && \
    chmod u+s /bin/ping && \
    addgroup -g ${GUID} hass && \
    adduser -D -G hass -s /bin/sh -u ${UID} hass

RUN export MAKEFLAGS="-j$(nproc)" && \
    export GNUMAKEFLAGS="-j$(nproc)" && \
    apk add --no-cache --virtual=build-dependencies cython autoconf openzwave-dev eudev-dev cmake build-base linux-headers tzdata libffi-dev libressl-dev libxml2-dev libxslt-dev mariadb-connector-c-dev jpeg-dev ffmpeg-dev glib-dev && \
    cp "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime && echo "${TIMEZONE}" > /etc/timezone && \
    pip install wheel && \
    pip install -r /tmp/requirements_all.txt && \
    pip install ujson && \
    pip install mysqlclient && \
    pip install homeassistant=="${VERSION}" && \
    apk del build-dependencies && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

EXPOSE 8123

VOLUME /config

ENTRYPOINT ["/sbin/tini", "--"]

CMD [ "hass", "--open-ui", "--config=/config" ]
