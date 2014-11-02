# Default platform detection.
if grep -q "^model.*: powerpc-accton-as5710-54x-r0$" /proc/cpuinfo; then
    echo "powerpc-accton-as5710-54x-r0" >/etc/onl_platform
    exit 0
else
    exit 1
fi

