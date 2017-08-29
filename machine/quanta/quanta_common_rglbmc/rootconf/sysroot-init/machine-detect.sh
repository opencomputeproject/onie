#!/bin/sh
. /lib/onie/functions

platform=$(/usr/bin/mb_detect -p)
if [ -n "$(echo ${platform} | /bin/grep _rglbmc)" ]; then
	cp -f /etc/machine.conf /etc/machine_common_rglbmc.conf
	/bin/sed "s/common_rglbmc/${platform}/g" /etc/machine_common_rglbmc.conf > /etc/machine.conf
	log_info_msg "Platform $(onie-sysinfo -m) detected ..."
fi
