#!/bin/sh
############################################################
#
# The only argument is the SDK version suffix for the
# required modules.
#
############################################################
set -e

version=$1

if [ "${version}" = "" ]; then
    echo "usage: $0 <version>"
    exit 1
fi

# Remove old modules in case we're switching versions
[ -e /proc/linux-user-bde ] && rmmod linux-user-bde
[ -e /proc/linux-kernel-bde ] && rmmod linux-kernel-bde

# Is there a platform-specific installation script?
if [ -f /etc/sl_platform ]; then
    PLATFORM_NAME=$(cat /etc/sl_platform)
elif [ -f /etc/onl_platform ]; then
    PLATFORM_NAME=$(cat /etc/onl_platform)
fi

PLATFORM_SCRIPT=/lib/platform-config/${PLATFORM_NAME}/sbin/brcm-modules-init.sh

if [ -e "$PLATFORM_SCRIPT" ]; then
    "$PLATFORM_SCRIPT" "$@"
else
# Default to standard insertion
    insmod /lib/modules/`uname -r`/linux-kernel-bde-${version}.ko
    insmod /lib/modules/`uname -r`/linux-user-bde-${version}.ko
fi

# Verify existance of the device files
[ -e /dev/linux-kernel-bde ] || mknod /dev/linux-kernel-bde c 127 0
[ -e /dev/linux-user-bde ] || mknod /dev/linux-user-bde c 126 0








