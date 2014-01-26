#!/bin/sh

this_script=$(basename $(realpath $0))
script_dir=$(dirname $(realpath $0))

onie_dir="/mnt/onie"
mkdir -p $onie_dir || exit 1
mount -t tmpfs -o "defaults,noatime,size=100M" onie-tmpfs /mnt/onie || exit 1

cd $onie_dir
# test that needed utilities are present in host OS
for u in xz cpio ; do 
    which $u > /dev/null 2>&1 || {
        echo "ERROR: missing utility '$u', needed to mount ONIE tools"
        exit 1
    }
done
(xz -d -c $script_dir/onie.initrd | cpio -id) || {
    echo "ERROR: problem extracting ONIE initrd for ONIE tools."
    exit 1
}

echo "ONIE tools available in $onie_dir/bin"
echo "Type 'umount $onie_dir' when finished"
