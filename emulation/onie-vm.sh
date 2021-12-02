#!/bin/bash
#-------------------------------------------------------------------------------
#
#  Copyright (C) 2021 Alex Doyle <adoyle@nvidia.com>
#
#-------------------------------------------------------------------------------

# SCRIPT_PURPOSE: Automate and provide examples for running ONIE in emulation.

# OVERVIEW
# This script will work with an ONIE recovery .iso file that was built for an
# emulated ONIE target ( onie/machine/kvm_x86_64, for example ) to create a
# virtual hard drive and install ONIE on it from the recovery iso - in exactly
# the same way an ONIE recovery iso can be used to install ONIE on a switch.

# It also has the option of performing debug by running just a kernel
# and initrd with GDB, which can be extremely useful for validating
# the kernel when one is bringing up new hardware.

# In addition to radically simplifying the process of getting and image
# up and running it provides support for emulating a UEFI or legacy BIOS,
# and provides a virtual USB drive that can be used to store files
# between installations or during debug.
# See the online help, or the associated README file for more information.

# Everything is relative to this directory
ONIE_TOP_DIR=$( realpath "$(pwd)")

# Use --debug as first argument if -x is desired
if [ "$1" = "--debug" ];then
    echo "Enabling top level --debug"
    # and we'll hide that argument
    shift
    set -x
fi

# If true, defaults set in fxnApplyDefaults are set.
# Leave unset to specify everything on the command line.
APPLY_HARDCODE_DEFAULTS="TRUE"

# Base path to ./onie/build
BUILD_DIR="${ONIE_TOP_DIR}/../build"

# Store all files related to running emulation here
EMULATION_DIR="${ONIE_TOP_DIR}/emulation-files"

# ONIE recovery iso to boot off of for a fresh install
# Defaults based on machine type, or is user specified.
ONIE_RECOVERY_ISO=""


#
# Files in this directory get added to a virtual USB drive
#
USB_DIR="${EMULATION_DIR}/usb"

# Directory holds data to be put on the virtual drive
USB_TRANSFER_DIR="${USB_DIR}/usb-data"

# Path to the USB image We'll stuff the whole world in here
USB_IMG="${USB_DIR}/usb-drive"

# Virtual USB Drive size in MB
USB_SIZE="256M"

# Local mount point in host for loop back mount of USB file system.
# ( will require root privileges )
USB_MNT_DIR="${USB_DIR}/usb-mount"

# Virtual Hard Drive size in GB
HARD_DRIVE_SIZE=1G

#
# UEFI BIOS emulation files
#

# Any downloaded BIOS files can be cached here.
UEFI_DOWNLOADS_DIR="${EMULATION_DIR}/uefi-downloads"

# Copy from ovmf package installed on host system (Debian Linux example)
UEFI_BIOS_SOURCE_VARS=/usr/share/OVMF/OVMF_VARS.fd
# Put UEFI BIOS files here
UEFI_BIOS_DIR="${EMULATION_DIR}/uefi-bios"

UEFI_X86_BIOS_DIR="${UEFI_BIOS_DIR}/x86"

# File for storing set UEFI variables.
# Can be modified by user.
UEFI_BIOS_VARS="${UEFI_X86_BIOS_DIR}/OVMF_VARS.fd"


UEFI_BIOS_SOURCE_CODE=/usr/share/OVMF/OVMF_CODE.fd
# Source code file for UEFI BIOS
UEFI_BIOS_CODE="${UEFI_X86_BIOS_DIR}/OVMF_CODE.fd"

ARM_FLASH_FILES_DIR="${UEFI_BIOS_DIR}/arm-flash-files"
#
# Include additional functions for supporting emulation.
# Broken out for code clarity.

. onie-vm.lib

# If unpacking an image installer to get the
# intird/kernel, look for it here
UNPACK_INSTALLER_DIR="../unpack-installer"
# Put any kernel debs to be unpacked here
# Red Hat RPMs are a to-do item when need/opportunity arises.
UNPACK_LINUX_DEB_DIR="../unpack-linux-deb"

# Locally built kernel/initrd, copied in during unpack
INSTALLER_KERNEL="${UNPACK_INSTALLER_DIR}/kernel"
INSTALLER_INITRD="${UNPACK_INSTALLER_DIR}/initrd"

#
# Using kernel/vmlinux extracted from Debian package
# with 'extract-linux-deb'
#
DEB_KERNEL="${UNPACK_LINUX_DEB_DIR}/bzImage"
DEB_VMLINUX="${UNPACK_LINUX_DEB_DIR}/vmlinux"
# No initrd from deb as it generates it. ARM is different.
# Script with the command to run gdb
RUN_GDB_SCRIPT="run-onie-gdb.sh"

# A universal error checking function. Invoke as:
# fxnEC <command line> || exit 1
# Example:  fxnEC cp ./foo /home/bar || exit 1
function fxnEC ()
{
    # actually run the command
    "$@"

    # save the status so it doesn't get overwritten
    status=$?
    # Print calling chain (BASH_SOURCE) and lines called from (BASH_LINENO) for better debug
    if [ $status -ne 0 ];then
        echo "ERROR [ $status ] in $(caller 0), calls [ ${BASH_LINENO[*]} ] command: \"$*\"" 1>&2
    fi
    return $status
}

#
# Function to illustrate important points in the build process
#
STEP_COUNT=0
function fxnPS()
{
    echo "Step: [ $STEP_COUNT ] $1"
    STEP_COUNT=$(( STEP_COUNT +1 ))
}

