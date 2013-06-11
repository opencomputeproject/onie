#!/bin/sh

PATH=/usr/bin:/usr/sbin:/bin:/sbin

. /scripts/functions

import_cmdline

# Static ethernet management configuration
config_ethmgmt_static()
{
    # TODO
    # log_info_msg "TODO: Checking for static ethmgmt configuration."
    return 1
}

# DHCPv6 ethernet management configuration
config_ethmgmt_dhcp6()
{
    # TODO
    # log_info_msg "TODO: Checking for DHCPv6 ethmgmt configuration."
    return 1
}

# DHCPv4 ethernet management configuration
config_ethmgmt_dhcp4()
{
    intf_list=$(net_intf)

    # no default args
    udhcp_args="$(udhcpc_args) -n -o"
    if [ "$1" = "discover" ] ; then
        udhcp_args="$udhcp_args -t 2 -T 2"
    else
        udhcp_args="$udhcp_args -t 5 -T 3"
    fi
    udhcp_request_opts=
    for o in subnet broadcast router domain hostname ntpsrv dns ; do
        udhcp_request_opts="$udhcp_request_opts -O $o"
    done

    # Initate DHCP request on every interface in the list.  Stop after
    # one works.
    for i in $intf_list ; do
        log_info_msg "Trying DHCPv4 on interface: $i"
        tmp=$(udhcpc $udhcp_args $udhcp_request_opts $udhcp_user_class -i $i -s /scripts/udhcp4_net) && break
    done

}

# Fall back ethernet management configuration
config_ethmgmt_fallback()
{
    # TODO
    log_warning_msg "Using fall back ethmgmt configuration."
}

# Configure the management interface
# Try these methods in order:
# 1. static, from kernel command line parameters
# 2. DHCPv6
# 3. DHCPv4
# 4. Fall back to well known IP address
config_ethmgmt()
{
    config_ethmgmt_static "$*" && return

    # Bring up all the interfaces for the subsequent methods.
    for i in $intf_list ; do
        cmd_run ifconfig $i up
    done

    config_ethmgmt_dhcp6 "$*"  && return
    config_ethmgmt_dhcp4 "$*"  && return
    config_ethmgmt_fallback "$*"
}

config_ethmgmt "$*"
