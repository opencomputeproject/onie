Build Instructions
==================

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

Cross-Compiler Toolchain
------------------------

The ONIE build process generates and uses a cross compiling toolchain
based on `gcc <http://gcc.gnu.org/>`_ and `uClibc
<http://www.uclibc.org/>`_.  The `crosstool-NG
<http://crosstool-ng.org/>`_ project is used to manage the build the
of the toolchain.

A number of packages are downloaded from the Internet by the ONIE
build process and cached for subsequent builds.  You can setup your
own local mirror for these packages by setting up
``onie/build-config/local.make``.  See the sample file,
``onie/build-config/local.make.example``, and the ``ONIE_MIRROR`` and
``CROSSTOOL_ONIE_MIRROR`` variables for examples.

Cross-Compiling ONIE
--------------------

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

Source Code Description
=======================

Source Code Layout
------------------

The ONIE source code layout is as follows::

  onie
  ├── build
  │   └── docs
  │       ├── doctrees
  │       └── html
  ├── build-config
  │   ├── arch
  │   ├── conf
  │   ├── make
  │   └── scripts
  ├── contrib
  │   └── onie-server
  ├── demo
  ├── docs
  ├── installer
  ├── machine
  │   └──<platform> 
  │       ├── demo
  │       ├── kernel
  │       ├── test
  │       └── u-boot
  ├── patches
  │   ├── busybox
  │   ├── crosstool-NG
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
  ├── test
  │   ├── bin
  │   ├── lib
  │   └── tests
  └── upstream

====================  =======
Directory             Purpose
====================  =======
build/docs            The final documentation is placed here.
build-config          Builds are launched from this directory.  The main Makefile is here.
build-config/arch     Contains configurations for CPU architectures.
build-config/conf     Contains configurations common to all platforms.
build-config/make     Contains makefile fragments included by the main Makefile.
build-config/scripts  Scripts used by the build process.
contrib/onie-server   A stand alone DHCP+HTTP python based server to simple installs.
demo                  A sample ONIE-compliant installer and OS.  See README.demo for details.
docs                  What you are reading now.
installer             Files for building an ONIE update installer.
machine               Contains platform-specific machine definition files.  More details below.
patches               Patch sets applied to upstream projects, common to all platforms.
rootconf              Files copied into the final sysroot image. The main ONIE discovery
                      and execution application lives here.  More details below.
test/bin              Contains the ONIE testing harness (python unittest based).
test/lib              Common python classes for writing ONIE tests.
test/tests            ONIE tests.
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
  │   │   ├── onie-nos-install
  │   │   ├── onie-console
  │   │   ├── support
  │   │   ├── uninstaller
  │   │   ├── onie-self-update
  │   │   └── onie-stop
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
bin/onie-nos-install        CLI for explicitly specifying a NOS URL to use for the install.
bin/support                 CLI that generates a tarball of useful system information.
bin/uninstaller             Executed during uninstall operations.
bin/onie-self-update        CLI for explicit specifying an ONIE update URL to use for the install.
bin/onie-stop               CLI for disabling discovery mode.  Terminates the discovery process.
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
