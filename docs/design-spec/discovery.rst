.. Copyright (C) 2013,2014,2015,2016,2017 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2015 Carlos Cardenas <carlos@cumulusnetworks.com>
   Copyright (C) 2013,2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. _image_discovery:

*****************************
Image Discovery and Execution
*****************************

The primary responsibility of ONIE is to locate a network operating system 
(NOS) installer and execute it.

.. _platform_name:

Platform Name and Identification
================================

For identifying the running platform. ONIE uses the following definitions:

- arch -- The CPU architecture.  The currently supported architectures are:

  - arm
  - powerpc
  - x86_64

- machine -- A string of the form ``<VENDOR>_<MODEL>``.

- machine-revision -- A string of the form ``r<NUMBER>``, used to track
  different hardware revision of a machine

- platform -- A string of the form ``<ARCH>-<MACHINE>-<MACHINE-REVISION>``

- switch-silicon-vendor -- A string of one of the following, used to
  track ASIC silicon vendor:

==============  ======
Silicon Vendor  String
==============  ======
Broadcom        bcm
Cavium          cavium
Centec          centec
Marvell         mvl
Mellanox        mlnx
Nephos          nephos
Qemu            qemu
==============  ======
  
.. note:: The above definitions place some restrictions on the valid
          characters allowed for the <ARCH>, <VENDOR> and <MODEL>
          strings.

The allowable characters in the above strings are:

#. VENDOR - cannot contain ``_`` (underscore) or ``-`` (hyphen) characters
#. MODEL  - cannot contain ``-`` (hyphen) character.  ``_``
   (underscore) is OK
#. ARCH   - cannot contain ``_`` (underscore) or ``-`` (hyphen) characters

At runtime, ONIE provides the ``onie-sysinfo`` command, which can be
used to dump this information and more.  See the
:ref:`cmd_onie_sysinfo` section for more about the ``onie-sysinfo``
command.

The platform name must remain consistent across all ONIE modes as
described in :ref:`nos_interface`.

.. _installer_discovery:

Installer Discovery Methods
===========================

ONIE attempts to locate the installer through a number of discovery
methods.  The first successful method found is used to download and
run an installer.

.. note:: Even though an installer is successfully found, the
  installer can fail, in which case ONIE moves on to the next discovery
  method.

The following methods are tried in this order:

#. Statically configured (passed from boot loader)
#. Local file systems (USB for example)
#. Exact URLs from DHCPv4
#. Inexact URLs based on DHCP responses
#. IPv6 neighbors
#. TFTP waterfall

.. note:: The discovery methods are tried repeatedly, forever, until a
          successful image install occurs.

The general image discovery procedure is illustrated by this
pseudo-code::

  while (true) {
    Configure Ethernet management console
    Attempt discovery method 1
    Attempt discovery method 2
    ...
    Attempt discovery method N
    Sleep for 20 seconds
  }

The subsequent sections describe these methods in detail.

.. _default_file_name:

Default File Name Search Order
------------------------------

In a number of the following methods, ONIE searches for default file
names in a specific order.  All the methods use the same default file
names and search order, which are described in this section.

The default installer file names are searched for in the following order:

#. ``onie-installer-<arch>-<vendor>_<machine>-r<machine_revision>``
#. ``onie-installer-<arch>-<vendor>_<machine>``
#. ``onie-installer-<vendor>_<machine>``
#. ``onie-installer-<cpu_arch>-<switch_silicon_vendor>``
#. ``onie-installer-<arch>``
#. ``onie-installer``

For a hypothetical x86_64 machine, the default installer file names
would be::

  onie-installer-x86_64-VENDOR_MACHINE-r0
  onie-installer-x86_64-VENDOR_MACHINE
  onie-installer-VENDOR_MACHINE
  onie-installer-x86_64-SWITCH_SILICON_VENDOR
  onie-installer-x86_64
  onie-installer

.. note::

  ONIE 2016.05 introduced
  ``onie-installer-<cpu_arch>-<switch_silicon_vendor>``.  All previous
  versions will not include this naming item.
     
.. note:: In the case of ONIE *self-update mode*, the file name prefix is
          ``onie-updater`` instead of ``onie-installer``.

.. note:: For the exact file names used for your specific hardware
          platform please contact your NOS vendor or your hardware
          vendor.

Static Configuration Method
---------------------------

