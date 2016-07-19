# Rationale

By default, the ONL file system is NOT persistent, meaning that if you
reboot, your changes will dissapear (!!).  While this may sound suboptimal
at first, it does have the incredibly nice property of ensuring that many
classes of configuration and other problems can go away with a reboot.
This is particularly nice when you have a switch that may be headless
(no permanently connected console cable or keyboard).

ONL accomplishes this with OverlayFS
(https://www.kernel.org/doc/Documentation/filesystems/overlayfs.txt).
As described at http://opennetlinux.org/docs/bootprocess, the ONL
switch image (.SWI file) contains a read-only root file system image.
The default ONL root file system is then a copy-on-write (using overlayfs)
view into that file system image.

It has the following properites:

* Any file that is editted/removed/etc is transparently copied into a RAM disk via overlayfs
* Thus, any changes to files appear as you would expect, until a reboot
* Any file that is uneditted remains backed by the /mnt/flash2 file system, so you 
    do not need to have enough RAM to store the entire rootfs.  This is important with
    switches that do not have much RAM to begin with.

That said, ONL does have a provision to persist explicitly marked files
across a reboot.  This document shows how this works.


# Persisting Files

Just run `/sbin/persist /path/to/file` to mark a file as 'persisted'.  This
file will be saved to the /mnt/flash persistent storage device and automatically
put back into place on reboot.  Once a file has been persisted, it will always
be persisted across reboots.  If you really want to unpersist a file, manually remove it from
'/persist/rootfs/path/to/file'.

# Under the covers

Running `/sbin/persist file` makes a hardlink of that file, e.g., /foo/bar/baz, to
/persist/rootfs/foo/bar/baz.  

The `/etc/init.d/restorepersist` script runs on bootup and does a number of things:

* Restores the previously saved cpio archive from /mnt/flash/persist/rootfs into both / and /persist/rootfs
* Sets up hard links between /persist/rootfs/foo/bar/baz and /foo/bar/baz
* Starts a `watchdir` process for changes in /persist/rootfs

`watchdir` in turn uses the inotify(3) subsystem to, upon a change, run `/sbin/savepersist /persist/rootfs`.

And so, any change to a persisted file is noticed by watchdir and saved
to /mnt/flash in a cpio archive automatically using /sbin/savepersist.

# Limitations

You cannot persist any file that is read/used before `/etc/rcS.d/S03restorepersist` is run, including this script itself.  Also, it is NOT recommended for persisting logging files, e.g., /var/log/*.  While technically this will work, you will likely quickly exceed the write cycle limit of the underlying flash memory.  Better to use a syslog server.
