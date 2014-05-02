********************************
x86 Linux Kernel and Integration
********************************

Most x86 platforms will "just work" with the stock ONIE x86 kernel,
but some platform specific modifications may be necessary.

Kernel Modifications
====================

To add support to the kernel for a particular platform, the following
Linux kernel files must be created or modified:

======================================================       =======
File                                                         Purpose
======================================================       =======
``linux/drivers/platform/x86/vendor_machine.c``              Platform support C file. Basic initialization and reset.
``linux/drivers/platform/x86/Kconfig``                       Kernel configuration fragment that allows 
                                                             the new platform to be selected.
``linux/drivers/platform/x86/Makefile``                      Makefile fragment detailing what C file to 
                                                             compile when the platform is selected.
======================================================       =======

What needs to go into the platform specific kernel files varies from
platform to platform.  Some common reasons for adding platform
specific kernel code:

- Special reset sequence.  Perhaps requiring access to a specific
  CPLD.

- Mapping GPIO lines to specific things, like i2c muxes or front panel
  LEDs.

The resulting stg kernel patches are stored in the ``$MACHINE/kernel``
directory.  Patches placed here will automatically be applied by the
build system.

See the :ref:`creating_stg_patches` section for information about how
to create stg patches.

Board EEPROM Access -- onie-syseeprom
=====================================

On x86 platforms the ``onie-syseeprom`` is used to access the board
EEPROM.  The syntax of the command follows::

  ONIE:/ # onie-syseeprom -h
  Display and program the system EEPROM data block.
  Usage: sys-eeprom [-h][-l] [-e] [-s <code>=<value>,...]
     With no arguments display the EEPROM contents.
     -h --help
        Display usage
     -l --list
        List the understood TLV codes and names.
     -e --erase
        Reset the EEPROM data.
     -g --get <code>
        Look up a TLV by code and write the value to stdout.
     -s --set <code>=<value>,<code>=<value>...
        Set a TLV code to a value.
        If no value, TLV is deleted.

See the :ref:`non_volatile_board_info` section for more about the
format of the EEPROM data and available TLV fields.

In order for the tool to work, however, each platform must define how
to access its EEPROM.  At a minimum each platform must define the
following in sys_eeprom_platform.h::

  SYS_EEPROM_SIZE       : size of usable eeprom
  SYS_EEPROM_I2C_DEVICE : i2c-bus
  SYS_EEPROM_I2C_ADDR   : address on the bus

The following may also be defined in sys_eeprom_platform.h, else
the defaults will take over::

  SYS_EEPROM_MAX_SIZE : Total size of the eeprom
  SYS_EEPROM_OFFSET   : offset from where the ONIE TLV header starts

See the ``onie-syseeprom`` patch for details,
``onie/patches/i2ctools/i2ctools-sys-eeprom.patch``.

On the x86 architecture the ``onie-sysinfo`` command uses the
``onie-syseeprom`` command to generate parts of its output.  See the
:ref:`cmd_onie_sysinfo` section for more about the ``onie-sysinfo``
command.

See the :ref:`creating_stg_patches` section for information about how
to create stg patches.
