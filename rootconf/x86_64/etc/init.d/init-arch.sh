#!/bin/sh

# x86_64 boot time initializations

. /scripts/functions

. /bin/onie-grub-common

onie_find_partitions || {
    log_failure_msg "Unable to locate ONIE partitions"
    exit 1
}

mkdir -p $onie_boot_mnt
mount -o defaults,ro $onie_boot_dev $onie_boot_mnt || {
    echo "ERROR: Problems mounting $onie_boot_dev on $onie_boot_mnt"
    exit 1
}

mkdir -p $onie_config_mnt
mount -o defaults $onie_config_dev $onie_config_mnt || {
    echo "ERROR: Problems mounting $onie_config_dev on $onie_config_mnt"
    exit 1
}
