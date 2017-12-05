#!/bin/sh
. /lib/onie/functions
. /lib/onie/platform-discover

bigstone_g_card_detect
if [ -n "${platform}" ] ; then
    cp -f /etc/machine.conf /etc/machine_cel_bigstone_g.conf
    /bin/sed "s/cel_bigstone_g/cel_bigstone_g_${platform}/g" /etc/machine_cel_bigstone_g.conf > /etc/machine.conf
fi
log_info_msg "Platform $(onie-sysinfo -m) detected ..."
