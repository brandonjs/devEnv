#!/usr/local/bin/perl

#===============================================================================|
##   Perl modules.                                                              |
#===============================================================================|
use Cwd;
use Getopt::Std;
use File::Basename;
use Sys::Hostname;
use Date::Calc qw(:all);

## make sure configDir is set.
my $progName = basename($0);
my $configDir = dirname($0);
#===============================================================================|
# Several different files to open:
#   $inputFile  = Contains Qadmin information
#   $unameFile  = Contains uid and shell information. Keyed off e-mail address.
#   $outFile    = passwd file that is output for UNIX structure.
#   $cronFile   = Run out of cron that will set password expiration.
#   $decruFile  = A batch file to be passed to the decru_login.pl script to add 
#                   or remove users from the decru DFs.
#   $ahomeFile  = Automounter information for users mounts.
#===============================================================================|
my $inputFile = "$configDir/airlock.txt";
my $unameFile = "$configDir/usernames";
my $outFile = "/usr/local/etc/setup/passwd/etc/duty/craclogins/passwd";
my $cronFile = "/usr/local/etc/setup/cron/bin/chage";
my $decruScript = "/root/scripts/decru_login.pl";
my $decruFile = "$configDir/usermod";
my $ahomeFile = "/usr/local/etc/setup/automount/etc/cluster/crac.sec/auto.home";
my $adminList = "$configDir/admins";
my $adminPasswd = "/usr/local/etc/setup/passwd/etc/duty/craccompute/passwd";
my $gid = 10002;
my $mailCC          = "brandons\@qualcomm.com";
my $mailDomain      = "qualcomm.com";
my $mailHost        = "mailhost.qualcomm.com";
my $mailProg        = "/usr/sbin/sendmail -t -oii";
my $mailTo          = "crac-samsung.request\@qualcomm.com";
my $mailSubject     = "$progName";
my $sendEmail       = 0;
my ($mailMsg);

# Check if we're on syslog server, if not exit with error.
if (my $hostName=hostname() ne "crac-sec-syslog") {
    print "ERROR: This script should only be run on crac-sec-syslog.\n";
    exit 1;
}

# Open the files for reading/writing.
open (PASSWD,"$inputFile") || die ("Can't open $inputFile : $!");
open (UNAMES,"$unameFile") || die ("Can't open $unameFile : $!");
open (ADMINS,"$adminList") || die ("Can't open $adminList : $!");
open (OUTFILE,">$outFile") || die ("Can't open $outFile : $!");
open (ADMINPW,">$adminPasswd") || die ("Can't open $adminPasswd : $!");
open (DECRUFILE,">$decruFile") || die ("Can't open $decruFile : $!");
open (CRONFILE,">$cronFile") || die ("Can't open $cronFile : $!");
open (AHOMEFILE,">>$ahomeFile") || die ("Can't open $ahomeFile : $!");

# Read shell and uid information into a hash.
while (<UNAMES>) {
    chop;
    my ($eMail, $shell, $uid) = split / /;
    $shellHash{$eMail} = $shell;
    $uidHash{$eMail} = $uid;
}
close (UNAMES);

# Sort through hash to find the largest uid, this will be used for any accounts that are not
# in the current file.
$mailMsg = "User accounts added:\n--------------------\n";
$largestUid = 0;
foreach $key (keys(%uidHash)) {
    if ( $uidHash{$key} > $largestUid ) {
        $largestUid = $uidHash{$key};
    }
}
open (UNAMES,">>$unameFile") || die ("Can't open $unameFile : $!");
$largestUid += 1;
print CRONFILE "#!/bin/bash\n";
print OUTFILE "nike1:ESDtuvEAAeGa6:1806:1806:nike1:/user/nike1:/bin/csh\n";
print OUTFILE "nike2:J84PX8D2HpsbI:1807:1806:nike2:/user/nike2:/bin/csh\n";
print ADMINPW "nike1:ESDtuvEAAeGa6:1806:1806:nike1:/user/nike1:/bin/csh\n";
print ADMINPW "nike2:J84PX8D2HpsbI:1807:1806:nike2:/user/nike2:/bin/csh\n";

