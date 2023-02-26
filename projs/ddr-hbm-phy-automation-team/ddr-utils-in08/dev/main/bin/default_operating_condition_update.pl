#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use Getopt::Long;

#Usage Tracking Utilities.
use lib "$RealBin/../lib/perl/";
#use utilities;
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Carp qw{ confess };
use Cwd;

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11'; 
#--------------------------------------------------------------------#



BEGIN{ our $AUTHOR = 'ddr-da-team'; header(); }
&Main();
END {
    local $?;   ## adding this will pass the status of failure if the script
                ## does not compile; otherwise this will always return 0
    write_stdout_log("$LOGFILENAME");
    footer();
}


#-----------------------------------------------------------
sub Main(){

    my @orig_argv = @ARGV;
    my $opt_input = process_cmd_line_args();

    unless( $main::DEBUG ){
        utils__script_usage_statistics( $RealScript, $VERSION, \@orig_argv);
    }

    my $outdir = 'finallib';
    mkdir $outdir unless -d $outdir;

    my @split_inputfile = split(/\//, $opt_input);
    my $output_file = "$outdir/" . $split_inputfile[-1];

    my @out;
    my @lines = read_file($opt_input);
    iprint( "Searching for operation conditions in file: '$opt_input' \n" );
    foreach my $iline ( @lines ){
        push(@out, $iline);
        if ( $iline =~ /^ ( \s* ) operating_conditions \s* \( \s* ( .* ) \s* \) \s* { \s* $/x ) {
            my ( $leading_space, $operating_cond ) = ( $1, $2 );
            until ( $iline =~ /^ \s* } \s* ( .* ) $/x ) {
                $iline = shift(@lines);
                push(@out, $iline);
            }
            push(@out, "${leading_space}default_operating_conditions : $operating_cond ;\n");
        }
    }

    write_file(\@out, $output_file);

    exit(0);
}  ## END Main()

#-----------------------------------------------------------
sub Tokenify
{
    ## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = shift;
    $line =~ s/^\s*(.*)\s+$/$1/;
    return split(/\s+/, $line);
}

#------------------------------------------------------------------------------
sub process_cmd_line_args() {
    ## get specified args
    my($opt_input, $opt_help, $opt_debug, $opt_verbosity);

    my $success = GetOptions(
       "help!"       => \$opt_help,
       "input=s"     => \$opt_input,
       "debug=i"     => \$opt_debug,
       "verbosity=i" => \$opt_verbosity,
    );

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );

    ## quit with usage message, if usage not satisfied
    &usage(0) if( $opt_help );
    &usage(1) unless( $success );
    &usage(1) unless( defined $opt_input );

    return( $opt_input );
}

#------------------------------------------------------------------------------
#  script usage message
#------------------------------------------------------------------------------
sub usage($) {
    my $exit_status = shift;

    print << "EOP" ;
Description

USAGE : $PROGRAM_NAME [options] -input <FILE>

------------------------------------
Required Args:
------------------------------------
-input  <FILE>    input file


------------------------------------
Optional Args:
------------------------------------
-help              Print this screen
-verbosity  <#>    print additional messages ... includes details of system calls etc. 
                   Must provide integer argument -> higher values increases verbosity.
-debug      <#>    print additional diagnostic messagess to debug script
                   Must provide integer argument -> higher values increases messages.
EOP

    exit $exit_status ;
} # usage()

1;
