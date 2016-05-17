# Makefile fragment for Freescale LS1043ARDB

# Copyright 2016 Freescale Semiconductor, Inc.
#
# SPDX-License-Identifier:     GPL-2.0

ONIE_ARCH ?= armv8a

VENDOR_REV ?= ONIE

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),ONIE)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

UBOOT_MACHINE = ls1043ardb_ONIE_$(MACHINE_REV)
KERNEL_DTB = freescale/fsl-ls1043a-rdb.dtb
KERNEL_DTB_PATH = dts/$(KERNEL_DTB)

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
