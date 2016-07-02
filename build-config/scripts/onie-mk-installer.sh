#!/bin/sh

#  Copyright (C) 2013,2014,2015,2016 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014,2015,2016 david_yang <david_yang@accton.com>
#  Copyright (C) 2014 Mandeep Sandhu <mandeep.sandhu@cyaninc.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0

#
# Script to create an ONIE binary installer, suitable for downloading
# to a running ONIE system during "update" mode.
#

set -e

update_type=$1
rootfs_arch=$2
machine_dir=$3
machine_conf=$4
installer_dir=$5
output_file=$6

shift 6

[ -d "$machine_dir" ] || {
    echo "ERROR: machine directory '$machine_dir' does not exist."
    exit 1
}
if [ "$rootfs_arch" = "grub-arch" ] ; then
    # installer_conf is required for grub architecture machines
    installer_conf="${machine_dir}/installer.conf"
    [ -r "$installer_conf" ] || {
        echo "ERROR: unable to read machine installer file: $installer_conf"
        exit 1
    }
fi

[ -r "$machine_conf" ] || {
    echo "ERROR: unable to read machine configuration file: $machine_conf"
    exit 1
}

[ -d "$installer_dir" ] || {
    echo "ERROR: installer directory does not exist: $installer_dir"
    exit 1
}

arch_dir="$rootfs_arch"

[ -d "$installer_dir/$arch_dir" ] || {
    echo "ERROR: arch specific installer directory does not exist: $installer_dir/$arch"
    exit 1
}

touch $output_file || {
    echo "ERROR: unable to create output file: $output_file"
    exit 1
}
rm -f $output_file

case "$update_type" in
    onie)
        update_label="ONIE"
        ;;
    firmware)
        update_label="Firmware"
        firmware_dir="${machine_dir}/firmware"
        [ -d "$firmware_dir" ] || {
            echo "ERROR: firmware directory '$firmware_dir' does not exist."
            exit 1
        }
        [ -r "$firmware_dir/fw-install.sh" ] || {
            echo "ERROR: unable to find firmware install script: $firmware_dir/fw-install.sh"
            exit 1
        }
        ;;
    *)
        echo "ERROR: unknown update_type: $update_type"
        exit 1
esac

