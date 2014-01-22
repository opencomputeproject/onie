#!/bin/sh

cmd="$1"

. /lib/onie/functions

name=dropbear
daemon=/usr/sbin/$name

[ -x $daemon ] || exit 0

ARGS="-m -B -P"

RSA_KEY=/etc/dropbear/dropbear_rsa_host_key
DSS_KEY=/etc/dropbear/dropbear_dss_host_key

[ -r /lib/onie/dropbear-arch ] && . /lib/onie/dropbear-arch

get_keys() {
    # If keys are already present just return
    [ -r "$RSA_KEY" ] && [ -r "$DSS_KEY" ] && return 0

    get_keys_arch
}

case $cmd in
    start)
        killall $name > /dev/null 2>&1
        log_begin_msg "Starting: $name ssh daemon"
        get_keys || exit 1
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
