Contributing to ONIE
====================

This section describes how to participate in the ONIE project.

Open Source Development Process
-------------------------------

The description is somewhat informal, but captures the spirit of the
effort.  It is based on how other projects (Linux kernel and U-Boot,
for example) manage.

Please read `The Lifecycle of a Patch
<http://www.linuxfoundation.org/content/22-lifecycle-patch>`_.

Here is how git "open source" development works. For nearly everything written
below, you could replace the word "ONIE" with "Linux kernel".

1.  There is a public git repo for ONIE.

2.  A few people have commit privilege to the repo, also known as
    "maintainers" or "custodians" -- at the moment for ONIE that's a few
    people from Cumulus Networks and a few people from Big Switch.

3.  The entire world has read privilege to the repo.

4.  People without commit privilege want to contribute (a hardware
    vendor for example), called a "contributor".  They open a
    discussion around their problem on the mailing list.

5.  Next the contributor makes a patch and sends it to the mailing
    list, including a maintainer.

6.  The maintainer, mailing list and contributor kick the patch
    around, look it over, make some changes, goes through some
    revisions.

7.  Eventually the patch is deemed acceptable and a maintainer applies
    the patch to the git repo.

8.  The patch contains all the attribution information.  The git
    history will show that the contributor made the patch and changes.
    The maintainer merely applied the patch to the repo.

After the patch is applied it will be available in the common ONIE
code base for everyone.

Step #6 can seem kind of brutal at first -- your code gets beat up in
public on the mailing list.  But it is not personal.  It is all about
code quality, sound design and being open.

.. _creating_stg_patches:

Patching ONIE Using stgit
-------------------------

This technical note describes the workflow used at Cumulus Networks to
develop and maintain the patches that comprise the bulk of ONIE.

By way of example, patching U-Boot for the Freescale P2020RDB-PCA
evaluation board will be described in detail, as hardware partners are
very often interested in modifying U-Boot.

The patching techniques and principles described can also be applied
to any other ONIE sub-project.

Background
^^^^^^^^^^

The ONIE project itself is comprised of several upstream sub-projects,
like U-Boot, the Linux kernel, uClibc, BusyBox, etc.  Without these
sub-projects ONIE would not exist.  A large portion of the ONIE source
code is patches applied to the various sub-projects.

Working with and managing these patches forms a big part of
"developing ONIE".

For each of the sub-projects we keep a "patch stack" in the ONIE repo.
These files are in the onie/patches directory::

  build-04:~/onie$ ls -l patches
  total 28
  drwxr-xr-x 2 build build 4096 Mar  4 08:51 busybox
  drwxr-xr-x 2 build build 4096 Mar  4 08:51 crosstool-NG
  drwxr-xr-x 2 build build 4096 Feb 14 17:50 e2fsprogs
  drwxr-xr-x 2 build build 4096 Mar  4 08:51 gptfdisk
  drwxr-xr-x 2 build build 4096 Mar  4 08:51 kernel
  drwxr-xr-x 2 build build 4096 Mar  4 08:51 popt
  drwxr-xr-x 2 build build 4096 Mar  4 08:51 u-boot

U-Boot Patch Files
^^^^^^^^^^^^^^^^^^

The tool we use to manage patch stacks is called ``stg``, short for
`stacked git <https://gna.org/projects/stgit>`_.  It lets us manage a
stack of patches against an upstream project.  You can search the Web for "stgit"
for more information and proper tutorials.

