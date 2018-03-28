#!/bin/sh

cat /etc/machine-build.conf > /etc/machine.conf

if [ -s /etc/machine-live.conf ] ; then
    cat /etc/machine-live.conf >> /etc/machine.conf
    sed -i '/Runtime/d' /etc/machine.conf
fi

exit 0
