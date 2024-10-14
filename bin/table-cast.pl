#!/usr/bin/perl -w
use strict;

my $strict;
my @keep;
for (@ARGV) {
    if (/^--?s(trict)?$/) {
	$strict++;
    } else {
	push @keep, $_;
    }
}
@ARGV = @keep;


my $tbl;
my %rows;
my %cols;
my @rownames;
my @colnames;
unless (@ARGV) {
    push @ARGV, "-";
}
for my $file (@ARGV) {
    my $in;
    $file = undef if $file eq "-";
    if ($file) {
	unless (-e $file) {
	    die "ERROR: no such file '$file'\n";
	}
	if (-z $file) {
	    print STDERR "WARNING: '$file' is empty\n";
	}
    }
    if ($file) {
	open $in, '<', $file || die $!;
    } else {
	$in = *STDIN;
    }
    while(<$in>) {
	# Remove line endings
	s/\R+//;
	# Skip empty lines
	next unless /\S/;
	my ($row, $col, $value) = split/\t/;
	push @rownames, $row unless $rows{$row};
	$rows{$row}++;
	push @colnames, $col unless $cols{$col};
	$cols{$col}++;
	if ($tbl->{$row}->{$col}) {
	    print STDERR "Warning: ('$row', '$col') is already set. (Replacing '" . $tbl->{$row}->{$col} ."' by '" . $value . "'\n";
	}
	$tbl->{$row}->{$col} = $value;
	unless ($strict) {
	    if ($tbl->{$col}->{$row}) {
		print STDERR "Warning: ('$col', '$row') is already set. (Replacing '" . $tbl->{$col}->{$row} ."' by '" . $value . "'\n";
	    }
	    $tbl->{$col}->{$row} = $value;
	}
    }
}

unless ($strict) {
    # Add missing cols or rows
    for my $col (@rownames) {
	push @colnames, $col unless $cols{$col};
	$cols{$col}++;
    }
    for my $row (@colnames) {
	push @rownames, $row unless $rows{$row};
	$rows{$row}++;
    }
}

print join("\t", "", @colnames), "\n";
for my $i (@rownames) {
    print "$i";
    for my $j (@colnames) {
	my $v = "NA";
	if (defined($tbl->{$i}->{$j})) {
	    $v = $tbl->{$i}->{$j};
	}
	print "\t$v";
    }
    print "\n";
}
