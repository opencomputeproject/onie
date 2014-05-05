***
FAQ
***

.. Add questions as sections headings and the answers as the section
   body.  For really long questions, abbreviate them in the heading
   and put the entire question in the section body.

What is ONIE?
=============

ONIE is a small operating system, pre-installed as firmware on bare
metal network switches, that provides an environment for automated
provisioning.

To get started, read the :ref:`onie_overview` section.

Is there an ONIE state transition diagram?
==========================================

The ONIE states and transitions can be a little confusing.  For a high
level overview of the states and transitions, read the :ref:`onie_fsm` section.

For more details, read the :ref:`full_design_spec` chapter.

Why is the default console baud rate 115200?
=============================================

It is the 21st century -- time to use a reasonably fast baud rate.

How often is ONIE released?
===========================

ONIE is released every 3 months.  For more details, read the
:ref:`release_cycle` section.

Is there a virtual machine implementation?
==========================================

Yes.  See the :ref:`x86_virtual_machine` section for details.

.. _cache_packages:

Can I set up a local cache of downloaded packages ONIE needs?
=============================================================

The problem is ONIE downloads various packages as it builds.  Can we
avoid downloading things all time?  Yes we can.

To avoid downloading the packages from across the ocean you can setup
a local cache of the packages.  You would need a HTTP server on your
local development network.

To setup the local cache read the documentation in the
onie/build-config/local.make.example file.  Rename this file to
local.make and the build system will use it.

In that file set the ``ONIE_MIRROR`` variable to point at your local
HTTP server.

To set up the cache do this:: 

  build-04:~/onie/build-config$ make download-clean 
  build-04:~/onie/build-config$ make download 

Now copy all the \*.gz \*.bz2 \*.xz files to your HTTP server.

Next set the ``ONIE_MIRROR`` variable in ``onie/build-config/local.make``
to match your HTTP server.

The crosstools-ng component also downloads a lot of packages.  It has
it's own config variable, ``CROSSTOOL_ONIE_MIRROR``.  After building
kvm_x86_64 ONIE once you can find the downloaded packages here:

  onie/build/x-tools/x86_64/build/build/tarballs 

Copy all those files to your HTTP server and set the 
``CROSSTOOL_ONIE_MIRROR`` variable accordingly. 

Now you should be all set. 

The build system will still download packages, but it will be from a 
local HTTP server and will be much faster. 

Can I copy an ONIE source tree work space to another location?
==============================================================

No.  The build environment does not allow copying or moving trees
around.  When building, "stamp" files are created that use the
*absolute* path names of files.  If you move a ONIE tree to a another
location the build system will be confused, with unexpected results.

If you do move an ONIE tree (which I don't recommend) you must first
clean out the tree by building the "distclean" target.  Like this::

  build-04:~/onie/build-config$ make distclean 

That will wipe out everything and you can proceed. 

.. note::

  The "clean" target will *not* clean up everything.  It will leave
  behind the toolchain and the downloaded packages.  The "distclean"
  target wipes out everything.

Are there any interesting Makefile targets lurking around?
==========================================================


- download -- downloads all the source packages, storing them in
  ``build/download``

- demo -- builds the demo OS and demo OS installer

- docs -- generates the HTML and PDF documentation 

- clean -- wipes out all build products for a particular
  machine. Downloads and the toolchain are *preserved*.

- download-clean -- wipes out all the downloaded packages

- distclean -- wipes out everything including downloads and the
  toolchain.

- debian-prepare-build-host -- Installs various packages needed to
  compile ONIE on a Debian based system, using "apt-get install".

