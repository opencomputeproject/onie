# Makefile fragment for CENTEC E580-20Q4Z 


ONIE_ARCH ?= powerpc-softfloat
SWITCH_ASIC_VENDOR = centec

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# Set the desired kernel version.
LINUX_TARBALL_URLS	= http://git.freescale.com/git/cgit.cgi/ppc/sdk/linux.git/snapshot
LINUX_RELEASE		= fsl-sdk-v1.5
LINUX_TARBALL		= linux-$(LINUX_RELEASE).tar.bz2

# Older GCC required for older fsl-sdk-v1.5 kernel
GCC_VERSION = 4.9.2

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 27975 

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
