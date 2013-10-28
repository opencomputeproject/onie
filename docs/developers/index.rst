.. role:: red
.. role:: green
.. raw:: html

    <style>
         .red   {color:red; font-weight: bold}
         .green {color:green; font-weight: bold}
    </style>

***********************
Developer Documentation
***********************

ONIE Build Instructions
=======================

Machine Definition Files
------------------------

In order to compile ONIE for a particular platform, you need the
platform's machine definition, located in ``$ONIE_ROOT/machine/<platform>``.

If you received a machine definition tarball separately, you must first
untar it in the ``$ONIE_ROOT`` directory.  For example::

  $ cd onie
  $ tar xJf /path/to/tarball/onie-<platform>.tar.xz

See the README file in ``machine/<platform>`` for additional information
about a particular platform.

Preparing a New Build Machine
-----------------------------

To prepare a new build machine for compiling, ONIE must first install a
number of standard development packages.

For a `Debian-based system <http://www.debian.org/>`_, a Makefile
target exists that installs the required packages on your build
machine.  This target requires the use of ``sudo(8)``, since package
installation requires root privileges::

  $ cd build-config
  $ sudo apt-get update
  $ sudo apt-get install build-essential
  $ make debian-prepare-build-host

For a different Linux distribution, look at the Makefile and the
``$(DEBIAN_BUILD_HOST_PACKAGES)`` variable.  Then install packages for
your distribution that provide the same tools.

Optional: Installing the ELDK version 5.3
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Compiling ONIE requires a cross-compiling toolchain.

Compiling ONIE has been qualified using the `ELDK 5.3
<http://www.denx.de/wiki/ELDK-5>`_ ``powerpc-softfloat`` toolchain,
installed into /opt/eldk-5.3 on the build host.

If you want to use a different toolchain, skip this section.

First, read the `ELDK download 
<http://www.denx.de/wiki/view/ELDK-5/WebHome#Section_1.6.>`_ instructions all 
the way through to understand the procedure.

Next, download the following files, maintaining the directory structure::

  $ mkdir eldk-download
  $ cd eldk-download
  $ mkdir -p targets/powerpc-softfloat
  $ wget ftp://ftp.denx.de/pub/eldk/5.3/install.sh
  $ chmod +x ./install.sh
  $ cd targets/powerpc-softfloat
  $ wget ftp://ftp.denx.de/pub/eldk/5.3/targets/powerpc-softfloat/target.conf
  $ wget ftp://ftp.denx.de/pub/eldk/5.3/targets/powerpc-softfloat/eldk-eglibc-i686-powerpc-toolchain-gmae-5.3.sh

Finally, install the toolchain into ``/opt/eldk-5.3``. This requires ``sudo``
root privileges::

  $ cd eldk-download
  $ ./install.sh -s gmae -r - powerpc-softfloat

Cross-Compiling ONIE
--------------------

The primary Makefile, ``build-config/Makefile``, defaults to using the
`ELDK 5.3 <http://www.denx.de/wiki/ELDK-5>`_ ``powerpc-softfloat``
toolchain.  To use a different toolchain, change the following
variables in ``build-config/Makefile``::

  ARCH        ?= powerpc
  TARGET      ?= $(ARCH)-linux
  CROSSBIN    ?= /opt/eldk-5.3/powerpc-softfloat/sysroots/i686-eldk-linux/usr/bin/powerpc-nf-linux

To compile ONIE, first change directories to ``build-config`` and then
type ``make MACHINE=<platform> all``, specifying the target machine.
For example::

  $ cd build-config
  $ make -j4 MACHINE=<platform> all

When complete, the following ONIE binaries are created in the ``build/images``
directory:

.. _onie_build_products:

.. csv-table:: ONIE Build Products
  :header: "File", "Purpose"
  :delim: |

  onie-<platform>-<revision>.bin | Raw binary, suitable for NOR flash programming
  onie-updater-<platform>-<revision> | ONIE updater, for use with the ONIE update mechanism

Installing the ONIE binary
--------------------------

See the INSTALL file in ``machine/<platform>`` for additional information
about how to install the ONIE binary on a particular platform.

