# Makefile fragment for Accton AS7710_32X

# Vendor's version number can be defined here.
# Available variables are 'VENDOR_VERSION' and 'UBOOT_IDENT_STRING'.
# e.g.,
# VENDOR_VERSION = .00.01
# UBOOT_IDENT_STRING = 1.4.0.1

ONIE_ARCH ?= powerpc-softfloat
SWITCH_ASIC_VENDOR = bcm

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

EXT3_4_ENABLE = yes

# Set the desired kernel version.
LINUX_TARBALL_URLS	= http://git.freescale.com/git/cgit.cgi/ppc/sdk/linux.git/snapshot
LINUX_RELEASE		= fsl-sdk-v1.7
LINUX_TARBALL		= linux-$(LINUX_RELEASE).tar.bz2

# Set the desired u-boot version.
UBOOT_TARBALL_URLS	= http://git.freescale.com/git/cgit.cgi/ppc/sdk/u-boot.git/snapshot
UBOOT_VERSION		= fsl-sdk-v1.7

UBOOT_MACHINE = AS7710_32X
KERNEL_DTB = as7710_32x.dtb

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Accton Technology Corporation IANA number
VENDOR_ID = 259

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