while ($record = <PASSWD>) {
    open (AHOMEFILERO,"$ahomeFile") || die ("Can't open $ahomeFile : $!");
    @ahome = <AHOMEFILERO>;
    close (AHOMEFILERO);
    ($userName,$eMail,$null,$passWord,$expDate) = split(/:/, $record);
    if ($expDate == "") {
            next;
    }
    ($userName, $null) = split(/@/,$userName);
    $homeDir="/prj/user/$userName";
    $passWord =~ s/^\{(crypt|SHA)\}//i;

    $uid = $uidHash{$eMail};
    $shell = $shellHash{$eMail};
    if (! $shell ) {
            $shell = "/bin/tcsh";
    }
    if (! $uid) {
            $uid = $largestUid;
            $largestUid += 1;
            print UNAMES "$eMail $shell $uid\n";
    }

   $expDate = substr($expDate,0,8);
    if ($expDate > 0) {
        ($year1,$month1,$day1) = Today([$gmt]);
        $year2 = substr($expDate,0,4);
        $month2 = substr($expDate,4,2);
        $day2 = substr($expDate,6,2);
        $dD = Delta_Days($year1, $month1, $day1, $year2, $month2, $day2);
    } else {
        $expDate = Today([$gmt]);
        $dD = 0;
    }

    if ($dD > 0) {
        print CRONFILE "passwd -w 7 -x $dD $userName\n";
        print DECRUFILE "user group grant samsung $userName\@qcom\n";
    } else {
        print CRONFILE "passwd -w 7 -x 0 $userName\n";
        $shell = "/bin/denylogin";
        print DECRUFILE "user group revoke samsung $userName\@qcom\n";
    }
    print OUTFILE "$userName:$passWord:$uid:$gid:$eMail:/user/$userName:$shell\n";
    unless(-d $homeDir) {
        mkdir $homeDir;
        chown $uid, $gid, $homeDir;
    }
    unless(`grep $userName $ahomeFile`) {
        print AHOMEFILE "$userName\t\t\t-rw,soft,intr,proto=tcp\t\tdfzag:/vol/vol0/user/&\n";
        if ($dD > 0) {
            print DECRUFILE "user add --domain qcom --id $uid,$gid --password hurry^10 nas-user $userName\n";
            print DECRUFILE "user group grant samsung $userName\@qcom\n";
            $mailMsg .= "\n$userName, $eMail\n";
            $sendEmail = 1;
        }
    }
    if(`grep $userName $adminList`) {
        print ADMINPW "$userName:$passWord:$uid:$gid:$eMail:/user/$userName:$shell\n";
    }
}

close(DECRUFILE);
if ( -s $decruFile )
{
    system("$decruScript --batch $decruFile");
}
unlink($decruFile);
close(OUTFILE);
close(CRONFILE);
close(AHOMEFILE);
chmod(0755, "$cronFile");
close(PASSWD);
close(UNAMES);
close(ADMINS);
close(ADMINPW);
if ($sendEmail) {
    $mailMsg .= "\n\nSamsung Account information has been propagated to CRAC area.\n Please log into the CRAC to ensure that the user(s) can log in.\n";
    _mailNotify("Samsung User account(s) added.", $mailMsg);
}

#
# Sub Routines
#
sub _mailNotify {

    my ($statStr) = shift;
    my ($mailMsg) = shift;

    open(MAIL, "| $mailProg") or warn("WARNING: Unable to open pipe for sendmail: $!\n")
;
    print MAIL <<EndOfMsg;
To: $mailTo
CC: $mailCC
Subject: $mailSubject on $hostName - $statStr

Run Time: $runTime

$mailMsg

Thank You,
QCT Remote Systems

EndOfMsg

    close(MAIL) or warn("WARNING: Mail pipe failed: $?\n");
}

