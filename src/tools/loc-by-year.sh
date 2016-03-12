#!/bin/bash
#
# For each tag create a file with the number of lines per year
#

mkdir -p loc-by-year
cd import
for tag in $(git tag -l) ; do
	if [ -r ../loc-by-year/$tag ] ; then
		continue
	fi
	git checkout $tag
	find .  -name .git -prune -o -type f -print0 |
	xargs -0 -n 1 git blame -C -C --line-porcelain |
	perl -ne 'if (/^author-time\s+(\d+)/) { ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($1); $count[$year]++}  END {for ($y = 70 ; $y < 114; $y++) { print $y + 1900, "\t", $count[$y], "\n" if ($count[$y])}}' >../loc-by-year/$tag
done
