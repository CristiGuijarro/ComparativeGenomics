#!/usr/bin/perl -w
use strict;
use lib '/home/cristig/Desktop/ComparativeGenomicsP1';
use queryMySQL;
use Getopt::Long;
use List::MoreUtils qw/ uniq /;
use Array::Utils qw(:all);
use Try::Tiny;

my $cladename = 'Echinodermata';
my $hglevel = "Novel";
my $organism = "purpuratus";
my $occ = '/home/cristig/Desktop/ComparativeGenomics/OccupancyTables/Kingdom.Metazoa.occupancy.csv';
GetOptions ('cladename=s' => \$cladename, 'hglevel=s' => \$hglevel, 'csvfile=s' => \$occ, 'organism=s' => \$organism) or die "A --cladename, --hglevel (Novel, Lost or Ancestral) --organism and --csvfile needs to be supplied\n";
my @lines = ();
if ($hglevel eq "Novel") {
	@lines = `sed -n -e '/StrictGain/,/StrictLoss/ p' $occ | grep -v 'Strict'`;
}
#if ($hglevel eq "Novel") {
#	@lines = `sed -n -e '/LooseGain/,/LooseLoss/ p' $occ | grep -v 'Loose'`;
#}
#if ($hglevel eq "Lost") {
#	@lines = `sed -n -e '/StrictLoss/,/StrictAncestal/ p' $occ | grep -v 'Strict'`;
#}
if ($hglevel eq "Lost") {
	@lines = `sed -n -e '/LooseLoss/,/LooseAncestal/ p' $occ | grep -v 'Strict'`;
}
if ($hglevel eq "Ancestral") {
	@lines = `sed -n -e '/StrictAncestal/,/LooseGain/ p' $occ | grep -v 'Strict' | grep -v 'Loose'`;
}
pop @lines;
$cladename = ucfirst $cladename;
my $cols = `head -n 1 $occ`;
my @cols = split /,/, $cols;
my %sg = ();
foreach (my $i = 1; $i<@cols; $i++) {
	chomp $cols[$i];
	my @clades = split / /, $cols[$i];
	my $kingdom = $clades[0];
	my $spec = $clades[-1];
	if ($cols[$i] =~ /$cladename/) {
		$cols[$i] = "$cladename,$spec";
	}
	else {
		$cols[$i] = "Ignore,$spec";
	}
}
my %sg2 = ();
print "Gene Descriptives based on $organism\n";
print "HG,cellular_component,biological_process,molecular_function,protein,protein_ID,count\n";
foreach my $sg (@lines) {
	chomp $sg;
	my $string = classify_count($organism."_$sg",\@cols);
	my @string = split /\n/, $string;
	foreach my $st (@string) {
		my $group = "-";
		my $species = "-";
		my $hg = "-";
		my $cc = "-";
		my $bp = "-";
		my $mf = "-";
		my $protein = "-";
		my $symbol = "-";
		($group,$species,$hg,$cc,$bp,$mf,$protein,$symbol,my $sum) = split /,/, $st;
		#print "Group:$group,Species:$species,HG:$hg,CC:$cc,BP:$bp,MF:$mf,Protein:$protein,Symbol:$symbol=Sum:$sum\n";
		unless ($sum !~ /[A-Z]/) {
			print "Group:$group,Species:$species,HG:$hg,CC:$cc,BP:$bp,MF:$mf,Protein:$protein,Symbol:$symbol=Sum:$sum\n";
		}
		$sg{"$hg,$cc,$bp,$mf,$protein,$symbol"} += $sum;
	}
}
foreach my $keys(sort keys %sg) {
	print "$keys,",$sg{$keys}, "\n";
}

#########################################################################################################################################################

