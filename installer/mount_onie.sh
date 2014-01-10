#!/bin/sh

this_script=$(basename $(realpath $0))
script_dir=$(dirname $(realpath $0))

onie_dir="/mnt/onie"
mkdir -p $onie_dir || exit 1
mount -t tmpfs -o "defaults,noatime,size=100M" onie-tmpfs /mnt/onie || exit 1

cd $onie_dir
xz -d -c $script_dir/onie.initrd | cpio -id

echo "ONIE tools available in $onie_dir/bin"
echo "Type 'umount $onie_dir' when finished"
