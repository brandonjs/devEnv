#!/usr/local/bin/perl -w
use strict;
use Data::Dumper;
use LWP::Simple;
use LWP::UserAgent;
use JSON::PP;
use Finance::Quote;
use HTML::TableExtract;
use Text::Table;

my %stks = (
    "INDEXDJX:.DJI" => { "name" => "Dow Jones", comp => 1 }, 
    "INDEXNASDAQ:.IXIC" => { "name" => "Nasdaq", "comp" => 1 }, 
    "INDEXSP:.INX" => { "name" => "S&P500", "comp" => 1 }, 
    "VUG" => { "name" => "VUG", "comp" => 2 }, 
    "SPY" => { "name" => "SPDR S&P 500", "comp" => 2 }, 
    "AMZN" => { "name" => "Amazon", "comp" => 2 }, 
    "QCOM" => { "name" => "Qualcomm", "comp" => 2 }, 
    "ARAY" => { "name" => "AccuRay", "comp" => 2 }, 
    "OTCMKTS:ZNOG" => { "name" => "Zion Oil", "comp" => 2 }, 
    "AAPL" => { "name" => "Apple", "comp" => 2 }, 
    "GOOG" => { "name" => "Google Cl A", "comp" => 2 }, 
    "GOOGL" => { "name" => "Google Cl C", "comp" => 2 },
);

my $black="\033[00m";
my $red="\033[31m";
my $green="\033[32m";
my $syms = join(',', sort(keys %stks));
my @syms = (sort { lc($a) cmp lc($b) } (keys %stks));
my $content;
my $result;
my %result;
my $ua = LWP::UserAgent->new();
$ua->agent('Mozilla/4.76 [en] (Win98; U)');
foreach my $symbol (@syms) {
    my $content = $ua->get("https://www.google.com/search?&q=$symbol") or die "Couldn't get it!" unless defined $content;
    my $table_extract = HTML::TableExtract->new();
    $table_extract->parse($content->decoded_content);
    foreach my $table ($table_extract->tables) {
        my $line = $table->rows->[0]->[0];
        next unless (defined($line) && ($line =~ /Disclaimer/) && ($line =~ /^\s+[0-9]/));
        $line =~ s/^\s*//;
        $line =~ s/\s+/ /g;
        my ($price, $change, $percent, $rest) = split /\s/, $line, 4;
        $percent =~ s/\((.*)%\)/$1/g;
        $stks{$symbol}{"price"} = $price;
        $stks{$symbol}{"change"} = $change;
        $stks{$symbol}{"percent"} = $percent;

        $stks{$symbol}{"color"} = $change =~ m/^-/ ? $red : $green;
    }
}
#print Dumper sort { $stks{$a}{'comp'} <=> $stks{$b}{'comp'} || lc($a) cmp lc($b) } (keys %stks);
printf "$black%-13s$stks{$_}{'color'}%9s%9.2f%8.2f\n", $stks{$_}{'name'}, $stks{$_}{'price'}, $stks{$_}{'change'}, $stks{$_}{'percent'} for (sort { $stks{$a}{'comp'} <=> $stks{$b}{'comp'} || lc($a) cmp lc($b) } (keys %stks));

