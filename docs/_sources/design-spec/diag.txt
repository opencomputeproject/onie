.. _hw_diag:

*******************************
Hardware Diagnostics [Optional]
*******************************

Some hardware vendors may choose to include a permanently resident
diagnostic image with their hardware.

In order to have NOS installers co-operate with the already installed
hardware diagnostic image we need to layout some ground rules.  This
is similar to how a NOS installer co-operates with ONIE in general.

Specifying how to provide a diag image it will help:

* hardware vendors -- They will have guidance on how to create and
  store their diag image.

* software vendors -- They will understand how to invoke the diag and
  how to avoid destroying the diag when installing the NOS.

The main idea is that hardware vendors should install their diag OS
just like a NOS installer.

The specifics of how to do this are covered in the architecture
specific sections of this document.

Also to assist in creating a diag image the ONIE distribution provides
a demonstration diagnostic image installer.  See the
:ref:`demo_diag_os` section for more information.
