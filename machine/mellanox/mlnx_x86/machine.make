# Mellanox X86 Series
# MSX1400: CPU Module: Intel Core i7-3612QE

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = mlnx

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Mellanox IANA number
VENDOR_ID = 33049

I2CTOOLS_ENABLE = yes

export EXTRA_CMDLINE_LINUX := acpi_enforce_resources=no nmi_watchdog=0 $(EXTRA_CMDLINE_LINUX)

#
#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

LINUX_VERSION = 3.10

LINUX_MINOR_VERSION = 0-54.0.1.el7.x86_64

LINUX_TARBALL = linux-3.10.0-54.0.1.el7.x86_64.tar.xz

MELLANOX_PXE_UPDATER_STAMP   = $(STAMPDIR)/mellanox-pxe-updater-stamp
MELLANOX_NETBOOT_PXE_UPDATER = $(IMAGEDIR)/mellanox_net_boot_label.sh

mellanox-net-boot-label: $(MELLANOX_PXE_UPDATER_STAMP)

$(MELLANOX_PXE_UPDATER_STAMP): $(MELLANOX_NETBOOT_PXE_UPDATER)
	touch $@

$(MELLANOX_NETBOOT_PXE_UPDATER): $(MACHINEDIR)/net_boot_label.template
	mkdir -p $(@D)
	cat $< | sed -e "s/@VERSION@/$(MACHINE_PREFIX)/g" > $@
	chmod +x $@

include $(MACHINEDIR)/mellanox_bsp_tools_kernel.make
include $(MACHINEDIR)/mellanox_bsp_tools.make
