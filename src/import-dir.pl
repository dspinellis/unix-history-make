#!/usr/bin/perl
#
# Import directory snapshots or directories containing SCCS VCS data.
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

use Date::Parse;
use File::Copy;
use File::Find;
use Getopt::Std;
use Git::FastExport;
use Git::Repository;
use Time::Local;
use VCS::SCCS;

# A map from contributor ids to full names
my %full_name;

# A map from contributor ids to emails
my %email;

# A map containing paths of files to ignore
my %ignore_map;

# A map containing paths of file to add when merging
my %merge_add_map;

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
-C date	Ignore commits after the specified cutoff date
-c file	Map of the tree's parts written by specific contributors
-G str	Import directory through git. Argument is author and timestamp
	to use for the reference files commit.
-i file	Comma-separated list of files containing pathnames of files to ignore
-I file	Comma-separated list of files containing pathnames of files to ignore
	during incremental import, and add when merging
-m T	The commit(s) from which the import will be merged
-n file	Map between contributor login names and full names
-P path	Path to prepend to file paths (branches for git) being committed
-p re	Regular expression of files to process
-R date	Remove reference files after the specified date (for git import)
-r T	During import keep by side a reference copy of the specified files
-S	Import directory through SCCS
-s path	Leading path to strip from file paths being committed
	By default this is the supplied directory
-u file	File to write unmatched paths (paths matched with a wildcard)

T is a tree-ish series of comma-seperated specifications, normally tag names.
Each reference directory has .ref- prepended to its name.

version_name and tz_offset are not required for SCCS imports
};
}

our($opt_C, $opt_c, $opt_G, $opt_i, $opt_I, $opt_m, $opt_n, $opt_P, $opt_p, $opt_R, $opt_r, $opt_S, $opt_s, $opt_u);
$opt_m = $opt_r = '';

if (!getopts('C:c:G:i:I:m:n:P:p:R:r:Ss:t:u:')) {
	main::HELP_MESSAGE(*STDERR);
	exit 1;

}