ONIE Source Code Description
============================

Source Code Layout
------------------

The ONIE source code layout is as follows::

  onie
  ├── build
  │   └── docs
  │       ├── doctrees
  │       └── html
  ├── build-config
  │   ├── conf
  │   ├── make
  │   └── scripts
  ├── demo
  ├── docs
  ├── installer
  ├── machine
  │   └──<platform> 
  │       ├── demo
  │       ├── kernel
  │       └── u-boot
  ├── patches
  │   ├── busybox
  │   ├── e2fsprogs
  │   ├── kernel
  │   └── u-boot
  ├── rootconf
  │   └── default
  │       ├── bin
  │       ├── etc
  │       │   ├── init.d
  │       │   ├── rc3.d
  │       │   └── rcS.d
  │       ├── root
  │       ├── sbin
  │       └── scripts
  └── upstream

====================  =======
Directory             Purpose
====================  =======
build/docs            The final documentation is placed here.
build-config          Builds are launched from this directory.  The main Makefile is here.
build-config/conf     Contains configurations common to all platforms.
build-config/make     Contains makefile fragments included by the main Makefile.
build-config/scripts  Scripts used by the build process.
demo                  A sample ONIE-compliant installer and OS.  See README.demo for details.
docs                  What you are reading now.
installer             Files for building an ONIE update installer.
machine               Contains platform-specific machine definition files.  More details below.
patches               Patch sets applied to upstream projects, common to all platforms.
rootconf              Files copied into the final sysroot image. The main ONIE discovery
                      and execution application lives here.  More details below.
upstream              Local cache of upstream project tarballs.
====================  =======


Machine Definition Directory
----------------------------

The ``machine`` directory layout is as follows::

  onie/machine
  └── <platform>
      ├── demo
      │   └── platform.conf
      ├── INSTALL
      ├── kernel
      │   ├── config
      │   ├── platform-<platform>.patch
      │   └── series
      ├── machine.make
      ├── onie-rom.conf
      └── u-boot
          ├── platform-<platform>.patch
          └── series

This directory contains all the files necessary to build ONIE for the
Freescale P2020RBD-PCA reference platform.

================================   =======
File                               Purpose
================================   =======
demo/platform.conf                 Platform-specific codes for creating the demo OS.
INSTALL                            Platform-specific ONIE installation instructions.
kernel/config                      Additional kernel config appended to the core kernel config.
kernel/platform-<platform>.patch   Kernel platform-specific patch(es).
kernel/series                      List of kernel platform-specific patch(es) in order.
machine.make                       Platform-specific make file.
onie-<platform>-rom.conf           Layout of the ONIE binary image(s).
u-boot/platform-<platform>.patch   U-Boot platform-specific patch(es).
u-boot/series                      List of U-Boot platform-specific patch(es) in order.
================================   =======


``rootconf`` Directory
----------------------

The ``rootconf`` directory layout is as follows::

  onie/rootconf
  ├── default
  │   ├── bin
  │   │   ├── discover
  │   │   ├── exec_installer
  │   │   ├── install_url
  │   │   ├── onie-console
  │   │   ├── support
  │   │   ├── uninstaller
  │   │   └── update_url
  │   ├── etc
  │   │   ├── init.d
  │   │   │   ├── discover.sh
  │   │   │   ├── dropbear.sh
  │   │   │   ├── makedev.sh
  │   │   │   ├── networking.sh
  │   │   │   ├── rc
  │   │   │   ├── rc.local
  │   │   │   ├── syslogd.sh
  │   │   │   └── telnetd.sh
  │   │   ├── inittab
  │   │   ├── issue
  │   │   ├── issue.null
  │   │   ├── mtab
  │   │   ├── passwd
  │   │   ├── profile
  │   │   ├── rc3.d
  │   │   │   ├── S10dropbear.sh -> ../init.d/dropbear.sh
  │   │   │   ├── S10telnetd.sh -> ../init.d/telnetd.sh
  │   │   │   └── S50discover.sh -> ../init.d/discover.sh
  │   │   ├── rcS.d
  │   │   │   ├── S01makedev.sh -> ../init.d/makedev.sh
  │   │   │   ├── S05rc.local -> ../init.d/rc.local
  │   │   │   ├── S10networking.sh -> ../init.d/networking.sh
  │   │   │   └── S20syslogd.sh -> ../init.d/syslogd.sh
  │   │   └── syslog.conf
  │   ├── root
  │   ├── sbin
  │   │   └── boot-failure
  │   └── scripts
  │       ├── functions
  │       ├── udhcp4_net
  │       └── udhcp4_sd
  └── install

