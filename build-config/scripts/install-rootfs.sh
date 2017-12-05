#!/bin/sh

#  Copyright (C) 2013,2014,2015 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

srcfs="$1"
rootfs=$2

[ -n "$srcfs" ] && [ -d "$srcfs" ] || {
    echo "Error: unable to locate source fs: $srcfs"
    exit 1
}
[ -n "$rootfs" ] && [ -d "$rootfs" ] || {
    echo "Error: unable to locate target fs: $rootfs"
    exit 1
}
[ "$rootfs" != "/" ] || {
    echo "Error: will not modify \"${rootfs}\""
    exit 1
}

ROOTFS="$(realpath ${rootfs})" && echo "Installing in ${ROOTFS}"

TAR_OPTS="--exclude=*~ --exclude-backups --owner=root --group=root"
echo "Copying $srcfs rootfs into target rootfs"
tar --directory=$srcfs $TAR_OPTS  -cf - . | ( cd $ROOTFS; tar -xpf - )
