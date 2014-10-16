#!/bin/sh

#  Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

. /lib/onie/functions
. /lib/demo/functions

# Mount demo filesystem
demo_mnt="/boot"

mkdir -p $demo_mnt || {
    echo "Error: Unable to create demo file system mount point: $demo_mnt"
    exit 1
}

demo_type=$(demo_type_get)
label="ONIE-DEMO-${demo_type}"

[ -n "$label" ] || {
    echo "Error: Unable to find DEMO_TYPE on kernel command line"
    exit 1
}

mount -t ext4 -o defaults LABEL=$label $demo_mnt || {
    echo "Error: Unable to mount LABEL=$label on $demo_mnt"
    exit 1
}

# Local Variables:
# mode: shell-script
# eval: (sh-set-shell "/bin/sh" t nil)
# End:
