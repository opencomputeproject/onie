.. Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

*******************
PowerPC Boot Loader
*******************

On PowerPC platforms, U-Boot provides the startup environment for
loading and running the ONIE kernel and the network operation system
(NOS) kernel.

ONIE uses U-Boot for basic services and builds on top of it.

The U-Boot functionality consists of platform dependent
responsibilities as well as platform independent features.

.. note:: The examples throughout this section reference a
  hypothetical machine, called *MACHINE*, manufactured by a hypothetical
  hardware manufacturer, called *VENDOR*.

.. _nor_flash_memory_layout:

NOR Flash Memory Layout
=======================

The typical layout of a 32MB NOR flash for an ONIE system looks like this
(note that this diagram is not to scale)::

  +---------------------------+  High Memory Address
  |   CPU Reset Vector        |
  +---------------------------+
  |                           |
  |   U-Boot Binary           |
  |   Size: 512 KB            |
  |                           |
  +---------------------------+
  |                           |
  |   U-Boot Environment Vars |
  |   Size: 1 flash sector    |
  |                           |
  +---------------------------+
  |                           |
  |   ONIE Kernel + initramfs |
  |   Size: 3 MB              |
  |                           |
  +---------------------------+
  |                           |
  |   HW Diagnostic Image     |
  |   Size: xx MB             |
  |                           |
  +---------------------------+
  |                           |
  |                           |
  |                           |
  /   Unused, left for OS     /
  /   Size: About 28 MB       /
  |                           |
  |                           |
  |                           |
  +---------------------------+  Low Memory Address

.. note:: The hardware diagnostic partition is optional.  It is
          intended to be used by hardware vendors to provide a
          diagnostic image.

Platform-Dependent Hardware Initialization
==========================================

ONIE expects U-Boot to provide a number of services at boot time, including:

* Platform-specific hardware initialization.
* Provide information (in the form of environment variables) to the boot time scripts.

U-Boot is responsible for initializing the following devices for the operating system:

===================   ========
Device                Comments
===================   ========
System Fans	      Set system idle fan speed to 100%. The switching ASIC is not running.
Ethernet Management   Initialize the PHY and network devices for possible DHCP/TFTP downloads.
Front Panel LEDs      Set front panel system status LEDs to a known state.
PCIe root complex     Initialize PCIe root complex corresponding to the switching ASIC.
===================   ========

In addition, U-Boot is responsible for setting up a number of environment variables.

Information that is the same for all machines can be compiled into U-Boot itself. For
example, the NOR flash offset of where ONIE resides.

On the other hand, information that is unique for every device, like serial number or MAC 
address, should reside in non-volatile storage, such as an EEPROM or NOR flash.

See :ref:`non_volatile_board_info` for more information.

The following variables must be set by the U-Boot platform:

.. _u_boot_platform_vars:

.. csv-table::  Platform-Dependent Environment Variables
   :header: "Variable", "Use / Meaning", "Example", "Compiled In or Non-Volatile Storage"

    ``consoledev``, The primary serial console port, ``ttyS0``, compiled in
    ``onie_start``, The starting address, ``0xefb60000``, compiled in
    ``onie_sz.b``, Size of the ONIE kernel uImage region, ``0x00400000``, compiled in
    ``platform``, Identifying string of the form "``<vendor>_<machine>-r<machine_revision>``", ``vendor_machine-r0``, non-volatile storage
    ``vendor_id``, 32-bit IANA Private Enterprise Number in decimal, ``12345``, non-volatile storage
    ``serial#``, Device serial number, ``XZY00123``, non-volatile storage
    ``eth_addr``, MAC address for Ethernet management port, ``00:11:22:33:44:55``, non-volatile storage

Environment Variables: ``consoledev, oniestart and oniesz.b``
-------------------------------------------------------------

These variables are compiled into U-Boot using the platform's U-Boot
configuration header file ``include/configs/VENDOR_MACHINE.h``.

