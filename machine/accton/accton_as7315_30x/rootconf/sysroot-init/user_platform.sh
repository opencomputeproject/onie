#!/bin/sh

. /lib/onie/onie-blkdev-common

partprobe
boot_dev="$(onie_get_boot_disk)"
sync ; sync
if [ -n "$boot_dev" ] ; then
    for p in $(seq 8) ; do
        umount ${boot_dev}$p > /dev/null 2>&1
    done
    sleep 2
fi

i2cset -f -y 1 0x76 0x0 0x20
i2cset -f -y 1 0x64 0x2 0xCC
sleep 2
