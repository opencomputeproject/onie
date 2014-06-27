#!/bin/sh

PATH=/usr/bin:/usr/sbin:/bin:/sbin

. /scripts/functions

import_cmdline

# Static ethernet management configuration
config_ethmgmt_static()
{
    if [ -n "$onie_ip" ] ; then
        # ip= was set on the kernel command line and configured by the
        # kernel already.  Do no more.
        log_console_msg "Using static IP config: ip=$onie_ip"
        return 0
    fi

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
        udhcp_args="$udhcp_args -t 5 -T 3"
    else
        udhcp_args="$udhcp_args -t 15 -T 3"
    fi
    udhcp_request_opts=
    for o in subnet broadcast router domain hostname ntpsrv dns logsrv ; do
        udhcp_request_opts="$udhcp_request_opts -O $o"
    done

    # Initate DHCP request on every interface in the list.  Stop after
    # one works.
    for i in $intf_list ; do
        log_info_msg "Trying DHCPv4 on interface: $i"
        tmp=$(udhcpc $udhcp_args $udhcp_request_opts $udhcp_user_class -i $i -s /scripts/udhcp4_net)
        if [ "$?" = "0" ] ; then
            local ipaddr=$(ifconfig $i |grep 'inet '|sed -e 's/:/ /g'|awk '{ print $3 " / " $7 }')
            log_console_msg "Using DHCPv4 addr: ${i}: $ipaddr"
            return 0
        fi
    done

    return 1
}

# Fall back ethernet management configuration
config_ethmgmt_fallback()
{

    local base_ip=10
    local default_nm="255.255.255.0"
    local default_hn="onie-host"

    # Assign sequential static IP to each detected interface
    for i in $(net_intf) ; do
        local default_ip="192.168.3.$base_ip"
        log_console_msg "Using default IPv4 addr: ${i}: ${default_ip}/${default_nm}"
        ifconfig $i $default_ip netmask $default_nm || {
            log_console_msg "Problems setting default IPv4 addr: ${i}: ${default_ip}/${default_nm}"
        }
        base_ip=$(( $base_ip + 1 ))
    done

    hostname $default_hn

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
