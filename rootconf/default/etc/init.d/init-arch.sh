#!/bin/sh

# Architecture specific system initializations

cmd="$1"

. /lib/onie/functions

init_arch()
{
    # NO-OP
    true
}

[ -r /lib/onie/init-arch ] && . /lib/onie/init-arch

case $cmd in
    start)
        init_arch
        ;;
    *)
        
esac