#
# Command line help
#
function fxnHelp()
{
    # Set default configuration so values are visible in help
    fxnApplyDefaults
    echo ""
    echo " $0 [command][options]"
    echo "--------------------------------"
    echo ""
    echo "Commands"
    echo "---------"
    echo ""
    echo " Running:"
    echo "  run                     - Run from boot device selected with run time options."
    echo "  rk-onie                 - Run just the initrd/kernel from the ONIE ../build directory."
    echo "  rk-installer            - Run a kernel/initrd extracted from an ONIE installer (see below)"
    echo "  rk-deb-kernel-debug     - Use deb extracted kernel and installer initrd with rk-installer. (see below)"
    echo ""
    echo " Informational commands:"
    echo "  info-runables           - Print kernels and file systems available for use."
    echo "  info-run-options        - Print what could be run, given what was found."
    echo ""
    echo " Utility commands:"
    echo "  update-m-usb <dir>      - Create a 'USB drive' qcow2 file system for QEMU use."
    echo "                              if <dir> is not passed, will default to"
    echo "                              adding files from [ $USB_TRANSFER_DIR ]"
    echo "  clean                   - Delete generated directories."
	echo "  export-emulation <name> - Create tar file of all emulation files to run elsewhere. Name is optional."
	echo ""
    echo ""
    echo " Unpacking other kernels/initrds:"
    echo "  extract-linux-deb <v><b>- Extract passed vmlinux,bzImage debs to $UNPACK_LINUX_DEB_DIR"
    echo "  extract-installer <nos> - Extract kernel/initrd from NOS image installer."
    echo ""
    echo " Options"
    echo "---------"
    echo ""
    echo "  Target selection options:"
    echo "   --machine-name  <name> - Name of build target machine - ex kvm_x86_64, qemu_armv8a"
    echo "   --machine-revision <r> - The -rX version at the end of the --machine-name"
    echo ""
    echo "  Runtime options:"
    echo "   --m-onie-iso  <file>   - Boot off of recovery ISO at <file> and install onto qcow2"
    echo "   --m-onie-arch <arch>   - Define target architecture as one of x86_64 or arm64."	
    echo "   --m-embed-onie         - Boot to embed onie. Requires --m-onie-iso <file>"
    echo "   --m-boot-cd            - Boot off of rescue CD to start."
    echo "   --m-mount-cd           - CD is accessible when booting off hard drive."
    echo "   --m-cpu                - Set number of virtual processors."
    echo "   --m-secure-default     - Set --m-bios-uefi --m-usb-drive --m-boot-cd to demonstrate secure boot."
    echo ""
    echo "  BIOS configuration:     Default: Legacy BIOS."
    echo "   --m-bios-uefi          - Use UEFI rather than legacy bios."
    echo "   --m-bios-vars-file <f> - Use a copy of a previously saved OVMF_VARS file at: <file>"
    echo "   --m-bios-clean         - Delete OVMF_VARS.fd and replace with empty copy to erase all set UEFI vars."
    echo ""
    echo "  Emulation instance configuration:"
    echo "   --m-telnet-port<num>   - Set telnet port number.          Default: [ $QEMU_TELNET_PORT ]"
    echo "   --m-vnc-port   <num>   - Set vnc port number.             Default: [ $QEMU_VNC_PORT ]"
    echo "   --m-ssh-port   <num>   - Set local ssh port forward.      Default: [ $QEMU_SSH_PORT ]"
    echo "   --m-monitor-port <#>   - Telnet port for QEMU monitor.    Default: [ $QEMU_MONITOR_PORT ]"
    echo "   --m-network-mac <xx>   - Two hex digits for a unique MAC. Default: [ $MAC_ADDRESS_ENDS_IN ]"
    echo "   --m-gdb                - Enable gdb through QEMU."
    echo ""
    echo "  Storage:"
    echo "   --m-hd-clean           - Replace target 'hard drive' with an empty one  and run install."
    echo "   --m-hd-file <file>     - Use a previously configured drive file."
    echo "   --m-nvme-drive         - Have QEMU emulate storage as NVME drives."
    echo "   --m-usb-drive          - Make virtual USB drive available at KVM run time."
    echo ""
    echo "  Help:"
    echo "   --help                 - This output."
    echo "   --help-examples        - Examples of use."
    echo ""
}

# Show, don't tell
function fxnHelpExamples()
{
    local thisScript
    thisScript="$( basename "$0" )"	
    echo "
 Help Examples
-----------------------------

#
# Running just a kernel
# ---------------------------
# Run just the kernel and intird from the ONIE build
    Cmd: $thisScript rk-onie

# Run just the kernel and initrd from an ONIE installer
    Cmd: $thisScript rk-installer

# Run a debug kernel from a Debian linux-image deb, with the ONIE initrd
    Cmd: $thisScript rk-installer-debug

# Unpack an ONIE installer and store the initrd/kernel where it can be used to run
    Cmd: $thisScript unpack-installer

# Unpack the two Debian Linux linux-image*-debug-*.debs and put them in a known location
    Cmd: $thisScript extract-linux-deb

#
# Runtime info
# ---------------------------
# List things that could be run
    Cmd: $thisScript info-runables
# List things that can currently be run
    Cmd: $thisScript info-run-options

#
# Running a qcow2 image as a virtual hard drive
# ---------------------------
# Boot off a recovery iso, install onie in an empty qcow2 with legacy BIOS
    Cmd: $thisScript run --m-embed-onie --m-hd-clean

# Run a qcow2 that has onie embedded (see above)
    Cmd: $thisScript run

# Run and install ONIE on an empty qcow2 hard drive file using UEFI BIOS
    Cmd: $thisScript run --m-onie-iso <path to recovery iso> --m-usb-drive --m-bios-uefi --m-secure --m-hd-clean --m-bios-clean

# Run qcow2 hard drive file that has ONIE installed using UEFI BIOS
    Cmd: $thisScript run  --m-bios-uefi

# Run Secure Boot and install ONIE on an empty qcow2 and keep UEFI vars
    Cmd: $thisScript run --m-secure --m-hd-clean --m-embed-onie

# Run Secure Boot using previously embedded image (see above)
    Cmd: $thisScript run --m-secure

# Run new secure boot while another QEMU is running:
    Cmd: $thisScript --m-network-mac 21 --m-telnet-port 9400 --m-vnc-port 127 --m-ssh-port 4122 --m-embed-onie --m-secure  --m-hd-clean  --m-bios-clean

# Embed ONIE on a new arm64 emulation target built from ../machine/myvendor/mynewmachine that is not qemu_armv8a
# Note that --m-onie-arch is required. Known targets can default their architecture. New ones need it supplied.
./onie-vm.sh run --m-bios-uefi --m-bios-clean --m-hd-clean --m-embed-onie --machine-name mynewmachine --m-onie-arch arm64
"
    echo "
Quick setup:
 To embed ONIE on a virtual hard drive:
 -  kvm_x86_64
      ./onie-vm.sh run --machine-name kvm_x86_64 --machine-revision r0 --m-usb-drive --m-bios-uefi --m-bios-clean --m-hd-clean --m-embed-onie --m-boot-cd --m-onie-iso ../build/images/onie-recovery-x86_64-kvm_x86_64-r0.iso  
      OR, using defaults
      ./onie-vm.sh run --machine-name kvm_x86_64  --m-usb-drive --m-bios-uefi --m-embed-onie
 - qemu_armv8a
      ./onie-vm.sh run --machine-name qemu_armv8a --m-bios-uefi --m-bios-clean --m-hd-clean --m-embed-onie --m-onie-iso ../build/images/onie-recovery-arm64-qemu_armv8a-r0.iso 

 In a separate window, start the virtual machine by logging in with:
  telnet localhost $QEMU_TELNET_PORT

 To run after embedding ONIE, type:
 -  kvm_x86_64
    $0 run --machine-name kvm_x86_64 --m-usb-drive --m-bios-uefi
 - qemu_armv8a
    $0 run --machine-name qemu_armv8a --m-usb-drive --m-bios-uefi

"
}


