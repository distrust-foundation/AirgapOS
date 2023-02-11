include $(PWD)/src/toolchain/Makefile

.DEFAULT_GOAL := $(OUT_DIR)/airgap.iso

.PHONY: clean
clean: toolchain
	rm -f $(OUT_DIR) $(CACHE_DIR)/buildroot-ccache || :
	$(call toolchain,$(USER)," \
		cd $(FETCH_DIR)/buildroot; \
		make clean; \
	")

.PHONY: mrproper
mrproper:
	docker image rm -f $(IMAGE)
	rm -rf $(CACHE_DIR) $(OUT_DIR)

.PHONY: menuconfig
menuconfig: toolchain
	$(call toolchain,$(USER)," \
		cd $(FETCH_DIR)/buildroot; \
		make "airgap_$(TARGET)_defconfig"; \
		make menuconfig; \
	")
	cp $(FETCH_DIR)/buildroot/.config \
	"config/buildroot/configs/airgap_$(TARGET)_defconfig"

.PHONY: linux-menuconfig
linux-menuconfig: toolchain
	$(call toolchain,$(USER),"\
		cd $(FETCH_DIR)/buildroot; \
		make linux-menuconfig; \
		make linux-update-defconfig; \
	")

.PHONY: vm
vm: toolchain
	$(call toolchain,$(USER)," \
		qemu-system-i386 \
			-M pc \
			-nographic \
			-cdrom "${HOME}/release/${TARGET}/airgap.iso"; \
	")

.PHONY: release
release: | \
	$(OUT_DIR)/airgap.iso \
	$(OUT_DIR)/manifest.txt
	mkdir -p $(DIST_DIR)
	cp $(OUT_DIR)/release.env $(DIST_DIR)/release.env
	cp $(OUT_DIR)/airgap.iso $(DIST_DIR)/airgap.iso
	cp $(OUT_DIR)/manifest.txt $(DIST_DIR)/manifest.txt

$(FETCH_DIR)/buildroot: toolchain
	$(call git_clone,buildroot,$(BUILDROOT_REPO),$(BUILDROOT_REF))

$(OUT_DIR)/airgap.iso: \
	toolchain \
	$(FETCH_DIR)/buildroot \
	$(OUT_DIR)/release.env
	$(call apply_patches,$(FETCH_DIR)/buildroot,$(BR2_EXTERNAL)/patches)
	$(call toolchain,$(USER)," \
    	cd $(FETCH_DIR)/buildroot; \
    	make "airgap_$(TARGET)_defconfig"; \
		unset FAKETIME; \
		make source; \
		make; \
	")
	mkdir -p $(OUT_DIR)
	cp $(FETCH_DIR)/buildroot/output/images/rootfs.iso9660 \
		$(OUT_DIR)/airgap.iso
