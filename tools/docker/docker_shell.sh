#!/bin/sh

# This is the list of things to run when starting docker

# Start the local apt caching daemon
/etc/init.d/apt-cacher-ng start

# Create an account with the calling UID and add it to sudo
if [ ! -z $MAKE_USER ] ; then
    useradd $MAKE_USER --uid $MAKE_UID -m
    echo "$MAKE_USER     ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
    chown $MAKE_USER:$MAKE_USER /home/$MAKE_USER /root       # make sure we can write to home dir
    sudo -u $MAKE_USER ONL=$ONL bash
else
    bash
fi

