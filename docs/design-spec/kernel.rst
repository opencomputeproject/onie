.. Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2013-2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

**************************
Linux Kernel Configuration
**************************

ONIE provides an environment in which a network operating system (NOS) installer 
can run. As such, the kernel must provide features and services useful for an
installer.  This places a number of requirements on the Linux kernel configuration.

Every platform must add platform support to the Linux kernel.  What
needs to be added exactly depends on the specific platform and CPU
architecture.

For CPU architecture specific details see these sections:

- :ref:`uboot_kernel`

- :ref:`x86_kernel`

Generic Kernel Configuration
============================

In addition to the platform-specific kernel code, ONIE requires a
number of other configuration options to support an effective
installation environment.

* Kernel features

  * Kexec – allows an installer to `kexec(8)
    <http://linux.die.net/man/8/kexec>`_ into its own kernel

* Networking

  * Driver for the Ethernet management interface
  * IPv4
  * IPv6

* File systems

  * vfat, which allows for installation from USB memory sticks
  * ext2, ext3, ext4
  * jffs2
  * squashfs
  * nfs

* Hardware support

  * PCIe
  * i2c EEPROMs
  * USB storage devices
  * SDHC
  * SATA
