#!/bin/sh

#
# Script to create an ONIE binary installer, suitable for downloading
# to a running ONIE system during "update" mode.
#

machine=$1
machine_conf=$2
installer_dir=$3
image_dir=$4
conf_dir=$5
output_file=$6

[ -r "$machine_conf" ] || {
    echo "ERROR: unable to read machine configuration file: $machine_conf"
    exit 1
}

[ -d "$conf_dir" ] || {
    echo "ERROR: machine configuration directory '$conf_dir' does not exist."
    exit 1
}

conf_file="$conf_dir/onie-rom.conf"
[ -r "$conf_file" ] || {
    echo "ERROR: unable to read machine ROM configuration '$conf_file'."
    exit 1
}

. $conf_file

[ -d "$installer_dir" ] || {
    echo "ERROR: installer directory '$installer_dir' does not exist."
    exit 1
}

[ -d "$image_dir" ] || {
    echo "ERROR: image directory '$image_dir' does not exist."
    exit 1
}

onie_uimage="$image_dir/${machine}.itb"
[ -r "$onie_uimage" ] || {
    echo "ERROR: onie-uImage '$onie_uimage' does not exist."
    exit 1
}

uboot_bin="$image_dir/${machine}.u-boot"
[ -r "$uboot_bin" ] || {
    echo "ERROR: u-boot binary '$uboot_bin' does not exist."
    exit 1
}

touch $output_file || {
    echo "ERROR: unable to create output file: $output_file"
    exit 1
}
rm -f $output_file

tmp_dir=
clean_up()
{
    rm -rf $tmp_dir
    exit $1
}

# make the data archive
# contents:
#   - uImage file
#   - u-boot file
#   - $machine_conf

echo -n "Building self-extracting ONIE installer image ."
tmp_dir=$(mktemp --directory)
tmp_installdir="$tmp_dir/installer"
mkdir $tmp_installdir || clean_up 1
tmp_tardir="$tmp_dir/tar"
mkdir $tmp_tardir || clean_up 1

cp $onie_uimage $tmp_tardir/ONIE.bin || clean_up 1
echo -n "."
cp $uboot_bin $tmp_tardir/u-boot.bin || clean_up 1
echo -n "."

# Bundle data into a tar file
tar -C $tmp_tardir -cJf $tmp_installdir/onie-update.tar.xz $(ls $tmp_tardir) || clean_up 1
echo -n "."

cp $installer_dir/install.sh $tmp_installdir || clean_up 1
echo -n "."
sed -e 's/onie_/image_/' $machine_conf > $tmp_installdir/machine.conf || clean_up 1
echo -n "."

sharch="$tmp_dir/sharch.tar"
tar -C $tmp_dir -cf $sharch installer || {
    echo "Error: Problems creating $sharch archive"
    clean_up 1
}
echo -n "."

[ -f "$sharch" ] || {
    echo "Error: $sharch not found"
    clean_up 1
}
sha1=$(cat $sharch | sha1sum | awk '{print $1}')
echo -n "."
cp $installer_dir/sharch_body.sh $output_file || {
    echo "Error: Problems copying sharch_body.sh"
    clean_up 1
}

# Replace variables in the sharch template
sed -i -e "s/%%IMAGE_SHA1%%/$sha1/" $output_file
echo -n "."
cat $sharch >> $output_file
rm -rf $tmp_dir
echo " Done."

echo "Success:  ONIE install image is ready in ${output_file}:"
ls -l ${output_file}

clean_up 0
