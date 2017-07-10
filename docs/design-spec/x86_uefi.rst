.. Copyright (C) 2015,2016,2017 Curt Brune <curt@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. _x86_uefi:


*************************
x86 UEFI Firmware Support
*************************

This design specification defines how the Open Network Install
Environment (ONIE) integrates with x86 based Unified Extensible
Firmware Interface (`UEFI
<http://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface>`_)
systems.

Acronyms
========

.. csv-table:: Acronyms related to UEFI
  :header: "Term", "Definition"
  :widths: 1, 4
  :delim: %

  BIOS % Basic Input/Output System PC Firmware `BIOS <http://en.wikipedia.org/wiki/BIOS>`_

  CSM  % UEFI Compatibility Support Module `CSM <http://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface#CSM_booting>`_

  ESP  % EFI System Partition `ESP <http://en.wikipedia.org/wiki/EFI_System_partition>`_

  FBM  % UEFI Firmware Boot Manager

  GPT  % GUID Partition Table `GPT <http://en.wikipedia.org/wiki/GUID_Partition_Table>`_

  GRUB-x86_64-efi % GRUB2 compiled for x86_64 CPU with UEFI firmware

  GRUB-i386-pc % GRUB2 compiled for i386/x86_64 CPU with BIOS firmware

  HDOS % Hardware diagnostics operating system

  MBR  % Master Boot Record `MBR <http://en.wikipedia.org/wiki/Master_boot_record>`_

  NOS  % Network Operating System

  ONIE % Open Network Install Environment

  UEFI % Unified Extensible Firmware Interface `UEFI <http://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface>`_

Overview
========

ONIE added support for UEFI in the 2015.08 release.  Previously for
x86, ONIE only supported legacy `BIOS
<http://en.wikipedia.org/wiki/BIOS>`_ firmware or a UEFI system
running in BIOS legacy mode, sometimes called "Compatibility Support
Module" `CSM
<http://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface#CSM_booting>`_.

While this worked, the mechanics of booting from NOS to ONIE and back
again is non-trivial and prone to implementation errors.

UEFI simplifies a number of ONIE design points on x86 platforms.
Among the benefits:

* UEFI is now a standard for x86 servers.  Requiring ONIE compatible
  systems to support a specific UEFI version, is a very specific
  target for hardware vendors to aim for.

* ONIE and network operating systems (NOS) can interoperate using a
  much less complicated method than the current BIOS based MBR method.

* Easier to support multiple operating systems installed on the same
  machine.

* UEFI is the only way to support future ARM64 platforms.

ONIE Requirements
=================

All the existing x86 requirements from :ref:`x86_hw_requirements`
continue to apply to UEFI, plus the following:

* Provide an "UEFI aware" environment for network operating system
  (NOS) installers to perform the installation task.

* Allow multiple operating system installations to coexist.

* Provide ONIE-NOS interfaces in terms of UEFI primitives.

Target UEFI Version
===================

At the time of this writing the current UEFI specification version is
2.4 (errata B).  `Download UEFI 2.4b Specification
<http://www.uefi.org/sites/default/files/resources/2_4_Errata_B.pdf>`_.

As necessary this specification will reference chapters and section
numbers from the UEFI specification, version 2.4 (errata B).

The design described herein targets that UEFI version or later.

As background, the reader is directed to chapter 3 (Boot Manager) and
section 12.3 (File System Format) for more on how the UEFI boot
manager locates and executes UEFI images.  See also
:ref:`x86_uefi_references`.

ONIE and UEFI Integration
=========================

ONIE is primarily concerned with the life cycle of an operation
system, including:

* installing an OS

* removing an OS

* scheduling which OS to boot

On a UEFI system the Firmware Boot Manager (FBM) determines the boot
order through a number of UEFI global variables, defined in section
3.2 of the UEFI specification.

In order for ONIE, which is Linux based, to inter-operate with these
global variables a number of additional software configurations and
programs are required.

