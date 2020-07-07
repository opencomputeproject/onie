#!/bin/sh

# Detect and set Mux channel
probe=$(i2cdetect -y 0 | grep 77)
if [ -n "$probe" ]; then
    i2cget -y 0 0x77 0x4
fi

probe=$(i2cdetect -y 0 | grep 41)
if [ -z "$probe" ]; then
    echo "CPLD not found." > /dev/kmsg
    exit 0
else
    boardid=$(i2cget -y 0 0x41 0x01)
    case ${boardid} in
    "0x0a")
    	echo "Board TN48M" > /dev/kmsg
        ;;
    "0x0b")
        echo "Board TN48M-P" > /dev/kmsg
        sed -i 's/tn48m-r0/tn48m_poe-r0/g' /etc/machine.conf
        ;;
    "0x0c")
        echo "Board TN4810M" > /dev/kmsg
        sed -i 's/tn48m-r0/tn4810m-r0/g' /etc/machine.conf
        ;;
    "0x0d")
        echo "Board TN48M2" > /dev/kmsg
        sed -i 's/tn48m-r0/tn48m2-r0/g' /etc/machine.conf
        ;;
    *)
        echo "Unkown Board Type." > /dev/kmsg
        ;;
    esac
fi
