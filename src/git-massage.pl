#!/usr/bin/perl
#
# ref-prepend prepend-string from-ref repo-path export-args
# Prepend the specified string to all refs of a git fast-export
# of the specified repository and fast-export arguments.
#

use strict;
use warnings;

use Git::Repository;
use Git::FastExport;

my $string = shift;
my $from = shift;

# get the object from a Git::Repository
my $repo = Git::Repository->new( work_tree => shift);
my $export = Git::FastExport->new($repo);
$export->fast_export(@ARGV);

my $added_from;
while ( my $block = $export->next_block() ) {
	$block->{header} =~ s:((commit|reset) refs/heads/)(.+)$:${1}$string-$3:o;
	if (!$added_from && $block->{header} =~ m/^commit/) {
		my @from = ("from $from");
		$block->{from} = \@from;
		$added_from = 1;
	}
	print $block->as_string();
}
