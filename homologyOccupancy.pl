#!/usr/bin/perl -w
use strict;
use queryMySQL;
use Getopt::Long;
use List::MoreUtils qw/ uniq /;
use Array::Utils qw(:all);

my $cladeofinterest = 'Deuterostomia';
my $cladelevel = 'Subdomain';
GetOptions ('cladelevel=s' => \$cladelevel, 'cladename=s' => \$cladeofinterest) or die "A --cladelevel  and --cladename needs to be specified with uppercase first letter and the rest lowercase\n";

my ($higherclade,$higherhigherclade,$lowerclade) = phylogeny_collector($cladeofinterest,$cladelevel);
#if ($cladeofinterest eq "Porifera") {
#	$higherclade = "Kingdom";
#	$higherhigherclade = "Group";
#	$lowerclade = "Nine";
#}
#if ($cladeofinterest eq "Tardigrada") {
#	$lowerclade = "Genus";
#}
#if ($cladeofinterest eq "Urochordata") {
#	$lowerclade = "Class";
#}
#if ($cladeofinterest eq "Mollusca") {
#	$higherclade = "Four";
#	$higherhigherclade = "Five";
#	$lowerclade = "Class";
#}
#if ($cladeofinterest eq "Nematoda") {
#	$higherclade = "Six";
#	$higherhigherclade = "Seven";
#	$lowerclade = "Class";
#}
#if ($cladeofinterest eq "Annelida") {
#	$higherclade = "Three";
#	$higherhigherclade = "Four";
#	$lowerclade = "Class";
#}
#if ($cladeofinterest eq "Hemichordata") {
#	$higherclade = "Six";
#	$higherhigherclade = "Seven";
#	$lowerclade = "Order";
#}
#if ($cladeofinterest eq "Platyhelminthes") {
#	$higherclade = "Five";
#	$higherhigherclade = "Six";
#	$lowerclade = "Class";
#}
#if ($cladeofinterest eq "Ctenophora") {
#	$higherclade = "Ten";
#	$higherhigherclade = "Kingdom";
#	$lowerclade = "Order";
#}
my @strictgain = strict_gain("$cladeofinterest","$cladelevel","$lowerclade","$higherclade","$higherhigherclade");
my @strictloss = strict_loss("$cladeofinterest","$cladelevel","$lowerclade","$higherclade","$higherhigherclade");
my @strictancestral = strict_ancestral("$cladeofinterest","$cladelevel","$lowerclade","$higherclade","$higherhigherclade");
my @loosegain = loose_gain("$cladeofinterest","$cladelevel","$lowerclade","$higherclade","$higherhigherclade");
my @looseloss = loose_loss("$cladeofinterest","$cladelevel","$lowerclade","$higherclade","$higherhigherclade");
my @looseancestral = loose_ancestral("$cladeofinterest","$cladelevel","$lowerclade","$higherclade","$higherhigherclade");

my @strictgainunique = uniq @strictgain;
my @strictlossunique = uniq @strictloss;
my @strictancestralunique = uniq @strictancestral;
my @loosegainunique = uniq @loosegain;
my @looselossunique = uniq @looseloss;
my @looseancestralunique = uniq @looseancestral;

## Collect a list of GOs to tabulate

#my @strictgaingo = go_collector(@strictgain);
#my @strictlossgo = go_collector(@strictloss);
#my @strictancestralgo = go_collector(@looseancestral);
#my @loosegaingo = go_collector(@loosegain);
#my @looselossgo = go_collector(@looseloss);
#my @looseancestralgo = go_collector(@looseancestral);
#my %strictgaingo = ();
#foreach my $go (@strictgaingo) {
#	$strictgaingo{$go}++;
#}
#my $out = "$cladelevel.$cladeofinterest.strictGain.go.csv";
#open(OUT, ">$out");
#while (my ($keys, $values) = each %strictgaingo) {
#	print OUT "$keys,$values\n";
#}
#close OUT;
#my %strictlossgo = ();
#foreach my $go (@strictlossgo) {
#	$strictgaingo{$go}++;
#}
#my $out3 = "$cladelevel.$cladeofinterest.strictLoss.go.csv";
#open(OUT, ">$out3");
#while (my ($keys, $values) = each %strictlossgo) {
#	print OUT "$keys,$values\n";
#}
#close OUT;

