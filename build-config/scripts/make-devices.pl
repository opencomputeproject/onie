#!/usr/bin/perl
################################################################################
#
#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
# This script builds a linux root file system.  It is a component of the build-out
# system that also builds a cross-compilation tool chain and linux kernel.
#
# See the POD at the end of the program for a more extensive explanation.
#
################################################################################
#
use IO::File;
use File::Path;
use Cwd 'abs_path';
use Getopt::Long;
use Pod::Usage;
use strict;
use warnings;

our ($ourversion);
our ($rootdir, $devdir);

$ourversion = "0.0.1";

&handle_commandline();

#
# Check to make sure we are running as root (preferably using sudo)
#

die ("must be run as root (sudo recommended), stopped")
    if ($< != 0);

my $caller_uid = exists ${ENV{"SUDO_UID"}} ? ${ENV{"SUDO_UID"}} : 0;
my $caller_gid = exists ${ENV{"SUDO_GID"}} ? ${ENV{"SUDO_GID"}} : 0;

#
# Do the work
#

&devices();
exit 0;



################################################################################
#
# Note that ARGV still has any packages specified on the command line
#
sub handle_commandline
{
    $rootdir  = "./sysroot";

    our (@opt_repos);
    GetOptions ( "help"         => sub { pod2usage(-verbose => 2) },
		 "man"          => sub { pod2usage(-verbose => 2) }
	) or pod2usage(-verbose => 2);

    print "make-devices.pl version ${ourversion}\n";

    #
    # Sanitize the root directory
    #

    ${rootdir} = $ARGV[0] if ($#ARGV >= 0);

    die "Root file system can NOT point to /, stopped"
	if ${rootdir} eq "/";

    die "Root file system \"${rootdir}\" does not exist, stopped"
	unless -d ${rootdir};

    ${rootdir} = Cwd::abs_path( ${rootdir} );

    die "Root file system \"${rootdir}\" should have /etc, /var, /lib, and /usr, stopped"
	unless (-d "${rootdir}/etc" &&
		-d "${rootdir}/var" &&
		-d "${rootdir}/lib" &&
		-d "${rootdir}/usr" );
}


################################################################################
#
# Create a slew of required devices
#
# The basis for this is a list lf "MAKEDEVs" and mknods in an emdebian "fixup"
# script (at http://wiki.ebian.org/Multistrap") which I broke down into the
# constituent components and pruned.
#
sub devices
{
    $devdir = "${rootdir}/dev/";
    print "Creating required devices in ${devdir}\n";
    system("mkdir -p -m 755 ${devdir}");

    # Get the correct gids we need

    my $root = 0;
    my $kmem = ${root};
    my $tty  = ${root};
    my $disk = ${root};
    my $dial = ${root};

    my $groupfile = "${rootdir}/etc/group";
    if( open(GROUP, "${groupfile}") ) {
	while (<GROUP>) {
	    @_ = split(/:/);
	    $kmem = $_[2] if ( $_[0] eq "kmem" );
	    $tty  = $_[2] if ( $_[0] eq "tty" );
	    $disk = $_[2] if ( $_[0] eq "disk" );
	    $dial = $_[2] if ( $_[0] eq "dialout" );
	}
	close GROUP;

	$kmem or print "Did not find a \"kmem\" group in ${groupfile}, using root gid\n";
	$tty  or print "Did not find a \"tty\" group in ${groupfile}, using root gid\n";
	$disk or print "Did not find a \"disk\" group in ${groupfile}, using root gid\n";
	$dial or print "Did not find a \"dialout\" group in ${groupfile}, using root gid\n";
    } else {
	print "Unable to open ${groupfile}: make all devices with root gid\n";
    }

    print "Create a set of basic devices:\n";
    print "  mem, kmem, null, port, zero, core, full, random, urandom, tty, ram, and loop\n";
    makedev("mem",     "c", 1, 1, ${root}, ${kmem}, 0640);
    makedev("kmem",    "c", 1, 2, ${root}, ${kmem}, 0640);
    makedev("null",    "c", 1, 3, ${root}, ${root}, 0666);
    makedev("port",    "c", 1, 4, ${root}, ${kmem}, 0640);
    makedev("zero",    "c", 1, 5, ${root}, ${root}, 0666);
    makedev("full",    "c", 1, 7, ${root}, ${root}, 0666);
    makedev("random",  "c", 1, 8, ${root}, ${root}, 0666);
    makedev("urandom", "c", 1, 9, ${root}, ${root}, 0666);
    makedev("tty",     "c", 5, 0, ${root}, ${tty},  0666);
    symlink "/proc/kcore", "${devdir}core";
    foreach my $i (0..16) {
	makedev("ram${i}", "b", 1, ${i}, ${root}, ${disk}, 0660);
    }
    symlink "./ram1", "${devdir}ram";
    foreach my $i (0..7) {
	makedev("loop${i}", "b", 7, ${i}, ${root}, ${disk}, 0660);
    }

    print "Create the console, ttys, and serial devices: console, vcs, vcsa, tty, ttyS\n";
    makedev("console", "c", 5, 1, ${root}, ${tty}, 0600);
    foreach my $i (0..15) {
	makedev("tty${i}",  "c", 4, ${i}, ${root}, ${tty}, 0600);
	makedev("vcs${i}",  "c", 7, ${i}, ${root}, ${tty}, 0600);
	makedev("vcsa${i}", "c", 7, (${i}+128), ${root}, ${tty}, 0600);
    }
    symlink "./vcs0", "${devdir}vcs";
    symlink "./vcsa0", "${devdir}vcsa";
    foreach my $i (0..2) {
	makedev("ttyS${i}", "c", 4, (${i}+64), ${root}, ${dial}, 0660);
    }

    print "Basic file descriptors: stdin, stdout, stderr\n";
    symlink "/proc/self/fd", "${devdir}fd";
    symlink "./fd/0", "${devdir}stdin";
    symlink "./fd/1", "${devdir}stdout";
    symlink "./fd/2", "${devdir}stderr";

    print "Create the pseudo-terminal devices: ptmx pts/\n";
    makedev("ptmx", "c", 5, 2, ${root}, ${tty}, 0666);
    mkdir "${devdir}pts", 0755;

    print "NOR flash access: mtd mtdblock\n";
    foreach my $i (0..7) {
	makedev("mtdblock${i}", "b", 31, ${i},     ${root}, ${root}, 0660);
	makedev("mtd${i}",      "c", 90, (2*${i}), ${root}, ${root}, 0660);
    }

    print "UBI device access: ubi\n";
    makedev("ubi_ctrl", "c", 10, 63, ${root}, ${root}, 0660);
    makedev("ubi0"    , "c", 253, 0, ${root}, ${root}, 0660);
    foreach my $i (0..7) {
	makedev("ubi0_${i}", "c", 253, ${i}+1, ${root}, ${root}, 0660);
    }

    print "SD flash access: mmcblk0 mmcblk0p{1..7}\n";
    makedev("mmcblk0",          "b", 179,    0, ${root}, ${root}, 0660);
    foreach my $i (1..7) {
	makedev("mmcblk0p${i}", "b", 179, ${i}, ${root}, ${root}, 0660);
    }

    print "I2C:\n";
    foreach my $i (0..3) {
	makedev("i2c-${i}", "c", 89, ${i}, ${root}, ${root}, 0660);
    }

    print "Miscellaneous devices: shm rtc nvram\n";
    mkdir "${devdir}shm", 0777;
    makedev("rtc0", "c", 254, 0, ${root}, ${root}, 0660);
    symlink "./rtc0", "${devdir}rtc";
    makedev("nvram", "c", 10, 144, ${root}, ${root}, 0660);

    print "SCSI Devices: sda sdb sdc sdd\n";
    makedev("sda", "b", 8, 0, ${root}, ${disk}, 0660);
    makedev("sdb", "b", 8, 16, ${root}, ${disk}, 0660);
    makedev("sdc", "b", 8, 32, ${root}, ${disk}, 0660);
    makedev("sdd", "b", 8, 48, ${root}, ${disk}, 0660);
    foreach my $i (1..15) {
	makedev("sda${i}", "b", 8, ${i}, ${root}, ${disk}, 0660);
    }
    foreach my $i (1..15) {
	makedev("sdb${i}", "b", 8, ${i} + 16, ${root}, ${disk}, 0660);
    }
    foreach my $i (1..15) {
	makedev("sdc${i}", "b", 8, ${i} + 32, ${root}, ${disk}, 0660);
    }
    foreach my $i (1..15) {
	makedev("sdd${i}", "b", 8, ${i} + 48, ${root}, ${disk}, 0660);
    }

}


# usage: makedev(name, [bcu], major, minor, owner, group, mode)
#
sub makedev
{
    if (@_ != 7) {
	print STDERR "makedev should be called with name, type, major, minor, owner, group, mode";
	die(", stopped");
    }
    my ($name, $type, $major, $minor, $owner, $group, $mode) = @_;
    my $temp  = "${name}-";
    my $errstr = "${name} ${type} ${major} ${minor} ${owner} ${group} ${mode}";

    unlink "${devdir}${temp}";
    system("mknod ${devdir}${temp} ${type} ${major} ${minor}") == 0 or
	die "Unable to make temp device: ${errstr}, stopped";

    chown ${owner}, ${group}, "${devdir}${temp}" or
	die "Unable to chown temp device: ${errstr}, stopped";

    chmod ${mode}, "${devdir}${temp}" or
	die "Unable to chmod temp device: ${errstr}, stopped";

    rename "${devdir}${temp}", "${devdir}${name}" or
	die "Unable to mv temp device to real: ${errstr}, stopped";
}

################################################################################
#

=head1 NAME

make-devices.pl

=head1 SYNOPSIS

  make-devices.pl <rootdir>
  make-devices.pl -man|-h|--help

=head1 OPTIONS

=over 8

=item B<rootdir>

Indicates a system root (as in chroot) in which to create the devices.  For
safety purposes, this directory can not be "/".  The directory is checked for
existence as well as the presence of a few directories (etc, var, lib, usr)
that suggest that it's a system rootfs.

B<Defaults to ./sysroot> if not supplied on the command line.

=back

=head1 DESCRIPTION

make-devices.pl creates a set of baseline devices required by our embedded systems.

=over

=item Basic devices

mem, kmem, null, port, zero, core, full, random, urandom, tty, ram, and loop

=item The console, ttys, and serial devices

console, vcs, vcsa, tty, ttyS

=item Basic file descriptors

stdin, stdout, stderr

=item Pseudo-terminal devices

ptmx pts

=item MTDs for flash access

mtd mtdblock

=item Miscellaneous devices

shm rtc

=back

make-devices.pl B<MUST BE RUN WITH ROOT PRIVILEGES>, and it checks to make
sure that this is the case.
=cut
