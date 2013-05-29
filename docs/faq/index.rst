***
FAQ
***

.. Add questions as sections headings and the answers as the section
   body.  For really long questions, abbreviate them in the heading
   and put the entire question in the section body.

What is ONIE?
=============

ONIE is a small operating system for bare metal network switches that
provides an environment for automated provisioning.

TODO
====


******************
ONIE EEPROM Format
******************

Each ONIE system must include an EEPROM which contains various system parameters
assigned by the manufacturer.  This EEPROM includes information such as the MAC
address(es) allocated to the system, the serial number, the date of
manufacturer, etc.  The name of the EEPROM format specified here is "TlvInfo",
because the information contained in the EEPROM is found in TLVs, or **T**\ ype
**L**\ ength and **V**\ alue fields.

Definition of the TlvInfo EEPROM Format
=======================================

The first eight bytes in the EERPOM are the NULL-terminated ASCII string
"TlvInfo".  This identification string can be used as a simple, preliminary
check that the EEPROM conforms to the TlvInfo format defined here.  Additional
validation checks should be performed to validate that the TlvInfo format is
really being used, such as validating the CRC.  But this string provides a good
clue, when debugging or dumping memory, that what follows is in the TlvInfo
EEPROM format.

The identification string is followed by a single-byte version value.  This
value is set to 0x01 for the TlvInfo EEPROM format described on this page.
Since the format described herein is very flexible and extensible, this value is
not expected to ever change, but is included just in case.  Software should not
assume anything about the format of the data which follows this byte if it has
not been written to support the version it reads from this value.  The values
0x00 and 0xFF are reserved and will never be used.

The version field is followed by two bytes, which give the total length of the
data which follows.  This field is in big endian order and includes the
cumulative length of all of the TLV fields which follow.  This field can be used
to determine the amount of data to read, if the EEPROM data is read in bulk,
following the first 11 bytes.  This field can also be used to determine the
location of the CRC, since the CRC-32 TLV is fixed-length and always the last
TLV in the EERPOM.

The total length field is followed by the EEPROM system data, known as TLV
fields.  Each TLV field is composed of three sub-fields: a type code field, a
length field, and a value field, in that order.

* **Type** code: This is a single byte which defines the type and format of the
  value field.  These types are defined in the table, below.  Since these type
  codes can be added over time, software which does not understand a particular
  type code should treat the value field as opaque data, not assigning any
  meaning to its type or format.  Type codes 0x00 and 0xFF are reserved and will
  never be used.  This allows for up to 254 type codes.

* **Length**: This is a single byte which contains the number of bytes in the
  value field.  Valid values of this field range from 0 to 255.  A length of
  zero means that there is no value field associated with this type code.  In
  that case, the byte following the length field is the first byte of the next
  TLV, its type code field.

* **Value**: This field contains the value for the specified type code.  It may
  range in size from 0 to 255 bytes.  The format of this field is defined,
  below, for each of the individual type codes.  Because each TLV contains a
  length field, ASCII strings are not NULL-terminated, unless otherwise
  specified, below.

Only the CRC-32 TLV is required to be present by this specification, but some
systems may not initialize properly without the presence of other fields.  The
CRC-32 TLV must occur last.  This field can be quickly found at the following
offset in the EEPROM by adding 11 (the length of the fixed header information) +
the value of the total length field - 6 (the length of the CRC-32 TLV field).

The total length of the TlvInfo EERPOM data, from the first byte of the
identification string to the last byte of the CRC TLV, must be less than or
equal to 2048 bytes.

Type Code Values
================

The following type codes are defined.

=========  ==========  ================  ==================================================
Type Code  Length      Description       Format
=========  ==========  ================  ==================================================
0x00       None        Reserved          This type code is illegal and will never be used.
0x01       Variable    Product Name      An ASCII string containing the product name.
0x02       Variable    Part Number       An ASCII string containing the vendor's part
                                         number for the device.
0x03       Variable    Serial Number     An ASCII string containing the serial number of
                                         the device.
0x04       6 bytes     MAC #1 Base       Six bytes containing the base MAC address for this
                                         device. The first three bytes contain the OUI of
                                         the assigning authority.
0x05       19 bytes    Manufacture Date  An ASCII string which specifies when the device
                                         was manufactured. The format of this string is:
                                         MM/DD/YYYY HH:NN:SS where MM is the month (01-12),
                                         DD is the day of the month (01-31), YYYY is the
                                         year, HH is the hour (00-23), NN is the minute
                                         (00-59), and SS is the second (00-59).
0x06       1 byte      Device Version    A single byte indicating the version, or revision,
                                         of the device.
0x07       Variable    Label Revision    An ASCII string containing the label revision.
0x08       Variable    Model Name        An ASCII string containing the name of the model
                                         of this device.
0x09       Variable    Software Version  An ASCII string containing the version of the
                                         software installed by the manufacturer.
0x0A       1 byte      MAC #1 Size       A single byte indicating the number of sequential
                                         MAC addresses allocated to this device, starting
                                         with the value specified in the MAC #1 Base TLV.
                                         Valid values for this field range from 1 to 255.
0x0B       Variable    Manufacturer      An ASCII string containing the name of the entity
                                         who manufactured the device.
0x0C       2 bytes     Country Code      A two-byte ASCII string containing the ISO 3166-1
                                         alpha-2 code of the country where the device was
                                         manufactured.
0x0D       Variable    Vendor            The name of the vendor who contracted with the
                                         manufacturer for the production of this device.
0xFE       4 bytes     CRC-32            A four-byte CRC which covers the EEPROM contents
                                         from the first byte of the EEPROM (the "T" in the
                                         "TlvInfo" identification string) to the length
                                         field of this TLV, inclusive.  This CRC uses the
                                         crc32 algorithm (see python's ``binascii.crc32()``
                                         function).
0xFF       None        Reserved          This type code is illegal and will never be used.
=========  ==========  ================  ==================================================

Maintanence of this EEPROM format specification and allocation of the TLV type
codes is handled by the ONIE Foundation (http://www.onie.org).
