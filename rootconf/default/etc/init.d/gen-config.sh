#!/bin/sh

#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

# If necessary, generate run-time ONIE configuration variables in
# /etc/machine-live.conf.

cmd="$1"

gen_live_config()
{
    # NO-OP
    true
}

[ -r /lib/onie/gen-config-platform ] && . /lib/onie/gen-config-platform

case $cmd in
    start)
        gen_live_config > /etc/machine-live.conf
        ;;
    *)

esac
