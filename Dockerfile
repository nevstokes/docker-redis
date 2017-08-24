FROM alpine:3.6 AS build

# Config
ARG REDIS_VERSION="4.0.1"
ARG REDIS_DOWNLOAD_URL="http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz"
ARG REDIS_DOWNLOAD_SHA="2049cd6ae9167f258705081a6ef23bb80b7eff9ff3d0d7481e89510f27457591"

RUN set -euxo pipefail \
  \
  # Tooling
  && apk --update add --no-cache \
    gcc \
    linux-headers \
    make \
    musl-dev \
    tar \
  \
  # Fetch
  && wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL" \
  && echo "$REDIS_DOWNLOAD_SHA *redis.tar.gz" | sha256sum -c - \
  && mkdir -p /usr/src/redis \
  && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
  \
  && grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h \
  && sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h \
  && grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h \
  \
  # Build
  && make -C /usr/src/redis \
  && make -C /usr/src/redis install \
  \
  && strip --strip-all /usr/local/bin/redis-*


FROM alpine:3.6 as libs

COPY --from=build /usr/local/bin/redis-server /usr/local/bin/redis-cli /usr/local/bin/

RUN set -euxo pipefail \
    \
    # Requirements (assuming redis-cli needs the same as redis-server)
    && echo '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    && apk --update add upx@community \
    && scanelf --nobanner --needed /usr/local/bin/redis-server | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | xargs apk add \
    && upx -9 /usr/local/bin/redis-cli /usr/local/bin/redis-server \
    && apk del --purge apk-tools upx \
    && tar -czf lib.tar.gz /lib/*.so.*


FROM busybox

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

EXPOSE 6379

ENTRYPOINT ["redis-server", "--save \"\"", "--appendonly no"]
HEALTHCHECK CMD test $(redis-cli ping) -ne 'PONG' || exit 0

COPY --from=libs /usr/local/bin/redis-server /usr/local/bin/redis-cli /usr/local/bin/
COPY --from=libs /lib.tar.gz /

RUN set -euxo pipefail \
    \
    # User
    && addgroup -S redis \
    && adduser -H -s /sbin/nologin -D -S -G redis redis \
    \
    # Tidy up
    && tar -xzf /lib.tar.gz \
    && rm *.tar.gz \
    && find /bin -type f | grep -Ev "/(sh|test)" | xargs rm -rf

USER redis

LABEL maintainer="Nev Stokes <mail@nevstokes.com>" \
      description="Beanstalkd general-purpose work queue" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URL