## Need to ensure that each of the smaller arrays are present in the larger

my @intersectstrictgain = intersect( @strictgain, @loosegain );
if (scalar(@intersectstrictgain) < scalar(@strictgain)) {
	print "Strictgain has failed to be a subset of loosegain\n";
}
my @intersectstrictgain2 = intersect( @strictgain, @strictancestral );
if (scalar(@intersectstrictgain2) < scalar(@strictgain)) {
	print "Strictgain has failed to be a subset of strictancestral\n";
}
my @intersectancestral = intersect( @strictancestral, @looseancestral );
if (scalar(@intersectancestral) < scalar(@strictancestral)) {
	print "Strictancestral has failed to be a subset of looseancestral\n";
}
my @intersectloss = intersect( @strictloss, @looseloss );
if (scalar(@intersectloss) < scalar(@strictloss)) {
	print "Strictloss has failed to be a subset of looseloss\n";
}
my @intersectloosegain = intersect( @loosegain, @looseancestral);
if (scalar(@intersectloosegain) < scalar(@loosegain)) {
	print "Loosegain has failed to be a subset of looseancestral\n";
}
my $strictgain = "";
my $strictloss = "";
my $strictancestral = "";
my $loosegain = "";
my $looseancestral = "";
my $looseloss = "";
foreach my $sg (@strictgainunique) {
	chomp $sg;
	$strictgain .= `grep "^$sg," fullOccupancy.csv`;
}
foreach my $sl (@strictlossunique) {
	chomp $sl;
	$strictloss .= `grep "^$sl," fullOccupancy.csv`;
}
foreach my $sa (@strictancestralunique) {
	chomp $sa;
	$strictancestral .= `grep "^$sa," fullOccupancy.csv`;
}
foreach my $lg (@loosegainunique) {
	chomp $lg;
	$loosegain .= `grep "^$lg," fullOccupancy.csv`;
}
foreach my $ll (@looselossunique) {
	chomp $ll;
	$looseloss .= `grep "^$ll," fullOccupancy.csv`;
}
foreach my $la (@looseancestralunique) {
	chomp $la;
	$looseancestral .= `grep "^$la," fullOccupancy.csv`;
}
my $out2 = "$cladelevel.$cladeofinterest.occupancy.csv";
if (open(OUT, ">$out2")) {
	print OUT `head -n 1 fullOccupancy.csv\n`;
	print OUT "StrictGain\n$strictgain\n";
	print OUT "StrictLoss\n$strictloss\n";
	print OUT "StrictAncestal\n$strictancestral\n";
	print OUT "LooseGain\n$loosegain\n";
	print OUT "LooseLoss\n$looseloss\n";
	print OUT "LooseAncestral\n$looseancestral\n";
}
my $strictgainnum = scalar(@strictgain);
my $strictlossnum = scalar(@strictloss);
my $strictancestralnum = scalar(@strictancestral);
my $loosegainnum = scalar(@loosegain);
my $looselossnum = scalar(@looseloss);
my $looseancestralnum = scalar(@looseancestral);
print "INSERT INTO lossGainAncestral VALUES (\"$cladelevel\", \"$cladeofinterest\", ($strictgainnum), ($strictlossnum), ($strictancestralnum) , ($loosegainnum), ($looselossnum), ($looseancestralnum));\n";
my $insertstatement = "INSERT INTO lossGainAncestral VALUES (\"$cladelevel\", \"$cladeofinterest\", ($strictgainnum), ($strictlossnum), ($strictancestralnum) , ($loosegainnum), ($looselossnum), ($looseancestralnum));\n";
#system "echo \"\n$insertstatement\n\" | mailx -v -r \"#######\" -s \"$cladelevel $cladeofinterest\" -S smtp=\"smtp-mail.outlook.com:587\" -S smtp-use-starttls -S smtp-auth=login -S smtp-auth-user=\"######\" -S smtp-auth-password=\"######\" -S ssl-verify-ignore -a /$out2 ######";

exit;