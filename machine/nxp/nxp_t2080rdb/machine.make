# Makefile fragment for Freescale T2080RDB

# Copyright 2016 Freescale Semiconductor, Inc.
#
# SPDX-License-Identifier:     GPL-2.0

ONIE_ARCH ?= powerpc-softfloat
SWITCH_ASIC_VENDOR = none

VENDOR_REV ?= ONIE

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),ONIE)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

UBOOT_MACHINE = T2080RDB_ONIE_$(MACHINE_REV)
KERNEL_DTB = t2080rdb.dtb

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 33118

# Include kexec-tools
KEXEC_ENABLE = yes

# Set the desired U-Boot version
UBOOT_VERSION = 2015.10

#---------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
