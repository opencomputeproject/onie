#!/bin/sh

#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014 david_yang <david_yang@accton.com>
#  Copyright (C) 2013 Doron Tsur <doront@mellanox.com>
#
#  SPDX-License-Identifier:     GPL-2.0

PATH=/usr/bin:/usr/sbin:/bin:/sbin

. /lib/onie/functions
[ -f /lib/onie/sysinfo-platform ] && . /lib/onie/sysinfo-platform

import_cmdline

# Static ethernet management configuration
config_ethmgmt_static()
{
    local intf=$1
    shift

    if [ -n "$onie_ip" ] ; then
        # ip= was set on the kernel command line and configured by the
        # kernel already.  Do no more.
        log_console_msg "${intf}: Using static IP config: ip=$onie_ip"
        if [ -f /lib/onie/network-startup-platform ]; then
            . /lib/onie/network-startup-platform
        fi
        return 0
    fi

    return 1
}

# DHCPv6 ethernet management configuration
config_ethmgmt_dhcp6()
{
    intf=$1
    shift

    # TODO
    # log_info_msg "TODO: Checking for DHCPv6 ethmgmt configuration."

    return 1
}

# DHCPv4 ethernet management configuration
config_ethmgmt_dhcp4()
{
    intf=$1
    shift

    # no default args
    udhcp_args="$(udhcpc_args) -n -o"
    if [ "$1" = "discover" ] ; then
        udhcp_args="$udhcp_args -t 5 -T 3"
    else
        udhcp_args="$udhcp_args -t 15 -T 3"
    fi
    udhcp_request_opts=
    for o in subnet broadcast router domain hostname ntpsrv dns logsrv search ; do
        udhcp_request_opts="$udhcp_request_opts -O $o"
    done

    log_info_msg "Trying DHCPv4 on interface: $intf"
    tmp=$(udhcpc $udhcp_args $udhcp_request_opts $udhcp_user_class -i $intf -s /lib/onie/udhcp4_net)
    if [ "$?" = "0" ] ; then
        local ipaddr=$(ifconfig $intf |grep 'inet '|sed -e 's/:/ /g'|awk '{ print $3 " / " $7 }')
        log_console_msg "Using DHCPv4 addr: ${intf}: $ipaddr"
    else
        _log_err_msg "DHCPv4 on interface: $intf failed"
        return 1
    fi
    return 0

}

# Fall back ethernet management configuration
config_ethmgmt_fallback()
{

    local base_ip=10
    local default_nm="255.255.255.0"
    local default_hn="onie-host"
    intf_counter=$1
    shift
    intf=$1
    shift

    interface_base_ip=$(( $base_ip + $intf_counter ))
    # Assign sequential static IP to each detected interface
    local default_ip="192.168.3.$interface_base_ip"
    log_console_msg "Using default IPv4 addr: ${intf}: ${default_ip}/${default_nm}"
    ifconfig $intf $default_ip netmask $default_nm || {
        _log_err_msg "Problems setting default IPv4 addr: ${intf}: ${default_ip}/${default_nm}"
        return 1
    }

    hostname $default_hn || {
        _log_err_msg "Problems setting default hostname: ${intf}: ${default_hn}"
        return 1
    }

    return 0

}

# Check if the specified interface is operationally "up".  Try for 5
# seconds and then give up.
check_link_up()
{
    local intf=$1
    local operstate="/sys/class/net/${intf}/operstate"

    _log_info_msg "Info: ${intf}:  Checking link... "
    local i=0
    [ -r $operstate ] && while [ $i -lt 100 ] ; do
        if [ "$(cat $operstate)" = "up" ] ; then
            _log_info_msg "up.\n"
            return 0
        fi
        sleep 0.1
        i=$(( $i + 1 ))
    done

    # no link
    _log_info_msg "down.\n"
    return 1
}

# Configure the management interface
# Try these methods in order:
# 1. static, from kernel command line parameters
# 2. DHCPv6
# 3. DHCPv4
# 4. Fall back to well known IP address
config_ethmgmt()
{
    intf_list=$(net_intf)
    intf_counter=0
    return_value=0

    # Bring up all the interfaces for the subsequent methods.
    for intf in $intf_list ; do
        cmd_run ifconfig $intf up
        params="$intf $*"
        eval "result_${intf}=0"
        type check_link_status_platform > /dev/null && {
            check_link_status_platform
        } || {
            check_link_up $intf || {
                log_console_msg "${intf}: link down.  Skipping configuration."
                eval "result_${intf}=1"
                continue
            }
        }
        config_ethmgmt_static    $params || \
            config_ethmgmt_dhcp6 $params || \
            config_ethmgmt_dhcp4 $params || \
            config_ethmgmt_fallback $intf_counter $params || \
            eval "result_${intf}=1"
        intf_counter=$(( $intf_counter + 1))
    done
    for intf in $intf_list ; do
        eval "curr_intf_result=\${result_${intf}}"
        if [ "x$curr_intf_result" != "x0" ] ; then
            log_console_msg "Failed to configure ${intf} interface"
            return_value=1
        fi
    done
    return $return_value
}

# When starting the network at boot time configure the MAC addresses
# for all the Ethernet management interfaces.
if [ "$1" = "start" ] ; then
    # Configure Ethernet management MAC addresses
    intf_list=$(net_intf)
    intf_counter=0

    # Set MAC addr for all interfaces, but leave the interfaces down.
    base_mac=$(onie-sysinfo -e)
    for intf in $intf_list ; do
        new_mac="$(mac_add $base_mac $intf_counter)"
        if [ $? -eq 0 ] ; then
            log_info_msg "Using $intf MAC address: $new_mac"
            cmd_run ifconfig $intf down
            cmd_run ifconfig $intf hw ether $new_mac down
        else
            log_failure_msg "Unable to configure MAC address for $intf"
        fi
        intf_counter=$(( $intf_counter + 1))
    done
fi

config_ethmgmt "$*"
