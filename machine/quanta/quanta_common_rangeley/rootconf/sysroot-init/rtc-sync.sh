#!/bin/sh
RTC_DS1339_I2C_SLAVE=0x68

. /lib/onie/functions

/usr/bin/i2cget -y 0 $RTC_DS1339_I2C_SLAVE &> /dev/null && {
	log_info_msg "Initializing RTC DS1339 ..."
	mkdir /sysfs
	mount -t sysfs sysfs /sysfs
	/bin/echo ds1339 0x68 > /sysfs/devices/pci0000:00/0000:00:1f.3/i2c-0/new_device
	umount /sysfs
	rm -rf /sysfs
	/bin/mknod /dev/rtc1 c 254 1
	/bin/ln -sf /dev/rtc1 /dev/rtc
	/sbin/hwclock --hctosys
	log_info_msg "Initializing RTC DS1339 Done ..."
}