# Determine the files to include based on update_type
if [ "$update_type" = "onie" ] ; then
    # For this update type the files to include are specified on
    # the command line.
    if [ $# -eq 0 ] ; then
        echo "Error: No ONIE update image files found"
        exit 1
    fi
    include_files="$*"
elif [ "$update_type" = "firmware" ] ; then
    include_files="$firmware_dir"
fi

tmp_dir=
clean_up()
{
    rm -rf $tmp_dir
}

trap clean_up EXIT

# make the update data archive
# contents:
#   - OS image files
#   - $machine_conf

echo -n "Building self-extracting $update_label installer image ."
tmp_dir=$(mktemp --directory)
tmp_installdir="$tmp_dir/installer"
mkdir $tmp_installdir || exit 1
tmp_tardir="$tmp_dir/tar"
mkdir $tmp_tardir || exit 1

for f in $include_files ; do
    cp -rL "$f" $tmp_tardir || exit 1
    echo -n "."
done

# Bundle data into a tar file
tar -C $tmp_tardir -cJf $tmp_installdir/onie-update.tar.xz $(ls $tmp_tardir) || exit 1
echo -n "."

# Parameterize the user interface of the update installer based on the
# udpate_type.
cat <<EOF > $tmp_installdir/update-type
update_type="$update_type"
update_label="$update_label"
EOF
echo -n "."

cp $installer_dir/install.sh $tmp_installdir || exit 1
echo -n "."
cp -r $installer_dir/$arch_dir/* $tmp_installdir
echo -n "."

[ -r $machine_dir/installer/install-platform ] && {
    cp $machine_dir/installer/install-platform $tmp_installdir
}

# Massage install-arch
if [ "$arch_dir" = "u-boot-arch" ] ; then
    sed -e "s/%%UPDATER_UBOOT_NAME%%/$UPDATER_UBOOT_NAME/" \
	-i $tmp_installdir/install-arch
fi
echo -n "."

# Add optional installer configuration files
if [ "$rootfs_arch" = "grub-arch" -a "$update_type" = "onie" ] ; then
    cp "$installer_conf" $tmp_installdir || exit 1
    echo -n "."

    if [ "$SERIAL_CONSOLE_ENABLE" = "yes" ] ; then
        DEFAULT_GRUB_SERIAL_COMMAND="serial --port=$CONSOLE_PORT --speed=$CONSOLE_SPEED --word=8 --parity=no --stop=1"
        DEFAULT_GRUB_CMDLINE_LINUX="console=tty0 console=ttyS${CONSOLE_DEV},${CONSOLE_SPEED}n8"
        DEFAULT_GRUB_TERMINAL_INPUT="serial"
        DEFAULT_GRUB_TERMINAL_OUTPUT="serial"
    else
        DEFAULT_GRUB_SERIAL_COMMAND=""
        DEFAULT_GRUB_CMDLINE_LINUX=""
        DEFAULT_GRUB_TERMINAL_INPUT="console"
        DEFAULT_GRUB_TERMINAL_OUTPUT="console"
    fi
    GRUB_DEFAULT_CONF="$tmp_installdir/grub/grub-variables"
    cat <<EOF >> $GRUB_DEFAULT_CONF
## Begin grub-variables

# default variables
DEFAULT_GRUB_SERIAL_COMMAND="$DEFAULT_GRUB_SERIAL_COMMAND"
DEFAULT_GRUB_CMDLINE_LINUX="$DEFAULT_GRUB_CMDLINE_LINUX"
DEFAULT_GRUB_TERMINAL_INPUT="$DEFAULT_GRUB_TERMINAL_INPUT"
DEFAULT_GRUB_TERMINAL_OUTPUT="$DEFAULT_GRUB_TERMINAL_OUTPUT"
# overridden if they have been defined in the environment
GRUB_SERIAL_COMMAND=\${GRUB_SERIAL_COMMAND:-"\$DEFAULT_GRUB_SERIAL_COMMAND"}
GRUB_TERMINAL_INPUT=\${GRUB_TERMINAL_INPUT:-"\$DEFAULT_GRUB_TERMINAL_INPUT"}
GRUB_TERMINAL_OUTPUT=\${GRUB_TERMINAL_OUTPUT:-"\$DEFAULT_GRUB_TERMINAL_OUTPUT"}
GRUB_CMDLINE_LINUX=\${GRUB_CMDLINE_LINUX:-"\$DEFAULT_GRUB_CMDLINE_LINUX"}
export GRUB_SERIAL_COMMAND
export GRUB_TERMINAL_INPUT
export GRUB_TERMINAL_OUTPUT
export GRUB_CMDLINE_LINUX

# variables for ONIE itself
GRUB_ONIE_SERIAL_COMMAND=\$GRUB_SERIAL_COMMAND
export GRUB_ONIE_SERIAL_COMMAND

## End grub-variables
EOF
    echo -n "."

    GRUB_MACHINE_CONF="$tmp_installdir/grub/grub-machine.cfg"
    echo "## Begin grub-machine.cfg" > $GRUB_MACHINE_CONF
    # make sure each var is 'exported' for GRUB shell
    sed -e 's/\(.*\)=\(.*$\)/\1=\2\nexport \1/' $machine_conf >> $GRUB_MACHINE_CONF
    echo "## End grub-machine.cfg" >> $GRUB_MACHINE_CONF
    echo -n "."
    GRUB_EXTRA_CMDLINE_CONF="$tmp_installdir/grub/grub-extra.cfg"
    echo "## Begin grub-extra.cfg" > $GRUB_EXTRA_CMDLINE_CONF
    echo "ONIE_EXTRA_CMDLINE_LINUX=\"$EXTRA_CMDLINE_LINUX\"" >> $GRUB_EXTRA_CMDLINE_CONF
    echo "export ONIE_EXTRA_CMDLINE_LINUX" >> $GRUB_EXTRA_CMDLINE_CONF
    echo "## End grub-extra.cfg" >> $GRUB_EXTRA_CMDLINE_CONF
    echo -n "."
fi

sed -e 's/onie_/image_/' $machine_conf > $tmp_installdir/machine.conf || exit 1
echo -n "."

if [ "$update_type" = "firmware" ] ; then
    # Add a fragment that will launch the firmware update script.
    cat $installer_dir/firmware-update/install >> $tmp_installdir/update-type
    # Create a dummy installer.conf needed by some architectures
    touch $tmp_installdir/installer.conf
fi

sharch="$tmp_dir/sharch.tar"
tar -C $tmp_dir -cf $sharch installer || {
    echo "Error: Problems creating $sharch archive"
    exit 1
}
echo -n "."

[ -f "$sharch" ] || {
    echo "Error: $sharch not found"
    exit 1
}
sha1=$(cat $sharch | sha1sum | awk '{print $1}')
echo -n "."
cp $installer_dir/sharch_body.sh $output_file || {
    echo "Error: Problems copying sharch_body.sh"
    exit 1
}

# Replace variables in the sharch template
sed -i -e "s/%%IMAGE_SHA1%%/$sha1/" $output_file
echo -n "."
cat $sharch >> $output_file
rm -rf $tmp_dir
echo " Done."

echo "Success:  $update_label installer image is ready in ${output_file}:"
ls -l ${output_file}
