#Open Network Linux Quickstart


Build Hosts and Environments
------------------------------------------------------------
Ubuntu:
- 12.10
- 13.04
- 13.10

Debian:
- 7.5

Environments:
* Bare metal
* Hyper-V
* VMWare
* KVM

Prerequisites
------------------------------------------------------------

- sudo access with no password required.
- $HOSTNAME is resolvable to an IP address
- IP forwarding enabled on build machine
    * in /etc/sysctl.conf, set net.ipv4.ip_forward=1
    * `sudo sysctl -p`
- NetworkManager (or similar utilities) is disabled
    * Either disable via `sudo service networkmanager stop`
    * Or tell NetworkManager to ignore new interfaces:
        https://wiki.debian.org/NetworkManager#Wired_Networks_are_Unmanaged

General
------------------------------------------------------------
The login for all image builds is user `root`, password `onl`

Create a work directory
------------------------------------------------------------
    #> mkdir work
    #> cd work

Get the sources
------------------------------------------------------------
    #> git clone git://github.com/opennetworklinux/ONL

Install required build dependencies on your host machine.
------------------------------------------------------------
    #> cd onl
    #> make install-host-deps

Create an ONL Workspace
------------------------------------------------------------

The ONL workspace is a debian wheezy chroot environment
will all tools installed for cross compiling and
multistrapping.

The `install-host-deps` step installed two tools into your
host build machine:

    `onl-mkws`
    `onl-chws`

The `onl-mkws` tool creates a build workspace.
The `onl-chws` tool enters a build workspace.

Create a build workspace and name it `ws.amd64`.
Do this in your work directory, not the ONL tree:
------------------------------------------------------------
    #> cd ..        # should be in ~/work or equivalent
    #> onl-mkws -a amd64 ws.amd64

Change to the ONL workspace you just created.
------------------------------------------------------------
    #> cd ws.amd
    #> onl-chws         # enter workspace

You are now in a chrooted, network-isolated workspace.

Go back into the ONL tree and install the required build dependencies into your workspace
------------------------------------------------------------
    #> cd ../onl                # now in the workspace
    #> make install-ws-deps


You are now ready to build ONL.

    # To build the powerpc images, run:
    #> make onl-powerpc

    # To build the kvm images, run:
    #> make onl-kvm

Additional Details
----------------------------------------------------------

The rest of this guide talks about how to build specific 
sub-components of the ONL ecosystem.

Build all component packages for powerpc, i386, and amd64.

    #> cd $ONL/builds/components
    #> make

Not all architectures are needed for all builds under
normal circumstances but for the purposes of this Quickstart
we will just build everything.

A number of things will happen automatically, including:
- git submodule updates for kernel, loader, and code repositories
- automatic builds of all debian packages and their dependencies

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
    #> cd $ONL/builds/swi/i386/kvm
    #> make
    #> ls *.swi
    onl-i386-kvm-2014.01.27.11.53.swi  onl-i386-kvm.swi
    #>

Build the KVM Loader+SWI images for running ONL under KVM:
------------------------------------------------------------
    #> cd $ONL/builds/kvm/i386/onl
    #> make

If you have KVM installed, you can use it now to run
the Open Network Linux Loader and i386 SWI.

See `$ONL/make/kvm.mk` for details.

After you system is setup, you can run it as follows.

    #> cd $ONL/builds/kvm/i386/onl
    #> make run-nat

You should run this from your local build machine directory,
not from the workspace, if you want bridged networking to work.
NAT networking should always work.
