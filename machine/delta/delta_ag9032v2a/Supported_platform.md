There are some of platforms which use the same design of CPU board.
So we share the same onie's source with defferent model name. 
if using the default way to build onie and we will get the ag9032v2a platform.

    $ cd build-config
    $ make -j4 MACHINEROOT=../machine/delta MACHINE=delta_ag9032v2a all

We use the delta_ag9032v2a as base to extend other model and list the externed model in the following.
 
1. delta_agc7648sv1 
    $ cd build-config
    $ make -j4 MACHINEROOT=../machine/delta MACHINE=delta_ag9032v2a ONIE_BUILD_MACHINE=delta_agc7648sv1 all


