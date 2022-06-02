#!/bin/sh

# Installer script for DEMO OS

set -e

cd $(dirname $0)
. ./machine.conf

echo "Demo Installer: platform: $platform"
install_uimage() {
    #echo ">>> Partitioning USB Disk <<<"
    #echo -e "o\nw\n" |fdisk /dev/sda
    #echo -e "n\np\n1\n\n\nw\n" |fdisk /dev/sda

    #echo ">>> Format Partition to EXT4 <<<"
    #echo -e "y\n" | mkfs.ext4 /dev/sda1
    FileName="demo-${platform}.itb"
    Partition="/dev/mmcblk0p2"
    echo ">>> Install ${FileName} to ${Partition} <<<"
    mkdir /mnt/demo 
    mount ${Partition} /mnt/demo/
    cp ${FileName} /mnt/demo/
    
    echo ">>> SYNC <<<" 
    sync
}

hw_load() {
    echo "if test -e mmc 0:2 demo-${platform}.itb; then if ext4load mmc 0:2 \$loadaddr demo-${platform}.itb; then run wtd_16hz_en && bootm \$loadaddr; fi; fi;"
}

#. ./platform.conf

install_uimage

hw_load_str="$(hw_load)"

echo "Updating U-Boot environment variables"
(cat <<EOF
hw_load $hw_load_str
copy_img echo "Loading Demo $platform image..." && run set_bootargs && run hw_load
nos_bootcmd run copy_img 
EOF
) > /tmp/env.txt

fw_setenv -f -s /tmp/env.txt

cd /

# Set NOS mode if available.  For manufacturing diag installers, you
# probably want to skip this step so that the system remains in ONIE
# "installer" mode for installing a true NOS later.
if [ -x /bin/onie-nos-mode ] ; then
    /bin/onie-nos-mode -s
fi
