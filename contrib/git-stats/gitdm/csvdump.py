#
# aggregate per-month statistics for people
#
import sys, datetime
import csv

class CSVStat:
    def __init__ (self, name, email, employer, date):
        self.name = name
        self.email = email
        self.employer = employer
        self.added = self.removed = self.changesets = 0
        self.date = date
    def accumulate (self, p):
        self.added = self.added + p.added
        self.removed = self.removed + p.removed
        self.changesets += 1

PeriodCommitHash = { }

def AccumulatePatch (p, Aggregate):
    if (Aggregate == 'week'):
        date = "%.2d-%.2d"%(p.date.isocalendar()[0], p.date.isocalendar()[1])
    elif (Aggregate == 'year'):
        date = "%.2d"%(p.date.year)
    else:
        date = "%.2d-%.2d-01"%(p.date.year, p.date.month)
    authdatekey = "%s-%s"%(p.author.name, date)
    if authdatekey not in PeriodCommitHash:
        empl = p.author.emailemployer (p.email, p.date)
        stat = CSVStat (p.author.name, p.email, empl, date)
        PeriodCommitHash[authdatekey] = stat
    else:
        stat = PeriodCommitHash[authdatekey]
    stat.accumulate (p)

ChangeSets = []
FileTypes = []

def store_patch(patch):
    if not patch.merge:
        employer = patch.author.emailemployer(patch.email, patch.date)
        employer = employer.name.replace('"', '.').replace ('\\', '.')
        author = patch.author.name.replace ('"', '.').replace ('\\', '.')
        author = patch.author.name.replace ("'", '.')
        try:
            domain = patch.email.split('@')[1]
        except:
            domain = patch.email
        ChangeSets.append([patch.commit, str(patch.date),
                           patch.email, domain, author, employer,
                           patch.added, patch.removed])
        for (filetype, (added, removed)) in patch.filetypes.iteritems():
            FileTypes.append([patch.commit, filetype, added, removed])


def save_csv (prefix='data'):
    # Dump the ChangeSets
    if len(ChangeSets) > 0:
        fd = open('%s-changesets.csv' % prefix, 'w')
        writer = csv.writer (fd, quoting=csv.QUOTE_NONNUMERIC)
        writer.writerow (['Commit', 'Date', 'Domain',
                          'Email', 'Name', 'Affliation',
                          'Added', 'Removed'])
        for commit in ChangeSets:
            writer.writerow(commit)

    # Dump the file types
    if len(FileTypes) > 0:
        fd = open('%s-filetypes.csv' % prefix, 'w')
        writer = csv.writer (fd, quoting=csv.QUOTE_NONNUMERIC)

        writer.writerow (['Commit', 'Type', 'Added', 'Removed'])
        for commit in FileTypes:
            writer.writerow(commit)



def OutputCSV (file):
    if file is None:
        return
    writer = csv.writer (file, quoting=csv.QUOTE_NONNUMERIC)
    writer.writerow (['Name', 'Email', 'Affliation', 'Date',
                      'Added', 'Removed', 'Changesets'])
    for date, stat in PeriodCommitHash.items():
        # sanitise names " is common and \" sometimes too
        empl_name = stat.employer.name.replace ('"', '.').replace ('\\', '.')
        author_name = stat.name.replace ('"', '.').replace ('\\', '.')
        writer.writerow ([author_name, stat.email, empl_name, stat.date,
                          stat.added, stat.removed, stat.changesets])

__all__ = [  'AccumulatePatch', 'OutputCSV', 'store_patch' ]
