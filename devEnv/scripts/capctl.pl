#!/usr/bin/perl

#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2006 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)capctl.pl	1.5	06/11/21 SMI"
#

#
# capctl: Modify CPU caps
# Author: Alexander Kolbasov
#

use warnings;
use strict;
use Getopt::Long qw(:config no_ignore_case bundling auto_version);
use File::Basename;

# Get script name
our $cmdname = basename($0, ".pl");

sub usage
{
	print STDERR
	  "Usage:\t$cmdname " .
	  "[-P project] [-p pid] [-Z zone] [-n name] [-v value]\n";
	print STDERR "\t-P proj:  Specify project id\n";
	print STDERR "\t-p pid:   Specify pid\n";
	print STDERR "\t-Z zone:  Specify zone name\n";
	print STDERR "\t-n name:  Specify resource name\n";
	print STDERR "\t-v value: Specify resource value\n";

	exit (shift);
}

sub prctl
{
	my $arg = shift;
	print $arg, "\n";
	system($arg);
}

# Parse command-line options
our($opt_h, $opt_n, $opt_Z, $opt_p, $opt_P, $opt_v);

GetOptions("Z=s"   => \$opt_Z,
	   "n=s" => \$opt_n,
	   "v=s" => \$opt_v,
	   "h|?" => \$opt_h,
	   "P=s" => \$opt_P,
	   "p=s" => \$opt_p) || usage(3);

usage(0) if $opt_h;
usage(1) if $opt_Z && ($opt_P || $opt_p);
usage(1) if ($opt_P && $opt_p);

my $do_print = 1 unless defined($opt_v);
my $do_project = 1 if $opt_p || $opt_P;

my $zone = $opt_Z || 'global';

my $name = $opt_n ? $opt_n :
  $do_project ?  'project.cpu-cap' : 'zone.cpu-cap' ;

$opt_Z = $zone unless $do_project;

# Do some processing for the value
$opt_v =~ s/%// if $opt_v;	# Remove trailing %
my $value = $opt_v || 0;

my $common_args = "-t privileged -n $name";

my $prctl_args  = "/usr/bin/prctl REPLACE $common_args";
my $check_args  = "/usr/bin/prctl $common_args -P";
my $remove_args = "/usr/bin/prctl $common_args -x";

my $what;
$what = " -i zone $zone" if $opt_Z;
$what = " -i project $opt_P" if $opt_P;
$what = " -i process $opt_p" if $opt_p;

$prctl_args = $prctl_args . " -P" if $do_print;

$prctl_args  = $prctl_args . " -v $opt_v" if $opt_v;

$prctl_args  = $prctl_args . $what;
$check_args  = $check_args . $what;
$remove_args = $remove_args . $what;

my $nresources = 0;

if (!$do_print) {
	#
	# replace value if it is already present
	#
	open(PRCTL, "$check_args | ") or
	  die "can not run $check_args";

	while(<PRCTL>) {
		$nresources++ if /$name/;
	}

	close PRCTL;

	if ($nresources == 1 && $value != 0) {
		$prctl_args =~ s/REPLACE/-r/;
	} else {
		while ($nresources--) {
			prctl($remove_args);
		}
	}
	exit(0) unless $value;
}

$prctl_args =~ s/REPLACE//;
prctl($prctl_args);

__END__

=pod

=head1 NAME

capctl - Set or display CPU caps

=head1 SYNOPSYS

  capctl [-P project] [-p pid] [-Z zone] [-n name] [-v value]

=head1 DESCRIPTION

The capctl script simplifies CPU Caps management.

  capctl [-P project] [-p pid] [-Z zone] [-n name] [-v value]

=head2 OPTIONS

=over

=item -P proj

Specify project id

=item -p pid

Specify pid

=item -Z zone

Specify zone name

=item -n name

Specify resource name

=item -v value

Specify resource value

=back

=head1 EXAMPLES

=over

=item set a cap for project foo to 50%

  # capctl -P foo -v 50

=item change the cap to 80%

  # capctl -P foo -v 80

=item see the cap value

  # capctl -P foo

=item remove the cap

  # capctl -P foo -v 0

=back


=cut
