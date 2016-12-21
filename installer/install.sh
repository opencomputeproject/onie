#!/bin/sh

#  Copyright (C) 2013-2014,2016 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2015 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0

cd $(dirname $0)

[ -r ./machine.conf ] || {
    echo "ERROR: machine.conf file is missing."
    exit 1
}
. ./machine.conf

# Default implementation is no additional args
parse_arg_arch()
{
    return 1
}

[ -r ./update-type ] || {
    echo "ERROR: update-type file is missing."
    exit 1
}
. ./update-type

if [ "$update_type" = "onie" ] ; then
    [ -r ./install-arch ] || {
        echo "ERROR: install-arch file is missing."
        exit 1
    }
    . ./install-arch
fi

# get running machine from conf file
[ -r /etc/machine.conf ] && . /etc/machine.conf

# for backward compatibility if running machine_rev is empty assume it
# is 0.
true ${onie_machine_rev=0}

# for backward compatibility if running onie_conf_version is empty
# assume it is 0.
true ${onie_config_version=0}

args="hivfqx${args_arch}"

usage()
{
    cat <<EOF
$update_label Installer -- Installs/Updates $update_label

COMMAND LINE OPTIONS

	-h
		Help.  Print this message.

	-v
		Be verbose.  Print what is happening.

	-q
		Be quiet.  Do not print what is happening.

	-x
		Extract image to a temporary directory.

	-i
		Dump image information.

	-f
		Force ONIE update opteration, bypassing any safety
		checks.

$usage_arch
EOF
}

verbose=no
force=no
quiet=no
while getopts "$args" a ; do
    case $a in
        h)
            usage
            exit 0
            ;;
        v)
            verbose=yes
            cmd_verbose=-v
            quiet=no
            ;;
        f)
            force=yes
            ;;
        q)
            quiet=yes
            verbose=no
            ;;
        i)
            # Dump the image information
            cat ./machine.conf
            exit 0
            ;;
        *)
            parse_arg_arch "$a" "$OPTARG" || {
                echo "Unknown argument: $a"
                usage
                exit 1
            }
            ;;
    esac
done

[ -r onie-update.tar.xz ] || {
    echo "ERROR:$update_label: update tar file is missing."
    exit 1
}

xz -d -c onie-update.tar.xz | tar -xf -

check_machine_image()
{
    if [ "$onie_machine" != "$image_machine" ] ; then
        fail=yes
    fi
    if [ "$onie_machine_rev" != "$image_machine_rev" ] ; then
        fail=yes
    fi
    if [ "$onie_arch" != "$image_arch" ] ; then
        fail=yes
    fi
}

[ -r ./install-platform ] && . ./install-platform

fail=
check_machine_image

if [ "$fail" = "yes" ] && [ "$force" = "no" ] ; then
    echo "ERROR:$update_label: Machine mismatch"
    echo "Running machine     : ${onie_arch}-${onie_machine}-${onie_machine_rev}"
    echo "Update Image machine: ${image_arch}-${image_machine}-${image_machine_rev}"
    echo "Source URL: $onie_exec_url"
    exit 1
fi

[ "$quiet" = "no" ] && echo "$update_label: Version       : $image_version"
[ "$quiet" = "no" ] && echo "$update_label: Architecture  : $image_arch"
[ "$quiet" = "no" ] && echo "$update_label: Machine       : $image_machine"
[ "$quiet" = "no" ] && echo "$update_label: Machine Rev   : $image_machine_rev"
[ "$quiet" = "no" ] && echo "$update_label: Config Version: $image_config_version"

# arch specific install method
install_image "$@"
ret=$?
if [ $ret -ne 0 ] ; then
    echo "ERROR:$update_label: update failed."
fi

cd /

exit $ret
