#!/bin/sh
RTC_DS1339_I2C_SLAVE=0x69

. /lib/onie/functions

/usr/bin/i2cget -y 0 $RTC_DS1339_I2C_SLAVE &> /dev/null && {
	log_info_msg "Initializing RTC ..."
	/sbin/hwclock --hctosys
	log_info_msg "Initializing RTC Done ..."
}
