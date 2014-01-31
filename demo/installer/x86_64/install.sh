#!/bin/sh

set -e

cd $(dirname $0)
. ./machine.conf

echo "Demo Installer: platform: $platform"

# Install demo on same block device as ONIE
blk_dev=$(blkid | grep ONIE-BOOT | awk '{print $1}' | sed -e 's/[0-9]://' | head -n 1)

[ -b "$blk_dev" ] || {
    echo "Error: Unable to determine block device of ONIE install"
    exit 1
}

# Check that no partitions on this device are currently mounted
if grep -q "$blk_dev" /proc/mounts ; then
    echo "ERROR: Partitions on target device ($blk_dev) are currently mounted."
    grep "$blk_dev" /proc/mounts
    exit 1
fi

demo_part_name="demo-$machine"

# See if demo partition already exists
demo_part=$(sgdisk -p $blk_dev | grep "$demo_part_name" | awk '{print $1}')
if [ -z "$demo_part" ] ; then

    echo "Creating new demo partition ..."
    # Find next available partition
    last_part=$(sgdisk -p $blk_dev | tail -n 1 | awk '{print $1}')
    demo_part=$(( $last_part + 1 ))

    # Create new partition
    sgdisk --new=${demo_part}::+10MB \
        --change-name=${demo_part}:$demo_part_name $blk_dev || {
        echo "Error: Unable to create partition $demo_part on $blk_dev"
        exit 1
    }

else
    echo "Using existing demo partition ..."
fi

demo_dev="${blk_dev}$demo_part"

# Create filesystem on demo partition with a label
demo_volume_label="ONIE-DEMO"
mkfs.ext2 -L $demo_volume_label $demo_dev || {
    echo "Error: Unable to create file system on $demo_dev"
    exit 1
}

# Mount demo filesystem
demo_mnt="/mnt/demo"

mkdir -p $demo_mnt || {
    echo "Error: Unable to create demo file system mount point: $demo_mnt"
    exit 1
}
mount -t ext2 -o defaults $demo_dev $demo_mnt || {
    echo "Error: Unable to mount $demo_dev on $demo_mnt"
    exit 1
}

# Copy kernel and initramfs to demo file system
cp demo.vmlinuz demo.initrd $demo_mnt

# store installation log in demo file system
onie-support $demo_mnt

umount $demo_mnt

# Add GRUB menu entry for the demo OS
#   1. Create a GRUB menu entry in a temporary file
#   2. Use onie-boot-add to add the entry to the GRUB config
#   3. Use onie-boot-default to set the default boot entry
#   4. Use onie-boot-update to generate new grub.cfg file

demo_grub_entry="Demo NOS"
tmp_entry=$(mktemp)
(cat <<EOF
DEMO_CMDLINE="\$CMDLINE_LINUX_SERIAL \$ONIE_PLATFORM_ARGS \$ONIE_DEBUG_ARGS"
menuentry '$demo_grub_entry' --class gnu-linux --class gnu --class os {
        set root='(hd0,gpt${demo_part})'
        search --no-floppy --label --set=root $demo_volume_label
        echo    'Loading ONIE Demo OS ...'
        linux   /demo.vmlinuz \$DEMO_CMDLINE
        echo    'Loading ONIE initial ramdisk ...'
        initrd  /demo.initrd
}
EOF
) > $tmp_entry

onie-boot-entry-add -v -n 30_onie_demo -c $tmp_entry || {
    echo "Error: Unable to add boot menu entry"
    exit 1
}

# Clear any ONIE boot mode
onie-boot-default -v -o none || {
    echo "Error: Unable to clear ONIE boot mode"
    exit 1
}

# Set default menu entry
onie-boot-default -v -d "$demo_grub_entry"  || {
    echo "Error: Unable to set default boot entry: $demo_grub_entry"
    exit 1
}

# Update GRUB configuration
onie-boot-update -v || {
    echo "Error: Unable to update boot configuration"
    exit 1
}
