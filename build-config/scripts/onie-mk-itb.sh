#!/bin/sh

#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
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

SYSROOT="$3"
[ -r "$SYSROOT" ] || {
    echo "Error: SYSROOT file is not readable: $(realpath $SYSROOT)"
    exit 1
}

OUTFILE="$4"
[ -n "$OUTFILE" ] || {
    echo "Error: output .itb file not specified"
    exit 1
}

clean_tmp() {
    rm "$1"
}

its_file="$(mktemp)"
trap "clean_tmp $its_file" EXIT

set -e
KERNEL="$(realpath ../${MACHINE_PREFIX}/kernel/linux/vmlinux.bin.gz)"
SYSROOT="$(realpath $SYSROOT)"
DTB="$(realpath ${MACHINE_PREFIX}.dtb)"

# Create a .its file for this machine type on the fly
(cat <<EOF
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
	description = "PowerPC kernel, initramfs and FDT blob";
	#address-cells = <1>;

	images {
		kernel {
			description = "${MACHINE_PREFIX} PowerPC Kernel";
			data = /incbin/("$KERNEL");
			type = "kernel";
			arch = "ppc";
			os = "linux";
			compression = "gzip";
			load = <00000000>;
			entry = <00000000>;
			hash@1 {
				algo = "crc32";
			};
		};

		initramfs {
			description = "initramfs";
			data = /incbin/("$SYSROOT");
			type = "ramdisk";
			arch = "ppc";
			os = "linux";
			compression = "none";
			load = <00000000>;
			hash@1 {
				algo = "crc32";
			};
		};

		dtb {
			description = "${MACHINE_PREFIX}.dtb";
			data = /incbin/("$DTB");
			type = "flat_dt";
			arch = "ppc";
			os = "linux";
			compression = "none";
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
			fdt = "dtb";
		};
	};
};

EOF
) > $its_file

mkimage -f $its_file "$OUTFILE"
