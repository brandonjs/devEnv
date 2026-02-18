#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  orgChartTraverse.pl
#
#        USAGE:  ./orgChartTraverse.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Brandon Schwartz (bjs), bsschwar@amazon.com
#      COMPANY:  Amazon.com Inc
#      VERSION:  1.0
#      CREATED:  06/06/2022 08:55:55
#     REVISION:  ---
#===============================================================================
#
#Usage: ~/scripts/orgChartTraverse.pl uid waltersm

use strict;
use warnings;
use Net::LDAP;

my $attr = shift(@ARGV);

my $ldap = Net::LDAP->new('ldap');
$ldap->bind;

my @recurse = ();
foreach my $mgr (@ARGV) {
    my $result = $ldap->search( base => 'o=amazon.com', filter => "(uid=$mgr)", attrs => [$attr]);
    foreach my $entry ($result->entries) {
        print "$mgr: " . $entry->get_value($attr) . "\n";
        push (@recurse, $entry->dn());
    }
}

while (@recurse) {
    my $mgr = shift @recurse;
    $mgr =~ s/([()])/\\$1/g;
    my $result = $ldap->search( base => 'o=amazon.com', filter => "(&(manager=$mgr)(amznjobcode=6))", attrs => [$attr, 'amznismanager', 'uid', 'amznjobcode']);
    foreach my $entry ($result->entries) {
        print $entry->get_value('uid') . ": " . $entry->get_value('amznjobcode') . "\n" if ($entry->get_value('amznismanager') == 1);
        push (@recurse, $entry->dn()) if ($entry->get_value('amznismanager') == 0);
    }
}
