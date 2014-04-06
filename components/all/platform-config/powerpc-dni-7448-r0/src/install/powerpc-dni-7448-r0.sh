############################################################
# <bsn.cl fy=2013 v=onl>
#
#        Copyright 2013, 2014 BigSwitch Networks, Inc.
#
#
#
# </bsn.cl>
############################################################
#
# Installer scriptlet for the DNI 7448.
#

platform_bootcmd='mmc part 0; fatload mmc 0:1 0x10000000 onl-loader; setenv bootargs console=$consoledev,$baudrate onl_platform=powerpc-dni-7448-r0; bootm 0x10000000'

platform_installer() {
    # Standard installation on the CF card.
    installer_standard_blockdev_install mmcblk0 16M 64M ""
}
