#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd;
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Pod::Usage;

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $PREFIX       = "ddr-utils-timing";
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#

use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

BEGIN { our $AUTHOR='IN08 Timing team'; header(); } 
&Main();
END {
   write_stdout_log("$LOGFILENAME");
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}

sub Main {
my $tech = $ARGV[1];
my $cell_name;
my @orig_argv = @ARGV;
    my $opt_nousage;
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    my $opt_help = "";
    ($opt_nousage) = process_cmd_line_args();
    unless( $opt_nousage or $main::DEBUG ) {
        utils__script_usage_statistics( "$PROGRAM_NAME", $main::VERSION, \@orig_argv );
    }
    my @run_mc = ();
    run_system_cmd("mkdir MonteCarlo", "$VERBOSITY");

run_system_cmd("cp /proj/pllctp/devel_cfalking/development/$tech/PLL0/analysis/$cell_name/derived/hspice/$cell_name.net.flat netlist_pre.spf", "$VERBOSITY");

##link post layout extracted netlists
#if ($tech eq "TSMC16FF") {
#	run_system_cmd("cp /proj/pllctp/devel_cfalking/development/$tech/PLL0/analysis/$cell_name/derived/spf/TSMC16FFplus_1P11M2XA1XD3XE2Y2R/$cell_name.blackbox_nominal.dspf.gz netlist_RCtyp.spf.gz", "$VERBOSITY");
#	run_system_cmd("cp /proj/pllctp/devel_cfalking/development/$tech/PLL0/analysis/$cell_name/derived/spf/TSMC16FFplus_1P11M2XA1XD3XE2Y2R/$cell_name.blackbox_rcworst.dspf.gz netlist_RCmax.spf.gz", "$VERBOSITY");
#	run_system_cmd("cp /proj/pllctp/devel_cfalking/development/$tech/PLL0/analysis/$cell_name/derived/spf/TSMC16FFplus_1P11M2XA1XD3XE2Y2R/$cell_name.blackbox_rcbest.dspf.gz netlist_RCmin.spf.gz", "$VERBOSITY");
#} else {
#	run_system_cmd("cp /proj/pllctp/devel_cfalking/development/$tech/PLL0/analysis/$cell_name/derived/spf/GF14LPE_11M_3Mx_4Cx_2Kx_2Gx_LB/$cell_name.blackbox_nominal.dspf.gz netlist_RCtyp.spf.gz", "$VERBOSITY");
#	run_system_cmd("cp /proj/pllctp/devel_cfalking/development/$tech/PLL0/analysis/$cell_name/derived/spf/GF14LPE_11M_3Mx_4Cx_2Kx_2Gx_LB/$cell_name.blackbox_FuncRCmax.dspf.gz netlist_RCmax.spf.gz", "$VERBOSITY");
#	run_system_cmd("cp /proj/pllctp/devel_cfalking/development/$tech/PLL0/analysis/$cell_name/derived/spf/GF14LPE_11M_3Mx_4Cx_2Kx_2Gx_LB/$cell_name.blackbox_FuncRCmin.dspf.gz netlist_RCmax.spf.gz", "$VERBOSITY");
#}
#run_system_cmd("gunzip *.gz", "$VERBOSITY");
#}
}

sub print_usage {
    my $exit_status = shift;
    my $ScriptPath = shift;
    my $message_text = "Current script path:  $ScriptPath\n";
     pod2usage({
        -message => $message_text ,
        -exitval => $exit_status,
        -verbose => 0,
        }
    );
}

sub process_cmd_line_args() {
    my ( $opt_help, $opt_nousage, $opt_dryrun, 
         $opt_debug,  $opt_verbosity );

    my $success = GetOptions(
        "help"        => \$opt_help,           # Prints help
        "nousage"     => \$opt_nousage,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "dryrun!"     => \$opt_dryrun,
     );

    if((defined $opt_dryrun) && ($opt_dryrun == 1)){
        $main::TESTMODE = TRUE;
    }

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    &print_usage(0, "$RealBin/$PROGRAM_NAME") if $opt_help;
    &print_usage(1, "$RealBin/$PROGRAM_NAME") unless( $success );
    #&usage(1) unless( defined $opt_projSPEC );
   return( $opt_nousage );
};
