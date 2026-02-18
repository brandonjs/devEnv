#!/usr/local/bin/perl -w
## $Id: secApproval.pl,v 1.4 2009/05/20 02:22:24 brandons Exp $
#==============================================================================|
# $script:  secApproval.pl                                                     |
# $author:  Mitch McNeel \$@ Qualcomm Inc. for:  Brandon Schwartz              |
# $date:    09/20/2006                                                         |
# $purpose: Provide a automated way to approve files according to their type   |
#           and size prior to SEC access.                                      |
#                                                                              |
# Revision                                                                     |
# History:                                                                     |
#                                                                              |
# Date:       Who:    Comments:                                                |
# -----       ----    ---------------------------------------------------------|
# 20061113    MitchM  Feature Enhancements:                                    |
#                     1.) Added lockfile and lockfile check to prevent script  |
#                         from running if a previous run is still running.     |
# 20061109    MitchM  Feature Enhancements:                                    |
#                     1.) Add fileTypesSize configuration setting, to allow    |
#                         for file size checking against file types.           |
#                     2.) Removed the fileSizeLimit options.                   |
# 20061019    MitchM  Feature Enhancements:                                    |
#                     1.) Added check to see if files (with same name) already |
#                         exist in the destination directory, if so then don't |
#                         copy them.                                           |
#                     2.) Added '--verbose' command line option to allow for   |
#                         less output to screen, unless given the verbose      |
#                         option.                                              |
#                     3.) Changed output of log files to be less verbose.      |
#                         removed full path from file name and added it to the |
#                         top of the log instead.                              |
#                     4.) Added email notification for successfull copies and  |
#                         files that need approval.  Also, notify on errors.   |
#                     5.) Added unlinking of successfull copies and moving of  |
#                         files that need approval to the $needAppPath, set in |
#                         configuration file.                                  |
# 20060920    MitchM  Initial Version.                                         |
#==============================================================================|
##
# NOTE: set tabstop=4 to view, 'vim' or 'vi' this script.
##
#==============================================================================|
#   Perl modules.                                                              |
#==============================================================================|
use strict;
use Config::IniFiles;
use File::Basename;
use File::Copy;
use File::MMagic;
use Getopt::Long;
use IO::File;
use Pod::Usage;
use Sys::Hostname;

##
# get command line options and display usage if not given any options or invalid
# options.
my %opts = ();
pod2usage(-verbose => 0)
  unless GetOptions(\%opts, 'help|?', 'man', 'verbose', 'source=s', 'destination=s');
pod2usage(-verbose => 1, -msg => "Extended Help Section...") if ($opts{'help'});
pod2usage(-verbose => 2) if ($opts{'man'});
##
# set configuration path and get setting from configuration file.
my $configPath = dirname($0);
my $configs = Config::IniFiles->new(-file => "$configPath/secApproval.cfg")
  or die("ERROR: Unable to find configuration file $configPath/secApproval.cfg\n\n");

#==============================================================================|
#   Initialize Vars.                                                           |
#==============================================================================|
my $hostName        = hostname;
my $progName        = basename($0);
my $runTime         = localtime;
my $sourcePath      = $opts{'source'} || $configs->val('General', 'sourcePath');
my $destPath        = $opts{'destination'} || $configs->val('General', 'destPath');
my $needAppPath     = $opts{'destination'} || $configs->val('General', 'needAppPath');
my $needApproval    = $configs->val('General', 'needApproval') if ($configs);
my $copiedFiles     = $configs->val('General', 'copiedFiles') if ($configs);
my @addFileTypes    = split(/:/, $configs->val('General', 'addFileTypes')) if ($configs);
my @fileTypesSize   = split(/:/, $configs->val('General', 'fileTypesSize')) if ($configs);
my $fileTypes       = $configs->val('General', 'fileTypes') if ($configs);
my $dirExcludes     = $configs->val('General', 'dirExcludes') if ($configs);
my $lockFile        = $configs->val('General', 'lockFile') if ($configs);
my $dtplockFile     = $configs->val('General', 'dtplockFile') if ($configs);
my $ftslockFile     = $configs->val('General', 'ftslockFile') if ($configs);
my $wrtNeedApproval = IO::File->new();
my $createLock      = IO::File->new();
my $verbose         = $opts{'verbose'} if ($opts{'verbose'});
my $mailCC          = $configs->val('Mail', 'mailCC') if ($configs);
my $mailDomain      = $configs->val('Mail', 'mailDomain') if ($configs);
my $mailHost        = $configs->val('Mail', 'mailHost') if ($configs);
my $mailProg        = $configs->val('Mail', 'mailProg') if ($configs);
my $mailTo          = $configs->val('Mail', 'mailTo') if ($configs);
my $mailSubject     = "$progName";
my $approval        = 0;
my (%myApprovedFiles, %fileStats, %fileTypeSizes, @sourceFiles, $mailMsg);

