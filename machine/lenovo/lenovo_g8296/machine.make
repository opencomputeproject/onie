# Makefile fragment for Lenovo G8296

ONIE_ARCH ?= powerpc-softfloat
SWITCH_ASIC_VENDOR = bcm

VENDOR_REV ?= 0
VENDOR_VERSION = .0.1

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

UBOOT_MACHINE = LENOVO_G8296
KERNEL_DTB = lenovo_g8296.dtb

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 19046

# Set Linux kernel version
LINUX_TARBALL_URLS	= http://git.freescale.com/git/cgit.cgi/ppc/sdk/linux.git/snapshot
LINUX_RELEASE		= fsl-sdk-v1.8
LINUX_TARBALL		= linux-$(LINUX_RELEASE).tar.bz2
#LINUX_VERSION		= fsl-sdk-v1.7
#LINUX_MINOR_VERSION	= 27

# Older GCC required for older fsl-sdk kernel
GCC_VERSION = 4.9.2

#Add EXT 3 support
EXT3_4_ENABLE = yes

# Specify uClibc version
#UCLIBC_VERSION = 0.9.32.1

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
