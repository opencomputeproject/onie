*********************
x86 Interface Details
*********************

This section describes the x86-specific methods used to implement the
NOS interface.  See the :ref:`nos_interface` section for more about
the NOS interface.

.. _cmd_onie_boot_mode:

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
