#!/bin/sh

#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2015,2016,2017 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0

cmd="$1"

. /lib/onie/functions

import_cmdline

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
            exit 0
            ;;
        install)
            cat <<EOF >> /etc/issue
NOTICE: ONIE started in NOS install mode.  Install mode persists
NOTICE: until a NOS installer runs successfully.

EOF
            log_info_msg "Making NOS install boot mode sticky."
            install_remain_sticky_arch || {
                echo "Error: problems making install boot mode sticky" > /dev/console
            }
            exit 0
            ;;
        *)

    esac

}

case $cmd in
    start)
        do_start
        ;;
    *)

esac
