.. Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. _demo_os:

********************************
Demo OS Installer and OS Runtime
********************************

The demo OS installer and runtime illustrate a number of ONIE
concepts, useful for OS vendors creating their own ONIE-compatible
installers:

*  How to make an installer compatible with ONIE.
*  The tools and environment available to an installer at runtime.
*  How the OS can invoke ONIE services, like reinstall, uninstall
   rescue, update and embed.

.. note:: The ONIE binary must previously be installed on the machine.
   See the ``INSTALL`` file for details.

.. _demo_building:

Building the Demo Installer
---------------------------

To compile the demo installer, first change directories to ``build-config`` 
and then type ``make MACHINE=<platform> demo``, specifying the target machine.
For example::

  $ cd build-config
  $ make -j4 MACHINE=<platform> demo

When compilation finishes, the demo installer is located in
``build/images/demo-installer-<platform>.bin``.

Using the Installer with ONIE
-----------------------------

The installer needs to be located where the ONIE discovery mechanisms
can find it.  See :ref:`user_guide` for more on the discovery
mechanisms and usage models.

For a quick lab demo, the IPv6 neighbor discovery method is described
next.

.. note:: The build host and network switch must be on the same network
   for this to work.  For example, the switch's Ethernet management port
   and the build host should be on the same IP subnet.  Directly
   attaching the build host to the network switch also works.

Installing and Setting Up an HTTP Server on Your Build Host
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Assume the root of the HTTP server is ``/var/www``.

Copy the demo installer to the HTTP server root, using the name
``onie-installer-<platform>-<arch>``::

  $ cp build/images/demo-installer-<platform>.bin /var/www/onie-installer-<platform>-<arch>

Currently the only supported ``<arch>`` are ``powerpc`` and ``x86_64``.

Powering on the Network Switch
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When the switch powers up, ONIE will run and attempt to find an installer.  
One of the methods is to look for a file named
``onie-installer-<platform>-<arch>`` on all of the switch's IPv6 neighbors.

Using the Freescale P2020RDB-PCA reference platform as an example, the
default installer name would be::

  onie-installer-fsl_p2020rdbpca-powerpc

1.  Connect to the serial console of the network switch.
2.  Power cycle the machine.

The serial console output should now look like::

  U-Boot 2013.01.01-g65a5657 (May 09 2013 - 10:43:49)

  CPU0:  P2020E, Version: 2.1, (0x80ea0021)
  Core:  E500, Version: 5.1, (0x80211051)
  Clock Configuration:
         CPU0:1000.050 MHz, CPU1:1000.050 MHz, 
  ...
  Loading Open Network Install Environment ...
  Version: 0.0.1-429376a-20130509-NB
  ...

ONIE will find the demo installer and run it.  After that, the machine
will reboot into the demo OS.

Demo Network Operating System
-----------------------------

After the install, the system will reboot and you should see something
like::

  Welcome to the <platform> platform.
   
  Please press Enter to activate this console. 

Press the Enter key to get a root prompt on the machine.  You should see
something like::

  Welcome to the xyz_123 platform.
  PLATFORM-OS:/ # 

The example OS is running BusyBox, so feel free to look around.

.. _demo_nos_reinstall:

Re-installing or Installing a Different OS
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you want to install a new operating system, you can re-run the ONIE
installation process.  The demo NOS has a command to do just that::

  PLATFORM-OS:/ # install
  
This command will reboot the machine and the ONIE install process will
run again.  You would do this, for example, when you want to change
operating systems.

.. warning::  This is a destructive operation.

.. _demo_nos_uninstall:

Uninstalling to Wipe the Machine Clean
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you want to wipe the machine clean, removing all of the operating
system, use the ``uninstall`` command::

  PLATFORM-OS:/ # uninstall
  
This command will reboot the machine and ONIE will erase the available
NOR flash and mass storage devices.

.. warning:: This is a destructive operation.

.. _demo_nos_rescue:

Rescue Boot
^^^^^^^^^^^

ONIE has a rescue boot mode, where you can boot into the ONIE
environment and troubleshoot. The discovery and installer mechanisms
do not run while in rescue mode::

  PLATFORM-OS:/ # rescue
  
This command will reboot the machine and ONIE will enter rescue mode.

.. _demo_nos_update:

Updating ONIE
^^^^^^^^^^^^^

If you want to upgrade the ONIE version on the system, use the
``update`` command.  This will restart the machine in ONIE update
mode::

  PLATFORM-OS:/ # update

See :ref:`updating_onie` for more details on this mode.

Demo Source Code Layout
-----------------------

The demo installer and OS source code is laid out as follows::

  onie/demo
  ├── installer
  │   ├── install.sh
  │   └── sharch_body.sh
  └── os
      ├── default
      │   ├── bin
      │   │   ├── install
      │   │   ├── rescue
      │   │   ├── uninstall
      │   │   └── update
      │   └── etc
      │       ├── init.d
      │       │   └── demo.sh
      │       ├── profile
      │       └── rc3.d
      │           └── S99demo.sh -> ../init.d/demo.sh
      └── install

====================  =======
Directory             Purpose
====================  =======
installer             Files used for making the installer.
os/default            Files copied into the final sysroot image.
os/install            The installer.
====================  =======

A machine-specific configuration file is also required::

  machine/<platform>/demo/platform.conf

This contains instructions specific to the machine needed by the
installer.

To understand how the self-extracting installer image is generated see
these source files::

  build-config/make/demo.make
  build-config/scripts/mkdemo.sh
