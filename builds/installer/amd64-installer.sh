#!/bin/sh
############################################################
# <bsn.cl fy=2013 v=none>
#
#        Copyright 2013, 2014 BigSwitch Networks, Inc.
#
#
#
# </bsn.cl>
############################################################
#
# ONL Installation Script for AMD64.
#
# The purpose of this script is to automatically install ONL
# on the target system.
#
# This script is ONIE-compatible.
#
# This script is can be run under a manual boot of the ONL
# Loader as the execution environment for platforms that do not
# support ONIE.
#
############################################################

############################################################
#
# Installation utility functions
#
############################################################

CR="
"

PATH=$PATH:/sbin:/usr/sbin

##############################
#
# Find the main GPT device in $DEV,
# and the starting switch light partition in $MINPART
#
##############################

visit_blkid()
{
  local fn rest
  fn=$1; shift
  rest="$@"

  local ifs
  ifs=$IFS; IFS=$CR
  for line in `blkid`; do
    IFS=$ifs

    local part rest
    part="`echo "$line" | sed -e 's/:.*//'`"
    rest="`echo "$line" | sed -e 's/^[^:]*:[ ]*//'`"

    local LABEL UUID key val
    while test "$rest"; do
      key="`echo "$rest" | sed -e 's/=.*//'`"
      val="`echo "$rest" | sed -e 's/^[^=]*=\"\([^\"]*\).*\"/\1/'`"
      rest="`echo "$rest" | sed -e 's/^[^=]*=\"[^\"]*\"[ ]*//'`"
      eval "$key=\"$val\""
    done

    eval $fn "$part" "$LABEL" "$UUID" $rest || return 1

  done
  IFS=$ifs

  return 0
}

DEV=
MINPART=

do_visit_blkid_part()
{
  local dev part label uuid
  part=$1; shift
  label=$1; shift
  uuid=$1; shift

  case "$part" in
    /dev/???[0-9])
      dev="`echo $part | sed -e 's/[0-9]$//'`"
      part="`echo $part | sed -e 's/.*\([0-9]\)$/\1/'`"
    ;;
    *)
      installer_say "*** invalid partition $part"
      return 1
      ;;
  esac

  case "$label" in
    *-DIAG|ONIE-BOOT)
      DEV=$dev
      if test "$MINPART"; then
        if test $MINPART -le $part; then
          MINPART=$(( $part + 1 ))
        fi
      else
        MINPART=$(( $part + 1 ))
      fi
    ;;
  esac
}

find_main_partition()
{
  DEV=
  MINPART=
  visit_blkid do_visit_blkid_part || return 1
  if test -b "$DEV"; then
    :
  else
    installer_say "*** cannot find install device"
    return 1
  fi
  if test "$MINPART"; then
    :
  else
    installer_say "*** cannot find install partition"
    return 1
  fi
  return 0
}

