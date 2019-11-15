#!/usr/bin/env python
#-*- coding:utf-8 -*-
#
# Copyright © 2009 Germán Póo-Caamaño <gpoo@gnome.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA

import sys
from patterns import patterns

class LogPatchSplitter:
    """
        LogPatchSplitters provides a iterator to extract every
        changeset from a git log output.

        Typical use case:

            patches = LogPatchSplitter(sys.stdin)

            for patch in patches:
                parse_patch(patch)
    """

    def __init__(self, fd):
        self.fd = fd
        self.buffer = None
        self.patch = []

    def __iter__(self):
        return self

    def next(self):
        patch = self.__grab_patch__()
        if not patch:
            raise StopIteration
        return patch

    def __grab_patch__(self):
        """
            Extract a patch from the file descriptor and the
            patch is returned as a list of lines.
        """

        patch = []
        line = self.buffer or self.fd.readline()

        while line:
            m = patterns['commit'].match(line)
            if m:
                patch = [line]
                break
            line = self.fd.readline()

        if not line:
            return None

        line = self.fd.readline()
        while line:
            # If this line starts a new commit, drop out.
            m = patterns['commit'].match(line)
            if m:
                self.buffer = line
                break

            patch.append(line)
            self.buffer = None
            line = self.fd.readline()

        return patch


if __name__ == '__main__':
    patches = LogPatchSplitter(sys.stdin)

    for patch in patches:
        print '---------- NEW PATCH ----------'
        for line in patch:
            print line,
