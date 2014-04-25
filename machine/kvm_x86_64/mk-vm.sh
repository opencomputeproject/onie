#!/bin/sh

MEM=1024
DISK="$HOME/kvm/onie-x86-demo.img"

# Path to ONIE installer .iso image
CDROM="$HOME/kvm/onie-recovery-x86_64-kvm_x86_64-r0.iso"

# VM will listen on telnet port $KVM_PORT
KVM_PORT=9000

# VNC display to use
VNC_PORT=0

# set mode=disk to boot from hard disk
# mode=disk

# set mode=cdrom to boot from the CDROM
mode=cdrom

# set mode=net to boot from network adapters
# mode=net

on_exit()
{
    rm -f $kvm_log
}

kvm_log=$(mktemp)
trap on_exit EXIT

boot=c
if [ "$mode" = "cdrom" ] ; then
    boot="order=cd,once=d"
    cdrom="-cdrom $CDROM"
elif [ "$mode" = "net" ] ; then
    boot="order=cd,once=n,menu=on"
fi

sudo /usr/bin/kvm -m $MEM \
    -name "onie" \
    -boot $boot $cdrom \
    -net nic,model=e1000 \
    -net tap,ifname=onie0 \
    -vnc 0.0.0.0:$VNC_PORT \
    -vga std \
    -drive file=$DISK,media=disk,if=virtio,index=0 \
    -serial telnet:localhost:$KVM_PORT,server > $kvm_log 2>&1 &

kvm_pid=$!

sleep 0.5

[ -d "/proc/$kvm_pid" ] || {
        echo "ERROR: kvm died."
        cat $kvm_log
        exit 1
}

telnet localhost $KVM_PORT

echo "to kill kvm:  sudo kill $kvm_pid"

exit 0
