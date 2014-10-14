#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines compiler and linker options
# for building the user space tools.
#
# Note: The kernel and u-boot do not use these options.
#

export ONIE_CPPFLAGS	= --sysroot=$(DEV_SYSROOT)
export ONIE_CFLAGS	= -Os $(ONIE_CPPFLAGS)
export ONIE_CXXFLAGS	= -Os $(ONIE_CPPFLAGS)
export ONIE_LDFLAGS	= --sysroot=$(DEV_SYSROOT)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
