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

demo_volume_label="ONIE-DEMO"

# determine ONIE partition type
onie_partition_type=$(onie-sysinfo -t)
# demo partition size in MB
demo_part_size=128
if [ "$onie_partition_type" = "gpt" ] ; then
    create_demo_partition="create_demo_gpt_partition"
    grub_part_type="gpt"
elif [ "$onie_partition_type" = "msdos" ] ; then
    create_demo_partition="create_demo_msdos_partition"
    grub_part_type="msdos"
else
    echo "ERROR: Unsupported partition type: $onie_partition_type"
    exit 1
fi

# Creates a new partition for the DEMO OS.
# 
# arg $1 -- base block device
#
# Returns the created partition number in $demo_part
demo_part=
create_demo_gpt_partition()
{
    blk_dev="$1"

    demo_gpt_part_name="demo-$machine"
    
    # See if demo partition already exists
    demo_part=$(sgdisk -p $blk_dev | grep "$demo_gpt_part_name" | awk '{print $1}')
    if [ -n "$demo_part" ] ; then
        # delete existing partition
        sgdisk -d $demo_part $blk_dev || {
            echo "Error: Unable to delete partition $demo_part on $blk_dev"
            exit 1
        }
        partprobe
    fi
    # Find next available partition
    last_part=$(sgdisk -p $blk_dev | tail -n 1 | awk '{print $1}')
    demo_part=$(( $last_part + 1 ))

    # Create new partition
    echo "Creating new demo partition ${blk_dev}$demo_part ..."
    sgdisk --new=${demo_part}::+${demo_part_size}MB \
        --change-name=${demo_part}:$demo_gpt_part_name $blk_dev || {
        echo "Error: Unable to create partition $demo_part on $blk_dev"
        exit 1
    }
    partprobe
}

create_demo_msdos_partition()
{
    blk_dev="$1"

    # See if demo partition already exists -- look for the filesystem
    # label.
    part_info="$(blkid | grep $demo_volume_label | awk -F: '{print $1}')"
    if [ -n "$part_info" ] ; then
        # delete existing partition
        demo_part="$(echo -n $part_info | sed -e s#${blk_dev}##)"
        parted -s $blk_dev rm $demo_part || {
            echo "Error: Unable to delete partition $demo_part on $blk_dev"
            exit 1
        }
        partprobe
    fi

    # Find next available partition
    last_part_info="$(parted -s -m $blk_dev unit s print | tail -n 1)"
    last_part_num="$(echo -n $last_part_info | awk -F: '{print $1}')"
    last_part_end="$(echo -n $last_part_info | awk -F: '{print $3}')"
    # Remove trailing 's'
    last_part_end=${last_part_end%s}
    demo_part=$(( $last_part_num + 1 ))
    demo_part_start=$(( $last_part_end + 1 ))
    # sectors_per_mb = (1024 * 1024) / 512 = 2048
    sectors_per_mb=2048
    demo_part_end=$(( $demo_part_start + ( $demo_part_size * $sectors_per_mb ) - 1 ))

    # Create new partition
    echo "Creating new demo partition ${blk_dev}$demo_part ..."
    parted -s --align optimal $blk_dev unit s \
      mkpart primary $demo_part_start $demo_part_end set $demo_part boot on || {
        echo "ERROR: Problems creating demo msdos partition $demo_part on: $blk_dev"
        exit 1
    }
    partprobe

}

eval $create_demo_partition $blk_dev
demo_dev="${blk_dev}$demo_part"
partprobe

# Create filesystem on demo partition with a label
mkfs.ext4 -L $demo_volume_label $demo_dev || {
    echo "Error: Unable to create file system on $demo_dev"
    exit 1
}

# Mount demo filesystem
demo_mnt="/boot"

mkdir -p $demo_mnt || {
    echo "Error: Unable to create demo file system mount point: $demo_mnt"
    exit 1
}
mount -t ext4 -o defaults,rw $demo_dev $demo_mnt || {
    echo "Error: Unable to mount $demo_dev on $demo_mnt"
    exit 1
}

# Copy kernel and initramfs to demo file system
cp demo.vmlinuz demo.initrd $demo_mnt

# store installation log in demo file system
onie-support $demo_mnt

# Pretend we are a major distro and install GRUB into the MBR of
# $blk_dev.
grub-install --boot-directory="$demo_mnt" --recheck "$blk_dev" || {
    echo "ERROR: grub-install failed on: $blk_dev"
    exit 1
}

# Create a minimal grub.cfg that allows for:
#   - configure the serial console
#   - allows for grub-reboot to work
#   - a menu entry for the DEMO OS
#   - menu entries for ONIE

grub_cfg=$(mktemp)


# Set a few GRUB_xxx environment variables that will be picked up and
# used by the 50_onie_grub script.  This is similiar to what an OS
# would specify in /etc/default/grub.
#
# GRUB_SERIAL_COMMAND
# GRUB_CMDLINE_LINUX

[ -r ./platform.conf ] && {
. ./platform.conf
}

[ -n "${GRUB_SERIAL_COMMAND}" ] || {
    GRUB_SERIAL_COMMAND="serial --port=0x3f8 --speed=115200 --word=8 --parity=no --stop=1"
}
export GRUB_SERIAL_COMMAND

[ -n "${GRUB_CMDLINE_LINUX}" ] || {
    GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8"
}
export GRUB_CMDLINE_LINUX

# Add common configuration, like the timeout and serial console.
(cat <<EOF
$GRUB_SERIAL_COMMAND
terminal_input serial
terminal_output serial

set timeout=5

EOF
) > $grub_cfg

# Add the logic to support grub-reboot
(cat <<EOF
if [ -s \$prefix/grubenv ]; then
  load_env
fi
if [ "\${next_entry}" ] ; then
   set default="\${next_entry}"
   set next_entry=
   save_env next_entry
fi

EOF
) >> $grub_cfg

# Add a menu entry for the DEMO OS
demo_grub_entry="Demo NOS"
(cat <<EOF
menuentry '$demo_grub_entry' {
        search --no-floppy --label --set=root $demo_volume_label
        echo    'Loading ONIE Demo OS ...'
        linux   /demo.vmlinuz $GRUB_CMDLINE_LINUX
        echo    'Loading ONIE initial ramdisk ...'
        initrd  /demo.initrd
}
EOF
) >> $grub_cfg

# Add menu entries for ONIE -- use the grub fragment provided by the
# ONIE distribution.
/mnt/onie-boot/onie/grub.d/50_onie_grub >> $grub_cfg

cp $grub_cfg $demo_mnt/grub/grub.cfg

# clean up
umount $demo_mnt || {
    echo "Error: Problems umounting $demo_mnt"
}

cd /
