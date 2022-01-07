#!/bin/sh

# Parameters
prog=$(basename $0)
fw_opt=$1
## fw_opt_lc is the lowercase expression of fw_opt
fw_opt_lc=$(echo ${fw_opt} | tr '[A-Z]' '[a-z]')
fw_img=$2
fw_img_ver=$3
sku=$4

fw_cur_ver=$(fw_printenv | grep "ver=" | cut -c 5-55)

# Firmware install execution
## Execute firmware installation with firmware install utility
fw_install_exe()
{
    local fw_install_img=$1
    echo "INFO ${prog}: Installing U-boot"
    # TODO Action for Installing U-boot
    flashcp -v ${fw_img} /dev/mtd2

    return $?
}

# Install optional firmware
## Install firmware if current firmware version is not the same as installing firmware version
echo "INFO ${prog}: Current    ${fw_opt} Firmware version: ${fw_cur_ver}"
echo "INFO ${prog}: Installing ${fw_opt} firmware version: ${fw_img_ver}"
if [ "${fw_img_ver}" != "${fw_curr_ver}" ]; then
    fw_install_exe "${fw_img}"
    if [ $? -ne 0 ]; then
        echo "ERROR ${prog}: Install ${fw_opt} firmware ${fw_img} failed"
        exit 1
    fi
else
    echo "Current ${fw_opt} firmware version is the same as installing firmware version"
    echo "Skip ${fw_opt} firmware installation"
    exit 0
fi

echo "${fw_opt} firmware install successful"
exit 0
