ifndef ONL
$(error $$ONL is undefined.)
endif
ifndef ARCH
$(error $$ARCH is undefined.)
endif

ONL_REQUIRED_SUBMODULES := ofdpa-2.0-closed
#ONL_REQUIRED_PACKAGES := onlp-platform:$(ARCH) onlp-platform-defaults:$(ARCH)
ONL_REQUIRED_PACKAGES := kernel-85xx-headers:powerpc

include $(ONL)/make/component.mk
