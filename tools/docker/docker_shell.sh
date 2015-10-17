#!/bin/sh

# This is the list of things to run when starting docker

# Start the local apt caching daemon
/etc/init.d/apt-cacher-ng start

# Create an account with the calling UID and add it to sudo
if [ ! -z $MAKE_USER ] ; then
    useradd $MAKE_USER --uid $MAKE_UID
    echo "$MAKE_USER     ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
    exec sudo -u $MAKE_USER -s
else
    exec bash
fi

