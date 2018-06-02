#!/usr/bin/perl -w
use strict;

#sudo python busco/scripts/run_BUSCO.py -i ProteomesBackup/hsap_prot.fasta -o buscoed -l eukaryota_odb9 -m proteins
my $dir = $ARGV[0];
chomp $dir;
my @genomes = `ls $dir/*_prot.fasta`;
foreach my $genome (@genomes) {
	chomp $genome;
	my $spec;
	if ($genome =~ /([A-Z0-9a-z]{4})_prot.fasta/) {
		$spec = $1;
	}
	system "cp $genome $genome.2.fasta";
	system "sed -i \"s/\\///g\" $genome.2.fasta";
	print "sed -i \"s/\\///g\" $genome.2.fasta\n";
	system "sed -i \"s/\\'//g\" $genome.2.fasta";
	print "sed -i \"s/\\'//g\" $genome.2.fasta\n";
	system "python busco/scripts/run_BUSCO.py -i $genome.2.fasta -o $spec-buscoed -l eukaryota_odb9 -m proteins -f";
	system "rm $genome.2.fasta";
}
exit;