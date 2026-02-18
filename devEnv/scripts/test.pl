#!/usr/bin/perl -w
use strict;
use Config::IniFiles;
use File::Basename;
use File::Copy;
use File::MMagic;
use Getopt::Long;
use IO::File;
use Pod::Usage;
use Sys::Hostname;


#    my (@filePath) = @_;
    opendir(DH, $ARGV[0]);
    my (@filePath) = readdir(DH);
    closedir(DH);
    my $magicFile = File::MMagic->new();
    my %fileStat = ();
    my $addFileType  = "0 byte 0x03 DBase/3-data-file:0 beshort 0x180f KLA_Tencor/RDF-File:0 beshort 0x1818 KLA_Tencor/RDF-File:0 beshort 0x18C1 KLA_Tencor/RDF-File:0 beshort 0x184E KLA_Tencor/RDF-File:0 beshort 0x1827 KLA_Tencor/RDF-File:0 belong 0x00060002 GDSII/Stream-File";
    my @addFileTypes    = split(/:/, $addFileType);
##

    ##
    # add filetype(s) to perl module data array.
    if (@addFileTypes) {
        foreach my $type (@addFileTypes) {
            my ($offset, $string, $file, $msg) = split(/\s+/, $type);
            my $entry = "$offset\t$string\t$file\t$msg";
            print "$entry \n";
            $magicFile->addMagicEntry($entry) or warn($@);
        }
    }

    # get file type of files.
    foreach my $files (@filePath) {
        my ($fileType, undef) = split(/;/, $magicFile->checktype_filename($files));
        print "File:" . $files . " is of type: " . $fileType . "\n";
        #$fileStat{basename($files)} = {
        #    f_type => $fileType,
        #    f_size => (stat($files))[7]
        #};
    }



