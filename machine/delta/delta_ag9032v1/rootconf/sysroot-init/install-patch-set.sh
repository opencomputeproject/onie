#!/bin/sh
. /etc/machine.conf

#Use machine-build.conf in place of machine.conf, because ONL install need machine.conf rather than machine-build.conf.
if [ -r /etc/machine.conf ]; then
    cp -a /etc/machine.conf /etc/machine.conf_backup
    cat /etc/machine-build.conf > /etc/machine.conf
    echo "onie_platform=$onie_platform" >> /etc/machine.conf
    echo "onie_machine=$onie_machine" >> /etc/machine.conf
    echo "mcahine.config copy ok..."
fi

#Create ~/tmp/onie-support.tar.bz2, beacause SONiC install need mv onie-support.tar.bz2 rather than  ~/tmp/onie-support-${onie_machine}.tar.bz2.
if [ -r /bin/onie-support ]; then
    MACHINE_NAME=`grep "onie_machine=" /etc/machine.conf | cut -d '=' -f 2`
    sed -i "76 a cp -a ~/tmp/onie-support-${MACHINE_NAME}.tar.bz2 ~/tmp/onie-support.tar.bz2" ~/bin/onie-support
    echo "support set ok..."
fi

