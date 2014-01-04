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

PLATFORM_IMAGE_COMPLETE = $(KERNEL_INSTALL_STAMP) $(SYSROOT_CPIO_XZ)
DEMO_IMAGE_PARTS = $(DEMO_KERNEL_VMLINUZ) $(DEMO_SYSROOT_CPIO_XZ)
DEMO_IMAGE_PARTS_COMPLETE = $(DEMO_KERNEL_COMPLETE_STAMP) $(DEMO_SYSROOT_CPIO_XZ)

GPT_ENABLE = yes
# gptfdisk requires C++
REQUIRE_CXX_LIBS = yes

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
