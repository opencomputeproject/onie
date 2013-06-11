#!/bin/sh

PATH=/usr/bin:/usr/sbin:/bin:/sbin

. /scripts/functions

import_cmdline

daemon="discover"

# Check for any one time boot commands
if [ -n "$onie_reboot_cmd" ] ; then

    # delete one time env variable
    fw_setenv -f reboot_cmd > /dev/null 2>&1

    # Further parse reboot_cmd
    case "$onie_reboot_cmd" in
        rescue)
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
        install)
            # pass through to discover
            true
            ;;
        *)
            log_failure_msg "$daemon: Unknown reboot command: $onie_reboot_cmd"
            reboot
    esac

fi

echo "** Installer Mode Enabled **" >> /etc/issue
log_begin_msg "Starting: $daemon"
start-stop-daemon -S -b -m -p /var/run/${daemon}.pid -x $daemon
log_end_msg
