#
# The "database".
#
# This code is part of the LWN git data miner.
#
# Copyright 2007-11 Eklektix, Inc.
# Copyright 2007-11 Jonathan Corbet <corbet@lwn.net>
#
# This file may be distributed under the terms of the GNU General
# Public License, version 2.
#
import sys, datetime


class Hacker:
    def __init__ (self, name, id, elist, email):
        self.name = name
        self.id = id
        self.employer = [ elist ]
        self.email = [ email ]
        self.changed = self.added = self.removed = 0
        self.patches = [ ]
        self.signoffs = [ ]
        self.reviews = [ ]
        self.tested = [ ]
        self.reports = [ ]
        self.testcred = self.repcred = 0
        self.versions = [ ]

    def addemail (self, email, elist):
        self.email.append (email)
        self.employer.append (elist)
        HackersByEmail[email] = self

    def emailemployer (self, email, date):
        for i in range (0, len (self.email)):
            if self.email[i] == email:
                for edate, empl in self.employer[i]:
                    if edate > date:
                        return empl
        print 'OOPS.  ', self.name, self.employer, self.email, email, date
        return None # Should not happen

    def addpatch (self, patch):
        self.added += patch.added
        self.removed += patch.removed
        self.changed += max(patch.added, patch.removed)
        self.patches.append (patch)

    #
    # Note that the author is represented in this release.
    #
    def addversion (self, release):
        if release not in self.versions:
            self.versions.append (release)
    #
    # There's got to be a better way.
    #
    def addsob (self, patch):
        self.signoffs.append (patch)
    def addreview (self, patch):
        self.reviews.append (patch)
    def addtested (self, patch):
        self.tested.append (patch)
    def addreport (self, patch):
        self.reports.append (patch)

    def reportcredit (self, patch):
        self.repcred += 1
    def testcredit (self, patch):
        self.testcred += 1

HackersByName = { }
HackersByEmail = { }
HackersByID = { }
MaxID = 0

def StoreHacker (name, elist, email):
    global MaxID

    id = MaxID
    MaxID += 1
    h = Hacker (name, id, elist, email)
    HackersByName[name] = h
    HackersByEmail[email] = h
    HackersByID[id] = h
    return h

def LookupEmail (addr):
    try:
        return HackersByEmail[addr]
    except KeyError:
        return None

def LookupName (name):
    try:
        return HackersByName[name]
    except KeyError:
        return None

def LookupID (id):
    try:
        return HackersByID[id]
    except KeyError:
        return None

def LookupStoreHacker(name, email, mapunknown = True):
    email = RemapEmail(email)
    h = LookupEmail(email)
    if h: # already there
        return h
    elist = LookupEmployer(email, mapunknown)
    h = LookupName(name)
    if h: # new email
        h.addemail(email, elist)
        return h
    return StoreHacker(name, elist, email)


def AllHackers ():
    return HackersByID.values ()

def DumpDB ():
    out = open ('database.dump', 'w')
    names = HackersByName.keys ()
    names.sort ()
    for name in names:
        h = HackersByName[name]
        out.write ('%4d %s %d p (+%d -%d) sob: %d\n' % (h.id, h.name,
                                                        len (h.patches),
                                                        h.added, h.removed,
                                                        len (h.signoffs)))
        for i in range (0, len (h.email)):
            out.write ('\t%s -> \n' % (h.email[i]))
            for date, empl in h.employer[i]:
                out.write ('\t\t %d-%d-%d %s\n' % (date.year, date.month, date.day,
                                                 empl.name))
        if h.versions:
            out.write ('\tVersions: %s\n' % ','.join (h.versions))

#
# Hack: The first visible tag comes a ways into the stream; when we see it,
# push it backward through the changes we've already seen.
#
def ApplyFirstTag (tag):
    for n in HackersByName.keys ():
        if HackersByName[n].versions:
            HackersByName[n].versions = [tag]

#
# Employer info.
#
class Employer:
    def __init__ (self, name):
        self.name = name
        self.added = self.removed = self.count = self.changed = 0
        self.sobs = 0
        self.hackers = [ ]

    def AddCSet (self, patch):
        self.added += patch.added
        self.removed += patch.removed
        self.changed += max(patch.added, patch.removed)
        self.count += 1
        if patch.author not in self.hackers:
            self.hackers.append (patch.author)

    def AddSOB (self):
        self.sobs += 1

