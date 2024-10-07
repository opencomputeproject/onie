#!/bin/sh 

link_10g_raw() {
    epdm_cli reg set 0 1 0xc8d9 0x10   > /dev/null
    epdm_cli reg set 0 1 0xc8d8 0x4602 > /dev/null
    epdm_cli reg set 0 1 0xc8d8 0x4682 > /dev/null
    epdm_cli reg set 0 1 0x0000 0xa040 > /dev/null
}

link_1g_raw() {
    epdm_cli reg set 0 1 0xc8d9 0x10   > /dev/null
    epdm_cli reg set 0 1 0xc8d8 0x01   > /dev/null
    epdm_cli reg set 0 1 0xc8d8 0x81   > /dev/null
    epdm_cli reg set 0 1 0x0000 0xa040 > /dev/null
}

link_10g() {
    timeout -t 30 epdm_cli init auto 10g > /tmp/phy_init.log
    if [ $? != 0 ];then
        echo "ERROR: link_10g failed"
    fi
}

link_1g() {
    timeout -t 30 epdm_cli init auto 1g > /tmp/phy_init.log
    if [ $? != 0 ];then
        echo "ERROR: link_1g failed"
    fi
}



if [ $# != 1 ]; then
    echo "Usage: link_phy_BCM82752.sh [1g|10g]"
    exit 1
fi

if [ ! -x "/bin/epdm_cli" ]; then
    echo "Ufi: Missing epdm_cli tool"
    exit 1
fi

if [ "$1" = "10g" ]; then
    echo "Ufi: Enabling 10G for KR PHY ..."
    link_10g
elif [ "$1" = "1g" ]; then
    link_1g
    echo "Ufi: Enabling 1G for KR PHY ..."
else
    echo "Usage: link_phy_BCM82752.sh [1g|10g]"
    exit 1
fi

