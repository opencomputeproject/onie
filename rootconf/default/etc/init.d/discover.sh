#!/bin/sh

#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

cmd="$1"

PATH=/usr/bin:/usr/sbin:/bin:/sbin

. /lib/onie/functions

import_cmdline

daemon="discover"

# We want rescue mode booting to be a one time operation.  After the
# rescue mode we should reboot into the previous default boot entry.
# How to do that is an architecture specific detail.
#
# An architecture must provide an override of this function.
rescue_revert_default_arch()
{
    false
}

# We want install mode booting to be sticky, i.e. if you boot into
# install mode you stay install mode until an installer runs
# successfully.  How to do that is an architecture specific detail.
#
# An architecture must provide an override of this function.
install_remain_sticky_arch()
{
    false
}

[ -r /lib/onie/boot-mode-arch ] || {
    echo "Error: missing /lib/onie/boot-mode-arch file." > /dev/console
    exit 1
}
. /lib/onie/boot-mode-arch

do_start() {

    # parse boot_reason
    case "$onie_boot_reason" in
        rescue)
            # Delete the one time onie_boot_reason env variable.
            rescue_revert_default_arch || {
                echo "Error: problems clearing rescue boot mode" > /dev/console
            }
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
            install_remain_sticky_arch || {
                echo "Error: problems making install boot mode sticky" > /dev/console
            }
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

