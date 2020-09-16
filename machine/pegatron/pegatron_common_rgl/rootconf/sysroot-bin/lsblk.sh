#!/bin/sh

#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2017 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0

# If necessary, generate run-time ONIE configuration variables in
# /etc/machine-live.conf.

machine_block_conf="/etc/machine-block.conf"
machine_conf="/etc/machine.conf"

lsblk()
{
    all_disks=""
    
    mountables_partitions=$(cat /proc/partitions | grep -v "^major" | grep -v ram | grep -v mtd |awk '{{print $4}}')
    for block_device_name in ${mountables_partitions}
    do
        block_device_link=$(find /sys/bus /sys/class /sys/block/ -name ${block_device_name})
        block_device_show=false
        for first_block_device_link in ${block_device_link}
        do
            if [ -e ${first_block_device_link}/device ] && [ ${block_device_show} = false ]; then
                block_device_show=true
                DEVICE_NAME=${block_device_name}
                DEVICE_HCTL=""
                DEVICE_USB_BUS=""
                DEVICE_TYPE="disk"
                DEVICE_VENDOR=$(cat ${first_block_device_link}/device/vendor)
                DEVICE_MODEL=$(cat ${first_block_device_link}/device/model)
                DEVICE_REV=$(cat ${first_block_device_link}/device/rev)
                DEVICE_SIZE=$(cat /proc/partitions | grep "${block_device_name}\b" |awk '{{print $3}}' )
                DEVICE_TRAN=""
                for device_tran in ata usb
                do
                    case `uname -r` in
                        4.9*)
                            target=${first_block_device_link}/device
                            ;;
                        4.14*)
                            target=${first_block_device_link}
                            ;;
                    esac
                    tmp=$(readlink ${target} | grep ${device_tran})
                    if [ ! -z $tmp ] ; then
                        if [ "${device_tran}" = "ata" ]; then
                            DEVICE_USB_BUS="sata"
                        else
                            DEVICE_USB_BUS=$(echo "${tmp}" | grep "usb" | awk -F "/" '{print $8}')
                        fi
                        DEVICE_TRAN="${device_tran}"
                        DEVICE_HCTL=$(echo "${tmp}" | awk -F "/" '{print $NF}')
                    fi
                done
    all_disks="${all_disks}$(cat <<EOF

$DEVICE_NAME  $DEVICE_HCTL    $DEVICE_TYPE $DEVICE_VENDOR $DEVICE_MODEL $DEVICE_REV $DEVICE_TRAN   $DEVICE_USB_BUS     $DEVICE_SIZE
EOF
)"
            fi
        done
    done
    
echo "NAME HCTL       TYPE VENDOR   MODEL             REV TRAN  BUS      SIZE$all_disks"
}

output()
{
    echo "$(lsblk)" > $machine_block_conf
}

args="hSo"

usage()
{
    echo "$(basename $0) [-${args}]"
    cat <<EOF
Dump ONIE system information.

COMMAND LINE OPTIONS
	The default is to dump the ONIE platform (-p).
	-h
		Help.  Print this message.
	-S
		output info about SCSI devices
	-o
		output info about SCSI devices
EOF
}

[ $# -eq 0 ] && lsblk

while getopts "$args" a ; do
    case $a in
        h)
            usage
            exit 0
            ;;
        S)
            lsblk
            ;;
        o)
            output
            ;;
        *)
            echo "Unknown argument: $a"
            usage
            exit 1
    esac
done

