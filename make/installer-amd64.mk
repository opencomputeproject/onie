###############################################################################
#
# Common AMD64 Installers
#
#
###############################################################################
ifndef ONL
$(error $$ONL is not set.)
else
include $(ONL)/make/config.mk
endif

# The platform list must be specified
ifndef INSTALLER_PLATFORMS
$(error $$INSTALLER_PLATFORMS not defined)
endif

# The final name of the installer file must be specified.
ifndef INSTALLER_NAME
$(error $$INSTALLER_NAME is not set)
endif

export INSTALLER_SWI
export INSTALLER_NAME

# Get the platform loaders from each platform package
KERNELS			:= $(shell $(ONL_PKG_INSTALL) kernel-x86-64:amd64 --find-file kernel-x86_64) $(shell $(ONL_PKG_INSTALL) kernel-3.14-x86-64-all:amd64 --find-file kernel-3.14-x86_64-all)
INITRD			:= $(shell $(ONL_PKG_INSTALL) initrd-amd64:amd64 --find-file initrd-amd64)

MKSHAR = $(ONL)/tools/mkshar
##MKSHAR_OPTS = --lazy --unzip-sfx --unzip-loop --unzip-pipe
MKSHAR_OPTS = --lazy --unzip-pad

$(INSTALLER_NAME): $(PLATFORM_DIRS) $(INSTALLER_SWI) installer-setup
	$(ONL_V_at)rm -rf *.installer *.installer.md5sum .*.installer.md5sum
	$(foreach k,$(KERNELS),cp $(k) .;)
	$(ONL_V_at)cp $(INITRD) .
	$(foreach p,$(INSTALLER_PLATFORMS), $(ONL_PKG_INSTALL) platform-config-$(p):all --extract .;)
ifdef INSTALLER_SWI
	$(ONL_V_at)cp $(INSTALLER_SWI) .
endif
	$(ONL_V_at)sed \
	  -e 's^@ONLVERSION@^$(RELEASE)^g' \
	  $(ONL)/builds/installer/amd64-installer.sh \
	>> installer.sh
	$(ONL_V_GEN)set -o pipefail ;\
	if $(ONL_V_P); then v="-v"; else v="--quiet"; fi ;\
	$(MKSHAR) $(MKSHAR_OPTS) $@ $(ONL)/tools/sfx.sh.in installer.sh kernel-x86_64 kernel-3.14-x86_64-all initrd-amd64 lib *.swi $(INSTALLER_EXTRA_FILES)
ifdef INSTALLER_SWI
	$(ONL_V_at)rm -f *.swi
endif
	$(ONL_V_at)rm -rf installer.sh ./lib ./usr kernel-x86_64 kernel-3.14-x86_64-all initrd-amd64
ifdef INSTALLER_CLEAN_FILES
	$(ONL_V_at)rm -rf $(INSTALLER_CLEAN_FILES)
endif
	md5sum $@ | awk '{ print $$1 }' > .$@.md5sum


shar installer: $(INSTALLER_NAME)

ifdef INSTALLER_SWI
$(INSTALLER_SWI):
	$(MAKE) -C $(dir $(INSTALLER_SWI))
endif

# Build config
ifndef ONL_BUILD_CONFIG
$(error $$ONL_BUILD_CONFIG is not defined.)
endif

# Release string, copied from swi.mk
ifndef RELEASE
RELEASE := Open Network Linux $(ONL_RELEASE_BANNER)($(ONL_BUILD_CONFIG),$(ONL_BUILD_TIMESTAMP),$(ONL_BUILD_SHA1))
endif

clean:
	rm -f *.swi *.installer kernel-x86_64 initrd-amd64


installer-setup::