visit_parted()
{
  local dev diskfn partfn rest
  dev=$1; shift
  diskfn=$1; shift
  partfn=$1; shift
  rest="$@"

  local ifs ifs2 dummy
  ifs=$IFS; IFS=$CR
  for line in `parted -m $dev unit s print`; do
    IFS=$ifs

    line=`echo "$line" | sed -e 's/[;]$//'`

    case "$line" in
      /dev/*)
        ifs2=$IFS; IFS=:
        set dummy $line
        IFS=$ifs2

        local dev sz model lbsz pbsz typ modelname flags
        shift
        dev=$1; shift
        sz=$1; shift
        model=$1; shift
        lbsz=$1; shift
        pbsz=$1; shift
        typ=$1; shift
        modelname=$1; shift
        flags=$1; shift

        eval $diskfn "$dev" "$sz" "$model" "$typ" "$flags" $rest || return 1

        ;;
      [0-9]:*)
        ifs2=$IFS; IFS=:
        set dummy $line
        IFS=$ifs2

        local part start end sz fs label flags
        shift
        part=$1; shift
        start=$1; shift
        end=$1; shift
        sz=$1; shift
        fs=$1; shift
        label=$1; shift
        flags=$1; shift

        eval $partfn "$part" "$start" "$end" "$sz" "$fs" "$label" "$flags" $rest || return 1

        ;;

      *) continue ;;
    esac

  done
  IFS=$ifs
}

BLOCKS=
# total blocks on this GPT device

NEXTBLOCK=
# next available block for allocating partitions

do_handle_disk()
{
  local dev sz model typ flags
  dev=$1; shift
  sz=$1; shift
  model=$1; shift
  typ=$1; shift
  flags=$1; shift

  if test "$typ" != "gpt"; then
    installer_say "*** invalid partition table: $typ"
    return 1
  fi
  BLOCKS=`echo "$sz" | sed -e 's/[s]$//`
  installer_say "found a disk with $BLOCKS blocks"

  return 0
}

do_handle_disk_msdos()
{
  local dev sz model typ flags
  dev=$1; shift
  sz=$1; shift
  model=$1; shift
  typ=$1; shift
  flags=$1; shift

  if test "$typ" != "msdos"; then
    installer_say "*** invalid partition table: $typ"
    return 1
  fi
  BLOCKS=`echo "$sz" | sed -e 's/[s]$//`
  installer_say "found a disk with $BLOCKS blocks"

  return 0
}

do_maybe_delete()
{
  local part start end sz fs label flags
  part=$1; shift
  start=$1; shift
  end=$1; shift
  sz=$1; shift
  fs=$1; shift
  label=$1; shift
  flags=$1; shift

  installer_say "examining $DEV part $part"
  if test $part -lt $MINPART; then
    echo "skip this part"
    end=`echo "$end" | sed -e 's/[s]$//'`
    if test "$NEXTBLOCK"; then
      if test $end -ge $NEXTBLOCK; then
        NEXTBLOCK=$(( $end + 1 ))
      fi
    else
      NEXTBLOCK=$(( $end + 1 ))
    fi
    return 0
  fi

  installer_say "deleting this part"
  parted $DEV rm $part || return 1
  return 0
}

ONL_BOOT=
FLASH=
FLASH2=
# final partitions

partition_gpt()
{
  local start end part

  installer_say "Creating 32GiB for ONL boot"
  start=$NEXTBLOCK
  end=$(( $start + 65535 ))

  parted -s $DEV unit s mkpart "ONL-BOOT" ext4 ${start}s ${end}s || return 1
  parted $DEV set $MINPART boot on || return 1
  mkfs.ext4 -L "ONL-BOOT" ${DEV}${MINPART}
  ONL_BOOT=${DEV}${MINPART}

  NEXTBLOCK=$(( $end + 1 ))
  MINPART=$(( $MINPART + 1 ))

  # Ha ha, blkid doesn't recognize 32MiB vfat
  # partitions; 33MiB seems to be large enough
  installer_say "Creating /mnt/flash"
  start=$NEXTBLOCK
  end=$(( $start + 33 * 1048576 / 512 ))

  parted -s $DEV unit s mkpart "FLASH" fat32 ${start}s ${end}s || return 1
  mkfs.vfat -n "FLASH" ${DEV}${MINPART}
  FLASH=${DEV}${MINPART}

  NEXTBLOCK=$(( $end + 1 ))
  MINPART=$(( $MINPART + 1 ))

  installer_say "Allocating remainder for /mnt/flash2"
  start=$NEXTBLOCK

  parted -s $DEV unit s mkpart "FLASH2" fat32 ${start}s "100%" || return 1
  mkfs.vfat -n "FLASH2" ${DEV}${MINPART}
  FLASH2=${DEV}${MINPART}

  return 0
}

partition_msdos()
{
  local start end part

  installer_say "Creating 32GiB for ONL boot"
  start=$NEXTBLOCK
  end=$(( $start + 65535 ))

  parted -s $DEV unit s mkpart primary ext4 ${start}s ${end}s || return 1
  tune2fs -L "ONL-BOOT" $DEV || return 1
  parted $DEV set $MINPART boot on || return 1
  mkfs.ext4 -L "ONL-BOOT" ${DEV}${MINPART}
  ONL_BOOT=${DEV}${MINPART}

  NEXTBLOCK=$(( $end + 1 ))
  MINPART=$(( $MINPART + 1 ))

  # Ha ha, blkid doesn't recognize 32MiB vfat
  # partitions; 33MiB seems to be large enough
  installer_say "Creating /mnt/flash"
  start=$NEXTBLOCK
  end=$(( $start + 33 * 1048576 / 512 ))

  parted -s $DEV unit s mkpart primary fat32 ${start}s ${end}s || return 1
  tune2fs -L "FLASH" $DEV || return 1
  mkfs.vfat -n "FLASH" ${DEV}${MINPART}
  FLASH=${DEV}${MINPART}

  NEXTBLOCK=$(( $end + 1 ))
  MINPART=$(( $MINPART + 1 ))

  installer_say "Allocating remainder for /mnt/flash2"
  start=$NEXTBLOCK

  parted -s $DEV unit s mkpart primary fat32 ${start}s "100%" || return 1
  tune2fs -L "FLASH2" $DEV || return 1
  mkfs.vfat -n "FLASH2" ${DEV}${MINPART}
  FLASH2=${DEV}${MINPART}

  return 0
}

installer_standard_gpt_install()
{
  find_main_partition || return 1
  installer_say "Installing to $DEV starting at partition $MINPART"

  visit_parted $DEV do_handle_disk do_maybe_delete || return 1

  if test "$BLOCKS"; then
    installer_say "found a disk with $BLOCKS blocks"
  else
    installer_say "*** cannot get block count for $DEV"
    return 1
  fi

  if test "$NEXTBLOCK"; then
    installer_say "next usable block is at $NEXTBLOCK"
  else
    installer_say "*** cannot find a starting block"
    return 1
  fi

  partition_gpt || return 1

  installer_say "Installing boot files to $ONL_BOOT"
  mkdir "$workdir/mnt"

  if test -f "${installer_dir}/boot-config"; then
    installer_say "Installing boot-config"
    mount $FLASH "$workdir/mnt"
    cp "${installer_dir}/boot-config" "$workdir/mnt/boot-config"
    umount "$workdir/mnt"
  else
    installer_say "Warning: No boot-config. Manual booting will be required."
  fi

  if test -f "${installer_platform_dir}/swi-config"; then
    . "${installer_platform_dir}/swi-config"
  elif test -f "${installer_dir}/swi-config"; then
    . "${installer_dir}/swi-config"
  fi

  if test -f "${SWISRC}"; then
    if test ! "${SWIDST}"; then
      SWIDST="$(basename ${SWISRC})"
    fi
    installer_say "Installing ONL Software Image (${SWIDST})..."
    mount $FLASH2 "$workdir/mnt"
    cp "${SWISRC}" "$workdir/mnt/${SWIDST}"
    umount "$workdir/mnt"
  else
    installer_say "No ONL Software Image available for installation. Post-install ZTN installation will be required."
  fi

  installer_say "Installing kernel"
  mount -t ext4 $ONL_BOOT "$workdir/mnt"

#  cp "${installer_dir}/kernel-3.14-x86_64-all" "$workdir/mnt/."
  cp "${installer_dir}/kernel-3.2-deb7-x86_64-all" "$workdir/mnt/."

  cp "${installer_dir}/kernel-x86_64" "$workdir/mnt/."
  cp "${installer_dir}/initrd-amd64" "$workdir/mnt/."
  mkdir "$workdir/mnt/grub"
  cp "${installer_platform_dir}/boot/grub.cfg" "$workdir/mnt/grub/grub.cfg"

  installer_say "Installing GRUB"
  grub-install --boot-directory="$workdir/mnt" $DEV

  # leave the GRUB directory mounted,
  # so we can manipulate the GRUB environment
  BOOTDIR="$workdir/mnt"

  return 0
}

installer_standard_msdos_install()
{
  find_main_partition || return 1
  installer_say "Installing to $DEV starting at partition $MINPART"

  visit_parted $DEV do_handle_disk_msdos do_maybe_delete || return 1

  if test "$BLOCKS"; then
    installer_say "found a disk with $BLOCKS blocks"
  else
    installer_say "*** cannot get block count for $DEV"
    return 1
  fi

  if test "$NEXTBLOCK"; then
    installer_say "next usable block is at $NEXTBLOCK"
  else
    installer_say "*** cannot find a starting block"
    return 1
  fi

  partition_msdos || return 1

  installer_say "Installing boot files to $ONL_BOOT"
  mkdir "$workdir/mnt"

  if test -f "${installer_dir}/boot-config"; then
    installer_say "Installing boot-config"
    mount $FLASH "$workdir/mnt"
    cp "${installer_dir}/boot-config" "$workdir/mnt/boot-config"
    umount "$workdir/mnt"
  else
    installer_say "Warning: No boot-config. Manual booting will be required."
  fi

  if test -f "${installer_platform_dir}/swi-config"; then
    . "${installer_platform_dir}/swi-config"
  elif test -f "${installer_dir}/swi-config"; then
    . "${installer_dir}/swi-config"
  fi

  if test -f "${SWISRC}"; then
    if test ! "${SWIDST}"; then
      SWIDST="$(basename ${SWISRC})"
    fi
    installer_say "Installing ONL Software Image (${SWIDST})..."
    mount $FLASH2 "$workdir/mnt"
    cp "${SWISRC}" "$workdir/mnt/${SWIDST}"
    umount "$workdir/mnt"
  else
    installer_say "No ONL Software Image available for installation. Post-install ZTN installation will be required."
  fi

  installer_say "Installing kernel"
  mount -t ext4 $ONL_BOOT "$workdir/mnt"

#  cp "${installer_dir}/kernel-3.14-x86_64-all" "$workdir/mnt/."
  cp "${installer_dir}/kernel-3.2-deb7-x86_64-all" "$workdir/mnt/."

  cp "${installer_dir}/kernel-x86_64" "$workdir/mnt/."
  cp "${installer_dir}/initrd-amd64" "$workdir/mnt/."
  mkdir "$workdir/mnt/grub"
  cp "${installer_platform_dir}/boot/grub.cfg" "$workdir/mnt/grub/grub.cfg"

  installer_say "Installing GRUB"
  grub-install --boot-directory="$workdir/mnt" $DEV

  # leave the GRUB directory mounted,
  # so we can manipulate the GRUB environment
  BOOTDIR="$workdir/mnt"

  return 0
}

############################################################
#
# Installation Main
#
# Installation is performed as follows:
#
# 1. Run the ONIE setup
#
# 2. Unpack the installer files.
#
# 3. Source the installer scriptlet for the current platform.
#
# 4. Run the installer function from the platform scriptlet.
#
# The platform scriptlet determines the entire installation
# sequence.
#
# Most platforms will just call the installation
# utilities in this script with the approprate platform settings.
#
############################################################

set -e
cd $(dirname $0)

installer_script=${0##*/}
installer_zip=$1

