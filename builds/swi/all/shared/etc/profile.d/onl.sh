# Add platform specific directories to path

dir=/lib/platform/`cat /etc/onl_platform`

if [ "`id -u`" -eq 0 ]; then
    PATH="$PATH:$dir/bin"
else
    PATH="$PATH:$dir/bin:$dir/sbin"
fi
export PATH
