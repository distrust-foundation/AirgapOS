################################################################################
#
# flashtools
#
################################################################################

FLASHTOOLS_VERSION = 9acce09aeb635c5bef01843e495b95e75e8da135
FLASHTOOLS_SITE = https://github.com/osresearch/flashtools.git
FLASHTOOLS_SITE_METHOD = git
FLASHTOOLS_LICENSE = GPL-2.0
FLASHTOOLS_LICENSE_FILES = LICENSE

ifeq ($(BR2_PACKAGE_FLASHTOOLS_FLASHTOOL),y)
	FLASHTOOLS_TARGETS += flashtool
endif

ifeq ($(BR2_PACKAGE_FLASHTOOLS_PEEK),y)
	FLASHTOOLS_TARGETS += peek
endif

ifeq ($(BR2_PACKAGE_FLASHTOOLS_POKE),y)
	FLASHTOOLS_TARGETS += poke
endif

ifeq ($(BR2_PACKAGE_FLASHTOOLS_CBFS),y)
	FLASHTOOLS_TARGETS += cbfs
endif

ifeq ($(BR2_PACKAGE_FLASHTOOLS_UEFI),y)
	FLASHTOOLS_TARGETS += uefi
endif

define FLASHTOOLS_BUILD_CMDS
	$(foreach t,$(FLASHTOOLS_TARGETS),\
		$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) \
			CFLAGS="$(TARGET_CFLAGS)" -C $(@D) $(t) \
	)
endef

define FLASHTOOLS_INSTALL_TARGET_CMDS
	$(foreach t,$(FLASHTOOLS_TARGETS),\
		$(INSTALL) -D -m 0755 $(@D)/$(t) $(TARGET_DIR)/usr/bin/$(t)$(sep) \
	)
endef


$(eval $(generic-package))
