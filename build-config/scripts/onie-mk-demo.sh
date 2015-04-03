#!/bin/sh

#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

arch=$1
machine=$2
platform=$3
installer_dir=$4
platform_conf=$5
output_file=$6
demo_type=$7

shift 7

if  [ ! -d $installer_dir ] || \
    [ ! -r $installer_dir/sharch_body.sh ] ; then
    echo "Error: Invalid installer script directory: $installer_dir"
    exit 1
fi

if  [ ! -d $installer_dir/$arch ] || \
    [ ! -r $installer_dir/$arch/install.sh ] ; then
    echo "Error: Invalid arch installer directory: $installer_dir/$arch"
    exit 1
fi

[ -r "$platform_conf" ] || {
    echo "Error: Unable to read installer platform configuration file: $platform_conf"
    exit 1
}

[ $# -gt 0 ] || {
    echo "Error: No OS image files found"
    exit 1
}

case $demo_type in
    OS|DIAG)
        # These are supported
        ;;
    *)
        echo "Error: Unsupported demo type: $demo_type"
        exit 1
esac

tmp_dir=
clean_up()
{
    rm -rf $tmp_dir
    exit $1
}

# make the data archive
# contents:
#   - kernel and initramfs
#   - install.sh
#   - $platform_conf

echo -n "Building self-extracting install image ."
tmp_dir=$(mktemp --directory)
tmp_installdir="$tmp_dir/installer"
mkdir $tmp_installdir || clean_up 1

cp $installer_dir/$arch/install.sh $tmp_installdir || clean_up 1

# Escape special chars in the user provide kernel cmdline string for use in
# sed. Special chars are: \ / &
EXTRA_CMDLINE_LINUX=`echo $EXTRA_CMDLINE_LINUX | sed -e 's/[\/&]/\\\&/g'`

# Tailor the demo installer for OS mode or DIAG mode
sed -i -e "s/%%DEMO_TYPE%%/$demo_type/g" \
       -e "s/%%CONSOLE_SPEED%%/$CONSOLE_SPEED/g" \
       -e "s/%%CONSOLE_DEV%%/$CONSOLE_DEV/g" \
       -e "s/%%CONSOLE_PORT%%/$CONSOLE_PORT/g" \
       -e "s/%%EXTRA_CMDLINE_LINUX%%/$EXTRA_CMDLINE_LINUX/" \
    $tmp_installdir/install.sh || clean_up 1
echo -n "."
cp $* $tmp_installdir || clean_up 1
echo -n "."
cp $platform_conf $tmp_installdir || clean_up 1
echo "machine=$machine" > $tmp_installdir/machine.conf
echo "platform=$platform" >> $tmp_installdir/machine.conf
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

echo "Success:  Demo install image is ready in ${output_file}:"
ls -l ${output_file}

clean_up 0
