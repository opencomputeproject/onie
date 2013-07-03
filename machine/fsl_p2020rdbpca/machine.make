# Makefile fragment for FSL P2020RDB

VENDOR_REV ?= ONIE

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),ONIE)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

UBOOT_MACHINE = P2020RDB-PC_ONIE_$(MACHINE_REV)
KERNEL_DTB = p2020rdb.dtb

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 33118

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
