.. _updating_onie:

*************
Updating ONIE
*************

ONIE provides a way to update itself, including the boot loader and
Linux kernel. In many ways this behaves similarly to the discovery and
installation phase, except that ONIE is looking for a different kind
of image.

When compiling ONIE one of the build products is an ONIE updater.  See
the :ref:`onie_build_products` table.

To update ONIE you follow a procedure similar to installing a network
OS, except instead of using a network OS installer use the ONIE
updater.  Also a few details are different as described next.

Start ONIE in Update Mode
=========================

First to initiate ONIE update mode follow the steps described in the
network OS interface :ref:`nos_intf_updating_onie` section.  This
launches ONIE in update mode.

Specifying Updater URL
======================

All of the methods for discovering a network OS installer from the
:ref:`installer_discovery` section also apply to discovering an ONIE
updater image, with a few exceptions.

The default updater image name that ONIE looks for is::

  onie-updater-${onie_machine}-${onie_arch}

Another difference is when using DHCP :ref:`dhcp_vivso` you must set
option 2 ``Updater URL`` to specify the updater URL.

Also as described in the :ref:`rescue_recovery` section you can use
the ``updater_url`` command to specify an updater URL from rescue
mode.
