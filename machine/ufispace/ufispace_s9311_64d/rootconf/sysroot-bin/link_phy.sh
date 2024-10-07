#!/bin/sh 
if [ ! -x "/bin/epdm_cli" ]; then
    echo "Ufi: Missing epdm_cli tool"
    exit 1
fi


timeout -t 90 epdm_cli init all > /tmp/phy_init.log
if [ $? != 0 ];then
    echo "ERROR: PHY init timeouted"
    exit 1
fi

exit 0
