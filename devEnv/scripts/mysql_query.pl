#!/pkg/qct/bin/perl -w

use strict;
use Mysql;

my $host = "rtmdb1.qualcomm.com";
my $database = "rtmdb";
my $user = "mysql";
my $password = "mysql";

my $db = Mysql->connect($host, $database, $user);
#my $db = Mysql->connect($host, $database, $user, $password);
#my $db = Mysql->connect($host, $database);
