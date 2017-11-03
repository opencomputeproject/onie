#!/bin/bash

#
#  Copyright (C) 2017 Rajendra Dendukuri <rajendra.dendukuri@broadcom.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#

# Make an ONIE installer using CentOS 7 chroot environment
#
# inputs: cento7 chroot package
# output: ONIE compatible OS installer image
#
# Comments: This script expects that yumbootsstrap is installed on
#           on the Linux host where it is executed.

#!/bin/sh

set -e

IN=./input
OUT=./output
rm -rf $OUT
mkdir -p $OUT

WORKDIR=./work
EXTRACTDIR="$WORKDIR/extract"
INSTALLDIR="$WORKDIR/installer"

# Create a centos-7 chroot package if not done already
DISTR0_VER=centos-7
CHROOT_PKG="${DISTR0_VER}-chroot.tar.bz2"
[ ! -r ${IN}/${CHROOT_PKG} ] && {
   CHROOT_PATH="${WORKDIR}/${DISTR0_VER}-chroot"
   mkdir -p ${CHROOT_PATH}
   which yumbootstrap  > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo "Error: yumbootstrap tool not found. Please install yumbootstrap."
      exit 1;
   fi
   PKG_LIST=openssh-server,grub2
   /usr/sbin/yumbootstrap --include=${PKG_LIST} --verbose --group=Core ${DISTR0_VER} ${CHROOT_PATH}
   cd ${CHROOT_PATH}
   ln -sf boot/vmlinuz-$(ls -1 lib/modules | tail -1) vmlinuz
   ln -sf boot/initramfs-$(ls -1 lib/modules | tail -1).img initrd.img
   cd -
   mkdir -p ${IN}
   tar -cjf ${IN}/${CHROOT_PKG} -C ${CHROOT_PATH} .
}

output_file="${OUT}/${DISTR0_VER}-ONIE.bin"

echo -n "Creating $output_file: ."

# prepare workspace
[ -d $EXTRACTDIR ] && chmod +w -R $EXTRACTDIR
rm -rf $WORKDIR
mkdir -p $EXTRACTDIR
mkdir -p $INSTALLDIR

# Copy distro package
cp -f ${IN}/${CHROOT_PKG} $INSTALLDIR

# Create custom install.sh script
touch $INSTALLDIR/install.sh
chmod +x $INSTALLDIR/install.sh

