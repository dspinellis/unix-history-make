#!/bin/sh
# Push the generated repository to GitHub
#

cd import
git repack --window=50 -a -d -f

# Push to GitHub
git remote add origin git@github.com:dspinellis/unix-history-repo.git
git push -fu --all origin
