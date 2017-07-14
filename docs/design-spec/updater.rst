.. Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2013 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. _updating_onie:

*************
Updating ONIE
*************

ONIE provides a way to update itself, including the boot loader and
Linux kernel. In many ways, this behaves similarly to the discovery and
installation phase, except that ONIE is looking for a different kind
of image.

When compiling ONIE, one of the build products is an ONIE updater.  See
the :ref:`onie_build_products` table.

To update ONIE, you follow a procedure similar to installing a network
OS (NOS), except instead of using an NOS installer, you use the ONIE
updater.  Also a few details are different as described next.

Starting ONIE in Self-Update Mode
=================================

To initiate ONIE self-update mode, follow the steps described in the
NOS interface :ref:`nos_intf_update` section.  This launches ONIE in 
self-update mode.

.. _specify_updater_url:

Specifying the Updater URL
==========================

All of the methods for discovering an NOS installer from the
:ref:`installer_discovery` section also apply to discovering an ONIE
updater image, with a few exceptions.

ONIE looks for the following default updater file names in order:

#. ``onie-updater-<arch>-<vendor>_<machine>-r<machine_revision>``
#. ``onie-updater-<arch>-<vendor>_<machine>``
#. ``onie-updater-<vendor>_<machine>``
#. ``onie-updater-<arch>``
#. ``onie-updater``

For a hypothetical x86_64 machine, the default updater file names
would be::

  onie-updater-x86_64-VENDOR_MACHINE-r0
  onie-updater-x86_64-VENDOR_MACHINE
  onie-updater-VENDOR_MACHINE
  onie-updater-x86_64
  onie-updater

Another difference is when using DHCP :ref:`dhcp_vivso`, you must set
option 2, ``Updater URL``, to specify the updater URL.

Also, as described in :ref:`nos_intf_rescue`, you can use the
``onie-self-update`` command to specify an updater URL from rescue
mode.

.. _update_image_format:

ONIE Update Image Format
========================

The ONIE update image adheres to the following format:

* The image is a self-extracting shell script archive.

* The image must contain the string ``ONIE-UPDATER-COOKIE``, which
  identifies the image as an ONIE updater image.

The image itself is executable and supports a number of command line
options::

  -h
          Help.  Print this message.
   
  -v
          Be verbose.	 Print what is happening.
   
  -q
          Be quiet.  Do not print what is happening.
   
  -x
          Extract image to a temporary directory.
   
  -i
          Dump image information.
   
  -f
          Force ONIE update opteration, bypassing any safety
          checks.

Delivering General Firmware Updates using ONIE
==============================================

For managing firmware updates see :ref:`firmware_updates`.
