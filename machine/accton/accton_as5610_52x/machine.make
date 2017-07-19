# Makefile fragment for Accton AS5610_52X

# Vendor's version number can be defined here.
# Available variables are 'VENDOR_VERSION' and 'UBOOT_IDENT_STRING'.
# e.g.,
# VENDOR_VERSION = .00.01
# UBOOT_IDENT_STRING = 1.4.0.1


ONIE_ARCH ?= powerpc-softfloat
SWITCH_ASIC_VENDOR = bcm

VENDOR_REV ?= r01a

# Translate Accton hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),r01a)
  MACHINE_REV = 0
else ifeq ($(VENDOR_REV),r01d)
  # This machine has new SDRAM and a different oscillator
  MACHINE_REV = 1
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

EXT3_4_ENABLE = no
MTDUTILS_ENABLE = no

UBOOT_MACHINE = AS5610_52X
KERNEL_DTB = as5610_52x.dtb

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Accton Technology Corporation IANA number
VENDOR_ID = 259

# Set Linux kernel version
LINUX_VERSION		= 3.2
LINUX_MINOR_VERSION	= 69

# Older GCC required for older 3.2 kernel
GCC_VERSION = 4.9.2

# Exclude ext3/4 file system tools
EXT3_4_ENABLE = no
# Exclude btrfs file system tools
BTRFS_PROGS_ENABLE = no
# Exclude strace debug utility
STRACE_ENABLE = no

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
