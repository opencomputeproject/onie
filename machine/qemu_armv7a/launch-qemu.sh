#!/bin/sh

#  Copyright (C) 2014,2015 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

QEMU_PATH="${QEMU_PATH:=/opt/qemu-2.4.0/bin}"
[ -x "$QEMU_PATH/qemu-system-arm" ] || {
    echo "Error: Unable to find qemu-system-arm in QEMU_PATH: $QEMU_PATH"
    exit 1
}

IMAGE_DIR="$1"

usage() {
    echo
    echo "Usage: $0"
    echo "$0: <image_directory>"
    echo
    echo "<image_directory> is the path containing the ONIE build products."
    exit 1
}

[ -d "$IMAGE_DIR" ] || {
    echo "ERROR: Image directory does not exist: $IMAGE_DIR"
    usage
}

DISK_IMG="${IMAGE_DIR}/onie-qemu_armv7a-r0-sd.img"
NOR0_IMG="${IMAGE_DIR}/onie-qemu_armv7a-r0-nor0.img"
NOR1_IMG="${IMAGE_DIR}/onie-qemu_armv7a-r0-nor1.img"

[ -n "$DISK_IMG" -a -r "$DISK_IMG" ] || {
    echo "ERROR: Unable to read disk image: $DISK_IMG"
    usage
}

[ -n "$NOR0_IMG" -a -r "$NOR0_IMG" ] || {
    echo "ERROR: Unable to read NOR0 image: $NOR0_IMG"
    usage
}

[ -n "$NOR1_IMG" -a -r "$NOR1_IMG" ] || {
    echo "ERROR: Unable to read NOR1 image: $NOR1_IMG"
    usage
}

# The VM serial console is redirected via telnet to localhost port 5555.
CONSOLE=5555

# localhost port 5556 is forwarded to the VM on port 22 (ssh)
SSH=$(( $CONSOLE + 1 ))

# localhost port 5557 is forwarded to the VM on port 23 (telnet)
TELNET=$(( $SSH + 1 ))

echo "console listening on: localhost:$CONSOLE"
echo "ssh listening on    : localhost:$SSH"
echo "telnet listening on : localhost:$TELNET"

# enable GDB support
[ -n "$GDB" ] && {
    # connect gdb to the VM using localhost port 5558
    GDB_PORT=$(( $TELNET + 1 ))
    GDB="-gdb tcp::$GDB_PORT -S"
    echo "connect gdb to localhost port $GDB_PORT"
}

PATH=${QEMU_PATH}:$PATH qemu-system-arm \
    -M vexpress-a9 \
    -cpu cortex-a9 \
    -m 1024M \
    -drive "if=sd,format=raw,file=$DISK_IMG" \
    -drive "if=pflash,format=raw,file=$NOR0_IMG" \
    -drive "if=pflash,format=raw,file=$NOR1_IMG" \
    $GDB \
    -redir tcp:$SSH::22 \
    -redir tcp:$TELNET::23 \
    -nographic \
    -serial telnet:localhost:$CONSOLE,server

# add -tftp option to redirect tftp to a localhost directory.  Useful
# for using tftp from U-Boot:
#
#    -tftp /work/curt/build/onie/build/images
