.. Copyright (C) 2014,2015,2016,2017 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

*************************************
U-Boot Platform NOS Interface Details
*************************************

This section describes the U-Boot platform specific methods used to implement
the NOS interface.  See the :ref:`nos_interface` section for more
about the NOS interface.

U-Boot platform Adding Kernel Command Arguments
-----------------------------------------------

In the case of U-Boot and Linux, the user can set additional kernel
command line arguments by setting the ``onie_debugargs`` U-Boot
environment variable.

The ``install_url`` kernel command line argument can be used to boot
into ONIE and automatically use the URL as an install URL.  For
example::

  => setenv onie_debugargs 'install_url=http://10.0.1.249/nos_installer.bin'
  => run onie_bootcmd

U-Boot platform NOS Interface
-----------------------------

On U-Boot platforms, ONIE communicates with the NOS via U-Boot
environment variables.  Both ONIE and the NOS must be able to read and
write U-Boot environment variables.  See the :ref:`nos_interface`
section for more about the NOS interface.

.. _uboot_nos_intf_installer:

U-Boot platform NOS Installer
=============================

The only requirement ONIE has for the NOS installer is that the NOS
**must** update the ``nos_bootcmd`` U-Boot environment variable
described in :ref:`platform_ind_vars`. This signals U-Boot to load the
NOS on subsequent boots, bypassing ONIE.

What goes into the ``nos_bootcmd`` is entirely up to the NOS vendor, but
generally it will contain commands to load and boot the NOS image from
NOR flash or from an SD card.

See the :ref:`nos_intf_installer` section for more about the NOS
installer interface.

.. _uboot_nos_intf_reinstaller:

U-Boot platform Reinstalling or Installing a Different NOS
==========================================================

To invoke the install operation, the running NOS sets the
``onie_boot_reason`` U-Boot environment variable to the value
``install`` (see :ref:`platform_ind_vars`), and then reboots the
system.  When the system starts up again, ONIE will see the
``onie_boot_reason`` and restart the discovery and installation phase.

.. note::

  From the U-Boot prompt, you can also boot ONIE into the discovery and
  installation phase by typing::

    => run onie_bootcmd

See the :ref:`nos_intf_reinstaller` section for more about the NOS
reinstaller interface.

.. _uboot_nos_intf_uninstall:

U-Boot platform NOS Uninstall
=============================

ONIE has an uninstall operation that wipes out the unused portions of
NOR flash and the attached mass storage device (like an SD card or USB NAND
flash). The only thing untouched is ONIE itself. This is a
"reset to factory defaults"-like operation.

To invoke the uninstall operation, the running NOS sets the
``onie_boot_reason`` U-Boot environment variable to the value
``uninstall`` (see :ref:`platform_ind_vars`), and then reboots the
system.  When the system starts up again, ONIE will see the
``onie_boot_reason`` and start the uninstall process.

Following the uninstall process, the system returns to the
discovery and installation phase.

.. note::

  From the U-Boot prompt you can also boot ONIE into the uninstall
  mode by typing::

    => run onie_uninstall

See the :ref:`nos_intf_uninstall` section for more about the NOS
uninstall interface.

.. _uboot_nos_intf_rescue:

U-Boot platform Rescue and Recovery
===================================

To invoke the rescue operation, the running NOS sets the ``onie_boot_reason`` 
U-Boot environment variable to the value ``rescue`` 
(see :ref:`platform_ind_vars`), and then reboots the system.  When the system 
starts up again, ONIE will see the ``onie_boot_reason`` and enter rescue mode.

.. note::

  From the U-Boot prompt you can also boot ONIE into rescue mode by
  typing::

    => run onie_rescue

See the :ref:`nos_intf_rescue` section for more about the NOS rescue
interface.

.. _uboot_nos_intf_update:

U-Boot platform Updating and Embedding ONIE
===========================================

On U-Boot platforms, only the ``update`` operation is supported; there
is no ``embed`` command for U-Boot platforms.  The ``update``
operation is **not** descructive to the currently installed NOS.

The update operation installs a new version of ONIE in the NOR flash,
including:

- An updated U-Boot image

- An updated ONIE kernel and initramfs

To invoke the ONIE update operation, the running NOS sets the
``onie_boot_reason`` U-Boot environment variable to the value
``update`` (see :ref:`platform_ind_vars`), and then reboots the
system.  When the system starts up again, ONIE will see the
``onie_boot_reason`` and enter ONIE self-update mode.

.. note::

  From the U-Boot prompt you can also boot ONIE into ONIE self-update mode by
  typing::

    => run onie_update

See the :ref:`nos_intf_update` section for more about the NOS update
interface.

.. _uboot_hw_diag:

U-Boot Platform Hardware Diagnostics Interface [Optional]
---------------------------------------------------------

This section describes a method for providing a hardware diagnostic
for U-Boot platforms.  See the :ref:`hw_diag` section for more about
providing a hardware diagnostic.

The preferred storage location for the hardware diagnostic image is in
a NOR flash partition.  See the :ref:`nor_flash_partition` section for
more information on the NOR flash partitioning.

The diag image is located in the NOR flash in a specific ``diag``
partition.  This allows the NOS installer to clearly identify the
partition and avoid overwriting it.

In order to boot the diagnostic image, the implementation must create
a new U-Boot environment variable called ``boot_diag``.  This variable
contains all the U-Boot commands necessary to load and boot the
diagnostic image.

To invoke the diagnostic image the user would type ``run boot_diag``
from the U-Boot loader prompt.
