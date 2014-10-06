#!/bin/sh
############################################################
# <bsn.cl fy=2013 v=onl>
# 
#        Copyright 2013, 2014 Big Switch Networks, Inc.       
# 
# Licensed under the Eclipse Public License, Version 1.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
# 
#        http://www.eclipse.org/legal/epl-v10.html
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the
# License.
# 
# </bsn.cl>
############################################################
#
# Open Network Linux Installation Script. 
#
# The purpose of this script is to automatically install ONL
# on the target system. 
#
# This script is ONIE-compatible. 
#
# This script is can be run under a manual boot of the 
# Open Network Loader as the execution environment for 
# platforms that do not support ONIE. 
# 
############################################################


############################################################
#
# Installation Utility Functions
# 
############################################################


############################################################
#
# installer_create_device_file <blockdev> <partno>
#     <blockdev> The block device name
#     <partno>   The partition number. 
# 
#    Set the global variable 'installer_df' with the name of 
#    the created device file. 
#
# We can't always rely on the existance of a partition's
# device file after the device has been formatted. 
#
# This function creates the appropriate device file
# for a given block partition to avoid this problem.
#
#

installer_create_device_file() {
    local blockdev=$1
    local partno=$2
    
    # Determine the device major number for the given block device:
    local major=`ls -l /dev/${blockdev} | tr "," " " | awk '{print $5}'`

    # Create a new device file matching the given partition 
    installer_df=$(mktemp)
    rm ${installer_df}
    mknod "${installer_df}" b "${major}" "${partno}"
}

############################################################
#
# installer_partition_cp <blockdev> <partno> <src> <dst>
#
#    <blockdev> The block device name
#    <partno>   The partition number
#    <src>      The local source filename
#    <dst>      The destination filename
#
# Copy the source file to the given partition. 
# The partition must be formatted/mountable. 
#
############################################################

installer_partition_cp() { 
    local blockdev=$1
    local partno=$2
    local src=$3
    local dst=$4

    installer_create_device_file ${blockdev} ${partno}
    mkdir -p "${installer_df}.mount"
    mount "${installer_df}" "${installer_df}.mount"
    cp "${src}" "${installer_df}.mount/${dst}"
    umount "${installer_df}.mount"
    rm "${installer_df}"
    rmdir "${installer_df}.mount"
}


############################################################
#
# installer_partition_dd <blockdev> <partno> <src>
#
#    <blockdev> The block device name
#    <partno>   The partition number.
#    <src>      The source file. 
#
# 'dd' the contents of the src file directly to the given partition.
#
############################################################

installer_partition_dd() {
    local blockdev=$1
    local partno=$2
    local src=$3

    # installer_partition_dd <blockdev> <partno> <src>
    installer_create_device_file ${blockdev} ${partno}
    dd if=${src} of="${installer_df}" bs=1024
    rm "${installer_df}"
}

############################################################
#
# installer_partition_format <blockdev> <partno> <mkfs>
#
#    <blockdev> The block device name.
#    <partno>   The partition number.
#    <mkfs>     The formatting tool.
# 
############################################################

installer_partition_format() {
    local blockdev=$1
    local partno=$2
    local mkfs=$3
    local partition="$1$2"

    installer_say "Format ${partition}..."
    installer_create_device_file ${blockdev} ${partno}
    "${mkfs}" "${installer_df}"
    installer_say "Format ${partition} complete."
    rm "${installer_df}"
}

############################################################
#
# installer_umount_blockdev <blockdev>
#
#    <blockdev> The block device name.
#
# Unmount all partitions of the given blockdevice. 
#
# Required to avoid errors when repartitioning block
# devices that are currently mounted. 
#
############################################################

installer_umount_blockdev() { 
    local blockdev=$1
    grep $blockdev /proc/mounts
    if [ 0 = $? ]; then
        umount `awk "/${blockdev}/ "'{print $2}' /proc/mounts` || true
    else
        echo $1 not mounted, skiping umount
        exit 1
    fi
}