Linux Kernel Support for UEFI
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The Linux kernel configuration must enable the following configuration
options:

* ``CONFIG_EFI``

* ``CONFIG_EFIVAR_FS``

The ``CONFIG_EFIVAR_FS`` option exports the UEFI global variables in
``/sys/firmware/efi/efivars``.

For more about configuring Linux for UEFI see `uefi.txt
<https://www.kernel.org/doc/Documentation/x86/x86_64/uefi.txt>` in the
kernel documentation.

UEFI User Space Tools
^^^^^^^^^^^^^^^^^^^^^

ONIE requires a few additional user space tools to inter-operate in a
UEFI environment.

``efibootmgr`` and ``efivar``
'''''''''''''''''''''''''''''

The `efibootmgr(8) <https://github.com/rhinstaller/efibootmgr>`_
utility is used to manipulate the UEFI global variables.  In
particular the following variables are modified:

* ``Boot####`` -- A boot load option.  #### is a printed hex value.

* ``BootOrder`` -- The ordered list of Boot#### load options.  The
  firmware attempts to boot each load option in turn, starting with
  the first entry.

* ``BootNext`` -- The boot entry to use for the next boot only.  This
  option is used to load a boot option once, then returning to the
  order specified in ``BootOrder``.

See section 3.2 of the UEFI specification for more about these
variables.

The efibootmgr utility depends on the `efivar library
<https://github.com/rhinstaller/efivar>`_, which must also be present
in the ONIE runtime.

FAT File System Support and Tools
'''''''''''''''''''''''''''''''''

The UEFI specification requires the use of the FAT file system for the
`EFI System Partition (ESP)
<http://en.wikipedia.org/wiki/EFI_System_partition>`_.  See section
12.3 of the UEFI specification for more about the ESP.

As such the ONIE image requires tools for creating, maintaining and
mounting FAT file systems.  The following tools are required to be
present:

* ``mkfs.vfat``  -- create a FAT file system
* ``fsck.vfat``  -- check and repair FAT file systems

UEFI x86 Boot Loader (GRUB-x86_64-efi)
======================================

For UEFI systems, ONIE will continue to use the `GRUB2
<http://www.gnu.org/software/grub/>`_ boot loader, albeit in a rather
different manner than legacy BIOS systems.  For UEFI systems ONIE uses
GRUB-x86_64-efi, which is GRUB2 compiled for UEFI x86_64 platforms.
GRUB-x86_64-efi does not install data into the disk MBR, as was the
case for legacy GRUB-i386-pc.  Rather each OS (ONIE included) installs
its boot loader into a sub-directory of the EFI System Partition.

This section describes how ONIE uses GRUB-x86_64-efi and how the hard
disk is partitioned.  Further mentions of *GRUB* in this document will
mean GRUB-x86_64-efi, unless otherwise specified.

Disk Partition Layout
^^^^^^^^^^^^^^^^^^^^^

The disk partition layout plays a critical role in how ONIE and the
installed NOS cooperate. This section describes the layout and the
guidelines by which ONIE and the NOS must abide.

The Demo OS Installer and Demo OS Runtime that ships with ONIE
exercise all of the steps described in this section.  See
:ref:`demo_os` for more about the Demo OS.

