#!/bin/bash
# Push the generated repository to GitHub
#

set -e

cd import

git checkout Research-V1-Snapshot-Development

# Empty old repo
pushd ../empty
# Don't error when GitHub refuses to delete current branch:
# refs/heads/Research-PDP7-Snapshot-Development
git push origin --mirror || true
popd

# Push to GitHub
git remote add origin git@github.com:dspinellis/unix-history-repo.git
git push -fu --all origin
git push --tags origin
