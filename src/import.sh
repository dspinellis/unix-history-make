#!/bin/bash
#
# Import Unix branches into a single repo
#

# When debugging import only a few representative files
# export DEBUG=-p\ '(u1\.s)|(((nami)|(c00)|(ex_addr)|(sys_socket))\.c)|(open\.2)|(((proc)|(stat))\.h)'

# Location of archive mirror
ARCHIVE=../archive

# Used to terminate when git fast-import fails
trap "exit 1" TERM
export TOP_PID=$$

add_boilerplate()
{
	cp ../old-code-license LICENSE
	cp ../Caldera-license.pdf .
	cp ../../README.md .
	git add LICENSE README.md Caldera-license.pdf
	git commit -a -m "Add licenses and README"
}

# Check prerequisites
if ! perl -MVCS::SCCS -e 1 2>/dev/null
then
	echo "The VCS::SCCS module is not installed"
	exit 1
fi

# Initialize repo
rm -rf import
mkdir import
cd import
git init
add_boilerplate
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

# V1: Assembly language kernel
perl ../import-dir.pl -m Epoch -c ../author-path/Research-V1 -n ../bell.au \
	$DEBUG \
	$ARCHIVE/v1/sys Research V1 -0500 | gfi

# V3: C kernel
perl ../import-dir.pl -m Research-V1 -c ../author-path/Research-V3 -n ../bell.au \
	-r Research-V1 $DEBUG \
	-u ../unmatched/Research-V3 $ARCHIVE/v3 Research V3 -0500 | gfi

# V4: Manual pages
perl ../import-dir.pl -m Research-V3 -c ../author-path/Research-V4 -n ../bell.au \
	-r Research-V3 $DEBUG \
	-u ../unmatched/Research-V4 $ARCHIVE/v4 Research V4 -0500 | gfi

# V5: Full (apart from manual pages)
perl ../import-dir.pl -m Research-V4 -c ../author-path/Research-V5 -n ../bell.au \
	-r Research-V3,Research-V4 $DEBUG \
	-u ../unmatched/Research-V5 $ARCHIVE/v5 Research V5 -0500 | gfi

# V6: Full
perl ../import-dir.pl -m Research-V5 -c ../author-path/Research-V6 -n ../bell.au \
	-r Research-V5 $DEBUG \
	-u ../unmatched/Research-V6 $ARCHIVE/v6 Research V6 -0500 | gfi

# BSD1: Just commands; forked from V6
# Leaves behind .ref-Research-V6
perl ../import-dir.pl -m Research-V6 -c ../author-path/BSD-1 -n ../berkeley.au \
	-r Research-V6 $DEBUG -i ../ignore/BSD-1 \
	-u ../unmatched/BSD-1 $ARCHIVE/1bsd BSD 1 -0800 | gfi

# BSD2: Just commands
perl ../import-dir.pl -m BSD-1 -c ../author-path/BSD-2 -n ../berkeley.au \
	-r BSD-1,Research-V6 $DEBUG -i ../ignore/BSD-2 \
	-u ../unmatched/BSD-2 $ARCHIVE/2bsd BSD 2 -0800 | gfi

# V7: Full
perl ../import-dir.pl -m Research-V6 -c ../author-path/Research-V7 -n ../bell.au \
	-r Research-V6 $DEBUG -i ../ignore/Research-V7 \
	-u ../unmatched/Research-V7 $ARCHIVE/v7 Research V7 -0500 | gfi

# Unix/32V: Full
perl ../import-dir.pl -m Research-V7 -c ../author-path/Bell-32V -n ../bell.au \
	-r Research-V7 $DEBUG -i ../ignore/Bell-32V \
	$ARCHIVE/32v Bell 32V -0500 | gfi

# BSD 3.0: First full distribution
# Merge 32V and 2BSD
perl ../import-dir.pl -m Bell-32V,BSD-2 -c ../author-path/BSD-3 \
	-n ../berkeley.au \
	-r Bell-32V,BSD-2 $DEBUG -i ../ignore/BSD-3 \
	-u ../unmatched/BSD-3 $ARCHIVE/3bsd BSD 3 -0800 | gfi

# BSD SCCS: From 1980 to 1995
DIR=../archive/CSRG/cd4.patched
if [ -n "$DEBUG" ]
then
	STRIP="-s $DIR"
	DIR=$DIR/sys/sys
fi
perl ../import-dir.pl -S -C 1996-01-01 -m BSD-3 -c ../author-path/BSD-3 \
	-n ../berkeley.au -u ../unmatched/BSD-SCCS.authors $DEBUG \
	-r BSD-3 -P usr/src/ \
	$STRIP $DIR BSD-SCCS | gfi

