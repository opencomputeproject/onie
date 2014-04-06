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
#  autobuild.sh
#
# This script automatically builds all components, SWIs,
# and installers using the targets defined in ONL/build/Makefile
# and copies them to a remote autobuild server
# by branch and user.
#
############################################################
set -e
set -x

# Skip grep
touch abat_nogrep

# Parent ONL directory
ONL_ROOT=`realpath $(dirname $(readlink -f $0))/../`

# The current branch
BRANCH=`cd $ONL_ROOT && git symbolic-ref --short -q HEAD`

# The repository origin.
: ${GITUSER:=`cd $ONL_ROOT && git remote -v | grep origin | grep fetch | tr ':/' ' ' | awk '{print $3}'`}

SHA1=`cd $ONL_ROOT && git rev-list HEAD -1`

if [ "$GITUSER" == "opennetworklinux" ]; then
    # Special case.
    USERDIR=""
    ABAT_SUFFIX=".$BRANCH"
else
    USERDIR="$GITUSER/"
    ABAT_SUFFIX=".$GITUSER.$BRANCH"
fi

if [ -z "$WS_ROOT" ]; then
    echo "No workspace specified with \$WS_ROOT."
    exit 1
fi


MAILSUBJECT="autobuild: pid=$$ branch=$BRANCH user=$GITUSER"


if [ -n "$MAILTO" ]; then
    NOW=`date`
    mail -s "$MAILSUBJECT time=`date` : start" $MAILTO < /dev/null
fi

cd $WS_ROOT

# Set one build date for all builds
export ONL_BUILD_TIMESTAMP=`date +%Y.%m.%d.%H.%M`
export ONL=/build/onl
: ${INSTALL_SERVER:=switch-nfs}
: ${INSTALL_BASE_DIR:=/var/export/onl/autobuilds}
INSTALL_AUTOBUILD_DIR=${INSTALL_BASE_DIR}/$USERDIR"$BRANCH"
INSTALL_DIR=${INSTALL_AUTOBUILD_DIR}/$ONL_BUILD_TIMESTAMP.$SHA1

#
# Remount the current workspace to /build/onl
#
pwd
cat <<EOF > .chwsrc
bind_mount_dst $ONL_ROOT $ONL
EOF

rm -rf $ONL_ROOT/builds/BUILDS

#
# Optimized parallel build setups
#
(chws make -C /build/onl/builds CCACHE_DIR=/mnt/cache/ccache parallel0 -j $JOBS) || true
(chws make -C /build/onl/builds CCACHE_DIR=/mnt/cache/ccache parallel1 -j $JOBS) || true
(chws make -C /build/onl/builds CCACHE_DIR=/mnt/cache/ccache parallel2 -j $JOBS) || true
(chws make -C /build/onl/builds CCACHE_DIR=/mnt/cache/ccache parallel3 -j $JOBS) || true
(chws make -C /build/onl/builds CCACHE_DIR=/mnt/cache/ccache parallel4 -j $JOBS) || true
(chws make -C /build/onl/builds CCACHE_DIR=/mnt/cache/ccache parallel5 -j $JOBS) || true
(chws make -C /build/onl/builds CCACHE_DIR=/mnt/cache/ccache parallel6 -j $JOBS) || true

#
# Anything that still needs to be built (this shouldn't fail).
#
(chws make -C /build/onl/builds CCACHE_DIR=/mnt/cache/ccache components)

function build_and_install {
    # Build Requested
    chws make -C /build/onl/builds CCACHE_DIR=/mnt/cache/ccache $@

    # Make the install directory
    ssh $INSTALL_SERVER mkdir -p $INSTALL_DIR

    # Copy all build products to the install directory
    scp $ONL_ROOT/builds/BUILDS/* $INSTALL_SERVER:$INSTALL_DIR

    # Update latest and build manifest
    ssh $INSTALL_SERVER $INSTALL_BASE_DIR/update-latest.py --dir $INSTALL_AUTOBUILD_DIR --force

    if [ -n "$MAILTO" ]; then
        ARGS="$@"
	mail -s "$MAILSUBJECT time=`date` : built and installed $ARGS" $MAILTO < /dev/null
    fi
}

# Build primary targets for testing
build_and_install swi-all installer-all

# Copy the loader binaries (hack)
ssh $INSTALL_SERVER mkdir -p $INSTALL_DIR/loaders
LOADERS=`find $ONL_ROOT/debian/installs -name "*.loader"`
scp $LOADERS $INSTALL_SERVER:$INSTALL_DIR/loaders

# Copy all debian packages
ssh $INSTALL_SERVER mkdir -p $INSTALL_DIR/repo
scp -r $ONL_ROOT/debian/repo $INSTALL_SERVER:$INSTALL_DIR
ssh $INSTALL_SERVER rm $INSTALL_DIR/repo/update.sh $INSTALL_DIR/repo/.lock $INSTALL_DIR/repo/.gitignore || true

# Kick off automated tests here for primary targets
if [ -n "$ABAT_SUFFIX" ]; then
    $ONL_ROOT/tools/autotests.sh "$ABAT_SUFFIX" || true
fi

# Update build manifest
ssh $INSTALL_SERVER $INSTALL_BASE_DIR/update-latest.py --update-manifest --dir $INSTALL_AUTOBUILD_DIR --force

if [ -n "$MAILTO" ]; then
    NOW=`date`
    mail -s "$MAILSUBJECT time=`date`: finished" $MAILTO < /dev/null
fi












