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

for i in {5,6}
do
	git branch Research-Development-v$i
	SHA=`git rev-parse Research-Release`
	(cd .. ; perl import-dir.pl -m $SHA -c v$i.map $OLD_UNIX/v$i Research V$i -0500 ) |
	git fast-import --stats --done --quiet
done


#git repack --window=50 -a -d -f

# Succeed if text files in the two specified directories
# are the same
same_text()
{
	diff -r "$1" "$2" |
	perl -ne '
		BEGIN {$exit = 0}
		chop;
		if (!s/^Only in // || !s|: |/| || -T) {
			$exit = 1;
			print "$_\n"
		}
		END {exit $exit}'
}

# Verify releases are the same
for i in {5,6}
do
	git checkout Research-Development-v$i
	if ! same_text . $OLD_UNIX/v$i
	then
		echo "Differences found" 1>&2
		exit 1
	fi
done

