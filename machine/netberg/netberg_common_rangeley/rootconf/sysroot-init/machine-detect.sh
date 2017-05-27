#!/bin/sh
. /lib/onie/functions

platform=$(/usr/bin/mb_detect -p)
if [ -n "$(echo ${platform} | /bin/grep _rangeley)" ]; then
	cp -f /etc/machine.conf /etc/machine_common_rangeley.conf
	/bin/sed "s/common_rangeley/${platform}/g" /etc/machine_common_rangeley.conf > /etc/machine.conf
	log_info_msg "Platform $(mb_detect -m) detected ..."
fi
