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
# Component Makefile
#
# Allow dependency resolution prior to actual component build.
#
############################################################
include $(ONL)/make/config.mk

ifndef MAX_PARALLEL_MAKES
MAX_PARALLEL_MAKES=8
endif

ifndef NOT_PARALLEL
ONL_MAKE_PARALLEL := -j $(MAX_PARALLEL_MAKES)
endif

component: component-deps
	$(ONL_V_at)$(MAKE) -f Makefile.comp $(ONL_MAKE_PARALLEL) $(ONL_MAKEFLAGS)

deb: component-deps
	$(ONL_V_at)$(MAKE) -f Makefile.comp deb $(ONL_MAKE_PARALLEL) $(ONL_MAKEFLAGS)

clean:
	$(ONL_V_at)$(ONL_PKG_INSTALL) $(ONL_REQUIRED_PACKAGES) --clean
	$(ONL_V_at)$(MAKE) -f Makefile.comp clean $(ONL_MAKEFLAGS)


component-deps:
ifdef ONL_REQUIRED_SUBMODULES
	$(ONL_V_at)$(ONL)/tools/submodules.py $(ONL_REQUIRED_SUBMODULES) $(ONL_LOCAL_SUBMODULES) $(ONL)
endif
ifdef ONL_REQUIRED_PACKAGES
	$(ONL_V_at)$(ONL_PKG_INSTALL) $(ONL_REQUIRED_PACKAGES) --build
endif
