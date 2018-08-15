#!/usr/bin/python
#
# Another quick hack of a script to find files unchanged
# since a given commit.
#
# This code is part of the LWN git data miner.
#
# Copyright 2007-11 Eklektix, Inc.
# Copyright 2007-11 Jonathan Corbet <corbet@lwn.net>
#
# This file may be distributed under the terms of the GNU General
# Public License, version 2.
#
import sys, os

OriginalSin = '1da177e4c3f41524e886b7f1b8a0c1fc7321cac2'

def CheckFile(file):
    git = os.popen('git log --pretty=oneline -1 ' + file, 'r')
    line = git.readline()
    if line.startswith(OriginalSin):
        print file
    git.close()
#
# Here we just plow through all the files.
#
if len(sys.argv) != 2:
    sys.stderr.write('Usage: findoldfiles directory\n')
    sys.exit(1)

os.chdir(sys.argv[1])
files = os.popen('/usr/bin/find . -type f', 'r')
for file in files.readlines():
    if file.find('.git/') < 0:
        CheckFile(file[:-1])
