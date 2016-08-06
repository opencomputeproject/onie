Getting Started
------------------------------------------------
To install and run ONL you need is an ONL Compatible switch (see
http://opennetlinux.org/hcl) and the ONL installer binary.  Every
ONL compatible switch ships with the ONIE installer environment installed
which gives you a multitude of ways of getting ONL installed on your switch.

We document the easiest ways here (manual install via console and NFS)
but the http://onie.org website contains a variety of installation
methods including via USB, over the network, and even via ssh.

The resulting installation has a default account ("root") with a default
password ("onl").  The network interface is disabled by default so that
you can change the root password before the system comes up.


ONL Manual Install
------------------------------------------------
1) Attach a serial terminal to the switch
2) Boot switch and hit return to go to ONIE''s interactive mode
    2a) You must wait until after uboot has finished loading; if you
        accidentally interupt uboot first, just run `boot` to continue
        booting into ONIE
3) Download the ONL installer from http://opennetlinux.org and run it by hand

Expected Serial Console Output (from an QuantaMesh LB9, other switches ouput will vary):

        U-Boot 2010.12 (Oct 08 2013 - 17:11:37)

        CPU:   8541, Version: 1.1, (0x80720011)
        Core:  Unknown, Version: 2.0, (0x80200020)
        Clock Configuration:
               CPU0:825  MHz, 
               CCB:330  MHz,
               DDR:165  MHz (330 MT/s data rate), LBC:41.250 MHz
        CPM:   330 MHz
        L1:    D-cache 32 kB enabled
               I-cache 32 kB enabled
        I2C:   ready
        DRAM:  Detected UDIMM TS128MSD64V3A
        Detected UDIMM(s)
        DDR: 1 GiB (DDR1, 64-bit, CL=2.5, ECC off)
        FLASH: 64 MiB
        L2:    256 KB enabled

        LB9 U-Boot
          Product Name          : LB9
          Model Name            : QUANTA LB9
          Serial Number         : QTFCA63280001
          Part Number           : 1LB9BZZ0STQ
          Label Revision Number : 1
          Hardware Version      : 1.0
          Platform Version      : 0xb901 
          Release Date          : 2013/7/5
          MAC Address           : 08:9e:01:ce:bd:2d
        Set ethaddr MAC address = 08:9e:01:ce:bd:2d
        In:    serial
        Out:   serial
        Err:   serial
        Net:   TSEC0: PHY is Broadcom BCM5461S (2060c1)
        TSEC0
        IDE:   Bus 0: OK 
          Device 0: Model: 4GB CompactFlash Card Firm: Ver6.04J Ser#: CDE207331D0100001484
                    Type: Hard Disk
                    Capacity: 3811.9 MB = 3.7 GB (7806960 x 512)
        Hit any key to stop autoboot:  0 
        ## Error: "nos_bootcmd" not defined
        Loading Open Network Install Environment ...
        Platform: powerpc-quanta_lb9-r0
        Version : 1.5.2-20131008154633
        WARNING: adjusting available memory to 30000000
        ## Booting kernel from Legacy Image at 04000000 ...
           Image Name:   quanta_lb9-r0
           Image Type:   PowerPC Linux Multi-File Image (gzip compressed)
           Data Size:    3479390 Bytes = 3.3 MiB
           Load Address: 00000000
           Entry Point:  00000000
           Contents:
              Image 0: 2762740 Bytes = 2.6 MiB
              Image 1: 707380 Bytes = 690.8 KiB
              Image 2: 9254 Bytes = 9 KiB
           Verifying Checksum ... OK
        ## Loading init Ramdisk from multi component Legacy Image at 04000000 ...
        ## Flattened Device Tree from multi component Image at 04000000
           Booting using the fdt at 0x434f378
           Uncompressing Multi-File Image ... OK
           Loading Ramdisk to 2ff53000, end 2ffffb34 ... OK
           Loading Device Tree to 03ffa000, end 03fff425 ... OK
        Cannot reserve gpages without hugetlb enabled
        setup_arch: bootmem
        quanta_lb9_setup_arch()
        arch: exit
                     
        ONIE: Using DHCPv4 addr: eth0: 10.7.1.10 / 255.254.0.0
        discover: installer mode detected.  Running installer.

        Please press Enter to activate this console. ONIE: Using DHCPv4 addr: eth0: 10.7.1.10 / 255.254.0.0
        ONIE: Starting ONIE Service Discovery

        To check the install status inspect /var/log/onie.log.
        Try this:  tail -f /var/log/onie.log