sub classify_count {
	my $sg = $_[0];
	my @cols = @{$_[1]};
	my %homologies = ();
	my @parts = split /,/, $sg;
	my $organism;
	my $hg = shift @parts;
	($organism, $hg) = split /\_/, $hg;
	chomp $hg;
	chomp $organism;
	my $go = `echo 'SELECT DISTINCT GO FROM geneontology WHERE Homology=$hg AND GO LIKE \"%GO:%\" AND Organism LIKE \"%$organism%\" ORDER BY LENGTH(GO) DESC LIMIT 1' | mysql -B -uweb ComparativeGenomics | tail -n+2`;
	my $proteinclass = protein_class($hg,$organism);
	#print $proteinclass, "\n";
	my ($class,$symbol) = split /,/, $proteinclass;
	my @goto = ();
	my %goto = ();
	$go =~ s/\n\n//g;
	if ($go =~ /;/) {
		@goto = split /;/, $go;
	}
	else {
		push @goto, $go;
	}
	my @ccs = ();
	my @mfs = ();
	my @bps = ();
	foreach my $goto (@goto) {
		$goto =~ s/^ //;
		$goto = ucfirst $goto;
		if ($goto =~ / \[(GO\:[0-9]+)\]/) {
			$goto = $1;
		}
		if ($goto =~ / (GO\:[0-9]+)/) {
			$goto = $1;
		}
		my $gotype = go_type($goto);
		my $goname = go_name($goto);
		chomp $gotype;
		chomp $goname;
		$goto = "$gotype $goname \[$goto\]";
		chomp $goto;
		if ($gotype =~ /biological/) {
				$goto =~ s/biological_process//;
				push @bps, $goto;
			}
			elsif ($gotype =~ /molecular/) {
				$goto =~ s/molecular_function//;
				push @mfs, $goto;
			}
			elsif ($gotype =~ /cellular/) {
				$goto =~ s/cellular_component//;
				push @ccs, $goto;
		}
	}
	my $cc = "-";
	my $bp = "-";
	my $mf = "-";
	unless (scalar(@ccs) < 1) {
		$cc = join(";",@ccs);
	}
	unless (scalar(@bps) < 1) {
		$bp = join(";",@bps);
	}
	unless (scalar(@mfs) < 1) {
		$mf = join(";",@mfs);
	}
	foreach (my $i = 1; $i<@parts; $i++) {
		chomp $parts[$i];
		$parts[$i]+=$parts[$i];
		$hg =~ s/,/-/g;
		$cc =~ s/,/-/g;
		$bp =~ s/,/-/g;
		$mf =~ s/,/-/g;
		$class =~ s/,/-/g;
		$symbol =~ s/,/-/g;
		$homologies{"$cols[$i],$hg,$cc,$bp,$mf,$class,$symbol"}=$parts[$i];
	}
	my $string = "";
	foreach my $classified (sort keys %homologies) {
		unless ($classified =~ /Ignore/ || $classified =~ /Homolog/ || $classified =~ /,,,,,/) {
			$string .= "$classified,".$homologies{$classified}."\n";
		}
	}
	return $string;
}
sub go_type {
	my $go = $_[0];
	my $gotype = `curl -s http://amigo.geneontology.org/amigo/term/$go | grep -A1 '<dt>Ontology</dt>' | grep -v 'Ontology' | sed 's/[<d>\/ ]//g'`;
	return $gotype;
}
sub go_name {
	my $go = $_[0];
	my $goname = `curl -s http://amigo.geneontology.org/amigo/term/$go | grep -A1 '<dt>Name</dt>' | grep -v 'Name'`;
	if ($goname =~ /<dd>(.+)<\/dd>/) {
		$goname = $1;
	}
	if ($goname =~ /(^[A-Za-z \- \(\)\']+), .+/) {
		$goname = $1;
	}
	$goname = ucfirst $goname;
	return $goname;
}
sub protein_class {
	my $go = $_[0];
	my $organism = $_[1];
	my @goid = `echo 'SELECT DISTINCT ID FROM geneontology WHERE Homology=$go AND Organism LIKE \"%$organism%\" LIMIT 5;' | mysql -B -uweb ComparativeGenomics | tail -n+2`;
	my @proteinclass;
	foreach my $goid (@goid) {
		chomp $goid;
		eval { 
			local $SIG{ALRM} = sub { die "" };
			alarm 3;
			eval { 
				my $proteinclass = `curl -s http://amigo.geneontology.org/amigo/gene_product/UniProtKB:$goid | grep -A2 '<dt>Name(s)</dt>' | tail -n 1`;
				if ($proteinclass =~ /<dd>([A-Z].+)<\/dd>/) {
					$proteinclass = $1;
					chomp $proteinclass;
					push @proteinclass,$proteinclass;
				}
				#else {
				#	$proteinclass = `curl -s https://www.uniprot.org/uniprot/$goid | grep 'Submitted name'`;
				#	if ($proteinclass =~ />\Submitted name: \<h1 property="schema:name"\>([A-Za-z0-9 ]+)\<\/h1\>/) {
				#		$proteinclass = $1;
				#		chomp $proteinclass;
				#		push @proteinclass,$proteinclass;
				#	}
				#}
			};
			alarm 0;
		};
		alarm 0;
		die if $@ && $@ !~ /alarm clock restart/;
	}
	my $goids = "-";
	my $proteinclass = "-";
	unless (scalar(@goid)<1) {
		$goids = join(";",@goid);
	}
	unless (scalar(@proteinclass)<1) {
		$proteinclass = join(";",@proteinclass);
	}
	$proteinclass =~ s/,/-/g;
	$proteinclass =~ s/\n//g;
	$goids =~ s/,/-/g;
	my $string = "$proteinclass,$goids";
	$string =~ s/NULL/-/g;
	return $string;
}
exit;