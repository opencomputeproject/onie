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
# Powerpc Loader and Platform Package Build Rules
#
############################################################

# The kernel image must be specified:
ifndef KERNEL.BIN.GZ
$(error $$KERNEL.BIN.GZ is not set)
endif

# The initrd must be specified:
ifndef INITRD
$(error $$INITRD is not set)
endif

# The dtb must be specified:
ifndef DTB
$(error $$DTB is not set)
endif

# Platform name must be set
ifndef PLATFORM_NAME
$(error $$PLATFORM_NAME is not set)
endif

all: onl.$(PLATFORM_NAME).loader

# Rule to build the UBoot Loader Image
onl.$(PLATFORM_NAME).loader: $(KERNEL.BIN.GZ) $(INITRD) $(DTB)
	$(ONL_V_GEN)set -e ;\
	if $(ONL_V_P); then set -x; fi ;\
	f=$$(mktemp) ;\
	trap "rm -f $$f" 0 1 ;\
	mkimage -A ppc -T multi -C gzip -d $(KERNEL.BIN.GZ):$(INITRD):$(DTB) $$f ;\
	cat $$f > $@

clean:
	rm -f *.loader
