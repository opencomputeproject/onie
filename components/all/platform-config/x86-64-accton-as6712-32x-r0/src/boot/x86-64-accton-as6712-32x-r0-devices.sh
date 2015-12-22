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
# initialize CPLD
echo as6712_32x_cpld1 0x60 > /sys/bus/i2c/devices/i2c-0/new_device
echo as6712_32x_cpld2 0x62 > /sys/bus/i2c/devices/i2c-0/new_device
echo as6712_32x_cpld3 0x64 > /sys/bus/i2c/devices/i2c-0/new_device

# initialize QSFP port 1~32
echo as6712_32x_sfp1 0x50 > /sys/bus/i2c/devices/i2c-2/new_device
echo as6712_32x_sfp2 0x50 > /sys/bus/i2c/devices/i2c-3/new_device
echo as6712_32x_sfp3 0x50 > /sys/bus/i2c/devices/i2c-4/new_device
echo as6712_32x_sfp4 0x50 > /sys/bus/i2c/devices/i2c-5/new_device
echo as6712_32x_sfp5 0x50 > /sys/bus/i2c/devices/i2c-6/new_device
echo as6712_32x_sfp6 0x50 > /sys/bus/i2c/devices/i2c-7/new_device
echo as6712_32x_sfp7 0x50 > /sys/bus/i2c/devices/i2c-8/new_device
echo as6712_32x_sfp8 0x50 > /sys/bus/i2c/devices/i2c-9/new_device
echo as6712_32x_sfp9 0x50 > /sys/bus/i2c/devices/i2c-10/new_device
echo as6712_32x_sfp10 0x50 > /sys/bus/i2c/devices/i2c-11/new_device
echo as6712_32x_sfp11 0x50 > /sys/bus/i2c/devices/i2c-12/new_device
echo as6712_32x_sfp12 0x50 > /sys/bus/i2c/devices/i2c-13/new_device
echo as6712_32x_sfp13 0x50 > /sys/bus/i2c/devices/i2c-14/new_device
echo as6712_32x_sfp14 0x50 > /sys/bus/i2c/devices/i2c-15/new_device
echo as6712_32x_sfp15 0x50 > /sys/bus/i2c/devices/i2c-16/new_device
echo as6712_32x_sfp16 0x50 > /sys/bus/i2c/devices/i2c-17/new_device
echo as6712_32x_sfp17 0x50 > /sys/bus/i2c/devices/i2c-18/new_device
echo as6712_32x_sfp18 0x50 > /sys/bus/i2c/devices/i2c-19/new_device
echo as6712_32x_sfp19 0x50 > /sys/bus/i2c/devices/i2c-20/new_device
echo as6712_32x_sfp20 0x50 > /sys/bus/i2c/devices/i2c-21/new_device
echo as6712_32x_sfp21 0x50 > /sys/bus/i2c/devices/i2c-22/new_device
echo as6712_32x_sfp22 0x50 > /sys/bus/i2c/devices/i2c-23/new_device
echo as6712_32x_sfp23 0x50 > /sys/bus/i2c/devices/i2c-24/new_device
echo as6712_32x_sfp24 0x50 > /sys/bus/i2c/devices/i2c-25/new_device
echo as6712_32x_sfp25 0x50 > /sys/bus/i2c/devices/i2c-26/new_device
echo as6712_32x_sfp26 0x50 > /sys/bus/i2c/devices/i2c-27/new_device
echo as6712_32x_sfp27 0x50 > /sys/bus/i2c/devices/i2c-28/new_device
echo as6712_32x_sfp28 0x50 > /sys/bus/i2c/devices/i2c-29/new_device
echo as6712_32x_sfp29 0x50 > /sys/bus/i2c/devices/i2c-30/new_device
echo as6712_32x_sfp30 0x50 > /sys/bus/i2c/devices/i2c-31/new_device
echo as6712_32x_sfp31 0x50 > /sys/bus/i2c/devices/i2c-32/new_device
echo as6712_32x_sfp32 0x50 > /sys/bus/i2c/devices/i2c-33/new_device

########### initialize I2C bus 1 ###########
# initiate multiplexer (PCA9548)
echo pca9548 0x70 > /sys/bus/i2c/devices/i2c-1/new_device

# initiate PSU-1 AC Power
echo as6712_32x_psu 0x38 > /sys/bus/i2c/devices/i2c-35/new_device
echo cpr_4011_4mxx 0x3C > /sys/bus/i2c/devices/i2c-35/new_device

# initiate PSU-2 AC Power
echo as6712_32x_psu 0x3b > /sys/bus/i2c/devices/i2c-36/new_device
echo cpr_4011_4mxx 0x3F > /sys/bus/i2c/devices/i2c-36/new_device

# initiate PSU-1 DC Power
echo as6712_32x_psu 0x50 > /sys/bus/i2c/devices/i2c-35/new_device

# initiate PSU-2 DC Power
echo as6712_32x_psu 0x53 > /sys/bus/i2c/devices/i2c-36/new_device

# initiate lm75
echo lm75 0x48 > /sys/bus/i2c/devices/i2c-38/new_device
echo lm75 0x49 > /sys/bus/i2c/devices/i2c-39/new_device
echo lm75 0x4a > /sys/bus/i2c/devices/i2c-40/new_device
echo lm75 0x4b > /sys/bus/i2c/devices/i2c-41/new_device

exit 0
