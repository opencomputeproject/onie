#!/bin/sh
sed -i "s/onie_machine=.*/onie_machine=pegatron_fb_6256_bn_b/g" /etc/machine.conf
sed -i "s/onie_machine_rev=.*/onie_machine_rev=0/g" /etc/machine.conf
sed -i "s/onie_platform=.*/onie_platform=x86_64-pegatron_fb_6256_bn_b-r0/g" /etc/machine.conf
i2cset -y 0 0x73 0 0x05
wp=`i2cget -y 0 0x75 0x12`
new_wp="$((wp & 0xfb))"
i2cset -y 0 0x75 0x12 $new_wp
onie-syseeprom -s 0x21=FB_6256_BN_B
onie-syseeprom -s 0x27=pegatron_fb_6256_bn_b
onie-syseeprom -s 0x28=x86_64-pegatron_fb_6256_bn_b-r0
onie-syseeprom -s 0x2a=56
onie-syseeprom -s 0x2b=PEGATRON
onie-syseeprom -s 0x2c=TW
onie-syseeprom -s 0x2d=PEGATRON
onie-syseeprom -s 0x2e=0
onie-syseeprom -s 0x2f=0
if [ ! -z $1 ]; then
    MAC_ADDRESS=$(echo $1 | egrep "^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$") 
    if [ ! -z ${MAC_ADDRESS} ]; then
        onie-syseeprom -s 0x24=${MAC_ADDRESS}
    fi
fi
wp=`i2cget -y 0 0x75 0x12`
new_wp="$((wp | 0x04))"
i2cset -y 0 0x75 0x12 $new_wp
i2cset -y 0 0x73 0 0x0