For U-Boot we have these files in the ONIE repo, ``onie/patches/u-boot``::

  build-04:~/onie/patches$ ls -l u-boot
  total 104
  -rw-r--r-- 1 build build  1535 Feb 26 15:28 arch-powerpc-85xx-always-call-board_reset.patch
  -rw-r--r-- 1 build build   642 Feb 26 15:28 arch-powerpc-define-85xx-sdhc-polarity-select.patch
  -rw-r--r-- 1 build build  1975 Feb 26 15:28 arch-powerpc-fix-fsl-ddram-cfg.patch
  -rw-r--r-- 1 build build   579 Feb 26 15:28 arch-powerpc-fix-p2020-i2c-clock.patch
  -rw-r--r-- 1 build build  7666 Mar  4 08:51 driver-support-new-broadcom-phys.patch
  -rw-r--r-- 1 build build  1460 Feb 26 15:28 feature-config-repeatable.patch
  -rw-r--r-- 1 build build  3330 Feb 26 15:28 feature-dhcp-options.patch
  -rw-r--r-- 1 build build  1805 Mar  4 08:51 feature-fdt-environment-size.patch
  -rw-r--r-- 1 build build  1590 Feb 26 15:28 feature-populate-serial-number.patch
  -rw-r--r-- 1 build build  2760 Feb 26 15:28 feature-save-default-env-on-bad-crc.patch
  -rw-r--r-- 1 build build 36449 Mar  4 08:51 feature-sys-eeprom-tlv.patch
  -rw-r--r-- 1 build build   255 Feb 26 15:28 git-ignore.patch
  -rw-r--r-- 1 build build  5541 Feb 26 15:28 platform-common-env.patch
  -rw-r--r-- 1 build build  3740 Mar  4 08:51 platform-onie-common-env.patch
  -rw-r--r-- 1 build build   568 Mar  4 08:51 series

All of the files named \*.patch are, not surprisingly, the patches.
The ``series`` file controls the order in which the patches are
applied.  Its contents looks like::

  build-04:~/onie/patches/u-boot$ cat series
  # This series applies on GIT commit 206306740ef729713eb12b2f3c6ee79420fffb2d
  git-ignore.patch
  feature-config-repeatable.patch
  feature-dhcp-options.patch
  feature-save-default-env-on-bad-crc.patch
  feature-populate-serial-number.patch
  feature-sys-eeprom-tlv.patch
  feature-fdt-environment-size.patch
  arch-powerpc-define-85xx-sdhc-polarity-select.patch
  arch-powerpc-fix-p2020-i2c-clock.patch
  arch-powerpc-fix-fsl-ddram-cfg.patch
  arch-powerpc-85xx-always-call-board_reset.patch
  driver-support-new-broadcom-phys.patch
  platform-onie-common-env.patch
  platform-common-env.patch

These files are the "core ONIE" U-Boot patches.

Each specific machine also adds one (or more) patches to the end.  The
machine-specific patch adds machine-specific details like memory
controller configuration, NOR flash layout, etc.

The machine-specific patch for the Freescale P2020RDB-PCA evaluation
board is here::

  build-04:~/onie$ ls -l machine/fsl_p2020rdbpca/u-boot/
  total 4
  -rw-r--r-- 1 build build 3157 Feb 14 17:50 platform-fsl-p2020rdb-pca.patch
  -rw-r--r-- 1 build build   32 Feb 14 17:50 series

Patching U-Boot
^^^^^^^^^^^^^^^

Using ``stgit`` can be a little confusing at first.  Here is
the basic work flow when building ONIE:

When compiling U-Boot (see ``build-config/make/u-boot.make`` for details)
the ``u-boot-patch`` target does the following:

1. Untars the base upstream U-Boot source.

2. Applies the core ONIE U-Boot patch stack.

3. Applies the machine-specific U-Boot patch stack.

You can try this out yourself, like this::

  build-04:~/onie/build-config$ make MACHINE=fsl_p2020rdbpca u-boot-patch
  ==== Extracting upstream U-Boot ====
  ==== Patching u-boot ====
  Initialized empty Git repository in /mnt/behemoth1/home/curt/onie-cn/onie/build/fsl_p2020rdbpca-r0/u-boot/u-boot-2013.01.01/.git/
  Checking for changes in the working directory ... done
  Importing patch "git-ignore.patch" ... done
  Importing patch "feature-config-repeatable.patch" ... done
  Importing patch "feature-dhcp-options.patch" ... done
  Importing patch "feature-save-default-env-on-bad-crc.patch" ... done
  Importing patch "feature-populate-serial-number.patch" ... done
  Importing patch "feature-sys-eeprom-tlv.patch" ... done
  Importing patch "feature-fdt-environment-size.patch" ... done
  Importing patch "arch-powerpc-define-85xx-sdhc-polarity-select.patch" ... done
  Importing patch "arch-powerpc-fix-p2020-i2c-clock.patch" ... done
  Importing patch "arch-powerpc-fix-fsl-ddram-cfg.patch" ... done
  Importing patch "arch-powerpc-85xx-always-call-board_reset.patch" ... done
  Importing patch "driver-support-new-broadcom-phys.patch" ... done
  Importing patch "platform-onie-common-env.patch" ... done
  Importing patch "platform-common-env.patch" ... done
  Importing patch "platform-fsl-p2020rdb-pca.patch" ... done
  Now at patch "platform-fsl-p2020rdb-pca.patch"

