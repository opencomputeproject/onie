#!/bin/sh

#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2015 david_yang <david_yang@accton.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# Helper script to make an .ISO image that is bootable in the
# following scenarios:
#
# - legacy BIOS CD-ROM drive
# - legacy BIOS USB thumb drive
# - UEFI CD-ROM drive
# - UEFI USB thumb drive
#
# This script takes a lot of arguments ...

set -e

# Check verbosity flag
[ "$Q" != "@" ] && set -x

# Sanity check the number of arguments
[ $# -eq 12 ] || {
    echo "ERROR: $0: Incorrect number of arguments"
    exit 1
}
ARCH=$1
RECOVERY_KERNEL=$2
RECOVERY_INITRD=$3
RECOVERY_DIR=$4
MACHINE_CONF=$5
RECOVERY_CONF_DIR=$6
GRUB_TARGET_LIB_I386_DIR=$7
GRUB_HOST_BIN_I386_DIR=$8
GRUB_TARGET_LIB_UEFI_DIR=$9
GRUB_HOST_BIN_UEFI_DIR=${10}
FIRMWARE_TYPE=${11}
RECOVERY_ISO_IMAGE=${12}

# Sanity check the arguments
[ -r "$RECOVERY_KERNEL" ] || {
    echo "ERROR: Unable to read recovery kernel image: $RECOVERY_KERNEL"
    exit 1
}
[ -r "$RECOVERY_INITRD" ] || {
    echo "ERROR: Unable to read recovery initrd image: $RECOVERY_INITRD"
    exit 1
}
[ -d "$RECOVERY_DIR" ] || {
    echo "ERROR: Recovery work directory does not exist: $RECOVERY_DIR"
    exit 1
}
[ -r "$MACHINE_CONF" ] || {
    echo "ERROR: Unable to read machine configuration file: $MACHINE_CONF"
    exit 1
}
[ -d "$RECOVERY_CONF_DIR" ] || {
    echo "ERROR: Unable to read recovery config directory: $RECOVERY_CONF_DIR"
    exit 1
}
[ -r "${GRUB_TARGET_LIB_I386_DIR}/biosdisk.mod" ] || {
    echo "ERROR: Does not look like valid GRUB i386-pc library directory: $GRUB_TARGET_LIB_I386_DIR"
    exit 1
}
[ -x "${GRUB_HOST_BIN_I386_DIR}/grub-mkimage" ] || {
    echo "ERROR: Does not look like valid GRUB i386-pc bin directory: $GRUB_HOST_BIN_I386_DIR"
    exit 1
}
if [ "$UEFI_ENABLE" = "yes" ] ; then
    [ -r "${GRUB_TARGET_LIB_UEFI_DIR}/efinet.mod" ] || {
        echo "ERROR: Does not look like valid GRUB ${ARCH}-efi library directory: $GRUB_TARGET_LIB_UEFI_DIR"
        exit 1
    }
    [ -x "${GRUB_HOST_BIN_UEFI_DIR}/grub-mkimage" ] || {
        echo "ERROR: Does not look like valid GRUB x86_64-efi bin directory: $GRUB_HOST_BIN_UEFI_DIR"
        exit 1
    }
fi
[ -r "${RECOVERY_CONF_DIR}/xorriso-options-bios.cfg" ] || {
    echo "ERROR: Unable to read xorriso options file: ${RECOVERY_CONF_DIR}/xorriso-options-bios.cfg"
    exit 1
}

[ -r "${RECOVERY_CONF_DIR}/xorriso-options-uefi.cfg" ] || {
    echo "ERROR: Unable to read xorriso options file: ${RECOVERY_CONF_DIR}/xorriso-options-uefi.cfg"
    exit 1
}

