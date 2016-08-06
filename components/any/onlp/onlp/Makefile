ifndef ONL
$(error $$ONL is undefined.)
endif
ifndef ARCH
$(error $$ARCH is undefined.)
endif

ONL_REQUIRED_SUBMODULES := onlp infra
ONL_REQUIRED_PACKAGES := onlp-platform:$(ARCH) onlp-platform-defaults:$(ARCH)

include $(ONL)/make/component.mk
