#!/bin/sh

cmd="$1"

PATH=/usr/bin:/usr/sbin:/bin:/sbin

. /lib/onie/functions

import_cmdline

daemon="discover"

do_start() {

    # parse boot_reason
    case "$onie_boot_reason" in
        rescue)
            # Delete the one time onie_boot_reason env variable.
            fw_setenv -f onie_boot_reason > /dev/null 2>&1
            echo "$daemon: Rescue mode detected.  Installer disabled." > /dev/console
            echo "** Rescue Mode Enabled **" >> /etc/issue
            exit 0
            ;;
        uninstall)
            echo "$daemon: Uninstall mode detected.  Running uninstaller." > /dev/console
            echo "** Uninstall Mode Enabled **" >> /etc/issue
            /bin/uninstaller
            exit 0
            ;;
        update)
            # pass through to discover
            echo "$daemon: ONIE update mode detected.  Running updater." > /dev/console
            echo "** ONIE Update Mode Enabled **" >> /etc/issue
            ;;
        install)
            # Delete the one time onie_boot_reason variable.  Also set
            # nos_bootcmd to a no-op, which will keep us in this state
            # if installation fails.
            (cat <<EOF
onie_boot_reason
nos_bootcmd true
EOF
            ) | fw_setenv -f -s - > /dev/null 2>&1
            # pass through to discover
            echo "$daemon: installer mode detected.  Running installer." > /dev/console
            echo "** Installer Mode Enabled **" >> /etc/issue
            ;;
        *)
            log_failure_msg "$daemon: Unknown reboot command: $onie_boot_reason"
            exit 1
    esac

    log_begin_msg "Starting: $daemon"
    start-stop-daemon -S -b -m -p /var/run/${daemon}.pid -x $daemon
    log_end_msg

}

do_stop() {
    log_begin_msg "Stopping: $daemon"
    start-stop-daemon -q -K -s TERM -p /var/run/${daemon}.pid
    killall -q $onie_installer exec_installer wget tftp 
    log_end_msg
}

case $cmd in
    start)
        do_start
        ;;
    stop)
        do_stop
        ;;
    *)
        
esac

