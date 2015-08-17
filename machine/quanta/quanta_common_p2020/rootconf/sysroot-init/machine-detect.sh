#!/bin/sh
platform=$(/bin/sed 's/quanta,//g' /proc/device-tree/compatible)
if [ -n "$(echo ${platform} | /bin/grep _p2020)" ]; then
	cp -f /etc/machine.conf /etc/machine_common_p2020.conf
	/bin/sed "s/common_p2020/${platform}/g" /etc/machine_common_p2020.conf > /etc/machine.conf
fi

