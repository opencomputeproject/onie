ifndef ONL
$(error $$ONL is undefined.)
endif
ifndef ARCH
$(error $$ARCH is undefined.)
endif

# if we have access to the closed source, then check it out
ifdef $(ONL_CLOSED_SOURCE)
ONL_REQUIRED_SUBMODULES := ofdpa-2.0-closed
ONL_REQUIRED_PACKAGES := kernel-85xx-headers:powerpc
# else nothing
endif

include $(ONL)/make/component.mk
