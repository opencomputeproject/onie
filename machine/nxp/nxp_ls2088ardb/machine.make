# Makefile fragment for NXP LS2088ARDB

# Copyright 2017 NXP Semiconductor, Inc.
#
# SPDX-License-Identifier:     GPL-2.0

ONIE_ARCH ?= armv8a
SWITCH_ASIC_VENDOR = none

VENDOR_REV ?= ONIE

# Translate hardware revision to ONIE hardware revision
MACHINE_REV = 1

UBOOT_MACHINE = ls2080ardb_ONIE_$(MACHINE_REV)
RUNTIME_ONIE_MACHINE = nxp-ls2080ardb
RUNTIME_ONIE_PLATFORM = arm64-nxp-ls2088ardb-r1

KERNEL_DTB = freescale/fsl-ls2088a-rdb.dtb
KERNEL_DTB_PATH = dts/$(KERNEL_DTB)

FDT_LOAD_ADDRESS = 0x90000000

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 33118

# Include kexec-tools
KEXEC_ENABLE = yes

#enable u-boot dtb
UBOOT_DTB_ENABLE = yes

# Set the desired U-Boot version
UBOOT_VERSION = 2015.10

#---------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
