#!/bin/sh

#  Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

# Architecture specific system initializations

. /lib/onie/functions

import_cmdline

cmd="$1"

machine_conf=/etc/machine.conf

onie_get_boot_dev()
{
    local device=$(blkid | grep "ONIE-BOOT" | sed -e 's/:.*$//')
    [ -n "$device" ] && echo -n "$device"
}

onie_get_mmc_dev()
{
    local find_mmc_rule="7f0a0000.usb"
    local mmc_device_list=$(lsblk.sh | grep -v ^NAME | grep -E "${find_mmc_rule}")
    local device=$(echo "${mmc_device_list}" | awk '{print $1}')
    while [ -z "$device" ] ; do
        mmc_device_list=$(lsblk.sh | grep -v ^NAME | grep -E "${find_mmc_rule}")
        device=$(echo "${mmc_device_list}" | awk '{print $1}')
    done

    [ -n "$device" ] && echo -n "$device"
}

onie_mmc_device="$(onie_get_mmc_dev)"
onie_boot_device="$(onie_get_boot_dev)"
onie_boot_device="${onie_boot_device%%[0-9]}"

gen_machine_config()
{
    local mmc_device=""
    local i=0
    for device_link in ${onie_mmc_device}
    do
        if [ $i -eq 0 ] ; then
            mmc_device="/dev/${device_link}"
        else
            mmc_device="${mmc_device} /dev/${device_link}"
        fi
        i=$((i+1))
    done
    echo "onie_mmc_device=\"${mmc_device}\"" >> $machine_conf

    if [ ! -z "${onie_boot_device}" ] ; then
        echo "onie_boot_device=\"$onie_boot_device\"" >> $machine_conf
        echo "nos_install_device=\"$onie_boot_device\"" >> $machine_conf
    else
        echo "onie_boot_device=\"\"" >> $machine_conf
    fi
}

remove_dev_info()
{
    sed -i '/onie_sata_device=/d' $machine_conf
    sed -i '/onie_mmc_device=/d' $machine_conf
    sed -i '/onie_boot_device=/d' $machine_conf
    sed -i '/nos_install_device=/d' $machine_conf
}

case $cmd in
    start|reset)
        remove_dev_info
        gen_machine_config
        ;;
    *)

esac
