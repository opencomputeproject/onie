# Default platform detection.
if grep -q "^model.*: powerpc-as5710-54x-r0a$" /proc/cpuinfo; then
    echo "powerpc-as5710-54x-r0a" >/etc/onl_platform
    exit 0
else
    exit 1
fi

