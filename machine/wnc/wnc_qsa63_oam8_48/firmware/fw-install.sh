#!/bin/sh

prog=$(basename $0)

# Firmware install config file
fw_conf="fw-install.conf"
if [ ! -r "${fw_conf}" ]; then
    echo "ERROR ${prog}: Firmware install config file ${fw_conf} does not exist"
    exit 1
fi

## check main board sku
#platform=`/usr/bin/onie-syseeprom -g 0x21`
#if [ "$platform" = "QSD61-AOM-A-48" ]; then
#	sku="10G"
#elif [ "$platform" = "QSA72-AOM-A-48P" ]; then
#	sku="48P"
#elif [ "$platform" = "QSA62-AOM-A-48" ]; then
#	sku="48T"
#else
#	echo "ERROR ${prog}: can not main board sku"
#    exit 1
#fi

# Firmware install sequence
fw_seq=$(grep "Firmware install sequence" ${fw_conf} | awk -F": " '{print $2}')
if [ -z "${fw_seq}" ]; then
    echo "ERROR ${prog}: Firmware install sequence does not exist"
    exit 1
fi

# Install specified firmware option in firmware install sequence
fw_install_opt()
{
    local install_opt=$1
    # install_opt_lc is the lowercase expression of install_opt
	local install_opt_lc=$(echo ${install_opt} | tr '[A-Z]' '[a-z]')
	local fw_img=$(ls ./fw_install_${install_opt_lc}/fw-img*)
	local fw_img_ver=$(echo ${fw_img%.*} | cut -d '-' -f 4 | cut -d '.' -f 1 )

    echo "INFO ${prog}: Enter Install ${install_opt} Firmware Mode ..."
    echo "INFO ${prog}: Install Firmware File: ${fw_img} "
    
    # Firmware image, update differnet cpld firmware with differnet sku
	#if [ "${install_opt}" = "A7KCPLD" ]; then
	#    fw_img=$(ls ./fw_install_${install_opt_lc}/fw-img-${sku}*)
	#else
	#    fw_img=$(ls ./fw_install_${install_opt_lc}/fw-img*)
	#fi
    #if [ ! -r "${fw_img}" ]; then
    #    echo "ERROR ${prog}: Firmware image ${fw_img} does not exist"
    #    return 1
    #fi
    
    # Firmware image version
	#if [ "${install_opt}" = "A7KCPLD" ]; then
	#    fw_img_ver=$(echo ${fw_img%.*} | cut -d '-' -f 5)
	#elif [ "${install_opt}" = "A385ROOTFS" ]; then
	#    fw_img_ver=$(echo ${fw_img%.*} | cut -d '-' -f 4,5,6)
	#else
	#    fw_img_ver=$(echo ${fw_img%.*} | cut -d '-' -f 4)
	#fi
    #if [ -z "${fw_img_ver}" ]; then
    #    echo "ERROR ${prog}: Firmware image version does not exist"
    #    return 1
    #fi

    # Execute firmware install script
    if [ ! -x "./fw_install_${install_opt_lc}/fw-install-${install_opt_lc}.sh" ]; then
        echo "ERROR ${prog}: Firmware install script fw-install-${install_opt_lc}.sh does not exist"
        return 1
    fi
    ./fw_install_${install_opt_lc}/fw-install-${install_opt_lc}.sh "${install_opt}" "${fw_img}" "${fw_img_ver}" 
    if [ $? -ne 0 ]; then
        echo "ERROR ${prog}: ${install_opt} firmware install failed"
        return 1
    fi

    return 0
}

# Install specified firmware options
if [ $# -eq 0 ]; then
    # Install all firmware options in firmware install sequence
    for fw_opt in ${fw_seq}
    do
        fw_install_opt "${fw_opt}"
        if [ $? -ne 0 ]; then
            echo "ERROR ${prog}: ${fw_opt} firmware install failed"
            exit 1
        fi
    done
else
    # Install firmware options specified in input parameters
    for opt in $@
    do
        # Check if specified firmware option is in firmware install sequence
        for fw_opt in ${fw_seq}
        do
            # fw_opt_lc is the lowercase expression of fw_opt
            fw_opt_lc=$(echo ${fw_opt} | tr '[A-Z]' '[a-z]')
            if [ "${opt}" = "${fw_opt}" ] || [ "${opt}" = "${fw_opt_lc}" ]; then
                # Install specified firmware option in firmware install sequence
                fw_install_opt "${fw_opt}"
                if [ $? -ne 0 ]; then
                    echo "ERROR ${prog}: ${fw_opt} firmware install failed"
                    exit 1
                fi
            fi
        done
    done
fi

exit 0
