.. Copyright (C) 2015,2016,2017 Carlos Cardenas <carlos@cumulusnetworks.com>
   Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

**************
NOS Validation
**************

NOS validation refers to the idea that a NOS must cooperate in an
ONIE-enable system in an appropriate manner.  NOS validation verifies
that a NOS respects the ONIE interface, without corrupting the ONIE
environment for other operating systems.

Testing Environment
===================

In order to perform NOS validation against an ONIE device, the following is required:

* Demo OS for given platform
* ONIE ready NOS (referred to as a NOS Under Test or NUT)
* ONIE Certified Device from 2015.05 or later (referred to as Device Under Test or DUT)
* HW Vendor provided serial console cable (for device interaction and recording of session)
* CAT5/CAT6 RJ45 (for image discovery and delivery)
* PC with serial terminal and RJ45 NIC

Recommended Environment - Linux
-------------------------------

* Latest Linux distribution (e.g. Debian) with IPv6 enabled
* `OCE <https://github.com/opencomputeproject/onie/blob/master/contrib/oce/README.md>`_ properly installed and configured

  * In particular `test-onie.py <https://github.com/opencomputeproject/onie/blob/master/contrib/oce/README.md#testing-onie>`_ and `test-nos.sh <https://github.com/opencomputeproject/onie/blob/master/contrib/oce/README.md#testing-a-nos>`_

* ``screen(1)`` or ``minicom(1)``

  * 115200 baud 8N1, no flow control (unless otherwise specified by DUT)
  * Logging enabled

Recommended Environment - Windows
---------------------------------
* Latest Windows 8.1 Update with patches
* PuTTY or Tera Term

  * 115200 baud 8N1, no flow control (unless otherwise specified by DUT)
  * Logging enabled

* `OCE <https://github.com/opencomputeproject/onie/blob/master/contrib/oce/README.md>`_ properly installed and configured

  * In particular `test-onie.py <https://github.com/opencomputeproject/onie/blob/master/contrib/oce/README.md#testing-onie>`_ and `test-nos.sh <https://github.com/opencomputeproject/onie/blob/master/contrib/oce/README.md#testing-a-nos>`_

Objectives
==========

This program is to ensure a NUT on a given DUT adheres to the software
contract provided by ONIE to the NOS.  In short, the NOS *shall* obey
the contract which includes:

* No Modification to ONIE (files, partition layout, etc...)
* The ability for a user to uninstall a NOS and install another NOS
* The ability for a user to update ONIE after a NOS has been installed
* The ability for a user to enter ONIE's rescue mode after a NOS has been installed
* The ability for a user to install and uninstall a NOS and update ONIE when a Diagnostic Image is present on a DUT

Tests
=====

Baseline
--------

Starting with a DUT with no NOS installed, record the state of the DUT
using ``test-nos.sh -c init``.  The output of the script will indicate
if a Diagnostic NOS (DIAG) is present on the DUT.  This information
will need to tracked throughout the rest of the tests to ensure the
DIAG is present and able to be invoked by the user.

.. important:: PASS Criteria: ONIE state successfully recorded. Test 0.

NOS Install
-----------

From the baseline DUT, install the NUT using OCE.  Once the
installation is complete, boot into ONIE rescue mode via ``GRUB`` for
x86_64 or ``U-boot`` on others.  In ONIE, perform ``test-nos.sh -c
check``.  Ensure no changes to ONIE have occurred (outside of
additional GRUB entries for NUT).

.. important:: PASS Criteria: NUT installation does not alter ONIE. Test 1.

NOS Uninstall
-------------

From the DUT with the installed NUT, perform an ONIE uninstall from the following areas:

* From within the NUT (**Test 2**)
* From within ONIE rescue (**Test 3**)
* From ``GRUB`` ONIE Uninstall target or ``run onie_uninstall`` from ``U-boot`` (**Test 4**)

At the end of all of those uninstall targets, ensure ``test-nos.sh -c check``
results in no changes.  E.g. ONIE is back into the baseline state.

.. important:: PASS Criteria: NUT uninstallation does not alter ONIE. Tests 2 - 4.

Demo OS Install
---------------

From the baseline DUT, install the Demo OS using OCE.  Once the
installation is complete, boot into ONIE rescue mode via ``GRUB`` for
x86_64 or ``U-Boot`` on others.  In ONIE, perform ``test-nos.sh -c
check``.  Ensure no changes to ONIE have occurred (outside of
additional GRUB entries for Demo OS).

.. important:: PASS Criteria: Demo OS installation does not alter ONIE. Test 5.

Demo OS Uninstall
-----------------

From the DUT with the installed Demo OS, perform an ONIE uninstall from the following areas:

* From within the Demo OS (**Test 6**)
* From within ONIE rescue (**Test 7**)
* From ``GRUB`` ONIE Uninstall target or ``run onie_uninstall`` from ``U-boot`` (**Test 8**)

At the end of all of those uninstall targets, ensure ``test-nos.sh -c
check`` results in no changes.  E.g. ONIE is back into the baseline
state.

.. important:: PASS Criteria: Demo OS uninstallation does not alter ONIE. Tests 6 - 8.

ONIE Self Update
----------------

From the DUT with the installed NUT, perform an ONIE Self Update from the following areas using OCE:

* From within the NUT (**Test 9**)
* From within ONIE rescue (**Test 10**)
* From ``GRUB`` ONIE Update target or ``run onie_update`` from ``U-boot`` (**Test 11**)

At the end of all of those update targets, perform ``test-nos.sh -c
init`` as ONIE files are modified. Record the state of the DUT.  This
is the new baseline state.

.. important:: PASS Criteria: ONIE is able to perform update with the NOS fully functional. Tests 9 - 11.

ONIE Rescue Mode
----------------

From the DUT with the installed NUT, perform an ONIE Rescue from the following areas:

* From within the NUT (**Test 12**)
* From ``GRUB`` ONIE Rescue target or ``run onie_rescue`` from ``U-boot`` (**Test 13**)

At the end of all of those rescue targets, ensure ``test-nos.sh -c
check`` results in no changes.  E.g. ONIE is back into the baseline
state.  If a DIAG was present on the box for the Baseline, ensure the
DIAG is still present on the DUT and is able to be invoked by the
user.

.. important:: PASS Criteria: ONIE is able to perform update with the NOS fully functional. Tests 12 and 13.
