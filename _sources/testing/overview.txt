.. Copyright (C) 2017,2018 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2015,2016,2017 Carlos Cardenas <carlos@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

****************
Testing Overview
****************

.. highlight:: none

Testing Environment
===================

In order to test an ONIE device, the following are required:

* ONIE device (referred to as Device Under Test or DUT)

* Vendor provided serial console cable (for device interaction and recording of session)

* CAT5/CAT6 RJ45 (for image discovery and delivery)

* PC with serial terminal and RJ45 NIC

* USB memory stick (if supported by the DUT)
  * 2GB is sufficient

Recommended environment - Linux
===============================
* Latest Linux distribution (e.g. Debian) with IPv6 enabled

* screen(1) or minicom(1)

  * 115200 baud 8N1, no flow control (unless otherwise specified by DUT)
  * Logging enabled

* DHCP Server

  * `ISC DHCP Server <https://www.isc.org/downloads/dhcp>`_
  * `dnsmasq <https://en.wikipedia.org/wiki/Dnsmasq>`_

* Web Server

  * Apache httpd
  * nginx
  * lighttpd

* TFTP Server

  * atftpd
  * tftpd-hpa

Recommended environment - Windows
=================================
* Latest Windows 8.1 Update with patches
* PuTTY or Tera Term

  * 115200 baud 8N1, no flow control (unless otherwise specified by DUT)
  * Logging enabled

* dhcpsrv `dhcpsrv <ttp://www.dhcpserver.de/dhcpsrv.htm>`_

  * Also includes web server and tftp server

* Web Server

  * IIS
  * Apache httpd

* TFTP Server

  * WinAgents TFTP server

Dead on Arrival Testing
=======================

Prior to the start of the testing the ONIE device, perform the
following functionality checks:

#. Power on the switch, perform any vendor diagnostic test, if
   applicable.

#. Verify the hardware configuration such as CPU, memory, flash
   storage, USB, Network ports, labeling and asset tracking

#. Perform warm reboot 20 x AC power cycles

#. Perform cold boot 20 x AC power cycles

.. important:: PASS Criteria: Switch boots from warm and cold boot.  Tests 0 and 1.

Preliminary
===========

