FOLDERS_x86_64  = lpc_i2c/
FOLDERS_x86     = $(FOLDERS_x86_64)

obj-y := $(FOLDERS_$(ARCH))

ifneq ($(ARCH),)
ifeq ($(obj-y),)
$(error Unsupported ARCH: $(ARCH))
endif
endif
