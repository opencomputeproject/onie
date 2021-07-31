#!/bin/bash 
#-------------------------------------------------------------------------------
#
#  Copyright (C) 2021 Alex Doyle <adoyle@nvidia.com>
#
#-------------------------------------------------------------------------------

# SCRIPT_PURPOSE: Automate and provide examples of KVM workflows.

# Run from the onie/encryption directory
if [ "$( basename "$(pwd)" )" != "encryption" ];then
	encryptionDir="$( realpath "$( dirname "$0" )" )"
	cd "$encryptionDir" || exit 1
	echo "Changing directory to [ $encryptionDir ]"
fi

ONIE_TOP_DIR=$( realpath "$(pwd)"/..)

ENCRYPTION_DIR="${ONIE_TOP_DIR}/encryption"

if [ "$1" = "--debug" ];then
    echo "Enabling top level --debug"
    # and we'll hide that argument
    shift
    set -x
fi

# If using emulation, keys can be copied to a virtual USB
# drive to be available at runtime
ONIE_EMULATION_DIR="${ONIE_TOP_DIR}/emulation"
USB_DATA_DIR="${ONIE_EMULATION_DIR}/emulation-files/usb/usb-data"

# Key prefix names
HW_VENDOR_PREFIX="hw-vendor"
SW_VENDOR_PREFIX="sw-vendor"
ONIE_VENDOR_PREFIX="onie-vendor"

# Demonstration script to update kek and db UEFI variables
# 
UEFI_KEK_DB_UPDATE_SCRIPT="write-keys.nsh"

# User instructions to read for UEFI
UEFI_INSTRUCTIONS_TXT="${ENCRYPTION_DIR}/AddingKeysToUEFIBIOS.txt"

BUILD_DIR="${ONIE_TOP_DIR}/build"

#
# Include Secure Boot functions, which use some of the above
# variables.
#

. ./onie-encrypt.lib


# A universal error checking function. Invoke as:
# fxnEC <command line> || exit 1
# Example:  fxnEC cp ./foo /home/bar || exit 1
function fxnEC ()
{

    # actually run the command
    "$@"

    # save the status so it doesn't get overwritten
    status=$?
    # Print calling chain (BASH_SOURCE) and lines called from (BASH_LINENO) for better debug
    if [ $status -ne 0 ];then
        #echo "ERROR [ $status ] in ${BASH_SOURCE[1]##*/}, line #${BASH_LINENO[0]}, calls [ ${BASH_LINENO[*]} ] command: \"$*\"" 1>&2
        echo "ERROR [ $status ] in $(caller 0), calls [ ${BASH_LINENO[*]} ] command: \"$*\"" 1>&2
    fi

    return $status
}

#
# Function to illustrate important points in the build process
#
STEP_COUNT=0
function fxnPS()
{
    echo "Step: [ $STEP_COUNT ] $1"
    STEP_COUNT=$(( STEP_COUNT +1 ))
}


function fxnHelp()
{
    # Set default configuration so values are visible in help
    fxnApplyDefaults
    echo ""
    echo " $0 [command] [ options ]"
    echo ""
    echo " Key creation and validation utilities for ONIE Secure Boot."
    echo ""
    echo "Commands:"
    echo ""
    echo " Build commands:"
    echo "  clean                    Destroy keys and anything touched by them."
    echo "  build-uefi-vars          Generate kek-all.auth and db-all.auth"
    echo "  build-uefi-db-key <key>  Convert certificate public key into uefi format to add to db."
    echo ""
    echo " Utility functions:"
    echo "  generate-key-set  <vendor > <name> <id> <comment>  Generate all the signing keys you'll need."
    echo "                            Example: $0 generate-key-set 'dev-vendor' 'dev-key' 'dev-test@vendor.org' 'development key' "
	echo ""
    echo "  generate-all-keys        Create hardware, software, and ONIE vendor demonstration keys."
    echo "                             If <date> is supplied it will be added to the "
	echo "                              organizationalUnitName in the certificate."
    echo "                             This is 'generate-key-set' times 3 with defaults."
    echo "                             Keys will be in onie/encryption/machines/<machine>/keys/"
	echo ""
    echo "  update-keys              Copy keys and key utilities to a directory for run time use."
    echo ""
    echo " Informational commands:"
    echo "  audit                    Check the build area for signing consistency."
    echo "  info-config              Print security configurations."
    echo ""
    echo " Options:"
    echo "  --machine-name  <name>   Name of build target machine - ex mlnx_x86"
    echo "  --machine-revision <r>   The -rX version at the end of the --machine-name"
    echo "  --help                   This output."
    echo ""
    echo " Run this script from onie/encryption."
    echo ""
}


#
# Clean out all staged keys and USB images as well
# as the kvm code
function fxnMakeClean()
{
	# Wipe out the keys and the signed shim too.
	echo "Removing ${ENCRYPTION_DIR}/machines/${ONIE_MACHINE_TARGET}"
	rm -rf "${ENCRYPTION_DIR}/machines/${ONIE_MACHINE_TARGET}"
}

# One stop to set default values for the run.
function fxnApplyDefaults()
{
    # KVM defaults
    ONIE_MACHINE_TARGET="kvm_x86_64"
    ONIE_MACHINE_REVISION="-r0"

    # And the values that get set from the above
    ONIE_MACHINE="${ONIE_MACHINE_TARGET}${ONIE_MACHINE_REVISION}"

	# path to manufacturer, if any
	ONIE_MACHINE_VENDOR=""

}


