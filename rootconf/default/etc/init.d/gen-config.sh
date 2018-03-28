#!/bin/sh

#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2017 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0

# If necessary, generate run-time ONIE configuration variables in
# /etc/machine-live.conf.

cmd="$1"

gen_live_config()
{
    # NO-OP
    true
}

[ -r /lib/onie/gen-config-platform ] && . /lib/onie/gen-config-platform

gen_machine_config()
{
    local build_conf=/etc/machine-build.conf
    local live_conf=/etc/machine-live.conf
    local machine_conf=/etc/machine.conf

    gen_live_config > $live_conf

    cat $build_conf $live_conf > $machine_conf
    sed -i -e '/onie_machine=/d' $machine_conf
    sed -i -e '/onie_platform=/d' $machine_conf

    # Use onie_machine if set, otherwise use build_machine
    . $build_conf
    . $live_conf
    local onie_machine=${onie_machine:-$onie_build_machine}
    local onie_platform="${onie_arch}-${onie_machine}-r${onie_machine_rev}"
    cat <<EOF >> $machine_conf
onie_machine=$onie_machine
onie_platform=$onie_platform
EOF

}

case $cmd in
    start)
        gen_machine_config
        ;;
    *)

esac
