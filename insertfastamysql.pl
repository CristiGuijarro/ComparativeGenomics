#!/usr/bin/perl -w
use strict;

my $fastafile = $ARGV[0];
chomp $fastafile;
my $allseqs = `grep '' $fastafile`;
sep_sequences($allseqs);
my %hash = ();
sub sep_sequences {
	my $seqs = $_[0];
	chomp $seqs;
	my @entries = split />/, $seqs;
	foreach my $entry (@entries) {
		chomp $entry;
		my($header, $seq) = split /\n/, $entry;
		my ($species, $rest) = split /_/, $header, 2;
		my @parts = split / /, $header;
		$header = $parts[0];
		$seq =~ s/[\n\r]//g;
		print "INSERT INTO sequences VALUES (\"$species\",\"$header\",\"$seq\");\n";
	}
}
exit;
