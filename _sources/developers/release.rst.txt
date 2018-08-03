.. Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

.. role:: red
.. role:: green
.. raw:: html

    <style>
         .red   {color:red; font-weight: bold}
         .green {color:green; font-weight: bold}
    </style>

.. _release_cycle:

=========================
Source Code Release Cycle
=========================

- ONIE will be released (approximately) every 3 months.

- Under normal conditions, the release date will be a Wednesday around
  mid-month.

- Immediately following each release, there will be a "merge window"
  of normally 8 weeks.

- While this merge window is open, new features can be added to the
  ONIE source tree.

- After the merge window closes, no new features may be added.

- After the merge window closes, new hardware platforms may be added
  that do not change the core ONIE code.
        
- This allows for a release candidate phase which is intended to fix
  bugs and regressions.  During this stabilization period, only
  patches that contain bug fixes get applied.

- After the merge window closes, the release cycle allows for about 4
  weeks of testing before generating the next release.

.. note:: While we try to adhere to the release schedule, we will not
   hesitate to delay a release for good reasons.  The code will be
   released when it is considered ready without caring too much about the
   announced deadline.

Version Numbers
---------------

Starting with the release in November 2013, the names of the releases
changed from numerical release numbers into timestamp-based
numbering. Regular releases are identified by names consisting of the
calendar year and month of the release date.

Additional fields (if present) indicate release candidates or bug fix
releases in "stable" maintenance trees.

Examples:

.. csv-table:: ONIE Version Numbers
  :header: "Version", "Comments"
  :delim: |

  ONIE 2015.11-rc1 | Release candidate 1 for November 2015
  ONIE 2015.11     | Stable Release for November 2015
  ONIE 2015.11.01  | Bug fix release 01 for November 2015

Future Releases
---------------

Please note that the following dates are for information only and
without any formal commitment.

.. csv-table:: Future ONIE Releases and Merge Windows
  :header: "Version", "Merge Window Closes", "Approx. Release Date"
  :delim: |

  2017.08 | Wed, Jul 19, 2017 | Wed, Aug 16, 2017
  2017.11 | Wed, Oct 18, 2017 | Wed, Nov 15, 2017
  2018.02 | Wed, Jan 17, 2018 | Wed, Feb 14, 2018
  2018.05 | Wed, Apr 18, 2018 | Wed, May 16, 2018
