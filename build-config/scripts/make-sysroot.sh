#!/bin/sh

#  Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0

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
rm -rf ${sysroot}/dev
mkdir -p ${sysroot}/dev
$device_script $sysroot
cd $sysroot && find . | cpio --create -H newc > $cpio_archive
