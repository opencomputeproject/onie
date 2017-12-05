#!/bin/sh

#
#  Copyright (C) 2015 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#

# goal: Make an ONIE installer from Debian's Jessie mini.iso
#
# inputs: debian-jessie.iso
# output: ONIE compatible installer

#!/bin/sh

set -e

IN=./input
OUT=./output
rm -rf $OUT
mkdir -p $OUT

WORKDIR=./work
EXTRACTDIR="$WORKDIR/extract"
INSTALLDIR="$WORKDIR/installer"

IN_IMAGE="debian-jessie-amd64-mini"
ISO="${IN}/${IN_IMAGE}.iso"

# Download the mini.iso if necessary
[ -r "$ISO" ] || {
    echo "Downloading Debian Jessie mini.iso ..."
    rm -rf $IN
    mkdir -p $IN
    URL="http://ftp.debian.org/debian/dists/jessie/main/installer-amd64/current/images/netboot/mini.iso"
    echo "Using URL: $URL"
    wget -O $ISO $URL
}

output_file="${OUT}/${IN_IMAGE}-ONIE.bin"

echo -n "Creating $output_file: ."

# prepare workspace
[ -d $EXTRACTDIR ] && chmod +w -R $EXTRACTDIR
rm -rf $WORKDIR
mkdir -p $EXTRACTDIR
mkdir -p $INSTALLDIR

# extract ISO
xorriso \
    -indev $ISO \
    -osirrox on \
    -extract / $EXTRACTDIR
echo -n "."

# based on isolinux.cfg, load save kernel and initramfs:
# default install
# label install
#         menu label ^Install
#         menu default
#         kernel linux
#         append vga=788 initrd=initrd.gz --- quiet 

KERNEL=linux
IN_KERNEL=$EXTRACTDIR/$KERNEL
[ -r $IN_KERNEL ] || {
    echo "ERROR: Unable to find kernel in ISO: $IN_KERNEL"
    exit 1
}
INITRD=initrd.gz
IN_INITRD=$EXTRACTDIR/$INITRD
[ -r $IN_INITRD ] || {
    echo "ERROR: Unable to find initrd in ISO: $IN_INITRD"
    exit 1
}

# Note: specify kernel args you want the Debian installer to
# automatically append by putting them after the special marker "---".
# Here we want the Deb installer to auto include the serial console
# parameters.
KERNEL_ARGS="--- console=tty0 console=ttyS0,115200n8"

# To debug DI preseed file add these args
# DI_DEBUG_ARGS="DEBCONF_DEBUG=5 dbg/flags=all-x"

# Debian installer args
DI_ARGS="auto=true priority=critical $DI_DEBUG_ARGS"

cp $IN_KERNEL $IN_INITRD $INSTALLDIR

# Create custom install.sh script
touch $INSTALLDIR/install.sh
chmod +x $INSTALLDIR/install.sh

(cat <<EOF
#!/bin/sh

cd \$(dirname \$0)

# remove old partitions
for p in \$(seq 3 9) ; do
  sgdisk -d \$p /dev/vda > /dev/null 2&>1
done

# bonk out on errors
set -e

# use the onie_exec_url to find the preseed file
base_url="\${onie_exec_url%/*}"
preseed_url="\${base_url}/./debian-preseed.txt"

echo "Loading new kernel ..."
kexec --load --initrd=$INITRD --append="$DI_ARGS url=\$preseed_url $KERNEL_ARGS" $KERNEL
kexec --exec

EOF
) >> $INSTALLDIR/install.sh
echo -n "."

# Repackage $INSTALLDIR into a self-extracting installer image
sharch="$WORKDIR/sharch.tar"
tar -C $WORKDIR -cf $sharch installer || {
    echo "Error: Problems creating $sharch archive"
    exit 1
}

[ -f "$sharch" ] || {
    echo "Error: $sharch not found"
    exit 1
}
echo -n "."

sha1=$(cat $sharch | sha1sum | awk '{print $1}')
echo -n "."

cp sharch_body.sh $output_file || {
    echo "Error: Problems copying sharch_body.sh"
    exit 1
}

# Replace variables in the sharch template
sed -i -e "s/%%IMAGE_SHA1%%/$sha1/" $output_file
echo -n "."
cat $sharch >> $output_file
rm -rf $tmp_dir
echo " Done."
