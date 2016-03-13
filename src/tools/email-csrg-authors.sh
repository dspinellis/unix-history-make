#!/bin/bash
#
# Email CSRG authors to claim their old email address

# Generate a list of the form
# Tor Egge:CSRG email(s):email:GitHub account:[YN]

commits()
{
  (
    cd ../import
    git log --all --author="$1" --pretty=%h |
    tail -5 |
    sed 's|^|https://github.com/dspinellis/unix-history-repo/commit/|'
  )
}

# Send email
while IFS=: read name csrg email github yn ; do
  set $name
  first="$1"
  (
    cat <<EOF
From: Diomidis Spinellis <dds@FreeBSD.org>
Subject: Your BSD Unix contributions
To: $name <$email>

Dear $first,

EOF
    if [ $yn = Y ] ; then
      cat <<EOF
I'm sending you this email, because I think it might be cool to
have your GitHub account $github associated with code your wrote
for Berkeley Unix a few decades ago.  This appears in a GitHub repo
that contains a series of Unix commits from 1972 until 2016.
(I've been putting together this repo for the past three years.)

Here are links to some of the commits from that era that
are attributed to you.

EOF
      commits "$csrg"
      cat <<EOF

You can have these commits associated with your account,
EOF
    else
      cat <<EOF
I'm sending you this email, because I think you wrote some code
for Berkeley Unix a few decades ago, and it might be cool to
have your GitHub account $github associated it.  The code appears
in a GitHub repo that contains a series of Unix commits from 1972
until 2016.  (I've been putting together this repo for the past
three years.)

Here are links to some of the commits from that era that
are attributed to $name.

EOF
      commits "$csrg"
      cat <<EOF

If these commits were indeed made by you (otherwise, apologies
for bothering you), you can have them associated with your account
EOF
    fi
    cat <<EOF
by claiming the <$csrg> email address through
https://github.com/settings/emails.
I've noticed that claimed email addresses work even without
going through the normal verification email process.

Kind regards,

Diomidis - http://www.spinellis.gr
EOF
  ) |
  /usr/sbin/sendmail dds@aueb.gr $email
done
