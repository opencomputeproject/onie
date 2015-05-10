#How to Build Open Network Linux 

In case you are not interested in building ONL from scratch
(it takes a while) you can download pre-compiled binaries from
http://opennetlinux.org/binaries .


Build Hosts and Environments
------------------------------------------------------------
ONL now builds with Docker (yay!) so the only requirements on the
build system is:

- docker			# to grab the build workspace
- binfmt-support		# kernel support for ppc builds
- About 20G of disk free space 	# to build all images

On a modern Ubuntu system, you can get these with:

    # apt-get install lxc-docker binfmt-support

Historical Note: the previous workspace workflow (with `onl-mkws` and
`onl-chws`) was actually a home grown Docker-like Linux container based
system, so this is not a fundamental change in how ONL is built.


Build ONL Summary
------------------------------------------------------------
    #> git clone git://github.com/opennetworklinux/ONL
    #> cd ONL
    #> make docker                                              # enter the docker workspace
    root@8onl-builder:/path/to/ONL# make onl-x86 onl-powerpc    # build both x86 and PPC images

The resulting ONIE installers are in
$ONL/builds/installer/$ARCH/all/onl-$VERSION-all.installer,
and the SWI files (if you want them) are in
$ONL/builds/swi/$ARCH/all/onl-$VERSION-all.swi.




#Installing Docker Gotchas

Docker installer oneliner (for reference: see docker.com for details)

    # apt-get install -y lxc-docker
or

    # wget -qO- https://get.docker.com/ | sh


Common docker related issues:

- Check out http://docs.docker.com/installation/ubuntulinux/ for detailed instructions
- You may have to update your kernel to 3.10+
- Beware that `apt-get install docker` installs a dock application not docker :-)  You want the lxc-docker package instead.
- Some versions of docker are unhappy if you use a local DNS caching resolver:
	- e.g., you have 127.0.0.1 in your /etc/resolv.conf
        - if you have this, specify DNS="--dns 8.8.8.8" when you enter the docker environment
 	- e.g., `make DNS="--dns 8.8.8.8" docker`

Consider enabling builds for non-privileged users with:

- `sudo usermod -aG docker $USER`
- If you run as non-root without this, you will get errors like "..: dial unix /var/run/docker.sock: permission denied"	
- Building as root is fine as well (it immediately jumps into a root build shell), so this optional
    
#Additional Build Details
----------------------------------------------------------

The rest of this guide talks about how to build specific 
sub-components of the ONL ecosystem and tries to overview
all of the various elements of the build.

Build all .deb packages for all architectures
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

Adding/Removing packages from a SWI:
------------------------------------------------------------

The list of packages for a given SWI are in

    $ONL/builds/swi/$ARCH/all/rootfs/rootfs.$ARCH	# for $ARCH specific packages
    $ONL/builds/swi/$ARCH/all/rootfs/rootfs		# for $ARCH-independent packages

Build a software image (SWI) for all powerpc platforms:
------------------------------------------------------------
    #> cd $ONL/builds/swi/powerpc/all
    #> make
    #> ls *.swi
    onl-27f67f6-powerpc-all-2014.01.27.10.59.swi  onl-27f67f6-powerpc-all.swi
    #>

Build an ONIE-compatible installer for all powerpc platforms.
This will incorporate the SWI you just built or build it dynamically if not.

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

After you host system is setup for kvm, you can run the image as follows.

    #> cd $ONL/builds/kvm/i386/onl
    #> make run-nat

You should run this from your local build machine directory,
not from the workspace, if you want bridged networking to work.
NAT networking should always work.