Before putting a device under test, it is best to know the available
environment variables and options as they will be used in a variety of
ways (naming schemes for install and update images, host options,
etc…).  Below is a print out of using the ``printenv`` command from
U-Boot (PowerPC and ARM only)::

  LOADER=> printenv
  autoload=no
  baudrate=115200
  bootargs=root=/dev/ram rw console=ttyS0,115200 quiet
  bootcmd=run check_boot_reason; run nos_bootcmd; run onie_bootcmd
  bootdelay=10
  check_boot_reason=if test -n $onie_boot_reason; then setenv onie_bootargs boot_reason=$onie_boot_reason; run onie_bootcmd; fi;
  consoledev=ttyS0
  dhcp_user-class=powerpc-as4600_54t_uboot
  dhcp_vendor-class-identifier=powerpc-as4600_54t
  ethact=eth0
  ethaddr=70:72:CF:AA:34:FA
  ethprime=eth0
  gatewayip=192.168.1.10
  hostname=es4654bf_zz-unknown
  ipaddr=192.168.1.10
  loadaddr=0x2000000
  loads_echo=1
  netmask=255.255.255.0
  nos_bootcmd=echo
  onie_args=run onie_initargs onie_platformargs
  onie_bootcmd=echo Loading Open Network Install Environment ...; echo Platform: $onie_platform ; echo Version : $onie_version ; cp.b $onie_start $loadaddr ${onie_sz.b} && run onie_args && bootm ${loadaddr}#$platform
  onie_initargs=setenv bootargs quiet console=$consoledev,$baudrate
  onie_machine=as4600_54t
  onie_machine_rev=0
  onie_platform=powerpc-as4600_54t
  onie_platformargs=setenv bootargs $bootargs serial_num=${serial#} eth_addr=$ethaddr $onie_bootargs $onie_testargs
  onie_rescue=setenv onie_boot_reason rescue && boot
  onie_start=0xefB60000
  onie_sz.b=0x00400000
  onie_uninstall=setenv onie_boot_reason uninstall && boot
  onie_update=setenv onie_boot_reason update && boot
  onie_vendor_id=259
  platform=as4600_54t
  serial#=460054T1406013
  serverip=192.168.1.99
  stderr=serial
  stdin=serial
  stdout=serial
  ver=U-Boot 2013.01.01-g73423af-dirty (Jan 10 2014 - 21:00:23) - 3.0.1.6
   
  Environment size: 1584/65532 bytes
  LOADER=>

Of interest for testing:

================   =====
Variable           Value
================   =====
MAC Address        70:72:CF:AA:34:FA
arch               powerpc
vendor             accton
machine            as4600_54t
machine_revision   0
================   =====

The other way to retrieve this information is from within ONIE
(e.g. rescue mode) using the ``onie-sysinfo`` command.

NOS Image discovery and Installation
====================================

Statically configured (passed from boot loader)
-----------------------------------------------

Prior to booting into ONIE, the environment variable ``install_url``
needs to be set.  To ensure ONIE will perform the installation
regardless if there is a NOS installed, the variable
``onie_boot_reason`` needs to be set to ``install``.

U-Boot Example::

  LOADER=> setenv onie_boot_reason install
  LOADER=> setenv onie_testargs install_url=<URL>
  LOADER=> boot

``GRUB example``

From the GRUB menu, choose ``ONIE: Install OS`` and press ``e`` to
edit the GRUB entry. Set the GRUB variable ``onie_debugargs`` to the
text string ``'onie_testargs install_url=<URL>'``.  Be sure to enclose
the value in single-quotes, like this::

             GNU GRUB  version 2.02~beta3

  +-------------------------------------------------------------+
  |setparams 'ONIE: Install OS'                                 |
  |onie_debugargs='onie_testargs install_url=<URL>'             |
  |  onie_install                                               |

The type ``ctrl-X`` to boot the entry.

.. important:: PASS Criteria: ONIE installs the specified image. Test 2.

Local file systems (USB for example)
------------------------------------

Prior to booting ONIE, a USB memory stick with an ONIE image
conforming to the :ref:`default_file_name`.

Boot device: *This test is only valid for those devices that contain a
USB port.*

.. important:: PASS Criteria: ONIE installs image from USB device using all options of the naming scheme. Tests 3 - 8.

Exact URLs from DHCPv4
----------------------

Prior to booting ONIE, ensure the ONIE image server has the DHCP
server configured to parse out VIVSO and other DHCP options, described
in :ref:`dhcp_vivso`.  When using ``default-url``, please ensure the
appropriate service (ftp, http, or tftp) is enabled.

.. important:: PASS Criteria: ONIE installs image using Exact URLs from DHCPv4 (all 4 targets).  Tests 9 - 12.

Inexact URLs (Partial URLs) based on DHCP responses
---------------------------------------------------

Prior to booting ONIE, ensure the ONIE image server has the DHCP
server configured with four options (configured one at a time).
Please refer to :ref:`partial_install_urls` based on DHCP responses
for the four options.  All options except for the TFTP bootfile, will
locate the image by conforming to the :ref:`default_file_name`.

.. important:: PASS Criteria: ONIE installs image using Inexact URLs from 4 DHCPv4 options (all 19 tests). Tests 13 - 31.

Inexact URLs based on default ONIE server name ``onie-server``
--------------------------------------------------------------

Configure DNS to serve the IP address of the ONIE image server for the
name ``onie-server``.  This server name is used for inexact URLs for
both ``http`` and ``tftp`` protocols.  Attempt each protocol
separately.

.. important:: PASS Criteria: ONIE installs image using Inexact URLs for `http` and `tftp` from the server `onie-server`. Tests 32 - 43.

IPv4 Link Local Address `RFC-3927 <https://tools.ietf.org/html/rfc3927>`_
-------------------------------------------------------------------------

Prior to booting ONIE, ensure the ONIE image server has a IPv4 link
local address configured and running a web server with the ONIE images
conforming to the :ref:`default_file_name`.

.. important:: PASS Criteria: ONIE installs image from IPv4 link local neighbor device using all options of the naming scheme. Tests 44 - 49.

IPv6 Neighbors
--------------

Prior to booting ONIE, ensure the ONIE image server has IPv6
configured and running a web server with the ONIE images conforming to
the :ref:`default_file_name`.

.. important:: PASS Criteria: ONIE installs image from IPv6 neighbor device using all options of the naming scheme. Tests 50 - 55.

TFTP Waterfall
--------------

Prior to booting ONIE, ensure the ONIE image server has the TFTP
service enabled and configured.

.. important:: PASS Criteria: ONIE installs image from TFTP waterfall using all options of the naming scheme. Tests 56 - 61.

NOS Uninstallation
==================

To perform the NOS uninstallation will depend on where in the boot
process the device is in.  If the device is powered off:

For U-Boot, break out to U-Boot prompt::

  LOADER=> run onie_uninstall

For x86 select ``ONIE: Uninstall NOS`` from the GRUB menu (x86).

To set ONIE to uninstall via the boot reason option,

(UBoot)::

  u-boot> fw_setenv onie_boot_reason uninstall
  u-boot> reboot

(x86, from ONIE rescue prompt)::

  ONIE:/# onie-boot-mode -o uninstall
  ONIE:/# reboot

.. important:: PASS Criteria: ONIE boots up and performs the
               uninstallation phase erasing all blocks of the previous
               image. Tests 122 - 124.

ONIE Self Update
================

Statically configured (passed from boot loader)
-----------------------------------------------

Prior to booting into ONIE, the environment variable ``install_url``
needs to be set.  To ensure ONIE will perform the installation
regardless if there is a NOS installed, the variable
``onie_boot_reason`` needs to be set to ``update``.

U-Boot Example::

  LOADER=> setenv onie_boot_reason update
  LOADER=> setenv onie_testargs install_url=<URL>
  LOADER=> boot

``GRUB example``

From the GRUB menu, choose ``ONIE: Update ONIE`` and press ``e`` to
edit the GRUB entry. Set the GRUB variable ``onie_debugargs`` to the
text string ``'onie_testargs install_url=<URL>'``.  Be sure to enclose
the value in single-quotes, like this::

             GNU GRUB  version 2.02~beta3

  +-------------------------------------------------------------+
  |setparams 'ONIE: Update ONIE'                                |
  |onie_debugargs='onie_testargs install_url=<URL>'             |
  |  onie_update                                                |

The type ``ctrl-X`` to boot the entry.

.. important:: PASS Criteria: ONIE updates the specified image. Test 62.

Local file systems (USB for example)
------------------------------------

Prior to booting ONIE, a USB memory stick with an ONIE image
conforming to the naming scheme :ref:`specify_updater_url`.

Boot device: *This test is only valid for those devices that contain a
USB port.*

.. important:: PASS Criteria: ONIE updates image from USB device using all options of the naming scheme. Tests 63 - 68.

Exact URLs from DHCPv4
----------------------

Prior to booting ONIE, ensure the ONIE image server has the DHCP server configured to parse out VIVSO and other DHCP options, described
in :ref:`dhcp_vivso`.  When using ``default-url``, please ensure the appropriate service (ftp, http, or tftp) is enabled.

.. important:: PASS Criteria: ONIE updates image using Exact URLs from DHCPv4 (all 4 targets).  Tests 69 - 72.

Inexact URLs (Partial URLs) based on DHCP responses
---------------------------------------------------

Prior to booting ONIE, ensure the ONIE image server has the DHCP
server configured with four options (configured one at a time).
Please refer to :ref:`partial_install_urls` based on DHCP responses
for the four options.  All options except for the TFTP bootfile, will
locate the image by conforming to the :ref:`specify_updater_url`.

.. important:: PASS Criteria: ONIE updates image using Inexact URLs from 4 DHCPv4 options (all 19 tests). Tests 73 - 91.

Inexact URLs based on default ONIE server name ``onie-server``
--------------------------------------------------------------

Configure DNS to serve the IP address of the ONIE image server for the
name ``onie-server``.  This server name is used for inexact URLs for
both ``http`` and ``tftp`` protocols.  Attempt each protocol
separately.

.. important:: PASS Criteria: ONIE updates image using Inexact URLs for `http` and `tftp` from the server `onie-server`. Tests 92 - 103.

IPv4 Link Local Address `RFC-3927 <https://tools.ietf.org/html/rfc3927>`_
-------------------------------------------------------------------------

Prior to booting ONIE, ensure the ONIE image server has a IPv4 link
local address configured and running a web server with the ONIE images
conforming to the :ref:`default_file_name`.

.. important:: PASS Criteria: ONIE updates image from IPv4 link local neighbor device using all options of the naming scheme. Tests 104 - 109.

IPv6 Neighbors
--------------

Prior to booting ONIE, ensure the ONIE image server has IPv6
configured and running a web server with the ONIE images conforming to
the :ref:`specify_updater_url`.

.. important:: PASS Criteria: ONIE updates image from IPv6 neighbor device using all options of the naming scheme. Tests 110 - 115.

TFTP Waterfall
--------------

Prior to booting ONIE, ensure the ONIE image server has the TFTP
service enabled and configured.

.. important:: PASS Criteria: ONIE updates image from TFTP waterfall using all options of the naming scheme. Tests 116 - 121.

Rescue Mode
===========

To enter rescue mode will depend on where in the boot process the
device is in.  If the device is powered off:

For U-Boot, break out to U-Boot prompt

  LOADER=> run onie_rescue

For x86, select ``ONIE: Uninstall NOS`` from the GRUB menu (x86).

To set ONIE to install via the boot reason option,

(U-Boot)

  u-boot> fw_setenv onie_boot_reason rescue
  u-boot> reboot

(x86, from ONIE rescue prompt)

  ONIE:/# onie-boot-mode -o rescue
  ONIE:/# reboot

.. important::
   PASS Criteria: ONIE boots up without the discover mechanism
   running. Tests 125 - 127.  Verify with boot screen saying::

     discover: Rescue mode detected.  Installer disabled.

   Or verify the output of ``ps w``.
