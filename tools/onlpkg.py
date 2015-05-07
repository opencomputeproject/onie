#!/usr/bin/python
############################################################
# <bsn.cl fy=2013 v=onl>
# 
#        Copyright 2013, 2014 Big Switch Networks, Inc.       
# 
# Licensed under the Eclipse Public License, Version 1.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
# 
#        http://www.eclipse.org/legal/epl-v10.html
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the
# License.
# 
# </bsn.cl>
############################################################
#
# Open Network Linux Build Package Manager
#
############################################################
import sys
import os
import argparse
import shutil
import re
from debian import deb822
import logging
import subprocess
import fcntl


#
# Hack
# These are the closed source packages that can't be built 
# without magic priveledges

closed_source = [
"onlp-x86-64-dell-s4000-c2338-r0:amd64",
"onlp-x86-64-dell-s6000-s1220-r0:amd64",
"onlp-powerpc-as5610-52x:powerpc",
"onlp-powerpc-as4600-54t:powerpc",
"onlp-powerpc-as6700-32x-r0:powerpc",
"onlp-powerpc-as5710-54x-r0b:powerpc",
"onlp-powerpc-as5710-54x-r0a:powerpc",
"onlp-powerpc-accton-as5700-96x-r0:powerpc",
"onlp-powerpc-accton-as5610-52x-r0:powerpc",
"onlp-powerpc-accton-as6700-32x-r0:powerpc",
"onlp-powerpc-accton-as5710-54x-r0:powerpc",
"onlp-powerpc-accton-as4600-54t-r0:powerpc",
"onlp-x86-64-accton-as5712-54x-r0:amd64",
"onlp-x86-64-accton-as6712-32x-r0:amd64",
"onlp-powerpc-dni-7448-r0:powerpc"
];

#
# Hack
# Disabled and/or deprecated packages
#
disabled_packages = [
"onlp-powerpc-accton-as5700-96x-r0",
"platform-config-powerpc-accton-as5700-96x-r0" # disabled until this platform is ready
];

# add the closed_source packages to the disabled
# list unless the magic env is set
if not "ONL_CLOSED_SOURCE" in os.environ:
    disabled_packages += closed_source

def package_enabled(p):
    for dp in disabled_packages:
        if dp in p:
            return False
    return True

def find_file_or_dir(basedir, filename=None, dirname=None):
    """Find and return the path to a given file or directory below the given root"""
    for root, dirs, files in os.walk(basedir):
        for file_ in files:
            if file_ == filename:
                print "%s/%s" % (root, file_)
                sys.exit(0)
        if dirname and os.path.basename(root) == dirname and root != basedir:
            print "%s" % (root)
            sys.exit(0)

def find_component_dir(basedir, package_name):
    """Find the local component directory that builds the given package."""
    for root, dirs, files in os.walk(basedir):
        for file_ in files:
            if file_ == "Makefile" or file_ == "makefile":
                with open("%s/%s" % (root,file_), "r") as f:
                    data = f.read()
                    packages = re.findall("Package:(.*)", data)
                    if package_name in packages:
                        # By convention - this is the component directory.
                        return os.path.abspath(root)
            if file_ == "control":
                with open("%s/%s" % (root,file_), "r") as f:
                    control = f.read()
                    if "Package: %s " % package_name in control or "Package: %s\n" % package_name in control:
                        # By convention - find the parent directory
                        # That has a 'debian' directory in it.
                        logger.info("found at %s", root)
                        while not 'Makefile.comp' in os.listdir(root):
                            root += "/.."
                        return os.path.abspath(root)

def find_package(repo, package, arch):
    """Find a package by name and architecture in the given repo dir"""
    dirname = "%s/%s" % (repo, arch)
    if os.path.exists(dirname):
        manifest = os.listdir(dirname)
        return [ arch + "/" + x for x in manifest if arch in x and "%s_" % package in x ]
    else:
        return []


def find_all_packages(basedir):
    """Find all local component packages."""
    all_ = [];

    for root, dirs, files in os.walk(basedir):
        for file_ in files:
            if file_ == "Makefile" or file_ == "makefile":
                with open("%s/%s" % (root,file_), "r") as f:
                    data = f.read()
                    packages = re.findall("Package:(.*)", data)
                    architectures = re.findall("Architecture:(.*)", data)
                    if len(packages) > 0 and len(architectures) > 0:
                        arch = architectures[0].replace("Architecture:", "")
                        for p in packages:
                            p = p.replace("Package:", "")
                            all_.append("%s:%s" % (p, arch))

            if file_ == "control":
                f = file("%s/%s" % (root,file_))
                d = deb822.Deb822(f)
                while d:
                    if 'Package' in d:
                        arch = 'all'
                        if 'Architecture' in d:
                            arch = d['Architecture']
                        all_.append("%s:%s" % (d['Package'],arch))
                    d = deb822.Deb822(f)

    return sorted(all_)

def check_call(cmd, *args, **kwargs):
    if type(cmd) == str:
        logger.debug("+ " + cmd)
    else:
        logger.debug("+ " + " ".join(cmd))
    subprocess.check_call(cmd, *args, **kwargs)

############################################################

ap = argparse.ArgumentParser("Open Network Linux Build Package Manager")

ap.add_argument("packages", nargs='*', action='append',
                help="package:arch", default=None)

ap.add_argument("--force", help="Force reinstall",
                action='store_true')
ap.add_argument("--find-file", help="Return path to given file.",
                default=None)
ap.add_argument("--find-dir", help="Return path to the given directory.",
                default=None)
ap.add_argument("--build", help="Attempt to build local package if it exists.",
                action='store_true')
