***********************
Developer Documentation
***********************

ONIE Build Instructions
=======================

Machine Definition Files
------------------------

In order to compile ONIE for a particular platform you need the
platform's machine definition, located in
$ONIE_ROOT/machine/<platform>.

If you received a machine definition tarball separately you must first
untar it in the $ONIE_ROOT directory.  For example::

  $ cd onie
  $ tar xJf /path/to/tarball/onie-<platform>.tar.xz

See the README file in ``machine/<platform>`` for additional information
about a particular platform.

Preparing a New Build Machine
-----------------------------

To prepare a new build machine for compiling ONIE first install a
number of standard development packages.

For a `Debian <http://www.debian.org/>`_ based system a Makefile
target exists that installs the required packages on your build
machine.  This target requires the use of sudo(8), since package
installation requires root privileges::

  $ cd build-config
  $ sudo apt-get update
  $ sudo apt-get install build-essential
  $ make debian-prepare-build-host

For a different Linux distribution look at the Makefile and the
``$(DEBIAN_BUILD_HOST_PACKAGES)`` variable.  Then install packages for
your distribution that provide the same tools.

Optional: Install the ELDK version 5.3
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Compiling ONIE requires a cross-compiling toolchain.

Compiling ONIE has been qualified using the `ELDK 5.3
<http://www.denx.de/wiki/ELDK-5>`_ ``powerpc-softfloat`` toolchain,
installed into /opt/eldk-5.3 on the build host.

If you want to use a different toolchain then skip this section.

Frist read the `ELDK download
<http://www.denx.de/wiki/view/ELDK-5/WebHome#Section_1.6.>`_
instructions all the way through to understand the procedure.

Next download the following files, maintaining the directory
structure::

  $ mkdir eldk-download
  $ cd eldk-download
  $ mkdir -p targets/powerpc-softfloat
  $ wget ftp://ftp.denx.de/pub/eldk/5.3/install.sh
  $ chmod +x ./install.sh
  $ cd targets/powerpc-softfloat
  $ wget ftp://ftp.denx.de/pub/eldk/5.3/targets/powerpc-softfloat/target.conf
  $ wget ftp://ftp.denx.de/pub/eldk/5.3/targets/powerpc-softfloat/eldk-eglibc-i686-powerpc-toolchain-gmae-5.3.sh

Finally install the toolchain into /opt/eldk-5.3.  This requires sudo
root privileges::

  $ cd eldk-download
  $ ./install.sh -s gmae -r - powerpc-softfloat

Cross-Compiling ONIE
--------------------

The primary Makefile, ``build-config/Makefile``, defaults to using the
`ELDK 5.3 <http://www.denx.de/wiki/ELDK-5>`_ ``powerpc-softfloat``
toolchain.  To use a different toolchain change the following
variables in ``build-config/Makefile``::

  ARCH        ?= powerpc
  TARGET      ?= $(ARCH)-linux
  CROSSBIN    ?= /opt/eldk-5.3/powerpc-softfloat/sysroots/i686-eldk-linux/usr/bin/powerpc-nf-linux

To compile ONIE first change directories to ``build-config`` and then
type ``"make MACHINE=<platform> all"``, specifying the target machine.
For example::

  $ cd build-config
  $ make -j4 MACHINE=<platform> all

When complete, the ONIE binary is located in
``build/images/<platform>.bin``.

Installing the ONIE binary
--------------------------

See the INSTALL file in ``machine/<platform>`` for additional information
about how to install the ONIE binary on a particular platform.

ONIE Source Code Description
============================

Source Code Layout
------------------

The ONIE source code is laid out as follows::

  onie
  ├── build
  │   ├── images
  ├── build-config
  │   ├── conf
  │   ├── make
  │   └── scripts
  ├── demo
  ├── docs
  ├── installer
  ├── machine
  ├── patches
  │   ├── busybox
  │   ├── kernel
  │   └── u-boot
  ├── rootconf
  │   └── onie
  └── upstream

====================  =======
Directory             Purpose
====================  =======
build/images          The final binary images are placed here
build-config          Builds are launched from this directory.  The main Makefile is here
build-config/conf     Contains configuration common to all platforms
build-config/make     Contains makefile fragments included by the main Makefile
build-config/scripts  Scripts used by the build process
demo                  A sample ONIE compliant installer and OS.  See README.demo for details
docs                  What you are reading now
installer             Files for building an ONIE update installer
machine               Contains platform specific machine definition files.  More on that below
patches               Patch sets applied to upstream projects, common to all platforms
rootconf              Files copied into the final sysroot image. The main ONIE discovery
                      and execution application lives here.  More on that below
upstream              Local cache of upstream project tarballs
====================  =======


Machine Definition Directory
----------------------------

The layout of the ``machine`` directory follows::

  onie/machine
  └── <platform>
      ├── demo
      │   └── platform.conf
      ├── INSTALL
      ├── kernel
      │   ├── config
      │   ├── platform-<platform>.patch
      │   └── series
      ├── onie-<platform>-rom.conf
      └── u-boot
          ├── platform-<platform>.patch
          └── series

This directory contains all the files necessary to build ONIE for the
Freescale P2020RBD-PCA reference platform.

================================   =======
File                               Purpose
================================   =======
demo/platform.conf                 Platform specific codes for creating the demo OS
INSTALL                            Platform specific ONIE installation instructions
kernel/config                      Additional kernel config appended to the core kernel config
kernel/platform-<platform>.patch   Kernel platform specific patch(es)
kernel/series                      List of kernel platform specific patch(es) in order
onie-<platform>-rom.conf           Layout of the ONIE binary image(s)
u-boot/platform-<platform>.patch   U-Boot platform specific patch(es)
u-boot/series                      List of U-Boot platform specific patch(es) in order
================================   =======


