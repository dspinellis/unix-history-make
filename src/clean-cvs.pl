#!/usr/bin/perl
#
# Leave only the specified RE in the symbols list of the CVS repository
# files in the given directory
#

use strict;
use warnings;

use File::Find;

if ($#ARGV != 1) {
	print STDERR "Usage: $0 directory RE\n";
	exit 1;
}

my $directory = shift;
my $re = shift;

find(\&fix_file, $directory);

sub
fix_file
{
	return unless -f;
	return unless /\,v$/;
	my $backup = "$_.bal";
	rename "$_", $backup || die "rename of $_ failed: $!\n";
	open(my $in, '<', $backup) || die "Unable to open $_.bak for reading: $!\n";
	open(my $out, '>', "$_") || die "Unable to open $_.bak for writing: $!\n";
	my $fixed;
	my $in_symbols;
	my $symbols = '';
	while (<$in>) {
		if (!$fixed && /^symbols$/) {
			$in_symbols = 1;
		} elsif (!$fixed && /^symbols .*;$/) {
			# Old style symbols
			# symbols  xntp_3_3s:1.1.1.1 udel:1.1.1;
			# Substitute the RE pair we want with ^A separator
			s/(\s+)(FINAL_.*)\:(\S+)/$1$2$3/g;
			s/\s+[^\t :]+\:[^ ;]+//g;
			s//:/g;
			$fixed = 1;
		} elsif ($in_symbols) {
			if (/^locks/) {
				$fixed = 1;
				$in_symbols = 0;
				$symbols =~ s/$/;/ unless ($symbols =~ m/;$/);
				print $out $symbols;
			} elsif (/^\t$re\:/) {
				$symbols .= $_;
				next;
			} else {
				next;
			}
		}
		print $out $_;
	}
	unlink $backup;
}
