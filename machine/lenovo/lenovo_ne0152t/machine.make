# Copyright (C) 2018 Lenovo.

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Lenovo NE0152T

# Vendor's version number can be defined here.
# Available variable is 'VENDOR_VERSION'.
# e.g.,
# VENDOR_VERSION = .00.01

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = bcm

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

VENDOR_VERSION = .0.1

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Lenovo IANA number
VENDOR_ID = 19046

I2CTOOLS_ENABLE = yes
UEFI_ENABLE = yes
#PXE_EFI64_ENABLE = yes

# Console parameters
CONSOLE_DEV = 1

# Set Linux kernel version
LINUX_VERSION		= 4.9
LINUX_MINOR_VERSION	= 95

GCC_VERSION = 6.3.0

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
