#!/bin/sh

#  Copyright (C) 2015 Carlos Cardenas <carlos@cumulusnetworks.com>
#
#  SPDX-License-Identifier:    GPL-2.0

. /lib/onie/functions
if [ -f /lib/onie/onie-blkdev-common ]; then
    . /lib/onie/onie-blkdev-common
fi

efi_check_dir=/sys/firmware/efi/efivars
mtree_bin=/usr/bin/mtree
mtree_dir=/mnt/onie-boot/onie/config/etc/mtree
this_script=$(basename $(realpath $0))
args="c:d:m:hqv"

usage()
{
    echo "usage: $this_script [-c COMMAND] [OPTIONS]"
    cat <<EOF
Test to see if ONIE has been altered by a NOS function (install, uninstall).
The default COMMAND is to perform 'check'.

COMMAND LINE OPTIONS

        -c
                Perform the following command.  Available commands are:

                check  -- Perform Check (default)
                init   -- Perform Initialization

        -d
                Use the following directory as the location to store the
                mtree index files. (default: $mtree_dir)

        -h
                Help.  Print this message.

        -m
                Use the following mtree binary.
                (default: $mtree_bin)

	-q
		Quiet.  No printing, except for errors.

	-v
		Be verbose.  Print what is happening.
EOF
}

create_mtree_dir()
{
    local dir="$1"
    local verbose="$2"
    [ "$verbose" = "yes" ] && echo "Create mtree directory: $dir"
    if [ -d "$dir" ] ; then
        [ "$verbose" = "yes" ] && echo "mtree directory: $dir exists"
    else
        mkdir -p $dir
        [ "$verbose" = "yes" ] && echo "mtree directory: $dir created"
    fi
}

create_mtree_index()
{
    local dir="$1"
    local verbose="$2"
    local dirs="/lib/onie /bin /sbin /usr/bin /usr/sbin"
    # if x86, add other dirs
    if [ -n "$onie_arch" ]; then
        if [ "$onie_arch" = "x86_64" ]; then
            dirs="$dirs /mnt/onie-boot/grub"
        fi
    fi
    for d in $dirs; do
        local suffix=$(echo $d | sed -e 's/\//./g')
        local file="ONIE$suffix"
        [ "$verbose" = "yes" ] && echo "Creating index for: $d"
        $mtree_bin -c -p $d > "$dir/$file"
    done
}

check_mtree_index()
{
    local dir="$1"
    local verbose="$2"
    if [ ! -d $dir ]; then
        echo "mtree directory is not found..."
        exit 1
    fi
    for f in $(ls $dir); do
        local path=$(echo $f | sed -e 's/^ONIE//' | sed -e 's/\./\//g')
        [ "$verbose" = "yes" ] && echo "Found index for: $path"
        $mtree_bin -f "$dir/$f" -p "$path"
    done
}

print_mass_storage()
{
    local verbose="$1"
    if [ -n "$onie_arch" ]; then
        if [ "$onie_arch" = "x86_64" ]; then
            onie_dev=onie_get_boot_dev
            blk_dev=$(echo $onie_dev | sed -e 's/[0-9]$//' | sed -e 's/\([0-9]\)\(p\)/\1/')
            if [ -d "$efi_check_dir" ]; then
                [ "$verbose" = "yes" ] && echo 
                [ "$verbose" = "yes" ] && echo "UEFI System Detected"
                [ "$verbose" = "yes" ] && echo 
                efibootmgr
            fi

            [ "$verbose" = "yes" ] && echo 
            [ "$verbose" = "yes" ] && echo "Printing all block ids"
            [ "$verbose" = "yes" ] && echo 
            blkid

            [ "$verbose" = "yes" ] && echo 
            [ "$verbose" = "yes" ] && echo "Printing Block Device Part. Table"
            [ "$verbose" = "yes" ] && echo 
            parted -l $onie_dev

            if [ "$onie_partition_type" = "gpt" ]; then
                blk_parts=$(blkid | awk '{print $1}' | sed -e 's/://')
                for p in "$blk_parts"; do
                    dev_p=$(echo $p | sed -e 's|/dev/||' | sed -e 's/\([a-z]*\)\([0-9]*\)/\1 \2/')
                    blk=$(echo $dev_p | cut -d ' ' -f 1)
                    part=$(echo $dev_p | cut -d ' ' -f 2)
                    echo "Attributes for $p"
                    sgdisk -A $part:show /dev/$blk
                done
            fi
        else #not x86_64
            # get all NOR partitions from /dev and print size
            for dev in $(ls /dev/mtd-*); do
                ls -l $dev | awk '{print $9 " " $10 " " $11}'
                fdisk -l $dev | grep -v 'partition'
            done
        fi
    fi
}

