Open Network Linux Quickstart
=============================

------------------------------------------------------------
Requirements
------------------------------------------------------------
Build Host:
- Ubuntu 12.10 or 13.04.
- Ubuntu 13.10 should also work but has not
  been recently verified.
- sudo access with no password required.
- $HOSTNAME is resolvable to an IP address
- IP forwarding enabled on build machine
	* in /etc/sysctl.conf, set ipv4.ip_forward=1
	* sudo sysctl -p

------------------------------------------------------------
GENERAL
------------------------------------------------------------
The login for all image builds is user "root", passwd "onl"


------------------------------------------------------------
Create a work directory
------------------------------------------------------------
    #> mkdir work
    #> cd work

------------------------------------------------------------
Get the sources
------------------------------------------------------------
    #> git clone git://github.com/opennetworklinux/ONL


------------------------------------------------------------
Install required build dependencies on your host machine.
------------------------------------------------------------
    #> cd onl
    #> make install-host-deps


------------------------------------------------------------
Create an ONL Workspace

The ONL workspace is a debian wheezy chroot environment
will all tools installed for cross compiling and
multistrapping.

The install-build-host step installed two tools into your
host build machine:

    `mkws`
    `chws`

The mkws tool creates a build workspace.
The chws tool enters a build workspace.

Create a build workspace and name it ws.amd64.
Do this in your work directory, not the ONL tree:
------------------------------------------------------------
    #> cd ..		# should be in ~/work or equivalent
    #> mkws -a amd64 ws.amd64




------------------------------------------------------------
Change to the ONL workspace you just created.
Afterwards you will be in the chrooted, network-isolated
workspace.
------------------------------------------------------------
    #> cd ws.amd
    #> chws         # enter workspace


------------------------------------------------------------
Go back into the ONL tree and install required build
dependencies into your workspace
------------------------------------------------------------
    #> cd ../onl                # now in the workspace
    #> make install-ws-deps


------------------------------------------------------------
You are now ready to build ONL.
You will need to set $ONL to the root of the tree:
------------------------------------------------------------
    #> export ONL=`pwd`

------------------------------------------------------------
Build all component packages for powerpc, i386, and amd64.

Not all architectures are needed for all builds under
normal circumstances but for the purposes of this Quickstart
we will just build everything.

A number of things will happen automatically, including:
- git submodule updates for kernel, loader, and code repositories.
- automatic builds of all debian packages and their dependencies.

------------------------------------------------------------
    #> cd $ONL/builds/components
    #> make


------------------------------------------------------------
After all components have been build, your can build an ONL
Software Image from those components.

Build a software image (SWI) for all powerpc platforms:
------------------------------------------------------------
    #> cd $ONL/builds/swi/powerpc/all
    #> make
    #> ls *.swi
    onl-27f67f6-powerpc-all-2014.01.27.10.59.swi  onl-27f67f6-powerpc-all.swi
    #>

------------------------------------------------------------
Build an ONIE-compatible installer for all powerpc platforms.
This will incorporate the SWI you just built.

This installer image can be served to ONIE on a Quanta LB9
or Quanta LY2 platform:
------------------------------------------------------------
    #> cd $ONL/builds/installer/powerpc/all
    #> make
    #> ls *.installer
    latest.installer  onl-27f67f6-powerpc-all.2014.01.27.11.05.installer
    #>



------------------------------------------------------------
Build an i386 kvm-compatible SWI:
------------------------------------------------------------
    #> cd $ONL/builds/swi/i386/kvm
    #> make
    #> ls *.swi
    onl-i386-kvm-2014.01.27.11.53.swi  onl-i386-kvm.swi
    #>



------------------------------------------------------------
Build the KVM Loader+SWI images for running ONL under KVM:
------------------------------------------------------------
    #> cd $ONL/builds/kvm/i386/onl
    #> make


------------------------------------------------------------
If you have KVM installed, you can use it now to run
the Open Network Linux Loader and i386 SWI.

See $ONL/make/kvm.mk for details.

After you system is setup, you can run it as follows.
You should run this from your local build machine directory,
not from the workspace, if you want bridged networking to work.
NAT networking should always work:
------------------------------------------------------------
    #> cd cd $ONL/builds/kvm/i386/onl
    #> make run-nat


