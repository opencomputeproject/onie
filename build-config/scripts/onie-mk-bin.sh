#!/bin/sh

#  Copyright (C) 2013,2015 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

set -e

#
# Script to create the raw ONIE binaries, suitable for flashing
# directly from u-boot.
#

machine=$1
image_dir=$2
conf_dir=$3
uboot_src=$4
output_bin=$5

onie_uimage_size=no
contiguous=no
conf_file="$conf_dir/onie-rom.conf"
[ -r "$conf_file" ] || {
    echo "ERROR: unable to read machine ROM configuration '$conf_file'."
    exit 1
}

# Most platforms have a max uImage size of 4MB.  You can override this
# in the platform specific conf file.
uimage_max_size=$(( 4 * 1024 * 1024 ))

# Most platforms have a max u-boot size of 512KB.  You can override
# this in the platform specific conf file.
uboot_max_size=$(( 512 * 1024 ))

. $conf_file

[ -d "$image_dir" ] || {
    echo "ERROR: image directory '$image_dir' does not exist."
    exit 1
}

onie_uimage="$image_dir/${machine}.itb"
[ -r "$onie_uimage" ] || {
    echo "ERROR: onie-uImage '$onie_uimage' does not exist."
    exit 1
}

uimage_size=$(stat -c '%s' $onie_uimage)
if [ $uimage_size -gt $uimage_max_size ] ; then
    printf "ERROR: $onie_uimage size (%d) is greater than max size: %d\n" $uimage_size $uimage_max_size
    exit 1
fi

UBOOT_BIN="$image_dir/${machine}.u-boot"
[ -r "$UBOOT_BIN" ] || {
    echo "ERROR: u-boot binary '$UBOOT_BIN' does not exist."
    exit 1
}

uboot_size=$(stat -c '%s' $UBOOT_BIN)
if [ $uboot_size -gt $uboot_max_size ] ; then
    printf "ERROR: $UBOOT_BIN size (%d) is greater than max size: %d\n" $uboot_size $uboot_max_size
    exit 1
fi

# Rummage u-boot directory for onie environment variables
true ${uboot_machine="$(echo $machine | tr a-z A-Z)"}
MACHINE_CONFIG="$uboot_src/include/configs/${uboot_machine}.h"
[ -r "$MACHINE_CONFIG" ] || {
    echo "ERROR: u-boot config file '$MACHINE_CONFIG' does not exist."
    exit 1
}

if [ -z "$env_sector_size" ] ; then
    # try to figure it out from the $MACHINE_CONIFG
    env_sector_size=$(grep CONFIG_ENV_SECT_SIZE $MACHINE_CONFIG | awk '{print $3}')
fi

env_sector_size=$(( $env_sector_size + 0 ))
if [ "$env_sector_size" = "" ] || [ "$env_sector_size" = "0" ] ; then
    echo "ERROR: Unable to find #define CONFIG_ENV_SECT_SIZE in $MACHINE_CONFIG."
    exit 1
fi

onie_uimage_size=$(grep onie_sz.b $MACHINE_CONFIG | sed -e 's/^.*=//' -e 's/\\.*$//')
onie_uimage_size=$(( $onie_uimage_size + 0 ))
if [ "$onie_uimage_size" = "" ] || [ "$onie_uimage_size" = "0" ] ; then
    echo "ERROR: Unable to find onie_sz.b $MACHINE_CONFIG."
    exit 1
fi

if [ "$format" = "contiguous" ] ; then
    # single ROM image : u-boot + env + onie-uimage
    # In increasing physical address space the order is:
    #   low : onie-uimage
    #   mid : u-boot env
    #   high: u-boot
    total_sz=$(( $onie_uimage_size + $env_sector_size ))
    pad_file=$(tempfile)
    dd if=$onie_uimage of=$pad_file ibs=$total_sz conv=sync > /dev/null 2>&1 || {
        echo "ERROR: Problems with dd for $format image"
        exit 1
    }
    cat $pad_file $UBOOT_BIN > $output_bin
    rm -f $pad_file
elif [ "$format" = "contiguous-up" ] ; then
    # single ROM image : u-boot + env + onie-uimage
    # In increasing physical address space the order is:
    #   low : u-boot
    #   mid : u-boot env
    #   high: onie-uimage
    # Pad U-Boot to uboot_max_size.
    total_sz=$(( $onie_uimage_size + $env_sector_size ))
    dd if=$UBOOT_BIN of=$output_bin ibs=$uboot_max_size conv=sync > /dev/null 2>&1 || {
        echo "ERROR: Problems with dd for $format image"
        exit 1
    }
    head --bytes=$env_sector_size /dev/zero >> $output_bin
    cat $onie_uimage >> $output_bin
elif [ "$format" = "ubootenv_onie" ] ; then
    # discontinuous ROM -- emit u-boot separately from u-boot-env + onie-uimage
    # "Accton 5652 Format"
    total_sz=$(( $onie_uimage_size + $env_sector_size ))
    dd if=$onie_uimage of=$output_bin ibs=$total_sz conv=sync > /dev/null 2>&1 || {
        echo "ERROR: Problems with dd for $format image"
        exit 1
    }
    cp $UBOOT_BIN ${output_bin}.uboot
elif [ "$format" = "uboot_ubootenv" ] ; then
    # discontinuous ROM -- emit u-boot+env separately from onie-uimage
    # In increasing physical address space the order of u-boot+env is:
    #   low : u-boot env
    #   high: u-boot
    cp $onie_uimage $output_bin
    pad_file=$(tempfile)
    dd if=/dev/zero of=$pad_file bs=$env_sector_size count=1 > /dev/null 2>&1 || {
        echo "ERROR: Problems with dd for $format image"
        exit 1
    }
    cat $pad_file $UBOOT_BIN > ${output_bin}.uboot+env
    rm -f $pad_file
elif [ "$format" = "uboot_ubootenv-up" ] ; then
    # discontinuous ROM -- emit u-boot+env separately from onie-uimage
    # In increasing physical address space the order of u-boot+env is:
    #   low : u-boot
    #   high: u-boot env
    cp $onie_uimage $output_bin
    pad_file=$(tempfile)
    dd if=/dev/zero of=$pad_file bs=$env_sector_size count=1 > /dev/null 2>&1 || {
        echo "ERROR: Problems with dd for $format image"
        exit 1
    }
    cat $UBOOT_BIN $pad_file > ${output_bin}.uboot+env
    rm -f $pad_file
elif [ "$format" = "contiguous-onie_uboot" ] ; then
    # No ubootenv included. It's in a separate piece of flash and we'd end up creating a
    # giant image if we included it.
    # Instead include instructions on wiping the env in the install details
    #   low : onie 
    #   high: u-boot
    pad_file=$(tempfile)
    dd if=$onie_uimage of=$pad_file ibs=$onie_uimage_size conv=sync > /dev/null 2>&1 || {
        echo "ERROR: Problems with dd for $format image"
        exit 1
    }
    cat $pad_file $UBOOT_BIN > $output_bin
    rm -f $pad_file
else
    echo "ERROR: Unknown ROM format '$format'."
    exit 1
fi
