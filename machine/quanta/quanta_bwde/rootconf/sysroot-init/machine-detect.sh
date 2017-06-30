#!/bin/sh
. /lib/onie/functions

platform=$(/usr/bin/mb_detect -p)
if [ -n "$(echo ${platform} | /bin/grep _bwde)" ]; then
	cp -f /etc/machine.conf /etc/machine_bwde.conf
	/bin/sed "s/_bwde/_${platform}/g" /etc/machine_bwde.conf > /etc/machine.conf
	log_info_msg "Platform $(onie-sysinfo -m) detected ..."
fi
