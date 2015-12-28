############################################################
# <bsn.cl fy=2013 v=none>
#
#        Copyright 2013, 2014 BigSwitch Networks, Inc.
#        Copyright 2015 Interface Masters Technologies, Inc.
#
# </bsn.cl>
############################################################

# Default platform detection.
# IMT uses one ONIE platform id for many devices.
# Detection is based on Manufacturer ID or on specific CPU boards
# if empty system info.

sys_man="`dmidecode -s system-manufacturer 2>&1 || :`"
sys_prod="`dmidecode -s system-product-name 2>&1 || :`"
sys_ver="`dmidecode -s system-version 2>&1 || :`"

case "$sys_man" in
  # New updated DMI info:
  *"Interface Masters"*)
    echo "x86-64-im-n29xx-t40n-r0" > /etc/onl_platform
    exit 0
  ;;
  # Old empty DMI info:
  *""*)

    if [ -z "$sys_prod" -a -z "$sys_ver" ]; then

        if grep -q "^model.*: AMD G-T40N Processor$" /proc/cpuinfo; then
            echo "x86-64-im-n29xx-t40n-r0" >/etc/onl_platform
            exit 0
        fi

        if grep -q "^model.*: Intel(R) Core(TM) i" /proc/cpuinfo; then
            echo "x86-64-im-n29xx-t40n-r0" >/etc/onl_platform
            exit 0
        fi

    fi

  ;;
esac

exit 1
