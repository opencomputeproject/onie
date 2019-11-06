#!/bin/sh

#  Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

# Architecture specific system initializations

cmd="$1"

. /lib/onie/functions

case $cmd in
    start)
        i2cset -y 0 0x18 0x70 0x1
        ;;
    *)

esac