#==============================================================================|
#   Begin                                                                      |
#==============================================================================|
##
# check for previous running process.
if (-e "$dtplockFile") {
    die("$progName: done_to_pending script is currently running...\n\n");
}

if (-e "$ftslockFile") {
    die("$progName: filer_to_sftp script is currently running...\n\n");
}

if (-e "$lockFile") {
    die("$progName: Script is already running...\n\n");
}
else {
    $createLock->open("> $lockFile");
    print $createLock ("Started: $runTime\n\n");
    $createLock->close();
}

##
# check to make sure all configuration variables have been set.
pod2usage(-verbose => 0, -msg => "ERROR: Unable to set configuration variables...\n\n")
  if (
    !(
            $sourcePath
        and $destPath
        and $needApproval
        and $copiedFiles
        and $fileTypes
        and $dirExcludes
        and @fileTypesSize
    )
  );
##
# clean up previous runs log files.
_cleanUp($needApproval) if (-e "$needApproval");
_cleanUp($copiedFiles)  if (-e "$copiedFiles");

##
# check to see if source path exists.
if (-e $sourcePath) {
    print("Processing...\n");
    opendir(DIR, "$sourcePath") or die("$progName: ERROR: Unable to open directory for reading: $!\n\n");
    ##
    # foreach entry in the directory, put into an array for testing.
    foreach my $entry (readdir DIR) {
        $entry =~ /^$dirExcludes$/ and next;    # skip .snapshot, current and parent directories.

        my $sourceFile = "$sourcePath/$entry";
        push(@sourceFiles, $sourceFile) unless (grep(/\Q$sourceFile\E$/, @sourceFiles));
    }
    closedir(DIR);
}
else {
    ##
    # notify when errors are encountered.
    _errNotify("ERROR: $sourcePath not found: $!\n") and die("$progName: ERROR: $sourcePath not found: $!\n\n");
}

##
# create destination path, if it doesn't exist.
#if (!(-e $destPath)) {
#    mkdir("$destPath") or die("ERROR: Unable to create $destPath: $!\n");
#}

##
# open file handle for writing files that don't pass the checks.
$wrtNeedApproval->open("> $needApproval") or die("$progName: ERROR: Unable to open/write $needApproval: $!\n\n");

##
# get file stats (type/size).
(%fileStats) = _checkFiles(@sourceFiles);

##
# create hash of file type sizes.
(%fileTypeSizes) = _createSizeMap(@fileTypesSize);

