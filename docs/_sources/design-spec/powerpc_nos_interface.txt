*************************
PowerPC Interface Details
*************************

This section describes the PowerPC specific methods used to implement
the NOS interface.  See the :ref:`nos_interface` section for more
about the NOS interface.

PowerPC Adding Kernel Command Arguments
---------------------------------------

In the case of U-Boot and Linux the user can set additional kernel
command line arguments by setting the ``onie_debugargs`` U-Boot
environment variable.

The ``install_url`` kernel command line argument can be used to boot
into ONIE and automatically use the URL as an install URL.  For
example::

  => setenv onie_debugargs 'install_url=http://10.0.1.249/nos_installer.bin'
  => run onie_bootcmd

PowerPC NOS Interface
---------------------

On PowerPC ONIE communicates with the NOS via U-Boot environment
variables.  Both ONIE and the NOS must be able to read and write
U-Boot environment variables.  See the :ref:`nos_interface` section
for more about the NOS interface.

.. _powerpc_nos_intf_installer:

PowerPC NOS Installer
=====================

The only requirement ONIE has for the NOS installer is that the NOS
**must** update the ``nos_bootcmd`` U-Boot environment variable
described in :ref:`platform_ind_vars`. This signals U-Boot to load the
NOS on subsequent boots, bypassing ONIE.

What goes into the ``nos_bootcmd`` is entirely up to the NOS vendor, but
generally it will contain commands to load and boot the NOS image from
NOR flash or from an SD card.

See the :ref:`nos_intf_installer` section for more about the NOS
installer interface.

.. _powerpc_nos_intf_reinstaller:

PowerPC Reinstalling or Installing a Different NOS
==================================================

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

.. _powerpc_nos_intf_uninstall:

PowerPC NOS Uninstall
=====================

ONIE has an uninstall operation that wipes out the unused portions of
NOR flash and the attached mass storage device (like an SD card or USB NAND
flash). The only thing untouched is ONIE itself. This is a
"reset to factory defaults"-like operation.

To invoke the uninstall operation, the running NOS sets the
``onie_boot_reason`` U-Boot environment variable to the value
``uninstall`` (see :ref:`platform_ind_vars`), and then reboots the
system.  When the system starts up again ONIE, will see the
``onie_boot_reason`` and start the uninstall process.

Following the uninstall process, the system returns to the
discovery and installation phase.

.. note::

  From the U-Boot prompt you can also boot ONIE into the uninstall
  mode by typing::

    => run onie_uninstall

See the :ref:`nos_intf_uninstall` section for more about the NOS
uninstall interface.

.. _powerpc_nos_intf_rescue:

PowerPC Rescue and Recovery
===========================

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

.. _powerpc_nos_intf_update:

PowerPC Updating and Embedding ONIE
===================================

On PowerPC only the ``update`` operation is supported, i.e. ``update``
and ``embed`` do the same thing.  The ``update`` operation is **not**
descructive to the currently installed NOS.

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
