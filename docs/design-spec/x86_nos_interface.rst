.. Copyright (C) 2014,2015,2016,2017 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2016 david_yang <david_yang@accton.com>
   Copyright (C) 2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

*********************
x86 Interface Details
*********************

This section describes the x86-specific methods used to implement the
NOS interface.  See the :ref:`nos_interface` section for more about
the NOS interface.

.. _cmd_onie_boot_mode:
.. _x86_nos_interface:

x86 NOS Interface
-----------------

On x86 the NOS and ONIE communicate using GRUB environment variables
stored in the ``ONIE-BOOT`` partition.

ONIE provides a tool called ``onie-boot-mode`` that an NOS uses to set
the ONIE boot mode to one of:

- ``install``

- ``uninstall``

- ``rescue``

- ``update``

- ``embed``

- ``diag``
  
The complete help for the tool is::

  ONIE:/ # onie-boot-mode -h
  usage: onie-boot-mode [-o <onie_mode>] [-lhvq]
  Get or set the default GRUB boot entry.  The default is to show
  the current default entry.
   
  COMMAND LINE OPTIONS
   
          -o
                  Set the default GRUB boot entry to a particular "ONIE
                  mode".  Available ONIE modes are:
   
                  install   -- ONIE OS installer mode
                  rescue    -- ONIE rescue mode
                  uninstall -- ONIE OS uninstall mode
                  update    -- ONIE self update mode
                  embed     -- ONIE self update mode and embed ONIE
                  diag      -- Hardware Vendor's Diagnostic
                  none      -- Use system default boot mode
   
                  Some platforms may offer additional modes.  Check with
                  your hardware vendor.
   
                  The 'none' mode will use the first ONIE boot menu entry.
   
          -l
                  List the current default entry.  This is the default.
   
          -h
                  Help.  Print this message.
   
          -q
                  Quiet.  No printing, except for errors.
   
          -v
                  Be verbose.  Print what is happening.

The tool is located in the ``ONIE-BOOT`` partition in the
``onie/tools/bin/onie-boot-mode`` directory.  The NOS can easily mount
the ``ONIE-BOOT`` partition by using the disk volume label
``ONIE-BOOT``; for example, the following mounts the ONIE-BOOT partition from a
Linux-based NOS::

  NOS:/ # mkdir /mnt/onie-boot
  NOS:/ # mount LABEL=ONIE-BOOT /mnt/onie-boot

After that the ``onie-boot-mode`` tool is available in::

  NOS:/ # /mnt/onie-boot/onie/tools/bin/onie-boot-mode

The tool is a thin wrapper around the `grub-editenv
<http://man.he.net/man1/grub-editenv>`_ command that sets the
``onie_mode`` variable to the desired value.

.. _x86_nos_intf_installer:

x86 NOS Installer
=================

The main duties of an NOS installer on x86 are:

- Create partitions and format file systems

- Install the NOS software in the new partitions

- Install GRUB in the MBR

- Set its GRUB configuration

Installing GRUB and setting up the GRUB configuration are the most
important steps to describe here.

The walk through for installing GRUB and setting up the GRUB
configuration is described in the :ref:`x86_boot_loader` section.

Also the provided demo OS installer exercises all of the steps
described in this section.  See the :ref:`demo_os` section for more
about the Demo OS.

In subsequent sections, the following assumptions about the NOS are made:

#. The NOS is Linux-based

#. The NOS has mounted the ``ONIE-BOOT`` partition read-write on
   ``/mnt/onie-boot``

#. The NOS has created a GRUB menu entry named ``ONIE`` to chainload
   into ONIE

#. The NOS has the ``grub-reboot`` command available

The ``grub-reboot`` command allows the NOS's GRUB to boot the ONIE
chainload entry once.  After one boot, the NOS's GRUB will revert back
to the NOS default GRUB menu entry.

.. _x86_nos_intf_reinstaller:

x86 Reinstalling or Installing a Different NOS
==============================================

To invoke the install operation, the NOS runs the following commands::

  NOS:/ # grub-reboot ONIE
  NOS:/ # /mnt/onie-boot/onie/tools/bin/onie-boot-mode -o install

See the :ref:`nos_intf_reinstaller` section for more about the NOS
reinstaller interface.

.. _x86_nos_intf_uninstall:

x86 NOS Uninstall
=================

To invoke the uninstall operation, the NOS runs the following
commands::

  NOS:/ # grub-reboot ONIE
  NOS:/ # /mnt/onie-boot/onie/tools/bin/onie-boot-mode -o uninstall

Following the uninstall process, the system returns to the
discovery and installation phase.

See the :ref:`nos_intf_uninstall` section for more about the NOS
uninstall interface.

.. _x86_nos_intf_rescue:

x86 Rescue and Recovery
=======================

