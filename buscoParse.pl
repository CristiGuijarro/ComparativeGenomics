#!/usr/bin/perl -w
use strict;

my @buscodirs = `find ./ -type d -name "run_*-buscoed" | sed -e "s/\\.\\///g"`;
foreach my $buscodir (@buscodirs) {
	chomp $buscodir;
	my $file = $buscodir;
	$file =~ s/run_//g;
	$file = "short_summary_$file.txt";
	my $filepath = "$buscodir/$file";
	my $percentages = `grep "\tC:" $filepath`;
	chomp $percentages;
	my $Complete;
	my $Single;
	my $duplicates;
	my $fragments;
	my $missing;
	my $total;
	if ($percentages =~ /\tC\:(.*)\%\[S\:(.*)\%,D\:(.*)\%\],F\:(.*)\%,M\:(.*)\%,n\:(303)/) {
		$Complete = $1;
		$Single = $2;
		$duplicates = $3;
		$fragments = $4;
		$missing = $5;
		$total = $6;
	}
	my $spec;
	if ($buscodir =~ /run_(.*)-buscoed/) {
		$spec = $1;
	}
	print "$spec,$Complete,$Single,$duplicates,$fragments,$missing,$total\n";
}
exit;