# Expected arguments
my $ea;
if (($opt_S && $#ARGV + 1 != ($ea = 2)) ||
    (!$opt_S && !$opt_G && $#ARGV + 1 != ($ea = 4)) ||
    ($opt_G && $#ARGV + 1 < ($ea = 2))) {
	print STDERR "Expected $ea required arguments\n";
	main::HELP_MESSAGE(*STDERR);
	exit 1;
}

my $unmatched;
if ($opt_u) {
	open($unmatched, '|-', "LC_COLLATE=C sort -u >$opt_u") || die "Unable to open $opt_u: $!\n";
}

my $cutoff_time;
if ($opt_C) {
	$cutoff_time = str2time($opt_C);
}

my $reference_stop_time;
if ($opt_R) {
	$reference_stop_time = str2time($opt_R);
}

my $directory = shift;
my $branch = shift;
my $version = '';
$version = shift unless ($opt_S || $opt_G);
my $tz_offset = shift unless ($opt_S || $opt_G);

# Prepare for issuing fast-export blocks
binmode STDOUT;
my $mark = $opt_G ? 1000000 : 1;

my $dev_branch = ($opt_S || $opt_G) ? "$branch-Import" : "$branch-Development-$version";
$dev_branch = $opt_P . $dev_branch if ($opt_P);

print STDERR "Import $dev_branch\n";

create_name_map() if (defined($opt_n));

# Fast exit for git import
if ($opt_G) {
	git_import();
	exit 0;
}

$opt_s = $directory unless defined($opt_s);
$opt_s .= '/' unless ($opt_s =~ m|/$|);
$opt_s =~ s/([^\w])/\\$1/g;
$opt_s = '^' . $opt_s;

create_map($opt_i, \%ignore_map);
create_map($opt_I, \%merge_add_map);
create_committer_map();

# Create branch
system "git branch $dev_branch" || die "git branch: $!\n";

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
	# Skip over unreadable directories; e.g. CSRG/cd2/net.2/var/spool/ftp/hidden
	if (-d && !-r) {
		$File::Find::prune = 1;
		return;
	}
	return unless (-f && -T);
	return if ($opt_p && !m|/$opt_p$|);
	if ($opt_i || $opt_I) {
		my $commit_path = $_;
		$commit_path =~ s/$opt_s// if ($opt_s);
		$fi{$_}->{commit_at_release} = 1 if ($merge_add_map{$commit_path});
		return if ($ignore_map{$commit_path});
	}
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

# use a best guess at user, hostname, etc.
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
		return if (defined($cutoff_time) && $delta{stamp} > $cutoff_time);
		my $stamp = pr_date ($delta{stamp});
		my $vsn   = $delta{version};

		printf STDERR "%-20s %3d %6s  %s %s %s\n", $fn, $rev, $vsn,
		$stamp, $delta{date}, $delta{"time"} if ($verbose);

		print "commit refs/heads/$dev_branch\n";
		print "mark :$mark\n";
		$last_devel_mark = $mark++;
		print "committer ", full_name($delta{committer}), " <",
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
		$fn = $opt_P . $fn if ($opt_P);
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

if (!defined($first_mtime)) {
	print STDERR "No files for import found in $directory\n";
	exit 1;
}

issue_start_commit();

# Issue the commit that starts development
# Return the commit's mark
sub
issue_start_commit
{
	# Add license blobs
	my $text_license_blob = add_file_blob('../old-code-license');
	my $caldera_license_blob = add_file_blob('../Caldera-license.pdf');
	my $readme_blob = add_file_blob('../../README.md');

	# The actual development commits
	print "# Start development commits from a clean slate\n";
	print "commit refs/heads/$dev_branch\n";
	print "mark :$mark\n";
	if ($opt_G) {
		print "author $opt_G\n";
		print "committer $opt_G\n";
	} else {
		print "author $release_master $first_mtime $tz_offset\n";
		print "committer $release_master $first_mtime $tz_offset\n";
	}
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
	# Add README and licenses
	print "M 644 :$readme_blob README.md\n";
	print "M 644 :$text_license_blob LICENSE\n";
	print "M 644 :$caldera_license_blob Caldera-license.pdf\n";
	return $mark++;
}

sub
issue_text_commits
{
	print "# Development commits\n";
	for my $name (sort {$fi{$a}->{mtime} <=> $fi{$b}{mtime}} keys %fi) {
		next if (defined($cutoff_time) && $fi{$name}->{mtime} > $cutoff_time);
		$last_mtime = $fi{$name}->{mtime};
		next if ($fi{$name}->{commit_at_release});

		print "# $fi{$name}->{mtime} $name\n";
		print "commit refs/heads/$dev_branch\n";
		print "mark :$mark\n";
		$last_devel_mark = $mark++;
		my $commit_path = $name;
		$commit_path =~ s/$opt_s// if ($opt_s);
		$commit_path = $opt_P . $commit_path if ($opt_P);
		my $author = committer($commit_path);
		print "author $author $fi{$name}->{mtime} $tz_offset\n";
		print "committer $author $fi{$name}->{mtime} $tz_offset\n";
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
print "from :$last_devel_mark\n" if defined($last_devel_mark);
for my $merge (split(/,/, $opt_m)) {
	print "merge $merge\n";
}
# Add delayed commit files
print "# Commits of merged files\n";
for my $name (sort {$fi{$a}->{mtime} <=> $fi{$b}{mtime}} keys %fi) {
	next if (defined($cutoff_time) && $fi{$name}->{mtime} > $cutoff_time);
	next unless ($fi{$name}->{commit_at_release});
	print "# $fi{$name}->{mtime} $name\n";
	my $commit_path = $name;
	$commit_path =~ s/$opt_s// if ($opt_s);
	$commit_path = $opt_P . $commit_path if ($opt_P);
	print "M $fi{$name}->{mode} :$fi{$name}->{id} $commit_path\n";
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
print STDERR "Done importing $dev_branch\n";

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
			if (!$committer) {
				print STDERR "$opt_c($.): Unspecied committer\n";
				exit 1;
			}
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


# Create a map to entries in the specified comma-separated list of files
sub
create_map
{
	my ($fname_list, $map_ref) = @_;

	return unless defined($fname_list);

	for my $fname (split(/\,/, $fname_list)) {
		open(my $in, '<', $fname) || die "Unable to open $fname: $!\n";
		while (<$in>) {
			chop;
			s/#.*//;
			s/^\s*//;
			next if (/^$/);
			$map_ref->{$_} = 1;
		}
		close($in);
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
		my ($id, $name, $email) = split(/:/, $_);
		if (defined($full_name{$id})) {
			print STDERR "Name for $id already defined as $full_name{$id}\n";
			exit 1;
		}
		$full_name{$id} = $name;
		if (defined($email)) {
			$email{$id} = $email;
		} else {
			$email{$id} = email_address($id);
		}
	}
	close($in);
}

# Return the domain associated with the specified email address
# Can handle UUCP and RFC-822 addresses
sub
get_domain
{
	my ($email) = @_;

	if ($email =~ m/^[^@]+\@(.*)$/) {
		return $1;
	} elsif ($email =~ m/^([^!]+)\!.*$/) {
		return $1;
	} else {
		print STDERR "Unable to get domain for address $email\n";
		exit 1;
	}
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
		# Check that names are valid and set same_domain to true
		# if all share the same domain
		my $same_domain = 1;
		my $domain = defined($address_template) ? get_domain(email_address("x.y.z.z.y")) : '';
		for my $i (@ids) {
			check_name($i);
			my $this_domain = get_domain($email{$i});
			$same_domain = 0 if ($domain ne $this_domain);
		}
		my @names = map { $full_name{$_} } @ids;
		my $name = join(' and ', @names);

		my $address;
		if ($same_domain) {
			$address = email_address("{$id}");
		} else {
			my @addresses = map { $email{$_} } @ids;
			$address = '{' . join(',', @addresses) . '}';
		}
		return "$name <$address>";
	} else {
		check_name($id);
		return "$full_name{$id} <$email{$id}>";
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

# Return a committer's full name, if available
# If not return the id, and save the unmatched id
sub
full_name
{
	my ($id) = @_;
	my $full = $full_name{$id};
	if (defined($full)) {
		return $full;
	} else {
		print $unmatched "$id\n" if (defined($unmatched));
		return $id;
	}
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

# Import files through git
# This routine modifies the git fast-export stream as follows.
# 1. It starts the sequence with the specified merge (-m)
# 2. It injects the specified reference files (-r) at the beginning of
#    all initial commits (those with no parents) up to the time point
#    specified with the -R option.
# 3. It removes the injected specified reference files from all the
#    graph edges they appear on after the specified time point.
# 4. It prepends to all branch names the string specified with -P.
sub
git_import
{

	# get the object from a Git::Repository
	my $repo = Git::Repository->new(work_tree => $directory);
	my $export = Git::FastExport->new($repo);
	$export->fast_export(('--date-order', '--reverse', $branch, @ARGV));

	my $added_ref = 0;
	my $removed_ref = 0;

	# Start with a merge and a copy of the specified reference files
	my $ref_mark = issue_start_commit();

	# Commits that have reference files in their ancestors
	my @has_ref;

	while (my $block = $export->next_block()) {
		# print STDERR $block->{header}, ":", join(' ', keys(%$block)), "\n";
		# Prepend the specified string to branch names
		$block->{header} =~ s:((commit|reset) refs/heads/)(.+)$:${1}$opt_P$3:o if ($opt_P);
		if ($block->{header} !~ m/^commit/) {
			print $block->as_string();
			next;
		}
		$block->{author}->[0] =~ s/^author\s+(\S+)\s+/author $full_name{$1} /
			if ($block->{author}->[0] =~ m/^author\s+(\S+)\s+/ &&
			    $full_name{$1});
		$block->{committer}->[0] =~ s/^committer\s+(\S+)\s+/committer $full_name{$1} /
			if ($block->{committer}->[0] =~ m/^committer\s+(\S+)\s+/ &&
			    $full_name{$1});
		# Process commits
		my ($mark) = ($block->{mark}->[0] =~ m/^mark\s+\:(\d+)/);
		my ($time) = ($block->{committer}->[0] =~ m/^[^<]*\<[^>]*\>\s*(\d+)\s+/);
		if (!defined($time)) {
			print STDERR "Undefined time in: ", @{$block->{committer}}[0], "\n";
		}
		# Pass the has_ref attribute down the commit chain
		my $from;
		if ($block->{from} && $mark) {
			($from) = ($block->{from}->[0] =~ m/^from\s+\:(\d+)/);
			$has_ref[$mark] = $has_ref[$from];
		}
		# Add reference files, if needed
		if ($opt_r && $time < $reference_stop_time && !$block->{from}) {
			my @from = ("from :$ref_mark");
			$block->{from} = \@from;
			$has_ref[$mark] = 1;
			$added_ref++;
		}
		# Remove reference files, if needed
		if ($opt_r && $time >= $reference_stop_time && $has_ref[$mark]) {
			my @files;
			@files = @{$block->{files}} if (defined($block->{files}));
			for my $ref (split(/,/, $opt_r)) {
				push(@files, "D .ref-$ref");
			}
			$block->{files} = \@files;
			$has_ref[$mark] = 0;
			$removed_ref++;
		}
		print $block->as_string();
	}
	print "done\n";
	print STDERR "Added reference files to $added_ref commit(s)\n";
	print STDERR "Removed reference files from $removed_ref commit(s)\n";
	print STDERR "Done importing ", join(' ', $branch, @ARGV), "\n";
}
