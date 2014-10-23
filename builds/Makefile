############################################################
# <bsn.cl fy=2013 v=onl>
#
#        Copyright 2013, 2014 BigSwitch Networks, Inc.
#
#
#
# </bsn.cl>
############################################################
#
# ONL Build Products
#
############################################################

.DEFAULT_GOAL = default

# All build products go here
BUILDDIR := BUILDS
ONLPKG := $(ONL)/tools/onlpkg.py

############################################################
#
# SWI Builds
#
############################################################

# These are the available SWI architectures
SWI_ARCHS := $(filter-out swi/all,$(wildcard swi/*))

# These are the available platform builds per-architecture
SWI_BUILD_PATHS := $(subst swi/,, $(foreach arch,$(SWI_ARCHS),$(wildcard $(arch)/*)))

#
# Define a build template for each platform by name and build directory
#

define swi_build_template
swi-$(1):
	$(MAKE) -C $(2)
	mkdir -p $(BUILDDIR)
	cp $(2)/onl-*-*-201*.swi $(BUILDDIR)
endef

$(foreach plat,$(SWI_BUILD_PATHS),$(eval $(call swi_build_template,$(subst /,-,$(plat)),swi/$(plat))))

# Add to ALL_SWI
ALL_SWI := $(foreach plat,$(SWI_BUILD_PATHS),swi-$(subst /,-,$(plat)))
ALL_TARGETS := $(ALL_TARGETS) $(ALL_SWI)

# Build all SWI
swi-all: $(ALL_SWI)

show-swis:
	@echo $(SWI_BUILD_PATHS)


############################################################
#
# Installer Builds
#
############################################################

# These are the available installer architectures
INST_ARCHS := $(filter-out installer/all,$(wildcard installer/*))

# These are the available installer builds per-architecture
INST_BUILD_PATHS := $(foreach arch,$(INST_ARCHS),$(wildcard $(arch)/*))

#
# Define a build template for each installer by name and build directory
#
define installer_build_template
installer-$(1):
	$(MAKE) -C $(2)
	mkdir -p $(BUILDDIR)
	cp $(2)/*.installer $(BUILDDIR)
	$(MAKE) -C $(2) clean
endef

$(foreach inst,$(INST_BUILD_PATHS),$(eval $(call installer_build_template,$(notdir $(inst)),$(inst))))

# Add to ALL_INSTALLER
ALL_INSTALLER := $(foreach inst,$(INST_BUILD_PATHS),installer-$(notdir $(inst)))
ALL_TARGETS := $(ALL_TARGETS) $(ALL_INSTALLER)

# Build all installers
installer-all: $(ALL_INSTALLER)

show-installers:
	@echo $(INST_BUILD_PATHS)



############################################################
#
# Components directory
#
############################################################
.PHONY: components

components:
	$(MAKE) -C components

ALL_TARGETS := $(ALL_TARGETS) components


# All you can eat.
all: $(ALL_TARGETS)

default: show-swis


############################################################
#
# Parallel Build Optimizations
#
############################################################
# init all submodules
submodules_init:
	$(ONL)/tools/submodules.py __all__ __all__ $(ONL)

define cbuild
$(subst :,.,$(1)): $(subst :,.,$(2))
	$(ONL)/tools/onlpkg.py $(1) --build
endef


# Hack to ensure this is build first; build SERIAL_$i before PARALLE_$i
SERIAL_0 := vendor-config-onl:all vendor-config-accton:all vendor-config-quanta:all
$(foreach c,$(SERIAL_0),$(eval $(call cbuild,$(c),submodules_init)))

# All Platform Config Packages
PARALLEL_0 := $(shell $(ONLPKG) --list platform-config-)
$(foreach c,$(PARALLEL_0),$(eval $(call cbuild,$(c),submodules_init)))

# All kernel packages
PARALLEL_1 := $(shell $(ONLPKG) --list kernel-85xx: kernel-e500mc: kernel-x86-64:)
$(foreach c,$(PARALLEL_1),$(eval $(call cbuild,$(c),$(PARALLEL_0))))

# All initrd packages
PARALLEL_2 := $(shell $(ONLPKG) --list initrd)
$(foreach c,$(PARALLEL_2),$(eval $(call cbuild,$(c),$(PARALLEL_1))))

# All platform packages
PARALLEL_3 := $(shell $(ONLPKG) --list platform-powerpc) loader-i386:i386
$(foreach c,$(PARALLEL_3),$(eval $(call cbuild,$(c),$(PARALLEL_2))))


serial0: $(subst :,.,$(SERIAL_0))
parallel0: $(subst :,.,$(PARALLEL_0))
parallel1: $(subst :,.,$(PARALLEL_1))
parallel2: $(subst :,.,$(PARALLEL_2))
parallel3: $(subst :,.,$(PARALLEL_3))
parallel-all: parallel3



