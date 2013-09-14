.. _nos_interface:

**********************************
Network Operating System Interface
**********************************

ONIE provides an environment for a network operating system (NOS) to perform 
system provisioning and maintainance operations, including:

- Installing the NOS into the hardware
- Reinstalling a different NOS
- Uninstalling, i.e. wiping the system clean
- Rescue and recovery
- Updating ONIE

This environment forms an interface between ONIE and the NOS.

U-Boot environment variables to communicate are the communication
channel between ONIE and the NOS.  Both ONIE and the NOS must be able
to read and write U-Boot environment variables.

NOS Installer
=============

ONIE makes no requirements on the NOS installer save for one: The NOS
**must** update the ``nos_bootcmd`` U-Boot environment variable
described in :ref:`platform_ind_vars`.  This is the signal telling
U-Boot to load the NOS on subsequent boots, bypassing ONIE.

What goes into the ``nos_bootcmd`` is entirely up to the NOS, but
generally it will contain commands to load and boot the NOS image from
NOR flash or from an SD-card.

Other than that the NOS installer is free to do whatever is necessary
to persistently install the operating system into the hardware.  The
install has a lot of flexibility.

Some examples of what an installer could do:

- Fetch additional binaries and configuration files via HTTP
- Chat with inventory control systems via HTTP
- Download a new kernel+initramfs and `kexec(8)
  <http://linux.die.net/man/8/kexec>`_ into it

Reinstall / Install a Different NOS
===================================

From the running NOS it is possible to instruct ONIE to go back to the
initial discovery and installation phase.  This could be used to
re-install the current NOS or to install a different NOS.

To invoke the install operation the running NOS sets the
``onie_boot_reason`` U-Boot environment variable to the value
``install`` (see :ref:`platform_ind_vars`) and then reboots the
system.  When the system starts up again ONIE will see the
``onie_boot_reason`` and restart the discovery and installation phase.

.. note::

  From the U-Boot prompt you can also boot ONIE into the discovery and
  installation phase by typing::

    => run onie_bootcmd

Uninstall
=========

ONIE has an uninstall operation that wipes out the unused portions of
NOR flash and the attached mass storage device (SD-card, USB NAND
flash, etc).  The only thing untouched is ONIE itself.  This is a
"reset to factory defaults" operation.

To invoke the install operation the running NOS sets the
``onie_boot_reason`` U-Boot environment variable to the value
``uninstall`` (see :ref:`platform_ind_vars`) and then reboots the
system.  When the system starts up again ONIE will see the
``onie_boot_reason`` and start the uninstall process.

Following the uninstall process the system will return to the
discovery and installation phase.

.. note::

  From the U-Boot prompt you can also boot ONIE into the uninstall
  mode by typing::

    => run onie_uninstall

.. _rescue_recovery:

Rescue and Recovery
===================

ONIE provides a rescue and recovery mode, mostly useful during
development, but potentially useful when trying to recover a broken
system.

The rescue mode is the same as the discovery and installation phase,
but with the discovery mechanism disabled.  ONIE is **not** trying to
locate and install an image.  It simply sits there allowing you to
poke around the system.

In this mode you can attach to ONIE via the serial console or via
telnet.  You can use the available busybox tools to try and fix a
problem.  Or use `wget <http://linux.die.net/man/1/wget>`_ to download
more tools and files.

Two useful commands included with ONIE are:

- install_url -- Takes one argument, a URL to a NOS installer.  This
  command downloads and installs the URL, just as if it had been
  *discovered*.

- update_url -- Takes one argument, a URL to an ONIE updater.  This
  command downloads and runs the updater, just as if it had been
  *discovered*.  See the :ref:`updating_onie` section for more about
  updating ONIE.

To invoke the rescue operation the running NOS sets the
``onie_boot_reason`` U-Boot environment variable to the value
``rescue`` (see :ref:`platform_ind_vars`) and then reboots the
system.  When the system starts up again ONIE will see the
``onie_boot_reason`` and enter rescue mode.

.. note::

  From the U-Boot prompt you can also boot ONIE into rescue mode by
  typing::

    => run onie_rescue

.. _nos_intf_updating_onie:

Updating ONIE
=============

ONIE provides a way to update itself, including the boot loader and
Linux kernel.  In many ways this behaves similarly to the discovery
and installation phase, except that ONIE is looking for a different
kind of image.  

See the :ref:`updating_onie` section for more about updating ONIE.

To invoke the ONIE update operation the running NOS sets the
``onie_boot_reason`` U-Boot environment variable to the value
``update`` (see :ref:`platform_ind_vars`) and then reboots the
system.  When the system starts up again ONIE will see the
``onie_boot_reason`` and enter ONIE self-update mode.

.. note::

  From the U-Boot prompt you can also boot ONIE into ONIE self-update mode by
  typing::

    => run onie_update
