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


FROM alpine:3.6

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

EXPOSE 6379

ENTRYPOINT ["redis-server"]
HEALTHCHECK CMD test $(redis-cli ping) -ne 'PONG' || exit 0

COPY --from=build /usr/local/bin/redis-server /usr/local/bin/redis-cli /usr/local/bin/

RUN set -euxo pipefail \
    \
    # User
    && addgroup -S redis \
    && adduser -H -s /sbin/nologin -D -S -G redis redis \
    \
    # Requirements
    && apk update \
    && scanelf --nobanner --needed `which redis-server` | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | xargs apk add --no-cache \
    \
    # Tidy up
    && rm -rf /var/cache /usr/sbin \
    && find /usr/bin -type l | grep -Ev "/(find|test|xargs)" | xargs rm -f \
    && find /bin -type l | grep -v /sh | xargs rm -f

USER redis

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URL