if [ "$SECURE_BOOT_ENABLE" = "yes" ] ; then
    which sbsign > /dev/null 2>&1 || {
        echo "ERROR: Unable to find sbsign utility: sbsign"
        echo "ERROR: Check that package sbsigntool is installed on your system"
        exit 1
    }
    [ -r "$SB_SHIM" ]  || {
        echo "ERROR: Unable to read secure boot signed shim image: $SB_SHIM"
        exit 1
    }
    [ -r "$ONIE_VENDOR_SECRET_KEY_PEM" ]  || {
        echo "ERROR: Unable to read ONIE_VENDOR_SECRET_KEY_PEM file: $ONIE_VENDOR_SECRET_KEY_PEM"
        exit 1
    }
    [ -r "$ONIE_VENDOR_CERT_PEM" ]  || {
        echo "ERROR: Unable to read ONIE_VENDOR_CERT_PEM file: $ONIE_VENDOR_CERT_PEM"
        exit 1
    }
fi

# Make sure a few tools are available
XORRISO=$(which xorriso) || {
    echo "ERROR: unable to find xorriso binary"
    exit 1
}
MKDOSFS=$(which mkdosfs) || {
    echo "ERROR: unable to find mkdosfs binary"
    exit 1
}
MCOPY=$(which mcopy) || {
    echo "ERROR: unable to find mcopy binary"
    exit 1
}

RECOVERY_ISO_SYSROOT="$RECOVERY_DIR/iso-sysroot"
RECOVERY_CORE_IMG="$RECOVERY_DIR/core.img"
RECOVERY_EFI_DIR="$RECOVERY_DIR/EFI"
RECOVERY_EFI_BOOT_DIR="$RECOVERY_EFI_DIR/BOOT"
RECOVERY_EFI_BOOTX86_IMG="$RECOVERY_EFI_BOOT_DIR/bootx64.efi"
RECOVERY_GRUBX86_IMG="$RECOVERY_DIR/grubx64.efi"
RECOVERY_EFI_GRUBX86_IMG="$RECOVERY_EFI_BOOT_DIR/grubx64.efi"
RECOVERY_ELTORITO_IMG="$RECOVERY_ISO_SYSROOT/boot/eltorito.img"
RECOVERY_EMBEDDED_IMG="$RECOVERY_DIR/embedded.img"
RECOVERY_UEFI_IMG="$RECOVERY_ISO_SYSROOT/boot/efi.img"
RECOVERY_XORRISO_OPTIONS="$RECOVERY_DIR/xorriso-options.cfg"

# Start clean
rm -rf $RECOVERY_ISO_SYSROOT $RECOVERY_ISO_IMAGE
mkdir -p $RECOVERY_ISO_SYSROOT

# Add kernel and initrd to ISO sysroot
cp $RECOVERY_KERNEL $RECOVERY_ISO_SYSROOT/vmlinuz
cp $RECOVERY_INITRD $RECOVERY_ISO_SYSROOT/initrd.xz

# Escape special chars in the user provide kernel cmdline string for
# use in sed. Special chars are: \ / &
EXTRA_CMDLINE_LINUX=`echo $EXTRA_CMDLINE_LINUX | sed -e 's/[\/&]/\\\&/g'`

# Create the grub.cfg from a template
mkdir -p $RECOVERY_ISO_SYSROOT/boot/grub
sed -e "s/<CONSOLE_SPEED>/$CONSOLE_SPEED/g"           \
    -e "s/<CONSOLE_DEV>/$CONSOLE_DEV/g"               \
    -e "s/<GRUB_DEFAULT_ENTRY>/$GRUB_DEFAULT_ENTRY/g" \
    -e "s/<CONSOLE_PORT>/$CONSOLE_PORT/g"             \
    -e "s/<EXTRA_CMDLINE_LINUX>/$EXTRA_CMDLINE_LINUX/" \
    -e "s/<SERIAL_CONSOLE_ENABLE>/$SERIAL_CONSOLE_ENABLE/g" \
    "$MACHINE_CONF" $RECOVERY_CONF_DIR/grub-iso.cfg   \
    > $RECOVERY_ISO_SYSROOT/boot/grub/grub.cfg

