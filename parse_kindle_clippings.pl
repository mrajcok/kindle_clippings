#!/usr/bin/perl -w
# Copyright © Mark Rajcok 2011
# Parses Kindle's "My Clippings.txt" file for highlights and notes
# (skips bookmarks) and groups them by book/title, ordered by location.
# Highlights start with "-", notes start with '*'
# A UTF-8 encoded file is created: ordered_clippings.txt
#
# Sample input (My Clippings.txt):
#
# 97_Things_Every_Programmer_Should_Know
# - Highlight Loc. 250-51  | Added on Wednesday, December 29, 2010, 06:10 AM
# 
# As soon as you make the decision to compromise, write a task card or log it
# ==========
# 97_Things_Every_Programmer_Should_Know
# - Highlight Loc. 298  | Added on Wednesday, December 29, 2010, 06:19 AM
# 
# the best way to capture requirements is to watch users.
# ==========
# 97_Things_Every_Programmer_Should_Know
# - Note Loc. 1453  | Added on Sunday, January 02, 2011, 09:40 PM
# 
# this is a personal note
# ==========
#
# Sample output ordered_clippings.txt):
#
# 97_Things_Every_Programmer_Should_Know
# --------------------------------------
# - As soon as you make the decision to compromise, write a task card or log it
# - the best way to capture requirements is to watch users.
# * this is a personal note

use warnings;
use strict;

my $MY_CLIPPINGS_FILE = "$ENV{USERPROFILE}\\My Documents\\My Clippings.txt";
my $OUTPUT_FILE       = "$ENV{USERPROFILE}\\My Documents\\ordered_clippings.txt";
# NOTE: the file is in UTF-8 format -- the first 3 bytes are
# a byte order mark: EF BB BF = 0xFEFF when decoded via UTF-8
open my $clips_fh, "<:encoding(utf8)", $MY_CLIPPINGS_FILE
	or die "Unable to open file $MY_CLIPPINGS_FILE: $!";
# since there might be UTF-8 encoded characters in the input, also output UTF-8
open my $output_fh, ">:utf8", $OUTPUT_FILE  # auto UTF-8 encoding on write
	or die "Unable to create output file $OUTPUT_FILE: $!";
binmode STDOUT, ":encoding(utf8)";

my %clips;
while(<$clips_fh>) {
	my $title = $_;
	$title =~ s/^\x{FEFF}//; # remove BOM
	my $line = <$clips_fh>;
	my ($type, $location);
	if($line =~ /^-\s+(\w+)\s+Loc.\s+(\d+)/) {
		($type, $location) = ($1, $2);
		# print "type=$type ";
	} else {
		die "Can't find clip type: " . $line;
	}
	if($type =~ /bookmark/i) {
		# print "skipping $type ";
		&skip_entry
	} else {
		while(1) {
			$line = <$clips_fh>;
			next if $line =~ /^\s*$/;  # skip blank lines
			last if $line =~ /^=======/;
			# print "adding $line";
			if($type =~ /note/i) {
				$clips{$title}{$location} .= '* ' .$line;
			} else {
				$clips{$title}{$location} .= '- ' .$line;
			}
		}
	}
}
foreach my $title (sort keys %clips) {
	#print "$title" . ('-' x (length($title) - 1)) . "\n";
	print $output_fh "$title" . ('-' x (length($title) - 1)) . "\n";
	foreach my $location (sort keys %{$clips{$title}}) {
		#print $clips{$title}{$location};
		print $output_fh $clips{$title}{$location};
	}
	#print "\n";
	print $output_fh "\n";
}
print "done -- see $OUTPUT_FILE\n";
exit;

# ------------------------------------------
sub skip_entry {
	while(1) {
		my $line = <$clips_fh>;
		last if $line =~ /^=======/;
	}
}