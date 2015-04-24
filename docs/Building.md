#How to Build Open Network Linux 


Build Hosts and Environments
------------------------------------------------------------
ONL now builds with Docker (yay!) so the only requirement on the
build system is that you have a modern version of docker installed.
We currently test with "Docker version 1.5.0, build a8a31ef", but
presumably others will work as well.

Historical Note: the previous workspace workflow (with `onl-mkws` and
`onl-chws`) was actually a home grown Docker-like Linux container based
system, so this is not a fundamental change in how ONL is built.


Build ONL Summary
------------------------------------------------------------
    #> git clone git://github.com/opennetworklinux/ONL
    #> cd ONL
    #> make docker                                              # enter the docker workspace
    root@8onl-builder:/path/to/ONL# make onl-x86 onl-powerpc    # build both x86 and PPC images

The resulting ONIE installers are in $ONL/builds/installer/$ARCH/all/onl-$VERSION-all.installer,
and the SWI files (if you want them) are in $ONL/builds/swi/$ARCH/all/onl-$VERSION-all.swi.



Additional Details
----------------------------------------------------------

The rest of this guide talks about how to build specific 
sub-components of the ONL ecosystem and tries to overview
all of the various elements of the build.

Installing Docker Gotchas
----------------------------------------------------------
Docker installer oneliner (for reference: see docker.com for details)
    # wget -qO- https://get.docker.com/ | sh


If you are installing on Ubuntu 14.04 or older:
    * You may have to update your kernel to 3.10+
    * Beware that `apt-get install docker` installs a dock application not docker :-)
    * Check out http://docs.docker.com/installation/ubuntulinux/ for details

Consider enabling builds for non-priviledged users with:
    * sudo usermod -aG docker
    

Build all .deb packages for powerpc, i386, and amd64.
----------------------------------------------------------
    #> cd $ONL/builds/components
    #> make
    #> find $ONL/debian/repo -name \*.deb    # all of the .deb files end up here

A number of things will happen automatically, including:
- git submodule checkouts and updates for kernel, loader, and additional code repositories
- automatic builds of all debian packages and their dependencies
- automatic download of binary-only .deb packages from apt.opennetlinux.org

After all components have been built, your can build an ONL
Software Image from those components.

Build a software image (SWI) for all powerpc platforms:
------------------------------------------------------------
    #> cd $ONL/builds/swi/powerpc/all
    #> make
    #> ls *.swi
    onl-27f67f6-powerpc-all-2014.01.27.10.59.swi  onl-27f67f6-powerpc-all.swi
    #>

Build an ONIE-compatible installer for all powerpc platforms.
This will incorporate the SWI you just built.

This installer image can be served to ONIE on Quanta or Accton platforms:
------------------------------------------------------------
    #> cd $ONL/builds/installer/powerpc/all
    #> make
    #> ls *.installer
    latest.installer  onl-27f67f6-powerpc-all.2014.01.27.11.05.installer
    #>

Build an i386 kvm-compatible SWI:
------------------------------------------------------------
    #> make onl-kvm

If you have KVM installed, you can use it now to run
the Open Network Linux Loader and i386 SWI.

See `$ONL/make/kvm.mk` for details.

After you system is setup, you can run it as follows.

    #> cd $ONL/builds/kvm/i386/onl
    #> make run-nat

You should run this from your local build machine directory,
not from the workspace, if you want bridged networking to work.
NAT networking should always work.
