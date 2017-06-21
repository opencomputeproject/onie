.. Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. _x86_hw_requirements:

*************************
x86 Hardware Requirements
*************************

For general switch hardware requirements see the
:ref:`switch_hw_requirements` section.

The hardware requirements for the x86 CPU architecture are:

====================================  =========================================
Required Hardware                     Purpose
====================================  =========================================
1GB (min) CPU DRAM                    The DRAM used by the CPU.
Mass storage 4GB(min), 16GB (rec)     GRUB, the ONIE kernel and the
                                      network OS reside in the mass
                                      storage block device.  Although
                                      4GB is the minimum size of this
                                      flash, 16GB is the recommended
                                      size.
Non-volatile board information        An EEPROM to store board information and
                                      manufacturing data, like the device
                                      serial number and network MAC address.
Ethernet management port              Required to download an operating system
                                      installer.
====================================  =========================================

For the mass storage device many possibilities exist.  The only real
requirement is that the BIOS recognizes the device as bootable.  Some
possibilities are:

- mSATA
- CFast
- SATA SSD
- USB NAND

System BIOS and the SMBIOS/DMI standard
=======================================

A defacto standard for managing x86 servers is the `SMBIOS
<http://www.dmtf.org/standards/smbios>`_ and `DMI
<http://www.dmtf.org/standards/dmi>`_ data stored in the system BIOS.
Under Linux the `dmidecode <http://www.nongnu.org/dmidecode/>`_
utility is used to access this data.

For mega-scale data centers the DMI information is a key component for
automation and configuration management.  All the major automation
engines use the DMI data to figure out what kind of box they are on.
For example see:

* `puppet <http://puppetlabs.com/>`_

* `chef <http://www.getchef.com/>`_

* `cfengine <https://cfengine.com/>`_

x86 switches should behave like x86 servers in this regard.

.. note::

  This is not a technical problem for ONIE, but it is an operational
  problem for end customers.

For reference see the `SMBIOS Reference Specification
<http://www.dmtf.org/sites/default/files/standards/documents/DSP0134_2.8.0.pdf>`_,
section 6.2 **Required Structures and Data**.

Below are the sections and fields of the SMBIOS/DMI data that are
required by the aforementioned automation engines.  The ONIE project
recommends that all of these fields be filled in correctly.

Required SMBIOS/DMI BIOS Information (DMI type 0) Fields
--------------------------------------------------------

.. csv-table:: Required SMBIOS/DMI BIOS Information (DMI type 0) Fields
  :header: "Field", "Comments"
  :widths: 1, 4
  :delim: %

  Vendor % Required - BIOS vendor name

  Version % Required - version of BIOS f/w

  Revision % Required - version of BIOS f/w

  Release Date % Optional - BIOS f/w build date

Required SMBIOS/DMI System Information (DMI type 1) Fields
----------------------------------------------------------

.. csv-table:: Required SMBIOS/DMI System Information (DMI type 1) Fields
  :header: "Field", "Comments"
  :widths: 1, 4
  :delim: %

  Manufacturer % Required

  Product Name % Required - should match SKU description

  Serial Number % Required

  Version % Optional - match orderable SKU or sticker on chassis

  SKU Number % Optional - match orderable SKU or sticker on chassis

Required SMBIOS/DMI Chassis Information (DMI type 3) Fields
-----------------------------------------------------------

.. csv-table:: Required SMBIOS/DMI Chassis Information (DMI type 3) Fields
  :header: "Field", "Comments"
  :widths: 1, 4
  :delim: %

  Manufacturer % Required

  Type % Optional

  Serial Number % Required

  Asset Tag % Required - for null return "Not Specified"

  Power Supply State % Optional

  Thermal State % Optional

  Height % Optional - should be in rack units
