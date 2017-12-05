#!/bin/sh

#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2015 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0

cmd="$1"

PATH=/usr/bin:/usr/sbin:/bin:/sbin

. /lib/onie/functions

import_cmdline

daemon="discover"

do_start() {

    # parse boot_reason
    case "$onie_boot_reason" in
        rescue)
            echo "$daemon: Rescue mode detected.  Installer disabled." > /dev/console
            echo "** Rescue Mode Enabled **" >> /etc/issue
            exit 0
            ;;
        uninstall)
            echo "$daemon: Uninstall mode detected.  Running uninstaller." > /dev/console
            echo "** Uninstall Mode Enabled **" >> /etc/issue
            /bin/onie-uninstaller
            exit 0
            ;;
        update|embed)
            # pass through to discover
            echo "$daemon: ONIE $onie_boot_reason mode detected.  Running updater." > /dev/console
            echo "** ONIE Update Mode Enabled **" >> /etc/issue
            ;;
        install)
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
    # parse boot_reason
    case "$onie_boot_reason" in
        rescue)
            echo "$daemon: Rescue mode detected. No $daemon stopped." > /dev/console
            exit 0
            ;;
        uninstall)
            echo "$daemon: Uninstall mode detected. No $daemon stopped." > /dev/console
            exit 0
            ;;
        update|embed)
            # pass through to discover stop
            echo "$daemon: ONIE $onie_boot_reason mode detected." > /dev/console
            ;;
        install)
            # pass through to discover stop
            echo "$daemon: installer mode detected." > /dev/console
            ;;
        *)
            # pass through to discover stop
            log_failure_msg "$daemon: Unknown reboot command [stop]: $onie_boot_reason"
    esac

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

