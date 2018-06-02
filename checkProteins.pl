#!/usr/bin/perl -w
use strict;

unless (-d "ProteomesBackup") {
	mkdir "ProteomesBackup";
}
my @listoffiles = `ls Proteomes/*_prot.fasta`;
print "Checking proteome sizes...\n";
foreach my $file (@listoffiles) {
	chomp $file;
	my @headers = `grep '>' $file`;
	my $code = '';
	if ($file =~ /Proteomes\/(.*)_prot\.fasta/) {
		$code = $1;
	}
	print "$code - ", scalar(@headers), "\n";
}
print "Size Checks Complete\n\n";
foreach my $file (@listoffiles) {
	chomp $file;
	print "Checking $file...\n";
	open(OUTPUT, ">ProteomesBackup/$file");
	my $wholefile = `grep "" $file`;
	my @sequences = split /\n>/, $wholefile;
	foreach my $seq (@sequences) {
		my @lines = split /\n/, $seq;
		my $header = shift @lines;
		unless ($header =~ />/) {
			$header = ">".$header;
		}
		my $sequence = join("", @lines);
		chomp $sequence;
		if (length($sequence) < 10) {
			next;
		}
		print OUTPUT $header, "\n", $sequence, "\n";
	}
	print "Re-written $file\n";
	close OUTPUT;
}
exit;