This method is intended for engineering use only; for example, during
the porting of ONIE to a new platform.  In the boot loader, the user
can statically configure an installer URL that ONIE will use by
setting the ``install_url`` kernel command line argument.

Local File System Method
------------------------

In this method, ONIE searches the partitions of locally attached
storage devices looking for one of the ONIE default installer file
names.

See :ref:`default_file_name` for more information on the default file names.

This method is intended for the case where the NOS installer is
available on a USB memory stick plugged into the front panel.

Two file system types are supported, the popular ``vFAT`` partition type
(common on commercially availabe USB sticks) and Linux's ``ext2``.

.. note::

  OSX's Disk Utility by default will write out an unsupported partition type.
  Please use the ``diskutil`` command line tool for formatting::

    # Find USB drive
     
    % diskutil list
    /dev/disk2
       #:                       TYPE NAME                    SIZE       IDENTIFIER
       0:     FDisk_partition_scheme                        *8.1 GB     disk2
       1:               Windows_NTFS ONIE                    8.1 GB     disk2s1
     
    # Write out correctly label (wipes all data on drive)
     
    % sudo diskutil eraseDisk FAT32 ONIE MBRFormat /dev/disk2
    Started erase on disk2
    Unmounting disk
    Creating the partition map
    Waiting for the disks to reappear
    Formatting disk2s1 as MS-DOS (FAT32) with name ONIE
    512 bytes per physical sector
    /dev/rdisk2s1: 15697944 sectors in 1962243 FAT32 clusters (4096 bytes/cluster)
    bps=512 spc=8 res=32 nft=2 mid=0xf8 spt=32 hds=255 hid=2 drv=0x80 bsec=15728638 bspf=15331 rdcl=2 infs=1 bkbs=6
    Mounting disk
    Finished erase on disk2

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

.. _onie_eth_mgmt_config:

Ethernet Management Port Configuration
--------------------------------------

In order to perform network based image discovery the Ethernet
management console must first be configured.  The following
configuration methods are tried in order:

#. Static configuration -- Set via the ``ip`` kernel command line argument
#. DHCPv6 -- Planned, but not yet implemented
#. DHCPv4
#. Link Local IPv4 address (see `RFC-3927 <https://tools.ietf.org/html/rfc3927>`_)

The static configuration uses the ``ip`` `Linux kernel command line
argument
<https://www.kernel.org/doc/Documentation/filesystems/nfs/nfsroot.txt>`_.

The fall back IPv4 address is ``192.168.3.10`` for the first
management port, with ``.11``, ``.12``, etc. used for additional
management ports if necessary.

.. _onie_dhcp_requests:

DHCP Requests and Responses
---------------------------

DHCP provides a powerful and flexible mechanism for specifying the
installer URL exactly.  During the DHCP request, ONIE sets a number of
options to help the DHCP server determine an appropriate response.

The following options are set during the request:

.. csv-table:: DHCP Request Options
  :header: "Option", "Name", "ISC option-name", "RFC"
  :widths: 1, 3, 3, 1
  :delim: |

  60  | Vendor Class Identifier | vendor-class-identifier | `RFC 2132 <http://www.ietf.org/rfc/rfc2132.txt>`_
  77  | User Class | user-class | `RFC 2132 <http://www.ietf.org/rfc/rfc2132.txt>`_
  125 | Vendor-Identifying Vendor-Specific Information | vivso | `RFC 3925 <http://www.ietf.org/rfc/rfc3925.txt>`_
  55  | Parameter Request List | dhcp-parameter-request-list | `RFC 2132 <http://www.ietf.org/rfc/rfc2132.txt>`_


.. _onie_dhcp_vendor_class:

Vendor Class Identifier -- Option 60
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The vendor class identifier option is the concatenation of two
strings, separated by the colon ``:`` character:

#.  The static string ``onie_vendor``
#.  <arch>-<vendor>_<machine>-r<machine_revision>

For example, using the example x86_64 machine, the string would be::

  onie_vendor:x86_64-VENDOR_MACHINE-r0

.. note:: For the exact DHCP Vendor Class Identifier used for your
          specific hardware platform please contact your NOS vendor or
          your hardware vendor.

See the :ref:`platform_name` table for more about the platform name.

User Class -- Option 77
^^^^^^^^^^^^^^^^^^^^^^^

The user class option is set to the static string::

  onie_dhcp_user_class

.. _dhcp_vivso:

