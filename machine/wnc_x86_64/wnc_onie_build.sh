#! /bin/sh

# Check if build/download/ have pkgs or not, if n, then check wnc.patch/download is exist or not, if y, then copy.
dir=`ls ../../build/download/`
if [ "$dir" = "" ]; then
    local_dl=`ls wnc.patch/download`
    if [ "$local_dl" != "" ]; then
        mkdir -p ../../build/download
        cp -rf wnc.patch/download/* ../../build/download
    fi
fi
#

# Copy file to each dirs which we modify or added.
cp -rf wnc.patch/* ../../
#

# Two mode, build iso, or Demo OS.
if [ "$1" = "" ]; then
    echo "Build boot iso...."
    cd ../../build-config && make -j4 MACHINE=wnc_x86_64 all recovery-iso
elif [ "$1" = "demo" ]; then
    echo "Build demo OS...."
    cd ../../build-config && make -j4 MACHINE=wnc_x86_64 demo
else
    echo "Error!"
fi

