*****************************
Image Discovery and Execution
*****************************

The primary responsibility of ONIE is to locate a NOS installer and
execute it.

Installer Discovery Methods
===========================

ONIE attempts to locate the installer through a number of discovery
methods.  The first successful method found is used to download and
run an installer.

.. note:: Even though an installer is successfully found, the
  installer can fail, in which case ONIE moves on to the next discover
  method.

The following methods are tried in order:

#. Statically configured (Passed from boot loader)
#. Local file systems (USB for example)
#. Exact URLs from DHCPv4
#. Inexact URLs based on DHCP responses
#. IPv6 neighbors
#. TFTP waterfall

The subsequent sections describe the methods in detail.

Static Configuration Method
---------------------------

This method is intended for engineering use only, e.g. during the
porting of ONIE to a new platform.  In the boot loader the user can
statically configure an installer URL that ONIE will use.

In the case of the U-Boot and Linux the user can set the
``install_url`` kernel command line argument prior to booting ONIE.
Additional kernel command line arguments can be added by setting the
``onie_debugargs`` environment varialbe.  An example::

  => setenv onie_debugargs 'install_url=http://10.0.1.249/nos_installer.bin'
  => run onie_bootcmd

Local File System Method
------------------------

In this method ONIE searches the partitions of locally attached
storage devices looking for the ONIE default installer file name.

.. note:: The default installer file name is ``onie-installer``.

This method is intended for the case where the NOS installer is
available on a USB memory stick plugged into the front panel.

The supported Linux file system types for the local storage are
``vfat`` (common on commercially availabe USB sticks) and ``ext2``.

The general algorithm for locating the installer on local storage
proceeds as follows::

  foreach $partition in /proc/partitions {
    if able to mount $partition then {
      if default file name exists {
        Add partition to found_list
      }
    }
  }

  foreach $partition in found_list {
    Run installer from $partition
  }

DHCP Requests and Responses
---------------------------

DHCP provides a powerful and flexible mechanism for specifying the
installer URL exactly.  During the DHCP request ONIE sets a number of
options to help the DHCP server determine an appropriate response.

The following options are set during the request:

.. csv-table:: DHCP Request Options
  :header: "Option", "Name", "ISC option-name", "RFC"
  :widths: 1, 3, 3, 1
  :delim: |

  55 | Parameter Request List | dhcp-parameter-request-list | [#2132]_
  60 | Vendor Class Identifier | vendor-class-identifier | [#2132]_
  77 | User Class | user-class | [#2132]_
  125 | Vendor-Identifying Vendor-Specific Information | vivso | [#3925]_

Vendor Class Identifier -- Option 60
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The vendor class identifier option is the concatenation of three
strings, separated by the colon ``:`` character:

#.  The static string ``onie_vendor``
#.  The platform name.
#.  The machine's CPU architecture.

For example using our ficticious PowerPC machine the string would be::

  onie_vendor:VENDOR_MACHINE:powerpc

Valid values for the CPU architecture string currnntly are:

-  powerpc
-  x86

See the :ref:`u_boot_platform_vars` table for more about the platform name.

User Class -- Option 77
^^^^^^^^^^^^^^^^^^^^^^^

The user class option is set to the static string::

  onie_dhcp_user_class

Vendor-Identifying Vendor-Specific Information (VIVSO)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The VIVSO option allows for custom option namespaces, where the
namespace is identified by the `32-bit IANA Private Enterprise Number
<http://www.iana.org/assignments/enterprise-numbers>`_.  ONIE
currently uses the enterprise number ``40310`` to identify its custom
namespace.

The option codes within the ONIE namespace are of size 1 byte.  The
option payload length is also 1 byte.

Within this namespace the following option codes are defined:

.. csv-table:: VIVSO Options
  :header: "Option Code", "Name", "Type", "Example"
  :widths: 1, 2, 1, 2
  :delim: |

  1 | Installer URL | string | \http://10.0.1.205/nos_installer.bin
  2 | Updater URL | string | \http://10.0.1.205/onie_update.bin
  3 | Platform Name | string | VENDOR_MACHINE
  4 | CPU Architecture | string | powerpc
  5 | Vendor ID | unsigned 32-bit integer | vendor_id from U-Boot

See the :ref:`u_boot_platform_vars` table for more about the platform
name and vendor ID.

Parameter Request List -- Option 55
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The parameter request list option encodes a list of requested options.
ONIE requests the following options:

.. csv-table:: DHCP Parameter Request List Options
  :header: "Option", "Name", "ISC option-name", "Option Type", "RFC", "Example"
  :widths: 1, 2, 2, 1, 1, 2
  :delim: |

  1 | Subnet Mask | subnet-mask | dotted quad | [#2132]_ | 255.255.255.0
  3 | Default Gateway | routers | dotted quad | [#2132]_ | 10.0.1.2
  6 | Domain Server | domain-name-servers | dotted quad | [#2132]_ | 10.0.1.2
  7 | Log Server | log-servers | dotted quad | [#2132]_ | 10.0.1.2
  12 | Hostname | host-name |   | [#2132]_ | switch-19
  15 | Domain Name | domain-name | string | [#2132]_ | cumulusnetworks.com
  42 | NTP Servers | ntp-servers | dotted quad | [#2132]_ | 10.0.1.2
  54 | DHCP Server Identifier | dhcp-server-identifier | dotted quad | [#2132]_ | 10.0.1.2
  66 | TFTP Server Name | tftp-server-name | string | [#2132]_ | behemoth01 (requires DNS)
  67 | TFTP Bootfile Name | bootfile-name or filename | string | [#2132]_ | tftp/installer.sh
  72 | HTTP Server | www-server | dotted quad | [#2132]_ | 10.0.1.251
  114 | Default URL | default-url | string | [#3679]_ | \http://server/path/installer
  150 | TFTP Server IP Address | next-server | dotted quad | [#5859]_ | 10.50.1.200

Execution Environment
=====================

.. rubric:: Footnotes

.. [#2132] `RFC 2132 <http://www.ietf.org/rfc/rfc2132.txt>`_
.. [#3925] `RFC 3925 <http://www.ietf.org/rfc/rfc3925.txt>`_
.. [#3679] `RFC 3679 <http://www.ietf.org/rfc/rfc3679.txt>`_
.. [#5859] `RFC 5859 <http://www.ietf.org/rfc/rfc5859.txt>`_
