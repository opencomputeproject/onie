ONIE_ROOT=$(realpath $(dirname $0)/../../../)
MACHINE=$(basename $(dirname $(realpath $0)))
MACHINEROOT=$ONIE_ROOT/machine/netberg
PARAMS=$*
PARAMS=${PARAMS:-help}
BUILD_IMAGE=$ONIE_ROOT/build/images

make -C $ONIE_ROOT/build-config MACHINE=$MACHINE MACHINEROOT=$MACHINEROOT $PARAMS

if [[ $PARAMS =~ .*all.* ]] || [[ $PARAMS =~ .*demo.* ]]; then
    echo "Build images path: $BUILD_IMAGE"
    ls -l $BUILD_IMAGE/*${MACHINE}* | sed "s#$BUILD_IMAGE/##g"
fi

