*********************
Hardware Requirements
*********************

ONIE has modest hardware requirements. The NOS definitely has
additional hardware requirements.

.. note::
  ONIE has no specific CPU architecture requirements -- it is Linux.

  The dominant architecture today, however, is Freescale's `QorIQ PowerPC 
  <http://www.freescale.com/webapp/sps/site/homepage.jsp?code=QORIQ_HOME>`_.

  The documentation in this section currently focuses on that
  architecture and the associated `U-Boot <http://www.denx.de/wiki/U-Boot>`_ 
  boot loader.

  Supporting the x86 architecture is on the roadmap.

====================================  =========================================
Required Hardware                     Purpose
====================================  =========================================
U-Boot compatible CPU complex         The CPU complex must be supported by
                                      U-Boot. For example,  PowerPC, ARM, MIPS.
1GB (min) CPU DRAM                    The DRAM used by the CPU.
NOR Boot flash 8MB (min), 32MB (rec)  U-Boot and the ONIE kernel and
                                      applications reside in NOR flash.
                                      Although 8 MB is the minimum size of
                                      this flash, 32 MB is the recommended
                                      size.
Non-volatile board information        An EEPROM to store board information and
                                      manufacturing data, like the device
                                      serial number and network MAC address.
Ethernet management port              Required to download an operating system
                                      installer.
====================================  =========================================

.. _non_volatile_board_info:

Board Information EEPROM Format
===============================

Each ONIE system must include an EEPROM which contains various system parameters
assigned by the manufacturer.  This EEPROM includes information such as the MAC
address(es) allocated to the system, the serial number, the date of
manufacturer, etc.  The name of the EEPROM format specified here is ``TlvInfo``,
because the information contained in the EEPROM is found in TLVs, or **T**\ ype
**L**\ ength and **V**\ alue fields.

Definition of the TlvInfo EEPROM Format
---------------------------------------

The first eight bytes in the EEPROM are the NULL-terminated ASCII string
``TlvInfo``.  This identification string can be used as a simple, preliminary
check that the EEPROM conforms to the TlvInfo format defined here.  Additional
validation checks should be performed to validate that the TlvInfo format is
really being used, such as validating the CRC.  But this string provides a good
clue, when debugging or dumping memory, that what follows is in the TlvInfo
EEPROM format.

The identification string is followed by a single-byte version value.  This
value is set to 0x01 for the TlvInfo EEPROM format described on this page.
Since the format described herein is very flexible and extensible, this value is
not expected to ever change, but is included just in case.  Software should not
assume anything about the format of the data that follows this byte if it has
not been written to support the version it reads from this value.  The values
0x00 and 0xFF are reserved and will never be used.

The version field is followed by two bytes, which give the total length of the
data that follows.  This field is in big endian order and includes the
cumulative length of all of the TLV fields that follow.  This field can be used
to determine the amount of data to read, if the EEPROM data is read in bulk,
following the first 11 bytes.  This field can also be used to determine the
location of the CRC, since the CRC-32 TLV is fixed length and always the last
TLV in the EERPOM.

The total length field is followed by the EEPROM system data, known as *TLV
fields*.  Each TLV field is composed of three sub-fields: a type code field, a
length field, and a value field, in that order.

* **Type** code: This is a single byte that defines the type and format of the
  value field.  These types are defined in the table below.  Since these type
  codes can be added over time, software that does not understand a particular
  type code should treat the value field as opaque data, not assigning any
  meaning to its type or format.  Type codes 0x00 and 0xFF are reserved and will
  never be used.  This allows for up to 254 type codes.

* **Length**: This is a single byte that contains the number of bytes in the
  value field.  Valid values of this field range from 0 to 255.  A length of
  zero means that there is no value field associated with this type code.  In
  that case, the byte following the length field is the first byte of the next
  TLV, its type code field.

* **Value**: This field contains the value for the specified type code.  It may
  range in size from 0 to 255 bytes.  The format of this field is defined,
  below, for each of the individual type codes.  Because each TLV contains a
  length field, ASCII strings are not NULL-terminated, unless otherwise
  specified as described below.

Only the CRC-32 TLV is required to be present by this specification, but some
systems may not initialize properly without the presence of other fields.  The
CRC-32 TLV must occur last.  This field can be quickly found at the following
offset in the EEPROM by adding 11 (the length of the fixed header information)
+ the value of the total length field - 6 (the length of the CRC-32 TLV field).

The total length of the TlvInfo EEPROM data, from the first byte of the
identification string to the last byte of the CRC TLV, must be less than or
equal to 2048 bytes.