BOOTDIR=/mnt/onie-boot
# initial boot partition (onie)

has_grub_env()
{
  local tag
  tag=$1; shift
  test -f $BOOTDIR/grub/grubenv || return 1
  case "`grub-editenv $BOOTDIR/grubenv list` 2>/dev/null" in
    *${tag}*) return 0 ;;
  esac
  return 1
}

set_grub_env()
{
  local key
  key=$1; shift
  if test $# -gt 0; then
    local val
    val=$1; shift
    grub-editenv $BOOTDIR/grub/grubenv set ${key}="${val}"
  else
    grub-editenv $BOOTDIR/grub/grubenv unset ${key}
  fi
  return 0
}

# Check installer debug option from the uboot environment
if has_grub_env sl_installer_debug; then installer_debug=1; fi

if test "$installer_debug"; then
  echo "Debug mode"
  set -x
fi

# Pickup ONIE defines for this machine.
if test -r /etc/machine.conf; then . /etc/machine.conf; fi

#
# Installation environment setup.
#
if test "${onie_platform}"; then
  :
else
  echo "Missing onie_platform (invalid /etc/machine.conf)" 1>&2
  exit 1
fi

# Running under ONIE, most likely in the background in installer mode.
# Our messages have to be sent to the console directly, not to stdout.
installer_say()
{
  echo "$@" > /dev/console
}