To invoke the rescue operation, the NOS runs the following commands::

  NOS:/ # grub-reboot ONIE
  NOS:/ # /mnt/onie-boot/onie/tools/bin/onie-boot-mode -o rescue

See the :ref:`nos_intf_rescue` section for more about the NOS rescue
interface.

.. _x86_nos_intf_update:

x86 Updating and Embedding ONIE
===============================

On x86 a distinction is made between the ``update`` operation and the
``embed`` operation.

The ``embed`` operation is **destructive** and will wipe out
everything (including any installed NOS) and install a new version of
ONIE.  Typically this is done in manufacturing before the customer
receives the unit.

The ``update`` operation is **not** destructive.  This operation will
only update the ``ONIE-BOOT`` partition.  Typically this would be used
in the field to update the current ONIE version, while leaving the
installed NOS intact.

To invoke the update operation, the NOS runs the following commands::

  NOS:/ # grub-reboot ONIE
  NOS:/ # /mnt/onie-boot/onie/tools/bin/onie-boot-mode -o update

To invoke the embed operation, the NOS runs the following commands::

  NOS:/ # grub-reboot ONIE
  NOS:/ # /mnt/onie-boot/onie/tools/bin/onie-boot-mode -o embed

See the :ref:`nos_intf_update` section for more about the NOS update
interface.

.. _x86_hw_diag:

*********************************************
x86 Hardware Diagnostics Interface [Optional]
*********************************************

This section describes the method for providing a hardware diagnostic
for x86 platforms.  See the :ref:`hw_diag` section for more about
providing a hardware diagnostic.

Installing the diag should be like installing a NOS.  Use the NOS
installer mechanism to install the diag image into its own partition.
This will allow hardware vendors to update the diag image
independently from ONIE.

All of the requirements specified in this section are illustrated by
the ``Demo Diag OS``, which comes with the ONIE source code.  See the
:ref:`demo_diag_os` section for more information.

Disk Partitioning
-----------------

The diagnostic image resides on a hard disk partition.  This sections
describes properties of the disk partition.

GPT Partition Table
===================

A diagnostic image installer on a GPT based machine must implement the
following:

* name the diag partition ``<SOMETHING>-DIAG``.  See the `sgdisk
  <http://www.rodsbooks.com/gdisk/sgdisk.html>`_ program and the
  ``--change-name`` option for details.  The ``<SOMETHING>`` can be
  any string that makes sense for the hardware vendor.

* set the GPT ``system partition`` attribute bit (bit 0).  See the
  `sgdisk <http://www.rodsbooks.com/gdisk/sgdisk.html>`_ program and
  the ``--attributes`` option.

* when creating the file system on the diag partition set the file
  system label to ``<SOMETHING>-DIAG``, the same string as used for
  the GPT partition label.  See the `mkfs.ext4
  <http://linux.die.net/man/8/mkfs.ext4>`_ program and the ``-L``
  option.

The ``-DIAG`` suffix and the ``system partition`` bit announces to ONIE
and ONIE compliant NOS installers that the partitions are *precious*
and should not be modified.

The ONIE ``uninstall`` operation must *not* remove or modify
partitions that meet the above requirements.

An ONIE compliant NOS must *not* remove or modify partitions that meet
the above requirements.

MSDOS Partition Table
=====================

For machines that use the MSDOS partition table, all we can do is use
the file system label. When creating the file system on the diag
partition set the file system label to ``<SOMETHING>-DIAG``. See the
`mkfs.ext4 <http://linux.die.net/man/8/mkfs.ext4>`_ program and the
``-L`` option as an example.

The ONIE ``uninstall`` operation must *not* remove or modify
partitions that meet the above requirements.

An ONIE compliant NOS must *not* remove or modify partitions that meet
the above requirements.

GRUB Considerations
-------------------

When installing the diagnostic image, install GRUB into the MBR, just
like a normal OS would do.

In addition, install GRUB into the diag partition.  This will allow a
NOS to *chainload* the diag OS with low friction.

The ``grub.cfg`` for the diag partition must contain all the GRUB menu
entries the diag OS needs, plus one entry to chainload ONIE.

.. note::
 
  For ONIE versions up to and including 2015.11 the diagnostic image
  installs GRUB into the MBR.  It is no longer recommended to install
  GRUB into the MBR for the later versions.


If the diagnostic image is installed on versions older than 2015.11,
it should *only* install GRUB into the diag partition and *not* set
``ONIE`` to be the default menu entry.  This makes the boot order
between the GRUBs on ONIE and diag OS be fixed.

If the diagnostic image is installed on versions newer than 2015.11,
it should *not* install GRUB into both the MBR and diag partition.
The later versions supports boot command feeded by diag installer.
This feature makes ONIE share GRUB with diag OS.  i.e., the diag
partition does not have its own GRUB instance and ``grub.cfg``.  To
enable the feature, diag installer needs to be revised to meet the
function.  Please refer to the Demo diag installer in ONIE 2016.02.
