Basic Debugging
===============

When developing new software for ONIE sometimes you need a little
help.


``strace(1)``
-------------

The `strace(1) <http://linux.die.net/man/1/strace>`_ utility is very
handy when developing and debugging programs.  Use it at runtime on
the target platform to trace the system calls made by a program.

Dynamic Libraries
-----------------

When trying to debug which dynamic libraries a program is trying to
load the `ldd(1) <http://linux.die.net/man/1/ldd>`_ utility is very
handy.  Doing this in an embedded cross-compile environment, however,
can be a little challenging.  The ONIE project does not have ``ldd``
exactly, but we offer something very close.

At runtime on the target platform you can get basic LDD information by
setting the environment variable LD_TRACE_LOADED_OBJECTS=1.  For
example::

  ONIE:/ # LD_TRACE_LOADED_OBJECTS=1 /usr/bin/grub-mkimage
          libdevmapper.so.1.02 => /usr/lib/libdevmapper.so.1.02 (0x7fc806c29000)
          libgcc_s.so.1 => /lib/libgcc_s.so.1 (0x7fc806a14000)
          libc.so.0 => /lib/libc.so.0 (0x7fc8067c8000)
          libpthread.so.0 => /lib/libpthread.so.0 (0x7fc8065b0000)
          libm.so.0 => /lib/libm.so.0 (0x7fc8063a3000)
          libdl.so.0 => /lib/libdl.so.0 (0x7fc80619f000)
          ld64-uClibc.so.0 => /lib/ld64-uClibc.so.0 (0x7fc806e62000)

For debugging LDD at build time the ONIE project includes a
``cross-ldd`` you can run on your build host.  The cross-ldd is
implemented as a Makefile target.  The core of cross-ldd comes from
the `crosstool-NG project <http://crosstool-ng.org/>`_.

For example to inspect the PowerPC /usr/bin/dropbearmulti binary from
your x86_64 build host you would invoke the Makefile 'ldd' target like
this::

  monster-04:~/onie-cn/onie/build-config$ gmake -j48 MACHINEROOT=../machine MACHINE=fsl_p2020rdbpca ldd LDD_TARGET=usr/bin/dropbearmulti
          libcrypt.so.0 => /lib/libcrypt.so.0 (0xdeadbeef)
          libc.so.0 => /lib/libc.so.0 (0xdeadbeef)
          ld-uClibc.so.0 => /lib/ld-uClibc.so.0 (0xdeadbeef)
          libutil.so.0 => /lib/libutil.so.0 (0xdeadbeef)
          libz.so.1 => /usr/lib/libz.so.1 (0xdeadbeef)
          libgcc_s.so.1 => /lib/libgcc_s.so.1 (0xdeadbeef)
          libm.so.0 => /lib/libm.so.0 (0xdeadbeef)
