#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines compiler and linker options
# for building the user space tools.
#
# Note: The kernel and u-boot do not use these options.
#

ONIE_CFLAGS	= -Os --sysroot=$(DEV_SYSROOT)
ONIE_LDFLAGS	= --sysroot=$(DEV_SYSROOT)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
