ARG DEBIAN_IMAGE_HASH=4ab3309ba955211d1db92f405be609942b595a720de789286376f030502ffd6f
ARG GOLANG_IMAGE_HASH=84349ee862d8bafff35e0d2bfd539da565b536b4dfce654773fc21a1db2da6d7

FROM golang@sha256:${GOLANG_IMAGE_HASH} as gotools

ARG FIXUID_GIT_REF="0ec93d22e52bde5b7326e84cb62fd26a3d20cead"
ARG OZZOCONFIG_GIT_REF="0ff174cf5aa6480026e0b40c14fd9cfb61c4abf6"
ARG JSONPREPROCESS_GIT_REF="a4e954386171be645f1eb7c41865d2624b69259d"
ARG TOML_GIT_REF="3012a1dbe2e4bd1391d42b32f0577cb7bbc7f005"
ARG YAMLV2_GIT_REF="51d6538a90f86fe93ac480b35f37b2be17fef232"
ARG GLIDE_GIT_REF="b94b39d657d8abcccba6545e148f1201aee6ffec"

RUN apk add bash git make

RUN printf "\
github.com/boxboat/fixuid.git github.com/boxboat/fixuid ${FIXUID_GIT_REF} \n\
github.com/go-ozzo/ozzo-config github.com/go-ozzo/ozzo-config ${OZZOCONFIG_GIT_REF} \n\
github.com/hnakamur/jsonpreprocess github.com/hnakamur/jsonpreprocess ${JSONPREPROCESS_GIT_REF} \n\
github.com/BurntSushi/toml github.com/BurntSushi/toml ${TOML_GIT_REF} \n\
github.com/go-yaml/yaml gopkg.in/yaml.v2 ${YAMLV2_GIT_REF} \n" \
> /go/src/repos

RUN echo ' \
    set -o nounset -o pipefail -o errexit; \
    cat /go/src/repos | while read -r line; do \
        repo=$(echo $line | awk "{ print \$1 }"); \
        folder=$(echo $line | awk "{ print \$2 }"); \
        ref=$(echo $line | awk "{ print \$3 }"); \
        git clone "https://${repo}" "/go/src/${folder}"; \
        git -C "/go/src/${folder}" checkout ${ref};  \
    done' \
| bash

RUN go build -o /usr/local/bin/fixuid github.com/boxboat/fixuid


FROM debian@sha256:${DEBIAN_IMAGE_HASH} as debian

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    TERM=xterm-256color \
    HOME=/home/build \
    PATH=/home/build/scripts:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

## Setup fixuid for mounting host-dirs with correct permissions during dev
COPY --from=gotools /usr/local/bin/ /usr/local/bin/
RUN chown root:root /usr/local/bin/fixuid \
    && chmod 4755 /usr/local/bin/fixuid \
    && mkdir -p /etc/fixuid \
    && printf "user: build\ngroup: build\npaths:\n  - /\n  - /home/build/build\n" > /etc/fixuid/config.yml
ENTRYPOINT ["/usr/local/bin/fixuid", "-q"]

## Install packages from packages.list with retry
ADD config/container/sources.list /etc/apt/sources.list
ADD config/container/packages.list /etc/apt/packages.list
run echo 'Acquire::http::Timeout "30";' >> /etc/apt/apt.conf.d/99apt.conf
RUN echo ' \
    set -e; \
    apt-get update; \
    until apt-get install -y $(cat /etc/apt/packages.list); do \
        echo "apt install failed. Likely throttled. Retrying in 10 mins..."; \
        sleep 600; \
    done; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;' \
| bash

## Create build user with sudo privs
RUN useradd -G plugdev,sudo -ms /bin/bash build \
    && chown -R build:build /home/build \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/build

USER build
