#!/bin/sh

#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2017 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0

# If necessary, generate run-time ONIE configuration variables in
# /etc/machine-live.conf.

. /lib/onie/functions

import_cmdline

cmd="$1"

machine_conf=/etc/machine.conf


onie_get_boot_dev()
{
    local device=$(blkid | grep "ONIE-BOOT" | sed -e 's/:.*$//')
    [ -n "$device" ] && echo -n "$device"
}

find_sata_rule="ata"
find_mmc_rule="Multiple Reader\|MMC"
find_non_usb_rule="${find_sata_rule}\|${find_mmc_rule}"
onie_sata_device="$(lsblk.sh | grep "${find_sata_rule}" | awk '{print $1}')"
onie_mmc_device="$(lsblk.sh | grep "${find_mmc_rule}" | awk '{print $1}')"
onie_boot_device="$(onie_get_boot_dev)"
onie_boot_device="${onie_boot_device%%[0-9]}"
insatll_device=""
demo_type=""

if [ -r /lib/demo/functions ]; then
   . /lib/demo/functions
   demo_type="$(demo_type_get)"
fi

select_device_menuconfig()
{
    IFS_BAK=$IFS
    IFS=$'\n'

    local disk="$(lsblk.sh | grep -v ^NAME | grep "${find_non_usb_rule}")"
    local numline=0
    local message="Choose device for installing NOS or wait 10 seconds to choose default device"
    local device=""
    for entry in ${disk}
    do
        block_device_name=$(echo "$entry" | awk '{print $1}')
        block_device_link=$(find /sys/bus /sys/class /sys/block/ -name ${block_device_name})
        num_line=$((num_line+1))
        model=$(cat ${block_device_link}/device/model)
        tran=$(echo "$entry" | awk '{print $(NF-1)}')
        message="${message}$(cat <<EOF

$num_line) $tran: $model
EOF
)"
    done

    message="${message}
Please select device:"

    IFS=$IFS_BAK
    IFS_BAK=

    while :
    do
        read -t 10 -p "$message"
        if [ "$?" -eq 1 ]; then
            log_console_msg "Time Out!!!"
            log_console_msg "ONIE will choose default device"
            break
        fi

        if [ -z "$REPLY" ]; then
            log_console_msg "ONIE will choose default device"
            break
        fi

        if [ "$REPLY" -le "$num_line" ] && [ "$REPLY" -gt "0" ]; then
            local line="${REPLY}p;${REPLY}q"
            device="/dev/$(echo "$disk" | sed -n $line | awk '{print $1}')"
            break
        fi
    done
    
    if [ -n "$device" ]; then
        echo -n "$device"
    else
        echo -n ""
    fi
}

gen_machine_config()
{
    if [ "$onie_boot_reason" == "install" -a \
         "$demo_type" != "OS" ] ; then
         insatll_device="$(select_device_menuconfig)"
    fi
    
    if [ ! -z "${onie_sata_device}" ] ; then
        local sata_device=""
        local i=0
        for device_link in ${onie_sata_device}
        do
            if [ $i -eq 0 ] ; then
                sata_device="/dev/${device_link}"
            else
                sata_device="${sata_device} /dev/${device_link}"
            fi
            i=$((i+1))
        done
        echo "onie_sata_device=\"$sata_device\"" >> $machine_conf
    else
        echo "onie_sata_device=\"\"" >> $machine_conf
    fi

    if [ ! -z "${onie_mmc_device}" ] ; then
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
        echo "onie_mmc_device=\"$mmc_device\"" >> $machine_conf
    else
        echo "onie_mmc_device=\"\"" >> $machine_conf
    fi

    if [ ! -z "${onie_boot_device}" ] ; then
        echo "onie_boot_device=\"$onie_boot_device\"" >> $machine_conf
        if [ ! -z "${insatll_device}" ] ; then
            echo "nos_install_device=\"$insatll_device\"" >> $machine_conf
        else
            echo "nos_install_device=\"$onie_boot_device\"" >> $machine_conf
        fi
    else
        echo "onie_boot_device=\"\"" >> $machine_conf
        echo "nos_install_device=\"\"" >> $machine_conf
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
