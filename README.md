# Redis Docker Image

[![](https://images.microbadger.com/badges/image/nevstokes/redis.svg)](https://microbadger.com/images/nevstokes/redis "Get your own image badge on microbadger.com") [![](https://images.microbadger.com/badges/commit/nevstokes/redis.svg)](https://microbadger.com/images/nevstokes/redis "Get your own commit badge on microbadger.com")

Tiny [Busybox](https://www.busybox.net)-based, [UPX](https://upx.github.io)-compressed image for Redis v4.01.

This Redis image has no persistence and is intended only to be used for ephemeral data purposes like caching and sessions.

Available from [Docker Hub](https://hub.docker.com/r/nevstokes/redis/) with:

    $ docker pull nevstokes/redis

#### Caveat lector
This is the result of general tinkering and experimentation. Hopefully it will be something at least of interest to someone but it's likely unwise to be using this for anything critically important.
