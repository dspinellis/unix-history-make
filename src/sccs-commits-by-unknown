#!/usr/local/bin/bash
#
# Display the work context of unknown names in sccs-map

find /mnt -path \*SCCS/s.\* -print |
xargs grep '^d' |
fgrep -f <(sed -n '/ /d;s/^/ /;s/$/ /;p' sccs-map) |
awk '{print $6, $1, $4}' |
sed 's|/mnt/||;s|/SCCS/s\.||;s/:d//' |
sort
