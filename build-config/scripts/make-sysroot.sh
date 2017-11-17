#!/bin/sh

#  Copyright (C) 2014,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0

# This script generates a cpio archive of the final sysroot.
#
# The script is run as the "root" user inside of a fakeroot
# environment.

sysroot="$1"
[ -d "$sysroot" ] || {
    echo "ERROR: Invalid sysroot directory specified: $sysroot"
    exit 1
}

cpio_archive="$2"
touch "$cpio_archive" || {
    echo "ERROR: Unable to create output CPIO archive: $cpio_archive"
    exit 1
}
rm -f $cpio_archive

rm -rf ${sysroot}/dev
mkdir -p ${sysroot}/dev
cd $sysroot && find . | cpio --create -H newc > $cpio_archive
