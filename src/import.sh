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
git tag Epoch

# Release branch
git branch Research-Release
EDITIONS='5 6 7'

# When debugging import only two representative files
# DEBUG=-f\ '(trap\.c)|(c00\.c)'

for i in $EDITIONS
do
	echo Working on $i
	git branch Research-Development-v$i
	SHA=`git rev-parse Research-Release`
	perl ../import-dir.pl $DEBUG -m $SHA -c ../v$i.map $OLD_UNIX/v$i Research V$i -0500 |
	# tee ../dump-$i |
	git fast-import --stats --done --quiet
done

git checkout Research-Release

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
			next if (/LICENSE/);
			$exit = 1;
			print "$_\n"
		}
		END {exit $exit}'
}

if [ -n "$DEBUG" ]
then
	exit 0
fi

# Verify releases are the same
for i in $EDITIONS
do
	git checkout Research-Development-v$i
	if ! same_text . $OLD_UNIX/v$i
	then
		echo "Differences found" 1>&2
		exit 1
	fi
done

