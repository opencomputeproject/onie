.. Copyright (C) 2015,2016,2017 Carlos Cardenas <carlos@cumulusnetworks.com>
   Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

*********************
Certification Process
*********************

`Test Report Form <http://files.opencompute.org/oc/public.php?service=files&t=c81b4a02ad7d1b5b6de16ca2935fa3cc>`_

The certification of ONIE (starting with 2014.08) has the following
processes.

Prerequisites
=============

* ONIE image must be based on an ONIE release (i.e. 2014.08, 2014.11, etc...)
* ONIE images for the device is openly available on the vendor's website (not behind a pay wall and not requiring a login)
* ONIE source code for the device is open available

  * preferably in the main ONIE repository on `GitHub <https://github.com/opencomputeproject/onie>`_

* Ensure all other requirements are met as described in :ref:`switch_hw_requirements`
* It might be a good idea to use `ONIE Compliance Environment (OCE) <https://github.com/opencomputeproject/onie/tree/master/contrib/oce>`_ and ensure all tests are passing.  This is the same tool the OCP lab will be using.

Logistics
=========

.. warning::

  If you have not met the Prerequisites, do not proceed with the
  following until it has all been met.  No exceptions will be made.

* Submit device(s) to ONIE certification lab at UNH-IOL

  * *NOTE:* the device is not returnable as this device will be used
    for all future ONIE certifications (on vendor's request)

  * The recommended number of devices is 3 per SKU to ensure a working
    model for the lifetime of the device.  However, 1 per SKU is
    acceptable **if** the vendor is able to provide parts (RMA) for
    the lifetime of the device.

  * If the device is able to take a different CPU module complex to
    make another SKU, then a separate set of device(s) must be
    submitted.  The lab will not be swapping out CPU module complexes
    to test a different SKU.

* Once the device has been received, testing will begin no later than
  5 business days.

* Normal testing results should be available no later than 5 business
  days after testing has begun

  * Test results will be sent directly to the vendor and OCP
    Certification Director (only if device has passed)

  * Test results are the following

    * `High Level Excel Report <http://files.opencompute.org/oc/public.php?service=files&t=c81b4a02ad7d1b5b6de16ca2935fa3cc>`_
    * All screen logs
    * OCE output logs

* OCP Foundation will issue certification voucher to vendor upon verification

* Vendor is now able to use ONIE Certified logo on website and marketing collateral.

Certification Notes
===================

ONIE version specific notes and exceptions are noted here.

ONIE Release 2014.08, 2014.11, 2015.02
--------------------------------------

Test cases 10, 11, 12, 46, 47, and 48 will be marked as **N/A** as
those releases of ONIE contained a bug that prevents compliance.  ONIE
release **2015.02.01** corrects this behavior.

ONIE Release 2015.08 and Beyond
-------------------------------

Starting with ONIE Release **2015.08**, the following new tests were
added for features `#219
<https://github.com/opencomputeproject/onie/pull/219>`_ (using well
known server name) and `#222
<https://github.com/opencomputeproject/onie/pull/222>`_ (using IV4
Link Local address RFC-3927): 80 to 109 (30 new tests).

ONIE Release 2016.05 and Beyond
-------------------------------

Starting with ONIE release **2016.05**, 18 more tests were added for
the new image naming scheme described in :ref:`default_file_name` )
along with test number realignment.

ONIE Releases Prior to 2017.05
-------------------------------

For ONIE Release prior to **2017.05**, Tests 13 and 73 will be marked
as **N/A** as those releases of ONIE contained a bug that prevents
compliance.  ONIE release **2017.05** corrects this behavior.
