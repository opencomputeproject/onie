1. decompress stordis.tar.bz2 in $ONIE/machine folder
2. apply onie_20191106.patch
    - update the customer ONIE version into ONIE EEPROM
    - assign the first MAC addrerss to I210
3. compile
    cd $ONIE/build-config
    make -j4 MACHINEROOT=../machine/stordis MACHINE=stordis_bf2556x_1t all

