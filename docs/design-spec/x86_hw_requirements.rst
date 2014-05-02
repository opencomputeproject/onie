.. _x86_hw_requirements:

*************************
x86 Hardware Requirements
*************************

For general switch hardware requirements see the
:ref:`switch_hw_requirements` section.

The hardware requirements for the x86 CPU architecture are:

====================================  =========================================
Required Hardware                     Purpose
====================================  =========================================
1GB (min) CPU DRAM                    The DRAM used by the CPU.
Mass storage 4GB(min), 16GB (rec)     GRUB, the ONIE kernel and the
                                      network OS reside in the mass
                                      storage block device.  Although
                                      4GB is the minimum size of this
                                      flash, 16GB is the recommended
                                      size.
Non-volatile board information        An EEPROM to store board information and
                                      manufacturing data, like the device
                                      serial number and network MAC address.
Ethernet management port              Required to download an operating system
                                      installer.
====================================  =========================================

For the mass storage device many possibilities exist.  The only real
requirement is that the BIOS recognizes the device as bootable.  Some
possibilities are:

- mSATA
- CFast
- SATA SSD
- USB NAND