ap.add_argument("--add-pkg", nargs='+', action='append',
                default=None, help="Install new package files and invalidate corresponding installs.")
ap.add_argument("--list-all", action='store_true', help="List all available component packages")
ap.add_argument("--list", nargs='+', action='append', default=None, help="Search for matching package names.")
ap.add_argument("--force-build", help="Force rebuild from source.",
                action='store_true')
ap.add_argument("--verbose", action='store_true', help="verbose logging")
ap.add_argument("--quiet", action='store_true', help="minimal logging")
ap.add_argument("--extract", help="Extract package to the given directory.")

ops = ap.parse_args()

logging.basicConfig()
logger = logging.getLogger("onlpkg")
if ops.verbose:
    logger.setLevel(logging.DEBUG)
elif ops.quiet:
    logger.setLevel(logging.ERROR)
else:
    logger.setLevel(logging.INFO)

ONL = os.getenv('ONL')
package_dir = os.path.abspath("%s/debian/repo" % ONL)
repo_lockf = "%s/.lock" % package_dir

if ONL is None:
    raise Exception("$ONL is not defined.")


class Lock:
    def __init__(self, filename):
        self.filename = filename
        self.handle = open(filename, 'w')

    def acquire(self):
        logger.debug("acquiring lock %s" % self.filename)
        fcntl.flock(self.handle, fcntl.LOCK_EX)
        logger.debug("acquired lock %s" % self.filename)

    def release(self):
        fcntl.flock(self.handle, fcntl.LOCK_UN)
        logger.debug("released lock %s" % self.filename)

    def __del__(self):
        self.handle.close()

repoLock = Lock(repo_lockf)

if ops.list_all:
    all_ = find_all_packages(os.path.abspath("%s/components" % (ONL)))
    for p in all_:
        if not ":any" in p and package_enabled(p):
            print p
    sys.exit(0)

if ops.list:
    all_ = find_all_packages(os.path.abspath("%s/components" % (ONL)))
    for p in all_:
        if not ":any" in p and package_enabled(p):
            for substr in ops.list[0]:
                if substr in p:
                    print p
                    continue
    sys.exit(0)

if ops.add_pkg:
    repoLock.acquire();
    for pa in ops.add_pkg[0]:
        # Copy the package into the repo
        logger.info("adding new package %s...", pa)
        # Determine package name and architecture
        underscores = pa.split('_')
        # Package name is the first entry
        package = underscores[0]
        # Architecture is the last entry (.deb)
        arch = underscores[-1].split('.')[0]
        logger.debug("+ /bin/cp %s %s/%s", pa, package_dir, arch)
        dstdir = "%s/%s" % (package_dir, arch)
        if not os.path.exists(dstdir):
            os.makedirs(dstdir)
        shutil.copy(pa, dstdir)
        extract_dir = "%s/debian/installs/%s/%s" % (ONL, arch, package)
        if os.path.exists(extract_dir):
            # Make sure the package gets reinstalled the next time it's needed
            logger.info("removed previous install directory %s...", extract_dir)
            logger.debug("+ /bin/rm -fr %s", extract_dir)
            shutil.rmtree(extract_dir)
    repoLock.release()
    sys.exit(0)


for pa in ops.packages[0]:

    try:
        (package, arch) = pa.split(":")
    except ValueError:
        logger.error("invalid package specification: %s", pa)
        sys.exit(1)

    packages = []
    if not ops.force_build:
        packages = find_package(package_dir, package, arch)
    else:
        ops.build = True

    if len(packages) == 0:
        logger.warn("no matching packages for %s (%s)", package, arch)
        # Look for package builder
        buildpath = find_component_dir(os.path.abspath("%s/components/%s" % (ONL,arch)),
                                       package)
        if buildpath is not None:
            logger.info("can be built locally at %s", buildpath)
            if ops.build:
                check_call(('make', '-C', buildpath, 'deb',))
                packages = find_package(package_dir, package, arch)
        if len(packages) == 0:
            sys.exit(1)

    if len(packages) > 1:
        logger.error("multiple packages found: %s", packages)
        sys.exit(1)

    deb = packages[0]

    if ops.extract:
        # Just extract the contents into the given directory.
        if not os.path.exists(ops.extract):
            os.makedirs(ops.extract)
        check_call(('dpkg', '-x', "%s/%s" % (package_dir, deb), ops.extract))
        sys.exit(0)

    extract_dir = "%s/debian/installs/%s/%s" % (ONL, arch, package)

    repoLock.acquire()
    if os.path.exists("%s/PKG.TIMESTAMP" % extract_dir):
        if (os.path.getmtime("%s/PKG.TIMESTAMP" % extract_dir) ==
            os.path.getmtime("%s/%s" % (package_dir, deb))):
            # Existing extract is identical
            logger.debug("existing extract for %s:%s matches the package file.", deb, arch)
        else:
            # Extract must be updated.
            ops.force = True
            logger.warn("existing extract for %s:%s does not match the package file. Forcing extract.", deb, arch)

        if ops.force:
            logger.info("force removing %s...", extract_dir)
            logger.debug("+ /bin/rm -fr %s", extract_dir)
            shutil.rmtree(extract_dir)


    if not os.path.exists(extract_dir):
        logger.info("extracting %s/%s...", package_dir, deb)
        logger.debug("+ /bin/mkdir -p %s", extract_dir)
        os.makedirs(extract_dir)
        check_call(('dpkg', '-x', package_dir + '/' + deb, extract_dir,))
        check_call(('touch', '-r', package_dir + '/' + deb, extract_dir + '/PKG.TIMESTAMP',))

    repoLock.release()
    find_file_or_dir(extract_dir, ops.find_file, ops.find_dir);
