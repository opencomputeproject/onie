#!/bin/sh

#  Copyright (C) 2013 Dustin Byford <dustin@cumulusnetworks.com>
#  Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2017 Nikolay Shopik <shopik@nvcube.net>
#
#  SPDX-License-Identifier:     GPL-2.0

cmd="$1"

. /lib/onie/functions

name=dropbear
daemon=/usr/sbin/$name

[ -x $daemon ] || exit 0

ARGS="-m -B"

RSA_KEY=/etc/dropbear/dropbear_rsa_host_key
DSS_KEY=/etc/dropbear/dropbear_dss_host_key
ECDSA_KEY=/etc/dropbear/dropbear_ecdsa_host_key

[ -r /lib/onie/dropbear-arch ] && . /lib/onie/dropbear-arch

get_keys() {
    # If keys are already present just return
    [ -r "$ECDSA_KEY" ] && [ -r "$RSA_KEY" ] && [ -r "$DSS_KEY" ] && return 0

    get_keys_arch || {
        # If problems just make new keys in ramdisk
        # genereate ecdsa key
        dropbearkey -t ecdsa -s 256 -f $ECDSA_KEY > /dev/null 2>&1
        # genereate rsa key
        dropbearkey -t rsa -s 1024 -f $RSA_KEY > /dev/null 2>&1
        # genereate dss key
        dropbearkey -t dss -s 1024 -f $DSS_KEY > /dev/null 2>&1
    }
}

case $cmd in
    start)
        killall $name > /dev/null 2>&1
        log_begin_msg "Starting: $name ssh daemon"
        get_keys
        cd / && $daemon $ARGS
        log_end_msg
        ;;
    stop)
        log_begin_msg "Stopping: $name ssh daemon"
        killall $name > /dev/null 2>&1
        log_end_msg
        ;;
    *)
        
esac
