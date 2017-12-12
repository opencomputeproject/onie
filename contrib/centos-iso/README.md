# Installing CentOS on a ONIE System

This example demonstrates how to create an ONIE compatible installer
image from the CentOS public repositories.  This README covers:

* Building the CentOS ONIE installer
* Running the CentOS installer on an ONIE x86_64 virtual machine
* Using yumbootstrap to prepare and customize CentOS Linux and including it
* in an ONIE installer

## Building the CentOS ONIE installer

Before building the installer make sure you have `git`, `yum`, `rpmbuild` and `yumbootstrap`
installed on your system.

On a Debian based system the following is sufficient:

```
# Install yum and git tools
build-host:~$ sudo apt-get install git yum

# Download and Install yumbootstrap
build-host:~$ git clone https://github.com/dozzie/yumbootstrap
build-host:~$ cd yumbootstrap
build-host:~/yumbootstrap$ dpkg-buildpackage -b -uc
build-host:~/yumbootstrap$ sudo dpkg -i ../yumbootstrap_0.0.3-2_all.deb
```

`dpkg-buildpackage` may fail with a missing build dependency on
`python-support`.  This package is no longer included with some
distributions, notably Ubuntu-16.04.  You can install python-support_1.0.15
following these instructions:

https://askubuntu.com/questions/766169/why-no-more-python-support-in-16-04

On a Redhat based system the following is sufficient:

```
# Install git and rpmbuild tools
build-host:~$ sudo yum install git
build-host:~$ sudo yum install rpm-build

# Download and Install yumbootstrap
build-host:~$ git clone https://github.com/dozzie/yumbootstrap
build-host:~/yumbootstrap$ cd yumbootstrap
build-host:~/yumbootstrap$ make srpm
build-host:~/yumbootstrap$ rpmbuild --rebuild yumbootstrap-*.src.rpm
build-host:~/yumbootstrap$ sudo rpm -ivh ~/rpmbuild/RPMS/noarch/yumbootstrap-0.0.3-1.el7.centos.noarch.rpm
```

To build the CentOS ONIE installer change directories to `contrib/centos-iso`
and type the following:

```
build-host:~$ cd onie/contrib/centos-iso
build-host:~/onie/contrib/centos-iso$ sudo ./cook-bits.sh
[18:42:17] installing CentOS (release 7) to ./work/centos-7-chroot
[18:42:17] preparing empty /etc/fstab and /etc/mtab
[18:42:17] using built-in repositories
[18:42:17] adding GPG keys
[18:42:17] installing default packages for CentOS 7
[18:42:17] /home/user/onie/contrib/centos-iso/work/centos-7-chroot/yumbootstrap/yum.conf doesn't exist, creating one
[18:42:17] GPG keys defined, adding them to repository configs
...
...
...
Complete!
[17:47:59] executing post-install scripts
[17:47:59] running finalize
[17:47:59] fixing RPM database for guest
[17:47:59] converting "Packages" file
[17:50:31] removing all the files except "Packages"
[17:50:31] running `rpm --rebuilddb'
[17:50:33] removing old RPM DB directory: $TARGET/home/user/.rpmdb
[17:50:33] running finalize
[17:50:33] removing yumbootstrap directory from target
[17:50:33] operation finished
/home/user/onie/contrib/centos-iso
Creating ./output/centos-7-ONIE.bin: ..... Done.
build-host:~/onie/contrib/centos-iso$
```
The resulting ONIE installer file is available in the `output` directory:

```
build-host:~/onie/contrib/centos-iso$ ls -l output/
total 365316
-rwxr-xr-x 1 root root 374078940 Sep 11 19:02 centos-7-ONIE.bin
build-host:~/onie/contrib/centos-iso$
```

CentOS distribution can be customized to have additional packages by modifying `PKG_LIST` in `cook-bits.sh`.
Arbitrary customizations can be done as marked in the section marked `# Customizations` in `cook-bits.sh`.

## Running the CentOS installer on a ONIE x86_64 virtual machine

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
will be available within the VM using IP address 10.0.2.2.

Put the `centos-7-ONIE.bin` file into the document root of the HTTP server:

```
build-host:~/onie/contrib/centos-iso$ sudo mkdir -p /var/www/html/centos-iso
build-host:~/onie/contrib/centos-iso$ sudo cp output/centos-7-ONIE.bin  /var/www/html/centos-iso
```

## Installing the CentOS installer from ONIE

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
ONIE:/ # wget http://10.0.2.2/centos-iso/centos-7-ONIE.bin
```

If either of those is not working figure out why before proceeding.

Now proceed with installing the ONIE compatible CentOS installer:

```
ONIE:/ # onie-nos-install http://10.0.2.2/centos-iso/centos-7-ONIE.bin
discover: Rescue mode detected. No discover stopped.
Info: Fetching http://10.0.2.2/centos-iso/centos-7-ONIE.bin ...
Connecting to 10.0.2.2 (10.0.2.2:80)
installer            100% |*******************************|   356M  0:00:00 ETA
ONIE: Executing installer: http://10.27.7.87/centos-7-ONIE.bin
Verifying image checksum ... OK.
Preparing image archive ... OK.
Create partition .
Warning: The kernel is still using the old partition table.
The new table will be used at the next reboot.
The operation has completed successfully.
mke2fs 1.42.13 (17-May-2015)
Creating filesystem with 2063611 4k blocks and 516096 inodes
...
```

The CentOS image will now be extracted and written to the VM disk.


## Checkout CentOS Linux after the install

After a successful installation the CentOS Linux system will have the following:

- a sudo-enabled user called `onie` with the login password of `onie`
- GRUB menu entries for ONIE, from /etc/grub.d/40_onie_grub

The GRUB menu looks like:

```
                        GNU GRUB  version 2.02~beta3

 +----------------------------------------------------------------------------+
 |*centos-7                                                                   |
 | ONIE                                                                       |
 |                                                                            |
```

