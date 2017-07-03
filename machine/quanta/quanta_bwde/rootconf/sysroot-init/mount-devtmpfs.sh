#!/bin/sh
echo "Mounting devtmpfs..."
mount -t devtmpfs devtmpfs /dev
mkdir /dev/pts
mount -t devpts devpts /dev/pts
echo "Mount devtmpfs done..."

