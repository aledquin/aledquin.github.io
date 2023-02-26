#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : ddr-defTransformCoords.pl
# Author  : alvaro
# Date    : 2023-01-23
# Purpose :
## A hack to transform DEF file x/y units from file UNITS to user defined UNITS
##
## Requires units field
##   UNITS DISTANCE MICRONS <units>
##
## Supports DEF file constructs:
##   DIEAREA ( <xunits> <yunits> ) ( <xunits> <yunits> ) ...
##   ... COVER ( <xunits> <yunits> ) DIR
##   ... PLACED ( <xunits> <yunits> ) DIR
##   ... RECT <layer> ( <xunits> <yunits> ) ( <xunits> <yunits> ) [;]
##   ... RECT ( <xunits> <yunits> ) ( <xunits> <yunits> ) [;]
##   ... ROUTED <layer> <width> ( <xunits> <yunits> [<extValue>] ) ( <xunits> <yunits> [<extValue>] ) ...
##   ... NEW <layer> <width> ( <xunits> <yunits> [<extValue>] ) ( <xunits> <yunits> [<extValue>] ) ...
##
## Fails for DEF file constructs:
##   + ( <xunits> <yunits> ) ...
##
## Flags all transformed units that are not integer
#
# Modification History
#     000 alvaro  2023-01-23
#         Created this script

#
###############################################################################

use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Copy;
use File::Spec::Functions qw( catfile );
use Cwd;
use Carp qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

use Capture::Tiny qw/capture/;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION     = get_release_version();
our $TESTMODE = 0;    # if set then your script should not do anything
                      # destructive like 'p4 submit' commands. Intead just
                      # print an info about it.

#--------------------------------------------------------------------#
our $FPRINT_NOEXIT = 1;    # This is only done when testing and when you do not
                           # want fatal_errorerror() to exit your application.
                           #