############################################################
#
# installer_blockdev_format <blockdev> <p1size> <p2size> <p3size>
# 
#    <blockdev> The block device name.
#    <p1size>   The size of the first partition.
#    <p2size>   The size of the second partition.
#    <p3size>   [Optional] The size of the third partition. 
#               If p3size is unset, the remainder of the device will be used
#               for the third partition.
#
############################################################

installer_blockdev_format() {
    local blockdev=$1
    local partition1size=$2
    local partition2size=$3
    local partition3size=$4

    installer_umount_blockdev ${blockdev}
    installer_say "Formatting ${blockdev} as ${partition1size}:${partition2size}:${partition3size}."
    echo -e "o\nn\np\n1\n\n+${partition1size}\nn\np\n2\n\n+${partition2size}\nn\np\n3\n\n${partition3size}\np\nw\n" | fdisk /dev/${blockdev}
    installer_partition_format ${blockdev} 1 mkdosfs
    installer_partition_format ${blockdev} 2 mkdosfs
    installer_partition_format ${blockdev} 3 mkdosfs
}

############################################################
#
# installer_platform_loader <blockdev> <partno>
#
#    <blockdev> The block device name.
#    <partno>   The partition number.
#
# Install the platform loader to the given partition.
#
#  The default is to copy the loader to the partition's filesystem.
#  If 'platform_loader_raw' is specified by the platform, the
#  loader will be written directly to the partition instead. 
#
############################################################
installer_platform_loader() {
    local blockdev=$1
    local partno=$2

    if [ "${platform_loader}" ]; then
        # Platform specific override
        local loader="${platform_loader}"
    else
        # Default platform loader
        local loader="${installer_dir}/onl.${installer_platform}.loader"
    fi
    
    if [ "${platform_loader_dst_name}" ]; then
        local loaderdst="${platform_loader_dst_name}"
    else
        local loaderdst="onl-loader"
    fi
        

    if [ -f "${loader}" ]; then
        installer_say "Installing the Open Network Loader..."
        
        if [ "${platform_loader_raw}" ]; then 
            installer_partition_dd ${blockdev} ${partno} ${loader}
        else
            installer_partition_cp ${blockdev} ${partno} ${loader} ${loaderdst}
        fi
    else
        installer_say "The platform loader file is missing. This is unexpected - ${loader}"
        exit 1
    fi
}

############################################################
#
# installer_platform_bootconfig <blockdev> <partno>
#
#    <blockdev> The block device name.
#    <partno>   The partition number.
#
# Generate and write the platform boot-config file
# into the given partition. 
#
############################################################

installer_platform_bootconfig() {
    local blockdev=$1
    local partno=$2

    # Is there a platform bootconfig file?
    if [ -f "${installer_platform_dir}/boot-config" ]; then
        bootconfig=$(cat ${installer_platform_dir}/boot-config)
    # Is there a platform bootconfig string?
    elif [ "${platform_bootconfig}" ]; then
        bootconfig="${platform_bootconfig}"
    # Use the default. 
    else
        if [ "${installer_mode_standalone}" ]; then
            bootconfig="SWI=flash2:onl-${installer_arch}.swi\nNETDEV=ma1\n"
        else
            bootconfig='SWI=flash2:.ztn-onl.swi\nNETDEV=ma1\nNETAUTO=dhcp\n'
        fi
    fi
    # Write the boot-config file to the given partition. 
    installer_say "Writing boot-config."
    echo -e "${bootconfig}" > /tmp/boot-config
    installer_partition_cp ${blockdev} ${partno} /tmp/boot-config boot-config
    rm /tmp/boot-config
}

############################################################
#
# installer_platform_swi <blockdev> <partno>
#
#    <blockdev> The block device name.
#    <partno>   The partition number.
#
# Install the SWI to the given partition.
#
############################################################

