#!/bin/sh

# Architecture specific system initializations

cmd="$1"

. /lib/onie/functions

init_platform_pre_arch()
{
    # NO-OP
    true
}

init_arch()
{
    # NO-OP
    true
}

init_platform_post_arch()
{
    # NO-OP
    true
}

[ -r /lib/onie/init-arch ] && . /lib/onie/init-arch
[ -r /lib/onie/init-platform ] && . /lib/onie/init-platform

case $cmd in
    start)
        init_platform_pre_arch
        init_arch
        init_platform_post_arch
        ;;
    *)

esac
