#!/bin/sh

#  Copyright (C) 2013 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

. /lib/demo/machine.conf
. /lib/demo/platform.conf
. /lib/demo/functions

demo_type=$(demo_type_get)

echo "Welcome to the $machine DEMO $demo_type platform." > /etc/issue

echo "Welcome to the $machine DEMO $demo_type platform." > /dev/console
