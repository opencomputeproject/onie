# Default platform detection.
if grep -q "^model.*: powerpc-as5710-54x-r0b$" /proc/cpuinfo; then
    echo "powerpc-as5710-54x-r0b" >/etc/onl_platform
    exit 0
else
    exit 1
fi

