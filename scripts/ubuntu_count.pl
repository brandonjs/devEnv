#!/pkg/qct/software/perl/bin/perl

#use strict;
#use warnings;

use Ph;
use Data::Dumper;
use Carp qw(carp croak);
use Text::Tabs;

$tabstop = 4; 

my $mdb = Ph->new();
my $queryStr = "duties=ubuntu.\*";
my $queryStr2 = "admin_contact=acme.admin os_dist=ubuntu\*";
my @return = ("name", "site", "hw_model", "os_dist", "duties", "status");
my @results, @sites, @models, @dists, @duties, @status;
my @twodArray, @onSiteCount, @offSiteCount, @temp, @hostSeen;
my $hn, $dist, $status, $typem, $hostCount = 0;
my $debug = 1;
my %k;

sub count_unique {
    my @array = @_;
    my %count;
   map { $count{$_}++ } @array;

#    print Dumper(\@array) if ($debug);
#    print Dumper(\%count) if ($debug);

    #print them out:
    map {printf expand("\t%5d\t%s\n", ${count{$_}}, $_)} sort keys(%count);
}

sub count_unique_2d {
    my @array = @_;
    my @seen, @unique;
    my (%count, %temp);
    for my $dist (@array) {
        for ($dist) {
            s/_Desktops.*//g;
            s/_Servers.*//g;
        }
    }
    map { $count{$_}++ } @array;

    @seen = sort keys %count;
    for my $dist (@seen) {
        for ($dist) {
            s/_online.*//g;
            s/_offline.*//g;
        }
    }
    %temp = map { $_, 1 } @seen;
    @unique = keys %temp;

#    print Dumper(\@unique);
    for my $dist (sort @unique) {
        my $distOn = $dist . "_online";
        my $distOff = $dist . "_offline";
        $dist = $dist . ":";
        if ( defined $count{$distOff} ) {
            printf expand("\t    %-9s %-5s %-4d %-5s %-4d\n", $dist, "Online:", $count{$distOn}, "Offline:", $count{$distOff}); 
        } else {
            printf expand("\t    %-9s %-5s %-4d %-5s %-4d\n", $dist, "Online:", $count{$distOn}, "Offline:", "0"); 
        }
            
    }
#    map {printf expand("\t%5d\t%s\n", ${count{$_}}, $_)} sort keys(%count);
}

sub return_unique {
    my @array = @_;
    my %count;
    map {$count{$_} = 1} @array;
    return sort keys(%count);
}

sub _queryMDB {
    my ($param1, @return) = @_;
    my $mdb = Ph->new();
    my @results;

    ##
    # if we connect to mdb server.
    if ($mdb) {
        ##
        # connect to mdb.
        $mdb->Connect('mdb', 905);
        ##
        # run query.
        @results = $mdb->Query($param1, [@return]);

    }
    return (@results) if (@results);

    return;
}

@results = ( _queryMDB($queryStr, @return), _queryMDB($queryStr2, @return));
foreach my $res (sort @results) {
    $hn = $res->{'name'};
    map { $k{$_} = 1 } @hostSeen;
    next if (defined($k{$hn}));
    push (@hostSeen, $hn);
    push (@sites, $res->{'site'});
    push (@models, $res->{'hw_model'});
    $hostCount ++;
    $dist = $res->{'os_dist'};
    $status = $res->{'status'};
    $type;
    for ($dist) {
        s/ubuntu8-10|debian-lenny\/sid/Intrepid/g;
        s/ubuntu9-04/Jaunty/g;
        s/ubuntu9-10/Karmic/g;
        s/ubuntu10-04/Lucid/g;
        s/ubuntu10-10/Maverick/g;
        s/ubuntu11-04/Natty/g;
        s/debian.*/Debian/g;
        s/Not present.*|LinuxMint.*/Unknown/g;
    }
    for ($status) {
        s/online.*/online/g;
        s/offline.*/offline/g;
        s/Not\ present.*/offline/g;
    }

    if ($res->{'duties'} =~ /ubuntu\.desktop/ixms) {
        $type = "Desktops";
    } else {
        $type = "Servers";
    }

    push (@dists, $dist);
    push (@duties, $res->{'duties'});
    if ($status eq "online") {
        push @onSiteCount, [ ($res->{'site'}, $dist) ]
    } else {
        push @offSiteCount, [ ($res->{'site'}, $dist) ];
    }
    push @twodArray, [ ($res->{'site'}, $dist . "_" . $status . "_" . $type) ];
 
    if ($status eq "online") {
        push (@online, $type);
    } else {
        push (@offline, $type);
    }
}

@twodArray = sort { lc($a->[0]) cmp lc($b->[0]) } @twodArray;
@onSiteCount = sort { lc($a->[0]) cmp lc($b->[0]) } @onSiteCount;
@offSiteCount = sort { lc($a->[0]) cmp lc($b->[0]) } @offSiteCount;

print "\n";
print "================ Ubuntu Machine Count ===============\n";
print "\n";
print "======= Total Hosts: " . $hostCount . " =======\n";
print "\n";
count_unique(@dists);
print "\n";
print "======= Online Hosts =======\n";
print "\n";
count_unique(@online);
printf expand("\t%5d\tTotal\n", scalar(@online));
print "\n";
print "======= Offline Hosts =======\n";
print "\n";
count_unique(@offline);
printf expand("\t%5d\tTotal\n", scalar(@offline));
print "\n";
print "======= Numbers by site =======\n";

for $i ( 0 .. $#twodArray ) {
    if ( $twodArray[$i][0] eq $twodArray[$i+1][0] ) {
        push (@temp, $twodArray[$i][1]);
    } else {
        push (@temp, $twodArray[$i][1]);
        print "\n";
        format STDOUT =
@|||||||||||||||||||||||||||||||||||||||||||||||
ucfirst($twodArray[$i][0])
@|||||||||||||||||||||||||||||||||||||||||||||||
"  ---------------------------------------"
.
        write STDOUT;
        my @temp2 = grep(/Desktops/, @temp);
        my @temp3 = grep(/Servers/, @temp);
        printf expand("\t  %-5s %-4d %-5s %-4d %-5s %-4d\n\n", "Total:", scalar(@temp), "Desktops:", scalar(@temp2), "Servers:", scalar(@temp3)); 
        count_unique_2d(@temp);
        @temp = ();
    }
}

print "\n";
print "======= Model Types =======\n";
print "\n";
count_unique(@models);