#
# Create a clean virtual hard drive to install on.
# Keep an unmodified backup copy for easy reversion.
#
function fxnCreateHardDrive ()
{
    if [ ! -e "$HARD_DRIVE" ];then
        fxnPS "Creating qcow2 image $HARD_DRIVE to use as 'hard drive'"
        fxnEC qemu-img create -f qcow2 -o preallocation=full  "$HARD_DRIVE" "${HARD_DRIVE_SIZE}" || exit 1
        if [ -e "$CLEAN_HARD_DRIVE" ];then
            rm "$CLEAN_HARD_DRIVE"
        fi
    fi

    # Keep a copy of this that has not been installed on for debug purposes.
    if [ ! -e "$CLEAN_HARD_DRIVE" ];then
        echo "Creating untouched $HARD_DRIVE image at $CLEAN_HARD_DRIVE for reference."
        rsync --progress "$HARD_DRIVE" "$CLEAN_HARD_DRIVE"
    fi

}


#
# Clean out all staged keys and USB images as well
# as the kvm code
function fxnMakeClean()
{
    if [ "$(basename "$(pwd)")" != "build-config" ];then
        echo "$0 must be run from onie/build-config. Exiting."
        exit 1
    fi

    echo "=== Cleaning Secure Boot artifacts."

    if [ -e "${USB_IMG}.raw" ];then
        echo "  Deleting      ${USB_IMG}.raw"
        rm "${USB_IMG}.raw"
    fi
    if [ -e "${USB_IMG}.qcow2" ];then
        echo "  Deleting      ${USB_IMG}.qcow2"
        rm "${USB_IMG}.qcow2"
    fi

    if [ -e "${USB_TRANSFER_DIR}" ];then
        echo "  Deleting      ${USB_TRANSFER_DIR}"
        rm -rf "$USB_TRANSFER_DIR"
    fi

    # Used in ARM emulation
    if [ -e "${ARM_FLASH_FILES_DIR}" ];then
        echo "  Deleting      ${ARM_FLASH_FILES_DIR}"
        rm -rf "$ARM_FLASH_FILES_DIR"
    fi

    if [ -e "${HARD_DRIVE}" ];then
        echo "  Deleting      $HARD_DRIVE"
        rm "$HARD_DRIVE"
    fi

    # Since this is a clean rebuild, the hard drive will be recreated.
    # remove the backup of the 'drive's pre install state.
    if [ -e "${CLEAN_HARD_DRIVE}" ];then
        echo "  Deleting      $CLEAN_HARD_DRIVE"
        rm "$CLEAN_HARD_DRIVE"
    fi


    if [ -e "$EMULATION_DIR" ];then
        echo "  Deleting      $EMULATION_DIR"
        rm -rf "$EMULATION_DIR"
    fi

    echo ""
    echo "Done cleaning everything except the build tools and the safe place."

    exit

}


