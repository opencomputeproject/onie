#!/bin/sh

# Parameters
prog=$(basename $0)
fw_opt=$1
## fw_opt_lc is the lowercase expression of fw_opt
fw_opt_lc=$(echo ${fw_opt} | tr '[A-Z]' '[a-z]')
fw_img=$2
fw_img_ver=$3
sku=$4

echo "Upgrading CPLD Firmware ..."

# TODO


echo "${fw_opt} firmware install successful"
exit 0
