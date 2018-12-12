#!/usr/bin/perl -w
use strict;
use List::MoreUtils qw(uniq);;
my $file = $ARGV[0];
chomp $file;
my @entries = `grep -v "Homology\tHeader" $file`;
my $dbtype = "";
#my %homologies = ();
my @homologies = ();
my %homologies = ();
my @entries2 = ();
foreach my $entry (@entries) {
	chomp $entry;
	my ($homology,$header) = split /\t/, $entry;
	#$homologies{$homology}++;
	#push @homologies, $homology;
	my $uniqueid;
	my $speccode;
	#if (length($header) < 52) {
	#	if ($header =~ /([a-z1-9]{4})_.*_([A-Za-z0-9]+)/) {#ensembl
	#		$speccode = $1;
	#		$uniqueid = $2;
	#		$dbtype = "ensembl";
	#	}
	#}
	#if (length($header) < 52) {
	if ($header =~ /([a-z1-9]{4})_(.*)_([A-Za-z0-9]+)/) {#ensembl
		$speccode = $1;
		$uniqueid = $2;
		$dbtype = "uniprot";
	}
	elsif ($header =~ /([a-z1-9]{4})_(.*)/) {
		$speccode = $1;
		$uniqueid = $2;
		$dbtype = "nothing";
	}
	#if ($header =~ /Unknown/ || $header =~ /hypothetical/) {
	#	$speccode = 0;
	#	$uniqueid = 0;
	#	#$dbtype = "nothing";
	#}
	#if ($header =~ /([a-z0-9]{4})_(RvY_[0-9]{5})_RvY_[0-9]+/) {
	#	$speccode = $1;
	#	$uniqueid = $2;
	#	$dbtype = "uniprot";
	#}
	else {
		$speccode = 0;
		$uniqueid = 0;
	}
	#elsif ($header =~ /([a-z1-9]+).*_[sptr]{2}\|(.*)\|/) {#uniprot
	#	$speccode = $1;
	#	$uniqueid = $2;
	#	$dbtype = "uniprot";
	#}
	my $line = `grep "$speccode" phylogenyTable.csv`;
	my @parts = ();
	my $species = "";
	if ($line) {
		@parts = split /,/, $line;
		$species = $parts[0];
	}
	$species =~ s/ /_/g;
	if ($uniqueid) {
		$homologies{"$homology.$species"}++;
	}
	$entry = "$homology\t$uniqueid\t$dbtype\t$species";
	if ($entry =~ /Uncharacterized/ ) {
		$entry = "0\t0\t0\t0";
	}
	#if ($homology < 1686) {
	#	next;
	#}
	#else {
	#	unless ($homologies{"$homology.$species"} > 1) {
	#		push @entries2, $entry;
	#	}
	#}
	#print $entry, "\n";
}
#while (my($keys, $values)=%homologies) {
#	print "$keys,$values";
#}
#my @unique = uniq @homologies;
#print scalar(@unique), "\n";
#exit;
my @uniprot;
my %check = ();
foreach my $entry (@entries) {
	chomp $entry;
	my ($homology,$header,$dbtype,$species) = split /\t/, $entry;
	unless (exists $check{$homology}) {
		if ($dbtype eq "uniprot") {
			#my @line = `curl -s 'https://www.uniprot.org/uniprot/?query=$header&&columns=id,organism,families,features,domains,domain,genes,go,go-id&&format=tab'`;
			my @line = `curl -s 'https://www.uniprot.org/uniprot/?query=$header&&reviewed:yes&&organism:33208&&database=pdb&&columns=id,organism,families,features,domains,domain,genes,go,go-id&&format=tab&limit=50&&sort=score'`;
			my $columns = shift @line;
			foreach my $lines (@line) {
				chomp $lines;
				$lines =~ s/\t\t/\tNULL\t/g;
				unless ($lines=~/\tNULL\tNULL\tNULL\tNULL\tNULL/) {
					push @uniprot, "$homology\t$lines";
					print "$homology\t$lines\n";
					$check{$homology}++;
				}
			}
		}
		else {
			next;
		}
	}
}
#print join("\n",@uniprot);