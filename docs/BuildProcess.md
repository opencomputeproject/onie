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



Building the Installer (includes the ONL Loader)
-------------------
    * uses busybox and buildroot


Building the SWI
-------------------
    * 
    * uses "multistrap" cross-architecture installer


Common
-----------------
    * Using buildroot (installer) or multistrap (SWI), Install all of the .deb files into a temporary root file system
    * Setup binformats so that the binaries from $ARCH are run using QEMU as _native_ binaries
    ** This is required to correctly run the post-install scripts in the native architecture
