#!/pkg/qct/bin/perl

#===============================================================================|
# Perl modules
#===============================================================================|
use strict;
use Cwd;
use Getopt::Std;
use File::Basename;
use Sys::Hostname;
use Date::Calc qw(:all);
## make sure configDir is set.
my $progName = basename($0);
my $configDir = dirname($0);
#===============================================================================|
# Files to open:
#   $inputFile  = Mail list users
#   $outFile    = passwd file that is output for UNIX structure.
#===============================================================================|
my $mailList = "/pkg/mailing-lists/crac-samsung.users";
my $outFile = "$configDir/passwd";
my $passwdFile = "/usr/local/etc/common/passwd/global/passwd";

# Open the files for reading/writing.
open (MLA,"$mailList") || die ("Can't open $mailList : $!");
open (PASSWD,"$passwdFile") || die ("Can't open $passwdFile : $!");
open (OUTFILE,">$outFile") || die ("Can't open $outFile : $!");

# Read in the passwd file from NIS (sorta).
my @passwdList = <PASSWD>;
close (PASSWD);

# Slurp in the entire file.
my $holdTerminator = $/;
undef $/;
my $userNames = <MLA>;
close (MLA);
$/ = $holdTerminator;

# Remove any blank lines and put into array.
chomp($userNames);
$userNames =~ s/[\n\r]//g;
my @uNames = split(/,/, $userNames);

# Cycle through each username and grep it out of NIS file.  When found place it
# into the passwd file.
foreach my $userName (@uNames) {
    if (my @entry = grep(/^$userName:/, @passwdList)) {
        my ($uname,$pw,$uid,$null,$name,$null,$shell) = split(/:/, $entry[0]);
        print OUTFILE "$uname:$pw:$uid:10001:$name, $uname\@qualcomm.com:/user/$uname:$shell"; 
    }
}
