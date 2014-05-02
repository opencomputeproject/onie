.. _x86_recovery:

********************************
x86 Initial Install and Recovery
********************************

Installing ONIE on a machine with a blank hard drive poses a few
challenges.  Traditional OS installation techniques are used to
overcome this.

PXE Network Install
-------------------

How to configure a particular machine for PXE booting is beyond the
scope of this document.  However, the ONIE build system does generate
kernel and initramfs images suitable for PXE booting.

The ``recovery-initrd`` Makefile target generates an ONIE initrd that
also contains an ONIE updater image.

Assuming you have set up PXE booting a few kernel command line options
can help automate the installation of ONIE:

- ``boot_env=recovery``

- ``boot_reason``

- ``install_url``

The ``boot_env=recovery`` parameter tells the running ONIE system that
the disk is not formatted.  This keeps ONIE from trying to mount any
partitions.

The ``boot_reason`` variable can take on any of the ONIE boot modes,
but the useful ones here are ``rescue`` and ``embed``.

With ``boot_reason=rescue`` you can boot into the system and manually
use the ``onie-self-update -e /lib/onie/onie-updater`` command to
embed the ONIE updater image contained in the recovery-initrd.

.. note::

  The ``-e`` option to the ``onie-self-update`` command is required to
  **embed** ONIE.  The **embed** operation will partition and format
  the disk.

For an automatic embedding set ``boot_reason=embed`` and
``install_url=file:///lib/onie/onie-updater``.  When ONIE boots it
will automatically start embedding the ONIE updater image contained in
the recovery-initrd.

.. note::

  You can also set the ``install_url`` to any valid URL.  For example
  you could have it point to an ONIE updater image on a HTTP server.

USB Drive Install
-----------------

For machines that are capable, installing from USB can be a convenient
option.  How to configure an individual machine to boot from USB is
beyond the scope of this document.

The first step is to create an .ISO image suitable for installing on a
USB memory stick.  Build the 'recovery-iso' Makefile target.

.. note::

  The recovery-iso image can also be used to boot from a CD-ROM.

The next step is to copy the .iso image to the USB memory stick using
the ``dd`` command from a Linux workstation.

.. warning::

  This will wipe out the contents of the memory stick.

  Also make sure you use the correct /dev/sdX or else you will wipe
  out the Linux workstation.

  You can find the correct /dev/sdX by inspecting the ``dmesg`` output
  after inserting the USB stick into your work station.

Use ``dd`` to copy the .iso image to the USB stick::

  $ sudo dd if=onie-recovery-x86_64-<machine>-r0.iso of=/dev/sdX bs=10M

The memory stick is now ready to use.

When the system boots you will see the following menu::

  +-----------------------------------------------------------+
  |                       ONIE Installer                      |
  |                                                           |
  |  ONIE: Rescue                                             |
  |  ONIE: Embed ONIE                                         |
  |                                                           |

.. note::

  You can customize the kernel command line arguments by editing the
  ``onie/build-config/recovery/syslinux.cfg`` file.  See the note
  above about using the ``install_url`` kernel argument.