check_for_diag()
{
    local verbose="$1"
    if [ -n "$onie_arch" ]; then
        if [ "$onie_arch" = "x86_64" ]; then
            [ "$verbose" = "yes" ] && echo 
            # check for *-DIAG
            diags=$(blkid | egrep -e '-DIAG')

            if [ -z "$diags" ]; then
                echo "No Diagnostic image found"
                return 1
            fi

            if [ "$onie_partition_type" = "gpt" ]; then
                blk_parts=$(echo $diags | awk '{print $1}' | sed -e 's/://')
                for p in "$blk_parts"; do
                    dev_p=$(echo $p | sed -e 's|/dev/||' | sed -e 's/\([a-z]*\)\([0-9]*\)/\1 \2/')
                    blk=$(echo $dev_p | cut -d ' ' -f 1)
                    part=$(echo $dev_p | cut -d ' ' -f 2)

                    # if found, check partition name
                    partname=$(sgdisk -i $part /dev/$blk | grep 'Partition name')
                    partname=${partname##*: }
                    if [ $(echo "$partname" | egrep -e '-DIAG') ] ; then
                        [ "$verbose" = "yes" ] && echo "Partition name $partname is valid"
                    else
                        echo "***Partition name is incorrectly named"
                    fi

                    # if found, check attribute flags
                    attr=$(sgdisk -i $part /dev/$blk | grep 'Attribute flags')
                    attr=${attr##*: }
                    if [ "$attr" = "0000000000000001" ] ; then
                        [ "$verbose" = "yes" ] && echo "Diag $p has valid attribute flags"
                    else
                        echo "***Diag $p does not have the correct attribute flags"
                    fi
                done
            fi
        else #not x86_64
            # check for boot_diag
            ret=$(onie-env-get boot_diag 2> /dev/null)
            if [ -z $ret ]; then
                echo "No Diagnostic image found"
            else
                [ "$verbose" = "yes" ] && echo "Diagnostic image found"
            fi
        fi
    fi
}

check_for_nos()
{
    local verbose="$1"
    if [ -n "$onie_arch" ]; then
        if [ "$onie_arch" = "x86_64" ]; then
            [ "$verbose" = "yes" ] && echo 
            # ignore *-DIAG, GRUB-BOOT, ONIE-BOOT, EFI System
            nos=$(blkid | egrep -ve '-DIAG|GRUB-BOOT|ONIE-BOOT|EFI System')

            if [ -z "$nos" ]; then
                echo "No NOS found"
                return 1
            fi

            if [ "$onie_partition_type" = "gpt" ]; then
                blk_parts=$(echo $nos | awk '{print $1}' | sed -e 's/://')
                for p in "$blk_parts"; do
                    echo "NOS found on $p"
                done
            fi
        else #not x86_64
            # check for boot_diag
            ret=$(onie-env-get nos_bootcmd 2> /dev/null | cut -d '=' -f 2)
            case "$ret" in
                true|echo)
                    echo "No NOS found"
                    ;;
                *)
                    echo "NOS found"
                    ;;
            esac
        fi
    fi
}


cmd=check
quiet=no
verbose=no
while getopts "$args" a ; do
    case $a in
        h)
            usage
            exit 0
            ;;
        v)
            verbose=yes
            ;;
        c)
            cmd="$OPTARG"
            ;;
        d)
            mtree_dir="$OPTARG"
            ;;
        m)
            mtree_bin="$OPTARG"
            ;;
        q)
            quiet=yes
            ;;
        *)
            echo "Unknown argument: $a"
            usage
            exit 1
    esac
done

[ "$verbose" = "yes" ] && quiet=no

if [ ! -x "$mtree_bin" ] ; then
    echo "mtree is not found on this system"
    exit 1
fi

if [ -n "$cmd" ] ; then
    case "$cmd" in
        check)
            [ "$verbose" = "yes" ] && echo "Performing checks..."
            check_mtree_index $mtree_dir $verbose
            print_mass_storage $verbose
            check_for_diag $verbose
            check_for_nos $verbose
            ;;
        init)
            [ "$verbose" = "yes" ] && echo "Initializing..."
            create_mtree_dir $mtree_dir $verbose
            create_mtree_index $mtree_dir $verbose
            print_mass_storage $verbose
            check_for_diag $verbose
            check_for_nos $verbose
            ;;
        *)
            echo "ERROR: Unknown command: $cmd"
            exit 1
    esac
fi

exit 0
