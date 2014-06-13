#!/bin/sh

. /lib/demo/machine.conf
. /lib/demo/platform.conf
. /lib/demo/functions

demo_type=$(demo_type_get)

echo "Welcome to the $machine DEMO $demo_type platform." > /etc/issue

echo "Welcome to the $machine DEMO $demo_type platform." > /dev/console
