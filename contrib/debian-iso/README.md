# Installing Debian on a ONIE System

This example demonstrates how to create an ONIE compatible installer
image from a Debian Jessie .ISO file.  This README covers:

* Building the Debian ONIE installer
* Running the Debian installer on a ONIE x86_64 virtual machine
* Using a Debian preseed.txt file to automate installation in an ONIE environment

## Building the Debian ONIE installer

Before building the installer make sure you have `wget` and `xorriso`
installed on your system.  On a Debian based system the following is
sufficient:

```
build-host:~$ sudo apt-get update
build-host:~$ sudo apt-get install wget xorriso
```

To build the Debian ONIE installer change directories to `debian-iso`
and type the following:

```
build-host:~$ cd onie/contrib/debian-iso
build-host:~/onie/contrib/debian-iso$ ./cook-bits.sh
Downloading Debian Jessie mini.iso ...
Using URL: http://ftp.debian.org/debian/dists/jessie/main/installer-amd64/current/images/netboot/mini.iso
--2015-10-09 10:15:03--  http://ftp.debian.org/debian/dists/jessie/main/installer-amd64/current/images/netboot/mini.iso
Resolving ftp.debian.org (ftp.debian.org)... 130.89.148.12, 2001:610:1908:b000::148:12
Connecting to ftp.debian.org (ftp.debian.org)|130.89.148.12|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 29360128 (28M) [application/x-iso9660-image]
Saving to: `./input/debian-jessie-amd64-mini.iso'

100%[==================================================================================================>] 29,360,128  3.11M/s   in 8.6s    

2015-10-09 10:15:12 (3.25 MB/s) - `./input/debian-jessie-amd64-mini.iso' saved [29360128/29360128]

Creating ./output/debian-jessie-amd64-mini-ONIE.bin: .xorriso 1.2.2 : RockRidge filesystem manipulator, libburnia project.

xorriso : NOTE : Loading ISO image tree from LBA 0
xorriso : UPDATE : 280 nodes read in 1 seconds
xorriso : NOTE : Detected El-Torito boot information which currently is set to be discarded
Drive current: -indev './input/debian-jessie-amd64-mini.iso'
Media current: stdio file, overwriteable
Media status : is written , is appendable
Boot record  : El Torito , ISOLINUX boot image capable of isohybrid
Media summary: 1 session, 11098 data blocks, 21.7m data, 1210g free
Volume id    : 'ISOIMAGE'
Copying of file objects from ISO image to disk filesystem is: Enabled
xorriso : UPDATE : 280 files restored ( 21495k) in 1 seconds = 15.9xD
Extracted from ISO image: file '/'='/work/monster-15/curt/trees/onie-cbrune/contrib/debian-iso/work/extract'
..... Done.
```

The resulting ONIE installer file is available in the `output` directory:

```
build-host:~/onie/contrib/debian-iso$ ls -l output/
total 17812
-rw-r--r-- 1 curt Development 18238940 Oct  9 10:15 debian-jessie-amd64-mini-ONIE.bin
```

## Running the Debian installer on a ONIE x86_64 virtual machine

The next step is to create the `kvm_x86_64` ONIE image and a virtual
machine in which to run it.  This is covered here:

https://github.com/opencomputeproject/onie/blob/master/machine/kvm_x86_64/INSTALL

Follow the instructions in the "Creating a New x86_64 Virtual Machine
Using the ISO Image" section.  The only change to make is to create a
large virtual disk image.  Create an 8G qcow2 image, like this:

```
build-host:~$ qemu-img create -f qcow2 onie-x86-demo.img 8G
```

This example VM uses local qemu networking.  From the guest VM you
will be able to access services on the host using IP address 10.0.2.2.

Once you have the ONIE VM running, boot the system into ONIE rescue
mode.  You should now be at the ONIE prompt:

```
ONIE:/ # 
```

## Preparing the HTTP image server

The example assumes you are running an HTTP server on the same machine
as the virtual machine.  Using local qemu networking the HTTP server
will be availabe within the VM using IP address 10.0.2.2.

Put the `debian-jessie-amd64-mini-ONIE.bin` file and
`debian-preseed.txt` file into the document root of the HTTP server:

```
build-host:~/onie/contrib/debian-iso$ sudo mkdir -p /var/www/html/debian-iso
build-host:~/onie/contrib/debian-iso$ sudo cp output/debian-jessie-amd64-mini-ONIE.bin debian-preseed.txt /var/www/html/debian-iso
```

## Installing the Debian installer from ONIE

Back on the ONIE VM.  First double check that the network is working
correctly:

```
ONIE:/ # ping 10.0.2.2
PING 10.0.2.2 (10.0.2.2): 56 data bytes
64 bytes from 10.0.2.2: seq=0 ttl=255 time=0.237 ms
64 bytes from 10.0.2.2: seq=1 ttl=255 time=0.179 ms
^C
--- 10.0.2.2 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
```

Next verify the HTTP server is accessible:

```
ONIE:/ # wget http://10.0.2.2/debian-iso/debian-preseed.txt
```

If either of those is not working figure out why before proceeding.

Now proceed with installing the ONIE compatible Debian installer:

```
ONIE:/ # onie-nos-install http://10.0.2.2/debian-iso/debian-jessie-amd64-mini-ONIE.bin
discover: Rescue mode detected. No discover stopped.
Info: Fetching http://10.0.2.2/debian-iso/debian-jessie-amd64-mini-ONIE.bin ...
Connecting to 10.0.2.2 (10.0.2.2:80)
installer            100% |*******************************| 17811k  0:00:00 ETA
ONIE: Executing installer: http://10.0.2.2/debian-iso/debian-jessie-amd64-mini-ONIE.bin
Verifying image checksum ... OK.
Preparing image archive ... OK.
Loading new kernel ...
kexec: Starting new kernel
...
```

The Debian installer kernel will now kexec and you are off to the
races.  The Debian installer will pull down the preseed.txt file and
continue the install process.

## Poking around Debian after the install

When complete the Debian system will have the following:

- a sudo-enabled user called `onie` with the login password of `onie`
- GRUB menu entries for ONIE, from /etc/grub.d/50_onie_grub

The GRUB menu looks like:

```
                        GNU GRUB  version 2.02~beta2-22
                                                       
 +----------------------------------------------------------------------------+
 | Debian GNU/Linux                                                           | 
 |*Advanced options for Debian GNU/Linux                                      |
 | ONIE                                                                       |
 |                                                                            |
```
