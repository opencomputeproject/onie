
.. _demo_diag_os:

****************************
Demo Diagnostic OS Installer
****************************

The ONIE distribution also comes with a demonstration *diagnostic*
installer.  This is an installer that illustrates how to write an
installer for a diagnostic image as discussed in :ref:`hw_diag`.

The demo diag OS installer illustrates a number of concepts, useful
for hardware vendors creating their own hardware diagnostic
installers:

* Where the diag image resides in the system
* How to boot the diagnostic image from ONIE
* Other architecture specific requirements for diagnostic images

Building the Demo Diag OS Installer
-----------------------------------

Building the demo diag OS installer follows the same mechanism
described in the :ref:`demo_building` section.  Just build the
``demo`` target.

This Makefile target will build **both** the demo OS installer and the
demo diagnostic OS installer.  When compilation finishes, the demo
diagnostic OS installer is located in
``build/images/demo-diag-installer-<platform>.bin``.

Installing the Demo Diag Installer
----------------------------------

Install the demo diagnostic OS the same way you install any other ONIE
OS installer.

.. note:: The order of operations in the factory for installing a diag
  on a new machine must follow:

  #. Install ONIE
  
  #. Install the diagnostic OS