Partition Table Format
''''''''''''''''''''''

The UEFI specification strongly recommends the use of the `GUID
Partition Table <http://en.wikipedia.org/wiki/GUID_Partition_Table>`_
(GPT) partition table format and ONIE will require that
recommendation.

GPT is the only partition type supported by ONIE on UEFI.

EFI System Partition (ESP)
''''''''''''''''''''''''''

Traditionally the first partition on a UEFI disk is the EFI System
Partition (ESP).  The UEFI specification dictates that this partition:

* Use the GPT partition type GUID ``C12A7328-F81F-11D2-BA4B-00A0C93EC93B``
* Contain a FAT32 file system
* Contain a directory nameed ``EFI``

In the case of ONIE, the UEFI boot application is GRUB2 and the UEFI
application path looks like::

  EFI/onie/grubx64.efi

ONIE-BOOT Partition
'''''''''''''''''''

Similar to the legacy BIOS ONIE implementation, a separate ONIE-BOOT
partition contains the ONIE kernel and initramfs.  Just as in the
legacy BIOS case this partition uses the GPT partition type GUID
``7412F7D5-A156-4B13-81DC-867174929325``.

.. note::

  The ONIE-BOOT partition type GUID,
  ``7412F7D5-A156-4B13-81DC-867174929325``, is recognized by the
  ``gdisk`` and ``sgdisk`` utilities from the `GPT fdisk package
  <http://www.rodsbooks.com/gdisk/>`_.

Initial ONIE Install
^^^^^^^^^^^^^^^^^^^^

ONIE is installed in the factory via the network using PXE or via a
directly attached USB flash drive.  During the installation, the ONIE
installer reinitializes the primary hard disk, erasing all previous
partitions and data.

The following example assumes the hard disk is available as
``/dev/sda`` from Linux.

During the initial disk provisioning, the ONIE installer performs the
following operations:

#.  Creates an empty GPT partition table on the disk

#.  Creates the ESP with appropriate GPT partition type GUID and FAT32
    file system

#.  Mounts the ESP on the traditional ESP mount point in Linux:
    ``/boot/efi``
    
#.  Creates the required ``EFI`` directory on the ESP,
    i.e. ``/boot/efi/EFI``.

#.  Creates the ``ONIE-BOOT`` partition with appropriate GPT partition
    type GUID

#.  Mounts the ONIE-BOOT partition on ``/mnt/onie-boot``

#.  Installs the ONIE kernel and initramfs into the ``ONIE-BOOT``
    partition

#.  Installs the UEFI version of GRUB into ``/boot/efi/EFI/onie/grubx64.efi``

#.  Installs the GRUB modules and GRUB configuration files into ``/mnt/onie-boot/grub``

#.  Creates a new UEFI ``Boot####`` entry for ``/boot/efi/EFI/onie/grubx64.efi``

#.  Modifies the UEFI ``BootOrder`` variable to boot ONIE first

After installing ONIE, the disk layout looks like::

  +========================+
  |                        |
  |  /dev/sda1 ESP         |  <-- EFI System Partition
  |                        |
  +========================+
  |                        |
  |  /dev/sda2 ONIE-BOOT   |  <-- ONIE partition.  Installed by ONIE.  Contains
  |                        |      kernel, initramfs and grub configuration.
  +========================+
  |                        |
  |                        |
  /  Free Space            /
  |                        |
  |                        |
  +========================+

and the contents of ``/boot/efi`` looks like::

  /boot/efi                         <-- mount point
  /boot/efi/EFI                     <-- required UEFI directory
  /boot/efi/EFI/onie                <-- ONIE OS directory
  /boot/efi/EFI/onie/grubx64.efi    <-- ONIE's GRUB UEFI boot Application

The UEFI ``BootOrder`` and ``BootCurrent`` variables contain::

  BootCurrent: 0003
  BootOrder: 0003,0000,0001,0002
  Boot0000* EFI DVD/CDROM
  Boot0001* EFI Network
  Boot0002* EFI Internal Shell
  Boot0003* ONIE: Open Network Install Environment

.. note::  

  UEFI firmware locates a boot program from the ESP.  The disk MBR is
  not used in this scheme, as was the case for legacy BIOS systems.
 
  The philosophy here is that the installed NOS creates whatever
  partitions it needs and installs its UEFI boot loader program into
  ``/boot/efi/EFI/<OS>/`` in the ESP.
  
  Following that the NOS creates a new UEFI ``Boot####`` entry for the
  NOS.  This allows multiple operating systems to coexist on a single
  hard disk.
 
  See section 12.3.1.3 of the UEFI specification for more on the
  directory structure of the ESP.

The initial ONIE GRUB menu looks like this::

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

NOS Installer
=============

Continuing the example above, this section examines the
responsibilities and operations of a NOS installer.  The NOS installer
operations are very similar to the ONIE installer case, except that
the ESP already exists at this time.

A NOS installer performs the following operations:

#.  Creates partitions(s) and file systems to contain the NOS runtime
    files.

#.  Installs the NOS files (kernels, initramfs, etc) into its
    partition(s).

#.  Installs a UEFI boot loader program into ``/boot/efi/EFI/<NOS>/<NOS loader image>``

#.  Creates a new UEFI ``Boot####`` entry for ``/boot/efi/EFI/<NOS>/<NOS loader image>``

#.  Modifies the UEFI ``BootOrder`` variable to boot the NOS first.

#.  For GRUB based operating systems, create a `:ref:chainload_onie`
    for ONIE.

As an example consider the case where the user installs CentOS into
the remaining free space.

The disk now looks like::

  +========================+
  |                        |
  |  /dev/sda1 ESP         |  <-- EFI System Partition
  |                        |
  +========================+
  |                        |
  |  /dev/sda2 ONIE-BOOT   |  <-- ONIE partition.  Installed by ONIE.  Contains
  |                        |      kernel and initramfs.
  +========================+
  |                        |
  |                        |
  /  /dev/sda3 CentOS      /  <-- CentOS partition.  Installed by CentOS.  Contains
  |                        |      kernel, initramfs and GRUB configuration.
  |                        |
  +========================+

and the contents of ``/boot/efi`` looks something like::

  /boot/efi                         <-- mount point
  /boot/efi/EFI                     <-- required UEFI directory
  /boot/efi/EFI/fedora              <-- Fedora OS directory
  /boot/efi/EFI/fedora/grubx64.efi  <-- Fedora's GRUB UEFI Application
  /boot/efi/EFI/onie                <-- ONIE OS directory
  /boot/efi/EFI/onie/grubx64.efi    <-- ONIE's GRUB UEFI Application

The UEFI BootOrder and BootCurrent variables contain::

  BootCurrent: 0004
  BootOrder: 0004,0003,0000,0001,0002
  Boot0000* EFI DVD/CDROM
  Boot0001* EFI Network
  Boot0002* EFI Internal Shell
  Boot0003* ONIE: Open Network Install Environment
  Boot0004* CentOS

.. note::

  CentOS installed its version of GRUB in /boot/efi/EFI/fedora,
  without disturbing the ONIE partition or files.

.. _chainload_onie:

Chainloading ONIE
=================

A NOS that uses GRUB may find it useful to create a GRUB menu entry
for ONIE.  This menu entry is useful when the user wants to manually
select the GRUB menu entry.  This method of using one GRUB menu entry
to load and boot another boot loader is called *chainloading*.

An ONIE implementation *must* provide a GRUB helper script that
creates an appropriate ONIE GRUB chainload entry for the NOS GRUB
configuration.  The ONIE repo provides the script `50_onie_grub
<https://github.com/opencomputeproject/onie/blob/master/installer/x86_64/grub.d/50_onie_grub>`_
for this purpose.

This script is suitable for placement into the ``/etc/grub.d`` directory
in the NOS.  The ``update-grub(8)`` command, used by many operating
system providers, uses the helper script when re-generating the
``grub.cfg`` file.

Continuing the previous example, with the ONIE chainload menu entry in
place, the GRUB menu for CentOS looks something like this after a
reboot::

     GNU GRUB  version 2.02~beta2+e4a1fe391

  +-----------------------------------------------+
  |*CentOS 6.5-x86_64                             | 
  | ONIE                                          |
  |                                               |
  |                                               | 
  +-----------------------------------------------+

This is an example of what the ONIE chainload GRUB-x86_64-efi menu entry looks
like::

  # Menu entry to chainload ONIE UEFI
  menuentry ONIE {
          set root='(hd0,gpt1)'
          search --no-floppy --fs-uuid --set=root 9A49-4F6B
          echo    'Loading ONIE ...'
          chainloader /EFI/onie/grubx64.efi
  }

The Demo OS installer goes through installing GRUB-x86_64-efi and
creating an initial ``grub.cfg`` file that chainloads ONIE.  See
`:ref:demo_os` for more about the Demo OS.

UEFI ONIE NOS Interface
=======================

The ONIE NOS interface for UEFI is very similar to the existing
`:ref:x86_nos_interface` for legacy BIOS system, differing only in the
implementation details.

To review, the NOS must be able to launch ONIE in following modes:

* ``install``

* ``uninstall``

* ``rescue``

* ``update``

* ``embed``

ONIE Boot Modes
^^^^^^^^^^^^^^^

From the NOS, rebooting into a particular ONIE boot mode is a two step
process:

#. Configure the system to boot into ONIE on the next boot

#. Configure the ONIE boot loader to select the request mode

To facilitate a one-time reboot into ONIE, a UEFI system sets the UEFI
``BootNext`` variable to the ``Boot####`` boot entry corresponding to
ONIE.  When set, this variable causes the UEFI boot manager to boot
the requested boot option one time only, returning to the order
specified by ``BootOrder`` for subsequent boots.

To select the "ONIE mode", the NOS uses a tool provided by ONIE called
``onie-boot-mode``, just as in the legacy BIOS case. See
`:ref:cmd_onie_boot_mode` for more about the ``onie-boot-mode``
command.

Hardware Diagnostics Operating System (Optional)
================================================

A hardware diagnostics operating system (HDOS) is treated much like a
regular NOS.  The same concepts of creating partitions and updating
UEFI boot variables apply to a HDOS.

The primary way HDOS installers differ from regular NOS installers is
in the creation of the GPT partition.

.. _hdos_disk_partition:

HDOS Disk Partitioning
^^^^^^^^^^^^^^^^^^^^^^

A HDOS installer on a UEFI firmware machine must implement the
following:

* name the diagnostic GPT partition ``<SOMETHING>-DIAG``. See the
  `sgdisk <http://www.rodsbooks.com/gdisk/sgdisk.html>`_ program and
  the ``--change-name`` option for details. The ``<SOMETHING>`` can be
  any string that makes sense for the hardware vendor.

* set the GPT ``system partition`` attribute bit (bit 0). See the
  `sgdisk <http://www.rodsbooks.com/gdisk/sgdisk.html>`_ program and
  the ``--attributes`` option.

* when creating the file system on the diag partition set the file
  system label to ``<SOMETHING>-DIAG``, the same string as used for
  the GPT partition label. See the
  `mkfs.ext4 <http://linux.die.net/man/8/mkfs.ext4>`_ program and the
  ``-L`` option as an example.

The ``-DIAG`` suffix for the GPT partition name and the GPT ``system
partition`` bit announce to ONIE and ONIE compliant NOS installers that
the partitions are *precious* and must not be modified.

The ONIE ``uninstall`` operation must *not* remove or modify partitions
that meet the above requirements.

An ONIE compliant NOS must *not* remove or modify partitions that meet
the above requirements.

GRUB Considerations
^^^^^^^^^^^^^^^^^^^

This section examines the responsibilities and operations of a ONIE
compliant HDOS installers.  This is very similar to the NOS installer
operations discussed previously.

A HDOS installer performs the following operations:

#.  Creates a disk partition and file system as described in
    `:ref:hdos_disk_partition`.

#.  Installs the HDOS files (kernels, initramfs, diagnostic programs,
    etc) into the -DIAG partition

#.  Installs a UEFI boot loader program into
    ``/boot/efi/EFI/<HDOS>/<HDOS loader image>``

#.  Creates a new UEFI ``Boot####`` entry for
    ``/boot/efi/EFI/<HDOS>/<HDOS loader image>``

#.  Add an ONIE chain load entry to the HDOS's GRUB menu

As an example consider the case where the hardware manufacture
installs the HDOS immediately after installing ONIE.

The disk now looks like::

  +========================+
  |                        |
  |  /dev/sda1 ESP         |  <-- EFI System Partition
  |                        |
  +========================+
  |                        |
  |  /dev/sda2 ONIE-BOOT   |  <-- ONIE partition.  Installed by ONIE.  Contains
  |                        |      kernel and initramfs.
  +========================+
  |                        |
  |                        |
  /  /dev/sda3 HDOS-DIAG   /  <-- HDOS partition.  Contains kernel, initramfs,
  |                        |      diagnostic programs and GRUB configuration.
  |                        |
  +========================+

and the contents of ``/boot/efi`` looks something like::

  /boot/efi                         <-- mount point
  /boot/efi/EFI                     <-- required UEFI directory
  /boot/efi/EFI/HDOS                <-- HDOS directory
  /boot/efi/EFI/HDOS/grubx64.efi    <-- HDOS's GRUB UEFI Application
  /boot/efi/EFI/onie                <-- ONIE OS directory
  /boot/efi/EFI/onie/grubx64.efi    <-- ONIE's GRUB UEFI Application

The UEFI BootOrder and BootCurrent variables contain::

  BootCurrent: 0003
  BootOrder: 0003,0004,0000,0001,0002
  Boot0000* EFI DVD/CDROM
  Boot0001* EFI Network
  Boot0002* EFI Internal Shell
  Boot0003* ONIE: Open Network Install Environment
  Boot0004* HDOS

.. note::

  The string 'HDOS', as used above in the ESP and BootOrder variable,
  is only an example.  Any string is acceptable as long as the HDOS
  disk partitioning requirements are met.

.. note::

  After installing the HDOS, notice that the system is still
  configured to boot ONIE next.  The intention here is that the system
  shipped from the factory is set to boot ONIE in installer mode.

An ONIE compliant HDOS *should* use the provided GRUB helper script,
`50_onie_grub
<https://github.com/opencomputeproject/onie/blob/master/installer/x86_64/grub.d/50_onie_grub>`_,
to create the appropriate ONIE GRUB chainload entry for the HDOS GRUB
configuration.  This adds an ``ONIE`` GRUB menu entry to the HDOS GRUB
menu *and* adds a ``DIAG`` GRUB menu to the ONIE GRUB menu.

Following this the HDOS GRUB menu will look something like::

     GNU GRUB  version 2.02~beta2+e4a1fe391

  +-----------------------------------------------+
  |*Hardware Vendor Diag                          | 
  | ONIE                                          |
  |                                               |
  |                                               | 
  +-----------------------------------------------+

and the ONIE GRUB menu will look something like::

      GNU GRUB  version 2.02~beta2+e4a1fe391

  +---------------------------------------------+
  |*ONIE: Install OS                            | 
  | ONIE: Rescue                                |
  | ONIE: Uninstall OS                          |
  | ONIE: Update ONIE                           |
  | ONIE: Embed ONIE                            |
  | Hardware Vendor Diag                        |
  |                                             |
  +---------------------------------------------+

.. _x86_uefi_references:

UEFI References
===============

* `UEFI Home Page <http://www.uefi.org/>`_

* `GUID Partition Table <http://en.wikipedia.org/wiki/GUID_Partition_Table>`_

* `UEFI boot: how does that actually work, then? <https://www.happyassassin.net/2014/01/25/uefi-boot-how-does-that-actually-work-then/>`_

* `Demystifying UEFI, the long-overdue BIOS replacement <http://www.extremetech.com/computing/96985-demystifying-uefi-the-long-overdue-bios-replacement>`_

* `The EFI System Partition and the Default Boot Behavior <http://blog.uncooperative.org/blog/2014/02/06/the-efi-system-partition/>`_
