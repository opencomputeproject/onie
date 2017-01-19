#!/bin/sh

#  Copyright (C) 2013,2014,2015 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0

#
# Create a U-Boot FIT image (itb)
#

MACHINE="$1"
[ -n "$MACHINE" ] || {
    echo "Error: MACHINE was not specified"
    exit 1
}

MACHINE_PREFIX="$2"
[ -n "$MACHINE_PREFIX" ] || {
    echo "Error: MACHINE_PREFIX was not specified"
    exit 1
}

ARCH="$3"
if [ "$ARCH" != "ppc" ] &&
   [ "$ARCH" != "arm" ] &&
   [ "$ARCH" != "arm64" ] ; then
    echo "Error: Unsupported architecture: $ARCH"
    exit 1
fi

KERNEL_LOAD="$4"
[ -n "$KERNEL_LOAD" ] || {
    echo "Error: KERNEL_LOAD was not specified"
    exit 1
}

KERNEL_ENTRY="$5"
[ -n "$KERNEL_ENTRY" ] || {
    echo "Error: KERNEL_ENTRY was not specified"
    exit 1
}

FDT_LOAD="$6"
[ -n "$FDT_LOAD" ] || {
    echo "Error: FDT_LOAD was not specified"
    exit 1
}
if [ "$FDT_LOAD" != "no" ] ; then
    FDT_LOAD_TEXT="load = <$FDT_LOAD>;"
else
    FDT_LOAD_TEXT=""
fi

KERNEL_COMPRESSION="gzip"
INITRD_LOAD="0x00000000"
FDT="fdt = \"dtb\";"

KERNEL="$7"
[ -r "$KERNEL" ] || {
    echo "Error: KERNEL file is not readable: $KERNEL"
    exit 1
}

DTB="$8"
[ -r "$DTB" ] || {
    echo "Error: DTB file is not readable: $DTB"
    exit 1
}

SYSROOT="$9"
[ -r "$SYSROOT" ] || {
    echo "Error: SYSROOT file is not readable: $SYSROOT"
    exit 1
}

OUTFILE="$10"
[ -n "$OUTFILE" ] || {
    echo "Error: output .itb file not specified"
    exit 1
}
touch $OUTFILE || {
    echo "Error: unable to write to output file: $OUTFILE"
    exit 1
}
rm -f $OUTFILE

clean_tmp() {
    rm "$1"
}

its_file="$(mktemp)"
trap "clean_tmp $its_file" EXIT

set -e
KERNEL="$(realpath $KERNEL)"
SYSROOT="$(realpath $SYSROOT)"
DTB="$(realpath $DTB)"

# Create a .its file for this machine type on the fly
cat <<EOF > $its_file
/*
*
* U-boot uImage source file with a kernel, ramdisk and FDT
* blob.
*
* Note: The /incbin/() paths used below are relative to the location
* of this file.  That's just how the tool works.
*
*/

/dts-v1/;

/ {
	description = "$ARCH kernel, initramfs and FDT blob";
	#address-cells = <1>;

	images {
		kernel {
			description = "${MACHINE_PREFIX} $ARCH Kernel";
			data = /incbin/("$KERNEL");
			type = "kernel";
			arch = "$ARCH";
			os = "linux";
			compression = "$KERNEL_COMPRESSION";
			load = <$KERNEL_LOAD>;
			entry = <$KERNEL_ENTRY>;
			hash@1 {
				algo = "crc32";
			};
		};

		initramfs {
			description = "initramfs";
			data = /incbin/("$SYSROOT");
			type = "ramdisk";
			arch = "$ARCH";
			os = "linux";
			compression = "none";
			load = <$INITRD_LOAD>;
			entry = <$INITRD_LOAD>;
			hash@1 {
				algo = "crc32";
			};
		};

		dtb {
			description = "${MACHINE_PREFIX}.dtb";
			data = /incbin/("$DTB");
			type = "flat_dt";
			arch = "$ARCH";
			os = "linux";
			compression = "none";
			$FDT_LOAD_TEXT
			hash@1 {
				algo = "crc32";
			};
		};
	};

	configurations {

		default = "$MACHINE";
		$MACHINE {
			description = "${MACHINE_PREFIX}";
			kernel = "kernel";
			ramdisk = "initramfs";
			$FDT
		};
	};
};

EOF

if [ "$V" != "0" ] ; then
    echo "=========================================="
    echo "DEBUG: Dumping FIT image its file contents"
    echo "=========================================="
    cat $its_file
fi

mkimage -f $its_file "$OUTFILE"