#
# Actually run the emulation, using QEMU
#
function fxnRunEmulation()
{

    if [ -e /.dockerenv ];then
        echo "ERROR: you probably don't want to try to run QEMU from inside a container. Exiting."
        exit 1
    fi

    #
    # Dump our current configuration
    #
    fxnPrintSettings


    # Megabytes of RAM the VM will have
    #QEMU_MEMORY_M=2048
    # UEFI firmware
    #    OVMF="${EMULATION_DIR}/OVMF.fd"

    USB_DRIVE="${USB_IMG}.qcow2"
    CDROM="$ONIE_RECOVERY_ISO"

    # boot from CD once
    boot="order=cd,once=d"
    cdrom="-cdrom $CDROM"


    echo "#########################################"
    echo "#                                       #"
    echo "# Running ONIE on qcow2 image           #"
    echo "#                                       #"
    echo "#########################################"

    if [ "$DO_QEMU_NVME_DRIVE" = "TRUE" ];then
        echo "Emulating NVME drives for storage."
        DRIVE_LINE="          -drive file=${HARD_DRIVE},if=none,id=nvme0 -device nvme,drive=nvme0,serial=nvme1,num_queues=4 "
    else
        case "$ONIE_ARCH" in
            'x86_64' )
                DRIVE_LINE=" -drive file=${HARD_DRIVE},media=disk,if=virtio,index=0 "
                #DRIVE_LINE=" -drive index=0,if=none,file=${HARD_DRIVE},id=hd  -device virtio-blk-pci,drive=hd,bootindex=0 "
                # This ^^ totally breaks everything
                ;;

            'arm64' )
                DRIVE_LINE=" -drive index=0,if=none,file=${HARD_DRIVE},id=hd  -device virtio-blk-pci,drive=hd,bootindex=0 "
                ;;
        esac
    fi

    if [ "$QEMU_MONITOR_PORT" != "" ];then
        # if the user specified a monitor port, then activate it
        QEMU_MONITOR="          -monitor telnet:localhost:55555,server,nowait "
    fi
    if [ "$DO_QEMU_GDB" = "TRUE" ];then
        # -s open gdb port on 1234
        # -S wait for gdb continue command
        USE_GDB=" -s -S "
    fi

    #
    # Use OVMF bios for UEFI and the local file to store changes.
    #
    if [ "$DO_QEMU_UEFI_BIOS" = "TRUE" ];then
		if [ "$ONIE_ARCH" = "x86_64" ];then
			BIOS_LINE="-drive if=pflash,format=raw,readonly,file=${UEFI_BIOS_CODE} -drive if=pflash,format=raw,file=${UEFI_BIOS_VARS}"
		fi
    fi

    # specify a mac address, and you get network.
    if [ "$MAC_ADDRESS_ENDS_IN" != "" ];then
        NETWORK_LINE="  -vnc 0.0.0.0:$QEMU_VNC_PORT  -device virtio-net,netdev=onienet,mac=52:54:00:13:34:$MAC_ADDRESS_ENDS_IN  -netdev user,id=onienet,hostfwd=tcp::${QEMU_SSH_PORT}-:22 "

    fi

    if [ "$DO_QEMU_USB_DRIVE" = "TRUE" ];then
        # Attach an additional USB drive to carry files. Not all installers handle
        # more than one potential storage target well, so it is optional

        case "$ONIE_ARCH" in
            'x86_64' )
                USB_DRIVE_LINE=" -drive file=$USB_DRIVE,media=disk,if=virtio,index=1"
                ;;

            'arm64' )
                USB_DRIVE_LINE=" -drive if=none,file=${USB_DRIVE},id=usb-hd -device virtio-blk-pci,drive=usb-hd "
                ;;
        esac
    fi

    if [ "$DO_BOOT_FROM_CD" = "TRUE" ];then
        case "$ONIE_ARCH" in
            'x86_64' )
                BOOT_LINE=" -boot $boot $cdrom "
                ;;

            'arm64' )
                BOOT_LINE=" $cdrom "
                ;;
        esac
    else
        # Not booting off cd, but keeping it accessible from the hard drive
        if [ "$DO_MOUNT_CD" = "TRUE" ];then
            # For QEMU, treat the ISO as another virtio drive.
            # Device shows up, but can't be read.
            # Probably need kernel support to mount it.
            CD_DRIVE_LINE=" -drive file=$CDROM,media=cdrom,if=virtio,index=2 "
        fi
    fi

    # QEMU_PROCESSOR_ARGS is set when determining architecture off
    # $ONIE_MACHINE_TARGET
    RUN_COMMAND="qemu-system-${QEMU_ARCH} \
         ${QEMU_PROCESSOR_ARGS} \
         -smp $QEMU_CPUS \
         -m $QEMU_MEMORY_M \
         -name onie \
         $USE_GDB \
         $QEMU_MONITOR \
         $BIOS_LINE \
         $BOOT_LINE \
         $DRIVE_LINE \
         $CD_DRIVE_LINE \
         $USB_DRIVE_LINE \
         $NETWORK_LINE \
         -nographic \
         -serial telnet:localhost:$QEMU_TELNET_PORT,server"

    echo "Invoking QEMU with:"
	    echo "$RUN_COMMAND " | sed -e 's/ -/\n -/g' 


    echo ""
    echo " Instructions:"
    echo "---------------"
    echo " Log in with: telnet localhost $QEMU_TELNET_PORT"
    echo "  If ssh is up, use ssh -p $QEMU_SSH_PORT "
    echo ""
    echo " Key configuration: "
    echo ""
    echo "  To interrupt boot, keep pressing:"
    echo "   F2         - UEFI BIOS"
    echo "   Down arrow - Grub"
    echo "   ctrl-a c   - QEMU monitor"
    echo "  Suggested setup:"
    echo "   1 - Embed ONIE  <Installs and reboots>"
    echo "   2 - Install OS  <Boots in to ONIE>"
    if [ "$USB_DRIVE_LINE" != "" ];then
        echo "   3 - Access virtual USB drive by typing:  'mount /dev/vdX /mnt/usb'"
        echo "        (Where X is the only /dev/vd* without a partition number.)"
        echo "   4 - ls /mnt/usb"
        # The USB drive wants to be part of the install in arm64, thus
        #  it will be erased if 'embed onie' is chosen.
        # Otherwise it and the CD can coexist.
        if [ "$DO_BOOT_FROM_CD" = "TRUE" ] && [ "$ONIE_ARCH" = "arm64" ];then
            echo ""
            echo "#####################################################################"
            echo "#                                                                   #"
            echo "#   WARNING: 'USB drive' will be erased if 'Embed ONIE' is chosen.  #"
            echo "#             The two can co-exist otherwise.                       #"
            echo "#                                                                   #"
            echo "#####################################################################"
            echo ""
        fi
    fi
    echo "  Note, ping does not work in kvm, but other network utils do!"

    echo ""
    if [ "$DO_BOOT_FROM_CD" = "FALSE" ];then
        # Keep this as a reminder when you forget why this happened
        echo " If you end up in UEFI - use qemu-embed-onie instead - you're not booting off the recovery iso."
    fi
    $RUN_COMMAND



}
# Run a locally built kernel and initrd
function fxnRunONIEKernel()
{
    # open gdb port on 1234
    local USE_GDB=" -s "
    local kernelPath="$ONIE_KERNEL"
    local initrdPath="$ONIE_INITRD"

    echo "#########################################################"
    echo "#                                                       #"
    echo "# Kernel: From ONIE build                               #"
    echo "# Initrd: From ONIE build                               #"
    echo "#                                                       #"
    echo "#########################################################"
    #
    RUN_COMMAND="qemu-system-${QEMU_ARCH} 
    -kernel $kernelPath 
    -nographic 
    -append 'console=ttyS0' -append 'debug' 
    -initrd $initrdPath 
    -m 512 
    --enable-kvm 
    -cpu host 
    -s -S "

    echo "# Running: $RUN_COMMAND " | sed -e 's/ -/\n -/g'

    echo "# Exit qemu with:  Ctrl-a, c quit"
    echo ""

    GDB_COMMAND="gdb -ex 'file $ONIE_VMLINUX' 
           -ex 'add-auto-load-safe-path ../build/${ONIE_MACHINE}/kernel/linux-4.9.95/scripts/gdb/vmlinux-gdb.py' 
           -ex 'target remote localhost:1234' 
           -ex 'break start_kernel'"
    # Create header
    fxnMakeGDBScript "$GDB_COMMAND"

    echo "Run gdb with $(pwd)  ./$RUN_GDB_SCRIPT"

    $RUN_COMMAND

}



# One stop to set default values for the run.
function fxnApplyDefaults()
{
    # Default to running ONIE KVM - can be overridden on command line.
    if [ "$ONIE_MACHINE_TARGET" = "" ];then
        ONIE_MACHINE_TARGET="kvm_x86_64"
        ONIE_ARCH="x86_64"
    fi

    # KVM defaults
    DO_QEMU_NVME_DRIVE="FALSE"
    DO_QEMU_UEFI_BIOS="FALSE"
    QEMU_MEMORY_M="2048"
    QEMU_CPUS="2"
    # Just edit these in place
    if [ "$APPLY_HARDCODE_DEFAULTS" = "TRUE" ];then
        echo ""
        echo "NOTE: Applying QEMU/ONIE hardcode default settings."
        echo ""
        MAC_ADDRESS_ENDS_IN="1E"
        DO_QEMU_GDB="FALSE"
        QEMU_MONITOR_PORT=""
        QEMU_TELNET_PORT="9300"
        QEMU_VNC_PORT="128"
        QEMU_SSH_PORT="4022"
    fi


}

# Spell out what has been set
function fxnPrintSettings()
{
    echo ""
    echo "####################################################"
    echo "#"
    echo "#  $0 Settings "
    echo "#"
    echo "#--------------------------------------------------"
    echo "#  Running in         [ $(pwd) ]"
    echo "#  Machine name       [ $ONIE_MACHINE_TARGET ] "
    echo "#  Machine revision   [ $ONIE_MACHINE_REVISION ]"
    echo "#  Boot from CD       [ $DO_BOOT_FROM_CD ]"
    echo "#   Path to CD        [ $ONIE_RECOVERY_ISO ]"
    echo "#  ONIE architecture  [ $ONIE_ARCH ]"	
    echo "#  QEMU processors    [ $QEMU_CPUS ]"
    echo "#  QEMU MAC ends in   [ $MAC_ADDRESS_ENDS_IN ]"
    echo "#  QEMU UEFI BIOS     [ $DO_QEMU_UEFI_BIOS ]"
    echo "#  QEMU GDB           [ $DO_QEMU_GDB ]"
    echo "#  QEMU Monitor       [ $QEMU_MONITOR_PORT ]"
    echo "#  QEMU telnet port   [ $QEMU_TELNET_PORT ]"
    echo "#  QEMU VNC port      [ $QEMU_VNC_PORT ]"
    echo "#  QEMU SSH port      [ $QEMU_SSH_PORT ]"
    echo "#  QEMU NVME drive    [ $DO_QEMU_NVME_DRIVE ]"

    echo "#"
    if [ -e "$ONIE_KERNEL" ];then
        echo "#  ONIE Kernel        [ $ONIE_KERNEL_VERSION ]"
    fi
    echo "#  ONIE machine tgt   [ $ONIE_MACHINE_TARGET ]"

    if [ "$DO_QEMU_USB_DRIVE" = "TRUE" ];then
        echo "#  USB stage dir      [ $USB_TRANSFER_DIR ]"
        echo "#  USB filesystem     [ $USB_IMG ]"
        echo "#  USB size           [ $USB_SIZE ]"
        echo "#  USB loop mount pt  [ $USB_MNT_DIR ]"
    fi
    echo "####################################################"
    echo ""
}