# Merge SCCS and incremental 4BSD additions
SCCS_AT_RELEASE=$(git log --before='1980-11-15 11:24:58 +0200' -n 1 --format='%H' BSD-SCCS)
perl ../import-dir.pl -m BSD-3,$SCCS_AT_RELEASE -c ../author-path/BSD-4 \
	-n ../berkeley.au \
	-r BSD-3,$SCCS_AT_RELEASE $DEBUG \
	-i ../ignore/BSD-4-src,../ignore/BSD-4-catman,../ignore/BSD-4-other,../ignore/BSD-4-map \
	-I ../ignore/BSD-4-sccs \
	-u ../unmatched/BSD-4 $ARCHIVE/CSRG//cd1/4.0 BSD 4 -0800 | gfi


# Merge SCCS and incremental BSD additions on snapshots
# See http://minnie.tuhs.org/Unix_History/4bsd
# (R/L stands for BSD-Release branch or Leaf.)
# Version	Parent		Directory		Last file timestamp + 1s  R/L
cat <<\EOF |
4_1_snap	4		cd1/4.1.snap		1982-02-03 08:34:45 +0200 R
4_1c_2		4_1_snap	cd1/4.1c.2		1983-03-12 10:46:32 +0200 R
4_2		4_1c_2		cd1/4.2			1983-09-26 16:24:27 +0200 R
4_3		4_2		cd1/4.3			1987-03-02 09:38:51 +0200 R
4_3_Tahoe	4_3		cd2/4.3tahoe		1989-05-23 13:47:44 +0300 R
4_3_Net_1	4_3_Tahoe	cd2/net.1		1989-01-01 12:15:59 +0200 L
4_3_Reno	4_3_Tahoe	cd2/4.3reno		1991-01-02 10:10:59 +0200 R
4_3_Net_2	4_3_Reno	cd2/net.2		1991-04-19 11:49:58 +0300 L
4_4		4_3_Reno	cd3/4.4			1993-06-06 10:12:36 +0300 R
4_4_Lite1	4_4		cd2/4.4BSD-Lite1	1994-04-02 06:05:37 +0300 R
4_4_Lite2	4_4_Lite1	cd3/4.4BSD-Lite2	1995-04-28 13:13:03 +0300 R
EOF
while read version parent dir date time tz rl ; do
	dir=../archive/CSRG/$dir
	parent=BSD-$parent

	# Exclude administrative files (SCCS and .MAP), and
	# files with spaces in their names
	test -r ../ignore/BSD-${version}-admin ||
		find $dir -type f |
		egrep '(/\.MAP)|(/SCCS/)| ' |
		sed "s|$dir/||" |
		sort >../ignore/BSD-${version}-admin

	# Exclude additional installed files
	test -r ../ignore/BSD-${version}-other || (
		find $dir/bin -type f
		find $dir/etc -type f
		find $dir/usr/bin -type f
		find $dir/usr/ingres -type f 2>/dev/null
		find $dir/usr/lasttape -type f 2>/dev/null
		find $dir/usr/ucb -type f
		find $dir/usr/include/sys -type f
	) |
	sed "s|$dir/||" |
	sort |
	comm -23 - ../ignore/BSD-${version}-admin >../ignore/BSD-${version}-other

	# Exclude files that are under SCCS control
	SCCS_AT_RELEASE=$(git log --before="$date $time $tz" -n 1 --format='%H' BSD-SCCS)
	test -r ../ignore/"BSD-${version}-sccs" || (
		# Files in the SCCS tree
		git ls-tree --full-tree --name-only -r $SCCS_AT_RELEASE |
		egrep -v '^((\.ref)|(LICENSE)|(README\.md)|(Caldera-license\.pdf))'

		# Files with SCCS mark
		find $dir -type f |
		egrep -v '(\.MAP)|(/SCCS/)|(/ingres/)|['"'"'" ]' |
		# Only text files
		perl -ne 'chop; print "$_\n" if -T ' |
		xargs fgrep -l '@(#)' |
		sed "s|$dir/||" |
		sort |
		comm -23 - ../ignore/BSD-${version}-other
	) | sort -u >../ignore/"BSD-${version}-sccs"

	perl ../import-dir.pl -m $parent,$SCCS_AT_RELEASE \
		-c ../author-path/BSD-default \
		-n ../berkeley.au \
		-r $parent,$SCCS_AT_RELEASE $DEBUG \
		-i ../ignore/BSD-${version}-other,../ignore/BSD-${version}-admin \
		-I ../ignore/BSD-${version}-sccs \
		-u ../unmatched/BSD-$version $dir \
		BSD $version -0800 | gfi
	# For leaf branches move BSD-Release pointer back to their parent
	if [ $rl = 'L' ] ; then
		git branch -f BSD-Release $parent
	fi
