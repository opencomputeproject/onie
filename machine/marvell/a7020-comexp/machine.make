# Makefile fragment for Marvell a7020-comexp
#
# Copyright 2017 Marvell International Ltd.
#
# SPDX-License-Identifier:     GPL-2.0


ONIE_ARCH ?= armv8a
SWITCH_ASIC_VENDOR = mvl

VENDOR_REV ?= 0

MACHINE_REV = 0

#set XTOOLS_ENABLE = "no" while using spesific cross-compiler (CROSSBIN)
XTOOLS_ENABLE?=yes

ifeq ($(XTOOLS_ENABLE),no)
  TARGET = aarch64-linux-gnu
  CROSSBIN = /local/store/projects/toolChain/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin
  GCC_VERSION = 5.2.1
  XTOOLS_BUILD_STAMP = $(CROSSBIN)/$(TARGET)-gcc
  STRACE_ENABLE = no
endif

# Set the desired U-Boot version
UBOOT_VERSION = 2018.03

#enable u-boot dtb
#UBOOT_DTB_ENABLE = yes

UBOOT_MACHINE = mvebu_db_armada8k
#RUNTIME_ONIE_MACHINE = a7020-comexp
#RUNTIME_ONIE_PLATFORM = arm64-a7020-comexp-r0

KERNEL_DTB = marvell/armada-7020-comexpress.dtb
KERNEL_DTB_PATH = dts/$(KERNEL_DTB)

#FDT_LOAD_ADDRESS =  0x0x4f00000

LINUX_VERSION = 4.9
LINUX_MINOR_VERSION = 95

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
# VENDOR_VERSION =

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 20495

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
