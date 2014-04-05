# -*- Makefile -*-
############################################################
# <bsn.cl fy=2013 v=onl>
# 
#        Copyright 2013, 2014 Big Switch Networks, Inc.       
# 
# Licensed under the Eclipse Public License, Version 1.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
# 
#        http://www.eclipse.org/legal/epl-v10.html
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the
# License.
# 
# </bsn.cl>
############################################################
#
# Common targets for running images under KVM.
#
############################################################



############################################################
#
# Run with 1G by default.
#
############################################################
ifndef KVM_MEMORY_SIZE
KVM_MEMORY_SIZE := 1024
endif

############################################################
#
# Need an HDA image.
#
############################################################
ifndef KVM_HDA
$(error $$KVM_HDA is not set)
endif

############################################################
#
# Need an ISO
#
############################################################
ifndef KVM_ISO
$(error $$KVM_ISO is not set)
endif

############################################################
#
# Basic KVM execution:
#
############################################################
KVM_RUN := sudo kvm -m $(KVM_MEMORY_SIZE) -cdrom $(KVM_ISO) -boot d -nographic -hda $(KVM_HDA)


############################################################
#
# Run using the default QEMU default NAT interface.
#
# Please note -- this is good for initial testing but
# is not going to be what you want for development.
#
# Important -- ICMP-based packets, like ping (!)
# do not work in this configuration, so don't try ping'ing
# something to verify connectivity...
#
# See the 'run-bridged' configuration below for something
# more useful, but it requires some setup first.
#
############################################################
run-nat:
	$(KVM_RUN)



############################################################
#
# Generate a random MAC address with the QEMU OUI 52:54:00
# This will be used for the bridged interface below.
#
############################################################
ifndef KVM_MAC
KVM_MAC := 52:54:00:$(shell dd if=/dev/urandom bs=512 count=1 2>/dev/null | md5sum | sed 's/^\(..\)\(..\)\(..\).*$$/\1:\2:\3/')
endif

############################################################
#
# You shouldn't have to change this under normal
# circumstances, even with multiple vms running
# simulatneously.
#
############################################################
ifndef KVM_NETDEV
KVM_NETDEV := net0
endif


############################################################
#
# Run with a bridged network interface.
#
# This requires that you setup a br interface on the host
# system.
#
# If you have no appropriate bridge, QEMU will warn you:
#
#     "no bridge for guest interface found"
#
# And your network interface will not work.
#
# Setting up a bridge under Ubuntu is simple, and should
# not affect your normal networking operation.
#
# The bridge setup should be done by editing /etc/network/interfaces.
#
# The following example converts a standard, "eth0 using dhcp" setup
# to include a bridge:
#
ifeq ("cut-here and", " => etc/network/interfaces")

# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
# The previous configuration had eth0 as dhcp
#iface eth0 inet dhcp
iface eth0 inet manual

auto br0
iface br0 inet dhcp
        bridge_ports eth0
        bridge_stp off
        bridge_fd 0
        bridge_maxwait 0

endif



############################################################
#
# Run with bridged networking
#
############################################################

run-bridged:
	$(KVM_RUN) -device e1000,netdev=$(KVM_NETDEV),mac=$(KVM_MAC) -netdev tap,id=$(KVM_NETDEV)
