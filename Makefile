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
	@echo "    docker                   Enter the pre-built docker workspace with all dev tools"
	@echo ""
	@echo "Step #2: (inside workspace)"
	@echo "    onl-{powerpc,x86, kvm}     Build all ONL for either x86, powerpc or kvm, including "
	@echo "                               components, swi, loader, and installer in workspace."
	@echo "                               Equivalent to \`make all-components swi installer\`"
	@echo ""
	@echo "Optional Steps"
	@echo "    all-components           Build all components in workspace before building actual images."
	@echo ""
	@echo "    deb-clean                Clean all debian log files in the components subtree."
	@echo ""
	@echo "    swi                      Build the SWitch Image; requires $$ARCH set"
	@echo ""
	@echo "    installer                Build the ONL ONIE installer; requires $$ARCH set"
	@echo ""

docker:
	export ONL=`pwd` && $(MAKE) -C tools/docker

onl-powerpc: ARCH=powerpc
onl-powerpc: all-components swi installer
	@echo "##############################################"
	@echo "################     DONE     ################"
	@echo "##############################################"
	@export ONL=`pwd` && ls -l $$ONL/builds/installer/powerpc/all/*.installer \
	    $$ONL/builds/swi/powerpc/all/*.swi

onl-x86: ARCH=amd64
onl-x86: all-components swi installer
	@echo "##############################################"
	@echo "################     DONE     ################"
	@echo "##############################################"
	@export ONL=`pwd` && ls -l $$ONL/builds/installer/amd64/all/*.installer \
	    $$ONL/builds/swi/amd64/all/*.swi

onl-kvm: ARCH=i386
onl-kvm: all-components swi kvm-loader kvm-iso
	@echo "##############################################"
	@echo "################     DONE     ################"
	@echo "##############################################"
	@export ONL=`pwd` && ls -l $$ONL/builds/kvm/i386/onl/*.iso \
	    $$ONL/builds/swi/i386/all/*.swi

############################################################
#
# Build each of the underlying components
#
############################################################
all-components:
	export ONL=`pwd` && make -C $$ONL/builds/components

installer:
	export ONL=`pwd` && make -C $$ONL/builds/installer/$(ARCH)/all
swi:
	export ONL=`pwd` && make -C $$ONL/builds/swi/$(ARCH)/all

kvm-loader:
	export ONL=`pwd` && make -C $$ONL/builds/kvm/i386/loader
kvm-iso:
	export ONL=`pwd` && make -C $$ONL/builds/kvm/i386/onl


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