The contents of the ``default`` directory are copied to the sysroot
verbatim during the build process.

==========================  =======
File                        Purpose
==========================  =======
bin/discover                Image discovery script. Feeds into exec_installer.
bin/exec_installer          Downloads and executes an installer image.
bin/install_url             CLI for explicitly specifying a NOS URL to use for the install.
bin/support                 CLI that generates a tarball of useful system information.
bin/uninstaller             Executed during uninstall operations.
bin/update_url              CLI for explicit specifying an ONIE update URL to use for the install.
etc/init.d                  Various initialization scripts.
etc/inittab                 Standard Linux initialization script.
etc/issue                   Standard Linux logon customization file.
etc/mtab                    Standard Linux file listing mounted file systems.
etc/passwd                  Standard Linux database file listing users authorized to access the system.
etc/profile                 Standard Linux file listing users of the system.
etc/rcS.d/S01makedev.sh     Creates the usual Linux kernel devices and file systems.
etc/rcS.d/S05rc.local       Standard Linux script to start rc.local.
etc/rcS.d/S10networking.sh  Brings up the Ethernet management interface.
etc/rcS.d/S20syslogd.sh     Starts the syslogd service.
etc/rc3.c/S10dropbear.sh    Starts the dropbear SSH service.
etc/rc3.d/S10telnetd.sh     Starts the telnet service.
etc/rc3.d/S50discover.sh    Starts the ONIE discovery service.
install                     The installer file.                     
scripts                     General helper scripts, sourced by other scripts.
==========================  =======

ONIE Demo Installer and Operating System
========================================

The demo installer and operating system illustrate a number of ONIE concepts, 
useful for OS vendors wanting to understand how their OS is installed:

*  How to make an installer compatible with ONIE.
*  The tools and environment available to an installer at runtime.
*  How the OS can invoke ONIE services, like reinstall, uninstall
   and rescue boot.

.. note:: The ONIE binary must previously be installed on the machine.
   See the INSTALL file for details.

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
can find it.  See the main ONIE documentation for more on the
discovery mechanisms and usage models.

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

Currently the only supported ``<arch>`` is ``powerpc``.

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
  PLATFORM:/ # 

The example OS is running BusyBox, so feel free to look around.

.. _demo_nos_reinstall:

Re-installing or Installing a Different OS
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you want to install a new operating system you can re-run the ONIE
installation process.  The demo NOS has a command to do just that::

  PLATFORM:/ # install
  
This command will reboot the machine and the ONIE install process will
run again.  You would do this, for example, when you want to change
operating systems.

.. warning::  This is a destructive operation.

.. _demo_nos_uninstall:

Uninstalling to Wipe the Machine Clean
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you want to wipe the machine clean, removing all of the operating
system, use the ``uninstall`` command::

  PLATFORM:/ # uninstall
  
This command will reboot the machine and ONIE will erase the available
NOR flash and mass storage devices.

.. warning:: This is a destructive operation.

.. _demo_nos_rescue:

Rescue Boot
^^^^^^^^^^^

ONIE has a rescue boot mode, where you can boot into the ONIE
environment and troubleshoot. The discovery and installer mechanisms
do not run while in rescue mode::

  PLATFORM:/ # rescue
  
This command will reboot the machine and ONIE will enter rescue mode.

.. _demo_nos_update:

Updating ONIE
^^^^^^^^^^^^^

If you want to upgrade the ONIE version on the system use the
``update`` command.  This will restart the machine in ONIE update
mode::

  PLATFORM:/ # update

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

ONIE Porting Guide
==================

