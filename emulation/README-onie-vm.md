# Running ONIE in emulation.

ONIE supports several virtual machine targets to allow
test and development without using actual hardware.

These systems should be considered 'reference designs' for
any hardware specific implementation of ONIE. New features
and software versions will be guaranteed to work on the
virtual systems before being made publicly available.

For anyone new to emulation, the number of arguments and
options to run emulation using QEMU can be overwhelming,
so this script is provided as a starting point.

# Getting Started.


#Build the KVM virtual machine

    cd onie/build-config
    make MACHINE=kvm_x86_64 all demo recovery-iso
...and do something else while it builds.

Once the compilation has completed, `onie/build/images` will have:  


|File                                        |Purpose                                   |
|--------------------------------------------|------------------------------------------|
|demo-diag-installer-x86_64-kvm_x86_64-r0.bin|diagnostic OS sample for KVM              |
|demo-installer-x86_64-kvm_x86_64-r0.bin     |demonstration OS for KVM                  |
|kvm_x86_64-r0.initrd                        |initial ramdisk                           |
|kvm_x86_64-r0.vmlinuz                       |kernel signed for Secure Boot (by default)|
|kvm_x86_64-r0.vmlinuz.unsigned              |kernel without signature                  |
|onie-recovery-x86_64-kvm_x86_64-r0.iso      |Recovery boot CD (used for ONIE install)  |
|onie-updater-x86_64-kvm_x86_64-r0           |Binary to update ONIE                     |
|                                            |                                          |



Now the emulation tools have something to work with.


# Commands
The `onie-vm.sh` script has the following commands:  

## Running:
    run                     - Run from boot device selected with runtime options.  
    rk-onie                 - Run just the initrd/kernel from the ONIE ../build directory.  
    rk-installer            - Run a kernel/initrd extracted from an ONIE installer (see below)  
    rk-deb-kernel-debug     - Use deb extracted kernel and installer initrd with rk-installer. (see below)  

### Informational commands:
    info-runables           - Print kernels and filesystems available for use.
    info-run-options        - Print what could be run, given what was found.

### Utility commands:
    update-m-usb <dir>      - Create a 'USB drive' qcow2 filesystem for QEMU use.
                              if <dir> is not passed, will default to
                              adding files from [  onie/emulation/emulation-files/usb/usb-data ]
    clean                   - Delete generated directories.

### Unpacking other kernels/initrds:
    extract-linux-deb <v><b>- Extract passed vmlinux,bzImage debs to ../unpack-linux-deb
    extract-installer <nos> - Extract kernel/initrd from NOS image installer.

# Options

##Target selection options:
    --machine-name  <name> - Name of build target machine - ex mlnx_x86
    --machine-revision <r> - The -rX version at the end of the --machine-name

##Runtime options:
    --m-onie-iso <path>    - Boot off of recovery ISO at <path> and install onto qcow2
    --m-embed-onie         - Boot to embed onie. Requires --m-onie-iso <path>
    --m-boot-cd            - Boot off of rescue CD to start.
    --m-secure             - Set --m-usb-drive and --m-bios-uefi for secure boot.

##BIOS configuration:     Default: Legacy BIOS.
    --m-bios-uefi          - Use UEFI rather than legacy bios.
    --m-bios-vars-file <f> - Use a copy of a previously saved OVMF_VARS file at: <file>
    --m-bios-clean         - Delete OVMF_VARS.fd and replace with empty copy to erase all set UEFI vars.

##Emulation instance configuration:
    --m-telnet-port<num>   - Set telnet port number.          Default: [ 9300 ]
    --m-vnc-port   <num>   - Set vnc port number.             Default: [ 128 ]
    --m-ssh-port   <num>   - Set local ssh port forward.      Default: [ 4022 ]
    --m-monitor-port <#>   - Telnet port for QEMU monitor.    Default: [  ]
    --m-network-mac <xx>   - Two hex digits for a unique MAC. Default: [ 1E ]
    --m-gdb                - Enable gdb through QEMU.

##Storage:
    --m-hd-clean           - Replace target 'hard drive' with an empty one  and run install.
    --m-hd-file <file>     - Use a previously configured drive file.
    --m-nvme-drive         - Have QEMU emulate storage as NVME drives.
    --m-usb-drive          - Make virtual USB drive available at KVM runtime.  

##Help
    --help                  - This output.
    --help-examples         - Examples of use.

#Files
A fully populated emulation directory may look like this.
Note that some files only appear after certain run time arguments,
like `--m-usb-drive` or `--m-bios-uefi` have been used.

     onie-vm.lib    <- library functions used by the emulation script  
     onie-vm.sh     <- Run emulation script  

##./emulation-files:  
    onie-kvm_x86_64-clean.qcow2   <- Pre-formatted target file system  
    onie-kvm_x86_64-demo.qcow2	  <- Target file system used by QEMU  
##./emulation-files/uefi-bios:  
    OVMF_CODE.fd    <- UEFI BIOS Firmware  
    OVMF_VARS.fd    <- UEFI BIOS variable storage.  
##./emulation-files/usb:  
     usb-drive.qcow2   <- Virtual USB drive fileysystem  
     usb-drive.raw	   <- Intermediate stage of virtual drive  

##./emulation-files/usb/usb-data:  
Holds files to put into varietal USB drive  

    README.txt         <- Notes on the virtual USB file system  
    ReadmeUEFI.txt     <- Notes on the UEFI shell environment  

##./emulation-files/usb/usb-mount:  
Loopback mount point for creating virtual file system  

This exists if emulation runs have been performed with the virtual usb drive, and
UEFI BIOS as an emulation option
  
  
#Examples
##Ways to run just a kernel

