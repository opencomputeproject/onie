#!/bin/sh

cd $(dirname $0)

[ -r ./machine.conf ] || {
    echo "ERROR: ONIE update machine.conf file is missing."
    exit 1
}
. ./machine.conf

# get running machine from conf file
[ -r /etc/machine.conf ] && . /etc/machine.conf

# for backward compatibility if running machine_rev is empty assume it
# is 0.
true ${onie_machine_rev=0}

fail=
if [ "$onie_machine" != "$image_machine" ] ; then
    fail=yes
fi
if [ "$onie_machine_rev" != "$image_machine_rev" ] ; then
    fail=yes
fi
if [ "$onie_arch" != "$image_arch" ] ; then
    fail=yes
fi

if [ "$fail" = "yes" ] && [ -z "$force" ] ; then
    echo "ERROR: Machine mismatch"
    echo "Running machine     : ${onie_arch}/${onie_machine}-${onie_machine_rev}"
    echo "Update Image machine: ${image_arch}/${image_machine}-${image_machine_rev}"
    echo "Source URL: $onie_exec_url"
    exit 1
fi

[ -r onie-update.tar.xz ] || {
    echo "ERROR: ONIE update tar file is missing."
    exit 1
}

echo "ONIE: Version     : $image_version"
echo "ONIE: Architecture: $image_arch"
echo "ONIE: Machine     : $image_machine"
echo "ONIE: Machine Rev : $image_machine_rev"

xz -d -c onie-update.tar.xz | tar -xf -

# install ONIE
echo "Updating ONIE kernel ..."
flashcp -v ONIE.bin /dev/mtd-onie || {
    echo "ERROR: Updating ONIE kernel failed."
    exit 1
}

# install u-boot
echo "Updating ONIE U-Boot ..."
flashcp -v u-boot.bin /dev/mtd-uboot || {
    echo "ERROR: Updating ONIE U-Boot failed."
    exit 1
}

# - clear the onie_boot_reason if set
# - update ONIE version in u-boot env.
# - update the 'ver' environment variable.  Use the U-Boot/ONIE
#   version compiled into the image.  The string is null-terminated.
ver=$(dd if=/dev/mtd-uboot bs=1 skip=4 count=256 2>/dev/null | awk -F\x00 '{ print $1; exit }')

(cat <<EOF
onie_boot_reason
onie_version $image_version
ver $ver
EOF
) | fw_setenv -f -s -

echo "Rebooting..."
reboot