Vendor-Identifying Vendor-Specific Information (VIVSO)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The VIVSO option allows for custom option namespaces, where the
namespace is identified by the `32-bit IANA Private Enterprise Number
<http://www.iana.org/assignments/enterprise-numbers>`_.  ONIE
currently uses the enterprise number ``42623`` to identify its custom
namespace.

The option codes within the ONIE namespace have a size of 1 byte. The
option payload length is also 1 byte.

Within this namespace, the following option codes are defined:

.. _dhcp_vendor_options:

.. csv-table:: VIVSO Options
  :header: "Option Code", "Name", "Type", "Example"
  :widths: 1, 2, 1, 2
  :delim: |

  1 | Installer URL | string | \http://10.0.1.205/nos_installer.bin
  2 | Updater URL | string | \http://10.0.1.205/onie_update.bin
  3 | Platform Name | string | VENDOR_MACHINE
  4 | CPU Architecture | string | x86_64
  5 | Machine Revision | string | 0

See the :ref:`u_boot_platform_vars` table for more information about the platform
name.

Parameter Request List -- Option 55
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The parameter request list option encodes a list of requested options.
ONIE requests the following options:

.. csv-table:: DHCP Parameter Request List Options
  :header: "Option", "Name", "ISC option-name", "Option Type", "RFC", "Example"
  :widths: 1, 2, 2, 1, 1, 2
  :delim: |

  1 | Subnet Mask | subnet-mask | dotted quad | `2132 <http://www.ietf.org/rfc/rfc2132.txt>`_ | 255.255.255.0
  3 | Default Gateway | routers | dotted quad | `2132 <http://www.ietf.org/rfc/rfc2132.txt>`_ | 10.0.1.2
  6 | Domain Server | domain-name-servers | dotted quad | `2132 <http://www.ietf.org/rfc/rfc2132.txt>`_ | 10.0.1.2
  7 | Log Server | log-servers | dotted quad | `2132 <http://www.ietf.org/rfc/rfc2132.txt>`_ | 10.0.1.2
  12 | Hostname | host-name |   | `2132 <http://www.ietf.org/rfc/rfc2132.txt>`_ | switch-19
  15 | Domain Name | domain-name | string | `2132 <http://www.ietf.org/rfc/rfc2132.txt>`_ | cumulusnetworks.com
  42 | NTP Servers | ntp-servers | dotted quad | `2132 <http://www.ietf.org/rfc/rfc2132.txt>`_ | 10.0.1.2
  54 | DHCP Server Identifier | dhcp-server-identifier | dotted quad | `2132 <http://www.ietf.org/rfc/rfc2132.txt>`_ | 10.0.1.2
  66 | TFTP Server Name | tftp-server-name | string | `2132 <http://www.ietf.org/rfc/rfc2132.txt>`_ | behemoth01 (requires DNS)
  67 | TFTP Bootfile Name | bootfile-name or filename | string | `2132 <http://www.ietf.org/rfc/rfc2132.txt>`_ | tftp/installer.sh
  72 | HTTP Server IP | www-server | dotted quad | `2132 <http://www.ietf.org/rfc/rfc2132.txt>`_ | 10.0.1.251
  114 | Default URL | default-url | string | `3679 <http://www.ietf.org/rfc/rfc3679.txt>`_ | \http://server/path/installer
  150 | TFTP Server IP Address | next-server | dotted quad | `5859 <http://www.ietf.org/rfc/rfc5859.txt>`_ | 10.50.1.200

.. _http_headers:

HTTP Requests and HTTP Headers
------------------------------

All HTTP requests made by ONIE include a set of standard HTTP headers,
which an HTTP CGI automation system could utilize.  The headers sent on
each HTTP request are:

.. csv-table:: HTTP Headers
  :header: "Header", "Value", "Example"
  :widths: 1, 1, 1
  :delim: |

  ONIE-SERIAL-NUMBER: | Serial number | XYZ123004
  ONIE-ETH-ADDR: | Management MAC address | 08:9e:01:62:d1:93
  ONIE-VENDOR-ID: | 32-bit IANA Private Enterprise Number in decimal | 12345
  ONIE-MACHINE: | <vendor>_<machine> | VENDOR_MACHINE
  ONIE-MACHINE-REV: | <machine_revision> | 0
  ONIE-ARCH: | CPU architecture | x86_64
  ONIE-SECURITY-KEY: | Security key | d3b07384d-ac-6238ad5ff00
  ONIE-OPERATION: | ONIE mode of operation | ``os-install`` or ``onie-update``


