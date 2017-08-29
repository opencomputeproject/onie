# QEMU armv7a Virtual Machine

#  Copyright (C) 2014,2015,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

# This machine configuration is based on the VEXPRESS ARM.

ONIE_ARCH ?= armv7a
SWITCH_ASIC_VENDOR = qemu

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

UBOOT_MACHINE = ca9x4_ct_vxp_onie_qemu

KERNEL_DTB = vexpress-v2p-ca9.dtb
# 3.14.x kernel keeps the .dtb in a different directory compared to 3.2.x
# using old 3.2.y for now
KERNEL_DTB_PATH = dts/$(KERNEL_DTB)

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
# VENDOR_VERSION = .12.34

LINUX_VERSION = 4.1
LINUX_MINOR_VERSION = 38

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 42623

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
