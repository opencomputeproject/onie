Summary
-------------

Building ONL results in two binaries:
* the ONL installer (used by ONIE)
* the ONL SWitch Image (SWI) file

To maximize code reuse, these two binaries share a lot of code and installer scripts.
The code is layed out in different modules, git repositories, and "components".

* Modules are a collection of source files (e.g., C, headers, etc.) that create a library or binary
* Components are a collection of libraries and/or binaries that create a Debian .deb file (no RPM support yet!)
* Components and Modules are spread across many git repositories that in some cases refer to each other using git submodules
* The SWI file is a Linux root file system image and kernel where all of the components have been installed
    along with a number of other (e.g., binutils) stock packages
* The Installer is the ONIE-compatible self-extracting archive that wraps up the ONL loader with the SWI, completing the system



Building the Installer (includes the ONL Loader)
-------------------
    * uses busybox and buildroot


Building the SWI
-------------------
    * uses "multistrap" cross-architecture installer
    * Most of the work is done by:
        * The `onl-mkws` command
        * The $ONL/make/swi.mk Makefile
    * The lists of specific packages to install are found in:
        * $ONL/build/swi/$ARCH/all/rootfs/repo.{all,$ARCH}


Common
-----------------
    * Using buildroot (installer) or multistrap (SWI), Install all of the .deb files into a temporary root file system
    * Setup binformats so that the binaries from $ARCH are run using QEMU as _native_ binaries
    ** This is required to correctly run the post-install scripts in the native architecture

Debugging
---------------

The build system is quite complex.  I might argue that some of this complexity is necessary, but be at as it may,
it is still useful to know how leverage the built in debugging commands.

* All Makefiles take a VERBOSE=1 option (e.g., `make VERBOSE=1 deb`)
    that will be more explicit as to what it is doing.  Very helpful.

* Additionally, you can define ONL_V_at='' (e.g., `make ONL_V_at='' deb`) to make all of the various commands echo before
    printing.  All of the commands that are executed by the Makefile are prefaced with $ONL_V_at instead of a literal '@' to
    enable this feature.


