# Makefile fragment for FSL P2020RDB

#  Copyright (C) 2013,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

ONIE_ARCH ?= powerpc-softfloat

VENDOR_REV ?= ONIE

SWITCH_ASIC_VENDOR = none

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),ONIE)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

UBOOT_MACHINE = P2020RDB-PC_ONIE_$(MACHINE_REV)
KERNEL_DTB = p2020rdb.dtb

LINUX_VERSION = 4.1
LINUX_MINOR_VERSION = 38

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 33118

# Include kexec-tools
KEXEC_ENABLE = yes

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
