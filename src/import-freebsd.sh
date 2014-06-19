#!/bin/bash


# Location of archive mirror
ARCHIVE=../archive

# Used to terminate when git fast-import fails
trap "exit 1" TERM
export TOP_PID=$$

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


# Branches that get merged
MERGED="BSD-4_4_Lite2 386BSD-0.1"

# Issue a git fast-import data command for the specified string
data()
{
	local LEN=$(echo "$1" | wc -c)
	echo "data $LEN"
	echo "$1"
}

cd import

echo "Adding merge and reference files" 1>&2
{
cat <<EOF
# Start FreeBSD commits
reset refs/heads/FreeBSD-release/2.0
commit refs/heads/FreeBSD-release/2.0
mark :1
author  Diomidis Spinellis <dds@FreeBSD.org> 739896552 +0000
committer  Diomidis Spinellis <dds@FreeBSD.org> 739896552 +0000
$(data "Start development on FreeBSD-release/2.0

Create reference copy of all prior development files")
merge BSD-4_4_Lite2
merge 386BSD-0.1
EOF
for ref in $MERGED ; do
	git ls-tree -r $ref |
	awk '{print "M", $1, $3, ".ref-'$ref'/" $4}'
done
cat <<EOF
reset refs/tags/FreeBSD-2.0-START
from :1
done
EOF
} | gfi

echo "Adding 2.0" 1>&2
{
	../ref-prepend.pl FreeBSD FreeBSD-2.0-START $ARCHIVE/freebsd.git/ --reverse --use-done-feature --progress=1000 release/2.0
	echo done
} | gfi

echo "Removing reference files" 1>&2
{
cat <<EOF
# Now remove reference files
commit refs/heads/FreeBSD-release/2.0
mark :1
author  Diomidis Spinellis <dds@FreeBSD.org> 785501938 +0000
committer  Diomidis Spinellis <dds@FreeBSD.org> 785501938 +0000
$(data "Remove reference files")
from refs/heads/FreeBSD-release/2.0^0
EOF
for ref in $MERGED ; do
	echo "D .ref-$ref/"
done
cat <<EOF
reset refs/tags/FreeBSD-2.0-END
from :1
done
EOF
} | gfi

echo "Adding remainder" 1>&2
# Add the remaining repo
# REFS=$(cd $ARCHIVE/freebsd.git/ ; git branch -l | egrep -v 'projects/|user/|release/2\.0| master')\ HEAD
REFS=$(cd $ARCHIVE/freebsd.git/ ; git branch -l | egrep -v 'projects/|user/|release/2\.0| master' | grep /3)
{
	../ref-prepend.pl FreeBSD FreeBSD-2.0-END $ARCHIVE/freebsd.git/ --reverse --use-done-feature --progress=1000 ^release/2.0 $REFS
	echo done
} | gfi