After this step the patched U-Boot source is available in
``build/fsl_p2020rdbpca-r0/u-boot/u-boot-2013.01.01``.

Now, make your changes to the U-Boot files.

For this example let's say we only wanted to change the board
name that is printed when the machine boots. The fsl_p2020rdbpca
board currently prints this::

  Board: P2020RDB-PCA CPLD: V4.1 PCBA: V4.0

Let's change the board name to "ONIE-P2020RDB-PCA".

In the U-Boot source the board name is controlled by the
``CONFIG_BOARDNAME`` #define, located in
``build/fsl_p2020rdbpca-r0/u-boot/u-boot-2013.01.01/include/configs/p1_p2_rdb_pc.h``.

After making the change use the ``stg status`` command to see what is
happening. You should see something like::

  build-04:~/onie/build/fsl_p2020rdbpca-r0/u-boot/u-boot-2013.01.01$ stg status
  M include/configs/p1_p2_rdb_pc.h

Similar to the ``git status`` command, the ``stg status`` command shows
the modified files.  You can also use ``stg diff`` to see a diff::

  build-04:~/onie/build/fsl_p2020rdbpca-r0/u-boot/u-boot-2013.01.01$ stg diff
  diff --git a/include/configs/p1_p2_rdb_pc.h b/include/configs/p1_p2_rdb_pc.h
  index 55a4299..e1e0ede 100644
  --- a/include/configs/p1_p2_rdb_pc.h
  +++ b/include/configs/p1_p2_rdb_pc.h
  @@ -117,7 +117,7 @@
   #endif
  
   #if defined(CONFIG_P2020RDB)
  -#define CONFIG_BOARDNAME "P2020RDB-PCA"
  +#define CONFIG_BOARDNAME "ONIE-P2020RDB-PCA"
   #define CONFIG_NAND_FSL_ELBC
   #define CONFIG_P2020
   #define CONFIG_SPI_FLASH

To see the active patch stack, run ``stg series``. It should look like this::

  $ stg status
  + git-ignore.patch
  + feature-config-repeatable.patch
  + feature-dhcp-options.patch
  + feature-save-default-env-on-bad-crc.patch
  + feature-populate-serial-number.patch
  + feature-sys-eeprom-tlv.patch
  + feature-fdt-environment-size.patch
  + arch-powerpc-define-85xx-sdhc-polarity-select.patch
  + arch-powerpc-fix-p2020-i2c-clock.patch
  + arch-powerpc-fix-fsl-ddram-cfg.patch
  + arch-powerpc-85xx-always-call-board_reset.patch
  + driver-support-new-broadcom-phys.patch
  + platform-onie-common-env.patch
  + platform-common-env.patch
  > platform-fsl-p2020rdb-pca.patch

The patch prefaced with the ">" is the active patch.

In this case, we want to add the changes to the
``platform-fsl-p2020rdb-pca.patch`` patch, which is already the active
patch. To do so, run the ``stg refresh`` command, like this::

  build-04:~/onie/build/fsl_p2020rdbpca-r0/u-boot/u-boot-2013.01.01$ stg refresh
  Now at patch "platform-fsl-p2020rdb-pca.patch"

That will put the "modified" file into the
``platform-fsl-p2020rdb-pca.patch``, which is what we want.

.. note::

  If you were changing a patch deeper in the patch stack you would use::

    stg refresh -p <patch_name>

  to add the changes to a patch buried in the patch stack.

Now the ``stg status`` command will show no changes::

  build-04:~/onie/build/fsl_p2020rdbpca-r0/u-boot/u-boot-2013.01.01$ stg status

