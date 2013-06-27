*****************************
Image Discovery and Execution
*****************************

The primary responsibility of ONIE is to locate a NOS installer and
execute it.

.. _installer_discovery:

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

In the case of U-Boot and Linux the user can set the ``install_url``
kernel command line argument prior to booting ONIE.  Additional kernel
command line arguments can be added by setting the ``onie_debugargs``
environment varialbe.  An example::

  => setenv onie_debugargs 'install_url=http://10.0.1.249/nos_installer.bin'
  => run onie_bootcmd

Local File System Method
------------------------

In this method ONIE searches the partitions of locally attached
storage devices looking for the ONIE default installer file name.

.. note:: The default installer file name is ``onie-installer-<platform>-<arch>``.

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

  60  | Vendor Class Identifier | vendor-class-identifier | [#2132]_
  77  | User Class | user-class | [#2132]_
  125 | Vendor-Identifying Vendor-Specific Information | vivso | [#3925]_
  55  | Parameter Request List | dhcp-parameter-request-list | [#2132]_

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

.. _dhcp_vivso:

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

.. _dhcp_vendor_options:

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
  72 | HTTP Server IP | www-server | dotted quad | [#2132]_ | 10.0.1.251
  114 | Default URL | default-url | string | [#3679]_ | \http://server/path/installer
  150 | TFTP Server IP Address | next-server | dotted quad | [#5859]_ | 10.50.1.200

Exact Installer URLs From DHCPv4
--------------------------------

The DHCP options discussed previously provide a number of ways to
express the **exact** URL of the NOS installer.  When interpreting URLs,
ONIE accepts the following URI schemes:

- \http://server/path/....
- \https://server/path/....
- \ftp://server/path/....
- \tftp://server/path/....

The following options can be used to form an exact URL.

.. csv-table:: Exact DHCP URLs
  :header: "Option", "Name", "Comments"
  :widths: 1, 1, 3
  :delim: |

  125 | VIVSO | "The *installer URL* option (code = 1) specified in the ONIE VIVSO
  options yields an exact URL.  See the :ref:`dhcp_vivso` section above"
  114 | Default URL | Intended for http, but other URLs accepted
  150 + 67 | TFTP Server IP and TFTP Bootfile |  Both options required for an exact URL
  66 + 67 | TFTP Server Name and TFTP Bootfile |  Both options required for an exact URL.  Requires DNS

Partial Installer URLs
----------------------

Configuring a DHCP server for exact URLs may be impractical in certain
situations.

For example consider an enterprise scenario where the corporate IT
department that controls the DHCP server is separate from the
application development department trying to prototype new web
services.  The application department wants to move quickly and
prototype their new solution as soon as possible.  In this case
waiting for the IT department to make DHCP server changes takes too
much time.

To allow for flexibility in the administration of the DHCP server ONIE
can find an installer using partial DHCP information.  ONIE uses a
default sequence of URL paths and default file names in conjunction
with partial DHCP information to find an installer.

The default installer name that ONIE looks for is::

  onie-installer-${onie_machine}-${onie_arch}

For our hypothetical PowerPC machine the default installer name would
be::

  onie-installer-VENDOR_MACHINE-powerpc

The default methods using partial DHCP information to locate an
installer are:

.. csv-table:: Partial DHCP URLs
  :header: "DHCP Options", "Name", "URL"
  :widths: 1, 1, 3
  :delim: |

  67 | TFTP Bootfile | Contents of bootfile [#bootfile_url]_
  72 | HTTP Server IP | \http://$http_server_ip/$onie_default_installer_name
  66 | TFTP Server IP | \http://$tftp_server_ip/$onie_default_installer_name
  66 | DHCP Server IP | \http://$dhcp_server_ip/$onie_default_installer_name

TFTP Waterfall
^^^^^^^^^^^^^^

A classic PXE-like TFTP waterfall is also provided for.  Given a TFTP
server address ONIE attempts to download the installer using a
sequence of TFTP paths with decreasing levels of specificity.

The TFTP URL name has this format::

  tftp://$tftp_server_ip/$path_prefix/$onie_default_installer_name

The ``$tftp_server_ip`` comes from DHCP option 66.

The ``$path_prefix`` is determined in the following manner:

- First the path_prefix is built using the Ethernet management
  interface's MAC address using lower case hexadecimal with a dash
  separator. For example with address ``55:66:AA:BB:CC:DD`` the
  path_prefix would be ``55-66-aa-bb-cc-dd``.

- Next, the path_prefix is built using the Ethernet management
  interface's IP address in upper case hexadecimal,
  e.g. ``192.168.1.178 -> C0A801B2``.  If the installer is not found
  at that location remove the least significant hex digit and try
  again.

- Ultimately try without a path_prefix, i.e. look at the root of the
  TFTP server.

Here is a complete list of the bootfile paths attempted using the
example MAC address, IP address and the ficticious PowerPC platform::

  55-66-aa-bb-cc-dd/$onie_default_installer_name
  C0A801B2/$onie_default_installer_name
  C0A801B/$onie_default_installer_name
  C0A801/$onie_default_installer_name
  C0A80/$onie_default_installer_name
  C0A8/$onie_default_installer_name
  C0A/$onie_default_installer_name
  C0/$onie_default_installer_name
  C/$onie_default_installer_name
  $onie_default_installer_name

HTTP IPv6 Neighbors
^^^^^^^^^^^^^^^^^^^

ONIE also queries it is IPv6 link-local neighbors via HTTP for an
installer.  The general algorithm follows:

#. ping6 the "all nodes" link local IPv6 multicast address, ``ff02::1``.
#. for each responding neighbor try to download the
   $onie_default_installer_name from the root of the web server.

Here is an example the URLs used by this method::

  http://fe80::4638:39ff:fe00:139e%eth0/onie-installer-VENDOR_MACHINE-powerpc
  http://fe80::4638:39ff:fe00:2659%eth0/onie-installer-VENDOR_MACHINE-powerpc
  http://fe80::230:48ff:fe9f:1547%eth0/onie-installer-VENDOR_MACHINE-powerpc
  http://fe80::4638:39ff:fe00:1c0%eth0/onie-installer-VENDOR_MACHINE-powerpc

This makes it very simple to walk up to a switch and directly connect
a laptop to the Ethernet management port and install from a local
HTTP server.

Execution Environment
=====================

After ONIE locates and downloads an installer the next step is to run
the installer.

Prior to execution ONIE prepares an execution environment:

- chmod +x on the downloaded installer
- export a number of environment variables, usable by the installer
- run the installer

ONIE exports the following environment variables:

.. csv-table:: Installer Core Environment Variables
  :header: "Variable Name", "Meaning"
  :widths: 1, 1
  :delim: |

  onie_exec_url | Currently executing URL
  onie_platform | Vendor and Machine name
  onie_vendor_id | 32-bit IANA Private Enterprise Number in decimal
  onie_serial_num | Device serial number
  onie_eth_addr | MAC address for Ethernet management port

In addition, any and all DHCP response options are exported, in the
style of busybox's udhcpc.  A sample of those variables follows:

.. csv-table:: Installer DHCP Environment Variables
  :header: "Variable Name", "Meaning"
  :widths: 1, 1
  :delim: |

  onie_disco_dns | DNS Server
  onie_disco_domain | Domain name fro DNS
  onie_disco_hostname | Switch hostname
  onie_disco_interface | Ethernet management interface, e.g. eth0
  onie_disco_ip | Ethernet management IP address
  onie_disco_router | Gateway
  onie_disco_serverid | DHCP server IP
  onie_disco_siaddr | TFTP server IP
  onie_disco_subnet | IP netmask
  onie_disco_vivso | VIVSO option data

See the :ref:`nos_interface` section for more about the NOS installer.

.. rubric:: Footnotes

.. [#2132] `RFC 2132 <http://www.ietf.org/rfc/rfc2132.txt>`_
.. [#3925] `RFC 3925 <http://www.ietf.org/rfc/rfc3925.txt>`_
.. [#3679] `RFC 3679 <http://www.ietf.org/rfc/rfc3679.txt>`_
.. [#5859] `RFC 5859 <http://www.ietf.org/rfc/rfc5859.txt>`_

.. [#bootfile_url] Try to intrepret the bootfile as a URL.  This is a
                   small abuse of the TFTP bootfile option, which has
                   a precedent in other loading schemes such as `iPXE
                   <http://ipxe.org/howto/dhcpd>`_.
