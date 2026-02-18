#!/pkg/perl/5.005_03/bin/perl

use strict ;
use Socket ;

my $mount = shift ;
$mount =~ m/(.*):(.*)/ ;

#my ($host) = gethostbyname $1 ;
my $host = gethostbyname $1 ;
my $path = $2 ; $path =~ s/\/$// ;
my %dnscache ;

print "host: $host, path:$path, mount:$mount\n";

open PRJ, "/usr/local/etc/common/auto.projects/auto.projects" or exit 1 ;
my @prjmnts = sort {$b->[2] cmp $a->[2] }
        grep { $_->[1] && $_->[1] eq $host }
        map { $dnscache{$_->[1]} ||= gethostbyname $_->[1] ;
                $_->[1] = $dnscache{$_->[1]} ;
                $_ }
        map { [ $_->[0], split(/:/, $_->[-1]) ] }
        map { [ split /\s+/ ] }
        <PRJ> ;
close PRJ ;

my $rest = "" ;

while ( $path =~ /\// ) {
        my ($result) = grep { $path eq $_->[2] } @prjmnts ;
        print "$result->[0]$rest\n" and exit 0 if $result ;
        $path =~ s/(\/[^\/]*)$// ;
        $rest = $1.$rest ;
}
        exit 1
#                $1 || print "/net/${1%%:*}/${1#*:}"
#        else
#                print "$1"
#        fi