##
# loop through hash array.
print $wrtNeedApproval ("Source Path: $sourcePath\n--------------------\n");
$mailMsg = "Source Path: $sourcePath\n--------------------\n";
foreach my $sourceFile (sort keys %fileStats) {
    foreach my $attrib (sort keys %{$fileStats{$sourceFile}}) {
        if ($attrib eq 'f_type') {
            ##
            # if file type matches types in configuration file.
            if ($fileStats{$sourceFile}->{$attrib} =~ /$fileTypes/) {
                ##
                # check file type size against configuration fileTypesSizes.
                #print("Type: $fileStats{$sourceFile}->{'f_type'} SIZE: $fileTypeSizes{$fileStats{$sourceFile}->{'f_type'}}\n");
                if ($fileStats{$sourceFile}->{'f_size'} <
                    $fileTypeSizes{$fileStats{$sourceFile}->{'f_type'}})
                {
                    if (!($fileStats{$sourceFile}->{'f_size'} <= 0)) {
                        $myApprovedFiles{"$sourcePath/$sourceFile"}++;
                    }
                    else {
                        warn(
"WARN: (Warning) - $sourceFile is $fileStats{$sourceFile}->{'f_size'} in size...\n"
                          )
                          if ($verbose);
                        print $wrtNeedApproval (
"Need Approval: $sourceFile is $fileStats{$sourceFile}->{'f_size'} in size...\n"
                        );
                        $mailMsg .=
"Need Approval: $sourceFile is $fileStats{$sourceFile}->{'f_size'} in size...\n";
                        ##
                        # move needs approval files to approval dir.
                        move("$sourcePath/$sourceFile", "$needAppPath")
                          or warn("WARN: Unable to move $sourceFile to $needAppPath: $!\n");
                        $approval++;
                    }
                }
                else {
                    warn(
"WARN: (Warning) - $sourceFile is greater than $fileTypeSizes{$fileStats{$sourceFile}->{'f_type'}} bytes...\n"
                      )
                      if ($verbose);
                    print $wrtNeedApproval (
"Need Approval: $sourceFile is greater than $fileTypeSizes{$fileStats{$sourceFile}->{'f_type'}} bytes...\n"
                    );
                    $mailMsg .=
"Need Approval: $sourceFile is greater than $fileTypeSizes{$fileStats{$sourceFile}->{'f_type'}} bytes...\n";
                    ##
                    # move needs approval files to approval dir.
                    move("$sourcePath/$sourceFile", "$needAppPath")
                      or warn("WARN: Unable to move $sourceFile to $needAppPath: $!\n");
                    $approval++;
                }
            }
            else {
                warn("WARN: (Warning) - $sourceFile is not a valid file type...\n") if ($verbose);
                print $wrtNeedApproval (
"Need Approval: $sourceFile is not a valid file type: $fileStats{$sourceFile}->{'f_type'}...\n"
                );
                $mailMsg .=
"Need Approval: $sourceFile is not a valid file type: $fileStats{$sourceFile}->{'f_type'}...\n";
                ##
                # move needs approval files to approval dir.
                move("$sourcePath/$sourceFile", "$needAppPath")
                  or warn("WARN: Unable to move $sourceFile to $needAppPath: $!\n");
                $approval++;
            }
        }
    }
}
##
# notify that files need approval.
$mailMsg .= "\nFiles were moved to $needAppPath...\n" if ($approval > 0);
$mailMsg .= "No files need approval...\n"             if ($approval == 0);
_mailNotify("Need Approval: $approval", $mailMsg) if ($approval > 0);
$wrtNeedApproval->close() if (-e "$needApproval");

if (%myApprovedFiles) {
    _copyFiles(%myApprovedFiles);
}
else {
    ##
    # notify when errors are encountered.
    warn("WARN: (Warning) - Nothing to do at this time...\n") if ($verbose);
    #_errNotify("WARN: (Warning) - Nothing to do at this time...\n");
}
##
# after run clean up lock file.
_cleanUp($lockFile) if (-e "$lockFile");

print("Check log file: $copiedFiles for sucessfull copies...\n");
print("Check log file: $needApproval for file(s) that need manual approval...\n");
print("Done...\n");

#==============================================================================|
#   Sub Routines.                                                              |
#==============================================================================|

