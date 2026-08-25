#!/bin/sh

#  Copyright (C) 2016 Audi Hsu <audi.hsu@quantatw.com>
#
#  SPDX-License-Identifier:     GPL-2.0

##
## redirect console_log_file and tee_log_file to /dev/console
##

. /lib/onie/functions

touch $console_log_file && /usr/bin/tail -f $console_log_file > /dev/console &
touch $tee_log_file && /usr/bin/tail -f $tee_log_file > /dev/console &