### Kernel and intird from the ONIE build
    Cmd: onie-vm.sh rk-onie

### Kernel and initrd from an ONIE installer
    Cmd: onie-vm.sh rk-installer

### Debug kernel from a Debian linux-image deb, with the ONIE initrd
    Cmd: onie-vm.sh rk-installer-debug

## Extracting that kernel, initrd, etc...

### Unpack an ONIE installer and store the initrd/kernel where it can be used to run
    Cmd: onie-vm.sh unpack-installer

### Unpack the two Debian Linux linux-image*-debug-*.debs and put them in a known location
    Cmd: onie-vm.sh extract-linux-deb


##Runtime info
### List things that could be run
    Cmd: onie-vm.sh info-runables
### List things that can currently be run
    Cmd: onie-vm.sh info-run-options

##Running a qcow2 image

###Boot off a recovery iso, install onie in an empty qcow2 with legacy BIOS
    Cmd: onie-vm.sh run --m-embed-onie --m-hd-clean

###Run a qcow2 that has onie embedded (see above)
    Cmd: onie-vm.sh run

###Run and install ONIE on an empty qcow2 hard drive file using UEFI BIOS
    Cmd: onie-vm.sh run --m-onie-iso <path to recovery iso> --m-usb-drive --m-bios-uefi --m-secure --m-hd-clean --m-bios-clean

###Run qcow2 hard drive file that has ONIE installed using UEFI BIOS
    Cmd: onie-vm.sh run  --m-bios-uefi

###Run Secure Boot and install ONIE on an empty qcow2 and keep UEFI vars
    Cmd: onie-vm.sh run --m-secure --m-hd-clean --m-embed-onie

###Run Secure Boot using previously embedded image (see above)
    Cmd: onie-vm.sh run --m-secure

###Run new secure boot while another QEMU is running:
    Cmd: onie-vm.sh --m-network-mac 21 --m-telnet-port 9400 --m-vnc-port 127 --m-ssh-port 4122 --m-embed-onie --m-secure  --m-hd-clean  --m-bios-clean


#Quick setup:
 To embed ONIE on a virtual hard drive file, type:  
    `./onie-vm.sh run --m-usb-drive --m-bios-uefi --m-secure --m-hd-clean --m-bios-clean --m-onie-iso ../build/images/onie-recovery-x86_64-kvm_x86_64-r0.iso`  

 In a separate window, type:  
    `telnet localhost 9300`

 To run after embedding ONIE, type:  
    `./onie-vm.sh run --m-usb-drive --m-bios-uefi --m-secure`




#More Examples:

## Embed KVM ONIE on an empty virtual file system. This should be the first step.
`onie-vm.sh run --m-embed-onie --m-boot-cd ../build/images/onie-recovery-x86_64-kvm_x86_64-r0.iso`
Where
 `--m-embed-onie`  - install ONIE on empty file system
 `--m-boot-cd`     - boot off the recovery iso to start

##Run ONIE after embedding

`onie-vm.sh run`

##Run ONIE with a UEFI BIOS
`onie-vm.sh run --m-bios-uefi`
NOTE: for the UEFI bios boot entries to be aware of ONIE, you should install ONIE first, as:
`onie-vm.sh run --m-bios-uefi --m-embed-onie --m-boot-cd ../build/images/onie-recovery-x86_64-kvm_x86_64-r0.iso`

##Run ONIE with the virtual USB drive
`onie-vm.sh run --m-usb-drive`
NOTE: once the system has booted, mount the drive with:
  mount /dev/vdb /mnt/usb


##Run just the locally built ONIE kernel and intird with gdb:
`./onie-vm.sh rk-onie`
...and follow the instructions for attaching with GDB


##Debug an installer kernel
 This uses the demo OS installer, but any ONIE compatible NOS installer should work

 ./onie-vm.sh --unpack-installer  ../build/images/demo-installer-x86_64-kvm_x86_64-r0.bin

 ./onie-vm.sh rk-installer


##Debug a NOS packaged kernel

Here Debian packages are used as an example, but whatever packaging architecture
the NOS uses can be added to the script.

*Note:* you will need an initrd if the NOS doesn't provide one. One can be taken from the ONIE installer,
as follows:  
   ./onie-vm.sh --unpack-installer  ../build/images/demo-installer-x86_64-kvm_x86_64-r0.bin

Download the packaged kernel. This example uses Debian's .deb packaging  
  apt-get download \
    linux-image-4.19.0.16-amd64-dbg \
	linux-image-4.19.0.16-amd64

Extract package contents ( using a dpkg -x - other packaging systems will be different )  
  ./onie-vm.sh --unpack-linux-deb \
     linux-image-4.19.0-16-amd64_4.19.181-1_amd64.deb \
	 linux-image-4.19.0-16-amd64-dbg_4.19.181-1_amd64.deb

Now run:
 ./onie-vm.sh rk-deb-kernel-debug

#Notes on using UEFI
The OVMF_VARS.fd file can be preserved after configuration for subsequent runs.
However, unless the filesystems it is used with have the same UUID, the system
will fail to boot.

If you are testing somehing like Secure Boot, where a set of keys would be
configured, one possible workflow is to:  
    1. Boot into the UEFI shell or BIOS menus  
    2. Add keys and configuration  
    3. Delete boot entries for ONIE and the NOS  
    4. Halt the emulation  
    5. Copy the modified OVMF_VARS.fd file to a 'safe place'
    6. ...then, on subsequent runs, copy it in for an ONIE embed and NOS
install so that the generated filesystem UUIDs in the bios will match
the partitions on the QCOW2 drive.  