Exact Installer URLs From DHCPv4
--------------------------------

The DHCP options discussed previously provide a number of ways to
express the **exact** URL of the NOS installer.  When interpreting URLs,
ONIE accepts the following URI schemes:

- \http://server/path/....
- \ftp://server/path/....
- \tftp://server/path/....

The following options can be used to form an exact URL.

.. csv-table:: Exact DHCP URLs
  :header: "Option", "Name", "Comments"
  :widths: 1, 1, 3
  :delim: |

  125 | VIVSO | The *installer URL* option (code = 1) specified in the ONIE VIVSO. Options yields an exact URL.  See :ref:`dhcp_vivso` above.
  114 | Default URL | Intended for HTTP, but other URLs accepted.
  150 + 67 | TFTP server IP and TFTP bootfile |  Both options required for an exact URL.
  66 + 67 | TFTP server name and TFTP bootfile |  Both options required for an exact URL.  Requires DNS.

Partial Installer URLs
----------------------

Configuring a DHCP server for exact URLs may be impractical in certain
situations.

For example, consider an enterprise scenario where the corporate IT
department that controls the DHCP server is separate from the
application development department trying to prototype new Web
services.  The application department wants to move quickly and
prototype their new solution as soon as possible.  In this case,
waiting for the IT department to make DHCP server changes takes too much time.

To allow for flexibility in the administration of the DHCP server,
ONIE can find an installer using partial DHCP information.  ONIE uses
a default sequence of URL paths and default installer file names in
conjunction with partial DHCP information to find an installer.

See :ref:`default_file_name` for more information on the default file
names and search order.

The following DHCP option responses are used to locate an installer in
conjunction with the default file names:

