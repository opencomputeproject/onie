#!/bin/sh

#  Copyright (C) 2013 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0

. /lib/demo/machine.conf
. /lib/demo/platform.conf
. /lib/demo/functions

demo_import_cmdline

if [ -n "$demo_menu_entry_no" ] ; then
    echo "Welcome to the $machine DEMO ${demo_type} platform #${demo_menu_entry_no}." > /etc/issue
    echo "Welcome to the $machine DEMO ${demo_type} platform #${demo_menu_entry_no}." > /dev/console
else
    echo "Welcome to the $machine DEMO $demo_type platform." > /etc/issue
    echo "Welcome to the $machine DEMO $demo_type platform." > /dev/console
fi
