#!/usr/bin/perl
#
# Improt directory snapshots or directories containing SCCS VCS data.
#
# Import the specified directory as a series of time-ordered commits on the
# specified branch name with a "-Development" -version-name suffix.
# Importing SCCS VCS adds all commits found in the tree in a time-ordered
# fashion.
# When starting, specified parts are copied into a reference
# directory to allow log/blame to work across releases.
# When done:
# - the branch is merged with the -Release branch (not for SCCS imports),
# - the reference directories are deleted, and
# - the release is tagged with the specified version name. (-END for SCCS)
#

use strict;
use warnings;

use File::Copy;
use File::Find;
use Getopt::Std;
use Time::Local;
use VCS::SCCS;

# A map from contributor ids to full names
my %full_name;

# Subsitute $ with an id to get a contributor's email address
my $address_template;

# Map from file paths to committers, ordered in terms of precedence
my @committer_map;

# Committer responsible for releases. Set for path .*
my $release_master;

# Set to true for verbose output
# (Might hide import errors)
my $verbose;

$main::VERSION = '0.1';

# Exit after command processing error
$Getopt::Std::STANDARD_HELP_VERSION = 1;

sub
main::HELP_MESSAGE
{
	my ($fh) = @_;
	print $fh qq{
Usage: $0 [options ...] directory branch_name [ version_name tz_offset ]
-c file	Map of the tree's parts tree written by specific contributors
-m T	The commit from which the import will be merged
-n file	Map between contributor login names and full names
-p re	Regular expression of files to process
-r T	During import keep by side a reference copy of the specified files
-S	Import directory through SCCS
-s re	Regular expression to strip paths into committed ones
	By default this is the supplied directory
-u file	File to write unmatched paths (paths matched with a wildcard)

T is a tree-ish series of comma-seperated specifications, normally tag names.
Each reference directory has .ref- prepended to its name.

version_name and tz_offset are not required for SCCS imports
};
}

our($opt_c, $opt_m, $opt_n, $opt_p, $opt_r, $opt_S, $opt_s, $opt_u);
$opt_m = $opt_r = '';

if (!getopts('c:f:m:n:p:r:Ss:u:')) {
	main::HELP_MESSAGE(*STDERR);
	exit 1;

}

