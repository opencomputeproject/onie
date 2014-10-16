.. Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. _x86_boot_loader:

***********************
x86 Boot Loader (GRUB2)
***********************

On x86, ONIE uses `GRUB2 <http://www.gnu.org/software/grub/>`_
as the boot loader.  This section describes how ONIE uses GRUB and how
the disk is partitioned.

.. note::

  At a high level, the philosophy is that the NOS **owns** the boot
  loader and the NOS **must** install its own GRUB (or some other boot
  loader) itself.

The ONIE kernel and ``initramfs`` reside in a single, self-contained
partition. The installed NOS controls how it manages the MBR and GRUB.

Disk Partition Layout
---------------------

The disk partition layout plays a critical role in how ONIE and the
installed NOS cooperate. This section describes the layout and lays
down the guidelines by which ONIE and the NOS must abide.

All of the steps described in this section are exercised by the Demo
OS Installer and Demo OS Runtime that ships with ONIE.  See the
:ref:`demo_os` section for more about the Demo OS.

Disk Partition Type
===================

Each machine can choose whether to use `GUID Partition Table
<http://en.wikipedia.org/wiki/GUID_Partition_Table>`_ (GPT) or `MS-DOS
<http://en.wikipedia.org/wiki/Master_boot_record>`_ disk labels.  The
choice is made in the ``$MACHINE/machine.make`` file by setting
``PARTITION_TYPE`` to ``msdos`` or ``gpt``.

The choice is up to the hardware vendor.  The ``onie-sysinfo -t``
command reports the disk label used by the running machine.  An NOS
installer can use this command to determine how to partition the disk
for itself.

If not specified, the default partition table type is GPT.

Initial ONIE Install (embed)
============================

When ONIE is initially installed in the factory, the hard disk is
blank.  Assume PXE boot (or a USB stick) was used to install ONIE for
the first time.

The below examples use GPT as the disk label.  The mechanics for MS-DOS
disk labels are nearly the same, the only difference being GPT needs
to create the "BIOS GRUB" partition while MS-DOS does not.

For example, assume the hard disk is available as ``/dev/sda`` from Linux.

After **embedding** ONIE, the disk layout looks like::

  +========================+
  |                        |
  |  Sector LBA 0 aka MBR  |  <-- 1st stage boot loader in LBA-0.  Installed by ONIE
  |                        |      during grub-install.  Loads additional code from
  |  1st stage boot loader |      /dev/sda1 and configuration from /dev/sda2.
  |                        |
  +========================+
  |                        |
  |  /dev/sda1 GRUB        |  <-- Additional data stored and used by GRUB for GPT disk
  |                        |      labels.  Installed by ONIE during grub-install.
  |  BIOS GRUB             |      MS-DOS partition type does not have this.
  |                        |
  +========================+
  |                        |
  |  /dev/sda2 ONIE-BOOT   |  <-- ONIE partition.  Installed by ONIE.  Contains
  |                        |      kernel and initramfs.  The GRUB 1st stage loader is
  |  ONIE Installs GRUB    |      *also* installed on this partition.
  |                        |
  +========================+
  |                        |
  |                        |
  /  Free Space            /
  |                        |
  |                        |
  +========================+

During the initial disk provisioning the ONIE installer does the
following:

#. Since the disk is blank we are **embedding** ONIE and need to
   create the partition table.  The installer creates a disk label (either
   ``msdos`` or ``gpt`` depending on machine config).  ``gpt`` is used in this
   example.

#. Creates needed partitions (two for ``gpt``, one for ``msdos``).  The
   ``ONIE-BOOT`` partition is created in either case.

#. Installs ONIE kernel+initramfs into the ``ONIE-BOOT`` partition.

#. Installs GRUB into ``/dev/sda``, using ``/dev/sda2`` as the GRUB
   ``--boot-directory``.  This allows the system to boot initially
   with no NOS installed.

#. Installs GRUB **again** into /dev/sda2, the ``ONIE-BOOT``
   partition.  This facilitates chainloading ONIE.

An OS normally installs the GRUB 1st stage loader into ``/dev/sda``
(and for GPT also in ``/dev/sda1``).  The GRUB configuration and
related files go into ``/dev/sda2``, typically mounted as ``/boot``.

Another supported option is to install the GRUB 1st stage loader into
a partition, like ``/dev/sda2``.  Using this approach you can
chainload the ONIE OS from the NOS's GRUB menu.

When ONIE is installed in the factory, the ONIE installer installs the
GRUB 1st stage loader into **both** ``/dev/sda`` and ``/dev/sda2``.
The 1st stage loader in ``/dev/sda`` is "disposable" and is over
written by the NOS when it installs GRUB.  The disposable 1st stage
loader is only used to get ONIE started the first time, then the NOS
installer will take over.

