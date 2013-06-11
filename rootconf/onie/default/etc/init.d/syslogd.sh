#!/bin/sh

cmd="$1"
remote="$2"

daemon="syslogd"

ARGS="-b 3 -D"
[ -n "$remote" ] && ARGS="$ARGS -L -R $remote"

. /scripts/functions

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

