#!/bin/sh

#  Copyright (C) 2013,2014,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

##
## Mount kernel filesystems and Create initial devices.
##

PATH=/usr/bin:/usr/sbin:/bin:/sbin

mount -t proc -o nodev,noexec,nosuid proc /proc
mount -t devtmpfs devtmpfs /dev

[ -e /dev/console ] || mknod -m 0600 /dev/console c 5 1
[ -e /dev/null ] || mknod -m 0666 /dev/null c 1 3

. /lib/onie/functions

# Set console logging to show KERN_WARNING and above
echo "5 4 1 5" > /proc/sys/kernel/printk

##
## Mount kernel virtual file systems, ala debian init script of the
## same name.  We use different options in some cases, so move the
## whole thing here to avoid re-running after the pivot.
##
mount_kernelfs()
{
    # keep /tmp, /var/tmp, /run, /run/lock in tmpfs
    tmpfs_size="10M"
    for d in run run/lock ; do
	cmd_run mkdir -p /$d
        mounttmpfs /$d "defaults,noatime,size=$tmpfs_size,mode=1777"
    done

    # On wheezy, if /var/run is not a link
    # fix it and make it a link to /run.
    if [ ! -L /var/run ] ; then
       rm -rf /var/run
       (cd /var && ln -s ../run run)
    fi

    for d in tmp var/tmp ; do
	cmd_run mkdir -p /$d
        mounttmpfs /$d "defaults,noatime,mode=1777"
    done

    cmd_run mount -o nodev,noexec,nosuid -t sysfs sysfs /sys || {
        log_failure_msg "Could not mount sysfs on /sys"
        /sbin/boot-failure 1
    }

    # take care of mountdevsubfs.sh duties also
    d=/run/shm
    if [ ! -d $d ] ; then
	cmd_run mkdir --mode=755 $d
    fi
    mounttmpfs $d "nosuid,nodev"

    TTYGRP=5
    TTYMODE=620
    d=/dev/pts
    if [ ! -d $d ] ; then
	cmd_run mkdir --mode=755 $d
    fi
    cmd_run mount -o "noexec,nosuid,gid=$TTYGRP,mode=$TTYMODE" -t devpts  devpts $d || {
        log_failure_msg "Could not mount devpts on $d"
        /sbin/boot-failure 1
    }
}

log_begin_msg "Info: Mounting kernel filesystems"
mount_kernelfs
log_end_msg

# mtd devices
# Use the names found in /proc/mtd to create symlinks in /dev.
# /dev/mtd-<NAME>
mtds=$(sed -e 's/://' -e 's/"//g' /proc/mtd | tail -n +2 | awk '{ print $1 ":" $4 }')
for x in $mtds ; do
    dev=/dev/${x%:*}
    name=${x#*:}
    if [ -n "$dev" ] ; then
        [ -c $dev ] || {
            log_failure_msg "$dev is not a valid MTD device."
            /sbin/boot-failure 1
        }
        ln -sf $dev /dev/mtd-$name
    fi
done

# mount securityfs if supported
if grep -q securityfs /proc/filesystems ; then
    mount -t securityfs securityfs /sys/kernel/security
fi

mkdir -p $ONIE_RUN_DIR
mkdir -p $ONIE_USB_DIR

