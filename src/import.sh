#!/bin/sh
#
# Import Unix branches into a single repo
#

# Location of archive mirror
ARCHIVE=../archive

# Used to terminate when git fast-import fails
trap "exit 1" TERM
export TOP_PID=$$

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

# Git fast import
gfi()
{
	if [ -n "$DEBUG" ]
	then
		tee ../gfi.in
	else
		cat
	fi |
	git fast-import --stats --done --quiet || kill -s TERM $TOP_PID
}

# When debugging import only a few representative files
# DEBUG=-p\ '(u1\.s)|(nami\.c)|(c00\.c)|(open\.2)|(ex_addr\.c)'

# V1: Assembly language kernel
perl ../import-dir.pl -m Epoch -c ../author-path/v1 -n ../bell.au \
	$DEBUG \
	$ARCHIVE/v1/sys Research V1 -0500 | gfi

# V3: C kernel
perl ../import-dir.pl -m Research-V1 -c ../author-path/v3 -n ../bell.au \
	-r Research-V1 $DEBUG \
	-u ../unmatched/v3 $ARCHIVE/v3 Research V3 -0500 | gfi

# V4: Manual pages
perl ../import-dir.pl -m Research-V3 -c ../author-path/v4 -n ../bell.au \
	-r Research-V3 $DEBUG \
	-u ../unmatched/v4 $ARCHIVE/v4 Research V4 -0500 | gfi

# V5: Full (apart from manual pages)
perl ../import-dir.pl -m Research-V4 -c ../author-path/v5 -n ../bell.au \
	-r Research-V3,Research-V4 $DEBUG \
	-u ../unmatched/v5 $ARCHIVE/v5 Research V5 -0500 | gfi

# V6: Full
perl ../import-dir.pl -m Research-V5 -c ../author-path/v6 -n ../bell.au \
	-r Research-V5 $DEBUG \
	-u ../unmatched/v6 $ARCHIVE/v6 Research V6 -0500 | gfi

# BSD1: Just commands; forked from V6
# Leaves behind .ref-v6
perl ../import-dir.pl -m Research-V6 -c ../author-path/1bsd -n ../berkeley.au \
	-r Research-V6 $DEBUG \
	-u ../unmatched/1bsd $ARCHIVE/1bsd BSD 1 -0800 | gfi

# BSD2: Just commands
perl ../import-dir.pl -m BSD-1 -c ../author-path/2bsd -n ../berkeley.au \
	-r BSD-1,Research-V6 $DEBUG \
	-u ../unmatched/2bsd $ARCHIVE/2bsd BSD 2 -0800 | gfi

# V7: Full
perl ../import-dir.pl -m Research-V6 -c ../author-path/v7 -n ../bell.au \
	-r Research-V6 $DEBUG \
	-u ../unmatched/v7 $ARCHIVE/v7 Research V7 -0500 | gfi

# Unix/32V: Full
perl ../import-dir.pl -m Research-V7 -c ../author-path/32v -n ../bell.au \
	-r Research-V7 $DEBUG \
	$ARCHIVE/32v Bell 32V -0500 | gfi

# BSD 3.0: First full distribution
# Merge 32V and 2BSD
perl ../import-dir.pl -m Bell-32V,BSD-2 -c ../author-path/3bsd \
	-n ../berkeley.au \
	-r Bell-32V,BSD-2 $DEBUG \
	-u ../unmatched/3bsd $ARCHIVE/3bsd BSD 3 -0800 | gfi

git checkout BSD-Release

# Add README file
cp ../../README.md .
git add README.md
git commit -a -m "Add README file"


# Succeed if text files in the two specified directories
# are the same
verify_same_text()
{
	echo "Verifying contents of $2"
	if ! diff -r "$1" "$2" |
		perl -ne '
			BEGIN {$exit = 0}
			chop;
			if (!s/^Only in // || !s|: |/| || -T) {
				next if (/LICENSE/);
				$exit = 1;
				print "$_\n"
			}
			END {exit $exit}'
	then
		echo "Differences found" 1>&2
		exit 1
	fi
}

if [ -n "$DEBUG" ]
then
	exit 0
fi

# Verify Research releases are the same
for i in 3 4 5 6 7
do
	git checkout Research-V$i
	verify_same_text . $ARCHIVE/v$i
done

# Verify BSD releases
for i in 1 2 3
do
	git checkout BSD-$i
	verify_same_text . $ARCHIVE/${i}bsd
done

git checkout Bell-32V
verify_same_text . $ARCHIVE/32v

# Verify that log/blame work as expected
N_EXPECTED=3
git checkout Research-Release
for i in  usr/src/cmd/c/c00.c usr/sys/sys/pipe.c
do
	echo Verify blame/log of $i
	N_ADD=`git log --follow --simplify-merges $i | grep -c "Work on"`
	if [ $N_ADD -lt $N_EXPECTED ]
	then
		echo "Found $N_ADD additions for $i; expected $N_EXPECTED" 1>&2
		exit 1
	fi
	N_BLAME=`git blame -C -C $i | awk '{print $1}' | sort -u | wc -l`
	if [ $N_BLAME -lt $N_EXPECTED ]
	then
		echo "Found $N_BLAME blames for $i; expected $N_EXPECTED" 1>&2
		exit 1
	fi
done

git checkout BSD-Release
N_EXPECTED=10
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