The layout of the entire EEPROM block looks like:

==============   =============      ==============================================
Field Name       Size in Bytes      Value
==============   =============      ==============================================
ID String        8                  "TlvInfo"
Header Version   1                  0x01
Total Length     2                  Total number of bytes that follow
TLV 1            Varies             The data for TLV 1
TLV 2            Varies             The data for TLV 2
\.....           \.....             \.....
TLV N            Varies             The data for TLV N
CRC-32 TLV       6                  Type = 0xFE, Length = 4, Value = 4 byte CRC-32
==============   =============      ==============================================

Type Code Values
----------------

The following type codes are defined.

=========  ==========  ================  ==================================================
Type Code  Length      Description       Format
=========  ==========  ================  ==================================================
0x00       None        Reserved          This type code is illegal and will never be used,
                                         so that it will be easy to detect if a portion of
                                         the EEPROM is erased.
0x21       Variable    Product Name      An ASCII string containing the product name.
0x22       Variable    Part Number       An ASCII string containing the vendor's part
                                         number for the device.
0x23       Variable    Serial Number     An ASCII string containing the serial number of
                                         the device.
0x24       6 bytes     MAC #1 Base       Six bytes containing the base MAC address for this
                                         device. The first three bytes contain the OUI of
                                         the assigning authority.
0x25       19 bytes    Manufacture Date  An ASCII string that specifies when the device
                                         was manufactured. The format of this string is:
                                         MM/DD/YYYY HH:NN:SS where MM is the month (01-12),
                                         DD is the day of the month (01-31), YYYY is the
                                         year, HH is the hour (00-23), NN is the minute
                                         (00-59), and SS is the second (00-59).
0x26       1 byte      Device Version    A single byte indicating the version, or revision,
                                         of the device.
0x27       Variable    Label Revision    An ASCII string containing the label revision.
0x28       Variable    Platform Name     An ASCII string which identifies a CPU subsystem
                                         (CPU, architecture, DRAM, NOR flash). Very useful
                                         when the CPU resides on a daughter card.  Typically
                                         this includes <arch>-<machine>-<machine_revision>.
0x29       Variable    ONIE Version      An ASCII string containing the version of the
                                         ONIE software installed by the manufacturer.
0x2A       2 bytes     MAC #1 Size       A two-byte big-endian unsigned number of sequential
                                         MAC addresses allocated to this device, starting
                                         with the value specified in the MAC #1 Base TLV.
                                         Valid values for this field range from 1 to 65535.
0x2B       Variable    Manufacturer      An ASCII string containing the name of the entity
                                         that manufactured the device.
0x2C       2 bytes     Country Code      A two-byte ASCII string containing the ISO 3166-1
                                         `alpha-2 code 
                                         <http://www.iso.org/iso/country_codes/iso_3166_code_lists/country_names_and_code_elements.htm>`_ 
                                         of the country where the device was manufactured.
0x2D       Variable    Vendor            The name of the vendor who contracted with the
                                         manufacturer for the production of this device.
                                         This is typically the company name on the outside
                                         of the device.
0x2E       Variable    Diag Version      An ASCII string containing the version of the 
                                         diagnostic software.
0xFD       Variable    Vendor Extension  This type code allows vendors to include extra
                                         information that is specific to the vendor and
                                         cannot be specified using the other type codes.
                                         The format of this value field is a four byte
                                         IANA enterprise number, followed by a vendor
                                         defined string of bytes. The format of the string
                                         of bytes is entirely up to the vendor, except
                                         that it can be, at most, 255 bytes long, including
                                         the `IANA enterprise number 
                                         <http://www.iana.org/assignments/enterprise-numbers/enterprise-numbers>`_. 
                                         If more space is needed, then multiple TLVs with 
                                         this type code can be used.
0xFE       4 bytes     CRC-32            A four-byte CRC which covers the EEPROM contents
                                         from the first byte of the EEPROM (the "T" in the
                                         "TlvInfo" identification string) to the length
                                         field of this TLV, inclusive.  This CRC uses the
                                         crc32 algorithm (see Python's ``binascii.crc32()``
                                         function).
0xFF       None        Reserved          This type code is illegal and will never be used,
                                         so that it will be easy to detect if a portion of
                                         the EEPROM is erased.
=========  ==========  ================  ==================================================

Maintanence of this EEPROM format specification and allocation of the TLV type
codes is handled by the `ONIE Foundation <http://http://onie.github.io/onie/>`_.

