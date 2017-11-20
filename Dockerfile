FROM alpine:3.6 AS build

COPY github-releases.xsl /

RUN echo '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    && apk --update add \
        gcc \
        libressl \
        libxslt-dev \
        linux-headers \
        make \
        musl-dev \
        upx@community

RUN mkdir -p /usr/src/redis \
    \
    && export REDIS_VERSION=`wget -q https://github.com/antirez/redis/releases.atom -O - | xsltproc /github-releases.xsl - | awk -F/ '{ print $NF; }'` \
    && export REDIS_HASH=`wget -q https://raw.githubusercontent.com/antirez/redis-hashes/master/README -O - | grep redis-$REDIS_VERSION.tar.gz | awk '{ print $4 }'` \
    && wget -qO redis.tar.gz http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz \
    && echo "$REDIS_HASH *redis.tar.gz" | sha256sum -c - \
    && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1

RUN grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h \
    && sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h \
    && grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h

RUN cd /usr/src/redis \
    && make CFLAGS=-Os \
    && make install \
    \
    && strip --strip-all /usr/local/bin/redis-* \
    && upx -9 /usr/local/bin/redis-cli /usr/local/bin/redis-server


FROM scratch

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

EXPOSE 6379

COPY --from=build /usr/local/bin/redis-cli /usr/local/bin/redis-server /usr/local/bin/
COPY --from=build /lib/ld-musl-x86_64.so.1 /lib/

ENTRYPOINT ["redis-server"]

LABEL maintainer="Nev Stokes <mail@nevstokes.com>" \
      description="Simple non-persisting Redis image" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URL
