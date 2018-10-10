#!/bin/sh

#  Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

MEM=1024
DISK="$HOME/kvm/onie-x86-demo.img"

# Path to ONIE installer .iso image
CDROM="$HOME/kvm/onie-recovery-x86_64-kvm_x86_64-r0.iso"

# Path to OVMF firmware for qemu
# Download OVMF from http://www.tianocore.org/ovmf/
OVMF="$HOME/kvm/OVMF.fd"

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

# set firmware=uefi to boot with UEFI firmware, otherwise the system
# will boot into legacy mode.
firmware=uefi

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

if [ "$firmware" = "uefi" ] ; then
    [ -r "$OVMF" ] || {
        echo "ERROR:  Cannot find the OVMF firmware for UEFI: $OVMF"
        echo "Please make sure to install the OVMF.fd in the expected directory"
        exit 1
    }
    bios="-bios $OVMF"
fi

sudo /usr/bin/kvm -m $MEM \
    -name "onie" \
    $bios \
    -boot $boot $cdrom \
    -device e1000,netdev=onienet \
    -netdev user,id=onienet,hostfwd=:0.0.0.0:3040-:22 \
    -vnc 0.0.0.0:$VNC_PORT \
    -vga std \
    -drive file=$DISK,media=disk,if=virtio,index=0 \
    -serial telnet:localhost:$KVM_PORT,server > $kvm_log 2>&1 &

kvm_pid=$!

sleep 1.0

[ -d "/proc/$kvm_pid" ] || {
        echo "ERROR: kvm died."
        cat $kvm_log
        exit 1
}

telnet localhost $KVM_PORT

echo "to kill kvm:  sudo kill $kvm_pid"

exit 0
