#!/bin/sh
#
# Import Unix branches into a single repo
#

# Location of archive mirror
OLD_UNIX=$UH/vol/nbk/old-unix

# Initialize repo
rm -rf import
mkdir import
cd import
git init
cp ../old-code-license LICENSE
git add LICENSE
git commit -a -m "Add license"

# Release branch
git branch Research-Release

git branch Research-Development-v5
SHA=`git rev-parse Research-Release`
(cd .. ; perl import-dir.pl -m $SHA -c v5.map $OLD_UNIX/v5 Research V5 -0500 ) |
tee foo |
git fast-import --stats --done --quiet

git branch Research-Development-v6
SHA=`git rev-parse Research-Release`
(cd .. ; perl import-dir.pl -m $SHA -c v5.map $OLD_UNIX/v6 Research V6 -0500 ) |
git fast-import --stats --done --quiet

#git repack --window=50 -a -d -f