workdir=$(mktemp -d -t install-XXXXXX)

# Installation failure message.
do_cleanup()
{
  installer_say "Install failed."
  cat /var/log/onie.log > /dev/console
  installer_say "Install failed. See log messages above for details"

  grep "$workdir" /proc/mounts | cut -d' ' -f2 | sort -r | xargs -n 1 umount
  cd /tmp
  rm -fr "$workdir"

  sleep 3
  reboot
}
trap "do_cleanup" 0 1

if test -z "${installer_platform}"; then
  # Our platform identifiers are equal to the ONIE platform identifiers without underscores:
  installer_platform=`echo ${onie_platform} | tr "_" "-"`
  installer_arch=${onie_arch}
fi
installer_say "ONL installer running under ONIE."

#
# Remount tmpfs larger if possible.
# We will be doing all of our work out of /tmp
#
mount -o remount,size=1024M /tmp || true

# Unpack our distribution
installer_say "Unpacking ONL installer files..."
installer_dir=`pwd`
if test "$SFX_PAD"; then
  # ha ha, busybox cannot exclude multiple files
  unzip $installer_zip -x $SFX_PAD
elif test "$SFX_UNZIP"; then
  unzip $installer_zip -x $installer_script
else
  dd if=$installer_zip bs=$SFX_BLOCKSIZE skip=$SFX_BLOCKS \
  | unzip - -x $installer_script
