#
# -*- coding:utf-8 -*-
# Pull together regular expressions used in multiple places.
#
# This code is part of the LWN git data miner.
#
# Copyright 2007-11 Eklektix, Inc.
# Copyright 2007-11 Jonathan Corbet <corbet@lwn.net>
# Copyright 2011 Germán Póo-Caamaño <gpoo@gnome.org>
#
# This file may be distributed under the terms of the GNU General
# Public License, version 2.
#
import re

#
# Some people, when confronted with a problem, think "I know, I'll use regular
# expressions." Now they have two problems.
#    -- Jamie Zawinski
#
_pemail = r'\s+"?([^<]+)"?\s<([^>]+)>' # just email addr + name

patterns = {
    'tagcommit': re.compile (r'^commit ([\da-f]+) .*tag: (v[23]\.\d(\.\d\d?)?)'),
    'commit': re.compile (r'^commit ([0-9a-f ]+)'),
    'author': re.compile (r'^Author:' + _pemail + '$'),
    'signed-off-by': re.compile (r'^\s+signed-off-by:' + _pemail + '.*$', re.I),
    'merge': re.compile (r'^Merge:.*$'),
    'add': re.compile (r'^\+[^+].*$'),
    'rem': re.compile (r'^-[^-].*$'),
    'date': re.compile (r'^(Commit)?Date:\s+(.*)$'),
    # filea, fileb are used only in 'parche mode' (-p)
    'filea': re.compile (r'^---\s+(.*)$'),
    'fileb': re.compile (r'^\+\+\+\s+(.*)$'),
    'acked-by': re.compile (r'^\s+Acked-by:' + _pemail+ '.*$'),
    'reviewed-by': re.compile (r'^\s+Reviewed-by:' + _pemail+ '.*$'),
    'tested-by': re.compile (r'^\s+tested-by:' + _pemail + '.*$', re.I),
    'reported-by': re.compile (r'^\s+Reported-by:' + _pemail + '.*$'),
    'reported-and-tested-by': re.compile (r'^\s+reported-and-tested-by:' + _pemail + '.*$', re.I),
    #
    # Merges are described with a variety of lines.
    #
    'ExtMerge': re.compile(r'^ +Merge( (branch|branches|tag|tags) .* of)? ([^ ]+:[^ ]+)( into .*)?\n$'),
    'IntMerge': re.compile(r'^ +(Merge|Pull) .* into .*$'),
    # PIntMerge2 = re.compile(r"^ +Merge branch(es)? '.*$"),
    'IntMerge2': re.compile(r"^ +Merge .*$"),
    # Another way to get the statistics (per file).
    # It implies --numstat
    'numstat': re.compile('^(\d+|-)\s+(\d+|-)\s+(.*)$'),
    'rename' : re.compile('(.*)\{(.*) => (.*)\}(.*)'),
    # Detect errors on svn conversions
    'svn-tag': re.compile("^svn path=/tags/(.*)/?; revision=([0-9]+)$"),
}
