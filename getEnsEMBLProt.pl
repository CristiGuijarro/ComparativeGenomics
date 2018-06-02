#!/usr/bin/perl -w
use strict;
use Bio::EnsEMBL::Registry;
use Try::Tiny;
use lib "$ENV{HOME}/src/bioperl-1.6.1";
use lib "$ENV{HOME}/src/ensembl/modules";
use lib "$ENV{HOME}/src/ensembl-compara/modules";
use lib "$ENV{HOME}/src/ensembl-variation/modules";
use lib "$ENV{HOME}/src/ensembl-funcgen/modules";
### Put in aliases into the species names for common names. Search by these common names whilst using the details of the non common name.
### If a file does not exist need to search for it using this common name.

my $speciesfile = $ARGV[0];
### Takes a unix newline seperated list of species with genus_species being the name.
### This will be adapted to include alias names to search for in the event that it is not found the first time round.
chomp $speciesfile;
my @species = `grep "_" $speciesfile`;
open(SPECLIST, ">missingSpecies.txt");
foreach my $species (@species) {
    chomp $species;
    my $registry = "Bio::EnsEMBL::Registry";
    $registry -> load_registry_from_db(
      -host    => 'ensembldb.ensembl.org',
      -user    => 'anonymous',
      -verbose => '1'
    );
    my @specode = split /_/, $species;
    ### Get the first letter code for ease later on and name file and header with this.
    my $specodeA = substr $specode[0], 0, 1;
    my $specodeB = substr $specode[1], 0, 3;
    my $specode = $specodeA.$specodeB;
    $specode =~ tr/[A-Z]/[a-z]/;
    my $filename = "$specode"."_prot.fasta";
    ### This is the output fasta file for all of the protein sequences listed under this genome.
    unless ( open ( OUTPUT, ">$filename" ) ){
        print "Cannot create output file $specode\_prot.fasta\n\n";
        next;
    }
    ### Try catch in place where the API exits program with errors if species is not recognisable.
    try {
        my $geneadaptor = $registry -> get_adaptor( $species, 'Core', 'Gene' );
        my @geneids= @{$geneadaptor->list_stable_ids()};
        while (my $geneid = shift @geneids){
            my $gene = $geneadaptor->fetch_by_stable_id($geneid);
            my $genename = "Unknown";
            ### geneid prodces the protein/gene identity code, so to get the common gene name below.
            if ($gene->external_name()) {
                $genename = $gene->external_name();
            }
            my $transcript=$gene->canonical_transcript();
            my $protein= $transcript->translate();
            ### Protein sequence is retrieved from the EnsEMBLE database and output with formatted header to fatsa file.
            if (defined $protein){
                print OUTPUT ">$specode","_$genename","_$geneid\n",$protein->seq(),"\n";
            }
        }
        close(OUTPUT);
    }
    catch {
        ### For all the species not found in EnsEMBL, listed here to retrieve elsewhere.
        print SPECLIST $species, "\n";
        system "rm $filename";
    }
}
close(SPECLIST);
exit;