installer_platform_swi() { 
    local blockdev=$1
    local partno=$2

    # Is there a platform-specific SWI?
    if [ -f "${installer_platform_dir}/${installer_platform}.swi" ]; then
        local swi="${installer_platform_dir}/${installer_platform}.swi"
    # Is there a default SWI?
    elif [ -f "${installer_dir}/onl-${installer_arch}.swi" ]; then
        local swi="${installer_dir}/onl-${installer_arch}.swi"
    fi
    
    if [ -f "${swi}" ]; then 
        installer_say "Installing Open Network Software Image..."
        if [ "${platform_swi_install_name}" ]; then 
            local swidst="${platform_swi_install_name}"
        else
            if [ "${installer_mode_standalone}" ]; then
                local swidst="onl-${installer_arch}.swi"
            else
                local swidst=".ztn-onl.swi"
            fi
        fi
        installer_partition_cp ${blockdev} ${partno} ${swi} ${swidst}
    else
        installer_say "No Open Network Software Image available for installation. Post-install ZTN installation will be required."
    fi
}

############################################################
#
# installer_standard_blockdev_install <blockdev> <p1size> <p2size> <p3size>
#
#    <blockdev> The block device name.
#    <p1size>   The size of the loader partition.
#    <p2size>   The size of the /mnt/flash partition.
#    <p3size>   The size of the /mnt/flash2 partition. 
#
# Performs a standard installation for the platform. 
# Most platform installers will just call this function with the appropriate arguments.
#
############################################################
installer_standard_blockdev_install () {
    local blockdev=$1
    local p1size=$2
    local p2size=$3
    local p3size=$4

    # Standard 3-partition format for loader, /mnt/flash, and /mnt/flash2
    installer_blockdev_format "${blockdev}" "${p1size}" "${p2size}" "${p3size}"
  
    # Copy the platform loader to the first partition. 
    installer_platform_loader "${blockdev}" 1 
    
    # Set the boot-config file
    installer_platform_bootconfig "${blockdev}" 2
    
    # Copy the packaged SWI to the third partition.
    installer_platform_swi "${blockdev}" 3
    
    sync
    installer_umount_blockdev "${blockdev}"
}


############################################################
#
# Installation Main
#
# Installation is performed as follows:
#
# 1. Detect whether we are running under ONIE or the 
#    Open Network Loader and perform the appropriate setup. 
# 
# 2. Unpack the installer files. 
#
# 3. Source the installer scriptlet for the current platform. 
# 4. Run the installer function from the platform scriptlet. 
#
# The platform scriptlet determines the entire installation
# sequence. 
# 
# Most platforms will just call the installation
# utilities in this script with the approprate platform settings. 
#
############################################################
set -e
cd $(dirname $0)

# Check installer debug option from the uboot environment
fw_printenv onl_installer_debug &> /dev/null && installer_debug=1
# Check installer debug option from the uboot environment from ONIE
fw_printenv onie_verbose &> /dev/null && installer_debug=1

if [ "$installer_debug" ]; then
    echo "Debug mode"
    set -x
fi

# if you comment this line out:
installer_mode_standalone=1
#
# the default automatic installer can install Open Network Linux in ZTN mode. 
# If you want to install in standalone mode from the console when ZTN is the default, 
# do the following at the uboot prompt before installing:
# -> setenv onl_installer_standalone 1
# -> saveenv
#




fw_printenv onl_installer_standalone &> /dev/null && installer_mode_standalone=1

#
# Remount tmpfs larger if possible. 
# We will be doing all of our work out of /tmp
#
mount -o remount,size=512M /tmp || true

# Pickup ONIE defines for this machine. 
[ -r /etc/machine.conf ] && . /etc/machine.conf


if [ "${onie_platform}" ]; then
    # Running under ONIE, most likely in the background in installer mode. 
    # Our messages have to be sent to the console directly, not to stdout. 
    installer_say() { 
        echo "$@" > /dev/console
    }
    # Installation failure message. 
    trap 'installer_say "Install failed.; cat /var/log/onie.log > /dev/console; installer_say "Install failed. See log messages above for details"; sleep 3; reboot' EXIT

    if [ -z "${installer_platform}" ]; then 
        # Our platform identifiers are equal to the ONIE platform identifiers without underscores:
        installer_platform=`echo ${onie_platform} | tr "_" "-"`
        installer_arch=${onie_arch}
    fi
    installer_say "Open Network Installer running under ONIE."
