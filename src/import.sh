#!/bin/sh
#
# Import Unix branches into a single repo
#

# Initialize repo
rm -rf import
mkdir import
cd import
git init
cp ../old-code-license LICENSE
git add LICENSE
git commit -a -m "Add license"

# Release branches
git branch Research-Development
git branch Research-Release

SHA=`git rev-parse Research-Development`

cd ..
perl import-dir.pl -c v5.map /vol/nbk/old-unix/v5 Research V5 $SHA -0500 |
tee foo |
(cd import ; git fast-import --stats --done --quiet)

#git repack --window=50 -a -d -f
