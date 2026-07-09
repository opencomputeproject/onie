# Generate Git Repo Statistics

This is a little git processing script to generate git repo
statistics, based on gitdm by Jonathan Corbet <corbet@lwn.net>.

Original source: `git://git.lwn.net/gitdm.git`

# gitdm

gitdm itself is **no longer vendored in this tree**.  The upstream
gitdm is python2 and is effectively unmaintained; rather than carry a
copy here, `onie-git-stats` obtains a python3 port of gitdm on demand.

By default the script auto-installs a pinned python3 gitdm the first
time it is run, so in the common case you can just run it as-is (see
[Running](#running) below).  This requires `git` and `python3` on your
`PATH`.

## Where gitdm comes from

On first run, `onie-git-stats` clones a python3 port of gitdm into a
local, git-ignored cache directory next to the script
(`contrib/git-stats/.gitdm/`) and reuses it on subsequent runs.  The
source and revision are pinned and can be overridden with environment
variables:

| Variable     | Default                                    | Meaning                                 |
| ------------ | ------------------------------------------ | --------------------------------------- |
| `GITDM_REPO` | `https://github.com/OSSystems/gitdm.git`   | git URL to clone gitdm from             |
| `GITDM_REF`  | `b7b1f8e7d567fc41dcfc249de5e967a6a30aa9b5` | commit/tag/branch of gitdm to check out |

To refresh the cache (e.g. after changing `GITDM_REF`), delete the
cache directory and re-run:

```
  $ rm -rf contrib/git-stats/.gitdm
```

## Using a pre-existing gitdm (skip the auto-install)

If you already have a python3-capable gitdm installed, set the `GITDM`
environment variable to point at its `gitdm` executable.  When `GITDM`
is set, `onie-git-stats` uses it directly and does **not** clone or
install anything:

```
  $ GITDM=/path/to/your/gitdm ./onie-git-stats 2024.05..HEAD quarterly
```

Note that gitdm must be a python3 port -- `onie-git-stats` invokes it
with `python3`.

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
file.  See the documentation of the gitdm the script installs (or that
`GITDM_REPO` points at) for complete configuration details.
