# QEMU armv8a Virtual Machine

#  This file is derived from https://github.com/opencomputeproject/onie/blob/master/machine/kvm_x86_64/machine.make
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0


ONIE_ARCH ?= armv8a
SWITCH_ASIC_VENDOR = qemu

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

XTOOLS_ENABLE = yes

ifeq ($(XTOOLS_ENABLE),no)
  TARGET = aarch64-linux-gnu
  CROSSBIN = $(HOME)/gcc-linaro-5.3-2016.02-x86_64_aarch64-linux-gnu/bin
  GCC_VERSION = 5.3.1
  XTOOLS_LIBC = glibc
  XTOOLS_LIBC_VERSION = 2.21
  LINUX_VERSION = 4.1.23
  STRACE_ENABLE = no
  XTOOLS_BUILD_STAMP = $(CROSSBIN)/$(TARGET)-gcc
endif

UBOOT_ENABLE = no
# Enable UEFI support
UEFI_ENABLE = yes

# Enable GRUB support
GRUB_ENABLE = yes

# Enable building firmware updates
FIRMWARE_UPDATE_ENABLE = no

RECOVERY_DEFAULT_ENTRY = embed

PXE_EFI64_ENABLE = yes

LINUX_VERSION = 4.4
LINUX_MINOR_VERSION = 30

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
# VENDOR_VERSION = .12.34

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 42623

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
