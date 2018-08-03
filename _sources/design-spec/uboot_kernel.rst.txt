.. Copyright (C) 2014,2015,2016,2017 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. _uboot_kernel:

***************************************************
U-Boot Platform Linux Kernel and Device Tree Source
***************************************************

ONIE provides an environment in which a network operating system (NOS) installer 
can run. As such, the kernel must provide features and services useful for an
installer.  This places a number of requirements on the Linux kernel configuration.

In addition, the kernel requires support for individual hardware platforms and the 
associated `device tree source <http://devicetree.org/Device_Tree_Usage>`_.
	
.. note:: The examples throughout this section reference a
  hypothetical machine, called *MACHINE*, manufactured by a
  hypothetical hardware manufacturer, called *VENDOR*.  The machine is
  based on a Freescale `QorIQ PowerPC 
  <http://www.freescale.com/webapp/sps/site/homepage.jsp?code=QORIQ_HOME>`_ CPU.

Every platform must add platform support to the Linux kernel.  In
general these types of files need to be added or modified:

======================================================       =======
File                                                         Purpose
======================================================       =======
``linux/arch/$(CPU)/boot/dts/vendor_machine.dts``            Device Tree Source (DTS) for the platform.
``linux/arch/$(CPU)/.../Kconfig``                            Kernel configuration fragment that allows 
                                                             the new platform to be selected.
``linux/arch/$(CPU)/.../Makefile``                           Makefile fragment detailing what C file to 
                                                             compile when the platform is selected.
``linux/arch/$(CPU)/.../vendor_machine.c``                   Platform support C file. Basic initialization and reset.
======================================================       =======

Device Tree Source
==================

The device tree is a simple tree structure of nodes and properties
that describe the hardware platform. Properties are key-value pairs,
and nodes may contain both properties and child nodes.  The nodes and
properties relevant to ONIE are discussed here.

=================   ==============   ================================================
Node                Property         Purpose
=================   ==============   ================================================
``/``               ``model``        A string that uniquely identifies the hardware 
                                     platform. For example, "vendor,model-XYZ".
``/``               ``compatible``   A string that identifies a platform that is 
                                     compatible with the model. For example, 
                                     "vendor,model".
``/localbus/nor``   ``partitions``   Node that partitions the NOR flash into 
                                     logical regions.  NAND flash could also be used.
=================   ==============   ================================================


``model`` and ``compatible`` Properties
---------------------------------------

The ``model`` and ``compatible`` properties are used by the kernel at
boot time to invoke the correct platform initialization routines. For example::

  /dts-v1/;
  / {
          model = "vendor,model-XYZ";
          compatible = "vendor,model";
  [ ... ]
  };

See how the ``compatible`` property is used in :ref:`platform_support_c_file` below.

.. _nor_flash_partition:

Boot Flash Partitioning
-----------------------

For an ONIE system the partitioning looks like:

============   ===============   =======
Region Label   Typical Size      Purpose
============   ===============   =======
open           ---               Leftover space for use by the operating system.
diag           ---               Space occupied by hardware diagnostics [optional].
onie           4MB               Space occupied by the ONIE kernel and ``initramfs``.
uboot-env      64KB (1 sector)   Space occupied by the U-Boot environment variables.
uboot          512KB             Space occupied by the U-Boot binary.
============   ===============   =======

Here is an example NOR flash node where the NOR flash is 128MB in size::

  nor@0,0 { 
          #address-cells = <0x1>;
          #size-cells = <0x1>;
          compatible = "cfi-flash";
          reg = <0x0 0x0 0x8000000>;
          bank-width = <0x2>;
          device-width = <0x2>;
          byteswap;
          partition@0 {
                  /* Entire flash minus (u-boot + onie + diag) */
                  reg = <0x00000000 0x07760000>;
                  label = "open";
          };      
          partition@1 {
                  /* Optional hardware diagnostic image, 4MB */
                  reg = <0x07760000 0x00400000>;
                  label = "diag";
          };      
          partition@2 {
                  /* 4MB onie */
                  reg = <0x07b60000 0x00400000>;
                  label = "onie";
          };
          partition@3 {
                  /* 128KB, 1 sector */
                  reg = <0x07f60000 0x00020000>;
                  label = "uboot-env";
                  env_size = <0x2000>;
          };
          partition@4 {
                  /* 512KB u-boot */
                  reg = <0x07f80000 0x00080000>;
                  label = "uboot";
          };
  };

Compare this partitioning scheme to the picture in :ref:`nor_flash_memory_layout`.

	
.. warning:: The region ``label`` properties within the nodes are
             important and must have the names as shown above. The
             ONIE application and operating system installers rely on
             these names.
	
.. warning:: The ``env_size`` property of the ``uboot-env`` partition
             indicates how much of the sector is used to store U-Boot
             environment variables. This value must match the
             ``CONFIG_ENV_SIZE`` macro defined in the U-Boot source
             file ``include/configs/onie_common_config.h``. This value
             is used at runtime to facilitate the reading and writing
             of U-Boot environment variables by an operating system
             installer.

.. note:: The ``diag`` partition is optional and is intended to be
          used by the hardware vendor to provide a diagnostic image.
          The size of the diagnostic partition is only constrained by
          the total size of the NOR flash.

Kconfig and Makefile
====================

The ``Kconfig`` file must contain an additional stanza for the new
platform. For example::

  config VENDOR_MACHINE
         bool "VENDOR Corporation Model MACHINE"
         select DEFAULT_UIMAGE
         help
           This option enables support for the VENDOR MACHINE networking platform

The ``Makefile`` file must contain an additional entry for the new
platform. For example::

  obj-$(CONFIG_VENDOR_MACHINE) += vendor_machine.o

.. _platform_support_c_file:

Platform Support C Files
========================

The platform support C files perform any boot time initialization
necessary for a particular platform.  Most of these initialization
codes can be ported from a similar hardware platform.

Any platform specific drivers are also considered to be "platform
support" C files.

The primary responsibilities of the platform support C files in ONIE
are:

- return true when the kernel probes for a device tree node whose
  compatible property is "vendor,machine". If it finds it, the kernel
  now knows what type of machine is running.

- if necessary, implement a platform-specific
  ``vendor_machine_restart()`` function to perform a system reboot.
  This may be necessary for platform that implement a CPLD-based reset
  mechanism, instead of using a standard CPU architecture reset
  mechanism.
