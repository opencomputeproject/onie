#!/bin/sh

#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

cmd="$1"

daemon="klogd"
ARGS=

. /lib/onie/functions

case $cmd in
    start)
        killall $daemon > /dev/null 2>&1
        log_begin_msg "Starting: $daemon"
        $daemon $ARGS
        log_end_msg
        ;;

    stop)
        log_begin_msg "Stopping: $daemon"
        killall $daemon > /dev/null 2>&1
        log_end_msg
        ;;

    *)

esac
