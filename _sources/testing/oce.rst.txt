.. Copyright (C) 2017,2018 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2015,2016,2017 Carlos Cardenas <carlos@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

***************************
ONIE Compliance Environment
***************************

.. highlight:: none

Overview
========

ONIE Compliance Environment or OCE is a set of tools that are used for

* Automated ONIE Builds (via CI tools like Jenkins)

* Automated ONIE Testing using the same tools found in deployments

Testing ONIE from a user's perspective included naming the NOS
installer ``onie-installer``, placing it in the root location of a web server,
and letting ONIE do it's thing.  While this works, it doesn't fully test a
vendor's implementation of ONIE:

* proper HTTP Headers
* DHCP options
* Proper ONIE image discovery
* The rest of the ONIE feature set

  * Self Update
  * Rescue
  * Uninstallation of a NOS

While most of these actions can be observed and recorded by the user,
it is typically not their deployment strategy to do so.  As such, we
have a simpler way of doing so for certification labs, vendors, and
others to use the same deployment tools that an end user will use to
provide a suite of tests to ensure a HW vendor's implementation of
ONIE is compliant with the OCP specification.

test-onie.py
------------

``test-onie.py`` allows the automatic configuration and testing of a
given test from the OCP ONIE specification.

It takes a list of arguments:

* MAC address of the DUT (Device Under Test)
* IP address (in CIDR form) of the DUT
* test number

  * For NOS installs, a NOS image
  * For ONIE self update, an ONIE image

And ``test-onie.py`` takes care of the rest.  By default, ``test-onie.py``
uses the following:

* DHCP using isc-dhcp-server
* TFTP using tftpd-hpa
* HTTP using nginx

However, it is possible to change out the back end services by either
modifying the test definition file (default:
``config/onie-tests.json``) or creating a new one.

Limitations of test-onie.py
===========================

At the current time, ``test-onie.py`` cannot handle the test cases
that require power or console interaction (10 test cases in all).  It
is able to handle the remaining 70 test cases just fine.

Installing Prerequisites
========================

Before we get started, if you system is running ``apparmor``, you must
stop it and unload all the profiles.  Typically, this involves::

  # sudo service apparmor stop
  # sudo service apparmor teardown

Install the necessary backend services and have them stopped and
disabled.  Typically this involves::

  # sudo apt-get install isc-dhcp-server tftpd-hpa nginx
  # sudo stop service isc-dhcp-server stop
  # sudo stop service nginx stop
  # sudo update-rc.d -f isc-dhcp-server remove
  # sudo update-rc.d -f nginx remove

.. note:: ensure tftpd is not running in inetd or xinetd

To use ``test-onie.py``, you need to have all of the python modules,
defined in ``requirements.txt`` installed.

An easy way to do this is to use python's virtualenv.

Ensure you have ``pip`` and ``virtualenv`` installed::

  # sudo apt-get install python-pip python-virtualenv

Then create the virtual environment::

  # virtualenv .venv

Now let's enter the virtual environment and install our dependencies::

  # source .venv/bin/activate
  (.venv) # pip install -r requirements.txt

Now you are ready to run ``test-onie.py``.

Please refer to `OCE's README
<https://github.com/opencomputeproject/onie/blob/master/contrib/oce/README.md>`_
for more information on running specific test cases.
