Overview
========

Open Network Linux has a number of internal APIs to simplify porting to
new hardware.  

To support a new switch/device, there are three large software components
that need device-specific drivers:

1. The ONL/ONIE installer -- how to actually install and boot ONL using ONIE
2. The ONLP platform drivers -- how to manage hardware once ONL is running
3. Any packet forwarding device specific settings 
    (e.g., front panel port mappings, pre-emphesis settings)

ONL provides plugable driver modules for (1) and (2) but currently 
provides no support for (3) -- this is work in progress.

The rest this PortingGuide is divided into two parts: (1) creating
the ONIE installer driver and (2) creating the ONLP platform driver.

ONL Installer
==================

About ONIE
----------

ONIE (the Open Network Installation Environment - http://onie.org)
is a small piece of software that ONL expects to exist on every
switch, pre-installed by the switch vendor.  ONIE provides the
installation and management utilities to install/uninstall/rescue
a Network Operating System (a "NOS") like ONL.  While ONIE is a
stand alone operating system in its own right, it is intentionally
stripped down and has few features outside of the bare minimum
needed to bootstrap a system and invoke an NOS installer program.

ONL Installer Operation
-----------------------

ONL has an ONIE-compatible installation script called the 'ONL
Installer'.  That is, the ONL installer is a device-specific
self-extracting shell script that, when run from ONIE, partitions
available storage, installs the ONL switch image file (SWI) on to
disk, and sets up the underlying boot loader (e.g., uboot or grub)
with the appropriate settings so that on boot, by default, ONL loads
correctly on the device.  So, to port ONL to a new switch, a number
of installer drivers, including for disk partitioning, installation,
booting, and python integration need to be written.

ONL Installer Example Code
--------------------------

TL; DR :: If you want to just jump to the code, look at the drivers
in $ONL/components/all/platform-config/* -- in particular, the powerpc-as5710-54x-r0b
driver is a good example.  Copy the directory/file layout and naming conventions and
see how the driver code is called from $ONL/builds/installer/installer.sh

ONL Installer file layout
-------------------------
All the installer drivers are stored in $ONL/components/all/platform-config/$platform,
where $platform corresponds to the ONIE platform identifier string.  This string is used
to identify which set of drivers to load (ONL supports many systems) at boot time and is 
critical that it matches the ONIE identifier exactly.  The rest of the directory structure
for the installer driver is as follows:
    ./$platform/
    ./$platform/Makefile                    # copy from existing driver
    ./$platform/Makefile.comp               # copy from existing driver
    ./$platform/deb/...                     # debian build instruction, copy and update
    ./$platform/src/name                    # text file with that contains "$platform"
    ./$platform/src/boot/detect.sh          # Script that returns 0 if run on $platform, 1 otherwise
    ./$platform/src/boot/$platform          # Script run on boot that populates device/hardware
                                            #       specific ONL OS abstractions (see below)
    ./$platform/src/install/$platform.sh    # Script called from installer.sh to partition
                                            # and install ONL and setup boot params (see below)
    ./$platform/src/python/onlpc.py         # Platform specific python library (see below)
    ./$platform/src/{sbin,etc}              # Platform specific files to be added to file system

ONL Installer src/boot drivers
------------------------------

The $platform/src/boot/$platform script is in charge of writing
the ONL boottime hardware abstraction configuration.  Because each
device has a different storage driver, storage device, management
network device, etc., ONL uses a series of config files to map the
specific hardware (an ethernet driver) to a device-agnostic form
(e.g., primary management interface).

The following files need to be populated by the $platform boot script:
* /etc/onl_net : The PCI device name and interface name of the management ethernet
* /etc/onl_block : The PCI device and type (e.g., 'flash') of the storage device
* /etc/onl_kernel: Which ONL kernel to load.  FIXME: how to find allowed kernel names?
* /etc/onl_initrd: Which initrd to load.  FIXME: how to find allowed initrd names?
* [optional] /etc/onl_nokexec : if this file exists, then keep using the kernel from the loader
* /etc/onl_mounts : The devices that correspond to /mnt/flash and /mnt/flash2 at boot
* /etc/fw_env.config : The device and configuration of the firmware device, for fw_printenv, fw_setenv

FIXME: This platform script is linked to as /etc/onl_rc.boot and is called from /etc/init.d/rc.boot (sourced
from $ONL/builds/swi/all/shared/etc/init.d/rc.boot).


ONL Installer src/install drivers
---------------------------------
The $platform/src/install/$platform.sh driver is called from the main installer script and has the job
of:
1) Identifying and partitioning the device specific storage
2) Deciding the file format of the target boot partition to install the ONL loader image
3) Deciding how to update the bootloader, e.g., in the case of uboot, what the $nos_bootcmd variables
    should be.

The contents of this driver are sourced into the installer.sh and
so the variables and functions are called in various places.  There
are an excess of ways that switches can be built (what storage
types, etc.) and how they boot, so seading the installer.sh code
along with the example platform driver code seems to be the best
bet here -- FIXME!

For example, looking at the driver
$ONL/components/all/platform-config/powerpc-as5710-54x-r0b/src/install/powerpc-as5710-54x-r0b.sh
the driver first sets "platform_loader_raw=1" which tells the
installer that the boot partition has no file format (as opposed
to ext2fs or fat - it is type 'raw').  Then it has the platform_bootcmd as:

   platform_bootcmd='usb start; usbboot 0x10000000 0:1; setenv bootargs console=$consoledev,$baudrate onl_platform=powerpc-as5710-54x-r0b; bootm 0x10000000'
 
    Which is a string of uboot commands, that:
    1) usb start -- initialize the usb subsystems
    2) Using the usb boot loader, load the contents of device 0, partition 1 (0:1) into memory range 0x10000000 
    3) Pass a number of env variables to the kernel at boot via $bootargs
    4) Actually just jump to memory 0x10000000 and start running (bootm 0x100000000)

The sequence of exact boot commands will vary with version of uboot
(or other boot loader), available storage, and other device specific
properties.


ONL Installer src/python drivers
--------------------------------

NOTE: Older style drivers (e.g., powerpc-quanta-ly2-r0/src/python/onlpc.py)
were written before ONLP existed and thus do much more than newer
style drivers (e.g., powerpc-as5710-54x-r0b/src/python/onlpc.py)
and should be largely ignored for new porting projects.  For newer
style drivers, there is mostly glue code for the CLI to be able to
pretty print device and vendor names.

FIXME: Verify this is true.

FIXME: onlpy.py or onlpc.py -- both are used!?!

FIXME: Find out how these are used:
        platinfo.LAG_COMPONENT_MAX : 16,
        platinfo.PORT_COUNT : 52,

FIXME: Verify that as6700             platinfo.PORT_COUNT : 52, is correct - 32 ports, no?





Open Network Linux Platform ("ONLP") APIs
=========================================

Every new networking switch/router/box has a unique layout of which
devices (fans, power supplies, LEDs, SFP/SFP+/QSFP, temperature
sensors, etc.) connect to which I/O devices (I2C, GPIO, etc.) and
how they are managed (FPGA, CPLD).  Rather than mandate one hardware
approach or assume that there exists a BIOS to take care of this
work for us (some platforms have a BIOS, some do not; some drivers
are not supported by BIOS), ONL has created an abstraction layer
to inventory, manage, and monitor these devices.


ONLP Application APIs
---------------------

If you want to create an application in ONL that builds on top of the
platform, the "application to platform" APIs are found in:

  $ONL/submodules/onlp/modules/onlp/module/inc/onlp

This section will have to become better documented, but look at the example
code in the `onlpdump` driver for how to call the ONLP APIs as an application.

At a high-level, each hardware device is given a unique Object ID
(OID).  Each type of device has a number of different properties that
is querable/programmable (e.g., read/set fan speed, query an SFP+ port
status, etc.)  and a mechanism for negotiating hardware capabilities
(e.g., is the fan speed setable?  reversible? does this SFP have a
hardware interupt bit on link down?).

The ONLP API is has internal locking so it supports multiple concurrent
callers.  That said, there is no inter-application internal hardware
contention resolution, so, if for example one application wants the fans
at 25% and another wants them at 75%, the last caller wins.

Applications start by getting a tree of OIDs from the platform using the 
 onlp_sys_init(void) and onlp_sys_info_get() calls.  There exist a number
of macros for interogating OID types in oid.h, ala ONLP_OID_IS_*().


ONLPI Driver APIs
-----------------

If you want to create a driver so that your new hardware can work with
ONL, the "platform to hardware" APIs are found in:

  $ONL/submodules/onlp/modules/onlp/module/inc/onlp/platformi

This section will have to become better documented,
but look at the example driver 'onlpie' implementation at
$ONL/ONL/submodules/onlp/modules/onlpie/module/src/.  Many driver
implementations have been written and they will become available over
time.

At a high-level, the driver is responsible for providing implementations
of the various 'platformi' APIs, e.g., sysi.h, fani.h, etc.  Whether
these implementations are provided via user-space or kernel space is an
implementation detail left to the driver maintainer.

In terms of programming paradigm, the application calls into the platform
code (see above) and then the platform code calls into the driver.  The main
platform code handles locking to ensure that the underlying driver code does
not need to be re-entrant or handle concurrent API calls.  This dramatically
simplifies the ONLPI driver code and we have found in most cases that code
from existing projects (e.g., from an ODM diagnostic utilities) can be readily
cut and pasted into place.

Feedback on these APIs are welcome.
