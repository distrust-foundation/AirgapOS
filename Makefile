NAME := airgap
IMAGE := local/$(NAME):latest
ARCH := x86_64
TARGET := $(ARCH)
DEVICES := librem_13v4 librem_15v4
USER := $(shell id -u):$(shell id -g)
CPUS := $(shell docker run -it debian nproc)
GIT_REF := $(shell git log -1 --format=%H config)
GIT_AUTHOR := $(shell git log -1 --format=%an config)
GIT_KEY := $(shell git log -1 --format=%GP config)
GIT_EPOCH := $(shell git log -1 --format=%at config)
GIT_DATETIME := \
	$(shell git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M:%S' config)
ifeq ($(strip $(shell git status --porcelain 2>/dev/null)),)
	GIT_STATE=clean
else
	GIT_STATE=dirty
endif
VERSION := $(shell TZ=UTC0 git show --quiet --date='format-local:%Y%m%dT%H%M%SZ' --format="%cd")
RELEASE_DIR := release/$(VERSION)
CONFIG_DIR := config
BR2_EXTERNAL := $(CONFIG_DIR)/buildroot
HEADS_EXTERNAL := $(CONFIG_DIR)/heads
CACHE_DIR := build
SRC_DIR := src
OUT_DIR := out
docker = docker
executables = $(docker) git patch

include $(PWD)/config/config.env

## Use env vars from existing release if present
ifneq (,$(wildcard $(RELEASE_DIR)/release.env))
    include $(RELEASE_DIR)/release.env
    export
endif

.DEFAULT_GOAL := out/manifest.txt

## Primary Targets

.PHONY: fetch
fetch: $(CACHE_DIR)/toolchain.tar
	mkdir -p build release
	$(call toolchain,$(USER),"fetch")

.PHONY: clean
clean: $(CACHE_DIR)/toolchain.tar
	$(call toolchain,$(USER),"clean")

.PHONY: mrproper
mrproper:
	docker image rm -f $(IMAGE)
	rm -rf $(CACHE_DIR)

.PHONY: build-fw
build-fw: $(CACHE_DIR)/toolchain.tar
	$(call toolchain,$(USER),"build-fw")
	mkdir -p $(RELEASE_DIR)
	for device in $(DEVICES); do \
		cp \
			$(CACHE_DIR)/heads/build/$${device}/pureboot*.rom \
			$(RELEASE_DIR)/$${device}.rom ; \
	done

## Release Targets

.PHONY: release
release: | out/release.env out/airgap.iso out/manifest.txt
	mkdir -p $(RELEASE_DIR)
	cp out/release.env $(RELEASE_DIR)/release.env
	cp out/airgap.iso $(RELEASE_DIR)/airgap.iso
	cp out/manifest.txt $(RELEASE_DIR)/manifest.txt

.PHONY: attest
attest:
	$(MAKE) mrproper out/manifest.txt
	diff -q out/manifest.txt release/$(VERSION)/manifest.txt;

.PHONY: sign
sign: $(RELEASE_DIR)/manifest.txt
	set -e; \
	git config --get user.signingkey 2>&1 >/dev/null || { \
		echo "Error: git user.signingkey is not defined"; \
		exit 1; \
	}; \
	fingerprint=$$(\
		git config --get user.signingkey \
		| sed 's/.*\([A-Z0-9]\{16\}\).*/\1/g' \
	); \
	gpg --armor \
		--detach-sig  \
		--output $(RELEASE_DIR)/manifest.$${fingerprint}.asc \
		$(RELEASE_DIR)/manifest.txt

.PHONY: verify
verify: $(RELEASE_DIR)/manifest.txt
	set -e; \
	for file in $(RELEASE_DIR)/manifest.*.asc; do \
		echo "\nVerifying: $${file}\n"; \
		gpg --verify $${file} $(RELEASE_DIR)/manifest.txt; \
	done;

.PHONY: audit
audit: $(CACHE_DIR)/toolchain.tar
	mkdir -p $(CACHE_DIR)/audit
	$(call toolchain,$(USER),"audit")

$(RELEASE_DIR):
	mkdir -p $(RELEASE_DIR)

$(RELEASE_DIR)/release.env: \
	$(RELEASE_DIR) \
	$(OUT_DIR)/release.env
	cp $(OUT_DIR)/release.env $(RELEASE_DIR)/release.env

$(RELEASE_DIR)/airgap.iso: \
	$(RELEASE_DIR) \
	$(OUT_DIR)/airgap.iso
	cp $(OUT_DIR)/airgap.iso $(RELEASE_DIR)/airgap.iso

$(RELEASE_DIR)/manifest.txt: \
	$(RELEASE_DIR) \
	$(OUT_DIR)/manifest.txt
	cp $(OUT_DIR)/manifest.txt $(RELEASE_DIR)/manifest.txt

## Development Targets

.PHONY: menuconfig
menuconfig: $(CACHE_DIR)/toolchain.tar
	$(call toolchain,$(USER),"menuconfig")
	cp $(CACHE_DIR)/buildroot/.config \
	"config/buildroot/configs/airgap_$(TARGET)_defconfig"

.PHONY: linux-menuconfig
linux-menuconfig: $(CACHE_DIR)/toolchain.tar
	$(call toolchain,$(USER),"linux-menuconfig")

.PHONY: vm
vm: $(CACHE_DIR)/toolchain.tar
	$(call toolchain,$(USER),"vm")

# Launch a shell inside the toolchain container
.PHONY: toolchain-shell
toolchain-shell: $(CACHE_DIR)/toolchain.tar
	$(call toolchain,$(USER),"bash --norc")

# Pin all packages in toolchain container to latest versions
.PHONY: toolchain-update
toolchain-update:
	docker run \
		--rm \
		--env LOCAL_USER=$(USER) \
		--platform=linux/$(ARCH) \
		--volume $(PWD)/$(CONFIG_DIR):/config \
		--volume $(PWD)/$(SRC_DIR)/toolchain/scripts:/usr/local/bin \
		--env ARCH=$(ARCH) \
		--interactive \
		--tty \
		debian@sha256:$(DEBIAN_HASH) \
		bash -c /usr/local/bin/packages-update

## Real targets

$(CACHE_DIR)/toolchain.tar:
	mkdir -p $(CACHE_DIR)
	DOCKER_BUILDKIT=1 \
	docker build \
		--tag $(IMAGE) \
		--build-arg DEBIAN_HASH=$(DEBIAN_HASH) \
		--build-arg CONFIG_DIR=$(CONFIG_DIR) \
		--build-arg SCRIPTS_DIR=$(SRC_DIR)/toolchain/scripts \
		--platform=linux/$(ARCH) \
		-f $(SRC_DIR)/toolchain/Dockerfile \
		.
	docker save "$(IMAGE)" -o "$@"

$(CACHE_DIR)/buildroot: $(CACHE_DIR)/toolchain.tar
	$(call git_clone,buildroot,$(BUILDROOT_REPO),$(BUILDROOT_REF))

$(CACHE_DIR)/heads: $(CACHE_DIR)/toolchain.tar
	$(call git_clone,heads,$(HEADS_REPO),$(HEADS_REF))

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(OUT_DIR)/release.env: $(OUT_DIR)
	echo 'VERSION=$(VERSION)'            > $(OUT_DIR)/release.env
	echo 'GIT_REF=$(GIT_REF)'           >> $(OUT_DIR)/release.env
	echo 'GIT_AUTHOR=$(GIT_AUTHOR)'     >> $(OUT_DIR)/release.env
	echo 'GIT_KEY=$(GIT_KEY)'           >> $(OUT_DIR)/release.env
	echo 'GIT_DATETIME=$(GIT_DATETIME)' >> $(OUT_DIR)/release.env

$(OUT_DIR)/airgap.iso: \
	$(CACHE_DIR)/buildroot \
	$(OUT_DIR)/release.env
	$(call apply_patches,buildroot,$(BR2_EXTERNAL)/patches)
	$(call toolchain,$(USER)," \
    	cd buildroot; \
    	make "airgap_$(TARGET)_defconfig"; \
		unset FAKETIME; \
    	make source; \
		make; \
	")
	mkdir -p $(OUT_DIR)
	cp $(CACHE_DIR)/buildroot/output/images/rootfs.iso9660 \
		$(OUT_DIR)/airgap.iso

$(OUT_DIR)/manifest.txt: \
	$(OUT_DIR)/airgap.iso \
	$(OUT_DIR)/release.env
	cd $(OUT_DIR); \
	openssl sha256 -r release.env > manifest.txt; \
	openssl sha256 -r airgap.iso >> manifest.txt;

## Make Helpers

check_executables := $(foreach exec,$(executables),\$(if \
	$(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

define git_clone
	[ -d $(CACHE_DIR)/$(1) ] || git clone $(2) $(CACHE_DIR)/$(1)
	git -C $(CACHE_DIR)/$(1) checkout $(3)
	git -C $(CACHE_DIR)/$(1) rev-parse --verify HEAD | grep -q $(3) || { \
		echo 'Error: Git ref/branch collision.'; exit 1; \
	};
endef

define apply_patches
	[ -d $(2) ] && $(call toolchain,$(USER)," \
		cd $(1); \
		git restore .; \
		find /$(2) -type f -iname '*.patch' -print0 \
		| xargs -t -0 -n 1 patch -p1 --no-backup-if-mismatch -i ; \
	")
endef

define toolchain
	docker load -i $(CACHE_DIR)/toolchain.tar
	docker run \
		--rm \
		--tty \
		--interactive \
		--user=$(1) \
		--platform=linux/$(ARCH) \
		--volume $(PWD)/config:/config \
		--volume $(PWD)/$(KEY_DIR):/keys \
		--volume $(PWD)/$(SRC_DIR):/src \
		--volume $(PWD)/$(CACHE_DIR):/home/build \
		--volume $(PWD)/scripts:/usr/local/bin \
		--cpus $(CPUS) \
		--workdir /home/build \
		--env HOME=/home/build \
		--env PS1="$(NAME)-toolchain" \
		--env GNUPGHOME=/cache/.gnupg \
		--env ARCH=$(ARCH) \
		--env TARGET="$(ARCH)" \
		--env GIT_REF="$(GIT_REF)" \
		--env GIT_AUTHOR="$(GIT_AUTHOR)" \
		--env GIT_KEY="$(GIT_KEY)" \
		--env GIT_DATETIME="$(GIT_DATETIME)" \
		--env GIT_EPOCH="$(GIT_EPOCH)" \
		--env KBUILD_BUILD_USER=$(KBUILD_BUILD_USER) \
		--env KBUILD_BUILD_HOST=$(KBUILD_BUILD_HOST) \
		--env KBUILD_BUILD_VERSION=$(KBUILD_BUILD_VERSION) \
		--env KBUILD_BUILD_TIMESTAMP=$(KBUILD_BUILD_TIMESTAMP) \
		--env KCONFIG_NOTIMESTAMP=$(KCONFIG_NOTIMESTAMP) \
		--env SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) \
		--env FAKETIME_FMT=$(FAKETIME_FMT) \
		--env FAKETIME=$(FAKETIME) \
		--env BR2_EXTERNAL="/$(BR2_EXTERNAL)" \
		--env HEADS_EXTERNAL="/$(HEADS_EXTERNAL)" \
		--env DEVICES="$(DEVICES)" \
		--env UID="$(shell id -u)" \
		--env GID="$(shell id -g)" \
		$(IMAGE) \
		bash -c $(2)
endef
