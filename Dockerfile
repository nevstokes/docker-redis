FROM alpine:3.6 AS build

ARG REDIS_VERSION="4.0.2"
ARG REDIS_DOWNLOAD_URL="http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz"
ARG REDIS_DOWNLOAD_SHA="b1a0915dbc91b979d06df1977fe594c3fa9b189f1f3d38743a2948c9f7634813"

RUN set -euxo pipefail \
  \
  && apk --update add --no-cache \
    gcc \
    linux-headers \
    make \
    musl-dev \
    tar \
  \
  && wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL" \
  && echo "$REDIS_DOWNLOAD_SHA *redis.tar.gz" | sha256sum -c - \
  && mkdir -p /usr/src/redis \
  && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
  \
  && grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h \
  && sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h \
  && grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h \
  \
  && make -C /usr/src/redis \
  && make -C /usr/src/redis install \
  \
  && strip --strip-all /usr/local/bin/redis-*


FROM alpine:3.6 as libs

COPY --from=build /usr/local/bin/redis-server /usr/local/bin/redis-cli /usr/local/bin/

RUN set -euxo pipefail \
    \
    && echo '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    && apk --update add upx@community \
    \
    && scanelf --nobanner --needed /usr/local/bin/redis-server | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | xargs apk add \
    \
    && upx -9 /usr/local/bin/redis-cli /usr/local/bin/redis-server \
    && apk del --purge apk-tools upx


FROM busybox

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

EXPOSE 6379

ENTRYPOINT ["redis-server", "--save \"\"", "--appendonly no"]
HEALTHCHECK CMD test $(redis-cli ping) -ne 'PONG' || exit 0

COPY --from=libs /usr/local/bin/redis-server /usr/local/bin/redis-cli /usr/local/bin/
COPY --from=libs /lib/ld-musl-x86_64.so.1 /lib/

RUN set -euxo pipefail \
    \
    && addgroup -S redis \
    && adduser -H -s /sbin/nologin -D -S -G redis redis \
    \
    && ln -s /lib/ld-musl-x86_64.so.1 /lib/libc.musl-x86_64.so.1

USER redis

LABEL maintainer="Nev Stokes <mail@nevstokes.com>" \
      description="Simple non-persisting Redis image" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URL