(cat <<EOF
#!/bin/sh

blk_dev=/dev/vda
root_disk=hd0
distro_part=3
distro_dev="/dev/vda\${distro_part}"
distro_mnt=/mnt/distro
onie_root_dir=/mnt/onie-boot/onie
kernel_args="console=tty0 console=ttyS0,115200n8"
grub_serial_command="serial --port=0x3f8 --speed=115200 --word=8 --parity=no --stop=1"

cd \$(dirname \$0)

# remove old partitions
for p in \$(seq 3 9) ; do
  umount -f \$blk_dev\$p  > /dev/null 2&>1
  sgdisk -d \$p \$blk_dev > /dev/null 2&>1
done
partprobe \${blk_dev}

# bonk out on errors
set -e

echo "Create partition ."
sgdisk --largest-new=\${distro_part} \
       --change-name="\${distro_part}:${DISTR0_VER}" \${blk_dev}  || {
        echo "ERROR: Unable to create partition \$distro_part on \$blk_dev"
        exit 1
    }
partprobe \${blk_dev}

# Create filesystem on partition with a label
mkfs.ext4 -L ${DISTR0_VER} \$distro_dev || {
    echo "ERROR: Unable to create file system on \$distro_dev"
    exit 1
}

# Mount filesystem
mkdir -p \$distro_mnt || {
    echo "ERROR: Unable to create distro file system mount point: \$distro_mnt"
    exit 1
}

mount -t ext4 -o defaults,rw \$distro_dev \$distro_mnt || {
    echo "ERROR: Unable to mount \$distro_dev on \$distro_mnt"
    exit 1
}

cp -f distro-setup.sh \${distro_mnt}
echo "Extract chroot environment ..."
tar -xf ${CHROOT_PKG} -C \${distro_mnt}

[ -e \${distro_mnt}/dev/pts ] && {
    mount -o bind /dev/pts \${distro_mnt}/dev/pts
}

mount -t proc proc \${distro_mnt}/proc
mount -t sysfs sys \${distro_mnt}/sys
cp -a \${blk_dev} \${distro_mnt}/\${blk_dev}

echo "Setting up distro .."
chroot \${distro_mnt} /distro-setup.sh \${distro_dev}

[ -e \${distro_mnt}/dev/pts ] && {
   umount \${distro_mnt}/dev/pts
}
umount \${distro_mnt}/proc
umount \${distro_mnt}/sys

# Install boot loader
echo "Install GRUB2 bootloader .."
grub-install --boot-directory="\${distro_mnt}/boot" --recheck "\${blk_dev}" || {
        echo "ERROR: grub-install failed on: \${blk_dev}"
        exit 1
}

# Prepare boot loader configuration file
grub_cfg=\$(mktemp)

# Add common configuration, like the timeout and serial console.
(cat <<EOF2

\${grub_serial_command}
terminal_input serial
terminal_output serial
set timeout=5

# Add the logic to support grub-reboot
if [ -s \\\$prefix/grubenv ]; then
  load_env
fi
if [ "\\\${saved_entry}" ] ; then
   set default="\${saved_entry}"
   set saved_entry=
   save_env saved_entry
fi

if [ "\\\${next_entry}" ] ; then
   set default="\\\${next_entry}"
   set next_entry=
   save_env next_entry
fi

EOF2
) >> \${grub_cfg}


# Add a menu entry for o/s distro
(cat <<EOF3
menuentry '${DISTR0_VER}' {
  set root='(\${root_disk},gpt\${distro_part})'
  echo    'Loading ${DISTR0_VER} ...'
  linux   /vmlinuz \${kernel_args} root=\${blk_dev}\${distro_part}
  echo    'Loading ${DISTR0_VER} initial ramdisk ...'
  initrd  /initrd.img
 }
EOF3
) >> \${grub_cfg}


# Add menu entries for ONIE -- use the grub fragment provided by the
# ONIE distribution.
\$onie_root_dir/grub.d/50_onie_grub >> \${grub_cfg}

# Copy boot loader config to appropriate location
cp -f \${grub_cfg} \${distro_mnt}/boot/grub/grub.cfg
cat \${grub_cfg} >> \${distro_mnt}/etc/grub.d/40_onie_grub

umount \${distro_mnt}

cd /

EOF
) > $INSTALLDIR/install.sh

# Create o/s setup script
touch $INSTALLDIR/distro-setup.sh
chmod +x $INSTALLDIR/distro-setup.sh

(cat <<EOF
#!/bin/sh

# Create default user onie, with password onie
echo "Setting user onie password as onie"
useradd -s /bin/bash -m -k /dev/null onie
echo onie | passwd onie --stdin
echo "onie    ALL=(ALL)       ALL" >> /etc/sudoers
echo onie | passwd --stdin

# Setup o/s mount points
(cat <<EOF2
tmpfs                   /tmp                    tmpfs   defaults        0 0
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
\${1}               /                       ext4    defaults        1 1
EOF2
) > /etc/fstab

# Configure default hostname
echo "HOSTNAME=localhost" > /etc/sysconfig/network

# Disable selinux
sed -ie "s/SELINUX=/SELINUX=disabled/g" /etc/selinux/config

# Customizations

exit 0
EOF
) > $INSTALLDIR/distro-setup.sh


echo -n "."

# Repackage $INSTALLDIR into a self-extracting installer image
sharch="$WORKDIR/sharch.tar"
tar -C $WORKDIR -cf $sharch installer || {
    echo "Error: Problems creating $sharch archive"
    exit 1
}

[ -f "$sharch" ] || {
    echo "Error: $sharch not found"
    exit 1
}
echo -n "."

sha1=$(cat $sharch | sha1sum | awk '{print $1}')
echo -n "."

cp sharch_body.sh $output_file || {
    echo "Error: Problems copying sharch_body.sh"
    exit 1
}

# Replace variables in the sharch template
sed -i -e "s/%%IMAGE_SHA1%%/$sha1/" $output_file
echo -n "."
cat $sharch >> $output_file
rm -rf $tmp_dir
echo " Done."
