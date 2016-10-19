#!/bin/sh

PATH=/usr/bin:/usr/sbin:/bin:/sbin

onie_machine_dflt=mlnx_x86
machine_conf=/etc/machine.conf
temp_conf=/tmp/temp_conf

set_onie_machine()
{
    tmp=$(onie-syseeprom -g 0x21 | awk '{print $1}')
    machine_model=$(echo "$tmp" | awk '{print tolower($0)}')
    case "$machine_model" in
    panther)
        onie_machine=mlnx_msn2700
        ;;
    spider)
        onie_machine=mlnx_msn2410
        ;;
    neptune)
        onie_machine=mlnx_msx6710
        ;;
    scorpion)
        onie_machine=mlnx_msb7700
        ;;
    tarantula)
        onie_machine=mlnx_msx1410
        ;;
    *)
        onie_machine=mlnx_$machine_model
        ;;
    esac
}

onie_machine_old=$(cat /etc/machine.conf | grep 'onie_machine=' | cut -d "=" -f 2)
if [ "$onie_machine_old" = "$onie_machine_dflt" ]; then
    set_onie_machine
    awk '!/onie_machine=/' $machine_conf > $temp_conf
    echo "onie_machine="${onie_machine} >> $temp_conf
    onie_platform_old=$(cat ${temp_conf} | grep "onie_platform")
    onie_platform=${onie_platform_old/$onie_machine_dflt/$onie_machine}
    awk '!/onie_platform=/' $temp_conf > $machine_conf
    echo ${onie_platform} >> $machine_conf
    rm -f $temp_conf
fi

exit 0
