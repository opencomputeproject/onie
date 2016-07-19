############################################################
# <bsn.cl fy=2013 v=none>
# 
#         Copyright 2013 Accton Technology Corporation.       
# 
# 
# 
# </bsn.cl>
############################################################

########### initialize I2C bus 0 ###########
# initiate multiplexer (PCA9548)
echo pca9548 0x76 > /sys/bus/i2c/devices/i2c-0/new_device

# initiate chassis fan
echo as7512_32x_fan 0x66 > /sys/bus/i2c/devices/i2c-2/new_device

# inititate LM75
echo lm75 0x48 > /sys/bus/i2c/devices/i2c-3/new_device
echo lm75 0x49 > /sys/bus/i2c/devices/i2c-3/new_device
echo lm75 0x4a > /sys/bus/i2c/devices/i2c-3/new_device

#initiate CPLD
echo accton_i2c_cpld 0x60 > /sys/bus/i2c/devices/i2c-0/new_device
echo accton_i2c_cpld 0x62 > /sys/bus/i2c/devices/i2c-0/new_device
echo accton_i2c_cpld 0x64 > /sys/bus/i2c/devices/i2c-0/new_device

########### initialize I2C bus 1 ###########
# initiate system eeprom
echo 24c02 0x57 > /sys/bus/i2c/devices/i2c-1/new_device

# initiate multiplexer (PCA9548)
echo pca9548 0x71 > /sys/bus/i2c/devices/i2c-1/new_device

# initiate PSU-1
echo as7512_32x_psu 0x50 > /sys/bus/i2c/devices/i2c-10/new_device
echo ym2651 0x58 > /sys/bus/i2c/devices/i2c-10/new_device

# initiate PSU-2
echo as7512_32x_psu 0x53 > /sys/bus/i2c/devices/i2c-11/new_device
echo ym2651 0x5b > /sys/bus/i2c/devices/i2c-11/new_device

#initiate max6657 thermal sensor
echo max6657 0x4c > /sys/bus/i2c/devices/i2c-15/new_device

# initiate multiplexer (PCA9548)
echo pca9548 0x72 > /sys/bus/i2c/devices/i2c-1/new_device
echo pca9548 0x73 > /sys/bus/i2c/devices/i2c-1/new_device
echo pca9548 0x74 > /sys/bus/i2c/devices/i2c-1/new_device
echo pca9548 0x75 > /sys/bus/i2c/devices/i2c-1/new_device

# initialize QSFP port 1~32
echo as7512_32x_sfp1 0x50 > /sys/bus/i2c/devices/i2c-18/new_device
echo as7512_32x_sfp2 0x50 > /sys/bus/i2c/devices/i2c-19/new_device
echo as7512_32x_sfp3 0x50 > /sys/bus/i2c/devices/i2c-20/new_device
echo as7512_32x_sfp4 0x50 > /sys/bus/i2c/devices/i2c-21/new_device
echo as7512_32x_sfp5 0x50 > /sys/bus/i2c/devices/i2c-22/new_device
echo as7512_32x_sfp6 0x50 > /sys/bus/i2c/devices/i2c-23/new_device
echo as7512_32x_sfp7 0x50 > /sys/bus/i2c/devices/i2c-24/new_device
echo as7512_32x_sfp8 0x50 > /sys/bus/i2c/devices/i2c-25/new_device
echo as7512_32x_sfp9 0x50 > /sys/bus/i2c/devices/i2c-26/new_device
echo as7512_32x_sfp10 0x50 > /sys/bus/i2c/devices/i2c-27/new_device
echo as7512_32x_sfp11 0x50 > /sys/bus/i2c/devices/i2c-28/new_device
echo as7512_32x_sfp12 0x50 > /sys/bus/i2c/devices/i2c-29/new_device
echo as7512_32x_sfp13 0x50 > /sys/bus/i2c/devices/i2c-30/new_device
echo as7512_32x_sfp14 0x50 > /sys/bus/i2c/devices/i2c-31/new_device
echo as7512_32x_sfp15 0x50 > /sys/bus/i2c/devices/i2c-32/new_device
echo as7512_32x_sfp16 0x50 > /sys/bus/i2c/devices/i2c-33/new_device
echo as7512_32x_sfp17 0x50 > /sys/bus/i2c/devices/i2c-34/new_device
echo as7512_32x_sfp18 0x50 > /sys/bus/i2c/devices/i2c-35/new_device
echo as7512_32x_sfp19 0x50 > /sys/bus/i2c/devices/i2c-36/new_device
echo as7512_32x_sfp20 0x50 > /sys/bus/i2c/devices/i2c-37/new_device
echo as7512_32x_sfp21 0x50 > /sys/bus/i2c/devices/i2c-38/new_device
echo as7512_32x_sfp22 0x50 > /sys/bus/i2c/devices/i2c-39/new_device
echo as7512_32x_sfp23 0x50 > /sys/bus/i2c/devices/i2c-40/new_device
echo as7512_32x_sfp24 0x50 > /sys/bus/i2c/devices/i2c-41/new_device
echo as7512_32x_sfp25 0x50 > /sys/bus/i2c/devices/i2c-42/new_device
echo as7512_32x_sfp26 0x50 > /sys/bus/i2c/devices/i2c-43/new_device
echo as7512_32x_sfp27 0x50 > /sys/bus/i2c/devices/i2c-44/new_device
echo as7512_32x_sfp28 0x50 > /sys/bus/i2c/devices/i2c-45/new_device
echo as7512_32x_sfp29 0x50 > /sys/bus/i2c/devices/i2c-46/new_device
echo as7512_32x_sfp30 0x50 > /sys/bus/i2c/devices/i2c-47/new_device
echo as7512_32x_sfp31 0x50 > /sys/bus/i2c/devices/i2c-48/new_device
echo as7512_32x_sfp32 0x50 > /sys/bus/i2c/devices/i2c-49/new_device

exit 0
