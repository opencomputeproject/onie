#!/bin/sh

#  Copyright (C) 2021 Andriy Dobush <andriyd@nvidia.com>
#
#  SPDX-License-Identifier:     GPL-2.0

set -e

#
# Sign efi file with onie vendor secret key and certificate
# - shim (only for tests)
# - grub
# - vmlinuz
#

ONIE_VENDOR_SECRET_KEY_PEM=$1
ONIE_VENDOR_CERT_PEM=$2
FILE=$3
FILE_SIGNED=$4

usage() {
    cat <<EOF
$0: Usage
$0 <ONIE_VENDOR_SECRET_KEY_PEM> <ONIE_VENDOR_SECRET_KEY_PEM> <file> <signed_file>

Sign efi  <file>
EOF
}

# PLATFORM_EFI_SIGN_SCRIPT - platform specific efi signing script
# If platform sign script variable is defined, run platform script instead of default script.
if [ "${PLATFORM_EFI_SIGN_SCRIPT}" != "" ] ; then
    eval "${PLATFORM_EFI_SIGN_SCRIPT} $1 $2 $3 $4"
    exit 0
fi

[ -r $ONIE_VENDOR_SECRET_KEY_PEM ] || {
    echo "Error: ONIE_VENDOR_SECRET_KEY_PEM file does not exist: $ONIE_VENDOR_SECRET_KEY_PEM"
    usage
    exit 1
}

[ -r $ONIE_VENDOR_CERT_PEM ] || {
    echo "Error: ONIE_VENDOR_CERT_PEM file does not exist: $ONIE_VENDOR_CERT_PEM"
    usage
    exit 1
}

[ -r $FILE ] || {
    echo "Error: File for signing does not exist: $FILE"
    usage
    exit 1
}

echo "$0 signing $FILE with ${ONIE_VENDOR_SECRET_KEY_PEM},  ${ONIE_VENDOR_CERT_PEM} to create $FILE_SIGNED"
sbsign --key ${ONIE_VENDOR_SECRET_KEY_PEM} --cert ${ONIE_VENDOR_CERT_PEM} \
       --output ${FILE_SIGNED} ${FILE}