if [ "$FIRMWARE_TYPE" != "uefi" ] ; then
	# Populate .ISO sysroot with i386-pc GRUB modules
	mkdir -p $RECOVERY_ISO_SYSROOT/boot/grub/i386-pc
	(cd $GRUB_TARGET_LIB_I386_DIR && cp *mod *lst $RECOVERY_ISO_SYSROOT/boot/grub/i386-pc)

	# Generate legacy BIOS eltorito format GRUB image
	$GRUB_HOST_BIN_I386_DIR/grub-mkimage \
		--format=i386-pc \
		--directory=$GRUB_TARGET_LIB_I386_DIR \
		--prefix=/boot/grub \
		--output=$RECOVERY_CORE_IMG \
		part_msdos part_gpt iso9660 biosdisk
	cat $GRUB_TARGET_LIB_I386_DIR/cdboot.img $RECOVERY_CORE_IMG > $RECOVERY_ELTORITO_IMG

	# Generate legacy BIOS MBR format GRUB image
	cat $GRUB_TARGET_LIB_I386_DIR/boot.img $RECOVERY_CORE_IMG > $RECOVERY_EMBEDDED_IMG
fi

if [ "$UEFI_ENABLE" = "yes" ] ; then
    # List of modules to build into the grub image.
    GRUB_MODULES="
	all_video
	boot
	btrfs
	cat
	chain
	configfile
	echo
	efifwsetup
	efinet
	ext2
	fat
	font
	gettext
	gfxmenu
	gfxterm
	gfxterm_background
	gzio
	halt
	hfsplus
	iso9660
	jpeg
	keystatus
	loadenv
	loopback
	linux
	linuxefi
	lsefi
	lsefimmap
	lsefisystab
	lssal
	lvm
	mdraid09
	mdraid1x
	memdisk
	minicmd
	normal
	part_apple
	part_msdos
	part_gpt
	password_pbkdf2
	png
	raid5rec
	raid6rec
	reboot
	search
	search_fs_uuid
	search_fs_file
	search_label
	serial
	sleep
	squash4
	terminal
	terminfo
	test
	true
	video
	zfs
	zfscrypt
	zfsinfo
"
    # Generate UEFI format GRUB image
    mkdir -p $RECOVERY_EFI_BOOT_DIR
    $GRUB_HOST_BIN_UEFI_DIR/grub-mkimage \
        --format=${ARCH}-efi \
        --directory=$GRUB_TARGET_LIB_UEFI_DIR \
        --prefix=/boot/grub \
        --config=$RECOVERY_CONF_DIR/grub-uefi.cfg \
        --output=$RECOVERY_GRUBX86_IMG \
        $GRUB_MODULES

    # For UEFI, the GRUB loader image is embedded inside a UEFI ESP
    # (fat16) disk partition image.  Create that here and copy the
    # UEFI loader image(s) into it.
    if [ "$SECURE_BOOT_ENABLE" = "yes" ] ; then
        # sign the grub image with the onie vendor key
        sbsign --key $ONIE_VENDOR_SECRET_KEY_PEM --cert $ONIE_VENDOR_CERT_PEM \
               --output $RECOVERY_EFI_GRUBX86_IMG $RECOVERY_GRUBX86_IMG
        # copy shim into place as the loader
        cp $SB_SHIM $RECOVERY_EFI_BOOTX86_IMG
    else
        # for non-secure boot, GRUB is the only loader image
        mv $RECOVERY_GRUBX86_IMG $RECOVERY_EFI_BOOTX86_IMG
    fi

    # The size of the ESP needs to be large enough to hold the
    # contents of the /EFI/BOOT directory, plus file system overhead.
    EFI_BOOT_SIZE_BYTES=$(du --bytes $RECOVERY_EFI_BOOT_DIR | awk '{ print $1 }')

    # mcopy wants disk to be an integer number of 32 sectors
    BOOTX86_IMG_SECTORS=$(( ( ( $EFI_BOOT_SIZE_BYTES / 512 ) + 31 ) / 32 ))
    # plus a couple of chunks for the file system overhead
    BOOTX86_IMG_SECTORS=$(( ( $BOOTX86_IMG_SECTORS + 2 ) * 32 ))

    dd if=/dev/zero of=$RECOVERY_UEFI_IMG bs=512 count=$BOOTX86_IMG_SECTORS
    $MKDOSFS $RECOVERY_UEFI_IMG
    $MCOPY -s -i $RECOVERY_UEFI_IMG $RECOVERY_EFI_DIR '::/'
