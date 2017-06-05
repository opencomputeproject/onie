#!/bin/sh
. /lib/onie/functions

platform=$(/usr/bin/mb_detect -p)
if [ -n "$(echo ${platform} | /bin/grep _rangeley)" ]; then
	cp -f /etc/machine.conf /etc/machine_rangeley_p1330.conf
	/bin/sed "s/rangeley_p1330/${platform}/g" /etc/machine_rangeley_p1330.conf > /etc/machine.conf
	log_info_msg "Platform $(mb_detect -m) detected ..."
fi
