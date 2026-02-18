#!/usr/bin/perl -w

use Data::Dumper;
use LWP::Simple;
use HTML::Parse;

my $hDayRef = {};
my $hDay="";
my @htmlA;
my @elements;
my %monthA;
@monthA{qw(January February March April May June July August September October November December)} = 1..12;

#print Dumper($res->decoded_content);

foreach ("New Year's Day", "Memorial Day", "Independence Day", "Labor Day", "Thanksgiving", "Christmas Day") {
    $hDay = $_;
    $hDay =~ tr/A-Z/a-z/; 
    $hDay =~ s/ /-/g;
    my $file = get('http://www.calendar-365.com/holidays/' . $hDay . '.html');
    @htmlA = split(/td/, $file);
    foreach my $line (@htmlA) {
        if ($line =~ /legenda_day/) {
            $line =~ s/.*legenda_day'>//g;
            $line =~ s/<.*//g;
            $line =~ s/,//g;
            push(@elements, $line);
            my ($month, $day, $year) = split(/ /, $line);
            $hDayRef->{$year}{$_} = $year . '/' . $monthA{$month} . '/' . $day;
        }
    }
}

open (my $fh, ">", "Bop.hol") or die "Can't open file Bop.hol: $!";

for my $k1 (sort keys %$hDayRef ) {
    print $fh "[Bop US Holidays $k1] " . keys (%{$hDayRef->{$k1}}) . "\n";
    for my $k2 (keys %{$hDayRef->{$k1}}) {
        print $fh "$k2     ,$hDayRef->{$k1}{$k2}\n";
    }
    print $fh "\n";
}
close $fh;