done

# 386BSD 0.0
perl ../import-dir.pl -m BSD-4_3_Net_2 -c ../author-path/386BSD \
	-n ../386bsd.au -r BSD-4_3_Net_2 $DEBUG \
	-u ../unmatched/386BSD-0.0 \
	$ARCHIVE/386BSD-0.0/src 386BSD 0.0 -0800 | gfi

# 386BSD 0.1
perl ../import-dir.pl -m 386BSD-0.0 -c ../author-path/386BSD \
	-n ../386bsd.au -r 386BSD-0.0 $DEBUG \
	-u ../unmatched/386BSD-0.1 \
	$ARCHIVE/386BSD-0.1 386BSD 0.1 -0800 | gfi

# FreeBSD 1.0
perl ../import-dir.pl -m 386BSD-0.1,BSD-4_3_Net_2 -c ../author-path/FreeBSD-1.0 \
	-i ../ignore/FreeBSD-1.0 \
	-n ../freebsd.au -r 386BSD-0.1,BSD-4_3_Net_2 $DEBUG \
	-u ../unmatched/FreeBSD-1.0 \
	$ARCHIVE/FreeBSD-1.0/filesys FreeBSD 1.0 -0800 | gfi

# Modern FreeBSD
# Branches that get merged
MERGED="BSD-4_4_Lite2,FreeBSD-1.0"

# Branches to import
if [ -n "$DEBUG" ]
then
	REFS='release/2.0 release/3.0.0'
else
	REFS=$(cd $ARCHIVE/freebsd.git/ ; git branch -l | egrep -v 'projects/|user/| master')\ HEAD
fi

perl ../import-dir.pl -r $MERGED -m $MERGED \
	-R '1994-11-22 10:59:00 +0000' \
	-G 'Diomidis Spinellis <dds@FreeBSD.org> 785501938 +0000' \
	-P FreeBSD- $ARCHIVE/freebsd.git/ $REFS --progress=1000 | gfi


git gc --aggressive

git checkout FreeBSD-Release

# Adding boilerplate again seems to help getting a modern
# timestamp for the files displayed on GitHub
add_boilerplate

# Succeed if text files in the two specified directories
# are the same
verify_same_text()
{
	echo "Verifying contents of $2"
	if ! diff -r "$1" "$2" |
		fgrep -v -f "$3" |
		perl -ne '
			BEGIN {$exit = 0}
			chop;
			if (!s/^Only in // || !s|: |/| || -T) {
				next if (/LICENSE/);
				next if (/Caldera-license\.pdf/);
				next if (/README\.md/);
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
for i in 3 4 5 6
do
	git checkout Research-V$i
	verify_same_text . $ARCHIVE/v$i /dev/null
done
verify_same_text . $ARCHIVE/v7 ../ignore/Research-V7

# Verify BSD releases
for i in 1 2 3
do
	git checkout BSD-$i
	verify_same_text . $ARCHIVE/${i}bsd ../ignore/BSD-${i}
done

git checkout Bell-32V
verify_same_text . $ARCHIVE/32v ../ignore/Bell-32V

git checkout BSD-4
verify_same_text . $ARCHIVE/CSRG/cd1/4.0 ../ignore/BSD-4-src

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

# verify_nodes branch/merge number
# Verify the number of the specified branch/merge type
verify_nodes()
{
	local N_EXPECTED=$2
	local N_JOIN=`git log --graph | fgrep -c $1`
	if [ $N_JOIN -lt $N_EXPECTED ]
	then
		echo "Found $N_JOIN instances of $1; expected $N_EXPECTED" 1>&2
		exit 1
	fi
}

git checkout BSD-Release
echo Verify branches and merges
verify_nodes '|/' 55
verify_nodes '|\' 32

echo Verify SCCS merge
N_HASH=$(git blame -C -C usr/src/sys/sys/proc.h |
	awk '{print $1}' |
	sort -u |
	wc -l)

N_EXPECTED=32
if [ $N_HASH -lt $N_EXPECTED ]
then
	echo "Found $N_HASH versions in proc.h; expected $N_EXPECTED" 1>&2
	exit 1
fi
