#!/bin/sh

VM_NAME=onie-x86-test
MEM=1024
DISK="$HOME/kvm/onie-x86-demo.img,bus=virtio"

sudo virt-install -n $VM_NAME -r $MEM \
--import --disk path="$DISK" \
--accelerate --network bridge=br0,model=e1000 \
--connect=qemu:///system --noautoconsole --vnc --hvm
