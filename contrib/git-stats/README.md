# Generate Git Repo Statistics

This is a little git processing script to generate git repo
statistics, based on gitdm by Jonathan Corbet <corbet@lwn.net>.

Original source: `git://git.lwn.net/gitdm.git`

# Running

The script takes two arguments.

## Argument 1 -- a range of git revisions

Some examples:

```
  <commit1-id>..<commit2-id>
  <tag-name>..<commit-id>
  <tag-name>..HEAD

  2018.05..HEAD
```

See the Specifying Ranges section of `gitrevisions(7)`.

## Argument 2 -- a label for the report

A meaningful label for the report, for example `yearly` or
`quarterly`.

## Full Example

To generate the stats from the 2015.02 to the 2016.02 release we would
do:

```
  $ ./onie-git-stats 2015.02..2016.02 2015-year
```

To generate stats from the 2017.05 release up to the current HEAD we
would do:

```
  $ ./onie-git-stats 2017.05..HEAD 2017-analysis
```

# Updating the maps

From time to time new companies and email aliases are needed.  These
changes are controlled by the gitdm configuration files in the
`gitdm-config` subdirectory.

The most common changes are mapping an email domain name to a
corporate name for the report.  This is controlled by the `domain-map`
file.  See `gitdm/README` for complete configuration details.
