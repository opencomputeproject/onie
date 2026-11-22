# NXP LX2160ARDB (LX2160A, 16x Cortex-A72, DPAA2)
#
# U-Boot is not built by ONIE: the LX2160A boots TF-A -> U-Boot from
# FlexSPI NOR (NXP lf-6.18.37 BSP). ONIE's FIT image lives in NOR chip 0 at
# 0x1000000 and is started by U-Boot environment variables (see INSTALL).

ONIE_ARCH ?= armv8a
SWITCH_ASIC_VENDOR = none

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

UBOOT_ENABLE = no
UBOOT_EXTERNAL = yes

KERNEL_DTB = freescale/fsl-lx2160a-rdb.dtb
KERNEL_DTB_PATH = dts/$(KERNEL_DTB)

# U-Boot stages the DPAA2 layout (DPL) at 0x80d00000 and applies it at
# bootm, after the images are loaded: keep the kernel above it.
KERNEL_LOAD_ADDRESS = 0x82000000
KERNEL_ENTRY_POINT = 0x82000000
FDT_LOAD_ADDRESS = 0x90000000

# NXP's IANA private enterprise number
VENDOR_ID = 33118

KEXEC_ENABLE = yes
MTDUTILS_ENABLE = yes

CONSOLE_DEV = ttyAMA0
CONSOLE_SPEED = 115200

# 6.12: DPAA2 PHY management (dpaa2-mac/phylink, since 5.5) for ONIE
# networking on the RGMII DPMACs; the same kernel SONiC runs on this board.
# The toolchain keeps 5.4.86 headers (crosstool-NG 1.24 predates 6.x).
LINUX_VERSION = 6.12
LINUX_MINOR_VERSION = 41
XTOOLS_LINUX_VERSION = 5.4
XTOOLS_LINUX_MINOR_VERSION = 86

# Local Variables:
# mode: makefile-gmake
# End:
