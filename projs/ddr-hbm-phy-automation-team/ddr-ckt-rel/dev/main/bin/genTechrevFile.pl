#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Cwd;
use Carp;
use File::Spec::Functions qw/catfile/;
use Devel::StackTrace;
use Getopt::Std;
use Cwd;
use Term::ANSIColor;
use Getopt::Long;
use Capture::Tiny qw/capture/;

use File::Basename qw(basename);
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#

BEGIN{
    our $AUTHOR='ljames';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
    &Main();
END {
    footer();
    write_stdout_log( $LOGFILENAME );
    local $?;   # to prevent the exit() status from getting modified
 }


############################## Main function ##################################
sub Main {
    my @orig_argv = @ARGV;   # keep this here cause GetOpts modifies ARGV

    my ($help, $cdl, $ckt, $usage, $output, $opt_debug, $opt_nousage, 
        $opt_verbosity, $opt_testmode);
    my $status = GetOptions(
        "help|h"      => \$help,
        "cdl=s"       => \$cdl,
        "ckt=s"       => \$ckt,
        "output=s"    => \$output,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "nousage"     => \$opt_nousage,
        "testmode"    => \$opt_testmode
    );
    $usage = <<END
Description:
  A Script to read CDL netlist and generate a techrevision.v file with a 16 bit number.
  techrevision.v file is useful for a customer to read to ensure that the silicon they have is what we would expect to be.
  CKT controls techrevision files entirely and does not need to check with any other team (any more).

Usage:
  genTechrevFile.pl -cdl <cdlFile> [-ckt <cktName>] [-output <outputfile>]

Required Args:
  -cdl <cdlFile>            CDL circuit netlist.
                            Full path to .cdl file is required.

Optional Args:
  -help                     Print this screen.
  -ckt       <cktName>      If this argument is not included, ckt name will default to the same as the one in the .cdl file name.
  -output    <outputFile>   Full path to .v file is required.
                            This argument requires that the techrevision.v file in p4 client's view is checked out as 
                            it will modify the content of file.
                            If this argument is not included:
                            - the output file name will default to techrevision.v
                            - the output file will be created in the user's current directory
  -debug     <#>            Print additional diagnostic messages to debug script.
                            Must provide integer argument -> higher values increases messages.
                            Do not call usage statistics function.
  -verbosity <#>            Print additional messages ... includes details of system calls etc. 
                            Must provide integer argument -> higher values increases verbosity.
  -nousage                  Do not call usage statistics function.

Outputs:
  .v techrevision file      The file contains only one line: `define <cktName> 16'bxxxxxx_xxxxx_xxxxx


END
;
    $DEBUG     = $opt_debug     if( defined($opt_debug));
    $VERBOSITY = $opt_verbosity if( defined($opt_verbosity));
    $TESTMODE  = 1              if( defined($opt_testmode));

    if($help ){
        nprint $usage;
        nprint "\n";
        exit(0);
    }
    if (! defined $cdl){ 
        eprint("Missing required option: -cdl\n");
        nprint $usage;
        nprint "\n";
        exit(1);
    }
    if(!defined($ckt)) { 
        $ckt = basename($cdl);
        $ckt =~ s/\.cdl//;
    }
    if(!defined($output)){ 
        $output = "./techrevision.v"; 
        iprint("Defaulting -output to $output\n");
    }
    unless( $DEBUG || $opt_nousage ) {
        utils__script_usage_statistics( $RealScript, $VERSION, \@orig_argv);
    }
    my $subckt = _getSubckt($cdl, $ckt);
    dprint(LOW, "_getSubckt('$cdl', '$ckt') => $subckt\n");
    $ckt       = uc($ckt);
    $ckt       =~ s/TECHREVISION/TECH_REVISION/g; # Jira P10020416-39365
    my $bitNum = _genBits($subckt);

    my $line = "\`define $ckt 16'b$bitNum";
    viprint(LOW, "Writing to '$output':\n\t'$line'\n" );
    write_file( $line, $output );

    viprint(LOW, "Exit successfully\n");
    exit(0);  ## 0 means success
}

############################## Common functions ###############################

#-----------------------------------------------------------------
#  Get required subckt
#-----------------------------------------------------------------
sub _getSubckt($$) {
    print_function_header();
    my $fname_cdl = shift;
    my $inCkt     = shift;

    if ( $main::DEBUG >= MEDIUM ) {
        my @cdl = read_file( $fname_cdl );
        foreach my $line (@cdl) {
            chomp $line;
            dprint(MEDIUM, "line:'$line'\n");
        }
    }

#    my $joinedStuff = do {local $/, read_file($fname_cdl) };
    my $joinedStuff = join $/, read_file($fname_cdl);
    dprint(HIGH, "joinedStuff='$joinedStuff'\n");
    
    my $mod = ".subckt";
    if($joinedStuff =~ m/($mod $inCkt (.*?)^\.ends)/sm) {
        dprint(LOW, "_getSubckt is returning '$1'\n");
        return $1;
    }else{
        dprint(LOW, "_getSubckt is returning EMPTY_STR\n");
        return EMPTY_STR;
    }
}

sub _genBits($) {
    print_function_header();
    my @subckt = split(/\n/,$_[0]);

    my @bits;
    foreach my $line (@subckt) {
        next if($line =~ /^\*|^\#/);
        my ($bitIdx, $bitVal) = ($line =~ /\[([0-9]+)\]\s.*_tie([a-z]+)/i);
        next if(!defined($bitIdx) || $bitIdx eq "" || $bitVal eq "");
        $bitVal = ($bitVal eq 'high') ? 1:0;
        $bits[$bitIdx] = $bitVal;
    }
    return join "",reverse(@bits);    
}
