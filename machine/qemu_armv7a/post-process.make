# QEMU armv7a Virtual Machine post processing instructions

#  Copyright (C) 2015 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

#-------------------------------------------------------------------------------
#
# This makefile fragment creates the NOR flash and SD flash images for
# the QEMU machine.
#
# Step 1. Create a blank SD card image file.  This example shows a
#         256MB SD card:
#
# Step 2. Create two blank 64MB NOR flash images:
#
# Step 3. Copy the ONIE u-boot and ONIE kernel images into the
#         ``onie-nor0.img``
#
# Step 4. Add the EEPROM data to the NOR flash:

MACHINE_IMAGE_COMPLETE_STAMP	= $(STAMPDIR)/machine-image-complete

SD_IMAGE	= $(IMAGEDIR)/onie-$(MACHINE_PREFIX)-sd.img
NOR0_IMAGE	= $(IMAGEDIR)/onie-$(MACHINE_PREFIX)-nor0.img
NOR1_IMAGE	= $(IMAGEDIR)/onie-$(MACHINE_PREFIX)-nor1.img

# For clean-up define the files this fragment creates that should be
# removed during 'make clean'.
MACHINE_IMAGE_PRODUCTS = $(SD_IMAGE) $(NOR0_IMAGE) $(NOR1_IMAGE)

SECTOR_SIZE	= 256k
EEPROM_DATA	= $(MACHINEDIR)/onie-qemu-eeprom.dat

ONIE_IMG_BIN 	  = $(IMAGEDIR)/onie-$(MACHINE_PREFIX).bin
UBOOT_ENV_IMG_BIN = $(ONIE_IMG_BIN).uboot+env

PHONY += machine-image-complete
machine-image-complete: $(MACHINE_IMAGE_COMPLETE_STAMP)
$(MACHINE_IMAGE_COMPLETE_STAMP): $(IMAGE_BIN_STAMP)
	$(Q) echo "==== Create $(MACHINE) virtual disk and flash images ===="
	$(Q) fallocate -l 256M $(SD_IMAGE)
	$(Q) fallocate -l 64M $(NOR0_IMAGE)
	$(Q) fallocate -l 64M $(NOR1_IMAGE)
	$(Q) dd if=$(UBOOT_ENV_IMG_BIN) of=$(NOR0_IMAGE) conv=notrunc bs=$(SECTOR_SIZE)
	$(Q) dd if=$(ONIE_IMG_BIN)	    of=$(NOR0_IMAGE) conv=notrunc bs=$(SECTOR_SIZE) seek=4
	$(Q) dd if=$(EEPROM_DATA)	    of=$(NOR0_IMAGE) conv=notrunc bs=$(SECTOR_SIZE) seek=3
	$(Q) touch $@

################################################################################
#
# Local Variables:
# mode: makefile-gmake
# End:
