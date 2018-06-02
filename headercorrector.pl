#!/usr/bin/perl -w
use strict;

my $input =  $ARGV[0];
chomp $input;
open (OUT, ">$input\_corrected");
open (IN, "<$input") or die "Could not open $input for reading\n";
while (my $line = <IN>) {
	chomp $line;
	$line =~ s/^RvY_/rvar_RvY_/;
	$line =~ s/\tRvY_/\trvar_RvY_/;
	$line =~ s/(^g)[0-9]/bsch_g/;
	$line =~ s/(\tg)[0-9]/\tbsch_g/g;
	print OUT $line, "\n";
}
exit;