.. note::

  The philosophy here is that the installed NOS **owns** the
  ``/dev/sda`` MBR for installing the GRUB 1st stage loader.  ONIE
  **owns** everything in ``/dev/sda2``.  As long as the NOS installer
  leaves ``/dev/sda2`` intact, we are good.

.. note::

  For GPT disk labels, the ONIE-BOOT partition type GUID is
  ``7412F7D5-A156-4B13-81DC-867174929325``.  This GUID is recognized
  by the ``gdisk`` and ``sgdisk`` utilities from the `GPT fdisk
  package <http://www.rodsbooks.com/gdisk/>`_.  See `commit b784e0c95a11
  <http://sourceforge.net/p/gptfdisk/code/ci/b784e0c95a11cdaad05b0f62806114ead678a2b0/>`_
  for details.

The initial GRUB menu looks like this::

       GNU GRUB  version 2.02~beta2+e4a1fe391
  
  +---------------------------------------------+
  |*ONIE: Install OS                            | 
  | ONIE: Rescue                                |
  | ONIE: Uninstall OS                          |
  | ONIE: Update ONIE                           |
  | ONIE: Embed ONIE                            |
  |                                             |
  |                                             |
  +---------------------------------------------+


After a NOS Installer Runs
==========================

Continuing the example above, let's examine what a NOS installer must
do.  The NOS installer is going to create partitions and install its
own version of GRUB (could even be GRUB legacy or LILO).

As an example assume the user installed CentOS into the remaining free
space.

The disk now looks like::

  +========================+
  |                        |
  |  Sector LBA 0 aka MBR  |  <-- 1st stage boot loader in LBA-0.  Installed by CentOS
  |                        |      during grub-install.  Loads additional code from
  |  1st stage boot loader |      /dev/sda1 and configuration from /dev/sda3.
  |                        |
  +========================+
  |                        |
  |  /dev/sda1 GRUB        |  <-- Additional data stored and used by GRUB for GPT disk
  |                        |      labels.  Installed by CentOS during grub-install.
  |  BIOS GRUB             |      MSDOS partition type does not have this.
  |                        |
  +========================+
  |                        |
  |  /dev/sda2 ONIE-BOOT   |  <-- ONIE partition.  Untouched by the CentOS installer.
  |                        |
  |  ONIE Installs GRUB    |
  |                        |
  +========================+
  |                        |
  |                        |
  /  /dev/sda3 CentOS      /  <-- CentOS partition.  Installed by CentOS.  Contains
  |                        |      kernel, initramfs and GRUB configuration.
  |                        |
  +========================+

.. note::

  CentOS installed its version of the GRUB 1st stage loader into
  ``/dev/sda``, overwriting what ONIE installed in the factory.  This
  is OK.

The CentOS GRUB will reference GRUB config files and modules from
``/dev/sda3``.  It does not involve ONIE installed on ``/dev/sda2`` at
all.

Chainloading and Selecting ONIE Mode
====================================

In order to facilitate returning to ONIE from the NOS the NOS adds a
GRUB menu entry for chainloading ONIE.  A sample file that can be
dropped into ``/etc/grub.d`` is provided in
``onie/rootconf/x86_64/sysroot-lib-onie/50_onie_grub``.

To select which "mode" to start ONIE in the NOS uses a tool provided
by ONIE called ``onie-boot-mode``.  See the :ref:`cmd_onie_boot_mode`
section for more about the ``onie-boot-mode`` command.

The use of `grub-reboot <man.he.net/man8/grub-reboot>`_ is helpful
here to reboot and chainload ONIE for one boot, returning to the
default GRUB menu entry after that.

With the ONIE chainload menu entry in place, the GRUB menu looks
something like this after a reboot::

        GNU GRUB  version 2.02~beta2+e4a1fe391
   
   +-----------------------------------------------+
   |*CentOS 6.5-x86_64                             | 
   | Memory test (memtest86+)                      |
   | ONIE                                          |
   |                                               |
   |                                               | 
   +-----------------------------------------------+

Installing GRUB and creating an initial ``grub.cfg`` file that
chainloads ONIE is demonstrated by the Demo OS installer.  See the
:ref:`demo_os` section for more about the Demo OS.

Here is an example of what the ONIE chainload GRUB menu entry looks
like::

  # Menu entry to chainload ONIE
  menuentry ONIE {
          search --no-floppy --label --set=root ONIE-BOOT
          echo    'Loading ONIE ...'
          chainloader +1
  }

Here is a example script, run in the context of the NOS, that would
reboot the system into ONIE rescue mode::

  #!/bin/sh
   
  echo "Rebooting into ONIE rescue mode..."
   
  grub-reboot ONIE
  /mnt/onie-boot/onie/tools/bin/onie-boot-mode -q -o rescue

