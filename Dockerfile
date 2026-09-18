# syntax=docker/dockerfile:1
#
# Flarum 2.0 Docker image
# ------------------------
# Fork/adaptation of crazy-max/docker-flarum (MIT) for Flarum 2.0.
# Installs Flarum from the official "complete package" archive
# (flarum/installation-packages) instead of running composer at build time,
# so the exact pinned release (v2.0.0-rc.8) is reproduced deterministically.
#
# https://github.com/YHXJLB/docker-flarum-new

ARG FLARUM_VERSION=v2.0.0-rc.8
ARG FLARUM_PHP=8.4
ARG ALPINE_VERSION=3.23

FROM tianon/gosu:latest AS gosu

FROM crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3
COPY --from=gosu /gosu /usr/local/bin/

RUN apk --update --no-cache add \
    bash \
    curl \
    jq \
    libgd \
    mysql-client \
    mariadb-connector-c \
    nginx \
    php84 \
    php84-cli \
    php84-bcmath \
    php84-ctype \
    php84-curl \
    php84-dom \
    php84-exif \
    php84-fileinfo \
    php84-fpm \
    php84-gd \
    php84-gmp \
    php84-iconv \
    php84-intl \
    php84-json \
    php84-mbstring \
    php84-opcache \
    php84-openssl \
    php84-pdo \
    php84-pdo_mysql \
    php84-pecl-uuid \
    php84-phar \
    php84-session \
    php84-simplexml \
    php84-sodium \
    php84-tokenizer \
    php84-xml \
    php84-xmlwriter \
    php84-zip \
    php84-zlib \
    shadow \
    tar \
    tzdata \
    unzip \
  && rm -rf /tmp/* /var/www/*

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

ARG FLARUM_VERSION
ARG FLARUM_PHP
RUN mkdir -p /opt/flarum \
  && curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && curl -sSL -o /tmp/flarum.zip "https://raw.githubusercontent.com/flarum/installation-packages/main/packages/v2.x/${FLARUM_VERSION#v}/flarum-${FLARUM_VERSION}-php${FLARUM_PHP}.zip" \
  && TMP="$(mktemp -d)" \
  && unzip -q /tmp/flarum.zip -d "$TMP/ext" \
  && SRC="$TMP/ext" \
  && if [ "$(find "$SRC" -maxdepth 1 -mindepth 1 | wc -l)" = "1" ] && [ -d "$(find "$SRC" -maxdepth 1 -mindepth 1)" ]; then \
       SRC="$(find "$SRC" -maxdepth 1 -mindepth 1)"; \
     fi \
  && cp -a "$SRC"/. /opt/flarum/ \
  && rm -rf "$TMP" /tmp/flarum.zip \
  && chmod +x /opt/flarum/flarum \
  && addgroup -g ${PGID} flarum \
  && adduser -D -h /opt/flarum -u ${PUID} -G flarum -s /bin/sh flarum \
  && chown -R flarum:flarum /opt/flarum \
  && rm -rf /root/.composer /tmp/*

COPY rootfs /

EXPOSE 8000
WORKDIR /opt/flarum
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
