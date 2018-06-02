#!/usr/bin/perl -w
use strict;

my @fileist = `ls *_prot.fasta`;
unless (-d "Proteomes") {
	mkdir "Proteomes";
}
foreach my $file (@fileist) {
	chomp $file;
	my @paths = split /\//, $file;
	my $filename = $paths[-1];
	unless (-f "Proteomes/$filename") {
		print "cp $file Proteomes/\n";
		system "cp $file Proteomes/";
	}
}
exit;