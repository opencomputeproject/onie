.. Copyright (C) 2013,2014,2018 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2013-2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. _nos_interface:

**********************************
Network Operating System Interface
**********************************

ONIE provides an environment for a network operating system (NOS) to perform 
system provisioning and maintainance operations, including:

- Installing the NOS into the hardware
- Reinstalling a different NOS
- Uninstalling the current NOS
- Embeding ONIE (wipes out everything, leaving only the new ONIE)
- Updating ONIE (updates the current ONIE with a new version)
- Rescue and recovery

This environment forms an interface between ONIE and the NOS.

.. _nos_intf_installer:

NOS Installer
=============

ONIE puts a small number of requirements on the NOS installer.

First, the installer **must** update the boot environment so that the
NOS boots at the next reboot.

How this is done depends on the specific CPU architecture.  See these
sections for the corresponding CPU architectures:

- :ref:`uboot_nos_intf_installer`

- :ref:`x86_nos_intf_installer`

Second, at the conclusion of a successful NOS install, the install
*should* call ``onie-nos-mode -s``.  This allows ONIE to be more "user
friendly" on subsequent boots.  See :ref:`cli_onie_nos_mode`.

Other than that, the NOS installer can do whatever is necessary to
persistently install the operating system into the hardware; the
installer has a lot of flexibility.

Some examples of what an installer could do:

- Fetch additional binaries and configuration files via HTTP
- Chat with inventory control systems via HTTP
- Download a new kernel+initramfs and `kexec(8)
  <http://linux.die.net/man/8/kexec>`_ into it

.. _cmd_onie_sysinfo:

System Information
------------------

Within the running ONIE context, an installer often needs to know
various information about the running system.  ONIE provides the
``onie-sysinfo`` command for this purpose.

For details, here is the complete help for ``onie-sysinfo`` follows::

  ONIE:/ # onie-sysinfo -h
  onie-sysinfo [-sevimrpcfdat]
  Dump ONIE system information.
   
  COMMAND LINE OPTIONS
   
          The default is to dump the ONIE platform (-p).
   
          -h
                  Help.  Print this message.
   
          -s
                  Serial Number
   
          -e
                  Management Ethernet MAC address
   
          -v
                  ONIE version string
   
          -i
                  ONIE vendor ID.  Print the ONIE vendor's IANA enterprise number.
   
          -m
                  ONIE machine string
   
          -r
                  ONIE machine revision string
   
          -p
                  ONIE platform string.  This is the default.
   
          -c
                  ONIE CPU architecture
   
          -f
                  ONIE configuration version
   
          -d
                  ONIE build date
   
          -t
                  ONIE partition type
   
          -S
                  ONIE silicon switch vendor
  
          -a
                  Dump all information.


.. _nos_intf_reinstaller:

Reinstalling or Installing a Different NOS
==========================================

From the running NOS, it is possible to instruct ONIE to return to the
initial discovery and installation phase.  This could be used to
reinstall the current NOS or to install a different NOS.

How to invoke the install operation depends on the specific CPU
architecture.  See these sections for the corresponding CPU
architectures:

- :ref:`uboot_nos_intf_reinstaller`

- :ref:`x86_nos_intf_reinstaller`

.. _nos_intf_uninstall:

NOS Uninstall
=============

ONIE has an uninstall operation that wipes out the unused portions of
the attached mass storage devices (like an mSATA card or USB NAND
flash). The only thing untouched is ONIE itself.  This is a
"reset to factory defaults"-like operation.

How to invoke the uninstall operation depends on the specific CPU
architecture.  See these sections for the corresponding CPU
architectures:

- :ref:`uboot_nos_intf_uninstall`

- :ref:`x86_nos_intf_uninstall`

Following the uninstall process, the system returns to the discovery
and installation phase.

.. _nos_intf_rescue:

Rescue and Recovery
===================

ONIE provides a rescue and recovery mode, which is useful mostly during
development, but is potentially useful when trying to recover a broken
system.

The rescue mode is the same as the discovery and installation phase,
but the discovery mechanism is disabled.  ONIE does **not** try to
locate and install an image; it simply sits there allowing you to
troubleshoot the system.

In this mode you can connect to ONIE via the serial console or via
telnet.  You can use the available BusyBox tools to try and fix a
problem.  Or use `wget <http://linux.die.net/man/1/wget>`_ to download
more tools and files.

A few useful commands included with ONIE are:

- ``onie-nos-install`` -- It takes one argument, a URL to a NOS installer.  This
  command downloads and installs from the URL, just as if it had been
  *discovered*.

- ``onie-self-update`` -- It takes a URL to an ONIE updater image.
  This command downloads and runs the updater, just as if it had been
  *discovered*.  See the :ref:`updating_onie` section for more about
  updating ONIE.

- ``onie-discovery-stop`` -- Stop the discovery process.  This can be
  useful in debugging cases where the discovery process is interfering
  with the debug.  With the discovery process disabled the system is
  quiet and you can poke around.

How to invoke the rescue operation depends on the specific CPU
architecture.  See these sections for the corresponding CPU
architectures:

- :ref:`uboot_nos_intf_rescue`

- :ref:`x86_nos_intf_rescue`

.. _nos_intf_update:

Updating and Embedding ONIE
===========================

ONIE provides a way to update itself, including the boot loader and
Linux kernel.  In many ways, this behaves similarly to the discovery
and installation phase, except that ONIE is looking for a different
kind of image.  

The update operation comes in two flavors: ``update`` and ``embed``.

The ``update`` operation will upgrade ONIE and is **not** destructive
to the currently installed NOS.

The ``embed`` operation, on the other hand, is **destructive**.  This
operation will wipe out everything (including any installed NOS) and
install a new version of ONIE.

.. note:: At this time, the ``embed`` operation is available only on the x86
   platform.

For more details on the ``update`` and ``embed`` operations see
:ref:`x86_nos_intf_update` and :ref:`uboot_nos_intf_update` for the
corresponding CPU architectures.

See the :ref:`updating_onie` section for more about updating ONIE.

How to invoke the ``update`` and ``embed`` operations depends on the
specific CPU architecture.  See these sections for the corresponding
CPU architectures:

- :ref:`uboot_nos_intf_update`

- :ref:`x86_nos_intf_update`
