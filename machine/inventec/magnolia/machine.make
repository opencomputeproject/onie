# Inventec Magnolia
# CPU Module: Intel Atom Rangeley (C2000)

ONIE_ARCH ?= x86_64

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
# Inventec Corporation
VENDOR_ID = 6569

# Skip the i2ctools and the onie-syseeprom command for this platform
#I2CTOOLS_ENABLE = no

# Set the desired kernel version.
LINUX_VERSION		= 3.2
LINUX_MINOR_VERSION	= 69

#LINUX_VERSION		= 3.14
#LINUX_MINOR_VERSION	= 16

# Set the desired uClibc version
UCLIBC_VERSION = 0.9.33.2

#NOS DEBIAN
NOS_IMAGE_PARTS = $(NOS_KERNEL_VMLINUZ) $(INITRAMFS_INITRD)
NOS_IMAGE_PARTS_COMPLETE = $(NOS_KERNEL_COMPLETE_STAMP) $(INITRAMFS_INITRD)
DEBIAN_PLATFORM = amd64

# BCM
# Include BCM SDK
BCM_ENABLE = yes
BCM_GITREPO             ?= git@10.3.11.30:switch/bcm.git
#BCM_GITBRANCH           ?= hudson32
#BCM_GITTAG              ?= 2014-11-06
BCM_GITBRANCH           ?= magnolia
BCM_GITTAG              ?= magnolia
BCM_LINUX_DIR           ?= x86-onie-3_2

# Coremark
COREMARK_ENABLE = yes

# Memtester
MEMTESTER_ENABLE = yes

# Stress CPU
STRESS_ENABLE = yes

# hmd
HMD_ENABLE = yes

# cpld
CPLD_ENABLE = yes

# psoc
PSOC_ENABLE = yes

#
# Console parameters can be defined here 
# - default values are in build-config/arch/x86_64.make
# - template files are build-config/recovery/syslinux.cfg and build-config/recovery/grub-pxe.cfg 
# 
CONSOLE_FLAG = 1
CONSOLE_DEV = 1

#
# rootdelay parameter (only for nos)
#
ROOTDELAY = 5

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