Now press RETURN here to jump into ONIE''s manual installer mode.  You should see:

        ** Installer Mode Enabled **

        ONIE:/ # 

Then simply download the latest ONL installer for the appropriate
architecture (powerpc or amd64) from the website and run it.

        ONIE:/ # install_url http://opennetlinux.org/binaries/latest-$ARCH.installer

        Connecting to opennetlinux.org (107.170.237.53:80)
        Open Network Installer running under ONIE.
        Installer Version: Open Network Linux e148b7a (powerpc.all,2014.05.21.18.57,e148b7a90131c07eb8d49f74316baf8f2aae92c6)
        Detected platform: powerpc-quanta-lb9-r0
        Installing in standalone mode.
        Unpacking Open Network Linux installer files...
        onl.powerpc-as4600-54t.loader
        onl.powerpc-as5600-52x.loader
        ...


Note: 

1) If there is different OS(other than ONL) running on the switch. 
Then halt the booting process at U-boot mode, Then check for the ONIE  
details in the environment(=> printenv). Open the ONIE in rescue mode, 
while ONIE has many different installation modes, 
we recommend the rescue mode for doing a manual (read: via console) 
because it disables the automatic ONIE server discovery. 
Then run (=> run onie_rescue) command to take you to the ONIE environment.

2) For development purpose, to load freshly build ONL installer from directly ONIE.
Run a http server from the build machine (example:python -m SimpleHTTPServer 8000) and access it as,

     
    example: ONIE:/ # install_url http://buildmachineIPAddress:/path/to/directory/onl-09b7bba-powerpc-all.2016.02.05.05.17.installer # update for specific file/date/build

Also, you can use install via scp with two steps,

       example: ONIE:/ # scp [username]@buildmachineIPAddress:/path/to/directory/onl-09b7bba-powerpc-all.2016.02.05.05.17.installer  ONL.installer # update for specific file/date/build
                ONIE:/ # sh ONL.installer

ONL NFS Root Directory
------------------------------------------------

Given that the default installation of ONL does not persist files across
reboots (this is intentional -- flash disks should not be written to
as often as spinning disks), it is sometimes useful to have a normally
writable, larger disk available for the switch.  Enter the NFS root
directory which enables a switch to boot ONL from a remote NFS partition.
While it is possible to simply fetch the SWI file from an NFS server
(keeping the same non-persisted behavior), the much more useful feature
is to have the root file system NFS hosted.

To enable NFS mounted root partition:

1) Run the ONL installer normally (e.g., via the manual mode per above) so that the ONL
    loader is installed.

2) Edit /mnt/flash/boot-config, enable DHCP, and change the SWI variable to point to a URL of the form "nfs://$ip[:port]/path/to/directory/".  For example, on my machine, this looks like:

     # cat /mnt/flash/boot-config
     SWI=nfs://10.6.0.4/home/robs/export/ly2-1/  # trailing '/' is critical
     NETAUTO=dhcp                                # optional, but likely what you want
     NETDEV=ma1                                  # leave untouched

3) On server $ip, in /path/to/directory, unzip a target .SWI file, e.g.,

     # wget http://opennetlinux.org/binaries/latest.swi
     # unzip latest.swi

4) unsquash the compressed root file system as directory 'rootfs-$arch':

     # unsquashfs -d rootfs-$arch rootfs-$arch.sqsh  # e.g., $arch = 'powerpc'h

Now reboot your switch and it should boot automatically into the NFS root file system.
Note that the SWI structure is still maintained:

     robs@sbs3:~/export/ly2-1$ ls -l
     total 109048
     -rw-r--r--  1 robs __USERS__   3382017 Nov  4 22:28 initrd-powerpc
     -rwxr-xr-x  1 robs __USERS__   6942960 Nov  4 22:28 kernel-85xx*
     -rw-r--r--  1 robs __USERS__ 101322752 Nov  4 22:28 rootfs-powerpc.sqsh
     drwxrwxr-x 22 robs __USERS__      4096 Jan  2 18:21 rootfs-powerpc/
     -rw-r--r--  1 robs __USERS__       100 Nov  4 22:29 version

That is:
* 'kernel-85xx' is the kernel image
* 'initrd-powerpc' is the initial RAM disk image
* 'rootfs-powerpc' is the base of the root filesystem
* 'version' is a string that identifies this SWI

Note: If NFS root squash is set on the server, you might get a permission error while booting. To fix this, you can set 'no_disable_squash' in /etc/exports. However, be aware of the security implications as root on a client machine will now have the same access privilege on the files as root on the NFS server.
