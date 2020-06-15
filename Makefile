NAME := unilinux
IMAGE := polychain/$(NAME):latest
TARGET := qemu
docker = docker
executables = $(docker)

.DEFAULT_GOAL := all

## Primary Targets

.PHONY: all
all: fetch build

.PHONY: image
image:
	$(docker) build \
		--tag $(IMAGE) \
		--file $(PWD)/config/container/Dockerfile \
		$(IMAGE_OPTIONS) \
		$(PWD)

.PHONY: build
build:
	$(contain) build
	cp -R build/buildroot/output/images/* release/*

.PHONY: fetch
fetch:
	mkdir -p build release
	$(contain) fetch

.PHONY: clean
clean:
	$(contain) clean

## Development Targets

.PHONY: shell
shell:
	$(docker) inspect "$(NAME)" \
	&& $(docker) exec --interactive --tty "$(NAME)" shell \
	|| $(contain) shell


.PHONY: menuconfig
menuconfig:
	$(contain) menuconfig

.PHONY: vm
vm:
	$(contain) vm

.PHONY: update-packages
update-packages:
	$(docker) run \
		--rm \
		--detach \
		--name "$(NAME)" \
		--user $(userid):$(groupid) \
		--volume $(PWD)/config:/home/build/config \
		--volume $(PWD)/scripts:/home/build/scripts \
		$(IMAGE) tail -f /dev/null
	$(docker) exec -it --user=root "$(NAME)" update-packages
	$(docker) cp \
		"$(NAME):/etc/apt/packages.list" \
		"$(PWD)/config/container/packages.list"
	$(docker) rm -f "$(NAME)"

## Make Helpers

check_executables := $(foreach exec,$(executables),\$(if \
	$(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

userid = $(shell id -u)
groupid = $(shell id -g)
contain := \
	$(docker) run \
		--rm \
		--tty \
		--interactive \
		--name "$(NAME)" \
		--hostname "$(NAME)" \
		--user $(userid):$(groupid) \
		--env TARGET=$(TARGET) \
		--security-opt seccomp=unconfined \
		--volume $(PWD)/build:/home/build/build \
		--volume $(PWD)/config:/home/build/config \
		--volume $(PWD)/release:/home/build/release \
		--volume $(PWD)/scripts:/home/build/scripts \
		$(IMAGE)
