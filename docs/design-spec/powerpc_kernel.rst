*******************************************
PowerPC Linux Kernel and Device Tree Source
*******************************************

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

Every platform must add platform support to the Linux kernel.  To add
support for the platform, the following Linux kernel files must be
created or modified:

======================================================       =======
File                                                         Purpose
======================================================       =======
``linux/arch/powerpc/boot/dts/vendor_machine.dts``           Device Tree Source (DTS) for the platform.
``linux/arch/powerpc/platforms/85xx/Kconfig``                Kernel configuration fragment that allows 
                                                             the new platform to be selected.
``linux/arch/powerpc/platforms/85xx/Makefile``               Makefile fragment detailing what C file to 
                                                             compile when the platform is selected.
``linux/arch/powerpc/platforms/85xx/vendor_machine.c``       Platform support C file. Basic initialization and reset.
======================================================       =======

Device Tree Source
==================

The device tree is a simple tree structure of nodes and properties
that describe the hardware platform. Properties are key-value pairs,
and nodes may contain both properties and child nodes.  The nodes and
properties relevant to ONIE are discussed here.

=================   ==============   ==============================================
Node                Property         Purpose
=================   ==============   ==============================================
``/``               ``model``        A string that uniquely identifies the hardware 
                                     platform. For example, "vendor,model-XYZ".
``/``               ``compatible``   A string that identifies a platform that is 
                                     compatible with the model. For example, 
                                     "vendor,model".
``/localbus/nor``   ``partitions``   Node that partitions the NOR flash into 
                                     logical regions.
=================   ==============   ==============================================


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

NOR Flash Partitioning
----------------------

The NOR flash partitioning scheme is very important for U-Boot and
ONIE.  For the QorIQ platform, the ``/localbus/nor`` node defines how the
NOR flash is partitioned.

For an ONIE system with a 32MB NOR flash, the partitioning looks like:

============   ===============   =======
Region Label   Typical Size      Purpose
============   ===============   =======
open           ~ 28MB            Leftover space for use by the operating system.
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
                  /* Entire flash minus (u-boot + onie) */
                  reg = <0x00000000 0x07b60000>;
                  label = "open";
          };      
          partition@1 {
                  /* 4MB onie */
                  reg = <0x07b60000 0x00400000>;
                  label = "onie";
          };
          partition@2 {
                  /* 128KB, 1 sector */
                  reg = <0x07f60000 0x00020000>;
                  label = "uboot-env";
                  env_size = <0x2000>;
          };
          partition@3 {
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
	
.. warning:: The env_size property of the uboot-env partition
             indicates how much of the sector is used to store U-Boot
             environment variables. This value must match the
             ``CONFIG_ENV_SIZE`` macro defined in the U-Boot source
             file ``include/configs/onie_common_config.h``. This value
             is used at runtime to facilitate the reading and writing
             of U-Boot environment variables by an operating system
             installer.

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

Platform Support C File
=======================

The platform support C file performs any boot time initializations
necessary for a particular platform.  Most of these initialization
codes can be ported from a similar hardware platform, like a P2020
reference platform.

If the platform uses a non-standard reset mechanism -- for example, to reset the
board, it is required to write to a CPLD -- that code would live in the
platform support C file.

Here is a snippet from a platform support C file for a P2020-based platform:

.. code-block:: c

  /* Called during reboot and system shutdown */
  static void vendor_machine_restart(char *cmd)
  {
          local_irq_disable();
          writeb(0, (cpld_regs + CPLD_RESET_REG));
          while (1);
  }
  /*
   * Called very early, device-tree isn't unflattened
   */
  static int __init vendor_machine_probe(void)
  {
          unsigned long root = of_get_flat_dt_root();
          if (of_flat_dt_is_compatible(root, "vendor,machine"))
                  return 1;
          return 0;
  }
  define_machine(vendor_machine) {
          .name           = "VENDOR Corporation Model MACHINE",
          .probe          = vendor_machine_probe,
          .setup_arch     = vendor_machine_setup_arch,
          .init_IRQ       = vendor_machine_pic_init,
          .show_cpuinfo   = vendor_machine_show_cpuinfo,
          .get_irq        = mpic_get_irq,
          .power_save     = e500_idle,
          .restart        = vendor_machine_restart,
          .calibrate_decr = generic_calibrate_decr,
          .progress       = udbg_progress,
  };
	
The ``vendor_machine_probe()`` is called by the kernel at boot
time. It searches the device tree for a node whose compatible property
is "vendor,machine". If it finds it, the kernel now knows what type of
machine is running.
	
The platform-specific ``vendor_machine_restart()`` function is called
by the kernel during system reboot. In this example it is necessary to
write to a reset register within a board CPLD. Some systems may not
need this as they can simply use the ``HRESET_REQ`` signal provided by
the P2020.
