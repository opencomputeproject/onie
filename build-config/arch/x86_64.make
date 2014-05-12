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

ifeq ($(PXE_EFI64_ENABLE),yes)
  PLATFORM_IMAGE_COMPLETE += $(PXE_EFI64_STAMP)
endif

UPDATER_IMAGE_PARTS = $(UPDATER_VMLINUZ) $(UPDATER_INITRD) $(UPDATER_ONIE_TOOLS) \
			$(ROOTCONFDIR)/x86_64/sysroot-lib-onie/onie-blkdev-common

UPDATER_IMAGE_PARTS_COMPLETE = $(KERNEL_INSTALL_STAMP) $(UPDATER_INITRD) $(UPDATER_ONIE_TOOLS)

DEMO_IMAGE_PARTS = $(DEMO_KERNEL_VMLINUZ) $(DEMO_SYSROOT_CPIO_XZ)
DEMO_IMAGE_PARTS_COMPLETE = $(DEMO_KERNEL_COMPLETE_STAMP) $(DEMO_SYSROOT_CPIO_XZ)

# Default to GPT on x86.  A particular machine.make can override this.
PARTITION_TYPE ?= gpt

# Include the GPT partitioning tools
GPT_ENABLE = yes

# gptfdisk requires C++
REQUIRE_CXX_LIBS = yes

# Include the GNU parted partitioning tools
PARTED_ENABLE = yes

# Include ext3/4 file system tools
EXT3_4_ENABLE = yes

# Include GRUB tools
GRUB_ENABLE = yes

# Default to include the i2ctools.  A particular machine.make can
# override this.
I2CTOOLS_ENABLE ?= yes

# Include dmidecode tools
DMIDECODE_ENABLE = yes

# Include lvm2 tools
LVM2_ENABLE = yes

# Include ethtool by default
ETHTOOL_ENABLE ?= yes

# Update this if the GRUB configuration mechanism changes from one
# release to the next.
ONIE_CONFIG_VERSION = 1

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
