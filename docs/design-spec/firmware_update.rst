.. Copyright (C) 2016,2017 Curt Brune <curt@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. _firmware_updates:

****************
Firmware Updates
****************

One of the goals of the ONIE project is to operate at scale.  On
occasion a hardware vendor has the need to update the "firmware" on
existing hardware platforms in the field.  ONIE provides a mechanism
that allows end customers to deploy firmware updates provided by HW
vendors at scale.

For the purposes of this section, firmware is defined as:

- the ONIE software (kernel + initramfs), everything in an ONIE
  updater image, set ref:`update_image_format`.

- BIOS / UEFI firmware.  The data that lives in an 8MB SPI-ROM on most
  x86 platforms.

- CPLD programs.  Most platforms have some number of CPLDs (3 seems
  typical) that require updates.  CPLDs are typically upgraded via
  JTAG I/O signals, usually connected to a GPIO controller on the CPU
  complex.

Firmware Updates Happen in ONIE Context
=======================================

Historically firmware update images are often delivered to customers
as executables for a particular operating system.  That places a
rather large burden on the hardware vendor to provide firmware update
images for many different operating system flavors.

For ONIE enabled hardware, firmware updates happen in the context of
ONIE.  In other words the update is *applied* while the ONIE kernel is
running, using tools from the ONIE system.

The reasons for supporting this strategy:

- HW vendors own ONIE, so they can add necessary drivers and tools to
  the base ONIE image.

- HW vendors own firmware updates.  They know what their firmware
  updates require.

- ONIE context is NOS agnostic.  No need to write firmware update
  images for various operating systems.

- ONIE context provides the HW vendors a stable environment to develop
  and test their updates.

Automating Firmware Updates
===========================

Firmware update images behave just like ONIE self-update images, using
the same image discovery mechanisms described in :ref:`specify_updater_url`.
Using the same image discovery mechanisms allows firmware updates to
be deployed at scale.

Firmware Update Flow
====================

The work flow of a firmware update within ONIE goes as follows:

- Stage firmware update for processing from the NOS
- Reboot into ONIE update mode
- The update is applied within ONIE context
- The system reboots, returning to the previous boot state

The update should not require a re-install of the NOS or wipe out any
partitions.

.. note::

  Depending on the hardware platform and the firmware being updated,
  sometimes a reboot is not sufficient.  For example a COLD boot is
  required for the firmware or CPLD update to take effect.
  
  To handle this case, a firmware update can specify a reboot command
  to use, by placing an executable in ``/tmp/reboot-cmd``.  The ONIE
  firmware update framework will detect this and use it for rebooting
  the machine.  The executable could be a script that writes a CPLD
  cold boot reset register for example.

Initiating Firmware Updates from the NOS
========================================

It is possible to deploy an ONIE firmware updater image using the
existing DHCP/HTTP and waterfall methods.  The image discovery methods
are described in :ref:`image_discovery`.

In practice, however, we see that configuring the DHCP server can be
burdensome depending on the nature of the user's engineering
departments and business functions.  Sometimes one group is
responsible for the initial NOS install and another application group
is responsible for the daily use of the hardware.  Sometimes all the
machines are installed/configured in one location and then racks of
gear are shipped around to world to global data centers.

For an in field update the application group will likely be on the
front lines.

With this in mind, ONIE provides a mechanism to address the case of an
end user with multiple (say, hundreds) of switches with the NOS
already installed and configured.  The user wants to update the
firmware with minimal disruption to the systems using an existing
orchestration tool.  We should not have to re-install the NOS, nor
reconfigure the NOS as part of the firmware update.

This mechanism enables this firmware update work flow:

#. [user] downloads the firmware update image from the running NOS

#. [user] stages the firmware update in the ONIE disk partition

#. [user] reboots into ONIE update mode

#. ONIE locates and applies the firmware update

#. System reboots the system back into the NOS

The steps labeled [user] above can be automated using a devops
orchestration system, like Ansible, Puppet, Chef, etc.

Deploying firmware updates via the existing orchestration mechanism is
far easier for the application group, since that is how they do
everything.  They do not need to configure DHCP servers, etc. in this
scenario.

