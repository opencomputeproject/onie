This directory serves as a single interface point for all the
keys and configuration used in cryptographic signing.

Note that the utilities here will read configuration from
the build target's machine-security.make file.

Contents:
 onie-encrypt.sh and onie-encrypt.lib
   - A utility that can generate:
     demonstration keys in many different formats, using
     the target system's machine-security.make  makefile fragment.
   - Run a signing audit to confirm what has been signed and how.

 mk-key-and-cert
   - a key generation script lifted from the kvm_x86_64 build.

 AddingKeysToUEFIBIOS.txt
   - Instructions for finding and adding keys to an emulated BIOS

README-encryption.txt
   - Describes the directory role

write-keys.nsh
   - A script to be run in the UEFI BIOS shell that will set
     updated KEK and DB variables from supplied, signed files.

machines/<machine name>
   - A directory generated to hold encryption specific files for
     a machine target build. This includes signing keys,
     UEFI variables, UEFI binaries, and a location for a
     signed shim.

Customize as necessary.
