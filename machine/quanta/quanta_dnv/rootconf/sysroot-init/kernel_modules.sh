#!/bin/sh

ip link set dev eth0 name ethtmp
ip link set dev eth2 name eth0
ip link set dev eth1 name eth2
ip link set dev ethtmp name eth1

datapath1=$(lspci | grep 15c2 | awk '{print $1}' | sed -e '2d')
datapath2=$(lspci | grep 15c2 | awk '{print $1}' | sed -e '1d')
echo "0000:$datapath1" > /sys/bus/pci/drivers/ixgbe/unbind
echo "0000:$datapath2" > /sys/bus/pci/drivers/ixgbe/unbind