BEGIN {
    our $AUTHOR = 'alvaro';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
Main() unless caller();

END {
    local $?;              # to prevent the exit() status from getting modified
    footer();
    write_stdout_log($LOGFILENAME);
}

########  YOUR CODE goes in Main  ##############
sub Main {
    my $record_usage = 0;
    my @orig_argv    = @ARGV;    # keep this here because GetOpts modifies ARGV

    # default -> automatically provide access and setup of the DEBUG and
    # VERBOSITY settings
    my ( $opt_config, $opt_nousage ) = process_cmd_line_args();
    utils__process_cmd_line_args();

    unless ( $main::DEBUG || $opt_nousage ) {
        utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@orig_argv );
    }

    if ($main::TESTMODE) {
        iprint("DRYRUN is set. Not running 'p4 submit'\n");
    }else{
        iprint("DRYRUN is NOT set. Would really do 'p4 submit' now.\n");
    }

## check number of input variables
    my $usage = "$0 defFile userUnits\n";
    if ( $#ARGV != 1 ) { die $usage; }

## welcome
    my $defFile   = $ARGV[0];
    my $userUnits = $ARGV[1];
    iprint(
        "Attempting to hack $defFile DEF file to convert UNITS=$userUnits\n");

## local vars
    my ( $defOrigFile, $origUnits, $unitRatio, %counts, $type );

## back-up original
    $defOrigFile = $defFile . '.orig';
    if ( !-e $defOrigFile ){
        copy $defFile, $defOrigFile
          or die "I/O copy $defFile to $defOrigFile failed\n.";
        iprint("Copying $defFile DEF file to $defOrigFile back-up DEF file.\n");
    }else{
        iprint(
            "  $defOrigFile backup DEF file exists. Skipping copy to back-up.\n"
        );
    }

## open LIB file and back-up
    my @origFileContents = read_file($defOrigFile,"Failed to open $defOrigFile back-up LIB file\n");
    my @outputContents;

## loop through orig DEF file
    foreach (shift @origFileContents) {
        ## find units
        if (
s/^(\s*UNITS\s+DISTANCE\s+MICRONS\s+)(\d+)(\s*\;\s*)$/$1$userUnits$3/
          )
        {
            $origUnits = $2;
            $unitRatio = $userUnits / $origUnits;
            iprint(
"Found $origUnits original units and calculated $unitRatio transform ratio\n"
            );
        }
        ## convert DIEAREA
        elsif (
/^\s*DIEAREA\s*\(\s*\-?\d+\s+\-?\d+\s*\)\s*\(\s*\-?\d+\s+\-?\d+\s*\)/
          )
        {
            if ( !defined $unitRatio ) {
                fprint("Found DIEAREA before UNITS, which is not supported\n");
            }
            else {
                if (
s/\(\s*(\-?\d+)\s+(\-?\d+)\s*\)/' ( '.($1*$unitRatio).' '.($2*$unitRatio).' )'/ge
                  )
                {
                    iprint("Converted DIEAREA by $unitRatio ratio\n");
                }
                else {
                    eprint("Transform failed on line $.: $_");
                    $counts{'ERROR TRANSFORM'}++;
                }
                if (s/\b(\-?\d+)\.(\d+)\b/$1/g) {
                    eprint(
"Resulting coordinates have a non-integer $1.$2 on line $., which we rounded down: $_"
                    );
                }
            }
        }
        ## convert COVER
        elsif (/\s*COVER\s*\(\s*\-?\d+\s+\-?\d+\s*\)\s*\w{1,2}\s*\;?\s*$/) {
            if ( !defined $unitRatio ) {
                fprint("Found COVER before UNITS, which is not supported\n");
            }
            else {
                if (
s/\(\s*(\-?\d+)\s+(\-?\d+)\s*\)/' ( '.($1*$unitRatio).' '.($2*$unitRatio).' )'/ge
                  )
                {
                    $counts{'cover'}++;
                }
                else {
                    eprint("Transform failed on line $.: $_");
                    $counts{'ERROR TRANSFORM'}++;
                }
                if (s/\b(\-?\d+)\.(\d+)\b/$1/g) {
                    eprint(
"Resulting coordinates have a non-integer $1.$2 on line $., which we rounded down: $_"
                    );
                }
            }
        }
        ## convert PLACED
        elsif (/\s*PLACED\s*\(\s*\-?\d+\s+\-?\d+\s*\)\s*\w{1,2}\s*\;?\s*$/) {
            if ( !defined $unitRatio ) {
                fprint("Found PLACED before UNITS, which is not supported\n");
            }
            else {
                if (
s/\(\s*(\-?\d+)\s+(\-?\d+)\s*\)/' ( '.($1*$unitRatio).' '.($2*$unitRatio).' )'/ge
                  )
                {
                    $counts{'placed'}++;
                }
                else {
                    eprint("Transform failed on line $.: $_");
                    $counts{'ERROR TRANSFORM'}++;
                }
                if (s/\b(\-?\d+)\.(\d+)\b/$1/g) {
                    eprint(
"resulting coordinates have a non-integer $1.$2 on line $., which we rounded down: $_"
                    );
                }
            }
        }
        ## convert PLACED
        elsif (/\s*PLACED\s*\(\s*\-?\d+\s+\-?\d+\s*\)\s*\;?\s*$/) {
            if ( !defined $unitRatio ) {
                fprint("Found PLACED before UNITS, which is not supported\n");
            }
            else {
                if (
s/\(\s*(\-?\d+)\s+(\-?\d+)\s*\)/' ( '.($1*$unitRatio).' '.($2*$unitRatio).' )'/ge
                  )
                {
                    $counts{'placed'}++;
                }
                else {
                    eprint("Transform failed on line $.: $_");
                    $counts{'ERROR TRANSFORM'}++;
                }
                if (s/\b(\-?\d+)\.(\d+)\b/$1/g) {
                    eprint(
"resulting coordinates have a non-integer $1.$2 on line $., which we rounded down: $_"
                    );
                }
            }
        }
        ## convert RECT
        elsif (
/\s*RECT\s+\S+\s*\(\s*\-?\d+\s+\-?\d+\s*\)\s*\(\s*\-?\d+\s+\-?\d+\s*\)\s*\;?\s*$/
            || /\s*RECT\s*\(\s*\-?\d+\s+\-?\d+\s*\)\s*\(\s*\-?\d+\s+\-?\d+\s*\)\s*\;?\s*$/
          )
        {
            if ( !defined $unitRatio ) {
                fprint("Found RECT before UNITS, which is not supported\n");
            }
            else {
                if (
s/\(\s*(\-?\d+)\s+(\-?\d+)\s*\)/' ( '.($1*$unitRatio).' '.($2*$unitRatio).' )'/ge
                  )
                {
                    $counts{'rect'}++;
                }
                else {
                    eprint("Transform failed on line $.: $_");
                    $counts{'ERROR TRANSFORM'}++;
                }
                if (s/\b(\-?\d+)\.(\d+)\b/$1/g) {
                    eprint(
"resulting coordinates have a non-integer $1.$2 on line $., which we rounded down: $_"
                    );
                }
            }
        }
        ## convert POLYGON
        elsif (/\s*POLYGON\s+\S+\s+\(\s*\-?\d+\s+\-?\d+\s*\)\s*/) {
            if ( !defined $unitRatio ) {
                fprint("Found POLYGON before UNITS, which is not supported\n");
            }
            else {
                if (
s/\(\s*(\-?\d+)\s+(\-?\d+)\s*\)/' ( '.($1*$unitRatio).' '.($2*$unitRatio).' )'/ge
                  )
                {
                    $counts{'polygon'}++;
                }
                else {
                    eprint("Transform failed on line $.: $_");
                    $counts{'ERROR TRANSFORM'}++;
                }
                if (s/\b(\-?\d+)\.(\d+)\b/$1/g) {
                    eprint(
"resulting coordinates have a non-integer $1.$2 on line $., which we rounded down: $_"
                    );
                }
            }
        }
        ## convert ROUTED
        elsif (/\s*ROUTED\s+\S+\s+\d+\s*\(\s*\-?\d+\s+\-?\d+\s*\)\s*/
            || /\s*ROUTED\s+\S+\s+\d+\s*\(\s*\-?\d+\s+\-?\d+\s+\-?\d+\s*\)\s*/ )
        {
            if ( !defined $unitRatio ) {
                fprint("Found ROUTED before UNITS, which is not supported\n");
            }
            else {
                if (
                    s/(ROUTED\s+\S+\s+)(\d+)/"$1".($2*$unitRatio)/e
                    && (
s/\(\s*(\-?\d+)\s+(\-?\d+)\s*\)/' ( '.($1*$unitRatio).' '.($2*$unitRatio).' )'/ge
                        || s/\(\s*(\-?\d+)\s+(\-?\d+)\s+(\-?\d+)\s*\)/' ( '.($1*$unitRatio).' '.($2*$unitRatio).' '.($3*$unitRatio).' )'/ge
                    )
                  )
                {
                    $counts{'routed'}++;
                }
                else {
                    eprint("Transform failed on line $.: $_");
                    $counts{'ERROR TRANSFORM'}++;
                }
                if (s/\b(\-?\d+)\.(\d+)\b/$1/g) {
                    eprint(
"resulting coordinates have a non-integer $1.$2 on line $., which we rounded down: $_"
                    );
                }
            }
        }
        ## convert NEW
        elsif (/\s*NEW\s+\S+\s+\d+\s*\(\s*\-?\d+\s+\-?\d+\s*\)\s*/
            || /\s*NEW\s+\S+\s+\d+\s*\(\s*\-?\d+\s+\-?\d+\s+\-?\d+\s*\)\s*/ )
        {
            if ( !defined $unitRatio ) {
                fprint("Found NEW before UNITS, which is not supported\n");
            }
            else {
                if (
                    s/(NEW\s+\S+\s+)(\d+)/"$1".($2*$unitRatio)/e
                    && (
s/\(\s*(\-?\d+)\s+(\-?\d+)\s*\)/' ( '.($1*$unitRatio).' '.($2*$unitRatio).' )'/ge
                        || s/\(\s*(\-?\d+)\s+(\-?\d+)\s+(\-?\d+)\s*\)/' ( '.($1*$unitRatio).' '.($2*$unitRatio).' '.($3*$unitRatio).' )'/ge
                    )
                  )
                {
                    $counts{'new'}++;
                }
                else {
                    eprint("Transform failed on line $.: $_");
                    $counts{'ERROR TRANSFORM'}++;
                }
                if (s/\b(\-?\d+)\.(\d+)\b/$1/g) {
                    eprint(
"resulting coordinates have a non-integer $1.$2 on line $., which we rounded down: $_"
                    );
                    $counts{'ERROR OFFGRID'}++;
                }
            }
        }
        elsif (/\(\s*\-?\d+\s+\-?\d+\s*\)/
            || /\(\s*\-?\d+\s+\-?\d+\s*\-?\d+\s*\)/ )
        {
            wprint("line with possible coordinates was not transformed: $_");
            $counts{'WARNING UNCHANGED POSSIBLE COORDS'}++;
        }
        ## print every line
        push(@outputContents, $_);
    } ## end foreach @origFileContents

    write_file( \@outputContents, $defFile);

    nprint( "  Transform summary:\n");
    foreach my $type ( sort keys %counts ) {
        nprint( "    $type = $counts{$type}\n");
    }

    ## All done
    nprint( "All done.\n");

}

sub usage($) {
    my $exit_status   = shift;
    my $message_text  = "$0 defFile userUnits";
    my $defFile_msg    = "def file";
    my $userUnits_msg  = " Type of Units for output";
    my $verbose_level = 1;                           ## The verbose level to use
    my $filehandle = \*STDERR;    ## The filehandle to write to

    pod2usage(
        {
            -message   => $message_text,
            -defFile   => $defFile_msg,
            -userUnits => $userUnits_msg,
            -exitval   => $exit_status,
            -verbose   => $verbose_level,
            -output    => $filehandle
        }
    );
}

#------------------------------------------------------------------------------
sub process_cmd_line_args() {
    my ( $opt_debug, $opt_verbosity, $opt_help, $opt_nousage, $opt_dryrun,
        $opt_example1_string, $opt_example2_string );
    my $status = GetOptions(
        "example1=s"  => \$opt_example1_string,
        "example2=s"  => \$opt_example2_string,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "nousage"     => \$opt_nousage,  # if enabled, skip logging usage data
        "dryrun!"     => \$opt_dryrun,   # do not run destructive p4 commands
        "help"        => \$opt_help,     # Prints help
    );

    $main::VERBOSITY = $opt_verbosity if ( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if ( defined $opt_debug );
    $main::TESTMODE = 1 if ( defined $opt_dryrun && $opt_dryrun );

    if ($opt_help) {
        usage(0);
    }
    if ( !$status ) {

        # Something went wrong with the parsing of ARGV
        usage(1);
    }

    return ($opt_nousage);
}
1;

__END__

=head1 NAME

ddr-defTransformCoords.pl

=head1 VERSION

2023.01

=head1 ABSTRACT

## Requires units field
##   UNITS DISTANCE MICRONS <units>
##
## Supports DEF file constructs:
##   DIEAREA ( <xunits> <yunits> ) ( <xunits> <yunits> ) ...
##   ... COVER ( <xunits> <yunits> ) DIR
##   ... PLACED ( <xunits> <yunits> ) DIR
##   ... RECT <layer> ( <xunits> <yunits> ) ( <xunits> <yunits> ) [;]
##   ... RECT ( <xunits> <yunits> ) ( <xunits> <yunits> ) [;]
##   ... ROUTED <layer> <width> ( <xunits> <yunits> [<extValue>] ) ( <xunits> <yunits> [<extValue>] ) ...
##   ... NEW <layer> <width> ( <xunits> <yunits> [<extValue>] ) ( <xunits> <yunits> [<extValue>] ) ...
##
## Fails for DEF file constructs:
##   + ( <xunits> <yunits> ) ...
##
## Flags all transformed units that are not integer

=head1 OPTIONS

=head2 ARGS

=over 8

=cut



