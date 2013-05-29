Hardware Requirements
=====================

ONIE has modest hardware requirements.  Undoubtedly the NOS has
additional hardware requirements.

.. note::
  ONIE has no specific CPU architecture requirements -- it is Linux.
   
  The dominant architecture today, however, is Freescale's QorIQ PowerPC [#powerpc]_.
   
  The documentation in this section currently focuses on that
  architecture and the associated U-Boot [#uboot]_ boot loader.
   
  Supporting the x86 architecture is on the road map.

==============================  ==============
Required Hardware               Purpose
==============================  ==============
U-Boot compatible CPU Complex	The CPU complex must be supported by U-Boot, e.g. PowerPC, ARM, MIPS.
8MB NOR boot flash (minimum)	U-Boot and the ONIE kernel and applications reside in NOR flash.
Non-volatile board information  An EEPROM to store board information
                                and manufacturing data, like the
                                device serial number and network MAC
                                address.
Ethernet management port	Required to download an operating system installer.
==============================  ==============

.. _non_volatile_board_info:

Non-Volatile Board Information
------------------------------

.. todo:: Fill in with recommended EEPROM format.

.. rubric:: Footnotes

.. [#powerpc] `QorIQ PowerPC <http://www.freescale.com/webapp/sps/site/homepage.jsp?code=QORIQ_HOME>`_
.. [#uboot]   `U-Boot <http://www.denx.de/wiki/U-Boot>`_