# Put fresh UEFI bios files in the install area
# If $1 = clean, then reset files
function fxnSetupUEFIBIOS()
{
	local doClean="$1"

    if [ "$ONIE_ARCH" = "x86_64" ];then
		if [ "$doClean" = "bios-clean" ];then
			echo "Deleting $UEFI_X86_BIOS_DIR contents."
			rm -rf "${UEFI_X86_BIOS_DIR}"
		fi
		
		if [ ! -d "$UEFI_X86_BIOS_DIR" ];then
			fxnEC mkdir -p "$UEFI_X86_BIOS_DIR" || exit 1
		fi
		
		if [  ! -e "$UEFI_BIOS_VARS" ];then
			# Is there a backup UEFI variable storage file
			# that might have been pre-configured to
			# have keys?
			echo "   Copying $UEFI_BIOS_SOURCE_VARS to $UEFI_BIOS_VARS "
			cp "$UEFI_BIOS_SOURCE_VARS" "$UEFI_BIOS_VARS" || exit 1

			# Copy over the runtime code for the BIOS
			echo "   Copying $UEFI_BIOS_SOURCE_CODE to $UEFI_BIOS_CODE "
			cp "$UEFI_BIOS_SOURCE_CODE" "$UEFI_BIOS_CODE" || exit 1
		fi
    fi
    #
    # UEFI BIOS for arm

    if [ "$ONIE_ARCH" = "arm64" ];then
		if [ "$doClean" = "bios-clean" ];then
			echo "Deleting $ARM_FLASH_FILES_DIR contents"
			rm -rf "${ARM_FLASH_FILES_DIR}"
		fi

        if [ ! -e "${ARM_FLASH_FILES_DIR}" ];then
			echo "Creating ${ARM_FLASH_FILES_DIR}"
			mkdir -p "${ARM_FLASH_FILES_DIR}"
		fi

		# Currently this is the only known working ARM BIOS
        UEFI_BIOS_SOURCE='linaro-uefi'
		ARM_UEFI_BIOS_FILE="linaro-16.02-QEMU_EFI.fd"
		
		# Has ARM source BIOS been downloaded?
		if [ ! -e "${UEFI_DOWNLOADS_DIR}/${ARM_UEFI_BIOS_FILE}" ];then			
            echo "   Getting UEFI BIOS for ARM from: [ $UEFI_BIOS_SOURCE ]"
            case "$UEFI_BIOS_SOURCE" in
                'linaro-uefi' )
                    # This is a known working version
                    #wget http://releases.linaro.org/components/kernel/uefi-linaro/16.02/release/qemu64/linaro-16.02-QEMU_EFI.fd
					fxnEC wget --directory-prefix="$UEFI_DOWNLOADS_DIR" http://mirror.opencompute.org/onie/onie-emulation-bios/armv8a/"$ARM_UEFI_BIOS_FILE" || exit 1
                    ;;
            esac
		fi

		# Flash 0 and 1 have the same roles of BIOS code and BIOS storage that
		# OVMF_CODE.fd and OVMF_VARS.fd do for x86. flash0 and 1 seem to be a
		# naming convention, so the names have been left that way.
		if [ ! -e "${ARM_FLASH_FILES_DIR}/flash0.img" ];then
            echo "   Creating flash0 in $ARM_FLASH_FILES_DIR"
            # Format the img file that will hold ARM UEFI BIOS data
            # They have to be exactly 64M in size.
            dd if=/dev/zero of="${ARM_FLASH_FILES_DIR}/flash0.img" bs=1M count=64
            # Add the UEFI BIOS data from our reference file
            dd if="${UEFI_DOWNLOADS_DIR}/${ARM_UEFI_BIOS_FILE}" of="${ARM_FLASH_FILES_DIR}/flash0.img" conv=notrunc
            echo "   Creating flash1 in $ARM_FLASH_FILES_DIR"
            # Format the image that will hold BIOS configuration
            dd if=/dev/zero of="${ARM_FLASH_FILES_DIR}/flash1.img" bs=1M count=64
		fi
 
    fi

}

# create the emulation directory
function fxnSetUpEmulationDir()
{
    # is the emulation directory set up
    if [ ! -e "$EMULATION_DIR" ];then

        echo "Creating $EMULATION_DIR to hold run time files."
        mkdir -p "$EMULATION_DIR"
        echo "Creating $ARM_FLASH_FILES_DIR to hold flash for ARM emulation."
        mkdir -p "$ARM_FLASH_FILES_DIR"
        echo "Creating $USB_TRANSFER_DIR to hold files for the virtual USB drive."
        mkdir -p "$USB_TRANSFER_DIR"
        echo "Files in $USB_TRANSFER_DIR are added to the virtual USB drive" > "${USB_TRANSFER_DIR}/README.txt"
        echo "Creating $UEFI_BIOS_DIR to hold UEFI BIOS files."
        mkdir -p "$UEFI_BIOS_DIR"
        mkdir -p "$UEFI_DOWNLOADS_DIR"
		
    fi

}

# Clean out the emulation directory, accounting for loop back mounts.
function fxnCleanEmulationDir()
{
    echo "Cleaning up emulation area."
    # Make this more robust as more bad cleanups happen
    # Hunt for loop back mounts of this usb directory

    hungLoopDev="$( df | grep "$USB_MNT_DIR" | awk '{print$1}' | head -n 1)"
    if [ "$hungLoopDev" != "" ];then
        hungLoopMount="$( df | grep "$USB_MNT_DIR" | awk '{print$6}' | head -n 1)"
        echo " - Unmounting loopback $hungLoopDev at $hungLoopMount"
        sudo umount "$hungLoopMount"
        #sudo /sbin/losetup -d $hungLoop
    fi
    # wipe out generated files
    if [ -d "$EMULATION_DIR" ];then
        echo " - Deleting [ $EMULATION_DIR ]"
        #        sudo rm -rf "$EMULATION_DIR"
        rm -rf "$EMULATION_DIR"
    fi

    # --but always keep the usb transfer directory around
    # and a directory to hold UEFI bios files...
    fxnSetUpEmulationDir

    if [ -e "$UEFI_INSTRUCTIONS_TXT" ];then
        echo " - Deleting [ $UEFI_INSTRUCTIONS_TXT ]"
        rm -f "$UEFI_INSTRUCTIONS_TXT"
    fi

    if [ -e "$RUN_GDB_SCRIPT" ];then
        echo " - Deleting $RUN_GDB_SCRIPT"
        rm -f "$RUN_GDB_SCRIPT"
    fi

    if [ -e 'QEMU_EFI.fd' ];then
        echo " - Deleting downloaded ARM UEFI BIOS."
        rm QEMU_EFI.fd*
    fi
    echo " Done cleaning the emulation directory."
}

