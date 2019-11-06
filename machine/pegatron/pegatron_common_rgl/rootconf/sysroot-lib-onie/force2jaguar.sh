#!/bin/sh
sed -i "s/onie_machine=.*/onie_machine=pegatron_fb_6256_rn_b/g" /etc/machine.conf
sed -i "s/onie_machine_rev=.*/onie_machine_rev=0/g" /etc/machine.conf
sed -i "s/onie_platform=.*/onie_platform=x86_64-pegatron_fb_6256_rn_b-r0/g" /etc/machine.conf
onie-syseeprom -f -s 0x21=FB_6256_RN_B
onie-syseeprom -f -s 0x27=pegatron_fb_6256_rn_b
onie-syseeprom -f -s 0x28=x86_64-pegatron_fb_6256_rn_b-r0
onie-syseeprom -f -s 0x2b=PEGATRON
onie-syseeprom -f -s 0x2c=TW
onie-syseeprom -f -s 0x2d=PEGATRON
onie-syseeprom -f -s 0x2e=0
onie-syseeprom -f -s 0x2f=0
if [ ! -z $1 ]; then
    MAC_ADDRESS=$(echo $1 | egrep "^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$") 
    if [ ! -z ${MAC_ADDRESS} ]; then
        onie-syseeprom -f -s 0x24=${MAC_ADDRESS}
    fi
fi
