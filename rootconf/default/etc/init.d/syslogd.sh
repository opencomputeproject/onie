#!/bin/sh

cmd="$1"

daemon="syslogd"

ARGS="-b 3 -D -L"

. /scripts/functions

ARG_FILE="${ONIE_RUN_DIR}/syslogd.args"
LOGSRVS=$(cat "${ONIE_RUN_DIR}/dhcp.logsrv")
for r in $LOGSRVS ; do
    ARGS="$ARGS -R $r"
done

# Only restart the syslogd if the args have changed
OLD_ARGS=
[ -r "$ARG_FILE" ] && OLD_ARGS=$(cat "$ARG_FILE")

case $cmd in
    start|discover)
        if [ "$OLD_ARGS" = "$ARGS" ] && pidof -s $daemon > /dev/null 2>&1 ; then
            # The args did not change and the server is still running.
            # Do nothing.
            return 0
        fi
        # kill the old one
        killall $daemon > /dev/null 2>&1
        $daemon $ARGS
        echo "$ARGS" > $ARG_FILE
        ;;

    stop)
        log_begin_msg "Stopping: $daemon"
        killall $daemon > /dev/null 2>&1
        log_end_msg
        ;;

    *)
        
esac
