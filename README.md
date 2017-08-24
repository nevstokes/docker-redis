# Redis Docker Image

Tiny [Busybox](https://www.busybox.net)-based, [UPX](https://upx.github.io)-compressed image for Redis v4.01.

This Redis image has no persistence and is intended only to be used for ephemeral data purposes like caching and sessions.

Available from [Docker Hub](https://hub.docker.com/r/nevstokes/redis/) with:

    $ docker pull nevstokes/redis

#### Caveat lector
This is the result of general tinkering and experimentation. Hopefully it will be something at least of interest to someone but it's likely unwise to be using this for anything critically important.