Next we want to "export" the ``platform-fsl-p2020rdb-pca.patch`` back out
to the ``onie/machine/fsl_p2020rdbpca/u-boot directory``, by way of a temp
directory, like this::

  build-04:~/onie/build/fsl_p2020rdbpca-r0/u-boot/u-boot-2013.01.01$ stg export -d /tmp
  Checking for changes in the working directory ... done
  build-04:~/onie/build/fsl_p2020rdbpca-r0/u-boot/u-boot-2013.01.01$ cp /tmp/platform-fsl-p2020rdb-pca.patch ../../../../machine/fsl_p2020rdbpca/u-boot

Wrapping Up
^^^^^^^^^^^

At this point the U-Boot patch is ready.  Now change directories to
the top level ``onie`` directory and check the output of ``git status`` and
``git diff``::

  build-04:~/onie$ git status
  # On branch master
  # Your branch is ahead of 'origin/master' by 1 commit.
  #
  # Changes not staged for commit:
  #   (use "git add <file>..." to update what will be committed)
  #   (use "git checkout -- <file>..." to discard changes in working directory)
  #
  #       modified:   machine/fsl_p2020rdbpca/u-boot/platform-fsl-p2020rdb-pca.patch
  #
  no changes added to commit (use "git add" and/or "git commit -a")

  build-04:~/onie$ git diff
  diff --git a/machine/fsl_p2020rdbpca/u-boot/platform-fsl-p2020rdb-pca.patch b/machine/fsl_p2020rdbpca/u-boot/platform-fsl-p2020rdb-pca.patc
  index 11e1e2d..c0a1dcf 100644
  --- a/machine/fsl_p2020rdbpca/u-boot/platform-fsl-p2020rdb-pca.patch
  +++ b/machine/fsl_p2020rdbpca/u-boot/platform-fsl-p2020rdb-pca.patch
  @@ -15,9 +15,18 @@ index e4b0d44..f389720 100644
    P2020RDB-PC_36BIT_NAND       powerpc     mpc85xx     p1_p2_rdb_pc        freescale      -           p1_p2_rdb_pc:P2020RDB,36BIT,NAND
    P2020RDB-PC_36BIT_SDCARD     powerpc     mpc85xx     p1_p2_rdb_pc        freescale      -           p1_p2_rdb_pc:P2020RDB,36BIT,SDCARD
   diff --git a/include/configs/p1_p2_rdb_pc.h b/include/configs/p1_p2_rdb_pc.h
  -index 964bfcd..55a4299 100644
  +index 964bfcd..e1e0ede 100644
   --- a/include/configs/p1_p2_rdb_pc.h
   +++ b/include/configs/p1_p2_rdb_pc.h
  +@@ -117,7 +117,7 @@
  + #endif
  +
  + #if defined(CONFIG_P2020RDB)
  +-#define CONFIG_BOARDNAME "P2020RDB-PCA"
  ++#define CONFIG_BOARDNAME "ONIE-P2020RDB-PCA"
  + #define CONFIG_NAND_FSL_ELBC
  + #define CONFIG_P2020
  + #define CONFIG_SPI_FLASH
   @@ -949,4 +949,69 @@ __stringify(__PCIE_RST_CMD)"\0"
  
    #define CONFIG_BOOTCOMMAND    CONFIG_HDBOOT

The modified
``machine/fsl_p2020rdbpca/u-boot/platform-fsl-p2020rdb-pca.patch`` is what
you would commit to your local git repo.

Commit these changes to your local git tree.  This is local, not going
to github, so don't worry.  Use the "git commit" command like this::

  $ git commit -a   <--- will prompt for a commit message

The commit message should contain at least the following:

- A succinct, one line description

- A description of the problem the patch is solving

- A description of how the patch solves the problem

- Reviewers and collaborators

- How the patch was tested

Now your ONIE patch is completely ready.  To make it suitable for
emailing to ONIE mailing list use the ``git format-patch`` command, like
this::

  $ git format-patch --signoff -1
  0001-fsl_p2020rdbpca-Change-board-name-to-ONIE-P2020RDB-PCA.patch

That creates the patch file
0001-fsl_p2020rdbpca-Change-board-name-to-ONIE-P2020RDB-PCA.patch

Now send that patch file to the ONIE mailing list for review.
