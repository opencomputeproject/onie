.. Copyright (C) 2022,2023 Michael Shych <michaelsh@nvidia.com>
   Copyright (C) 2021,2022 Alex Doyle <adoyle@nvidia.com>
   Copyright (C) 2019,2020 Alex Doyle <adoyle@cumulusnetworks.com>
   Copyright (C) 2013,2014,2015,2016,2017,2018 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0

################################
Open Network Install Environment
################################

  The Open Network Install Environment (ONIE) defines an open "install
  environment" for modern networking hardware. ONIE enables an open
  networking hardware ecosystem where end users have a choice among
  different network operating systems.

  Please read the :ref:`onie_overview`, the :ref:`user_guide` and the
  :ref:`full_design_spec` for more information.

  .. raw:: html

    Browse the source code and participate <a href="https://github.com/opencomputeproject/onie">
    <svg class="octicon-mark-github" viewBox="0 0 16 16" version="1.1" width="16" height="16" aria-hidden="true"><path fill-rule="evenodd" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8z"/></svg>
    opencomputeproject/onie</a>.

News
====
Aug 21, 2024
  Released version `2024.08
  <https://ocp-all.groups.io/g/OCP-ONIE/message/323>`_

Feb 20, 2024
  Released version `2024.02
  <https://ocp-all.groups.io/g/OCP-ONIE/message/309>`_

  Add support of 1 new Netberg platform.

Nov 15, 2023
  Released version `2023.11
  <https://ocp-all.groups.io/g/OCP-ONIE/message/301>`_

  Add support of 10 new Accton platforms.

Aug 16, 2023
  Released version `2023.08
  <https://ocp-all.groups.io/g/OCP-ONIE/message/291>`_

  Add support of 2 new Accton platforms and multple changes of existing Accton systems.

May 17, 2023
  Released version `2023.05
  <https://ocp-all.groups.io/g/OCP-ONIE/message/280>`_

   Add support of 3 new Accton and 1 Netberg platforms, patches of efivars package.

Feb 20, 2023
  Released version `2023.02
  <https://ocp-all.groups.io/g/OCP-ONIE/message/265>`_

  Add support of 6 new Pegatron platforms.

Aug 13, 2022
  Released version `2022.08
  <https://ocp-all.groups.io/g/OCP-ONIE/message/255>`_

  The master branch supports four new platforms, and DNS resolution has been fixed for armv8a builds.

May 01, 2022
  Released version `2022.05
  <https://ocp-all.groups.io/g/OCP-ONIE/message/248>`_

  The master branch supports three new hardware platforms, and an Alpha Networks design update.

Feb 12, 2022
  Released version `2022.02
  <https://ocp-all.groups.io/g/OCP-ONIE/message/232>`_

  The master branch supports four new hardware platforms, and DropBear was upgraded.

Nov 16, 2021
  Released version `2021.11
  <https://ocp-all.groups.io/g/OCP-ONIE/message/222>`_

  This releaese has many upgraded components, so building the master branch requires Debian 10, and platforms that have not been updated can still build in a Debian 9 environment using the 2021.08 branch.

  An `ONIE Secure Boot build and demonstration
  <https://youtu.be/Oq4FWw9lkwQ>`_ tutorial is available to introduce the new features in this release.  

Aug 31, 2021
  Release candidate version `2021.11-rc1
  <https://ocp-all.groups.io/g/OCP-ONIE/message/202>`_

  This releaese has many upgraded components, so building the master branch requires Debian 10, and platforms that have not been updated can still build in a Debian 9 environment using the 2021.08 branch.

  An `ONIE Secure Boot build and demonstration
  <https://youtu.be/Oq4FWw9lkwQ>`_ tutorial is available to introduce the new features in this release.  

Aug 03, 2021
  Released version `2021.08
  <https://ocp-all.groups.io/g/OCP-ONIE/message/200>`_
  This is the last widely compatible release before component upgrade requires platform updates.

May 12, 2021
  Released version `2021.05
  <https://ocp-all.groups.io/g/OCP-ONIE/message/186>`_

February 11, 2021
  Released version `2021.02
  <https://ocp-all.groups.io/g/OCP-ONIE/message/160>`_

January 12, 2021
  Introduced development branch `component-upgrade-2020
  <https://github.com/opencomputeproject/onie/commits/component-upgrade-2020>`_
  It features newer software components, and much less testing.

November 14, 2020
  Released version `2020.11
  <https://ocp-all.groups.io/g/OCP-ONIE/message/144>`_

August 18, 2020
  Released version `2020.08
  <https://ocp-all.groups.io/g/OCP-ONIE/topic/onie_2020_08_quarterly/76276459>`_

May 14, 2020
  Released version `2020.05
  <https://ocp-all.groups.io/g/OCP-ONIE/message/121>`_

April 24, 2020
  Open Compute talk on `Buiding ONIE in a Docker container
  <https://www.youtube.com/watch?v=-5onRbZA0QQ>`_

February 19, 2020
  Released version `2020.02
  <https://ocp-all.groups.io/g/OCP-ONIE/message/97>`_

November 24, 2019
  Released version `2019.11
  <https://ocp-all.groups.io/g/OCP-ONIE/topic/onie_release_2019_11_is_now/61879934?p=,,,20,0,0,0::recentpostdate%2Fsticky,,,20,2,0,61879934>`_

August 15, 2019
  Released version `2019.08
  <https://ocp-all.groups.io/g/OCP-ONIE/topic/onie_quarterly_release/32900032?p=,,,20,0,0,0::recentpostdate%2Fsticky,,,20,2,0,32900032>`_  

May 7, 2019
  Released version `2019.05
  <https://ocp-all.groups.io/g/OCP-ONIE/message/45>`_

February 12, 2019
  Released version `2019.02
  <https://ocp-all.groups.io/g/OCP-ONIE/topic/onie_2019_02_is_now_available/29772448?p=,,,20,0,0,0::recentpostdate%2Fsticky,,,20,2,0,29772448>`_
  
November 14, 2018
  Released version `2018.11
  <https://ocp-all.groups.io/g/OCP-ONIE/topic/onie_2018_11_release_is_now/28139886?p=,,,20,0,0,0::recentpostdate%2Fsticky,,,20,2,0,28139886>`_
  Notes are also available on the old list archives `server
  <http://lists.opencompute.org/pipermail/opencompute-onie/2018-November/001774.html>`_

September 5, 2018
  OCP `Networking Workshop Presentation
  <https://www.youtube.com/watch?v=p86mMKZqh4g>`_

August 14, 2018
  Released version `2018.08
  <http://lists.opencompute.org/pipermail/opencompute-onie/2018-August/001723.html>`_

May 16, 2018
  Version ``2018.05`` now supports :ref:`x86_uefi_secure_boot`

May 16, 2018
  Released version `2018.05
  <http://lists.opencompute.org/pipermail/opencompute-onie/2018-May/001688.html>`_

March 27-28, 2018
  OCP U.S. Summit 2018 Presentation `Video
  <https://www.youtube.com/watch?v=FCJJxzRtVro>`_ and `Slides
  <http://www.opencompute.org/assets/Uploads/ONIE-SecureBoot-OCP18.pdf>`_

Read more :ref:`news`

.. toctree::
   :maxdepth: 2
   :hidden:

   overview/index
   Download <download/index>
   community/index
   News <news/index>
   user-guide/index
   design-spec/index
   testing/index
   developers/index
   cli/index
   faq/index
