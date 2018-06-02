#!/usr/bin/perl -w
use strict;
use Try::Tiny;

my $listfile = $ARGV[0];
chomp $listfile;
my @species = `grep "_" $listfile`;
open(SPECLIST, ">missingSpecies2.txt");
foreach my $species (@species) {
	chomp $species;
	my @specode = split /_/, $species; 
    ### Get the first letter code for ease later on and name file and header with this.
    my $specodeA = substr $specode[0], 0, 1;
    my $specodeB = substr $specode[1], 0, 3;
    my $specode = $specodeA.$specodeB;
    $specode =~ tr/[A-Z]/[a-z]/;
    my $filename = "$specode"."_prot.fasta";
	unless ( open ( OUTPUT, ">$filename" ) ){
        print "Cannot create output file $specode\_prot.fasta\n\n";
        next;
    }
	$species =~ s/_/%20/;
	try {
		### Send the fasta file to variable
		my $fastafile = `wget -qO- 'http://www.uniprot.org/uniprot/?query=organism:$species&format=fasta&include=no'`;
		#print "wget -qO- 'http://www.uniprot.org/uniprot/?query=organism:$species\&format=fasta&include=no'\n";
		$fastafile =~ s/ | /_/g;
		$specode = ">".$specode;
		$fastafile =~ s/^>/$specode/ge;
		my @fastas = split />/, $fastafile;
		foreach my $fastas (@fastas) {
			chomp $fastas;
			if (length($fastas) < 1) {
				next;
			}
			my @lines = split /\n/, $fastas;
			my $header = shift @lines;
			$header = $specode."_".$header;
			my $sequence = join("", @lines);
			print OUTPUT "$header\n$sequence\n";
		}
		#print $fastafile;
		#print $fastafile, "\n";
	}
	catch {
		print SPECLIST $species, "\n";
        system "rm $filename";
	}
}
exit;