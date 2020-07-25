NAME := airgap
IMAGE := local/$(NAME):latest
TARGET := x86_64
DEVICES := librem13v4 librem15v4
GIT_REF := $(shell git log -1 --format=%H config)
GIT_AUTHOR := $(shell git log -1 --format=%an config)
GIT_KEY := $(shell git log -1 --format=%GP config)
GIT_EPOCH := $(shell git log -1 --format=%at config)
GIT_DATETIME := \
	$(shell git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M:%S' config)
VERSION := "develop"
RELEASE_DIR := release/$(VERSION)
ifeq ($(strip $(shell git status --porcelain 2>/dev/null)),)
	GIT_STATE=clean
else
	GIT_STATE=dirty
endif
OUT_DIR := build/buildroot/output/images
docker = docker
executables = $(docker)

.DEFAULT_GOAL := all

## Primary Targets

.PHONY: all
all: image fetch build hash

.PHONY: build
build: build-os build-fw

.PHONY: image
image:
	$(docker) build \
		--tag $(IMAGE) \
		--file $(PWD)/config/container/Dockerfile \
		$(IMAGE_OPTIONS) \
		$(PWD)

.PHONY: fetch
fetch:
	mkdir -p build release
	$(contain) fetch

.PHONY: clean
clean:
	$(contain) clean

.PHONY: mrproper
mrproper:
	docker image rm -f $(IMAGE)
	rm -rf build

.PHONY: build-os
build-os:
	$(contain) build-os
	mkdir -p $(RELEASE_DIR)
	cp $(OUT_DIR)/rootfs.iso9660 $(RELEASE_DIR)/airgap_$(TARGET).iso

.PHONY: build-fw
build-fw:
	$(contain) build-fw
	mkdir -p $(RELEASE_DIR)
	for device in $(DEVICES); do \
		cp \
			build/heads/build/$${device}/coreboot.rom \
			$(RELEASE_DIR)/$${device}.rom ; \
	done

## Release Targets

.PHONY: audit
audit:
	mkdir -p build/audit
	$(contain) audit

.PHONY: hash
hash:
	if [ ! -f release/$(VERSION)/hashes.txt ]; then \
		openssl sha256 -r release/$(VERSION)/*.rom \
			> release/$(VERSION)/hashes.txt; \
		openssl sha256 -r release/$(VERSION)/*.iso \
			>> release/$(VERSION)/hashes.txt; \
	fi

.PHONY: verify
verify:
	mkdir -p build/verify/$(VERSION)
	openssl sha256 -r $(RELEASE_DIR)/*.rom \
		> build/stats/$(VERSION)/release_hashes.txt
	openssl sha256 -r $(RELEASE_DIR)/*.iso \
		>> build/stats/$(VERSION)/release_hashes.txt
	diff -q build/stats/$(VERSION)/release_hashes.txt $(RELEASE_DIR)/hashes.txt;

.PHONY: sign
sign: $(RELEASE_DIR)/*.rom $(RELEASE_DIR)/*.iso
	for file in $^; do \
		gpg --armor --detach-sig "$${file}"; \
	done


## Development Targets

.PHONY: shell
shell:
	$(docker) inspect "$(NAME)" \
	&& $(docker) exec --interactive --tty "$(NAME)" shell \
	|| $(contain) shell


.PHONY: menuconfig
menuconfig:
	$(contain) menuconfig

.PHONY: menuconfig
linux-menuconfig:
	$(contain) linux-menuconfig

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
		--env GIT_EPOCH="$(GIT_EPOCH)" \
		$(IMAGE) tail -f /dev/null
	$(docker) exec -it --user=root "$(NAME)" update-packages
	$(docker) cp \
		"$(NAME):/etc/apt/packages.list" \
		"$(PWD)/config/container/packages.list"
	$(docker) cp \
		"$(NAME):/etc/apt/sources.list" \
		"$(PWD)/config/container/sources.list"
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
		--env TARGET="$(TARGET)" \
		--env DEVICES="$(DEVICES)" \
		--env GIT_DATETIME="$(GIT_DATETIME)" \
		--env GIT_EPOCH="$(GIT_EPOCH)" \
		--env GIT_REF="$(GIT_REF)" \
		--env GIT_AUTHOR="$(GIT_AUTHOR)" \
		--env GIT_KEY="$(GIT_KEY)" \
		--env GIT_STATE="$(GIT_STATE)" \
		--security-opt seccomp=unconfined \
		--volume $(PWD)/build:/home/build/build \
		--volume $(PWD)/config:/home/build/config \
		--volume $(PWD)/release:/home/build/release \
		--volume $(PWD)/scripts:/home/build/scripts \
		$(IMAGE)
