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
Usage: $0 [options ...] directory branch_name version_name tz_offset
-c file	Map of the tree's parts tree written by specific contributors
-m T	The commit from which the import will be merged
-n file	Map between contributor login names and full names
-p re	Regular expression of files to process
-r T	During import keep by side a reference copy of the specified files
-s re	Regular expression to strip paths into committed ones
	By default this is the supplied directory
-u file	File to write unmatched paths (paths matched with a wildcard)

T is a tree-ish series of comma-seperated specifications, normally tag names.
Each reference directory has .ref- prepended to its name.
};
}

our($opt_c, $opt_m, $opt_n, $opt_p, $opt_r, $opt_s, $opt_u);
$opt_m = $opt_r = '';
if (!getopts('c:f:m:n:p:r:s:u:') || $#ARGV + 1 != 4) {
	print STDERR $#ARGV;
	main::HELP_MESSAGE(*STDERR);
	exit 1;
}

my $unmatched;
if ($opt_u) {
	open($unmatched, '|-', "LC_COLLATE=C sort >$opt_u") || die "Unable to open $opt_u: $!\n";
}

my $directory = shift;
my $branch = shift;
my $version = shift;
my $tz_offset = shift;

$opt_s = $directory unless defined($opt_s);
$opt_s .= '/' unless ($opt_s =~ m|/$|);
$opt_s =~ s/([^\w])/\\$1/g;

create_name_map() if (defined($opt_n));
create_committer_map();

# Create branch
my $dev_branch = "$branch-Development-$version";
system "git branch $dev_branch" || die "git branch: $!\n";

print STDERR "Import $dev_branch\n";

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
	return if ($opt_p && !m|/$opt_p$|);
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

my $license_blob = add_file_blob('../old-code-license');
my $readme_blob = add_file_blob('../../README.md');

if (!defined($first_mtime)) {
	print STDERR "No files for import found in $directory\n";
	exit 1;
}

# The actual development commits
print "# Start development commits from a clean slate\n";
print "commit refs/heads/$dev_branch\n";
print "author $release_master $first_mtime $tz_offset\n";
print "committer $release_master $first_mtime $tz_offset\n";
print data("Start development on $branch $version\n" . ($opt_r ? "\nCreate reference copy of all prior development files\n" : ''));
# Specify merges
for my $merge (split(/,/, $opt_m)) {
	print "merge $merge\n";
}
# Add reference copies of older files
for my $ref (split(/,/, $opt_r)) {
	my $cmd;
	open(my $ls, '-|', $cmd = "git ls-tree -r $ref") || die "Unable to open run $cmd: $!\n";
	while (<$ls>) {
		chop;
		my ($mode, $blob, $sha, $path) = split;
		print "M $mode $sha .ref-$ref/$path\n";
	}
}
# Add README and license
print "M 644 :$readme_blob README.md\n";
print "M 644 :$license_blob LICENSE\n";

print "# Development commits\n";
my $last_mtime;
my $last_devel_mark;
for my $name (sort {$fi{$a}->{mtime} <=> $fi{$b}{mtime}} keys %fi) {
	print "# $fi{$name}->{mtime} $name\n";
	print "commit refs/heads/$dev_branch\n";
	print "mark :$mark\n";
	$last_devel_mark = $mark++;
	my $commit_path = $name;
	$commit_path =~ s/$opt_s// if ($opt_s);
	my $author = committer($commit_path);
	print "author $author $fi{$name}->{mtime} $tz_offset\n";
	print "committer $author $fi{$name}->{mtime} $tz_offset\n";
	$last_mtime = $fi{$name}->{mtime};
	print data("$branch $version development\n\nWork on file $commit_path");
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
for my $merge (split(/,/, $opt_m)) {
	print "merge $merge\n";
}
# Remove reference copies of older files
for my $ref (split(/,/, $opt_r)) {
	print "D .ref-$ref\n";
}

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
	if (!defined($address_template)) {
		print STDERR "Address template not defined for $id\n";
		exit 1;
	}
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
		if ($path =~ m/^$re->{pattern}/) {
			if (defined($unmatched) && $re->{pattern} eq '.*') {
				print $unmatched "$path\n";
			}
			return $re->{committer};
		}
	}
	print STDERR "Unable to map comitter for $path\n";
	exit 1;
}

# Add the specified file to the repo as a blob returning its mark
sub
add_file_blob
{
	my ($name) = @_;
	if (!-r $name) {
		print STDERR "$name: $!\n";
		exit 1;
	}
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat $name;
	print "# Manual addition of $name\n";
	print "blob\n";
	print "mark :$mark\n";
	print "data $size\n";
	# Flush stdout
	$| = 1;
	$| = 0;
	copy($name, \*STDOUT);
	return $mark++;
}
