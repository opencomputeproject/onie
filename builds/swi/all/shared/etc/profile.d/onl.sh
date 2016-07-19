# Add platform specific directories to path

dir=/lib/platform-config/`cat /etc/onl_platform`

if [ "`id -u`" -eq 0 ]; then
    PATH="$PATH:$dir/bin:$dir/sbin"
else
    PATH="$PATH:$dir/bin"
fi
export PATH
