#!/bin/sh

# Platform specific system initializations

cmd="$1"

. /lib/onie/functions

init_platform()
{
    # NO-OP
    true
}

[ -r /lib/onie/init-platform ] && . /lib/onie/init-platform

case $cmd in
    start)
        init_platform
        ;;
    *)

esac