if (($opt_S && $#ARGV + 1 != 2) || (!$opt_S && $#ARGV + 1 != 4)) {
	print STDERR "Required argument(s) missing\n";
	main::HELP_MESSAGE(*STDERR);
	exit 1;
}

my $unmatched;
if ($opt_u) {
	open($unmatched, '|-', "LC_COLLATE=C sort >$opt_u") || die "Unable to open $opt_u: $!\n";
}

my $directory = shift;
my $branch = shift;
my $version = shift unless ($opt_S);
my $tz_offset = shift unless ($opt_S);

$opt_s = $directory unless defined($opt_s);
$opt_s .= '/' unless ($opt_s =~ m|/$|);
$opt_s =~ s/([^\w])/\\$1/g;

create_name_map() if (defined($opt_n));
create_committer_map();

# Create branch
my $dev_branch = $opt_S ? $branch : "$branch-Development-$version";
system "git branch $dev_branch" || die "git branch: $!\n";

print STDERR "Import $dev_branch\n";

# Collect text files
if (! -d $directory) {
	print STDERR "$directory is not a directory\n";
	exit 1;
}

my @sccs;

# File information for text files
# ->{mtime} The date each file was last modified
my %fi;

sub
gather_text_files
{
	return unless (-f && -T);
	return if ($opt_p && !m|/$opt_p$|);
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat;
	$fi{$_}->{mtime} = $mtime;
	$fi{$_}->{size} = $size;
	$fi{$_}->{mode} = (-x $_) ? '755' : '644';
}

sub
gather_sccs_files
{
	$File::Find::dir =~ m{(?:^|/)SCCS$} and m/^s\./ or return;
	push @sccs, $File::Find::name;
}

# Now start committing them from oldest to newest
binmode STDOUT;
my $mark = 1;

# Modification time for first and last commit
my $first_mtime;
my $last_mtime;
# Last commit mark
my $last_devel_mark;

sub
create_text_blobs
{
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
}

# http://www.kernel.org/pub/software/scm/git/docs/gitattributes.html
# could be explored to write checkout hooks that translate SCCS
# keywords to actual content. Would be hard to translate back
sub
pr_date
{
	my @dt = localtime shift;
	sprintf "%s %02d-%02d-%4d %02d:%02d:%02d",
	(qw( Sun Mon Tue Wed Thu Fri Sat ))[$dt[6]],
	$dt[3], $dt[4] + 1, $dt[5] + 1900,
	$dt[2], $dt[1], $dt[0];
}

# use a best guess at user, hostname, etc.  FIXME: add authors map :)
my $domain = "ucbvax.Berkeley.EDU";
my %tzoffset;
my $tzoffset = sub {
	my $offset_s = timegm (localtime ($_[0])) - $_[0];
	$offset_s = 0 - 800;
	$tzoffset{$offset_s} ||= ( $offset_s >= 0 ? "+" : "-" )
	. sprintf "%.4d", abs $offset_s;
	};

# Submit in the same sequence as the original
my %sccs;
my %file;
my @fail;

sub
create_sccs_blobs
{
	foreach my $f (sort @sccs) {
		my $sccs;
		eval { $sccs = VCS::SCCS->new ($f) };
		unless ($sccs) {
			warn "Cannot convert $f\n";
			push @fail, $f;
			next;
		}
		# GIT supports get-hooks, to translate on retrieval
		# But it will be useless as you cannot translate back
		$sccs->set_translate ("SCCS");
		my $fn = $sccs->file ();
		$file{$fn}++;
		foreach my $rm (@{$sccs->revision_map ()}) {
			my ($rev, $vsn) = @{$rm};
			my $delta = $sccs->delta ($rev);
			$sccs{pack "NA*", $delta->{stamp}, $fn} = [ $sccs, $rev, $mark ];
			my $data = scalar $sccs->body ($rev);
			print "blob\nmark :", $mark,
					   "\ndata ", length ($data),
					   "\n", $data, "\n";
			printf STDERR "%-20s %3d %8s  %s\r", $fn, $rev, $vsn, pr_date ($delta->{stamp}) if ($verbose);
			$first_mtime = $delta->{stamp} unless defined($first_mtime);
			$last_mtime = $delta->{stamp};
			$tz_offset = $tzoffset->($last_mtime) unless defined($tz_offset);
			$mark++;
		}
		print STDERR "\n" if ($verbose);
	}
}

sub
issue_sccs_commits
{
	foreach my $c (sort keys %sccs) {
		my ($sccs, $rev, $commit_mark) = @{$sccs{$c}};

		my $fn	= $sccs->file ();
		my %delta = %{$sccs->delta ($rev)};
		my $stamp = pr_date ($delta{stamp});
		my $vsn   = $delta{version};

		printf STDERR "%-20s %3d %6s  %s %s %s\n", $fn, $rev, $vsn,
		$stamp, $delta{date}, $delta{"time"} if ($verbose);

		print "commit refs/heads/$dev_branch\n";
		print "mark :$mark\n";
		$last_devel_mark = $mark++;
		print "committer ", $delta{committer}, " <",
			($delta{committer}, "@", $domain, "> ", $delta{stamp} + 64800,
			 " ", $tz_offset = $tzoffset->($delta{stamp}), "\n");

		# tradition is to save all potentially useful but
		# uncategorized metadata as RFC822-style headers in the commit
		# message
		my $mr  = $delta{mr} || ""; $mr =~ s/^-$//;
		$mr  and $mr  = "SCCS-mr: $mr";
		$vsn and $vsn = "SCCS-vsn: $vsn";
		my $cmnt = $delta{comment} || "";
		$cmnt ||= "(no message)";
		$cmnt  .= "\n";
		my $msg  = join "\n", $cmnt, grep m/\S/, $mr, $vsn;

		print "data ", length ($msg), "\n$msg\n";

		my $mode = $delta{flags}{x} ? "755" : "644";
		$fn =~ s/$opt_s// if ($opt_s);
		print "M $mode :$commit_mark $fn\n";
		print "\n";
	}
}

if ($opt_S) {
	$version = '';
	find(\&gather_sccs_files, $directory);
	@sccs or die "No SCCS source files to convert\n";
	create_sccs_blobs();
} else {
	find({wanted => \&gather_text_files, no_chdir => 1 }, $directory);
	create_text_blobs();
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

sub
issue_text_commits
{
	print "# Development commits\n";
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
}

if ($opt_S) {
	issue_sccs_commits();
	$version = 'END';
} else {
	issue_text_commits();
}

# Now issue a release
print "# Release\n";
print "commit refs/heads/$branch" . ($opt_S ? '' : '-Release') . "\n";
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
