.. _powerpc_hw_requirements:

*****************************
PowerPC Hardware Requirements
*****************************

For general switch hardware requirements see the
:ref:`switch_hw_requirements` section.

The hardware requirements for the PowerPC CPU architecture are:

====================================  =========================================
Required Hardware                     Purpose
====================================  =========================================
U-Boot compatible CPU complex         The CPU complex must be supported by
                                      U-Boot.
1GB (min) CPU DRAM                    The DRAM used by the CPU.
NOR Boot flash 8MB (min), 32MB (rec)  U-Boot and the ONIE kernel and
                                      applications reside in NOR flash.
                                      Although 8MB is the minimum size of
                                      this flash, 32MB is the recommended
                                      size.
Non-volatile board information        An EEPROM to store board information and
                                      manufacturing data, like the device
                                      serial number and network MAC address.
Ethernet management port              Required to download an operating system
                                      installer.
====================================  =========================================