This section describes requirements and general guidelines to follow
when porting ONIE to a new platform.  Also the :ref:`testing_guide`
should be used to validate the ONIE implementation.

Porting U-Boot
--------------

When porting U-Boot the following items should be checked and
verified:

* Ethernet management PHY LEDs function correctly
* Front panel status LEDs are set appropriately - check power, fans
  and set any corresponding LEDs
* Fan speeds set to 40-50% duty cycle
* Verify MAC address and Serial # are exported as environment variables
* Confirm CONFIG_SYS_CLK_FREQ and CONFIG_DDR_CLK_FREQ oscillators by
  visual inspection.  For example if an oscillator is 66.666MHz use
  66666000 not 66666666.  That will lead to skew.
* Issue "INFO" message if a PSU is not detected or is in a failed state
* Verify the "INSTALL" instructions from the machine directory work.
  These are the instructions used to install ONIE from the u-boot
  prompt.  If the INSTALL instructions need updating then fix them.

ONIE DTS (Device Tree)
----------------------

When porting the ONIE kernel the following .dts (device tree) entries
should be checked and verified:

* The RTC is in the .dts file and works correctly
* The MDIO/PHY interrupts are correct in .dts
* Disable unused serial consoles in .dts
* Verify all EEPROMs (including SPDs) are accessible via sysfs using
  hexdump.  Set the "label" property accordingly:

  * board_eeprom – for the board EEPROM

  * psu1_eeprom / psu2_eeprom – for the power supply unit (PSU) eeproms

  * port1, port2, ... port52 – for the SFP+/QSFP eeproms

* For PCA95xx I2C muxes use the 'deselect-on-exit' property
* I2C nodes use the 'fsl,preserve-clocking' property

ONIE Kernel
-----------

* Inspect the boot log and dmesg output looking for any errors or
  anything unusual
* Inspect ``cat /proc/interrupts`` – are the expected interrutps
  enabled?
* If the platform has CPLDs try acessing some registers using the
  ``iorw`` command.  Can you read a version register?
* Verify the demo NOS compiles and installs OK
* If the box has USB ports plug in a USB stick and see if you can
  mount a partition
* Verify the ``install_url <demo NOS installer URL>`` command works from
  rescue mode
* Verify the ``update_url <ONIE updater URL>`` command works from
  rescue mode

.. _testing_guide:

ONIE Testing Guide
==================

When porting ONIE to a new platform use the tests in this section to
verify the ONIE implementation.  The demo NOS described previously can
be used to exercise the ONIE functionality.

The tests in this section assume you have compiled ONIE and installed
it on the target hardware.

ONIE Install Operations
-----------------------

These tests exercise the ability of ONIE to locate and install a NOS.

.. _locally_attached_network_test:

Locally Attached Network Install
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This test exercises the ability of ONIE to locate an installer image
over the network.

Using a locally attached HTTP server verify the following:

#. the machine boots
#. the Ethernet management interface is configured
#. the machine downloads the demo NOS installer
#. the machine installs the demo NOS
#. the machine reboots into the demo NOS

See :ref:`quick_start_guide` for more on how to configure a HTTP
server and setup the directly attached network.

Locally Attached File System Install (USB Memory Stick)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If the platform does **not** have a USB port skip this test.

This test exercises the ability of ONIE to locate an installer image
on a locally attached file system.  The primary use case is when an
installer image is located on the root directory of a USB memory
stick.

Follow these steps:

#. Power off the switch
#. Copy the demo NOS installer to the root directory of a USB memory
   stick.  Use the file names described in :ref:`default_file_name`.
#. Insert the USB memory stick into the switch's USB port.
#. Turn on the switch power

Verify the following:

#. the machine boots
#. the USB memory stick is detected
#. the machine installs the demo NOS from the USB memory stick
#. the machine reboots into the demo NOS

To verify the memory stick is detected you can inspect the output of
the ``dmesg`` command looking for your USB device.  Also you can
inspect the contents of the ``/proc/partitions`` file.

ONIE / NOS Interface Commands
-----------------------------

