#!/bin/sh
if [ -f /.pandora-ws ]; then
    #
    # If building in an ONL workspace the apt-cacher is accessed through the isolation network.
    #
    echo "10.198.0.0:3142/"
else
    #
    # Native build environment uses local apt-cacher
    #
    echo "127.0.0.1:3142/"
fi

