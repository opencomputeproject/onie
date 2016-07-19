############################################################
# <bsn.cl fy=2013 v=none>
#
#         Copyright 2013 Accton Technology Corporation.
#
#
#
# </bsn.cl>
############################################################

#
# The IDPROM device is initialized last as part of this script.
#
# Assume that if the IDPROM device already exists then we
# have already executed properly.
#
if [ -f /sys/devices/pci0000:00/0000:00:13.0/i2c-1/1-0057/eeprom ]; then
    exit 0
fi


########### initialize I2C bus 0 ###########
# initialize CPLD
echo accton_i2c_cpld 0x60 > /sys/bus/i2c/devices/i2c-0/new_device

# initiate multiplexer (PCA9548)
echo pca9548 0x71 > /sys/bus/i2c/devices/i2c-0/new_device

# initialize SFP
echo as5812_54t_qsfp49 0x50 > /sys/bus/i2c/devices/i2c-4/new_device
echo as5812_54t_qsfp50 0x50 > /sys/bus/i2c/devices/i2c-6/new_device
echo as5812_54t_qsfp51 0x50 > /sys/bus/i2c/devices/i2c-3/new_device
echo as5812_54t_qsfp52 0x50 > /sys/bus/i2c/devices/i2c-5/new_device
echo as5812_54t_qsfp53 0x50 > /sys/bus/i2c/devices/i2c-7/new_device
echo as5812_54t_qsfp54 0x50 > /sys/bus/i2c/devices/i2c-2/new_device

########### initialize I2C bus 1 ###########
# initiate multiplexer (PCA9548)
echo pca9548 0x70 > /sys/bus/i2c/devices/i2c-1/new_device

# initiate PSU-1
echo as5812_54t_psu 0x38 > /sys/bus/i2c/devices/i2c-11/new_device
echo cpr_4011_4mxx 0x3c > /sys/bus/i2c/devices/i2c-11/new_device

# initiate PSU-2
echo as5812_54t_psu 0x3b > /sys/bus/i2c/devices/i2c-12/new_device
echo cpr_4011_4mxx 0x3f > /sys/bus/i2c/devices/i2c-12/new_device

# initiate lm75
echo lm75 0x48 > /sys/bus/i2c/devices/i2c-15/new_device
echo lm75 0x49 > /sys/bus/i2c/devices/i2c-16/new_device
echo lm75 0x4a > /sys/bus/i2c/devices/i2c-17/new_device

# IDPROM
echo 24c02 0x57 > /sys/devices/pci0000:00/0000:00:13.0/i2c-1/new_device

exit 0