else
    #
    # Assume we are running in an interactive environment
    #
    installer_say() { 
        echo 
        echo "* $@"
        echo
    }
    trap 'installer_say "Install failed."; exit 1' EXIT
    if [ -z "${installer_platform}" ]; then
        if [ -f "/etc/onl_platform" ]; then
            installer_platform=$(cat /etc/onl_platform)
        else
            installer_say "The installation platform cannot be determined. It does not appear that we are running under ONIE or the Open Network Loader. If you know what you are doing you can re-run this installer with an explicit 'installer_platform=<platform>' setting, though this is unlikely to be the correct procedure at this point."
            exit 1
        fi
    fi
    # fixme
    installer_arch=powerpc
fi

# Replaced during build packaging with the current version. 
onl_version="@ONLVERSION@"

installer_say "Installer Version: ${onl_version}"
installer_say "Detected platform: ${installer_platform}"
if [ "${installer_mode_standalone}" ]; then
    installer_say "Installing in standalone mode."
else
    installer_say "Installing in ZTN mode."
fi

# Unpack our distribution
installer_say "Unpacking Open Network Linux installer files..."
installer_dir=/tmp/.installer
rm -rf "${installer_dir}"
mkdir "${installer_dir}"
sed -e '1,/^PAYLOAD_FOLLOWS$/d' "$0" | gzip -dc | ( cd "${installer_dir}" && cpio -imdv ) || exit 1


# Developer debugging
if [ "${installer_unpack_only}" ]; then
    installer_say "Unpack only requested."
    exit 1
fi



# Look for the platform installer directory. 
installer_platform_dir="${installer_dir}/lib/platform-config/${installer_platform}"
if [ -d "${installer_platform_dir}" ]; then 
    # Source the installer scriptlet
    . "${installer_platform_dir}/install/${installer_platform}.sh"
else
    installer_say "This installer does not support the ${installer_platform} platform."
    installer_say "Available platforms are:"
    list=`ls ${installer_dir}/lib/platform-config`
    installer_say "${list}"
    installer_say "Installation cannot continue."
    exit 1
fi

# Generate the MD5 signature for ourselves for future reference. 
installer_md5=$(md5sum "$0" | awk '{print $1}')
# Cache our install URL if available
if [ -f "$0.url" ]; then
    installer_url=$(cat "$0.url")
fi

# These variables are exported by the platform scriptlet
installer_say "Platform installer version: ${platform_installer_version:-unknown}"

# The platform script must provide this function. This performs the actual install for the platform. 
platform_installer

# The platform script must provide the platform_bootcmd after completing the install. 
if [ "${onie_platform}" ]; then
    installer_say "Setting ONIE nos_bootcmd to boot Open Network Linux"
    envf=/tmp/.env
    cp /dev/null "${envf}"
    echo "nos_bootcmd ${platform_bootcmd}" >> "${envf}"
    echo "onl_installer_md5 ${installer_md5}" >> "${envf}"
    echo "onl_installer_version ${onl_version}" >> "${envf}"
    if [ "$installer_url" ]; then
        echo "onl_installer_url ${installer_url}" >> "${envf}"
    else
        echo "onl_installer_url" >> "${envf}"
    fi
    fw_setenv -f -s "${envf}"
    trap - EXIT
    installer_say "Install finished.  Rebooting to Open Network Linux."
    sleep 3
    reboot
else
    trap - EXIT
    installer_say "Install finished."
    echo "To configure U-Boot to boot Open Network Linux automatically, reboot the switch,"
    echo "enter the U-Boot shell, and run these 2 commands:"
    echo "=> setenv bootcmd '${platform_bootcmd}'"
    echo "=> saveenv"
fi

exit

# Do not add any additional whitespace after this point.
PAYLOAD_FOLLOWS
