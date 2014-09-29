#!/bin/bash
############################################################
# <bsn.cl fy=2013 v=onl>
#
#        Copyright 2013, 2014 Big Switch Networks, Inc.
#
# Licensed under the Eclipse Public License, Version 1.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#        http://www.eclipse.org/legal/epl-v10.html
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the
# License.
#
# </bsn.cl>
############################################################
#
#  pretend-userbuild.sh
#
# This script automatically builds all workspaces, components, SWIs,
# and installers using the targets defined in ONL/build/Makefile
# just like a user following the instructions would.  This is 
# a slightly different task than the autobuild which takes a
# a bunch of work saving short cuts.
# 
# This script actually revokes itself from inside a workspace
############################################################

function die {
    echo "" >&2
    echo "" >&2
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
    echo "!!!!!!! Build Failed: $@" >&2
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
    echo "" >&2
    echo "" >&2
    exit 2
}

set -x

ARCHS=amd64
TARGETS="powerpc kvm"
ONL_ROOT=`realpath $(dirname $(readlink -f $0))/../`
BUILD_SCRIPT=pretend-userbuild.sh


cd $ONL_ROOT

case $1 in 
    powerpc)
        mode=powerpc
        ;;
#    amd64)
#        mode=amd64
#        ;;
    kvm)
        mode=kvm
        ;;
    all)
        mode=all
        ;;
    -h|--help|*)
        echo "Usage $0 [TARGET=all|powerpc|kvm]" >&2
        echo "      See script for more details" >&2
        exit 1
esac
echo Running $0 in Mode=$mode


if [ $mode = all ] ; then
    # Step #1 install local host build dependencies
    make install-host-deps || die "Installing host dependencies: \$?=$?"

    for arch in $ARCHS ; do 
        onl-mkws -a $arch ws.$arch || die "Make workspace for $arch failed: \$?=$?"
        cd ws.$arch
        for target in $TARGETS ; do
            onl-chws $ONL_ROOT/tools/$BUILD_SCRIPT $target || die "Parent build: making target=$target arch=$arch: \$?=$?"
        done
    done
else # mode != all, running inside a workspace
    make install-ws-deps || die "make install-ws-deps failed for arch=$mode : \$?=$?"
    make onl-$mode       || due "make onl-$mode failed: \$?=$?"
fi


