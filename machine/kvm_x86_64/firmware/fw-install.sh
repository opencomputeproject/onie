#!/bin/sh

#
# Copyright (C) 2016 Curt Brune <curt@cumulusnetworks.com>
#
# SPDX-License-Identifier:     GPL-2.0
#

# Demonstration of firmware update install script

# This script is the entry point of the of the ONIE firmware update
# mechanism.

# A machine uses this script to update "firmware", such as:
# - update BIOS
# - update CPLDs

# Simulate updating the BIOS
echo -n "Updating BIOS "
bios/update_bios.sh || {
    echo "ERROR: Problems updating the BIOS"
    exit 1
}
echo " done."

# Simulate updating CPLDs
for cpld in $(seq 1 3) ; do
    echo -n "Updating CPLD $cpld "
    cpld/update_cpld.sh || {
        echo "ERROR: Problems updating CPLD $cpld"
        exit 1
    }
    echo " done."
done

# No errors detected
echo "Update complete.  No errors detected."
exit 0