Employers = { }

def GetEmployer (name):
    try:
        return Employers[name]
    except KeyError:
        e = Employer (name)
        Employers[name] = e
        return e

def AllEmployers ():
    return Employers.values ()

#
# Certain obnoxious developers, who will remain nameless (because we
# would never want to run afoul of Thomas) want their work split among
# multiple companies.  Let's try to cope with that.  Let's also hope
# this doesn't spread.
#
class VirtualEmployer (Employer):
    def __init__ (self, name):
        Employer.__init__ (self, name)
        self.splits = [ ]

    def addsplit (self, name, fraction):
        self.splits.append ((name, fraction))

    #
    # Go through and (destructively) apply our credits to the
    # real employer.  Only one level of weirdness is supported.
    #
    def applysplits (self):
        for name, fraction in self.splits:
            real = GetEmployer (name)
            real.added += int (self.added*fraction)
            real.removed += int (self.removed*fraction)
            real.changed += int (self.changed*fraction)
            real.count += int (self.count*fraction)
        self.__init__ (name) # Reset counts just in case

    def store (self):
        if Employers.has_key (self.name):
            print Employers[self.name]
            sys.stderr.write ('WARNING: Virtual empl %s overwrites another\n'
                              % (self.name))
        if len (self.splits) == 0:
            sys.stderr.write ('WARNING: Virtual empl %s has no splits\n'
                              % (self.name))
            # Should check that they add up too, but I'm lazy
        Employers[self.name] = self

class FileType:
    def __init__ (self, patterns={}, order=[]):
        self.patterns = patterns
        self.order = order

    def guess_file_type (self, filename, patterns=None, order=None):
        patterns = patterns or self.patterns
        order = order or self.order

        for file_type in order:
            if patterns.has_key (file_type):
                for patt in patterns[file_type]:
                    if patt.search (filename):
                        return file_type

        return 'unknown'

#
# By default we recognize nothing.
#
FileTypes = FileType ({}, [])

#
# Mix all the virtual employers into their real destinations.
#
def MixVirtuals ():
    for empl in AllEmployers ():
        if isinstance (empl, VirtualEmployer):
            empl.applysplits ()

#
# The email map.
#
EmailAliases = { }

def AddEmailAlias (variant, canonical):
    if EmailAliases.has_key (variant):
        sys.stderr.write ('Duplicate email alias for %s\n' % (variant))
    EmailAliases[variant] = canonical

def RemapEmail (email):
    email = email.lower ()
    try:
        return EmailAliases[email]
    except KeyError:
        return email

#
# Email-to-employer mapping.
#
EmailToEmployer = { }
nextyear = datetime.date.today () + datetime.timedelta (days = 365)

def AddEmailEmployerMapping (email, employer, end = nextyear):
    if end is None:
        end = nextyear
    email = email.lower ()
    empl = GetEmployer (employer)
    try:
        l = EmailToEmployer[email]
        for i in range (0, len(l)):
            date, xempl = l[i]
            if date == end:  # probably both nextyear
                print 'WARNING: duplicate email/empl for %s' % (email)
            if date > end:
                l.insert (i, (end, empl))
                return
        l.append ((end, empl))
    except KeyError:
        EmailToEmployer[email] = [(end, empl)]

def MapToEmployer (email, unknown = 0):
    # Somebody sometimes does s/@/ at /; let's fix it.
    email = email.lower ().replace (' at ', '@')
    try:
        return EmailToEmployer[email]
    except KeyError:
        pass
    namedom = email.split ('@')
    if len (namedom) < 2:
        print 'Oops...funky email %s' % email
        return [(nextyear, GetEmployer ('Funky'))]
    s = namedom[1].split ('.')
    for dots in range (len (s) - 2, -1, -1):
        addr = '.'.join (s[dots:])
        try:
            return EmailToEmployer[addr]
        except KeyError:
            pass
    #
    # We don't know who they work for.
    #
    if unknown:
        return [(nextyear, GetEmployer ('(Unknown)'))]
    return [(nextyear, GetEmployer (email))]


def LookupEmployer (email, mapunknown = 0):
    elist = MapToEmployer (email, mapunknown)
    return elist # GetEmployer (ename)

