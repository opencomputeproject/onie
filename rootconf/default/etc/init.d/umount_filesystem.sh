#!/bin/sh

#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2015 Doron Tsur <doront@mellanox.com>
#
#  SPDX-License-Identifier:     GPL-2.0

##
## Unmount kernel filesystems
##

echo "Info: Unmounting kernel filesystems"
/bin/umount -a -r
