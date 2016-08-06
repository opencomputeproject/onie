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
echo as5812_54x_cpld1 0x60 > /sys/bus/i2c/devices/i2c-0/new_device
echo as5812_54x_cpld2 0x61 > /sys/bus/i2c/devices/i2c-0/new_device
echo as5812_54x_cpld3 0x62 > /sys/bus/i2c/devices/i2c-0/new_device

# initialize SFP
echo as5812_54x_sfp1 0x50 > /sys/bus/i2c/devices/i2c-2/new_device
echo as5812_54x_sfp2 0x50 > /sys/bus/i2c/devices/i2c-3/new_device
echo as5812_54x_sfp3 0x50 > /sys/bus/i2c/devices/i2c-4/new_device
echo as5812_54x_sfp4 0x50 > /sys/bus/i2c/devices/i2c-5/new_device
echo as5812_54x_sfp5 0x50 > /sys/bus/i2c/devices/i2c-6/new_device
echo as5812_54x_sfp6 0x50 > /sys/bus/i2c/devices/i2c-7/new_device
echo as5812_54x_sfp7 0x50 > /sys/bus/i2c/devices/i2c-8/new_device
echo as5812_54x_sfp8 0x50 > /sys/bus/i2c/devices/i2c-9/new_device
echo as5812_54x_sfp9 0x50 > /sys/bus/i2c/devices/i2c-10/new_device
echo as5812_54x_sfp10 0x50 > /sys/bus/i2c/devices/i2c-11/new_device
echo as5812_54x_sfp11 0x50 > /sys/bus/i2c/devices/i2c-12/new_device
echo as5812_54x_sfp12 0x50 > /sys/bus/i2c/devices/i2c-13/new_device
echo as5812_54x_sfp13 0x50 > /sys/bus/i2c/devices/i2c-14/new_device
echo as5812_54x_sfp14 0x50 > /sys/bus/i2c/devices/i2c-15/new_device
echo as5812_54x_sfp15 0x50 > /sys/bus/i2c/devices/i2c-16/new_device
echo as5812_54x_sfp16 0x50 > /sys/bus/i2c/devices/i2c-17/new_device
echo as5812_54x_sfp17 0x50 > /sys/bus/i2c/devices/i2c-18/new_device
echo as5812_54x_sfp18 0x50 > /sys/bus/i2c/devices/i2c-19/new_device
echo as5812_54x_sfp19 0x50 > /sys/bus/i2c/devices/i2c-20/new_device
echo as5812_54x_sfp20 0x50 > /sys/bus/i2c/devices/i2c-21/new_device
echo as5812_54x_sfp21 0x50 > /sys/bus/i2c/devices/i2c-22/new_device
echo as5812_54x_sfp22 0x50 > /sys/bus/i2c/devices/i2c-23/new_device
echo as5812_54x_sfp23 0x50 > /sys/bus/i2c/devices/i2c-24/new_device
echo as5812_54x_sfp24 0x50 > /sys/bus/i2c/devices/i2c-25/new_device

echo as5812_54x_sfp25 0x50 > /sys/bus/i2c/devices/i2c-26/new_device
echo as5812_54x_sfp26 0x50 > /sys/bus/i2c/devices/i2c-27/new_device
echo as5812_54x_sfp27 0x50 > /sys/bus/i2c/devices/i2c-28/new_device
echo as5812_54x_sfp28 0x50 > /sys/bus/i2c/devices/i2c-29/new_device
echo as5812_54x_sfp29 0x50 > /sys/bus/i2c/devices/i2c-30/new_device
echo as5812_54x_sfp30 0x50 > /sys/bus/i2c/devices/i2c-31/new_device
echo as5812_54x_sfp31 0x50 > /sys/bus/i2c/devices/i2c-32/new_device
echo as5812_54x_sfp32 0x50 > /sys/bus/i2c/devices/i2c-33/new_device
echo as5812_54x_sfp33 0x50 > /sys/bus/i2c/devices/i2c-34/new_device
echo as5812_54x_sfp34 0x50 > /sys/bus/i2c/devices/i2c-35/new_device
echo as5812_54x_sfp35 0x50 > /sys/bus/i2c/devices/i2c-36/new_device
echo as5812_54x_sfp36 0x50 > /sys/bus/i2c/devices/i2c-37/new_device
echo as5812_54x_sfp37 0x50 > /sys/bus/i2c/devices/i2c-38/new_device
echo as5812_54x_sfp38 0x50 > /sys/bus/i2c/devices/i2c-39/new_device
echo as5812_54x_sfp39 0x50 > /sys/bus/i2c/devices/i2c-40/new_device
echo as5812_54x_sfp40 0x50 > /sys/bus/i2c/devices/i2c-41/new_device
echo as5812_54x_sfp41 0x50 > /sys/bus/i2c/devices/i2c-42/new_device
echo as5812_54x_sfp42 0x50 > /sys/bus/i2c/devices/i2c-43/new_device
echo as5812_54x_sfp43 0x50 > /sys/bus/i2c/devices/i2c-44/new_device
echo as5812_54x_sfp44 0x50 > /sys/bus/i2c/devices/i2c-45/new_device
echo as5812_54x_sfp45 0x50 > /sys/bus/i2c/devices/i2c-46/new_device
echo as5812_54x_sfp46 0x50 > /sys/bus/i2c/devices/i2c-47/new_device
echo as5812_54x_sfp47 0x50 > /sys/bus/i2c/devices/i2c-48/new_device
echo as5812_54x_sfp48 0x50 > /sys/bus/i2c/devices/i2c-49/new_device
echo as5812_54x_sfp49 0x50 > /sys/bus/i2c/devices/i2c-50/new_device
echo as5812_54x_sfp52 0x50 > /sys/bus/i2c/devices/i2c-51/new_device
echo as5812_54x_sfp50 0x50 > /sys/bus/i2c/devices/i2c-52/new_device
echo as5812_54x_sfp53 0x50 > /sys/bus/i2c/devices/i2c-53/new_device
echo as5812_54x_sfp51 0x50 > /sys/bus/i2c/devices/i2c-54/new_device
echo as5812_54x_sfp54 0x50 > /sys/bus/i2c/devices/i2c-55/new_device


########### initialize I2C bus 1 ###########
# initiate multiplexer (PCA9548)
echo pca9548 0x70 > /sys/bus/i2c/devices/i2c-1/new_device

# initiate PSU-1
echo as5812_54x_psu 0x38 > /sys/bus/i2c/devices/i2c-57/new_device
echo cpr_4011_4mxx 0x3c > /sys/bus/i2c/devices/i2c-57/new_device

# initiate PSU-2
echo as5812_54x_psu 0x3b > /sys/bus/i2c/devices/i2c-58/new_device
echo cpr_4011_4mxx 0x3f > /sys/bus/i2c/devices/i2c-58/new_device

# initiate lm75
echo lm75 0x48 > /sys/bus/i2c/devices/i2c-61/new_device
echo lm75 0x49 > /sys/bus/i2c/devices/i2c-62/new_device
echo lm75 0x4a > /sys/bus/i2c/devices/i2c-63/new_device

# IDPROM
echo 24c02 0x57 > /sys/devices/pci0000:00/0000:00:13.0/i2c-1/new_device

exit 0

