#!/bin/sh

# This script generates a cpio archive of the final sysroot.
#
# The script is run as the "root" user inside of a fakeroot
# environment.
#
# Under fakeroot this script creates all of the required device files.

device_script="$1"
[ -x "$device_script" ] || {
    echo "ERROR: Invalid device creation script: $device_script"
    exit 1
}

sysroot="$2"
[ -d "$sysroot" ] || {
    echo "ERROR: Invalid sysroot directory specified: $sysroot"
    exit 1
}

cpio_archive="$3"
touch "$cpio_archive" || {
    echo "ERROR: Unable to create output CPIO archive: $cpio_archive"
    exit 1
}
rm -f $cpio_archive

echo "==== Installing the basic set of devices ===="
cd $sysroot && rm -rf dev && mkdir dev && cd -
$device_script $sysroot
cd $sysroot && find . | cpio --create -H newc > $cpio_archive
