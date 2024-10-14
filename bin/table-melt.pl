#!/usr/bin/perl -w
use strict;

my $sep = "\t";

my $tbl;
my %rows;
my %cols;
my @rownames;
my @colnames;
my $lines;
while(<>) {
    s/\R+//;
    next if /^$/;
    $lines++;
#    $_ .= '$';
    my ($row, @values) = split /$sep/;
#    s/\$$//;
#    $values[-1] =~ s/\$$//;
    if ($lines == 1) {
	print STDERR "Warning: Header row should start with an empty cell!\n\tMake sure the input is in a correct table format.\n" if $row;
	@colnames = @values;
    } else {
	for my $i (0..$#colnames) {
	    my $v = "";
	    if ($i < scalar @values) {
		$v = $values[$i] if ($values[$i] || 0 eq $values[$i]);
	    }
	    print join("\t", $row, $colnames[$i], $v), "\n";
	}
    }
}
