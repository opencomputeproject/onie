<!---
   Copyright (C) 2014-2015 Curt Brune <curt@cumulusnetworks.com>
   Copyright (C) 2014 Pete Bratach <pete@cumulusnetworks.com>
   SPDX-License-Identifier:     GPL-2.0
-->

## Table of Contents

* [Contributing to ONIE](#contributing-to-onie)
  * [Open Source Development Process](#open-source-development-process)
* [General Patching Philosophy](#general-patching-philosophy)

## Contributing to ONIE

This section describes how to participate in the ONIE project.

### Open Source Development Process

The description is somewhat informal, but captures the spirit of the
effort. It is based on how other projects (Linux kernel and U-Boot,
for example) manage.

Please read
[The Lifecycle of a Patch](http://www.linuxfoundation.org/content/22-lifecycle-patch).

Here is how git "open source" development works. For nearly everything
written below, you could replace the word "ONIE" with "Linux kernel".

1.  There is a public git repo for ONIE.
1.  A few people have commit privilege to the repo, also known as
    "maintainers" or "custodians" -- at the moment for ONIE that's a
    few people from Cumulus Networks and a few people from Big Switch.
1.  The entire world has read privilege to the repo.
1.  People without commit privilege want to contribute (a hardware
    vendor for example), called a "contributor". They open a
    discussion around their problem on the mailing list.
1.  Next the contributor makes a patch and sends it to the mailing
    list, including a maintainer.  That patch *must* apply cleanly
    to the master branch.
1.  The maintainer, mailing list and contributor kick the patch
    around, look it over, make some changes, goes through some
    revisions.
1.  Eventually the patch is deemed acceptable and a maintainer applies
    the patch to the git repo.
1.  The patch contains all the attribution information. The git
    history will show that the contributor made the patch and
    changes. The maintainer merely applied the patch to the repo.

After the patch is applied it will be available in the common ONIE
code base for everyone.

Step \#6 can seem kind of brutal at first -- your code gets beat up in
public on the mailing list. But it is not personal. It is all about
code quality, sound design and being open.

## General Patching Philosophy

One of the ONIE project goals is to maintain high standards for
software quality and engineering discipline. In that spirit, here are
some general comments regarding patch submission:

1.  Each patch should only contain *one* logical change. A patch
    should not contain multiple, unrelated changes.
1.  Each patch must apply cleanly to the master branch.
1.  Each patch must have the following:
  1.  The author must be a real person with a valid email address. No
      anonymous github user IDs.
  1.  A short one line summary. When the patch is for a specific
      machine include the machine name or company as a prefix to the
      summary, e.g. "machine\_xyz\_123: updated installer config".
  1.  What problem the patch solves (why do we need the patch).
  1.  How you tested the patch.

1.  To upstream patches please use GitHub
    [git pull requests](https://help.github.com/articles/using-pull-requests).
    The ONIE project is following the
    *fork and pull* model.

    > **Note**
    >
    > The author must be a real person with a valid email address. No anonymous github user IDs.
    >
    > Please do not create pull requests using your master branch. You should create a topic branch and make a pull request from that branch.
    >
    > This is described here: [Creating a Pull Request](https://help.github.com/articles/creating-a-pull-request/) and [Using Pull Requests](https://help.github.com/articles/using-pull-requests/).
    >
    > As it says in the article "These changes are proposed in a branch, which ensures that the master branch is kept clean and tidy."

1.  Alternatively to upstream patches, send patches to the mailing list using the
    output of
    [git format-patch](https://www.kernel.org/pub/software/scm/git/docs/git-format-patch.html). This
    ensures the patch is appropriately attributed to you.
  1.  Information on the mailing list: http://lists.opencompute.org/mailman/listinfo/opencompute-onie
  1.  Follow these guidelines: https://www.kernel.org/doc/Documentation/email-clients.txt
  1.  Using `git send-email` is *strongly* recommended to avoid encoding problems
  1.  Inline text patches are preferred as we can comment directly in email replies (avoid attachments)
  1.  Attachments of types other than `text/plain` will not be accepted.

Pull requests can be easier to use then sending patches via email, as
some email client mangle patch attachments.