``rootconf`` Directory
----------------------

The layout of the ``rootconf`` directory follows::

  onie/rootconf
  └── default
      ├── bin
      │   ├── discover
      │   ├── exec_installer
      │   ├── install_url
      │   ├── support
      │   ├── uninstaller
      │   └── update_url
      ├── etc
      │   ├── rcS.d
      │   │   ├── S01makedev.sh -> ../init.d/makedev.sh
      │   │   ├── S05networking.sh -> ../init.d/networking.sh
      │   │   └── S20syslogd.sh -> ../init.d/syslogd.sh
      │   ├── rc3.d
      │   │   ├── S10telnetd.sh -> ../init.d/telnetd.sh
      │   │   └── S50discover.sh -> ../init.d/discover.sh
      └── scripts

The contents of the ``default`` directory are copied to the sysroot
verbatim during the build process.

==========================  =======
File                        Purpose
==========================  =======
bin/discover                Image discovery script.  Feeds into exec_installer
bin/exec_installer          Downloads and executes an installer image
bin/install_url             CLI for explicity specifying a NOS URL to install
bin/support                 CLI that generates a tarball of useful system information
bin/uninstaller             Executed during uninstall operations
bin/update_url              CLI for explicity specifying an ONIE update URL to install
etc/rcS.d/S01makedev.sh     Creates usual Linux kernel devices and filesystems
etc/rcS.d/S05networking.sh  Brings up Ethernet management interface
etc/rcS.d/S20syslogd.sh     Starts the syslogd service
etc/rc3.d/S10telnetd.sh     Starts the telnet service
etc/rc3.d/S50discover.sh    Starts the ONIE discovery service
scripts                     General helper scripts, sourced by other scripts
==========================  =======

ONIE Demo Installer and Operating System
========================================

The demo installer and operating system illustrate a number of ONIE
concepts, useful for OS vendors wanting to understand how their OS is
installed.

1.  How to make an installer compatible with ONIE.
2.  The tools and environment available to an installer at runtime.
3.  How the OS can invoke ONIE services, like re-install, uninstall
    and rescue boot.

**Note**: The ONIE binary must previously be installed on the machine.
See the INSTALL file for details.

Building the Demo Installer
---------------------------

To compile the demo installer first change directories to
``build-config`` and then type ``"make MACHINE=<platform> demo"``,
specifying the target machine.  For example::

  $ cd build-config
  $ make -j4 MACHINE=<platform> demo

When complete, the demo installer is located in
``build/images/demo-installer-<platform>.bin``.

Using the Installer with ONIE
-----------------------------

The installer needs to be located where the ONIE discovery mechanisms
can find it.  See the main ONIE documentation for more on the
discovery mechanisms and usage models.

For a quick lab demo the IPv6 neighbor discovery method is described
next.

**Note**::

  The build host and network switch must be on the same network
  for this to work.  For example the switch's Ethernet management port
  and the build host should be on the same IP sub-net.  Directly
  attaching the build host to the network switch will work also.

Install and setup a HTTP server on your build host
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We will assume the root of the HTTP server is ``/var/www``.

Copy the demo installer to the HTTP server root, using the name
``onie-installer-<platform>-<arch>``::

  $ cp build/images/demo-installer-<platform>.bin /var/www/onie-installer-<platform>-<arch>

Currently the only supported ``<arch>`` is ``powerpc``.

Power on the Network Switch
^^^^^^^^^^^^^^^^^^^^^^^^^^^

When the switch powers up, ONIE will run and it will attempt to find
an installer.  One of the methods is to look for a file named
``onie-installer-<platform>-<arch>`` on all of the switch's IPv6
neighors.

Using the Freescale P2020RDB-PCA reference platform as an example the
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

ONIE will find the demo installer and run it.  After that the machine
will reboot into the demo OS.

Demo Operating System
---------------------

After the install, the system will reboot and you should see something
like::

  Welcome to the <platform> platform.
   
  Please press Enter to activate this console. 

Hit the Enter key to get a root prompt on the machine.  You should see
something like::

  Welcome to the xyz_123 platform.
  PLATFORM:/ # 

The example OS is running busybox, so feel free to look around.

Re-Install or Install a different OS
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you want to install a new operating system you can re-run the ONIE
installation process.  The demo OS has a command to do just that::

  PLATFORM:/ # install
  
This command will reboot the machine and the ONIE install process will
run again.  You would do this, for example, when you want to change
operating systems.

**WARNING** -- This is a destructive operation.

Un-Install, Wipe Machine Clean
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you want to wipe the machine clean, removing all of the operating
system, use the ``uninstall`` command::

  PLATFORM:/ # uninstall
  
This command will reboot the machine and ONIE will erase the available
NOR flash and mass storage devices.

**WARNING** -- This is a destructive operation.

Rescue Boot
^^^^^^^^^^^

ONIE has a rescue boot mode, where you can boot into the ONIE
environment and poke around.  The discovery and installer mechanisms
do not run while in rescue mode.

  PLATFORM:/ # rescue
  
This command will reboot the machine and ONIE will enter rescue mode.

Demo Source Code Layout
-----------------------

The demo installer and OS source code is laid out as follows::

  demo
  ├── installer
  └── os
      └── default

====================  =======
Directory             Purpose
====================  =======
installer             Files used for making the installer.
os/default            Files copied into the final sysroot image.
====================  =======

A machine specific configuration file is also required::

  machine/<platform>/demo/platform.conf

This contains instructions specific to the machine needed by the
installer.

To understand how the self-extracting installer image is generated see
these source files::

  build-config/make/demo.make
  build-config/scripts/mkdemo.sh

