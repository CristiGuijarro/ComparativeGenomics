#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $MCLfile = "";
my $password = "";
my $username = "";
GetOptions ('mclfile=s' => \$MCLfile, 'username=s' => \$username, 'password' => \$password) or die "A --mclfile, --username and --password needs to be specified\n";

my @clusterings = collect_clusters($MCLfile);
my ($homologycount, $genescollected, $specieslisted) = collect_homology(@clusterings);
insert_mysql_homologycount(%$homologycount);
insert_mysql_genes(%$genescollected);
insert_mysql_species(%$specieslisted);

sub collect_clusters {
	$MCLfile = shift;
	open(MCLIN, "<$MCLfile") or die "\nCould not access the MCL file: $MCLfile\n\n";
	chomp (my @lines = <MCLIN>);
	close MCLIN;
	return @lines;
}
sub collect_homology {
	#sub for collecting number of gene homologies for each species in 3 seperate hashes for objects
	my @clusters = @_;
	my %counthomology = ();
	my %collectedgenes = ();
	my %listedspecies = ();
	my $count = 0;
	foreach my $homology (@clusters) {
		my @proteins = split /\t/, $homology;
		my $group = $proteins[0];
		$counthomology{$count} = scalar @proteins;
		$collectedgenes{$count} = join("\t", @proteins);
		my @specs;
		foreach my $prot (@proteins) {
			my ($spec, $protein) = split /_/, $prot;
			push @specs, $spec;
		}
		$listedspecies{$count} = join("\t",@specs); 
		$count++;
	}
	return (\%counthomology, \%collectedgenes, \%listedspecies);
}
sub insert_mysql_homologycount {
	#Sub for inputting each of the homologies with counted genes
	my %hash = @_;
	open (OUT, ">out3.txt");
	while (my($keys, $values) = each %hash) {
		chomp $keys; chomp $values;
		print OUT "$keys\t$values\n";
	}
	close OUT;
	print "mysql -u$username -p$password ComparativeGenomics -e 'LOAD DATA LOCAL INFILE \"out3.txt\" INTO TABLE homologycount FIELDS TERMINATED BY \'\t\' OPTIONALLY ENCLOSED BY \'\"\' ESCAPED BY \'\"\' LINES TERMINATED BY \'\\n\'' &\n";
	#system "mysql -u$username -p$password ComparativeGenomics -e 'LOAD DATA LOCAL INFILE \"out3.txt\" INTO TABLE homologycount FIELDS TERMINATED BY \'\t\' OPTIONALLY ENCLOSED BY \'\"\' ESCAPED BY \'\"\' LINES TERMINATED BY \'\n\'' &";
}
sub insert_mysql_genes {
	#Sub for inputting each of the genes with protein list
	my %hash = @_;
	open(OUT, ">out.txt");
	while (my($keys, $values) = each %hash) {
		chomp $keys; chomp $values;
		my @values = split /\t/, $values;
		foreach my $genes (@values) {
			print OUT "$keys\t$genes\n";
		}
		
	}
	close OUT;
	#system "mysql -u$username -p$password ComparativeGenomics -e 'LOAD DATA LOCAL INFILE \"out.txt\" INTO TABLE genescollected FIELDS TERMINATED BY \'\t\' OPTIONALLY ENCLOSED BY \'\"\' ESCAPED BY \'\"\' LINES TERMINATED BY \'\n\'' &";
	print "mysql -u$username -p$password ComparativeGenomics -e 'LOAD DATA LOCAL INFILE \"out.txt\" INTO TABLE genescollected FIELDS TERMINATED BY \'\t\' OPTIONALLY ENCLOSED BY \'\"\' ESCAPED BY \'\"\' LINES TERMINATED BY \'\\n\'' &\n";
}
sub insert_mysql_species {
	#Sub for inputting most important data for gene loss and gain
	my %hash = @_;
	open(OUT, ">out2.txt");
	while (my($keys, $values) = each %hash) {
		chomp $keys; chomp $values;
		my @values = split /\t/, $values;
		
		foreach my $species (@values) {
			chomp $species;
			if (length($species) != 4) {
				next;
			}
			print OUT "$keys\t$species\n";
		}
	}
	close OUT;
	#system "mysql -u$username -p$password ComparativeGenomics -e 'LOAD DATA LOCAL INFILE \"out2.txt\" INTO TABLE specieslisted FIELDS TERMINATED BY \'\t\' OPTIONALLY ENCLOSED BY \'\"\' ESCAPED BY \'\"\' LINES TERMINATED BY \'\n\'' &";
	print "mysql -u$username -p$password ComparativeGenomics -e 'LOAD DATA LOCAL INFILE \"out2.txt\" INTO TABLE specieslisted FIELDS TERMINATED BY \'\t\' OPTIONALLY ENCLOSED BY \'\"\' ESCAPED BY \'\"\' LINES TERMINATED BY \'\\n\'' &\n";
}
# Listed species should generate the list of species in each homology group - this to determine the gene loss and gain - once the taxonomy is uploaded into the database
# Count homology provides the number of proteins in each homology group
# Collected genes provides a list of the proteins in each homology group