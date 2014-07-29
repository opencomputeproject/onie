# Makefile fragment for Accton AS5710_54X

ONIE_ARCH ?= powerpc-softfloat

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
LINUX_RELEASE		= fsl-sdk-v1.5
LINUX_TARBALL		= linux-$(LINUX_RELEASE).tar.bz2

UBOOT_MACHINE = AS5710_54X
KERNEL_DTB = as5710_54x.dtb

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Accton Technology Corporation IANA number
VENDOR_ID = 259

VENDOR_VERSION = .0.6
UBOOT_IDENT_STRING = 1.4.0.2

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
