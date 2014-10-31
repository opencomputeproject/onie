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
# call with `curl https://raw.githubusercontent.com/opennetworklinux/ONL/master/tools/pretend-userbuild.sh | bash | tee build.out`
# for no fuss, high trust building
# 
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
    echo "Error on `date`" >&2
    exit 2
}

set -x

ARCHS=amd64
TARGETS="powerpc kvm"
OUTDIR=build-`date | sed -e 's/[^a-zA-Z0-9]/_/g'`
ONL_ROOT=`pwd`/$OUTDIR/ONL
BUILD_SCRIPT=pretend-userbuild.sh



    echo Starting: `date`
    mkdir $OUTDIR
    cd $OUTDIR


    # Fugly hack to give us a complete log of the process,
    # Including the parts before the process started
    BUILDLOG=build.out
    if [ -f ../$BUILDLOG ] ; then
        echo Moving $BUILDLOG into the build directory
        ln ../$BUILDLOG
        rm ../$BUILDLOG	# will keep going even if file isn't there
    fi

    git clone git://github.com/opennetworklinux/ONL || die "git problem"

    cd ONL
    # Step #1 install local host build dependencies
    make install-host-deps || die "Installing host dependencies: \$?=$?"

    for arch in $ARCHS ; do 
        onl-mkws -a $arch ws.$arch || die "Make workspace for $arch failed: \$?=$?"
        cd ws.$arch
        onl-chws make -C $ONL_ROOT install-ws-deps die "make install-ws-deps failed for arch=$arch : \$?=$?"
        for target in $TARGETS ; do
            onl-chws make -C $ONL_ROOT onl-$target       || die "make onl-$target failed: \$?=$?"
        done
    done


