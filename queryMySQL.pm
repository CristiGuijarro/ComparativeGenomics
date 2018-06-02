#!/usr/bin/perl -w
use strict;
use List::MoreUtils qw/ uniq /;
use Array::Utils qw(:all);
sub phylogeny_collector {
	my $cladename = $_[0];
	my $clade = $_[1];
	my @hierarchy = qw (
		Superdomain
		Domain
		Subdomain
		Group
		Kingdom
		Ten
		Nine
		Eight
		Seven
		Six
		Five
		Four
		Three
		Two
		One
		Class
		Order
	);
	my $cladeindice = 0;
	foreach (my $i = 0; $i < @hierarchy; $i++) {
		chomp $hierarchy[$i];
		chomp $clade;
		if ($hierarchy[$i] eq $clade) {
			$cladeindice = $i;
		}
		else {
		}
	}
	my $higherclade = $hierarchy[$cladeindice-1];
	my $higherhigherclade = $hierarchy[$cladeindice-2];
	my $lowerclade = $hierarchy[$cladeindice+1];
	
	my @cladelist = `echo 'SELECT DISTINCT \`$higherclade\` FROM phylogeny;' | mysql -B -uweb ComparativeGenomics`;
	foreach my $cladelist (@cladelist) {
		if ($cladelist eq $cladename) {
			$higherclade = $hierarchy[$cladeindice-2];
			$higherhigherclade = $hierarchy[$cladeindice-3];
			next;
		}
	}
	@cladelist = `echo 'SELECT DISTINCT \`$lowerclade\` FROM phylogeny;' | mysql -B -uweb ComparativeGenomics`;
	foreach my $cladelist (@cladelist) {
		if ($cladelist eq $cladename) {
			$lowerclade = $hierarchy[$cladeindice+2];
			next;
		}
	}
	return ($higherclade, $higherhigherclade, $lowerclade);
}
sub strict_gain {
	my $clade = $_[0];
	my $cladename = $_[1];
	my $lowerclade = $_[2];
	my $higherclade = $_[3];
	my $higherhigherclade = $_[4];
	chomp $clade;
	chomp $higherclade;
	chomp $cladename;
	my $query1 = "SELECT DISTINCT `$lowerclade` FROM phylogeny WHERE `$cladename`=\"$clade\"";
	my $query2 = "SELECT DISTINCT Homology, COUNT(DISTINCT `$lowerclade`) AS Counted FROM specieslisted s, phylogeny l WHERE s.SpecCode=l.SpecCode AND `$cladename`=\"$clade\" GROUP BY Homology";
	my $query3 = "SELECT DISTINCT Homology FROM specieslisted s, phylogeny l WHERE s.SpecCode=l.SpecCode AND NOT `$cladename`=\"$clade\"";
	my $query4 = "SELECT DISTINCT Homology, COUNT(DISTINCT s.SpecCode) AS Counted FROM specieslisted s, phylogeny l WHERE s.SpecCode=l.SpecCode AND `$cladename`=\"$clade\" GROUP BY Homology";
	my $query5 = "SELECT DISTINCT SpecCode FROM phylogeny WHERE `$cladename`=\"$clade\"";
	my @lowercladelist = `echo '$query1' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @lowercladelist;
	my @homologyCounter = `echo '$query2' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homologyCounter;
	my @notin = `echo '$query3' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @notin;
	my @speccodelist = `echo '$query4' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @speccodelist;
	my @speccount = `echo '$query5' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @speccount;
	my @filter1;
	my @filter2;
	foreach my $homo (@homologyCounter) {
		chomp $homo;
		my ($homolog,$lower) = split /\t/, $homo;
		if ($lower == scalar(@lowercladelist)) {
			push @filter1, $homolog;
		}
	}
	foreach my $homo (@speccodelist) {
		chomp $homo;
		my ($homolog,$specs) = split /\t/, $homo;
		my $allowance = 0;
		if (scalar(@speccount) < 4) {
			$allowance = 0;
		}
		elsif (scalar(@speccount) > 3 && scalar(@speccount) < 6) {
			$allowance = 1;
		}
		elsif (scalar(@speccount) > 5 && scalar(@speccount) < 9) {
			$allowance = 2;
		}
		elsif (scalar(@speccount) > 8) {
			$allowance = 3;
		}
		if ($specs >= (scalar(@speccount)-$allowance) && $specs > 0) {
			push @filter2, $homolog;
		}
	}
	foreach my $homo (@notin) {
		chomp $homo;
	}
	
	my @filter3 = intersect(@filter1, @filter2);
	my @filter4 = array_minus(@filter3, @notin);
	my @homologies = @filter4;
	return @homologies;
}
sub strict_loss {
	my $clade = $_[0];
	my $cladename = $_[1];
	my $lowerclade = $_[2];
	my $higherclade = $_[3];
	my $higherhigherclade = $_[4];
	chomp $clade;
	chomp $cladename;
	chomp $lowerclade;
	chomp $higherclade;
	my $highercladename = `echo 'SELECT DISTINCT \`$higherclade\` FROM phylogeny WHERE \`$cladename\`="$clade"' | mysql -B -uweb ComparativeGenomics \n\n`;
	my ($goup,$higher) = split /\n/, $highercladename;
	$highercladename = $higher;
	chomp $highercladename;
	my $speccode = "SELECT COUNT(DISTINCT SpecCode) FROM phylogeny p WHERE `$higherclade`=\"$highercladename\" AND NOT `$cladename`=\"$clade\"";
	my $speccounted = `echo '$speccode' | mysql -B -uweb ComparativeGenomics \n\n`;
	my ($title, $speccount) = split /\n/, $speccounted;
	chomp $speccount;
	my $allowance = 0;
	if ($speccount < 4) {
		$allowance = 0;
	}
	elsif ($speccount > 3 && $speccount < 6) {
		$allowance = 1;
	}
	elsif ($speccount > 5 && $speccount < 9) {
		$allowance = 2;
	}
	elsif ($speccount > 8) {
		$allowance = 3;
	}
	my $query1 = "SELECT DISTINCT Homology FROM (SELECT DISTINCT Homology, COUNT(DISTINCT s.SpecCode) AS Counted FROM phylogeny p, specieslisted s WHERE p.SpecCode=s.SpecCode AND `$higherclade`=\"$highercladename\" AND NOT `$cladename`=\"$clade\" GROUP BY Homology) t1 WHERE t1.Counted>=($speccount-$allowance)";
	my $query2 = "SELECT DISTINCT Homology FROM specieslisted s, phylogeny p WHERE s.SpecCode=p.SpecCode AND `$cladename`=\"$clade\"";
	my $query3 = "SELECT DISTINCT Homology FROM specieslisted s, phylogeny p WHERE s.SpecCode=p.SpecCode AND NOT `$higherclade`=\"$highercladename\"";
	my @homology1 = `echo '$query1' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology1;
	my @homology2 = `echo '$query2' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology2;
	my @homology3 = `echo '$query3' | mysql -B -uweb ComparativeGenomics \n\n `;
	shift @homology3;
	my @strict = intersect(@homology1, @homology3);
	my @homologies = array_minus(@strict, @homology2);
	return @homologies;
}
sub strict_ancestral {
	my $clade = $_[0];
	my $cladename = $_[1];
	my $lowerclade = $_[2];
	my $higherclade = $_[3];
	my $higherhigherclade = $_[4];
	chomp $clade;
	chomp $higherclade;
	chomp $cladename;
	chomp $lowerclade;
	my $query1 = "SELECT DISTINCT Homology, COUNT(DISTINCT s.SpecCode) AS Counted FROM specieslisted s, phylogeny l WHERE s.SpecCode=l.SpecCode AND `$cladename`=\"$clade\" GROUP BY Homology";
	my $query2 = "SELECT DISTINCT SpecCode FROM phylogeny WHERE `$cladename`=\"$clade\"";
	my $query3 = "SELECT DISTINCT `$lowerclade` FROM phylogeny WHERE `$cladename`=\"$clade\"";
	my $query4 = "SELECT DISTINCT s.Homology, COUNT(DISTINCT `$lowerclade`) AS Counted FROM specieslisted s, phylogeny l, homologycount h WHERE s.SpecCode=l.SpecCode AND s.Homology=h.Homology AND `$cladename`=\"$clade\" GROUP BY Homology";
	my @homology1 = `echo '$query1' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology1;
	my @homology2 = `echo '$query2' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology2;
	my @homology3 = `echo '$query3' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology3;
	my @homology4 = `echo '$query4' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology4;
	my @filter1;
	my @filter2;
	foreach my $homo (@homology1) {
		chomp $homo;
		my ($homolog,$speccode) = split /\t/, $homo;
		my $allowance = 0;
		if (scalar(@homology2) < 4) {
			$allowance = 0;
		}
		elsif (scalar(@homology2) > 3 && scalar(@homology2) < 6) {
			$allowance = 1;
		}
		elsif (scalar(@homology2) > 5 && scalar(@homology2) < 9) {
			$allowance = 2;
		}
		elsif (scalar(@homology2) > 8) {
			$allowance = 3;
		}
		if ($speccode >= (scalar(@homology2)-$allowance) && $speccode > 0) {
			push @filter1, $homolog;
		}
	}
	foreach my $homo (@homology4) {
		chomp $homo;
		my ($homolog,$lower) = split /\t/, $homo;
			if (scalar(@homology3) > 1) {
				if ($lower > 1 && $lower > (scalar(@homology3)-1)) {
					push @filter2, $homolog;
				}
			}
			elsif ($lower==scalar(@homology3)) {
				push @filter2, $homolog;
			}
	}
	my @homologies = intersect(@filter1,@filter2);
	return @homologies;
}
sub loose_gain {
	my $clade = $_[0];
	my $cladename = $_[1];
	my $lowerclade = $_[2];
	my $higherclade = $_[3];
	my $higherhigherclade = $_[4];
	chomp $clade;
	chomp $higherclade;
	chomp $cladename;
	chomp $lowerclade;
	my $query1 = "SELECT DISTINCT `$lowerclade` FROM phylogeny WHERE `$cladename`=\"$clade\"";
	my $query2 = "SELECT DISTINCT Homology, COUNT(DISTINCT `$lowerclade`) AS Counted FROM specieslisted s, phylogeny l WHERE s.SpecCode=l.SpecCode AND `$cladename`=\"$clade\" GROUP BY Homology";
	my $query3 = "SELECT DISTINCT Homology FROM specieslisted s, phylogeny l WHERE s.SpecCode=l.SpecCode AND NOT `$cladename`=\"$clade\"";
	my @homology1 = `echo '$query1' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology1;
	my @homology2 = `echo '$query2' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology2;
	my @homology3 = `echo '$query3' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology3;
	my @filter1;
	foreach my $homo (@homology2) {
		chomp $homo;
		my ($homolog,$lower) = split /\t/, $homo;
		if ($lower > 1) {
			push @filter1, $homolog;
		}
	}
	foreach my $homo (@homology3) {
		chomp $homo;
	}
	my @filter2 = uniq @filter1;
	my @homologies = array_minus(@filter2, @homology3);
	if (scalar(@homology1 == 1)) {
		@homologies = strict_gain("$clade","$cladename","$lowerclade","$higherclade","$higherhigherclade");
	}
	return @homologies;
}
sub loose_loss {
	my $clade = $_[0];
	my $cladename = $_[1];
	my $lowerclade = $_[2];
	my $higherclade = $_[3];
	my $higherhigherclade = $_[4];
	chomp $clade;
	chomp $cladename;
	chomp $lowerclade;
	chomp $higherclade;
	my $highercladename = `echo 'SELECT DISTINCT \`$higherclade\` FROM phylogeny WHERE \`$cladename\`="$clade"' | mysql -B -uweb ComparativeGenomics \n\n`;
	my ($goup,$higher) = split /\n/, $highercladename;
	$highercladename = $higher;
	chomp $highercladename;
	my $query1 = "SELECT DISTINCT Homology FROM phylogeny p, specieslisted s WHERE p.SpecCode=s.SpecCode AND `$higherclade`=\"$highercladename\" AND NOT `$cladename`=\"$clade\"";
	my $query2 = "SELECT DISTINCT Homology FROM specieslisted s, phylogeny p WHERE s.SpecCode=p.SpecCode AND `$cladename`=\"$clade\"";
	my $query3 = "SELECT DISTINCT Homology FROM specieslisted s, phylogeny p WHERE s.SpecCode=p.SpecCode AND NOT `$higherclade`=\"$highercladename\"";
	my @homology1 = `echo '$query1' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology1;
	my @homology2 = `echo '$query2' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology2;
	my @homology3 = `echo '$query3' | mysql -B -uweb ComparativeGenomics \n\n `;
	shift @homology3;
	my @loose = intersect(@homology1, @homology3);
	my @homologies = array_minus( @loose, @homology2);
	return @homologies;
}
sub loose_ancestral {
	my $clade = $_[0];
	my $cladename = $_[1];
	my $lowerclade = $_[2];
	my $higherclade = $_[3];
	my $higherhigherclade = $_[4];
	chomp $clade;
	chomp $cladename;
	chomp $lowerclade;
	chomp $higherclade;
	#my $query1 = "SELECT DISTINCT s.Homology, COUNT(DISTINCT `$lowerclade`) AS Counted FROM specieslisted s, phylogeny l WHERE s.SpecCode=l.SpecCode AND `$cladename`=\"$clade\" GROUP BY Homology";
	my $query1 = "SELECT DISTINCT s.Homology FROM specieslisted s, phylogeny l WHERE s.SpecCode=l.SpecCode AND `$cladename`=\"$clade\"";
	my $query2 = "SELECT DISTINCT `$lowerclade` FROM phylogeny WHERE `$cladename`=\"$clade\"";
	my $query3 = "SELECT DISTINCT s.Homology FROM specieslisted s, phylogeny l WHERE s.SpecCode=l.SpecCode AND NOT `$cladename`=\"$clade\"";
	my $query4 = "SELECT DISTINCT s.Homology, COUNT(DISTINCT `$lowerclade`) AS Counted FROM specieslisted s, phylogeny l WHERE s.SpecCode=l.SpecCode AND `$cladename`=\"$clade\" GROUP BY Homology";
	my @homology1 = `echo '$query1' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology1;
	my @homology2 = `echo '$query2' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology2;
	my @homology3 = `echo '$query3' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology3;
	my @homology4 = `echo '$query4' | mysql -B -uweb ComparativeGenomics \n\n`;
	shift @homology4;
	my @filter2;
	my @filter1 = intersect(@homology1, @homology3);
	foreach my $homo (@homology4) {
		chomp $homo;
		my ($homolog,$lower) = split /\t/, $homo;
			if (scalar(@homology2) > 1) {
				if ($lower > 1) {
					push @filter1, $homolog;
				}
			}
			elsif ($lower==scalar(@homology2)) {
				push @filter2, $homolog;
			}
	}
	push @filter2, @filter1;
	my @homologies = uniq(@filter2);
	return @homologies;
}
sub go_collector {
	my @array = @_;
	my @goprofile = ();
	foreach my $array (@array) {
		chomp $array;
		my $query = `echo 'SELECT GO FROM geneontology WHERE Homology=$array LIMIT 1' | mysql -B -uweb ComparativeGenomics`;
		chomp $query;
		my $header;
		my $go;
		if (length($query) > 2) {
			($header, $go) = split /\n/, $query;
			unless ($go =~ /[a-z0-9A-Z]/) {
				$go = $array;
			}
		}
		else {
			$go = $array;
		}
		my @gos = split /[;]+/, $go;
		foreach (@gos) {
			$_ =~ s/\t/ /g;
			$_ =~ s/,/ /g;
			$_ =~ s/^[\s\t]+//g;
			$_ =~ s/[\s\t]+$//g;
			push @goprofile, $_;
		}
		#$go =~ s/;/\n/g;
		#push @goprofile, $go;
	}
	return @goprofile;
}
1;