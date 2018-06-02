#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $username = "web";
my $password = "";
GetOptions ('username=s' => \$username, 'password' => \$password) or die "A valid --username needs to be specified and --password if required\n";
if ($password =~ /[0-9A-Ba-b]/) {
	$password = -p$password;
}
else {
	$password = "";
}
my @homologys = `echo 'SELECT CONCAT(Superdomain," ", Domain," ", Subdomain," ", Kingdom," ", Nine," ", Eight," ", Seven," ", Six," ", Five," ", Four," ", s.SpecCode) AS Heads, s.Homology  FROM specieslisted s, phylogeny p WHERE s.SpecCode=p.SpecCode;' | mysql -B -u$username $password ComparativeGenomics`;
shift @homologys;
my @columns = `echo 'SELECT CONCAT(Superdomain," ", Domain," ", Subdomain," ", Kingdom," ", Nine," ", Eight," ", Seven," ", Six," ", Five," ", Four," ", SpecCode) AS Heads FROM phylogeny;' | mysql -B -u$username -p$password ComparativeGenomics`;
shift @columns;
foreach my $column (@columns) {
	chomp $column;
}
my @largesthomolog = `echo 'SELECT Homology FROM homologycount ORDER BY Homology DESC LIMIT 1;' | mysql -B -u$username -p$password ComparativeGenomics`;
my $numhomo = $largesthomolog[-1];
chomp $numhomo;
my $head = join(",", @columns);
$head = "Homologs,$head";
chomp $head;
my %hash = ();
foreach my $element (@homologys) {
	chomp $element;
	$element =~ s/\t/,/g;
	$hash{$element}++;
}
my @newarray = ();
print $head, "\n";
foreach (my $i = 0; $i < $numhomo; $i++) {
	my $string = $i;
	foreach my $classification (@columns) {
		chomp $classification;
		if (exists $hash{"$classification,$i"}){
			$string .= ",".$hash{"$classification,$i"};
		}
		else {
			$string .= ",0";
		}
	}
	print $string,"\n";
}
exit;