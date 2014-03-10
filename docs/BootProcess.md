Summary
---------

The high-level boot process for ONL is fairly straight forward, but there is a lot detail.

At high-level, there are three phases
1. uBoot phase
2. the ONL Loader phase
3. The final ONL operating system


Detailed Boot Process
--------------------------

1. uBoot is the first level boot loader: http://www.denx.de/wiki/U-Boot
2. uBoot reads the 'nos_bootcmd' environmental variable from flash and runs the contents
    ('nos' is Network Operating System)
4. If $nos_boot_cmd returns, uBoot loads and runs ONIE (see below) to download the ONL installer and install the ONL loader
    a) The factory default $nos_boot_cmd is to a trival command that returned immediately, e.g., 'echo'
5. In normal operation, i.e., after ONIE has been run, $nos_boot_cmd is set to load and run the ONL Loader
6. The ONL loader boots its own Linux kernel (later, the "boot kernel") 
7. The ONL loader decides which SWI to run based on the URL in the file /etc/SWI
    URL=`cat /etc/SWI`
8. The ONL loader runs `/bin/boot $URL`
9. The ONL loader retrieves the SWI file
    a) if the URL is remote (e.g., http://, ftp://, etc.), verify that there is a locally cached copy
        of the SWI in /mnt/flash2 or if not, download it
    b) if the URL is local, verify that the device is accessible
    c) if the URL is a Zero Touch Networking (ZTN) URL, the execute the ZTN protocol to get the SWI (see below)
10. The ONL loader reads the 'rootfs' file out of the SWI and mounts it using overlayfs[1] (SWI contents described below)
11. The ONL loader called kexec() to switch to the kernel in the SWI and boots the main ONL kernel
12. The final ONL kernel is passed the ONIE platform identifier as a
        kernel parameter so that platform specific bindings can be loaded





Partition Layout
------------------

Switches typically have two flash storage device: a smaller flash (e.g.,
64MB flash) for booting and a larger, mass storage device (e.g., compact
flash, 2+GB).


Smaller Boot Flash:

Partition 1: uBoot
Partition 2: environmental variables (e.g., $nos_boot_cmd)
Partition 3: ONIE
Partition 4+: Free space (unused)

Mass Storage Device:

Partition 1: ONL loader kernel  -- the format of this partition varies depending on what formats uBoot supports on the specific platform
Partition 2: ONL Loader configuration files (mounts as "/mnt/flash" both during the loader and the main ONL phases)
Partition 3: ONL SWitch Images (SWIs) partition (mounts as "/mnt/flash2" both during the loader and the main ONL phases)

ONL file system layout
-----------------------
root@onl-powerpc:/bin# df
Filesystem     1K-blocks  Used Available Use% Mounted on
rootfs             72040   176     71864   1% /
devtmpfs            1024     0      1024   0% /dev
none               72040   176     71864   1% /
tmpfs              48028   148     47880   1% /run
tmpfs               5120     0      5120   0% /run/lock
/dev/sda2          71177     7     71170   1% /mnt/flash
/dev/sda3        3791960 98172   3693788   3% /mnt/flash2
tmpfs              96040     0     96040   0% /run/shm


SWI
--------

Zip file contains

robs@ubuntu:~/work.onl/ONL/builds/swi/powerpc/all$ unzip -l onl-c7850a5-powerpc-all-2014.02.12.11.49.swi
Archive:  onl-c7850a5-powerpc-all-2014.02.12.11.49.swi
Length      Date       Time    Name
---------   ---------- -----   ----
6877424     2014-02-12 11:55   kernel-85xx
3378828     2014-02-12 11:55   initrd-powerpc
93753344    2014-02-12 11:55   rootfs-powerpc.sqsh
100         2014-02-12 11:55   version
---------                     -------
104009696                     4 files

1. 'kernel-85xx'    : the actual kernel image for the running ONL
2. 'initrd-$ARCH'   : the initial ram disk for the kernel
3. 'rootfs-$ARCH'   : the root file system for the running ONL
4. 'version'        : A build version string of the form "Open Network Linux $shorthash ($target,$date,$githash)"




Footnotes
-----------

[1] : https://kernel.googlesource.com/pub/scm/linux/kernel/git/mszeredi/vfs/+/overlayfs.current/Documentation/filesystems/overlayfs.txt
