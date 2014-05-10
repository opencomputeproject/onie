Porting Guide
=============

This section describes requirements and general guidelines to follow
when porting ONIE to a new platform.  Also, the :ref:`testing_guide`
should be used to validate the ONIE implementation.

Porting U-Boot
--------------

When porting U-Boot, the following items should be checked and
verified:

* Ethernet management PHY LEDs should function correctly.
* Front panel status LEDs are set appropriately - check power, fans
  and set any corresponding LEDs.
* Fan speeds set to 40-50% duty cycle.
* Verify MAC address and serial number are exported as environment variables.
* Confirm CONFIG_SYS_CLK_FREQ and CONFIG_DDR_CLK_FREQ oscillators by
  visual inspection.  For example, if an oscillator is 66.666MHz use
  66666000 not 66666666, as the latter will lead to skew.
* Issue "INFO" message if a PSU is not detected or is in a failed state.
* Verify the "INSTALL" instructions from the machine directory work.
  These are the instructions used to install ONIE from the U-Boot
  prompt. If the INSTALL instructions need updating, fix them.

ONIE DTS (Device Tree)
----------------------

When porting the ONIE kernel the following ``.dts`` (device tree) entries
should be checked and verified:

* The RTC is in the ``.dts`` file and works correctly.
* The MDIO/PHY interrupts are correct in ``.dts``.
* Disable unused serial consoles in ``.dts``.
* Verify all EEPROMs (including SPDs) are accessible via ``sysfs`` using
  ``hexdump``. Set the "label" property accordingly:

  * board_eeprom – for the board EEPROM

  * psu1_eeprom / psu2_eeprom – for the power supply unit (PSU) eeproms

  * port1, port2, ... port52 – for the SFP+/QSFP eeproms

* For PCA95xx I2C muxes, use the "deselect-on-exit" property.
* I2C nodes use the "fsl,preserve-clocking" property.

ONIE Kernel
-----------

* Inspect the boot log and ``dmesg`` output, looking for any errors or
  anything unusual.
* Inspect ``cat /proc/interrupts`` – are the expected interrupts
  enabled?
* If the platform has CPLDs, try accessing some registers using the
  ``iorw`` command. Can you read a version register?
* Verify the demo NOS compiles and installs OK.
* If the box has USB ports, plug in a USB stick and see if you can
  mount a partition.
* Verify the ``onie-nos-install <demo NOS installer URL>`` command works from
  rescue mode.
* Verify the ``onie-self-update <ONIE updater URL>`` command works from
  rescue mode.
