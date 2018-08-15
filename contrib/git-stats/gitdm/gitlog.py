#
# Stuff for dealing with the git log output.
#
# Someday this will be the only version of grabpatch, honest.
#
import re, rfc822, datetime
from patterns import patterns
import database


#
# Input file handling.  Someday it would be good to make this smarter
# so that it handles running git with the right options and such.
#
# Someday.
#
SavedLine = ''

def getline(input):
    global SavedLine
    if SavedLine:
        ret = SavedLine
        SavedLine = ''
        return ret
    l = input.readline()
    if l:
        return l.rstrip()
    return None

def SaveLine(line):
    global SavedLine
    SavedLine = line

#
# A simple state machine based on where we are in the patch.  The
# first stuff we get is the header.
#
S_HEADER = 0
#
# Then comes the single-line description.
#
S_DESC = 1
#
# ...the full changelog...
#
S_CHANGELOG = 2
#
# ...the tag section....
#
S_TAGS = 3
#
# ...the numstat section.
#
S_NUMSTAT = 4

S_DONE = 5

#
# The functions to handle each of these states.
#
def get_header(patch, line, input):
    if line == '':
        if patch.author == '':
            print 'Funky auth line in', patch.commit
            patch.author = database.LookupStoreHacker('Unknown',
                                                      'unknown@hacker.net')
        return S_DESC
    m = patterns['author'].match(line)
    if m:
        patch.email = database.RemapEmail(m.group(2))
        patch.author = database.LookupStoreHacker(m.group(1), patch.email)
    else:
        m = patterns['date'].match(line)
        if m:
            dt = rfc822.parsedate(m.group(2))
            patch.date = datetime.date(dt[0], dt[1], dt[2])
    return S_HEADER

def get_desc(patch, line, input):
    if not line:
        print 'Missing desc in', patch.commit
        return S_CHANGELOG
    patch.desc = line
    line = getline(input)
    while line:
        patch.desc += line
        line = getline(input)
    return S_CHANGELOG

tagline = re.compile(r'^\s+(([-a-z]+-by)|cc):.*@.*$', re.I)
def get_changelog(patch, line, input):
    if not line:
        if patch.templog:
            patch.changelog += patch.templog
            patch.templog = ''
    if patterns['commit'].match(line):
        # No changelog at all - usually a Linus tag
        SaveLine(line)
        return S_DONE
    elif tagline.match(line):
        if patch.templog:
            patch.changelog += patch.templog
        return get_tag(patch, line, input)
    else:
        patch.templog += line + '\n'
    return S_CHANGELOG

def get_tag(patch, line, input):
    #
    # Some people put blank lines in the middle of tags.
    #
    if not line:
        return S_TAGS
    #
    # A new commit line says we've gone too far.
    #
    if patterns['commit'].match(line):
        SaveLine(line)
        return S_DONE
    #
    # Check for a numstat line
    #
    if patterns['numstat'].match(line):
        return get_numstat(patch, line, input)
    #
    # Look for interesting tags
    #
    m = patterns['signed-off-by'].match(line)
    if m:
        patch.signoffs.append(m.group(2))
    else:
        #
        # Look for other tags indicating that somebody at least
        # looked at the patch.
        #
        for tag in ('acked-by', 'reviewed-by', 'tested-by'):
            if patterns[tag].match(line):
                patch.othertags += 1
                break
    return S_TAGS

def get_numstat(patch, line, input):
    m = patterns['numstat'].match(line)
    if not m:
        return S_DONE
    try:
        patch.addfile(int(m.group(1)), int(m.group(2)), m.group(3))
    #
    # Binary files just have "-" in the line fields.  In this case, set
    # the counts to zero so that we at least track that the file was
    # touched.
    #
    except ValueError:
        patch.addfile(0, 0, m.group(3))
    return S_NUMSTAT

grabbers = [ get_header, get_desc, get_changelog, get_tag, get_numstat ]


#
# A variant on the gitdm patch class.
#
class patch:
    def __init__(self, commit):
        self.commit = commit
        self.desc = ''
        self.changelog = ''
        self.templog = ''
        self.author = ''
        self.signoffs = [ ]
        self.othertags = 0
        self.added = self.removed = 0
        self.files = [ ]

    def addfile(self, added, removed, file):
        self.added += added
        self.removed += removed
        self.files.append(file)

def grabpatch(input):
    #
    # If it's not a patch something is screwy.
    #
    line = getline(input)
    if line is None:
        return None
    m = patterns['commit'].match(line)
    if not m:
        print 'noncommit', line
        return None
    p = patch(m.group(1))
    state = S_HEADER
    #
    # Crank through the patch.
    #
    while state != S_DONE:
        line = getline(input)
        if line is None:
            if state != S_NUMSTAT:
                print 'Ran out of patch', state
                return None
            return p
        state = grabbers[state](p, line, input)
    return p