The definition of the CONFIG_PLATFORM_ENV macro would look like:

.. code-block:: c

  #define CONFIG_PLATFORM_ENV       \
          "consoledev=ttyS0\0"      \
          "onie_start=0xefb60000\0" \
          "onie_sz.b=0x00400000\0"

Environment Variables: ``platform`` and ``vendor_id``
-----------------------------------------------------

These variables are compiled into U-Boot using the platform's U-Boot
configuration header file ``include/configs/VENDOR_MACHINE.h``.

Calling the ``CONFIG_ONIE_COMMON_UBOOT_ENV`` macro adds these variable
to the default environment.

In this example, the ``vendor_id`` is "12345" and the ``platform`` is
"vendor_model".  This would look like:

.. code-block:: c

  #define CONFIG_EXTRA_ENV_SETTINGS                  \
          CONFIG_PLATFORM_ENV                        \
          CONFIG_ONIE_COMMON_UBOOT_ENV(12345,        \
                                       vendor_model)

Environment Variable: ``serial#``
---------------------------------

The serial number must reside in non-volatile storage, such as an EEPROM or a NOR 
flash sector dedicated to storing manufacturing data. You **must not** store the 
serial number in a U-Boot environment variable as the U-Boot environment is reset 
to defaults during provisioning and re-provisioning.

The platform must provide an implementation for the
``populate_serial_number()`` function , which U-Boot calls during
board initialization.  This function retrieves the serial number from
non-volatile storage and sets the U-Boot environment variable ``serial#``.

An example implementation looks like:

.. code-block:: c

  /**
   * populate_serial_number - read the serial number from EEPROM
   *
   * This function reads the serial number from the EEPROM and sets the
   * appropriate environment variable.
   *
   * The environment variable is only set if it has not been set
   * already.  This ensures that any user-saved variables are never
   * overwritten.
   *
   */
  int populate_serial_number(void)
  {
          if (getenv("serial#"))
                  return 0;
          if (read_eeprom()) {
                  printf("Read failed.\n");
                  return -1;
          }
          setenv("serial#", (char *)e.serial_number);
          return 0;
  }

Environment Variable: ``eth_addr``
----------------------------------

The MAC address for the Ethernet management interface must reside in
non-volatile storage, such as an EEPROM or a NOR flash sector
dedicated to storing manufacturing data.  You **must not**
store the MAC address in a U-Boot environment variable as the U-Boot
environment is reset to defaults during provisioning and re-provisioning.

The platform must provide an implementation for the
``mac_read_from_eeprom()`` function , which U-Boot calls during board
initialization.  This function retrieves the serial number from
non-volatile storage and sets the U-Boot environment variable
``eth_addr``.

An example implementation looks like:

.. code-block:: c

  /**
   * mac_read_from_eeprom - read the MAC addresses from EEPROM
   *
   * This function reads the MAC addresses from EEPROM and sets the
   * appropriate environment variables for each one read.
   *
   * The environment variables are only set if they haven't been set already.
   * This ensures that any user-saved variables are never overwritten.
   *
   * This function must be called after relocation.
   */
  int mac_read_from_eeprom(void)
  {
          u32 csum;
          u8 *p;
          char ethaddr[18];
   
          if (read_eeprom()) {
                  printf("Read failed.\n");
                  return -1;
          }
          csum = calc_2s_comp((void *)&e, sizeof(e));
          if (csum != e.csum) {
                  printf("CRC mismatch (%02X != %02X)\n", csum, e.csum);
                  return -1;
          }
          p = &e.start_mac[0];
          sprintf(ethaddr, "%02x:%02x:%02x:%02x:%02x:%02x", p[0], p[1],
                  p[2], p[3], p[4], p[5]);
                  ethaddr[17] = '\0';
          /* Only initialize environment variables that are blank
           * (i.e. have not yet been set)
           */
          if (!getenv("ethaddr"))
                  setenv("ethaddr", ethaddr);
   
    return 0;
  }

