#!/usr/bin/perl -w

use strict;

my %mode;

# ANI tab separated file and tab separated type strain file (id, sp)
my ($anifile, $typefile);

my $min = 0.95;

my $index;
for (@ARGV) {
    $index++;
    if (/^--?a(ni)?$/i) {
	$anifile = $ARGV[$index];
    } elsif (/--?t(ypes?)?$/i) {
	$typefile = $ARGV[$index];
    } elsif (/^--?all$/) {
	$mode{'ANI'} = "all";
    } elsif (/^--?s(elect)?$/) {
	$mode{'ANI'} = "select";
    } elsif(/^--?d(istance)?$/) {
	$mode{'dist'}++;
	print STDERR "Using distance instead of ANI\n";
    } elsif (/^--?min=(\d+(\.\d+)?)$/) {
	$min = $1;
	print STDERR "The minimum value for ANI is changed to '$min' based on the arguments\n";
    }
}

unless (grep{/^--?no-?sp(ecies)?$/} @ARGV) {
    $mode{'sp'} = "yes";
}

my $help = "Usage:\n" .
    "\t$0 [-h | --help] -ani ani.tsv -type types.tsv [options]\n\n" .
    "Description:\n" .
    "\tA tool to classify strains based on reference strains and ANI scores\n\n" .
    "Options:\n" .
    "\t-h | --help\n" .
    "\t\tPrint help\n" .
    "\t-all | --all\n" .
    "\t\tPrint all the ANI scores (default skips all ANI)\n" .
    "\t-s | --select\n" .
    "\t\tPrint only the ANI scores for the reference strains (default skips all ANI)\n" .
    "\t-no-sp | --no-species\n" .
    "\t\tDo not add the species identification list to the end of the row (default would add it)\n" .
    "\t-min=<num> | --min=<num>\n" .
    "\t\tChange the minimum ANI score for species identifications to <num> (default is 0.95)\n" .
    "\t-d | --distance\n" .
    "\t\tUse genetic distance instead of ANI (similarity). Values have to be less or equal to minimum.\n" .
    "\n";


if ( grep{/^--?h(elp)?$/i} @ARGV) {
    print $help;
    exit;
}

my $readtype;
if ($typefile eq '-') {
    $readtype = *STDIN;
} elsif (! -e $typefile || -z $typefile) {
    die "ERROR: Input file ('$typefile') does not exist or it is emtyp\n\n" . $help;
} else {
    open($readtype, '<', $typefile) || die $!;
}
my $readani;
if ($anifile eq '-') {
    $readani = *STDIN;
} elsif (! -e $anifile || -z $anifile) {
    die "ERROR: Input file ('$anifile') does not exist or it is emtyp\n\n" . $help;
} else {
    open($readani, '<', $anifile) || die $!;
}

#$mode{'ANI'} = "select";
#$mode{'ANI'} = "all";

# Store type id2sp mapping
my %type;

# Process type file
for (<$readtype>) {
    s/\R//g;
    my ($id, $sp) = split/\t/;
    $type{$id} = $sp;
}
close $readtype;

#print STDERR join(", ", keys %type), "\n";

# Process ANI
my @header;
my @rows;
my @range;
for (<$readani>) {
    s/\R//g;
    my ($id, @scores) = split/\t/;
    # Header has no $id, header line should start with a tab
    if ($id) {
	# ID to ANI score mapping
	my %hash;
	my $i = 0;
	for my $k (@header) {
	    $hash{$k} = $scores[$i];
	    $i++;
	}

	# Collect species names
	my @sp;
	if ($mode{'dist'}) {
	    # Using distance instead of ANI
	    @sp = map{ $type{$_} } sort{ $hash{$a} <=> $hash{$b} } grep{ $hash{$_} <= $min } grep{ $type{$_} } keys %hash;
	} else {
	    @sp = map{ $type{$_} } sort{ $hash{$b} <=> $hash{$a} }grep{ $hash{$_} >= $min } grep{ $type{$_} } keys %hash;
	}
	@sp = ("Unknown") unless @sp;

	# Save all information for the row
	$hash{'id'} = $id;
	$hash{'scores'} = \@scores;
	$hash{'sp'} = \@sp;
	push @rows, \%hash;
    } else {
	# Map headers
	# Identify position for the types
	@header = @scores;
	my $i = 0;
	for (@header) {
	    push @range, $i if $type{$_};
	    $i++;
	}
    }
}
close $readani;

if ($mode{'ANI'}) {
    my @head = @header;
    if ($mode{'ANI'} eq 'select') {
	@head = @head[@range];
    }
    print join("\t", "", @head), "\n";
}
for my $row (@rows) {
    #    print join("\t", $row->{'id'}, @sp), "\n";
    my @col = ($row->{'id'});
    if ($mode{'ANI'} && $mode{'ANI'} eq 'all') {
	push @col, @{ $row->{'scores'} };
    } elsif ($mode{'ANI'} && $mode{'ANI'} eq 'select') {
	push @col, @{ $row->{'scores'} }[@range];
    }
    push @col, @{ $row->{'sp'} } if $mode{'sp'};
    
    print join("\t", @col), "\n";

}
