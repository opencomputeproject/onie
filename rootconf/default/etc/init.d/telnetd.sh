#!/bin/sh

#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

cmd="$1"

. /lib/onie/functions

daemon="telnetd"

# launch a shell on telnet connect
ARGS="-l /bin/onie-console -f /etc/issue.null"

case $cmd in
    start)
        killall $daemon > /dev/null 2>&1
        log_begin_msg "Starting: $daemon"
        cd / && $daemon $ARGS
        log_end_msg
        ;;
    stop)
        log_begin_msg "Stopping: $daemon"
        killall $daemon > /dev/null 2>&1
        log_end_msg
        ;;
    *)
        
esac

