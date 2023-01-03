ARG DEBIAN_HASH
FROM debian@sha256:${DEBIAN_HASH}

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    PATH=/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ARG CONFIG_DIR
ADD ${CONFIG_DIR} /config

ARG SCRIPTS_DIR
ADD ${SCRIPTS_DIR} /usr/local/bin

RUN packages-install

RUN echo "/usr/lib/x86_64-linux-gnu/faketime/libfaketime.so.1" \
    > /etc/ld.so.preload
