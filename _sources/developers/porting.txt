.. Copyright (C) 2014,2018 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

Porting Guide
=============

This section describes requirements and general guidelines to follow
when porting ONIE to a new platform.  Also, the
:ref:`unit_testing` guide *must* be used to validate the ONIE
implementation.

Porting U-Boot
--------------

When porting U-Boot, the following items should be checked and
verified:

* Ethernet management PHY LEDs should function correctly.
* Front panel status LEDs are set appropriately - check power, fans
  and set any corresponding LEDs.
* Fan speeds set to 100% duty cycle.
* Verify MAC address and serial number are exported as environment variables.
* Confirm CONFIG_SYS_CLK_FREQ and CONFIG_DDR_CLK_FREQ oscillators by
  visual inspection.  For example, if an oscillator is 66.666MHz use
  66666000 not 66666666, as the latter will lead to skew.
* Issue "INFO" message if a PSU is not detected or is in a failed state.
* Verify the "INSTALL" instructions from the machine directory work.
  These are the instructions used to install ONIE from the U-Boot
  prompt. If the INSTALL instructions need updating, fix them.

ONIE DTS (Device Tree)
----------------------

When porting the ONIE kernel the following ``.dts`` (device tree) entries
should be checked and verified:

* The RTC is in the ``.dts`` file and works correctly.
* The MDIO/PHY interrupts are correct in ``.dts``.
* Disable unused serial consoles in ``.dts``.
* Verify all EEPROMs (including SPDs) are accessible via ``sysfs`` using
  ``hexdump``. Set the "label" property accordingly:

  * board_eeprom – for the board EEPROM

  * psu1_eeprom / psu2_eeprom – for the power supply unit (PSU) eeproms

  * port1, port2, ... port52 – for the SFP+/QSFP eeproms

* For PCA95xx I2C muxes, use the "deselect-on-exit" property.
* I2C nodes use the "fsl,preserve-clocking" property.

ONIE Kernel
-----------

* Inspect the boot log and ``dmesg`` output, looking for any errors or
  anything unusual.
* Inspect ``cat /proc/interrupts`` – are the expected interrupts
  enabled?
* If the platform has CPLDs, try accessing some registers using the
  ``iorw`` command. Can you read a version register?
* Verify the demo NOS compiles and installs OK.
* If the box has USB ports, plug in a USB stick and see if you can
  mount a partition.
* Verify the ``onie-nos-install <demo NOS installer URL>`` command works from
  rescue mode.
* Verify the ``onie-self-update <ONIE updater URL>`` command works from
  rescue mode.

Machine Configuration: ``machine.make``
---------------------------------------

The ``machine.make`` Makefile fragment defines a number of aspects
about the machine.  Some of the configuration parameters are required,
while others have reasonable defaults.

The required parameters:

.. csv-table:: machine.make required parameters
  :header: "Parameter", "Meaning"
  :delim: |

  ONIE_ARCH | CPU architecture for the machine type: x86_64, armv7a, powerpc-softfloat
  VENDOR_REV | Machine hardware revision. "0" is a good choice for a machine
  SWITCH_ASIC_VENDOR | used to further differentiate the platform in the ONIE waterfall.  This string should be the stock ticker symbol of the ASIC vendor, in lower case.
  VENDOR_ID | Vendor ID -- IANA Private Enterprise Number: http://www.iana.org/assignments/enterprise-numbers

Optional Parameters:

.. csv-table:: machine.make optional parameters
  :header: "Parameter", "Meaning", "Default"
  :delim: |

  FIRMWARE_UPDATE_ENABLE | Build a vendor supplied firmware update | no
  CONSOLE_SPEED | Serial console baud rate | 115200
  SERIAL_CONSOLE_ENABLE | Use serial line for console output, otherwise use VGA | yes
  CONSOLE_DEV | serial TTY instance to use for console | ttyS0
  EXTRA_CMDLINE_LINUX | Extra kernel command line parameters to pass to the ONIE Linux kenrel | none
  RECOVERY_DEFAULT_ENTRY | Default menu option when booting a recovery image (rescue or embed) | rescue
  SKIP_ETHMGMT_MACS | Should ONIE skip programming the Ethernet management interface MAC addresses? | no
  VENDOR_VERSION | Optional string to append to the ONIE version string | empty

Optional Utilities and Features to Include:

.. csv-table:: machine.make optional features
  :header: "Utility / Feature", "Meaning", "Default"
  :delim: |

  MTDUTILS_ENABLE     | MTD flash utilities | yes, for U-Boot platforms
  GPT_ENABLE | GUID Partition Table (GPT) disk partitions | yes
  LVM2_ENABLE | Logical Volume Manager support | yes
  PARTED_ENABLE | parted disk partitioning tool | yes
  GRUB_ENABLE | GRUB boot loader support | yes, for x86_64 platforms
  UEFI_ENABLE     | Build ONIE for a UEFI machine | no
  I2CTOOLS_ENABLE | I2C peek/poke utilites | yes
  DMIDECODE_ENABLE | dmidecode (SMBIOS information) utility | yes, for x86_64 platforms
  ETHTOOL_ENABLE | ethtool utility | yes
  ACPI_ENABLE | Support for ACPI and related utilities | yes, for x86_64 platforms
  KEXEC_ENABLE | kexec utility | yes
  FLASHROM_ENABLE | flashrom BIOS programming utility | yes, for x86_64 platforms
  IPMITOOL_ENABLE | IPMI utility | no

