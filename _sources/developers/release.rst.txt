.. Copyright (C) 2022,2023 Michael Shych <michaelsh@nvidia.com>
.. Copyright (C) 2021,2022 Alex Doyle <adoyle@nvidia.com>
.. Copyright (C) 2019,2020 Alex Doyle <adoyle@cumulusnetworks.com>   
.. Copyright (C) 2014,2018 Curt Brune <curt@cumulusnetworks.com>
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

  2024.11 | Wed, Oct 16, 2024 | Wed, Nov 20, 2024
  2025.02 | Wed, Jan 15, 2025 | Wed, Feb 19, 2025
  2025.05 | Wed, Apr 16, 2025 | Wed, May 21, 2025
  2025.08 | Wed, Jul 16, 2025 | Wed, Aug 20, 2025
  2025.11 | Wed, Oct 22, 2025 | Wed, Nov 19, 2025

Making a Release
----------------

Making a release entails the following:

#. Verify various boards compile
#. Create release notes
#. Create a release branch and tag it
#. Send off email to the community

Release Notes
^^^^^^^^^^^^^

Some guidelines for creating release notes.  First look at a `previous
set of release notes
<https://github.com/opencomputeproject/onie/releases/tag/2018.05>`_. for
inspiration.  Things to include:

- major changes
- major features
- new hardware platforms
- new build infrastructure
- bug fixes related to hw platforms
- bug fixes related to ONIE or build system

Looking at the list of commits from the previous release up to the
current HEAD can be inspiring::

  $ git log --oneline 2018.05..HEAD
  092ff43a98ed grub-arch: show BIOS mode during booting up
  c1d259c9b5e0 NXP arm64 add TLV mtd hw-info partitions for onie-syseeprom
  5f619890b179 installer/u-boot-arch/install-arch: update_uboot_env support arm64
  aa5036caeee1 u-boot.make: UPDATER_UBOOT_NAME should still be u-boot.bin even with dtb enable
  c602a421609a Adding newline to delta/ag9064 busybox config. This fix ensures, that the file is properly parsed.
  ....

Release Branch
^^^^^^^^^^^^^^

Creating the release branch and tag is automated using the
``build-config/scripts/create-release`` script.  The usage follows::

  linux:$ ./build-config/scripts/create-release <X.Y.Z version> <release_notes_file>

The script will:

- create a branch called ``<version>br``
- add a new file, ``build-config/conf/onie-release``, containing the
  supplied version string
- create a tag called ``<version>`` (without the 'br' suffix)
- push both the branch and the tag to the upstream ONIE repo

Release Statistics
^^^^^^^^^^^^^^^^^^

For fun, generate some release statistics for sharing with the
community.  See the description of the `statistics scripts
<https://github.com/opencomputeproject/onie/tree/master/contrib/git-stats>`_.


Send Email
^^^^^^^^^^

Notify the community via the mailing list, including the URL of the
github release, the git statistics and the complete release notes.

Add anything else that is worthy of highlighting towards the top.
Look at a previous email for an `example
<https://ocp-all.groups.io/g/OCP-ONIE/message/186>`_.
