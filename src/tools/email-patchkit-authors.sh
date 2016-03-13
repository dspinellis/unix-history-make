#!/bin/bash
#
# Email 386BSD patchkit authors to claim their old email address

# Generate a list of the following form
# Tor Egge:tegge:Tor.Egge@idi.ntnu.no
comm -12 <(awk -F: '{print $1}' 386bsd-patch.au | sort) \
  <(awk -F: '{print $2}' freebsd.au | sort) |
join -t: -2 2 - <(sort -t: -k2 freebsd.au) |
join -t: -2 1 - <(sort -t: -k1 386bsd-patch.au) |
# Send email
while IFS=: read name fbsd old ; do
  set $name
  first="$1"
  /usr/sbin/sendmail dds@aueb.gr $fbsd@FreeBSD.org <<EOF
From: Diomidis Spinellis <dds@FreeBSD.org>
Subject: Your 386BSD patchkit contributions
To: $name <$fbsd@FreeBSD.org>

Dear $first,

I recently included in a GitHub repo that contains a series of Unix
commits from 1972 until 2016 the changes associated with the 386BSD
patchkit, to which you have apparently contributed.  You can see
these commits through the following link.
https://github.com/dspinellis/unix-history-repo/commits/386BSD-0.1-patchkit

If you have (or setup) a GitHub account, you can have your commits
associated with it, by claiming the <$old>
email address you were probably using at the time through
https://github.com/settings/emails.
I've noticed that claimed email addresses work even without
going through the normal verification email process.

Kind regards,

Diomidis - http://www.spinellis.gr
EOF
done
