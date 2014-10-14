.. Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. _testing_guide:

Testing Guide
=============

When porting ONIE to a new platform, use the tests in this section to
verify the ONIE implementation. The demo NOS described previously can
be used to exercise the ONIE functionality.

The tests in this section assume you have compiled ONIE and installed
it on the target hardware.

ONIE Install Operations
-----------------------

These tests exercise the ability of ONIE to locate and install an NOS.

.. _locally_attached_network_test:

Locally Attached Network Install
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This test exercises the ability of ONIE to locate an installer image
over the network.

Using a locally attached HTTP server, verify the following:

#. The machine boots.
#. The Ethernet management interface is configured.
#. The machine downloads the demo NOS installer.
#. The machine installs the demo NOS.
#. The machine reboots into the demo NOS.

See :ref:`quick_start_guide` for more on how to configure a HTTP
server and set up the directly attached network.

Locally Attached File System Install (USB Memory Stick)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If the platform does **not** have a USB port, skip this test.

This test exercises the ability of ONIE to locate an installer image
on a locally attached file system.  The primary use case is when an
installer image is located on the root directory of a USB memory
stick.

Follow these steps:

#. Power off the switch.
#. Copy the demo NOS installer to the root directory of a USB memory
   stick.  Use the file names described in :ref:`default_file_name`.
#. Insert the USB memory stick into the switch's USB port.
#. Turn on the switch power.

Verify the following:

#. The machine boots.
#. The USB memory stick is detected.
#. The machine installs the demo NOS from the USB memory stick.
#. The machine reboots into the demo NOS.

To verify the memory stick is detected, you can inspect the output of
the ``dmesg`` command looking for your USB device.  Also you can
inspect the contents of the ``/proc/partitions`` file.

ONIE / NOS Interface Commands
-----------------------------

These tests exercise the interfaces between the NOS and ONIE.  See
:ref:`nos_interface` for more on these interfaces.

Use the previously described demo NOS commands to exercise the
ONIE-NOS interface.

Install / Re-Provision
^^^^^^^^^^^^^^^^^^^^^^

From the demo NOS prompt, verify the ``install`` command works
correctly. See :ref:`demo_nos_reinstall` for more about this command.

After issuing this command, you should verify the following happens:

#. The machine reboots.
#. After the reboot, ONIE starts in ONIE installer mode.

Rescue Mode
^^^^^^^^^^^

From the demo NOS prompt, verify the ``rescue`` command works
correctly. See :ref:`demo_nos_rescue` for more about this command.

After issuing this command, you should verify the following happens:

#. The machine reboots.
#. After the reboot, ONIE starts in ONIE rescue mode.

Uninstall
^^^^^^^^^

From the demo NOS prompt, verify the ``uninstall`` command works
correctly.  See :ref:`demo_nos_uninstall` for more about this command.

After issuing this command you should verify the following happens:

#. The machine reboots.
#. After the reboot, ONIE starts in ONIE uninstall mode.
#. The mass storage device(s) are erased.
#. After uninstalling, the machine reboots again.
#. The machine detects a corrupt U-Boot environment and writes a new
   default environment.
#. The machine boots into ONIE installer mode.

ONIE Update
^^^^^^^^^^^

This test is very similar to the :ref:`locally_attached_network_test`,
except in this case ONIE is trying to locate and run an ONIE updater
instead of a NOS installer.

For more on updating ONIE and the default ONIE updater file names, see
:ref:`updating_onie`.

From the demo NOS prompt, verify the ``update`` command works
correctly. See :ref:`demo_nos_update` for more about this command.

After issuing this command you should verify the following happens:

#. The machine reboots.
#. After the reboot, ONIE starts in ONIE update mode.
#. The Ethernet management interface is configured.
#. The machine downloads the ONIE updater.
#. The machine installs the ONIE updater.
#. The machine reboots into the demo NOS.

Testing Infrastructure
======================

A testing framework is located in the ``test`` sub-directory.  At the
moment, documentation is sparse.  Here's the layout::

  test
  ├── bin
  │   └── test-onie.py
  ├── lib
  │   ├── connection.py
  │   ├── dut.py
  │   ├── power.py
  │   ├── test_base.py
  │   └── test_utils.py
  ├── site.conf
  └── tests
      ├── __init__.py
      └── test_u_boot.py

=========================    =======
File                         Purpose
=========================    =======
test/bin/test-onie.py        The main program entry point
test/lib                     Some base classes for DUTs, connections, power
test/lib/connection.py       Class for connections, serial console servers
test/lib/dut.py              DUT base class
test/lib/power.py            Class for dealing with remote PDUs
test/lib/test_base.py        Base class for tests
test/lib/test_utils.py       Misc utility functions
test/tests                   The "tests"
test/tests/test_u_boot.py    Tests involving U-Boot
test/site.conf               Config file for various DUTs and options
=========================    =======

The Makefile in ``build-config/Makefile`` contains a ``test`` target
that runs ``bin/test-onie.py`` with various parameters.

See ``test/tests/test_u_boot.py`` for an example of writing a test.
