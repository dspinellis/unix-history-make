#!/bin/bash

# DEBUG=1

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
MERGED="BSD-4_4_Lite2,386BSD-0.1"

cd import

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