# Make sure required components are present
function fxnSetupEnvironment()
{
    fxnSetUpEmulationDir
    # do we have a hard drive
    if [ ! -e "$HARD_DRIVE" ];then
        fxnCreateHardDrive
    fi

    # Get BIOS files, and clean if needed.
	fxnSetupUEFIBIOS $DO_BIOS_CLEAN

	if [ "$DO_QEMU_USB_DRIVE" = "TRUE" ];then
		# does a usb drive need to be set up
		if [ ! -e "${USB_IMG}.qcow2" ];then
			fxnUSBStoreFiles
		fi
	fi


}

##################################################
#                                                #
# MAIN  - script processing starts here          #
#                                                #
##################################################

if [ "$#" = "0" ];then
    # Require an argument for action.
    # Always trigger help messages on no action.
    fxnHelp
    exit 0
fi

# Set a default configuration that the CLI can override.
fxnApplyDefaults

#
# Gather arguments and set action flags for processing after
# all parsing is done. The only functions that should get called
# from here are ones that take no arguments.
while [[ $# -gt 0 ]]
do
    term="$1"

    case $term in

        # Run qemu using a qcow2 filesystem
        'run' | --run )
            DO_RUN_KVM="TRUE"
            ;;

        --m-onie-iso )
            # specify ONIE recovery iso to use
            if [ ! -e "$2" ];then
                echo "ERROR! invalid ONIE iso path [ $2 ]. Exiting."
                exit 1
            fi
            ONIE_RECOVERY_ISO="$(realpath "$2")"
            shift
            ;;
		
		--m-onie-arch )
			# Specify target architecture. Use this for a new emulation target that
			# is not one of the currently known defaults.
            if [ "$2" != "" ];then
                ONIE_ARCH="$2"
            fi
        	shift
			;;

        --m-embed-onie )
            # boot off of rescue cd to initialize an empty qcow2 filesystem
            echo ""
            echo "-- Using recovery iso to boot."
            echo ""
            DO_BOOT_FROM_CD="TRUE"
            DO_RUN_KVM="TRUE"
            ;;

        # Use previously saved qcow2 drive file
        --m-hd-file )
            if [ ! -e "$2" ];then
                # Accept files in the kvm directory if the path doesn't resolve.
                if [ ! -e "${EMULATION_DIR}/${2}" ];then
                    echo "Error! --m-hd-file file [ $2 ] does not exist. Exiting."
                    exit 1
                else
                    USE_QCOW2_HD_FILE="${EMULATION_DIR}/$2"
                    echo "Found in kvm directory. Using: [ $USE_QCOW2_HD_FILE ]"
                fi
            else
                USE_QCOW2_HD_FILE="$2"
            fi
            shift
            ;;

        # Wipe out the modified qcow2 and restore from backup.
        --m-hd-clean )
            DO_BOOT_FROM_CD="TRUE"
            DO_RUN_KVM="TRUE"
			DO_HD_CLEAN="TRUE"
            ;;


        # Do loopback mount to format usb image.
        # It is a separate option so it can be run outside of the container.
        # if $2
        'update-m-usb' )
            fxnSetUpEmulationDir
            # setting a non-default path for the files to add
            if [ "$2" != "" ];then
                # This has to be real, and a directory
                if [ -d "$2" ];then
                    USB_TRANSFER_DIR="$( realpath "$2" )"
                else
                    echo "ERROR! update-m-usb failed to find path [ $2 ]. Exiting."
                    exit 1
                fi
            fi
            # Expect to have secure boot files.
            # Hardcode for now
            fxnUSBStoreFiles "rebuild"
            exit
            ;;

        'clean' )
			# wipe out all generated files.
            fxnCleanEmulationDir
            exit
            ;;

		'export-emulation' )
			# Pack emulation files in to a tar archive
			# to run elsewhere. The second parameter
			# is optional.
			fxnExportEmulationFiles $2
			exit
			;;
		
        # Onie kernel and initrd, run on their own
        'rk-onie' )
            # just run the kernel and initrd
			DO_RUN_ONIE_KERNEL="TRUE"			
            ;;

        # Run the kernel and initrd pulled from the installer
        'rk-installer' )
			DO_RUN_INSTALLER_KERNEL="TRUE"			
            ;;

        'rk-deb-kernel-debug' )
            # Run a debug built Debian kernel with the ONIE installer's
            # initrd.
            if [ ! -e "$DEB_KERNEL" ];then
                echo "ERROR! Failed to find kernel extracted from deb at [ $DEB_KERNEL ]"
                echo " Get the "
                echo "   linux-image*debug-<arch>*deb and"
                echo "   linux-image-debug-<arch>-dbg*deb"
                echo "  files and run $0 extract-linux-deb."
                echo " Exiting."
                exit 1
            fi
			DO_RUN_DEBIAN_KERNEL="TRUE"
            ;;

        # Use a copy of a previously configured BIOS via it's OVMF_VARS.fd file
        # Note - you'll probably want to make sure the ONIE and NOS boot entries
        # are deleted before preserving the image, as new partitions have
        # new GUIDs
        --m-bios-vars-file )
            if [ ! -e "$2" ];then
                echo "Error! --m-bios-vars-file file [ $2 ] does not exist. Exiting."
                exit 1
            fi
            USE_OVMF_VARS_FILE="$2"
            # flag this for action later in case a clean runs in the meantime
            DO_UPDATE_OVMF_VARS_FILE="TRUE"
            shift
            ;;

        # Delete the OVMF_VARS.fd file and replace with a clean copy
        # to wipe out any variables that have been set.
        --m-bios-clean )			
			DO_BIOS_CLEAN="bios-clean"
            ;;


        --m-telnet-port )
            if [ "$2" = "" ];then
                echo "ERROR! Must supply a number for the telnet port. Ideally above 9000. Exiting."
                exit 1
            fi
            QEMU_TELNET_PORT="$2"
            shift
            ;;

        --m-vnc-port )
            # vnc 0.0.0.0:<this number>
            if [ "$2" = "" ];then
                echo "ERROR! Must supply a number for the vnc port. Defaults to [ $QEMU_VNC_PORT ]. Exiting."
                exit 1
            fi
            QEMU_VNC_PORT="$2"
            shift
            ;;

        --m-ssh-port )
            #hostfwd=tcp::${QEMU_SSH_PORT}-:22 "
            if [ "$2" = "" ];then
                echo "ERROR! Must supply a number greater than 1024 for the ssh port. Defaults to [ $QEMU_SSH_PORT ]. Exiting."
                exit 1
            fi
            QEMU_SSH_PORT="$2"
            shift
            ;;

        --machine-name | -n )
            if [ "$2" = "" ];then
                echo "ERROR! Must supply a machine name: ex 'mlnx_x86'. Exiting."
                exit 1
            fi
            ONIE_MACHINE_TARGET="$2"
            shift
            ;;
        --machine-revision )
            if [ "$2" = "" ];then
                echo "ERROR! Must supply a machine revision: ex '-r0'. Exiting."
                exit 1
            fi
            ONIE_MACHINE_REVISION="$2"
            shift
            ;;
        --m-nvme-drive )
            # IF true, have QEMU emulate the storage as NVME drives.
            DO_QEMU_NVME_DRIVE="TRUE"
            ;;

        --m-monitor-port )
            # create a qemu monitor telnet port at 5555
            if [ "$2" = "" ];then
                echo "ERROR! Must supply a telnet port for QEMU monitor. Around 55555. Exiting."
                exit 1
            fi
            QEMU_MONITOR_PORT="$2"
            shift
            ;;

        --m-gdb )
            # Enable gdb in qemu
            DO_QEMU_GDB="TRUE"
            ;;


        --m-bios-uefi )
            # Use UEFI bios
            DO_QEMU_UEFI_BIOS="TRUE"
            ;;

        --m-network-mac )
            if [ "$2" = "" ];then
                echo "ERROR! Must supply 2 hex digits for end of qemu mac Ex:1A. Exiting."
                exit 1
            fi
            MAC_ADDRESS_ENDS_IN="$2"
            shift
            ;;

        --m-boot-cd )
            # boot off a rescue cd
            DO_BOOT_FROM_CD="TRUE"
            ;;

        --m-mount-cd )
            # Boot from hard drive, but make cd available
            DO_MOUNT_CD="TRUE"
            ;;

        --m-usb-drive )
            # Copy everything out of USB_TRANSFER_DIR, and put it on a
            # QCOW2 filesystem that will present as a USB drive.
            DO_QEMU_USB_DRIVE="TRUE"
            ;;

        --m-cpu )
			# Number of virtual processors to emulate
            if [ "$2" != "" ];then
                QEMU_CPUS="$2"
            fi
            shift
            ;;

        --m-secure-default )
            # One stop to set options to run with secure boot.
            # Subsequent runs may need --m-hd-clean or --m-bios-clean added.
            # Secure boot only works with UEFI bios
            DO_QEMU_UEFI_BIOS="TRUE"
            # Create a second filesystem to store keys that must be loaded
            # in to the bios, and have that present as a USB drive.
            DO_QEMU_USB_DRIVE="TRUE"
            # Require iso image to boot off of for initial ONIE install
            # Check to see that it is configured after argument parsing.
            SET_DEFAULT_ONIE_RECOVERY_ISO="TRUE"
            ;;

        # Given a Debian linux-image deb, pull the kernel (no initrd exists)
        'extract-linux-deb' )
            fxnUnpackLinuxDeb "$2" "$3"
            exit
            ;;


        # given an image installer, unpack it and pull the initrd and kernel
        'extract-installer' )
            fxnExtractInstaller "$2"
            exit
            ;;


        'info-runables' )
            # what permutations of kernel/debug/initrd can be run?
            fxnListRunables
            exit
            ;;

        'info-run-options' )
            # What can we run, given what is available?
            fxnRunOptions
            exit
            ;;


        'info-check-signed' )
            # Check all things that could be signed
            fxnVerifySigned
            exit 0
            ;;


        -h | 'help' | --help )
            fxnHelp
            exit 0
            ;;


        --help-examples )
            fxnHelpExamples
            exit 0
            ;;

        *)
            fxnHelp
            echo "Unrecognized option [ $term ]. Exiting"
            exit 1
            ;;

    esac
    shift # skip over argument

