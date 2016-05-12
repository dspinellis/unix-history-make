#!/usr/bin/awk -f
#
# Summarize the output of diff -r in terms of different files, lines,
# and missing files.
# Ignore RCS ids and some development artefacts
# Run ./diff-sum.awk verbose=1 diff.out to get human-readable
# output of the actual differences
# Otherwise the program outputs only a summary suitable for scripts

BEGIN {

	diff_files = diff_lines = only_files = 0
}

# Ignore obj directories and tags files
/: (obj|tags)$/ { next }

# Ignore Git repo
/\/\.git\// { next }

# Ignore RCS ids
/\$(Id|Header|Log|Revision|Source|Author)/ { next }

# Ignore diff syntax
/^(---|[0-9,]+c[0-9,]+$)/ { next }

/^diff / {
	if (count > 0) {
		if (verbose) print name, count
		diff_lines += count
		diff_files++
	}
	count = 0
	name = $3
	next
}

/^Only / {
	if (verbose) print
	only_files++
}

# Count differences
{ count++ }

END { print diff_files, diff_lines, only_files }
