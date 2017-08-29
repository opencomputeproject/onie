#!/bin/sh

#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

# Network ASIC / Platform specific network driver initialization

cmd="$1"

. /lib/onie/functions

# Platform specific network driver initialization that happen
# *before* the primary network driver initialization.  This can be
# set for each platform.
network_driver_platform_pre_init()
{
    # NO-OP
    true
}

# Primary network driver initialization.
network_driver_init()
{
    # NO-OP
    true
}

# Platform specific network driver initialization that happen *after*
# the primary network driver initialization.  This can be set for
# each platform.
network_driver_platform_post_init()
{
    # NO-OP
    true
}

arch_network_driver="/lib/onie/network-driver-${onie_switch_asic}"
platform_network_driver="/lib/onie/network-driver-platform"

[ -r "$arch_network_driver" ]     && . "$arch_network_driver"
[ -r "$platform_network_driver" ] && . "$platform_network_driver"

case $cmd in
    start)
        network_driver_platform_pre_init
        network_driver_init
        network_driver_platform_post_init
        ;;
    *)

esac
