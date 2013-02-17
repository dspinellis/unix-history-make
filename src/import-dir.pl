#!/usr/bin/perl
#
# Import the specified directory as a series of time-ordered commits on the
# specified branch name with a "-Development" suffix.
# When done, any files in branch name "-Development" branch are deleted,
# the files are moved to the -Release branch,
# and the release is tagged with the specified name.

use strict;
use warnings;
use Getopt::Std;
use File::Find;
use File::Copy;

$main::VERSION = '0.1';

# Exit after command processing error
$Getopt::Std::STANDARD_HELP_VERSION = 1;

sub
main::HELP_MESSAGE
{
	my ($fh) = @_;
	print $fh qq{
Usage: $0 [-c contributor_map] [-m commit] [-p path_map] directory branch_name tag
tz_offset
-c	Specify a map of the tree's parts tree written by
	specific contributors
-m	Specify the commit from which the release will be merged
-p	Specify a regular expression to strip paths into committed ones
	By default this is the supplied directory
};
}

our($opt_c, $opt_m, $opt_p);
if (!getopts('c:m:p:') || $#ARGV + 1 != 4) {
	print STDERR $#ARGV;
	main::HELP_MESSAGE(*STDERR);
	exit 1;
}

my $directory = shift;
my $branch = shift;
my $tag = shift;
my $tz_offset = shift;

$opt_p = $directory unless defined($opt_p);
$opt_p .= '/' unless ($opt_p =~ m|/$|);
$opt_p =~ s/([^\w])/\\$1/g;

create_committer_map();

# Collect text files
if (! -d $directory) {
	print STDERR "$directory is not a directory\n";
	exit 1;
}
find({wanted => \&gather_files, no_chdir => 1 }, $directory);

# File information
# ->{mtime} The date each file was last modified
my %fi;

sub
gather_files
{
	return unless (-f && -T);
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat;
	$fi{$_}->{mtime} = $mtime;
	$fi{$_}->{size} = $size;
	$fi{$_}->{mode} = (-x $_) ? '755' : '644';
}

# Now start committing them from oldest to newest
binmode STDOUT;
my $mark = 1;

my $first_mtime;
# First create the blobs
for my $name (sort {$fi{$a}->{mtime} <=> $fi{$b}{mtime}} keys %fi) {
	print "# $fi{$name}->{mtime} $name\n";
	$first_mtime = $fi{$name}->{mtime} unless defined($first_mtime);
	$fi{$name}->{id} = $mark;
	print "blob\n";
	print "mark :$mark\n";
	print "data $fi{$name}->{size}\n";
	# Flush stdout
	$| = 1;
	$| = 0;
	copy($name, \*STDOUT);
	$mark++;
}

# The actual development commits
print "# Start development commits from a clean slate\n";
print "commit refs/heads/$branch-Development\n";
my $author = committer('///');
print "author $author $first_mtime $tz_offset\n";
print "committer $author $first_mtime $tz_offset\n";
print data("Start development on $branch $tag\n\nDelete all prior development files");
print "from refs/heads/$branch-Development^0\n";
print "merge $opt_m\n" if (defined($opt_m));
print "deleteall\n";

print "# Development commits\n";
my $last_mtime;
my $last_devel_mark;
for my $name (sort {$fi{$a}->{mtime} <=> $fi{$b}{mtime}} keys %fi) {
	print "# $fi{$name}->{mtime} $name\n";
	print "commit refs/heads/$branch-Development\n";
	print "mark :$mark\n";
	$last_devel_mark = $mark++;
	my $commit_path = $name;
	$commit_path =~ s/$opt_p// if ($opt_p);
	my $author = committer($commit_path);
	print "author $author $fi{$name}->{mtime} $tz_offset\n";
	print "committer $author $fi{$name}->{mtime} $tz_offset\n";
	$last_mtime = $fi{$name}->{mtime};
	print data("$branch $tag development\n\nAdd file $commit_path");
	print "M $fi{$name}->{mode} :$fi{$name}->{id} $commit_path\n";
}

# Now issue a release
print "# Release\n";
print "commit refs/heads/$branch-Release\n";
print "mark :$mark\n";
my $release_mark = $mark++;
$author = committer('///');
print "author $author $last_mtime $tz_offset\n";
print "committer $author $last_mtime $tz_offset\n";
print data("$branch $tag release\n\nSnapshot of all files from the development branch");
print "from refs/heads/$branch-Release^0\n";
print "merge :$last_devel_mark\n";
for my $name (keys %fi) {
	my $commit_path = $name;
	$commit_path =~ s/$opt_p// if ($opt_p);
	print "M $fi{$name}->{mode} :$fi{$name}->{id} $commit_path\n";
}

# Tag the release
print "tag $branch-$tag\n";
print "from :$release_mark\n";
print "tagger $author $last_mtime $tz_offset\n";
print data("Tagged $tag release snapshot of $branch with $tag\n\nSource directory: $directory");


# Signify that we're finished
print "done\n";

# Return the argument as a fast-import data element
sub
data
{
	my ($d) = @_;
	$d .= "\n" unless ($d =~ m/\n$/);
	return "data " . length($d) . "\n" . $d;
}

my @committer_map;

# Create a map from file paths to committers
sub
create_committer_map
{
	if (defined($opt_c)) {
		open(my $in, '<', $opt_c) || die "Unable to open $opt_c: $!\n";
		while (<$in>) {
			chop;
			s/#.*//;
			s/^\s*//;
			next if (/^$/);
			my ($pattern, $committer) = split(/\t+/, $_);
			push(@committer_map, {
				pattern => $pattern,
				committer => $committer
			});
		}
		close($in);
	}
	# Final catch-all
	push(@committer_map, {
		pattern => '.*',
		committer => 'Unknown <unknown@example.com>'
	});
}

# Return the committer for the specified file path
sub
committer
{
	my ($path) = @_;

	for my $re (@committer_map) {
		return $re->{committer} if ($path =~ m/^$re->{pattern}/);
	}
	print STDERR "Unable to map comitter for $path\n";
	exit 1;
}
