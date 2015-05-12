#!/bin/bash
############################################################
#
# This script will copy the given kernel module
# into the appropriately versioned subdirectory.
#
# $1 is the source kernel module
# $2 is the destination base directory.
#
# The file will be copied into $2/$(modver)/$1
#
############################################################
set -ex

srcfile=$1
dstroot=$2
modver=`/sbin/modinfo -F vermagic $1 | awk '{ print $1 }'`
dstdir="${dstroot}/${modver}"
mkdir -p "${dstdir}"
cp "${srcfile}" "${dstdir}"