fi

# Combine the legacy BIOS and UEFI GRUB images images into an ISO.
if [ "$FIRMWARE_TYPE" = "uefi" ] ; then
	cp ${RECOVERY_CONF_DIR}/xorriso-options-uefi.cfg ${RECOVERY_XORRISO_OPTIONS}
elif [ "$FIRMWARE_TYPE" = "auto" ] ; then
    rm -f ${RECOVERY_XORRISO_OPTIONS} && touch ${RECOVERY_XORRISO_OPTIONS}
	git merge-file -p --union ${RECOVERY_CONF_DIR}/xorriso-options-bios.cfg \
            ${RECOVERY_XORRISO_OPTIONS} \
            ${RECOVERY_CONF_DIR}/xorriso-options-uefi.cfg \
            > ${RECOVERY_XORRISO_OPTIONS}
else
	cp ${RECOVERY_CONF_DIR}/xorriso-options-bios.cfg ${RECOVERY_XORRISO_OPTIONS}
fi

cd $RECOVERY_DIR && $XORRISO -outdev $RECOVERY_ISO_IMAGE \
    -map $RECOVERY_ISO_SYSROOT / \
    -options_from_file $RECOVERY_XORRISO_OPTIONS

if [ "$UEFI_ENABLE" = "yes" ] ; then
    # The next step is to add a MS-DOS partition table with one entry for
    # the EFI image to the ISO image, so that it looks like a disk image.
    #
    # To create the MS-DOS partition entry for the efi.img (ESP) partition
    # we need to determine the iso9660 sectors (2048 byte sectors) of
    # /boot/efi.img in the CD-ROM and translate it into hard disk sectors
    # (512 byte).
    #
    # Then we create a bootable MS-DOS partition of type "0xEF", which a
    # UEFI firmware will recognize as a UEFI bootable image.

    # sanity check
    $XORRISO -indev $RECOVERY_ISO_IMAGE \
        -find /boot/efi.img -name efi.img -exec report_lba -- 2> /dev/null | grep -q efi.img || {
        echo "ERROR: Unable to find efi.img in the .ISO image"
        exit 1
    }

    # First determine the offset and size of the $RECOVERY_UEFI_IMG within
    # the .ISO

    # The output of the xorriso find command looks like:
    # Report layout: xt , Startlba ,   Blocks , Filesize , ISO image path
    # File data lba:  0 ,      132 ,       80 ,   163840 , '/boot/efi.img'
    EFI_IMG_START_BLOCK=$($XORRISO -indev $RECOVERY_ISO_IMAGE \
        -find /boot/efi.img -name efi.img -exec report_lba -- 2> /dev/null | \
        grep efi.img | awk '{ print $6 }')
    EFI_IMG_START_SECTOR=$(( $EFI_IMG_START_BLOCK * 2048 / 512 ))

    # Determine image size in sectors
    EFI_IMG_SIZE_BYTES=$(stat -c '%s' $RECOVERY_UEFI_IMG)
    EFI_IMG_SIZE_SECTORS=$(( $EFI_IMG_SIZE_BYTES / 512 ))

    # create a MS-DOS partition table with one partition pointing to the
    # EFI image.
    $(dirname $0)/mk-part-table.py $RECOVERY_ISO_IMAGE $EFI_IMG_START_SECTOR $EFI_IMG_SIZE_SECTORS
fi
