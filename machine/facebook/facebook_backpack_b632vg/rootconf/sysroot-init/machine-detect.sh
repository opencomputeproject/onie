#!/bin/sh
. /lib/onie/functions
. /lib/onie/platform-discover

backpack_card_detect
cp -f /etc/machine.conf /etc/machine_facebook_backpack.conf
/bin/sed "s/facebook_backpack/facebook_backpack_${platform}/g" /etc/machine_facebook_backpack.conf > /etc/machine.conf
log_info_msg "Platform $(onie-sysinfo -m) detected ..."