sub _checkFiles {

    my (@filePath) = @_;
    my $magicFile = File::MMagic->new();
    my %fileStat = ();

    ##
    # add filetype(s) to perl module data array.
    if (@addFileTypes) {
        foreach my $type (@addFileTypes) {
            my ($offset, $string, $file, $msg) = split(/\s+/, $type);
            my $entry = "$offset\t$string\t$file\t$msg";
            $magicFile->addMagicEntry($entry) or warn($@);
        }
    }

    ##
    # get file type of files.
    foreach my $files (@filePath) {
        my ($fileType, undef) = split(/;/, $magicFile->checktype_filename($files));
        $fileStat{basename($files)} = {
#            f_type => $magicFile->checktype_filename($files),
            f_type => $fileType,
            f_size => (stat($files))[7]
        };
    }

    return (%fileStat) if (%fileStat);

    # return undef if no types are found.
    return;
}

sub _copyFiles {

    my (%files)      = @_;
    my $wrtSentFiles = IO::File->new();
    my $copied       = 0;

    if (%files) {
        if (-d $destPath) {
            $wrtSentFiles->open("> $copiedFiles")
              or die("$progName: ERROR: Unable to open/write $copiedFiles: $!\n");
            print $wrtSentFiles ("Destation Path: $destPath\n---------------------\n");
            $mailMsg = "Destation Path: $destPath\n---------------------\n";
            foreach my $file (sort keys %files) {
                my $testFile = basename($file);
                if (!(-e "$destPath/$testFile")) {
                    print("Copying $testFile to $destPath...\n") if ($verbose);
                    copy("$file", "$destPath")
                      or warn(("WARN: (Warning) - Unable to copy $file: $!\n") and next);
                    print $wrtSentFiles ("Successfully Sent: ", basename($file), "\n");
                    $mailMsg .= "Successfully Sent: " . basename($file) . "\n";
                    ##
                    # remove source on successful transfer.
                    unlink("$file") if (-e "$destPath/$testFile");
                    $copied++;
                }
                else {
                    warn("WARN: (Warning) - ", basename($file), " already exists in $destPath\n")
                      if ($verbose);
                }
            }
            $wrtSentFiles->close() if (-e "$copiedFiles");
            ##
            # notify of files copied.
            $mailMsg .= "No files were copied...\n" if ($copied == 0);
            _mailNotify("Copied files: $copied", $mailMsg) if ($copied > 0);
        }
        else {
            ##
            # notify when errors are encountered.
            _errNotify("ERROR: Copy failed - $destPath doesn't exist: $!\n")
              and die("$progName: ERROR: Copy failed - $destPath doesn't exist: $!\n");
        }
    }
    else {
        warn("WARN: (Warning) - No files are available for copying...\n");
    }

    return;
}

sub _createSizeMap {

    my @fileTypeSize = @_;
    my $cnt          = 0;
    my %fileTypesSizes;

    ##
    # remove the regex parentheses and create array.
    $fileTypes =~ s/(\(|\))//g;
    my @fileTypes = split(/\|/, $fileTypes);

    ##
    # check to make sure they have the same size of type/size.
    if ($#fileTypes == $#fileTypeSize) {
        foreach my $size (@fileTypeSize) {
     #       print("$fileTypes[$cnt] = $size\n");
            $fileTypesSizes{$fileTypes[$cnt]} = $size;
            $cnt++;
        }
    }
    else {
        die(
            "$progName: ERROR: Check configuration for fileTypes and fileTypesSizes
       Make sure they have the same amount of fields\n\n"
        );
    }

    return (%fileTypesSizes);
}

sub _cleanUp {

    my $file = shift;

    if (-e "$file") {
        unlink("$file") or warn("WARN: (Warning) - Unable to remove $file: $!\n");
    }
    else {
        warn("WARN: (Warning) - Unable to remove $file: $!\n") if ($verbose);
    }

    return;
}

