#!/usr/bin/env python

# -----------------------------------------------------------------------------
# Copyright (C) 2014-2015 Carlos Cardenas <carlos@cumulusnetworks.com>
#
# SPDX-License-Identifier:     GPL-2.0
#
# -----------------------------------------------------------------------------

import os
import os.path
import sys

BUILD_CONFIG_PATH = None
MACHINE_ROOT_PATH = None
VENDOR_MACHINES = {}


def is_vendor(vendor):
    global VENDOR_MACHINES
    return vendor in VENDOR_MACHINES


def is_machine(machine):
    global VENDOR_MACHINES

    for machines in VENDOR_MACHINES.values():
        if machine in machines:
            return True
    return False


def get_vendor(machine):
    global VENDOR_MACHINES

    for vendor, machines in VENDOR_MACHINES.items():
        if machine in machines:
            return vendor
    return None


def add_vendor_machine(vendor, machine):
    global VENDOR_MACHINES

    if vendor in VENDOR_MACHINES:
        machines = VENDOR_MACHINES[vendor]
        machines.append(machine)
        machines.sort()
    else:
        machines = [machine]
        VENDOR_MACHINES[vendor] = machines


def determine_machine_dir(dir):
    contents = os.listdir(dir)
    for f in contents:
        rel_path = os.path.join(dir, f)
        if os.path.isfile(rel_path) and f == 'machine.make':
            return True
    return False


def determine_paths():
    global BUILD_CONFIG_PATH
    global MACHINE_ROOT_PATH

    build_str = 'build-config'
    machine_str = 'machine'

    current_path = os.path.abspath(os.path.curdir)
    if os.path.basename(current_path) == 'oce':
        # calling from within the dir, go two dirs up
        BUILD_CONFIG_PATH = os.path.join(current_path, '..', '..', build_str)
        BUILD_CONFIG_PATH = os.path.abspath(BUILD_CONFIG_PATH)
        MACHINE_ROOT_PATH = os.path.join(current_path, '..', '..', machine_str)
        MACHINE_ROOT_PATH = os.path.abspath(MACHINE_ROOT_PATH)
    else:
        # check if this dir has machines and build_config
        found_build_config = False
        found_machine_root = False
        contents = os.listdir(current_path)
        for f in contents:
            if f == build_str:
                found_build_config = True
            if f == machine_str:
                found_machine_root = True

        if found_build_config and found_machine_root:
            BUILD_CONFIG_PATH = os.path.join(current_path, build_str)
            BUILD_CONFIG_PATH = os.path.abspath(BUILD_CONFIG_PATH)
            MACHINE_ROOT_PATH = os.path.join(current_path, machine_str)
            MACHINE_ROOT_PATH = os.path.abspath(MACHINE_ROOT_PATH)
        else:
            sys.stderr.write('Not a valid ONIE repo\n')
            sys.exit(-1)


def process_vendor_machines():
    global MACHINE_ROOT_PATH

    potential_vendors = []
    machine_dir = MACHINE_ROOT_PATH

    contents = os.listdir(machine_dir)
    for v in contents:
        rel_path = os.path.join(machine_dir, v)
        if os.path.isdir(rel_path):
            potential_vendors.append(v)

    for v in potential_vendors:
        rel_path = os.path.join(machine_dir, v)
        contents = os.listdir(rel_path)
        # contents might be a machine dir, check
        if determine_machine_dir(rel_path):
            # Add Vendor 'UNKNOWN' and machine dir
            add_vendor_machine('UNKNOWN', v)
        else:
            # We are in Vendor dir, listdir and determine machine_dir
            for mac in contents:
                potential_mac_path = os.path.join(machine_dir, v, mac)
                if determine_machine_dir(potential_mac_path):
                    add_vendor_machine(v, mac)


def list_all():
    global VENDOR_MACHINES
    from collections import OrderedDict
    sorted_dict = OrderedDict(sorted(VENDOR_MACHINES.items(),
                                     key=lambda t: t[0]))

    for key, values in sorted_dict.items():
        print key
        for v in values:
            print '\t{0}'.format(v)
        print '\n'


def build(machine_or_vendor, dry_run=True, args='', targets=None):
    import subprocess
    global MACHINE_ROOT_PATH
    global VENDOR_MACHINES

    if is_vendor(machine_or_vendor):
        # build everything under that vendor
        print 'Building everything for vendor: {0}'.format(machine_or_vendor)
        machines = VENDOR_MACHINES[machine_or_vendor]
        for machine in machines:
            build(machine, dry_run, args, targets)

    elif is_machine(machine_or_vendor):
        vendor = get_vendor(machine_or_vendor)
        print 'Building {0} / {1}'.format(vendor, machine_or_vendor)
        machine_root = os.path.join(MACHINE_ROOT_PATH, vendor)
        add_targets = ''
        if targets is not None and len(targets) > 0:
            add_targets = ' '.join(targets)

        if vendor != 'UNKNOWN':
            cmd = 'make {0} MACHINEROOT={1} MACHINE={2} all {3}'.\
                  format(args, machine_root, machine_or_vendor, add_targets)
        else:
            cmd = 'make {0} MACHINE={1} all {2}'.\
                  format(args, machine_or_vendor, add_targets)
        print cmd
        if not dry_run:
            subprocess.check_call(cmd, shell=True)

    else:
        print 'Invalid Target: {0}'.format(machine_or_vendor)


def main():
    import argparse
    global BUILD_CONFIG_PATH

    parser = argparse.ArgumentParser(description="Build ONIE")
    parser.add_argument('-l', '--list', action='store_true', default=False,
                        help='list all vendors and machines')
    parser.add_argument('-b', '--build', action='append', metavar='PLATFORM',
                        help='Vendor or Machine to compile')
    parser.add_argument('-n', '--dry-run', action='store_true', default=False,
                        help='perform a dry run, do not execute')
    parser.add_argument('-m', '--make-args', action='store', metavar='ARGS',
                        default='',
                        help='additional args to be passed to make')
    parser.add_argument('-t', '--target', action='append', metavar='MAKE',
                        help='make target to use (in addition to "all")')

    args = parser.parse_args()
    if args.list is None and args.build is None:
        parser.print_help()
        sys.exit(-1)

    determine_paths()
    process_vendor_machines()

    if args.list:
        list_all()
        sys.exit(0)

    if args.build:
        print 'cd {0}'.format(BUILD_CONFIG_PATH)
        os.chdir(BUILD_CONFIG_PATH)
        if 'all' in args.build:
            for vendor in VENDOR_MACHINES.keys():
                build(vendor, args.dry_run, args.make_args, args.target)
        else:
            for b in args.build:
                build(b, args.dry_run, args.make_args, args.target)
    else:
        sys.stderr.write('No action performed\n')
        parser.print_help()
        sys.exit(-1)

if __name__ == '__main__':
    main()
