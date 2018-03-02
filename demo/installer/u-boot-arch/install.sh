#!/bin/sh

#  Copyright (C) 2014,2015 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2015 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0

set -e

cd $(dirname $0)
. ./machine.conf

echo "Demo Installer: platform: $platform"

install_uimage() {
    echo "Copying uImage to NOR flash:"
    flashcp -v demo-${platform}.itb $mtd_dev
}

hw_load() {
    echo "cp.b $img_start \$loadaddr $img_sz"
}

. ./platform.conf

install_uimage

hw_load_str="$(hw_load)"

echo "Updating U-Boot environment variables"
(cat <<EOF
hw_load $hw_load_str
copy_img echo "Loading Demo $platform image..." && run hw_load
nos_bootcmd run copy_img && setenv bootargs quiet console=\$consoledev,\$baudrate && bootm \$loadaddr
EOF
) > /tmp/env.txt

fw_setenv -f -s /tmp/env.txt

cd /

# Set NOS mode if available.  For manufacturing diag installers, you
# probably want to skip this step so that the system remains in ONIE
# "installer" mode for installing a true NOS later.
if [ -x /bin/onie-nos-mode ] ; then
    /bin/onie-nos-mode -s
fi