fi

# Developer debugging
if has_grub_env sl_installer_unpack_only; then installer_unpack_only=1; fi
if test "${installer_unpack_only}"; then
  installer_say "Unpack only requested."
  exit 1
fi


# Replaced during build packaging with the current version.
onl_version="@ONLVERSION@"

installer_say "ONL Installer ${onl_version}"
installer_say "Detected platform: ${installer_platform}"

# Look for the platform installer directory.
installer_platform_dir="${installer_dir}/lib/platform-config/${installer_platform}"
if test -d "${installer_platform_dir}"; then
  # Source the installer scriptlet
  . "${installer_platform_dir}/install/${installer_platform}.sh"
else
  installer_say "This installer does not support the ${installer_platform} platform."
  installer_say "Available platforms are:"
  list=`ls "${installer_dir}/lib/platform-config"`
  installer_say "${list}"
  installer_say "Installation cannot continue."
  exit 1
fi

# Generate the MD5 signature for ourselves for future reference.
installer_md5=$(md5sum "$0" | awk '{print $1}')
# Cache our install URL if available
if test -f "$0.url"; then
  installer_url=$(cat "$0.url")
fi

# These variables are exported by the platform scriptlet
installer_say "Platform installer version: ${platform_installer_version:-unknown}"

# The platform script must provide this function. This performs the actual install for the platform.
platform_installer

# persist some of the install parameters
set_grub_env sl_installer_md5 "${installer_md5}"
set_grub_env sl_installer_version "${sl_version}"
if test "$installer_url"; then
  set_grub_env sl_installer_url "${installer_url}"
else
  set_grub_env sl_installer_url
fi
trap - 0 1
installer_say "Install finished.  Rebooting to Open Network Linux."
sleep 3
reboot

exit

# Do not add any additional whitespace after this point.
PAYLOAD_FOLLOWS