Platform-Independent U-Boot Features
====================================

ONIE-powerpc relies on two fundamental features of U-Boot:

* Reading and writing the NOR boot flash.
* Reading and writing U-Boot environment variables.

The ONIE kernel and ``initramfs`` reside in the NOR boot flash, which
is why ONIE relies on U-Boot's NOR flash I/O.

What's more interesting is the use of U-Boot environment variables in
an ONIE-enabled system, as described in the next section.

.. _platform_ind_vars:

Platform-Independent Environment Variables
------------------------------------------

ONIE uses a number of different U-Boot variables to manage the system.

The most important environment variable is ``bootcmd``, which U-Boot
executes during every boot.  ONIE is the sole owner of this variable.
An NOS should **never** use this variable directly in an ONIE-enabled
system.  ONIE provides other variables an NOS can use to control its
boot process.

The second most important variable is ``bootargs``, which U-Boot adds to
the kernel command line when booting a kernel.

ONIE defines and uses the following U-Boot variables:

.. csv-table:: Platform-Independent Environment Variables
  :header: "Variable Name", "Default Value", "Use / Meaning"
  :widths: 1, 1, 2
  :delim: %

  ``bootcmd`` % "::

    run check_boot_reason;
    run nos_bootcmd;
    run onie_bootcmd
  "% "
  Called by U-Boot every boot. Configured at ONIE compile time and
  never touched again."

  ``check_boot_reason`` % "::

    if test -n $onie_boot_reason; then
      setenv onie_bootargs boot_reason=$onie_boot_reason;
      run onie_bootcmd;
    fi;
  "% "
  Called by ``bootcmd`` every boot. Checks the ``onie_boot_reason`` variable
  and, if set, U-Boot loads the ONIE kernel with the contents of
  ``$onie_boot_reason`` added to the kernel command line arguments."

  ``onie_boot_reason`` % "[Not Set]"% "
  See ``check_boot_reason above``. The current reboot commands understood
  by ONIE are:

    #. ``install`` – Boot ONIE and rerun the ODE application.
    #. ``uninstall`` – Boot ONIE in uninstall mode, which erases
       everything from the system, except U-Boot and ONIE.
    #. ``rescue`` – Boot ONIE in rescue mode for debug purposes.
    #. ``update`` – Boot ONIE in ONIE self-update mode, which looks for and
       installs a new version of ONIE.
  "

  ``nos_bootcmd`` % [Not Set]% "This is the variable an NOS vendor sets
  to control their boot process. When set, it is expected that the NOS
  vendor's init loads an NOS and does not return. If the NOS vendor init
  fails or returns for whatever reason, execution falls through to
  loading ONIE."

  ``onie_bootcmd`` % "::

    echo Loading Open Network Install Environment ...;
    echo Version: $onie_version ;
    cp.b $onie_start $loadaddr ${onie_sz.b} &&
      run onie_args && bootm ${loadaddr}#$platform
  "% "Only called by U-Boot when the ``nos_bootcmd`` init script
  returns. This is the case on a bare metal machine fresh from the
  factory."

  ``onie_args`` % ``run onie_initargs onie_platformargs`` % "Sets up
  kernel command line arguments when booting into ONIE."

  ``onie_initargs`` % ``setenv bootargs quiet console=$consoledev,$baudrate`` % "
  Minimal set of kernel command line arguments necessary to boot a kernel."

  ``onie_platformargs`` % "::

    setenv bootargs $bootargs serial_num=${serial#}
      eth_addr=$ethaddr vendor_id=$vendor_id
      platform=$platform $onie_bootargs $onie_debugargs
  "% "Appends additional, platform-specific variables to the kernel
  command line when booting ONIE."

  ``onie_bootargs`` % [Not Set]% "Used by ``check_boot_reason`` to pass
  additional kernel arguments when booting ONIE."

  ``onie_debugargs`` % [Not Set]% "For development and debug use to pass
  additional kernel arguments when booting ONIE."

 
