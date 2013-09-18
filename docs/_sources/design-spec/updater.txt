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
NOS interface :ref:`nos_intf_updating_onie` section.  This launches ONIE in 
self-update mode.

Specifying the Updater URL
==========================

All of the methods for discovering an NOS installer from the
:ref:`installer_discovery` section also apply to discovering an ONIE
updater image, with a few exceptions.

ONIE looks for the following default updater file names in order::

  onie-updater-<arch>-<platform>
  onie-updater-<platform>
  onie-updater-<arch>
  onie-updater

For the example PowerPC machine, the default updater file names would be::

  onie-updater-powerpc-VENDOR_MACHINE
  onie-updater-VENDOR_MACHINE
  onie-updater-powerpc
  onie-updater

Another difference is when using DHCP :ref:`dhcp_vivso`, you must set
option 2, ``Updater URL``, to specify the updater URL.

Also, as described in :ref:`rescue_recovery`, you can use
the ``updater_url`` command to specify an updater URL from rescue mode.
