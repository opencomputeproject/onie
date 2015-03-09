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

ifndef ONL
$(error $$ONL is undefined.)
endif

#
# These are the local packages that must be build
# for this SWI configuration, based on the required platforms.
#
include platforms.mk
ONL_REQUIRED_PACKAGES := $(foreach p,$(INSTALLER_PLATFORMS),platform-config-$(p):all)

include $(ONL)/make/component.mk


