#!/bin/sh
#
# Summarize the analyzed unmatched files by directory
#
mkdir -p summarized
cd analyzed
for f in *
do
	sed 's/\/[^/ ]* / /' $f |
	awk '	{ u[$1] += $2; l[$1] += $3 }
	END { for (i in u) print i, u[i], l[i] }' |
	sort -k 2nr >../summarized/$f
done
