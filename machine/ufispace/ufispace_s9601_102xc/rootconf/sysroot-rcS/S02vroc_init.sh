#!/bin/sh

#  Copyright (C) 2013,2014,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

##
## Mount kernel filesystems and Create initial devices.
##

PATH=/usr/bin:/usr/sbin:/bin:/sbin
. /lib/onie/functions

vroc_init () 
{
    echo "=== mdadm -As ===" > /tmp/vroc_init.log
    mdadm -As >> /tmp/vroc_init.log
    sleep 1
    echo "=== cat /proc/mdstat ===" >> /tmp/vroc_init.log
    cat /proc/mdstat >> /tmp/vroc_init.log
    echo "=== mdadm -D /dev/md126 ===" >> /tmp/vroc_init.log
    mdadm -D /dev/md126 >> /tmp/vroc_init.log
}
log_begin_msg "Info: Searching VROC devices"
vroc_init

