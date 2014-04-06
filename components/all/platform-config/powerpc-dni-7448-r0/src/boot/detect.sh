# Default platform detection.
if grep -q "^model.*: powerpc-dni-7448-r0$" /proc/cpuinfo; then
    echo "powerpc-dni-7448-r0" >/etc/onl_platform
    exit 0
else
    exit 1
fi

