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
  of normally 4 weeks.

- While this merge window is open, new features can be added to the
  ONIE source tree.

- After the merge window closes, no new features may be added.  This
  allows for a release candidate phase which is intended to fix bugs
  and regressions.  During this stabilization period, only patches
  that contain bug fixes get applied.

- After the merge window, the release cycle allows for about 2 months
  of testing before generating the next release.

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

  ONIE v2013.11-rc1 | Release candidate 1 for November 2013
  ONIE v2013.11.00  | Stable Release for November 2013
  ONIE v2013.11.01  | Bug fix release 01 for November 2013

Current Status
--------------

The Merge Window for the next release (v2014.05) is :red:`closed`.

Release "v2014.02" went out on February 14, 2014.

Release "v2024.05" is scheduled to go out on May 14, 2014.

Future Releases
---------------

Please note that the following dates are for information only and
without any formal commitment.

.. csv-table:: Future ONIE Releases and Merge Windows
  :header: "Version", "Merge Window Closes", "Approx. Release Date"
  :delim: |

  v2014.05 | Wed, Mar 12, 2014 | Wed, May 14, 2014
  v2014.08 | Wed, Jun 11, 2014 | Wed, Aug 13, 2014
  v2014.11 | Wed, Sep 10, 2014 | Wed, Nov 12, 2014
  v2015.02 | Wed, Dec 17, 2014 | Wed, Feb 11, 2015
