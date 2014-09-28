############################################################
# <bsn.cl fy=2013 v=onl>
#
#        Copyright 2013, 2014 BigSwitch Networks, Inc.
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
# Open Network Linux
#
############################################################

all:
	@echo "targets:"
	@echo ""
	@echo "Step #1: (outside workspace)"
	@echo "    install-host-deps        Install build dependencies into your host build machine."
	@echo ""
	@echo "Step #2: (inside workspace)"
	@echo "    install-ws-deps          Install build dependencies into your workspace after creating it."
	@echo ""
	@echo "Step #3: (inside workspace)"
	@echo "    onl-powerpc              Build all components, swi, loader, and installer in workspace."
	@echo "                               Run inside a workspace after \`make install-ws-deps\`"
	@echo "                               Equivalent to \`make all-components swi installer\`"
	@echo ""
	@echo "Optional Steps"
	@echo "    all-components           Build all components in workspace before building actual images."
	@echo ""
	@echo "    deb-clean                Clean all debian log files in the components subtree."
	@echo ""

############################################################
#
# These need to be initialized on the build host machine
#
############################################################
install-host-deps:
	sudo apt-get install binfmt-support qemu-user-static multistrap apt-cacher-ng devscripts debhelper realpath
	$(MAKE) -C tools
	sudo dpkg -i tools/*.deb
	@echo \`make install-host-deps\` SUCCESS


############################################################
#
# These need to be installed once in the build workspace
# after you create it.
#
############################################################
install-ws-deps: __install-ws-deps


onl-powerpc: all-components swi-powerpc installer-powerpc
	@echo "##############################################"
	@echo "################     DONE     ################"
	@echo "##############################################"
	@ls -l $$ONL/builds/installer/powerpc/all/*.installer \
	    $$ONL/builds/swi/powerpc/all/*.swi

############################################################
#
# Build each of the underlying components
#
############################################################
all-components:
	export ONL=`pwd` && make -C $$ONL/builds/components

installer-powerpc:
	export ONL=`pwd` && make -C $$ONL/builds/installer/powerpc/all

swi-powerpc:
	export ONL=`pwd` && make -C $$ONL/builds/swi/powerpc/all

############################################################
#
# These targets will clean all debian temporary files
# in the ONL component directories.
#
############################################################
deb-clean:
	find components -name "*.substvars" -delete
	find components -name "*.debhelper*" -delete
	find components -name "*.build" -delete
	find components -name "*.changes" -delete
	find components -name files -delete
	find components -name "*~" -delete


















############################################################
#
# No need to read further unless you run into issues
# installing the above targets.
#
# The following rules are a bit of hackery at the moment.
#
# We use the cross compiling and cross-package tools
# provided by the Emdebian repositories.
#
# Normally, we would just add the Emdebian sources and
# start installing everything, but some of the current
# package dependencies listed in Emdebian Wheezy appear
# to be broken -- the cross compiler tools provided by
# Emdebian have been recently updated with dependencies
# on libc6 and gcc-4.8 that cannot be satisfied by the
# versions provided by Debian Wheezy.
#
# This needs to get resolved, but as a stop-gap the
# previous versions of the offending packages (which
# are compatible with Debian Wheezy) are included and
# installed locally.
#
############################################################

#
# Install Emdebian keyring and repositories
#
emdebian-update:
	sudo apt-get install emdebian-archive-keyring
	echo 'APT::Get::AllowUnauthenticated "true";\nAPT::Get::Assume-Yes "true";' | sudo tee /etc/apt/apt.conf.d/99opennetworklinux
	sudo dpkg --add-architecture powerpc
	echo "deb http://emdebian.org/debian/ wheezy main" | sudo tee /etc/apt/sources.list.d/emdebian.list
	sudo apt-get update

#
# Install required native packages
#
install-native-deps: emdebian-update
	sudo apt-get install libedit-dev ncurses-dev gcc make xapt cdbs debhelper pkg-config devscripts bison flex texinfo wget cpio multistrap squashfs-tools zip binfmt-support autoconf automake1.9 autotools-dev libtool apt-file file genisoimage syslinux dosfstools mtools bc python-yaml mtd-utils gcc-4.7-multilib uboot-mkimage kmod

#
# Install required cross compiler packages.
# This is where it gets a little pear-shaped.
#
install-cross-deps: install-native-deps
	sudo apt-get install libc6-dev-powerpc-cross
	# These packages are currently incompatible between Debian/Emdebian wheezy:
	sudo dpkg -i tools/bin/amd64/binutils-powerpc-linux-gnu_2.22-7.1_amd64.deb
	sudo dpkg -i tools/bin/amd64/libgomp1-powerpc-cross_4.7.2-4_all.deb
	sudo apt-get install gcc-4.7-powerpc-linux-gnu libc6-dev-powerpc-cross dpkg-sig
	f=$$(mktemp); wget -O $$f "https://launchpad.net/ubuntu/+source/qemu/1.4.0+dfsg-1expubuntu3/+build/4336762/+files/qemu-user-static_1.4.0%2Bdfsg-1expubuntu3_amd64.deb" && sudo dpkg -i $$f
	sudo update-alternatives --install /usr/bin/powerpc-linux-gnu-gcc powerpc-linux-gnu-gcc /usr/bin/powerpc-linux-gnu-gcc-4.7 10
	sudo xapt -a powerpc libedit-dev ncurses-dev libsensors4-dev libwrap0-dev libssl-dev libsnmp-dev

__install-ws-deps: install-cross-deps

