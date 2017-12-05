#!/bin/sh

#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

##
## ONIE Update Installer
## DO NOT remove the following line:
##   ONIE-UPDATER-COOKIE
##
## Shell archive template
##
## Strings of the form %%VAR%% are replaced during construction.
##

extract=no
quiet=no
args=":xq"
while getopts "$args" a ; do
    case $a in
        x)
            extract=yes
            ;;
        q)
            quiet=yes
            ;;
        *)
        ;;
    esac
done

[ "$quiet" = "no" ] && echo -n "Verifying image checksum ..."
sha1=$(sed -e '1,/^exit_marker$/d' "$0" | sha1sum | awk '{ print $1 }')

payload_sha1=%%IMAGE_SHA1%%

if [ "$sha1" != "$payload_sha1" ] ; then
    echo
    echo "ERROR: Unable to verify archive checksum"
    echo "Expected: $payload_sha1"
    echo "Found   : $sha1"
    exit 1
fi

[ "$quiet" = "no" ] && echo " OK."

tmp_dir=
clean_up() {
    if [ "$(id -u)" = "0" ] ; then
        umount $tmp_dir > /dev/null 2>&1
    fi
    rm -rf $tmp_dir
    exit $1
}

# Untar and launch install script in a tmpfs
cur_wd=$(pwd)
archive_path=$(realpath "$0")
tmp_dir=$(mktemp -d)
if [ "$(id -u)" = "0" ] ; then
    mount -t tmpfs tmpfs-installer $tmp_dir || clean_up 1
fi
cd $tmp_dir
[ "$quiet" = "no" ] && echo -n "Preparing image archive ..."
sed -e '1,/^exit_marker$/d' $archive_path | tar xf - || clean_up 1
[ "$quiet" = "no" ] && echo " OK."
cd $cur_wd

if [ "$extract" = "yes" ] ; then
    # stop here
    echo "Image extracted to: $tmp_dir"
    if [ "$(id -u)" = "0" ] ; then
        echo "To un-mount the tmpfs when finished type:  umount $tmp_dir"
    fi
    exit 0
fi

[ -r $tmp_dir/installer/onie-update.tar.xz ] || {
    echo "ERROR: ONIE updater tar file is missing."
    echo "ERROR: ONIE updater has bad format."
    clean_up 1
}

$tmp_dir/installer/install.sh "$@"
rc="$?"

clean_up $rc

exit_marker
