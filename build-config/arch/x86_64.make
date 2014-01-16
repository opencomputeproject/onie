#-------------------------------------------------------------------------------
#
#  x86 Architecture and Toolchain Setup
#

# This is for testing purposes only.  It is totally wonky as it just
# uses gcc from /usr/bin, which may or may not be the "cross compiler"
# you want.  Works now because the development machine is x86_64.

ARCH        ?= x86_64
TARGET      ?= $(ARCH)-onie-linux-uclibc
CROSSPREFIX ?= $(TARGET)-
CROSSBIN    ?= $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin

KERNEL_ARCH		= x86
KERNEL_INSTALL_DEPS	+= kernel-vmlinuz-install

CLIB64 = 64

PLATFORM_IMAGE_COMPLETE = $(KERNEL_INSTALL_STAMP) $(SYSROOT_CPIO_XZ)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
