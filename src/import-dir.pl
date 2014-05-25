#!/usr/bin/perl
#
# Import the specified directory as a series of time-ordered commits on the
# specified branch name with a "-Development" -version-name suffix.
# When starting, any files in merged branch are moved into a temporary
# directory to allow log/blame to work across releases.
# When done the branch is merged with the -Release branch,
# the temporary directory is deleted,
# and the release is tagged with the specified version name.

use strict;
use warnings;
use Getopt::Std;
use File::Find;
use File::Copy;

# A map from contributor ids to full names
my %full_name;

# Subsitute $ with an id to get a contributor's email address
my $address_template;

# Map from file paths to committers, ordered in terms of precedence
my @committer_map;

# Committer responsible for releases. Set for path .*
my $release_master;

$main::VERSION = '0.1';

# Exit after command processing error
$Getopt::Std::STANDARD_HELP_VERSION = 1;

sub
main::HELP_MESSAGE
{
	my ($fh) = @_;
	print $fh qq{
Usage: $0 [-c contributor_map] [-f file_pattern] [-m commit] [-n name_map]
  [-p path_map] directory branch_name version_name tz_offset
-c	Specify a map of the tree's parts tree written by
	specific contributors
-f	Regular expression of files to process
-m	Specify the commit from which the release will be merged
-n	Specify a map between contributor login names and full names
-p	Specify a regular expression to strip paths into committed ones
	By default this is the supplied directory
};
}

our($opt_c, $opt_f, $opt_m, $opt_n, $opt_p);
if (!getopts('c:f:m:n:p:') || $#ARGV + 1 != 4) {
	print STDERR $#ARGV;
	main::HELP_MESSAGE(*STDERR);
	exit 1;
}

my $directory = shift;
my $branch = shift;
my $version = shift;
my $tz_offset = shift;

$opt_p = $directory unless defined($opt_p);
$opt_p .= '/' unless ($opt_p =~ m|/$|);
$opt_p =~ s/([^\w])/\\$1/g;

create_name_map() if (defined($opt_n));
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
	return if ($opt_f && !m|/$opt_f$|);
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat;
	$fi{$_}->{mtime} = $mtime;
	$fi{$_}->{size} = $size;
	$fi{$_}->{mode} = (-x $_) ? '755' : '644';
}

# Now start committing them from oldest to newest
binmode STDOUT;
my $mark = 1;

# Name of directory used for storing the previous snapshot
my $backup = '.previous_snapshot';

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
print "commit refs/heads/$branch-Development-$version\n";
print "author $release_master $first_mtime $tz_offset\n";
print "committer $release_master $first_mtime $tz_offset\n";
print data("Start development on $branch $version\n\nBackup all prior development files");
if (defined($opt_m)) {
	print "from $opt_m\n";
	# Create a directory of the previous snapshot
	# This is required for git blame / log to detect file copy operations
	# for new data added
	my $empty_tree = `git mktree </dev/null`;
	chop $empty_tree;
	print "M 040000 $empty_tree $backup\n";

	# Move all existing files into the backup directory
	for my $entry (`git ls-tree --name-only $opt_m`) {
		chop $entry;
		next if ($entry eq 'LICENSE');
		print "R $entry $backup/$entry\n";
	}
}

print "# Development commits\n";
my $last_mtime;
my $last_devel_mark;
for my $name (sort {$fi{$a}->{mtime} <=> $fi{$b}{mtime}} keys %fi) {
	print "# $fi{$name}->{mtime} $name\n";
	print "commit refs/heads/$branch-Development-$version\n";
	print "mark :$mark\n";
	$last_devel_mark = $mark++;
	my $commit_path = $name;
	$commit_path =~ s/$opt_p// if ($opt_p);
	my $author = committer($commit_path);
	print "author $author $fi{$name}->{mtime} $tz_offset\n";
	print "committer $author $fi{$name}->{mtime} $tz_offset\n";
	$last_mtime = $fi{$name}->{mtime};
	print data("$branch $version development\n\nAdd file $commit_path");
	print "M $fi{$name}->{mode} :$fi{$name}->{id} $commit_path\n";
}

# Now issue a release
print "# Release\n";
print "commit refs/heads/$branch-Release\n";
print "mark :$mark\n";
my $release_mark = $mark++;
print "author $release_master $last_mtime $tz_offset\n";
print "committer $release_master $last_mtime $tz_offset\n";
print data("$branch $version release\n\nSnapshot of the completed development branch");
print "from :$last_devel_mark\n";
print "merge $opt_m\n" if (defined($opt_m));
print "D $backup\n" if ($opt_m);

# Tag the release
print "tag $branch-$version\n";
print "from :$release_mark\n";
print "tagger $release_master $last_mtime $tz_offset\n";
print data("Tagged $version release snapshot of $branch with $version\n\nSource directory: $directory");


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
			$committer = add_name_email($committer);
			push(@committer_map, {
				pattern => $pattern,
				committer => $committer
			});
			$release_master = $committer if ($pattern eq '.*');
		}
		close($in);
	}
	if (!defined($release_master)) {
		print STDERR "No default committer specified\n";
		exit 1;
	}
}


# Create a map from contributor ids to full names and populate address_template
sub
create_name_map
{

	open(my $in, '<', $opt_n) || die "Unable to open $opt_n: $!\n";
	while (<$in>) {
		chop;
		s/#.*//;
		s/^\s*//;
		next if (/^$/);
		# Address email format
		# %A research!$1
		if (/^%A (.*)/) {
			$address_template = $1;
			next;
		}
		my ($id, $name) = split(/:/, $_);
		if (defined($full_name{$id})) {
			print STDERR "Name for $id already defined as $full_name{$id}\n";
			exit 1;
		}
		$full_name{$id} = $name;
	}
	close($in);
}

# Given a committer id (or full details) add full name and email if needed
# Examples:
# Jon Doe <joe@example.com> stays as is
# jd becomes Jon Doe <joe@example.com>
sub
add_name_email
{
	my ($id) = @_;

	# Return if id already contains an email field
	return $id if ($id =~ m/</);

	if ($id =~ m/,/) {
		# Multiple names
		my @ids = split(/,/, $id);
		for my $i (@ids) {
			check_name($i);
		}
		my @names = map { $full_name{$_} } @ids;
		my $name = join(' and ', @names);
		my $address = email_address("{$id}");
		return "$name <$address>";
	} else {
		check_name($id);
		my $address = email_address($id);
		return "$full_name{$id} <$address>";
	}
}

# Given a committer id, return the email address based on the
# address template
sub
email_address
{
	my ($id) = @_;
	my $address = $address_template;
	$address =~ s/\$/$id/g;
	return $address;
}

# Exit with an error if a full name is not defined for a given contributor id
sub
check_name
{
	my ($id) = @_;
	return if (defined($full_name{$id}));
	print STDERR "No full name defined for contributor id $id\n";
	exit 1;
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