.. csv-table:: Partial DHCP URLs
  :header: "DHCP Options", "Name", "URL"
  :widths: 1, 1, 3
  :delim: |

  67  | TFTP Bootfile | Contents of bootfile [#bootfile_url]_
  72  | HTTP Server IP | \http://$http_server_ip/${onie_default_installer_names}
  150 | TFTP Server IP | \http://$tftp_server_ip/${onie_default_installer_names}
  54  | DHCP Server IP | \http://$dhcp_server_ip/${onie_default_installer_names}

Default ONIE image server name ``onie-server``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If the default ONIE server name ``onie-server`` is resolvable by DNS
it is included in the search for the default installer file names for
both ``http`` and ``tftp`` protocols.  The following URLs are
attempted::

  http://onie-server/${onie_default_installer_names}
  tftp://onie-server/${onie_default_installer_names}

TFTP Waterfall
^^^^^^^^^^^^^^

ONIE includes a classic PXE-like TFTP waterfall.  Given a TFTP
server address, ONIE attempts to download the installer using a
sequence of TFTP paths with decreasing levels of specificity.

The TFTP URL name has this format::

  tftp://$tftp_server_ip/$path_prefix/$onie_default_installer_name

The ``$tftp_server_ip`` comes from DHCP option 66.

The ``$path_prefix`` is determined in the following manner:

#. First the ``path_prefix`` is built using the Ethernet management
   interface's MAC address using lower case hexadecimal with a dash
   separator. For example, with address ``55:66:AA:BB:CC:DD`` the
   ``path_prefix`` would be ``55-66-aa-bb-cc-dd``.

#. Next, the ``path_prefix`` is built using the Ethernet management
   interface's IP address in upper case hexadecimal. For example,
   ``192.168.1.178 -> C0A801B2``.  If the installer is not found
   at that location, remove the least significant hex digit and try again.

#. Finally, look for the list of default file names at the root of the TFTP server.

Here is a complete list of the bootfile paths attempted using the
example MAC address, IP address and the example x86_64 platform::

  55-66-aa-bb-cc-dd/onie-installer-<arch>-<vendor>_<machine>
  C0A801B2/onie-installer-<arch>-<vendor>_<machine>
  C0A801B/onie-installer-<arch>-<vendor>_<machine>
  C0A801/onie-installer-<arch>-<vendor>_<machine>
  C0A80/onie-installer-<arch>-<vendor>_<machine>
  C0A8/onie-installer-<arch>-<vendor>_<machine>
  C0A/onie-installer-<arch>-<vendor>_<machine>
  C0/onie-installer-<arch>-<vendor>_<machine>
  C/onie-installer-<arch>-<vendor>_<machine>
  onie-installer-<arch>-<vendor>_<machine>-<machine_revision>
  onie-installer-<arch>-<vendor>_<machine>
  onie-installer-<vendor>_<machine>
  onie-installer-<arch>
  onie-installer

See :ref:`default_file_name` for more information on the default file
names and search order.

.. _discover_neighbors:

HTTP IPv6 Neighbors
^^^^^^^^^^^^^^^^^^^

ONIE also queries its IPv6 link-local neighbors via HTTP for an
installer.  The general algorithm follows:

#. ``ping6`` the "all nodes" link local IPv6 multicast address, ``ff02::1``.
#. For each responding neighbor, try to download the default file names
   from the root of the Web server.

Here is an example the URLs used by this method::

  http://fe80::4638:39ff:fe00:139e%eth0/onie-installer-x86_64-VENDOR_MACHINE-r0
  http://fe80::4638:39ff:fe00:139e%eth0/onie-installer-x86_64-VENDOR_MACHINE
  http://fe80::4638:39ff:fe00:139e%eth0/onie-installer-VENDOR_MACHINE
  http://fe80::4638:39ff:fe00:139e%eth0/onie-installer-x86_64
  http://fe80::4638:39ff:fe00:139e%eth0/onie-installer
  http://fe80::4638:39ff:fe00:2659%eth0/onie-installer-x86_64-VENDOR_MACHINE-r0
  http://fe80::4638:39ff:fe00:2659%eth0/onie-installer-x86_64-VENDOR_MACHINE
  http://fe80::4638:39ff:fe00:2659%eth0/onie-installer-VENDOR_MACHINE
  http://fe80::4638:39ff:fe00:2659%eth0/onie-installer-x86_64
  http://fe80::4638:39ff:fe00:2659%eth0/onie-installer
  http://fe80::230:48ff:fe9f:1547%eth0/onie-installer-x86_64-VENDOR_MACHINE-r0
  http://fe80::230:48ff:fe9f:1547%eth0/onie-installer-x86_64-VENDOR_MACHINE
  http://fe80::230:48ff:fe9f:1547%eth0/onie-installer-VENDOR_MACHINE
  http://fe80::230:48ff:fe9f:1547%eth0/onie-installer-x86_64
  http://fe80::230:48ff:fe9f:1547%eth0/onie-installer

This makes it very simple to walk up to a switch and directly connect
a laptop to the Ethernet management port and install from a local HTTP server.

See :ref:`default_file_name` for more information on the default file
names and search order.

Execution Environment
=====================

After ONIE locates and downloads an installer, the next step is to run
the installer.

Prior to execution, ONIE prepares an execution environment:

- ``chmod +x`` on the downloaded installer.
- Export a number of environment variables, usable by the installer.
- Run the installer.

ONIE exports the following environment variables:

.. csv-table:: Installer Core Environment Variables
  :header: "Variable Name", "Meaning"
  :widths: 1, 1
  :delim: |

  onie_exec_url | Currently executing URL
  onie_platform | CPU architecture, vendor and machine name
  onie_vendor_id | 32-bit IANA Private Enterprise Number in decimal
  onie_serial_num | Device serial number
  onie_eth_addr | MAC address for Ethernet management port

In addition, any and all DHCP response options are exported, in the
style of BusyBox's ``udhcpc``.  A sample of those variables follows:

.. csv-table:: Installer DHCP Environment Variables
  :header: "Variable Name", "Meaning"
  :widths: 1, 1
  :delim: |

  onie_disco_dns | DNS Server
  onie_disco_domain | Domain name from DNS
  onie_disco_hostname | Switch hostname
  onie_disco_interface | Ethernet management interface, like eth0
  onie_disco_ip | Ethernet management IP address
  onie_disco_router | Gateway
  onie_disco_serverid | DHCP server IP
  onie_disco_siaddr | TFTP server IP
  onie_disco_subnet | IP netmask
  onie_disco_vivso | VIVSO option data

See :ref:`nos_interface` for more about the NOS installer.

.. rubric:: Footnotes


.. [#bootfile_url] Try to intrepret the bootfile as a URL.  This is a
                   small abuse of the TFTP bootfile option, which has
                   a precedent in other loading schemes such as `iPXE
                   <http://ipxe.org/howto/dhcpd>`_.
