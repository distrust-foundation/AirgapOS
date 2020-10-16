ARG DEBIAN_IMAGE_HASH=4ab3309ba955211d1db92f405be609942b595a720de789286376f030502ffd6f
FROM debian@sha256:${DEBIAN_IMAGE_HASH} as debian

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    TERM=xterm-256color \
    HOME=/home/build \
    PATH=/home/build/scripts:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ADD scripts/ /usr/local/bin/

## Download, verify, and install packages against stored lists/hashes via https
ADD config/container/sources.list /etc/apt/sources.list.new
ADD config/container/packages.list /etc/apt/packages.list.new
ADD config/container/package-hashes.txt /etc/apt/package-hashes.txt
ADD config/container/apt.conf /etc/apt/apt.conf
RUN apt-install

WORKDIR /home/build

ENTRYPOINT ["/usr/local/bin/host-env"]
