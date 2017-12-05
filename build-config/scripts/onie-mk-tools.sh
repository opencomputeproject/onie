#!/bin/sh

#  Copyright (C) 2015 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0

#
# Script to create a tarball of "ONIE tools", which are made available
# to the NOS.
#

rootfs_arch=$1
tools_dir=$2
output_file=$3
sysroot=$4

shift 4

# The tools originate from two locations:
#
# 1. Some CPU architecture independent tools are from the $sysroot of
#    the ONIE installer image directly.  These tools are unmodified
#    copies of what is in the ONIE runtime image.
#
# 2. CPU dependent tools are from an architecture specific directory
#    located within the ONIE repo $tools_dir.  These tools are *not*
#    present in the ONIE runtime image.

arch_dir="$rootfs_arch"

[ -d "${tools_dir}/${arch_dir}" ] || {
    echo "ERROR: arch tools directory '${tools_dir}/${arch_dir}' does not exist."
    exit 1
}

touch $output_file || {
    echo "ERROR: unable to create output file: $output_file"
    exit 1
}
rm -f $output_file

[ -d "$sysroot" ] || {
    echo "ERROR: sysroot directory '$sysroot' does not exist."
    exit 1
}

[ $# -gt 0 ] || {
    echo "Error: No ONIE sysroot tool files found"
    exit 1
}

tmp_dir=
clean_up()
{
    rm -rf $tmp_dir
}

trap clean_up EXIT

# make the tools tarball
# contents:
#   - /bin  -- shell scripts
#   - /lib  -- shell script fragments

echo -n "Building ONIE tools archive ."
tmp_dir=$(mktemp --directory)
cp -a "${tools_dir}/${arch_dir}"/* $tmp_dir
echo -n "."
for f in $* ; do
    tdir="${tmp_dir}/$(dirname $f)"
    mkdir -p $tdir || exit 1
    cp -a "${sysroot}/$f" $tdir || exit 1
    echo -n "."
done

# Bundle data into a tar file
tar -C $tmp_dir -cJf $output_file $(ls $tmp_dir) || exit 1
echo -n "."

rm -rf $tmp_dir
echo " Done."

echo "Success:  ONIE tools tar archive is ready: ${output_file}"