##################################################
#                                                #
# MAIN  - script processing starts here          #
#                                                #
##################################################

if [ "$#" = "0" ];then
    # Require an argument for action.
    # Always trigger help messages on no action.
    fxnHelp
    exit 0
fi

# Set a default configuration that the CLI can override.
fxnApplyDefaults

#
# Gather arguments and set action flags for processing after
# all parsing is done. The only functions that should get called
# from here are ones that take no arguments.
while [[ $# -gt 0 ]]
do
    term="$1"

    case $term in
        clean )
            DO_CLEAN="TRUE"
            ;;

        # Generate signing keys
        generate-key-set )
            if [ "$5" = "" ];then
                echo "Supply a vendor, type name, user email,  and a description to  associate with the certificate."
                echo "  Ex: $0 generate-key-set 'dev-vendor' 'dev-key' 'dev-test@vendor.org' 'development key' "
                echo " Exiting."
                echo ""
                exit 1
            fi
			# Pass settings along once defaults are read.
			DO_GENERATE_KEY_SET="TRUE"
			GEN_KEY_USER="$2"
			GEN_KEY_CERT_NAME="$3"
			GEN_KEY_USER_EMAIL="$4"
			GEN_KEY_DESCRIPTION="$5"
			shift 5
            ;;

        # Generate test keys for a hardware vendor, software vendor, and ONIE vendor.
        generate-all-keys )
			DO_GENERATE_ALL_KEYS="TRUE"
            ;;

        print-security-variables )
			# Read what the machine-security.make file has actually set.
            fxnReadKeyConfigFile
            echo "$ALL_SIGNING_KEYS"
            exit
            ;;

        update-keys )
            # 
			DO_UPDATE_KEYS="TRUE"
            ;;

        --machine-vendor )
            if [ "$2" = "" ];then
                echo "ERROR! Must supply a machine vendor: ex 'accton'. Exiting."
                exit 1
            fi
            ONIE_MACHINE_VENDOR="$2"
            shift
            ;;
		
        --machine-name )
            if [ "$2" = "" ];then
                echo "ERROR! Must supply a machine name: ex 'mlnx_x86'. Exiting."
                exit 1
            fi
            ONIE_MACHINE_TARGET="$2"
            shift
            ;;

        --machine-revision )
            if [ "$2" = "" ];then
                echo "ERROR! Must supply a machine revision: ex '-r0'. Exiting."
                exit 1
            fi
            ONIE_MACHINE_REVISION="$2"
            shift
            ;;

        build-uefi-vars )
            # Build UEFI database variables
            DO_BUILD_UEFI_VARS="TRUE"
            ;;

        build-uefi-db-key )
            fxnAddUEFIDBKey "$2"
            exit
            ;;

        audit )
			DO_SIGNING_AUDIT="TRUE"
            ;;

        info-config )
			DO_INFO_CONFIG="TRUE"
            ;;


        --help )
            fxnHelp
            exit 0
            ;;

        *)
            fxnHelp
            echo "Unrecognized option [ $term ]. Exiting"
            exit 1
            ;;

    esac
    shift # skip over argument

done


# onie/encryption
if [ "${ONIE_MACHINE_VENDOR}" = "" ];then
	CRYPTO_DIR=${ENCRYPTION_DIR}/machines/${ONIE_MACHINE_TARGET}
else
	CRYPTO_DIR=${ENCRYPTION_DIR}/machines/${ONIE_MACHINE_VENDOR}/${ONIE_MACHINE_TARGET}
fi

# Signed SHIMs and stuff reside here
# change as needed
SAFE_PLACE="${CRYPTO_DIR}/safe-place"

# Put user generated keys here
NEW_KEYS_DIR="${CRYPTO_DIR}/keys"

# Store KEK and DB efi vars generated from keys here
EFI_VARS_DIR="${NEW_KEYS_DIR}/efiVars"

KEY_EFI_BINARIES_DIR="${NEW_KEYS_DIR}/efi-binaries"
KEY_UTILITIES_DIR="${NEW_KEYS_DIR}/utilities"

if [ "$DO_INFO_CONFIG" = "TRUE" ];then

    # Print out any configuration information
	fxnReadKeyConfigFile "printOut"
    exit 0
fi


if [ "$DO_CLEAN" = "TRUE" ];then
    fxnMakeClean
    exit
fi

if [ ! -e "$SAFE_PLACE" ];then
	fxnEC mkdir -p "$SAFE_PLACE" || exit 1
fi
# Generate one set of keys
if [ "$DO_GENERATE_KEY_SET" = "TRUE" ];then
	
	fxnGenerateKeys "$GEN_KEY_USER" "$GEN_KEY_CERT_NAME" "$GEN_KEY_USER_EMAIL" "$GEN_KEY_DESCRIPTION" 
	exit
fi

# Generate all the keys
if [ "$DO_GENERATE_ALL_KEYS" = "TRUE" ];then
	fxnGenerateAllKeys 
	exit
fi

# Move generated keys in to usable locations.
if [ "$DO_UPDATE_KEYS" = "TRUE" ];then
	# copy keys and utilities to a directory for run time use.
	fxnUpdateKeyData
    exit
fi

if [ "$DO_SIGNING_AUDIT" = "TRUE" ];then
	# Check all things that could be signed
    fxnVerifySigned
    exit 0
fi


if [ "$DO_BUILD_UEFI_VARS" = "TRUE" ];then
    fxnGenerateKEKAndDBEFIVars
fi
