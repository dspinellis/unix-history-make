#!/usr/bin/perl
#
# ref-prepend prepend-string from-ref repo-path export-args
# Prepend the specified string to all refs of a git fast-export
# of the specified repository and fast-export arguments.
#

use strict;
use warnings;

use Getopt::Std;
use Git::Repository;
use Git::FastExport;


$main::VERSION = '0.1';

# Exit after command processing error
$Getopt::Std::STANDARD_HELP_VERSION = 1;

sub
main::HELP_MESSAGE
{
	my ($fh) = @_;
	print $fh qq{
Usage: $0 [options ...] repository
-a ref	Commit reference to initialize all commits lacking a from command
-f ref	Commit reference to initialize the first commit
-p str	String to prepend to branch names
};
}

our($opt_a, $pt_f, $opt_p);

if (!getopts('a:f:p:') || $#ARGV < 0) {
	main::HELP_MESSAGE(*STDERR);
	exit 1;

}

my $from = $opt_f || $opt_a;

# get the object from a Git::Repository
my $repo = Git::Repository->new( work_tree => shift);
my $export = Git::FastExport->new($repo);
$export->fast_export(@ARGV);

my $added_from;

while (my $block = $export->next_block()) {
	$block->{header} =~ s:((commit|reset) refs/heads/)(.+)$:${1}$opt_p-$3:o if ($opt_p);
	if ($block->{header} =~ m/^commit/ && !$block->{from} &&
	    ($opt_a || !$added_from)) {
			my @from = ("from $from");
			$added_from = 1;
			$block->{from} = \@from
	}
	print $block->as_string();
}
