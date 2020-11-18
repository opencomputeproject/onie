#!/bin/sh

ONIE_VERSION=`cat /etc/os-release | grep VERSION | awk -F "\"" '{print $2}'`
# ONIE Version's Code is 0x29
CURRENT_VERSION=`onie-syseeprom -g 0x29`
if [ "$?" == "0" ]; then
	if [ "${CURRENT_VERSION}" != "${ONIE_VERSION}" ]; then
		onie-syseeprom -s 0x29=$ONIE_VERSION
	fi
else
	onie-syseeprom -s 0x29=$ONIE_VERSION
fi