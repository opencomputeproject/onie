.. Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. _multiple_cpu:

=======================================
Machines That Share a Common CPU Module
=======================================

Hardware vendors often ask how best to support ONIE on a family of
machines that all share a common CPU module.  This section describes
infrastructure available in ONIE to help with this reality.

.. note::

  The infrastructure described in this section first became available
  with the 2017.11 release.

The hardware systems consist of a pluggable CPU module and a "base
board" that contains the switching ASIC silicon and front panel ports.

The CPU module contains the main CPU subsystems, including the CPU,
DRAM, storage (like mSATA and nvme m.2), CPLDs, eth0, serial console,
etc.

This design makes great sense for a hardware manufacturer -- they can
mass produce the CPU module independently of the base boards, allowing
them to support a variety of switching ASICs with a single CPU module.

The question in an ONIE environment is "how to identify the machine?"
when the CPU module is common.  The hardware vendors would like to
build ONIE once, just for the CPU module.  It complicates their life
to tailor an ONIE build for each base board variant.

At the same time NOS vendors need a clean way to identify the system.
If 10 different systems with a common CPU module all report
"x86_64-vendor_common_cpuXYZ-r0" for 10 different base boards that is
not helpful.  It complicates the NOS vendor's life to add vendor and
platform specific "peek and poke" code to their installers to figure
out what the base board is.

At a hardware level, the base board identifying information is
typically contained in the ONIE EEPROM, using one of the optional TLV
types like "Part Number"(0x22) or "Product Name"(0x21).  Sometimes the
information is contained in a CPLD.  The details of the identifying
information is not so important for this discussion.

One ONIE Image for the CPU Module
---------------------------------

The idea is to have a single ONIE "machine" for the CPU module and
detect at run time what the baseboard is.
    
The platform identification originates from ``/etc/machine.conf``, a
portion of which is now derived at run time.  Along with this a new
configuration variable, ``onie_build_machine`` is introduced.

Changes to ``/etc/machine.conf``
--------------------------------

Previously this file was entirely built at compile time.  This file is
now a small wrapper script that sources two new files,
``/etc/machine-build.conf`` and ``/etc/machine-live.conf``.

The contents of ``/etc/machine.conf`` looks like::

  # Source build-time machine configuration
  . /etc/machine-build.conf

  # Source run-time machine configuration if available
  [ -r /etc/machine-live.conf ] && . /etc/machine-live.conf

  # Use onie_machine if set, otherwise use build_machine
  onie_machine=${onie_machine:-$onie_build_machine}

  onie_platform="${onie_arch}-${onie_machine}-r${onie_machine_rev}"


- ``/etc/machine-build.conf`` -- this file is completely built at
  **compile time** and only contains information known at build time.
  This file introduces a new configuration variable,
  ``onie_build_machine``, which is the ONIE machine specified at compile
  time.  For example this would be the ONIE machine name of the common
  CPU module.

- ``/etc/machine-live.conf`` -- this file is built at **run time**.  A
  boot time init script sources a platform specific file if it exists,
  executes the ``gen_live_config()`` function and stores the output in
  ``/etc/machine-live.conf``.  By default this function outputs nothing,
  but a platform can override it produce a runtime ONIE machine name.

Using this mechanism, a machine can redefine ``onie_machine`` and
``onie_switch_asic`` at run time.  To do this, a machine defines a
small script in the source tree at
``machine/<vendor>/rootconf/sysroot-lib-onie/gen-config-platform``,
which include a definition of the ``gen_live_config()`` function.

If a machine does not define ``gen-config-platform``,
i.e. ``/etc/machine-live.conf`` is empty, then the contents of
``onie_build_machine`` is used to set ``onie_machine``.  This is
backwardly compatible with how ONIE worked previously.

How This Affects ONIE Updates
-----------------------------

When ONIE updates itself, it will now check that the running
``onie_build_machine`` matches the ``onie_build_machine`` of the
proposed update image.  Previously it checked that ``onie_machine``
matched between runtime and the image.

Working Example
---------------

For an example look at the ``kvm_x86_64`` virtual machine.  This
machine contains an example ``sysroot-lib-onie/gen-config-platform``
file that can dynamically generate different run time machine names
based on the environment.

To try out the kvm_x86_64 example, set the ``live_machine`` and
``live_asic`` variables on the GRUB command line when booting ONIE.
At boot time the kvm_x86_64 machine detects these and dynamically
generates a run time machine name.

.. note::

   This is just a toy example.  For a real hardware platform, the base
   board identifying information is typically contained in the ONIE
   EEPROM, using one of the optional TLV types like "Part
   Number"(0x22) or "Product Name"(0x21).  Sometimes the information
   is contained in a CPLD.