done

#
# Set variables that depend on user input


#
# Map machines to processor architectures
QEMU_PROCESSOR_ARGS=""

if [ "$( find ../build/images -type f -name onie-recovery*$ONIE_MACHINE_TARGET*)" != "" ];then
   echo "$ONIE_MACHINE_TARGET exists."
else
	echo "$ONIE_MACHINE_TARGET not found under ../build/images. Exiting."
	exit 1
fi
	   
# If the emulation is a known target, set ONIE_ARCH for default configuration.
case "$ONIE_MACHINE_TARGET" in
    'kvm_x86_64' )
		ONIE_ARCH='x86_64'
        ;;
    'qemu_armv8a' )
		ONIE_ARCH='arm64'
        ;;

    'qemu_armv7a' )
		ONIE_ARCH='arm32'		
        ;;

esac


case "$ONIE_ARCH" in
	'x86_64' )
		fxnEmulationDefaultsX86_64
        ;;
    'arm64' )
		fxnEmulationDefaultsARM64
        ;;

    'arm32' )
		fxnEmulationDefaultsARM32
        ;;

    * )
        echo "ERROR! Unsupported archtecture --m-cpu-arch  [ $ONIE_ARCH ]. Exiting."
        exit 1
        ;;
		

esac
ONIE_MACHINE_REVISION=${ONIE_MACHINE_REVISION:="-r0"}
# And the values that get set from the above
ONIE_MACHINE="${ONIE_MACHINE_TARGET}${ONIE_MACHINE_REVISION}"

# Virtual target hard drive to install on
HARD_DRIVE=${EMULATION_DIR}/onie-${ONIE_MACHINE_TARGET}-demo.qcow2

# Formatting takes a while, so once that is done, keep a copy
# of the empty formatted drive so that clean installs
# can be re-run without having to rebuild.
CLEAN_HARD_DRIVE=${EMULATION_DIR}/onie-${ONIE_MACHINE_TARGET}-clean.qcow2

# Set values based off of user entries
# If no kernel was found, kernel debug will not happen but ONIE install from a
# recovery .iso is possible, so note the lack of kernel and continue.
ONIE_KERNEL_VERSION=${ONIE_KERNEL_VERSION:="$( basename "$( ls -d "${BUILD_DIR}/${ONIE_MACHINE}"/kernel/linux-* 2>/dev/null | head -n 1 )" )"}
if [ "$ONIE_KERNEL_VERSION" = "" ];then
	ONIE_KERNEL_VERSION="NoKernelInBuildDir"
