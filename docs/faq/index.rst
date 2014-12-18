.. Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2013-2014 Pete Bratach <pete@cumulusnetworks.com>
   Copyright (C) 2013 Scott Emery <scotte@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

***
FAQ
***

.. Add questions as sections headings and the answers as the section
   body.  For really long questions, abbreviate them in the heading
   and put the entire question in the section body.

What is ONIE?
=============

ONIE is a small operating system, pre-installed as firmware on bare
metal network switches, that provides an environment for automated
provisioning.

To get started, read the :ref:`onie_overview` section.

How often is ONIE released?
===========================

ONIE is released every 3 months.  For more details, read the
:ref:`release_cycle` section.

I have a switch from vendor XYZ that does not have ONIE installed.  Can I install ONIE on it myself?
====================================================================================================

Short answer: no.

To "ONIE-ize" hardware is tricky to do correctly, highly vendor and
model specic, and fraught with peril.  There is more to an ONIE SKU
from a hardware vendor than just the installed ONIE software.

The first peril is that if the operation is not performed correctly
you are left with a dead, bricked box.  Nobody wants that.  You would
very likely need to RMA the box to your hardware supplier at this
point.

Let's assume you are a seasoned firmware / hardware developer armed
with a JTAG debugger for BIOS/U-Boot recovery.  You would likely be
able to install the ONIE software after a few attemps.  However, that
sets you up for the next problem -- the EEPROM format and contents.

The EEPROM format and contents between ONIE and non-ONIE SKUs
provided by hardware vendors is completely different.

The ONIE EEPROM format is standardized across all the hardware vendor
platforms.  This one of big accomplishments of the ONIE -- getting all
the different hardware vendors to agree on a common EEPROM format.

The EEPROM requirements are described in the
:ref:`non_volatile_board_info` section.

The EEPROM contents on non-ONIE product SKUs use the vendor's
proprietary (and different per vendor) format.  To ONIE-ize a box you
would have to migrate/translate the vendor's format/contents into the
ONIE format.  On top of that the number of MAC addresses allocated for
the device typically differs between the ONIE requirements and
non-ONIE SKUs -- you would have to allocate MAC addresses from your
own `MAC OUI
<https://en.wikipedia.org/wiki/Organizationally_unique_identifier>`_
pool.

Another thing to be aware of if you go down this path is that the
non-ONIE and ONIE product SKUs may have front panel port labeling and
FRU labeling differences.  See the ONIE labeling requirements
:ref:`fru_labeling` section, which may differ from a vendor's non-ONIE
SKU.

Why is the default console baud rate 115200?
=============================================

It is the 21st century -- time to use a reasonably fast baud rate.

Why is the Ethernet management port IPv4 address set to 192.168.3.10?
=====================================================================

``192.168.3.10`` is the default fall back IPv4 address, which is used
when no other address configuration mechanism works.  This is usually
*not* what you want and typically indicates your DHCP configuration is
not quite right.

See :ref:`onie_eth_mgmt_config` for details.


Is there a virtual machine implementation?
==========================================

Yes.  See the :ref:`x86_virtual_machine` section for details.

Is there an ONIE state transition diagram?
==========================================

The ONIE states and transitions can be a little confusing.  For a high
level overview of the states and transitions, read the :ref:`onie_fsm` section.

For more details, read the :ref:`full_design_spec` chapter.

.. _cache_packages:

Can I set up a local cache of downloaded packages ONIE needs?
=============================================================

The problem is ONIE downloads various packages as it builds.  Can we
avoid downloading things all time?  Yes we can.

To avoid downloading the packages from across the ocean you can set up
a local cache of the packages.  You would need an HTTP server on your
local development network.

To set up the local cache, read the documentation in the
``onie/build-config/local.make.example`` file.  Rename this file to
``local.make`` and the build system will use it.

In that file, set the ``ONIE_MIRROR`` variable to point at your local
HTTP server.

To set up the cache, do this:: 

  build-04:~/onie/build-config$ make download-clean 
  build-04:~/onie/build-config$ make download 

Now copy all the \*.gz \*.bz2 \*.xz files to your HTTP server.

Next set the ``ONIE_MIRROR`` variable in ``onie/build-config/local.make``
to match your HTTP server.

The ``crosstools-ng`` component also downloads a lot of packages.  It has
its own config variable, ``CROSSTOOL_ONIE_MIRROR``.  After building
kvm_x86_64 ONIE once you can find the downloaded packages here::

  onie/build/x-tools/x86_64/build/build/tarballs 

Copy all those files to your HTTP server and set the 
``CROSSTOOL_ONIE_MIRROR`` variable accordingly. 

Now you should be all set. 

The build system will still download packages, but it will be from a 
local HTTP server and will be much faster. 

Can I copy an ONIE source tree work space to another location?
==============================================================

No.  The build environment does not allow copying or moving trees
around.  When building, "stamp" files are created that use the
*absolute* path names of files. Moving an ONIE tree to another
location confuses the build system, with unexpected results.

If you do move an ONIE tree (which isn't recommended) you must first
clean out the tree by building the ``distclean`` target, like this::

  build-04:~/onie/build-config$ make distclean 

That will wipe out everything and you can proceed. 

.. note:: 

   The ``clean`` target will *not* clean up everything.  It will leave
   behind the toolchain and the downloaded packages.  The ``distclean``
   target wipes out everything.

Are there any interesting Makefile targets lurking around?
==========================================================


- download -- Downloads all the source packages, storing them in
  ``build/download``.

- demo -- Builds the demo OS and demo OS installer.

- docs -- Generates the HTML and PDF documentation.

- clean -- Wipes out all build products for a particular
  machine. Downloads and the toolchain are *preserved*.

- download-clean -- Wipes out all the downloaded packages.

- distclean -- Wipes out everything, including downloads and the toolchain.

- debian-prepare-build-host -- Installs various packages needed to
  compile ONIE on a Debian-based system, using ``apt-get install``.

