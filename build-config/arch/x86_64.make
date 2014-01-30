#-------------------------------------------------------------------------------
#
#  x86 Architecture and Toolchain Setup
#

ARCH        ?= x86_64
TARGET      ?= $(ARCH)-onie-linux-uclibc
CROSSPREFIX ?= $(TARGET)-
CROSSBIN    ?= $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin

KERNEL_ARCH		= x86
KERNEL_INSTALL_DEPS	+= $(KERNEL_VMLINUZ_INSTALL_STAMP)

CLIB64 = 64

PLATFORM_IMAGE_COMPLETE = $(IMAGE_UPDATER_STAMP)

UPDATER_IMAGE_PARTS = $(UPDATER_VMLINUZ) $(UPDATER_INITRD) $(UPDATER_ONIE_TOOLS) \
			$(ROOTCONFDIR)/x86_64/sysroot-lib-onie/onie-blkdev-common

UPDATER_IMAGE_PARTS_COMPLETE = $(KERNEL_INSTALL_STAMP) $(UPDATER_INITRD) $(UPDATER_ONIE_TOOLS)

DEMO_IMAGE_PARTS = $(DEMO_KERNEL_VMLINUZ) $(DEMO_SYSROOT_CPIO_XZ)
DEMO_IMAGE_PARTS_COMPLETE = $(DEMO_KERNEL_COMPLETE_STAMP) $(DEMO_SYSROOT_CPIO_XZ)

GPT_ENABLE = yes

# gptfdisk requires C++
REQUIRE_CXX_LIBS = yes

EXT3_4_ENABLE = yes

GRUB_ENABLE = yes

# Update this if the GRUB configuration mechanism changes from one
# release to the next.
ONIE_CONFIG_VERSION = 0

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