For more information on the tool for staging firmware updates see the
documentation for the <FIXME FIXME>.  This covers staging, unstaging
and querying information about pending firmware updates.

.. note::
 
  The staging of firmware updates is only supported for x86_64 based
  systems.  These systems have a readily available disk partition
  dedicated to ONIE, providing a storage location for staged updates.

  Other CPU types, like PowerPC and ARM, do not have a staging
  partition.  For these systems the firmware update can be applied
  using the traditional DHCP/HTTP ONIE update methods or applied
  directly at the ONIE prompt, using the ``onie-self-update`` command.

Processing Staged Firmware Updates (x86_64 only)
================================================

Once a firmware update is staged, as described in the previous
section, the ONIE run time must locate it during the update image
discovery phase.

.. note::

   On x86 systems, ONIE uses a persistent GPT partition on the mass
   storage medium signified by the GUID
   ``7412F7D5-A156-4B13-81DC-867174929325``.  When ONIE is running
   this partition is mounted as ``/mnt/onie-boot``.

A directory in the persistent ONIE partition is used for staging ONIE
update images.  This directory is called the ONIE update directory.

The update image discovery mechanism searches the ONIE update
directory for pending firmware update images and processes any images
found in lexicographical order.  This allows for processing multiple
update images at a time.

Each time an attempt is made to install an update, a "results record"
is created to track the outcome of the update.  The record includes
information about the update version and whether the update was
successful or not.  These records are stored persistently in the ONIE
partition.

The <FIXME FIXME> command has options for dumping the result records
and update status.

Example: Staging a Firmware Update From a NOS
'''''''''''''''''''''''''''''''''''''''''''''

Here are the concrete steps used to stage a firmware update from a
NOS::

  root@nos:/tmp# wget http://10.0.2.2/onie/onie-firmware-update
  root@nos:/tmp# mkdir -p /mnt/onie-boot
  root@nos:/tmp# mount LABEL=ONIE-BOOT /mnt/onie-boot
  root@nos:/tmp# /mnt/onie-boot/onie/tools/bin/onie-fwpkg add onie-firmware-update
  Staging firmware update: /tmp/onie-updater-x86_64-kvm_x86_64-r0
  root@nos:/tmp# /mnt/onie-boot/onie/tools/bin/onie-fwpkg show
  ** Pending firmware update information:
  Name                              | Version                    | Attempts |Size (Bytes)  | Date
  ==================================+============================+==========+==============+====================
  onie-firmware-update              | firmware-demo-201605031508 |        0 |     11470711 | 2016-05-03 22:29:27
  ==================================+============================+==========+==============+====================
  root@nos:/tmp# /mnt/onie-boot/onie/tools/bin/onie-boot-mode -q -o update
  root@nos:/tmp# umount /mnt/onie-boot
  root@nos:/tmp# reboot

This example shows:

- mounting the ONIE-BOOT partition, where the ONIE tools reside.

- executing the ``onie-fwpkg`` command with the ``add`` sub-command.  This
  stages the update in the ONIE-BOOT partition.

- executing the ``onie-fwpkg`` command with the ``add`` sub-command.  This
  displays any currently pending firmware updates.

- executing the ``onie-boot-mode`` command to set the system into
  ``ONIE Update`` mode for the next boot.

Next the system reboots in ``ONIE Update`` mode and the update is
applied.

Format of Firmware Update Image
===============================

The firmware update image is created just like an ONIE update image.
The image itself is an executable, traditionally written as a
self-extracting shell archive.  The additional requirement on the
firmware update image, same as the ONIE update image, is that the
image must include the string ``ONIE-UPDATER-COOKIE`` within the first
100 lines of the image.

For an example of how to create a self-extracting shell archive, see
the code for the DEMO OS installer.  In this case, instead of the
install.sh script "installing an OS", the firmware update install.sh
script would update the firmware.

In is the responsibility of the hardware vendor to include any
necessary utilities in the firmware update image.  For example any
custom programs for updating firmware would need to either be present
in the base ONIE system or provided by the installer itself.

