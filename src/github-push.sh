#!/bin/sh
# Push the generated repository to GitHub
#

cd import

#  Optimize structure
git checkout FreeBSD-Release

# Push to GitHub
git remote add origin git@github.com:dspinellis/unix-history-repo.git
git push -fu --all origin
git push --tags origin
