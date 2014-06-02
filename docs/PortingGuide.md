Overview
========

Open Network Linux has a number of internal APIs to simplify porting to
new hardware.

The most important of which is the Open Network Linux Platform (ONLP)
API driver.


Open Network Linux Platform ("ONLP") APIs
=========================================

Every new networking switch/router/box has a unique layout of which
devices (fans, power supplies, LEDs, SFP/SFP+/QSFP, temperature sensors,
etc.) connect to which I/O devices (I2C, GPIO, etc.) and how they are
managed (FPGA, CPLD).  Rather than mandate one hardware approach or
assume that there exists a BIOS to take care of this work for us (some
platforms have a BIOS, some do not), ONL has created an


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
