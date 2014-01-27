#!/bin/sh

### BEGIN INIT INFO
# Provides:        rc.boot
# Required-Start:  initdev
# Required-Stop:   
# Default-Start:   S
# Default-Stop:    
# Short-Description: Run rc.boot init script from flash or SWI
### END INIT INFO

. /lib/lsb/init-functions

cat /etc/onl_version >/etc/issue
echo >>/etc/issue
logger -t rc.boot </etc/onl_version

if [ -x /etc/onl_rc.boot ]; then
    log_action_begin_msg "Executing rc.boot from SWI"
    /etc/onl_rc.boot >/var/log/rc.boot 2>&1
    log_action_end_msg $?
elif [ -x /mnt/flash/rc.boot ]; then
    log_action_begin_msg "Executing flash:rc.boot"
    /mnt/flash/rc.boot >/var/log/rc.boot 2>&1
    log_action_end_msg $?
fi