sub _mailNotify {

    my ($statStr) = shift;
    my ($mailMsg) = shift;

    open(MAIL, "| $mailProg -oi -t") or warn("WARNING: Unable to open pipe for sendmail: $!\n");
    print MAIL <<EndOfMsg;
To: $mailTo
CC: $mailCC
Subject: $mailSubject on $hostName - $statStr

Run Time: $runTime

$mailMsg

Thank You,
QCT Engineering Compute

EndOfMsg

    close(MAIL) or warn("WARNING: Mail pipe failed: $?\n");
}

sub _errNotify {

    my ($errorStr) = @_;
    my ($errorSubject, undef) = split(/:/, $errorStr, 2);
    my $hostName = hostname;
    open(MAIL, "| $mailProg -oi -t") or warn("WARNING: Unable to open pipe to sendmail: $!\n");
    print MAIL <<EndOfMail;
To: $mailTo
Cc: $mailCC
Subject: $mailSubject on $hostName - $errorSubject

Run Time: $runTime

$progName - $errorStr

Thank You,
QCT Remote Systems

EndOfMail

    close(MAIL) or warn("WARNING: Mail pipe failed: $?\n");
}

__END__

#==============================================================================|
#   POD documentation                                                          |
#==============================================================================|

=head1 NAME

B<secApproval.pl>

=head1 SYNOPSIS

B<secApproval.pl> I<[ [ --help | -h ] | --man (extended help) ]> I<[ [ --source | -so ] /path/to/source/directory ]> I<[ [ --destination | -d ] /path/to/destination/directory ]> I<[ --verbose | -v ]>

=head1 DESCRIPTION

The secApproval.pl script is designed to take as input a source path and traverse the directory structure (one level) and determine the file(s) type/size.  It will determine if the file(s) match(es) the types and size of the types/sizelimit, set by the I<$fileTypes> and I<$fileTypesSize> variables within the configuration file F<secApproval.cfg>, for a SEC transfer (Approval) to proceed. It will then copy files from the source path to the destination path and remove file(s) from the source path on successfull transfer.  It will also move any files that do not match the criteria into the ($needAppPath variable) need approval directory.

NOTE: After successfull or failure transfers, this script will notify the administrator(s) or group of any success or failure.

This script requires the following perl modules be installed into your perl distribution:

=item Config::IniFiles

=item File::Basename

=item File::Copy

=item File::MMagic

=item Getopt::Long

=item IO::File

=item Pod::Usage

=item Sys::Hostname

=head1 OPTIONS

=head2 The following options are supported:

=over 3

=item B<[ --source | -so ]> F</source/path>

Provide this option with source path to validate files and copy them to destination.

=item B<[ --destination | -d ]> F</destination/path>

Provide this option with destination path so validated files will be copied.

=item B<[ --help | -h ]>

Provide this option to print the extended usage statement.

=item B<[ --man | -m ]>

Provide this option to print the entire perl documentation.

=item B<[ --verbose | -v ]>

Provide this option to show verbose output (i.e, status messages) to the screen.

=back

=head1 BUGS

B<NONE KNOWN AT THIS TIME>

=head1 EXAMPLES

Run approval process from the command line with options other than the default (found in F<secApproval.cfg> file).

C<$ ./secApproval.pl --source=/source/path --destination=/destination/path>

Run approval process from the command line using the default configuration options (found in the F<secApproval.cfg> file).

C<$ ./secApproval.pl>

=over 3

NOTE: You can setup a cron job to run this process with command line options or using the default configuration options within the configuration file (F<secApproval.cfg>).

=back

=head1 SEE ALSO

B<http://qwiki.qualcomm.com/foundry-int/Samsung_(SEC)>

=head1 FILES

=item secApproval.cfg

This file contains all the default configuration settings for the approval process. It should be in the same directory as the script.

=head1 AUTHOR

M. McNeel - <c_mmcnee@qualcomm.com> - Qualcomm Inc,.

=head1 COPYRIGHT

Copyright (C) 2006 by Qualcomm Inc,.

This script was written for Qualcomm Inc., and was not intended for external use.  Qualcomm reserves all the rights for this script. Copyright (c) 2006.

This script is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

=cut