These tests exercise the interfaces between the NOS and ONIE.  See
:ref:`nos_interface` for more on these interfaces.

Use the previously described demo NOS commands to exercise the
ONIE-NOS interface.

Install / Re-Provision
^^^^^^^^^^^^^^^^^^^^^^

From the demo NOS prompt verify the ``install`` command works
correctly.  See :ref:`demo_nos_reinstall` for more about this command.

After issuing this command you should verify the following happens:

#. the machine reboots
#. after the reboot ONIE starts in ONIE installer mode

Rescue Mode
^^^^^^^^^^^

From the demo NOS prompt verify the ``rescue`` command works
correctly.  See :ref:`demo_nos_rescue` for more about this command.

After issuing this command you should verify the following happens:

#. the machine reboots
#. after the reboot ONIE starts in ONIE rescue mode

Uninstall
^^^^^^^^^

From the demo NOS prompt verify the ``uninstall`` command works
correctly.  See :ref:`demo_nos_uninstall` for more about this command.

After issuing this command you should verify the following happens:

#. the machine reboots
#. after the reboot ONIE starts in ONIE uninstall mode
#. the mass storage device(s) are erased
#. after uninstalling the machine reboots again
#. the machine detects a corrupt u-boot environment and writes a new
   default environment
#. the machine boots into ONIE installer mode

ONIE Update
^^^^^^^^^^^

This test is very similar to the :ref:`locally_attached_network_test`,
except in this case ONIE is trying to locate and run an ONIE updater
instead of a NOS installer.

For more on updating ONIE and the default ONIE updater file names see
:ref:`updating_onie`.

From the demo NOS prompt verify the ``update`` command works
correctly.  See :ref:`demo_nos_update` for more about this command.

After issuing this command you should verify the following happens:

#. the machine reboots
#. after the reboot ONIE starts in ONIE update mode
#. the Ethernet management interface is configured
#. the machine downloads the ONIE updater
#. the machine installs the ONIE updater
#. the machine reboots into the demo NOS

.. _release_cycle:

ONIE Release Cycle
==================

- ONIE will be released (approximately) every 3 months.

- Under normal conditions the release date will be a Wednesday around
  mid-month.

- Immediately following each release, there will be a "merge window"
  of normally 4 weeks.

- While this merge window is open, new features can be added to the
  ONIE source tree.

- After the merge window closes, no new features may be added.  This
  allows for a release candidate phase which is intended to fix bugs
  and regressions.  During this stabilization period, only patches
  that contain bug fixes get applied.

- After the merge window the release cycle allows for about 2 months
  of testing before generating the next release.

Note: While we try to adhere to the release schedule, we will not
hesitate to delay a release for good reasons.  The code will be
released when it is considered ready without caring too much about the
announced deadline.

Version Numbers
---------------

Starting with the release in November 2013, the names of the releases
changed from numerical release numbers into a time stamp based
numbering. Regular releases are identified by names consisting of the
calendar year and month of the release date.

Additional fields (if present) indicate release candidates or bug fix
releases in "stable" maintenance trees.

Examples:

.. csv-table:: ONIE Version Numbers
  :header: "Version", "Comments"
  :delim: |

  ONIE v2013.11-rc1 | Release candidate 1 for November 2013
  ONIE v2013.11.00  | Stable Release for November 2013
  ONIE v2013.11.01  | Bug fix release 01 for November 2013

Current Status
--------------

The Merge Window for the next release (v2013.11) is :red:`closed`.

Release "v2013.11" is scheduled for November 13, 2013.

Future Releases
---------------

Please note that the following dates are for information only and
without any formal commitment.

.. csv-table:: Future ONIE Releases and Merge Windows
  :header: "Version", "Merge Window Closes", "Approx. Release Date"
  :delim: |

  v2014.02 | Wed, Dec 11, 2013 | Wed, Feb 12, 2014
  v2014.05 | Wed, Mar 12, 2014 | Wed, May 14, 2014
  v2014.08 | Wed, Jun 11, 2014 | Wed, Aug 13, 2014
  v2014.11 | Wed, Sep 10, 2014 | Wed, Nov 12, 2014