fi
if [ "$ONIE_ARCH" = 'x86_64' ];then
	ONIE_KERNEL=${ONIE_KERNEL:="${BUILD_DIR}/${ONIE_MACHINE}/kernel/${ONIE_KERNEL_VERSION}/arch/${ONIE_ARCH}/boot/bzImage"}
fi
if [ "$ONIE_ARCH" = 'arm64' ];then
	ONIE_KERNEL=${ONIE_KERNEL:="${BUILD_DIR}/images/${ONIE_MACHINE}.vmlinuz"}
	ONIE_DTB=${ONIE_DTB:="${BUILD_DIR}/images/${ONIE_MACHINE}.dtb"}
fi
ONIE_INITRD=${ONIE_INITRD:="${BUILD_DIR}/images/${ONIE_MACHINE}.initrd"}
ONIE_VMLINUX=${ONIE_VMLINUX:="${BUILD_DIR}/${ONIE_MACHINE}/kernel/${ONIE_KERNEL_VERSION}/vmlinux"}

ONIE_RECOVERY_ISO=${ONIE_RECOVERY_ISO:="${BUILD_DIR}/images/onie-recovery-${ONIE_ARCH}-${ONIE_MACHINE}.iso"}
ONIE_DEMO_INSTALLER=${ONIE_DEMO_INSTALLER:="${BUILD_DIR}/images/demo-installer-${ONIE_ARCH}-${ONIE_MACHINE}.bin"}

#
# Sanity checking.
#

# Was a recovery ISO required, and does it exist?
if [ "$SET_DEFAULT_ONIE_RECOVERY_ISO" = "TRUE" ];then
    # This will have been set by default, if not directly supplied.
    if [ ! -e "$ONIE_RECOVERY_ISO" ];then
        echo "ERROR! --m-secure-default found no ISO image at [ $ONIE_RECOVERY_ISO ]"
        echo " Are --machine-name and --machine-revision set correctly?"
        echo "Exiting."
        exit 1
    fi
fi

# Are qemu utilities installed?
if [ "$(command -v qemu-img)" = "" ];then
    echo "Failed to find qemu-img. Try installing qemu-utils."
    exit 1
fi
# Is qemu installed?
if [ "$(command -v qemu-system-${QEMU_ARCH})" = "" ];then
    echo "Failed to find qemu-system-${QEMU_ARCH}. Try installing qemu-system-x86 or qemu-system-aarch64. Exiting."
    exit 1
fi
# x86 uses UEFI BIOS files that can be pulled from an install on the host.
# In Debian, the ovmf package supplies these. Your environment may be different.
if [ "$(uname -m)" = "x86_64" ];then
	if [ ! -e "$UEFI_BIOS_SOURCE_VARS" ];then
		echo "Failed to find $UEFI_BIOS_SOURCE_VARS"
		echo "Try installing ovmf "
		exit 1
	fi
fi

#############################################
#
# If running just a kernel configuration
#
#############################################
if [ "$DO_RUN_ONIE_KERNEL" = "TRUE" ];then
	if [ "$ONIE_ARCH" = 'arm64' ];then
		fxnRunKernel "$ONIE_KERNEL" "" "" "$ONIE_DTB"
	else
		fxnRunKernel "$ONIE_KERNEL" "$ONIE_INITRD" "$ONIE_VMLINUX" 
	fi
    exit
fi

if [ "$DO_RUN_INSTALLER_KERNEL" = "TRUE" ];then
    fxnRunKernel "$INSTALLER_KERNEL" "$INSTALLER_INITRD"
    exit
fi

if [ "$DO_RUN_DEBIAN_KERNEL" = "TRUE" ];then
	fxnRunKernel "$DEB_KERNEL" "$INSTALLER_INITRD" "$DEB_VMLINUX"
	exit
fi

#############################################
#
# Full ONIE emulation
#
#############################################

if [ "$DO_HD_CLEAN" = "TRUE" ];then
    echo "Running a clean install:"
    if [ -e "${HARD_DRIVE}" ];then
        echo "  Deleting      $HARD_DRIVE"
        rm "$HARD_DRIVE"
    fi
    if [ -e "$CLEAN_HARD_DRIVE" ];then
        # Copying the backup is faster than formatting a new one.
        echo "   Creating empty hard drive from formatted backup $CLEAN_HARD_DRIVE."
        echo -n  "   "
        ls -lh "$CLEAN_HARD_DRIVE"
        rsync --progress  "$CLEAN_HARD_DRIVE" "$HARD_DRIVE"
    fi
fi

# If a virtual CD is being booted from, or made available
# after a hard drive boot, make sure it exists.
#
if [ "$DO_BOOT_FROM_CD" = "TRUE" ] || [ "$DO_MOUNT_CD"  = "TRUE" ];then
    if [ ! -e "$ONIE_RECOVERY_ISO" ];then
        echo "ERROR! --m-embed-onie requires an --m-onie-iso image specified."
        echo " Perhaps $( realpath "${BUILD_DIR}"/images/onie-recovery-"${ONIE_MACHINE_TARGET}"*iso )"
        exit 1
    fi
fi


# Copy and use the HD file here.
# Handy to get a clean setup if ONIE already installs
# and the NOS installer is being debugged.
if [ "$USE_QCOW2_HD_FILE" != "" ];then
    echo "Using saved qcow2 hard drive image file."
    echo "  Deleting $HARD_DRIVE"
    rm "$HARD_DRIVE"
    echo "  Replacing with: [ $USE_QCOW2_HD_FILE ]"
    rsync --progress "$USE_QCOW2_HD_FILE" "$HARD_DRIVE"
fi

if [ "$DO_RUN_KVM" = "TRUE" ];then

    # get emulation directory set up
    fxnSetupEnvironment

	# If resetting BIOS, do it after ONIE_ARCH has been set
	# to delete and restore the appropriate ARM/x86 BIOS files
	if [ "$DO_BIOS_CLEAN" != "" ];then
		# Put fresh UEFI BIOS files in
		fxnSetupUEFIBIOS $DO_BIOS_CLEAN
	fi
	
    # Running with a pre configured OVMF file?
    # Bring it in here after any UEFI cleans ran above
    # Handy to test different pre-configured BIOS settings
    # Different hardware/owner keys, for example.

    if [ "$DO_UPDATE_OVMF_VARS_FILE" = "TRUE" ];then
        echo ""
        if [ -e "${UEFI_BIOS_DIR}/OVMF_VARS.fd" ];then
            rm "${UEFI_BIOS_DIR}/OVMF_VARS.fd"
        fi
        echo "Replacing ${UEFI_BIOS_DIR}/OVMF_VARS.fd with $USE_OVMF_VARS_FILE"
        fxnEC cp "$USE_OVMF_VARS_FILE" "${UEFI_BIOS_DIR}/OVMF_VARS.fd" || exit 1
    fi


    # Run qemu with qcow2 image
    fxnRunEmulation
fi
