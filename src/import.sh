#!/bin/sh
#
# Import Unix branches into a single repo
#

# Location of archive mirror
ARCHIVE=../archive

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
# DEBUG=-f\ '(pipe\.c)|(c00\.c)'

for i in $EDITIONS
do
	echo Import Research-Development-v$i
	git branch Research-Development-v$i
	SHA=`git rev-parse Research-Release`
	perl ../import-dir.pl $DEBUG -m $SHA -c ../v$i.map -n ../bell.au \
		-u ../v$i.unmatched $ARCHIVE/v$i Research V$i -0500 |
	# tee ../dump-$i |
	git fast-import --stats --done --quiet
done

git checkout Research-Release

# Add README file
cp ../../README.md .
git add README.md
git commit -a -m "Add README file"


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
	echo Verify content of Research-Development-v$i
	git checkout Research-V$i
	if ! same_text . $ARCHIVE/v$i
	then
		echo "Differences found" 1>&2
		exit 1
	fi
done

# Verify that log/blame work as expected
N_EXPECTED=3
git checkout Research-Release
for i in  usr/src/cmd/c/c00.c usr/sys/sys/pipe.c
do
	echo Verify blame/log of $i
	N_ADD=`git log --follow --simplify-merges $i | grep -c Add`
	if [ $N_ADD -lt $N_EXPECTED ]
	then
		echo "Found $N_ADD additions for $i; expected $N_EXPECTED" 1>&2
		exit 1
	fi
	N_BLAME=`git blame -C -C $i | awk '{print $1}' | wc -c`
	if [ $N_BLAME -lt $N_EXPECTED ]
	then
		echo "Found $N_BLAME blames for $i; expected $N_EXPECTED" 1>&2
		exit 1
	fi
done

echo Verify branches and merges
for i in '|/' '|\'
do
	N_JOIN=`git log --graph | fgrep -c $i`
	if [ $N_JOIN -lt $N_EXPECTED ]
	then
		echo "Found $N_JOIN instances of $i; expected $N_EXPECTED" 1>&2
		exit 1
	fi
done
