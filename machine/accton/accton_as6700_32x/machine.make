# Makefile fragment for Accton AS6700_32X

# Vendor's version number can be defined here.
# Available variables are 'VENDOR_VERSION' and 'UBOOT_IDENT_STRING'.
# e.g.,
# VENDOR_VERSION = .00.01
# UBOOT_IDENT_STRING = 1.4.0.1

ONIE_ARCH ?= powerpc-softfloat
SWITCH_ASIC_VENDOR = bcm

VENDOR_REV ?= r01c

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),r01b)
  MACHINE_REV = 0
else ifeq ($(VENDOR_REV),r01c)
  MACHINE_REV = 1
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

EXT3_4_ENABLE = yes
UBOOT_PBL_ENABLE = yes

KERNEL_DTB = $(MACHINE_PREFIX).dtb

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Accton Technology Corporation IANA number
VENDOR_ID = 259

# Set the desired kernel version.
LINUX_TARBALL_URLS	= http://git.freescale.com/git/cgit.cgi/ppc/sdk/linux.git/snapshot
LINUX_RELEASE		= fsl-sdk-v1.5
LINUX_TARBALL		= linux-$(LINUX_RELEASE).tar.bz2

# Older GCC required for older fsl-sdk-v1.5 kernel
GCC_VERSION = 4.9.2

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
