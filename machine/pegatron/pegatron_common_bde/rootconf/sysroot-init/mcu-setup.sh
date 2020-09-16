#!/bin/sh

#  Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

# Architecture specific system initializations

cmd="$1"

. /lib/onie/functions

mcu_setup()
{
    local i2c_i801_dev=$(i2cdetect -l | grep "I801" | awk '{print $1}')
    local i2c_i801_bus=$(echo "${i2c_i801_dev}" | sed -e 's/i2c-//')
    local i2c_mux_dev=$(i2cdetect -l | grep "${i2c_i801_dev}-mux" | awk '{print $1}')
    local i2c_mux_bus=$(echo "${i2c_mux_dev}" | sed -e 's/i2c-//')
    local check_mux_bus=$(i2cdetect -y ${i2c_mux_bus} | grep "18")
    
    if [ -n "${check_mux_bus}" ]; then
        i2cset -y ${i2c_mux_bus} 0x18 0x70 0x1
    else
        i2cset -y ${i2c_i801_bus} 0x18 0x70 0x1
    fi
}


case $cmd in
    start)
        mcu_setup
        ;;
    *)

esac
