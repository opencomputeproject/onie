#!/bin/sh

#
# Copyright (C) 2016 Curt Brune <curt@cumulusnetworks.com>
#
# SPDX-License-Identifier:     GPL-2.0
#

# This is a sample place holder script for updating a machine BIOS.  A
# real BIOS update script would use a utility like flashrom.

for i in $(seq 1 10) ; do
    echo -n "."
    sleep 0.2
done

# No errors detected
exit 0
