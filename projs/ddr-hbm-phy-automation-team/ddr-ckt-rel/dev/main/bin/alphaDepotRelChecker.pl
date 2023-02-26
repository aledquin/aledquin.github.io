#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Cwd;
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
#use alphaHLDepotRelease;

#---- GLOBAL VARs------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG      = NONE;
our $VERBOSITY  = NONE;
our $TESTMODE   = NONE;
#----------------------------------#
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version();
my  $USERNAME     = get_username();
our %globals; 
#----------------------------------#


BEGIN {
    our $AUTHOR='bchalla, juliano';
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
END {
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer();
   write_stdout_log( $LOGFILENAME );
 }

######################################### Main function ############################################
sub Main {

    my ($opt_help, $opt_config,    $opt_rel, $opt_debug, 
        $opt_log,  $opt_verbosity, $nousage, $opt_dryrun);
    my @orig_args = @ARGV; # keep this here cause GetOpts modifies ARGV

    my $status = GetOptions(
        "cfg=s"       =>   \$opt_config,    #config file    
        "rel=s"       =>   \$opt_rel,       #release file
        "log=s"       =>   \$opt_log,       #custom log
        "debug=i"     =>   \$opt_debug,     #debug level
        "verbosity=i" =>   \$opt_verbosity, #verbosity level
        "nousage"     =>   \$nousage,       #do not report the use of this script
        "dryrun"      =>   \$opt_dryrun,    #enable testmode
        "help|h"      =>   \$opt_help,      #help 
    );

    $main::VERBOSITY = $opt_verbosity if ( defined $opt_verbosity);
    $main::DEBUG     = $opt_debug     if ( defined $opt_debug );
    $main::TESTMODE  = 1              if ( defined $opt_dryrun && $opt_dryrun );

    &usage(0) if( defined $opt_help );

    my $required_missing=0;

    if( !defined $opt_config || $opt_config eq ""){
        eprint( "Missing required argument. -cfg\n");
        $required_missing = 1;
    }

    if( !defined $opt_rel || $opt_rel eq ""){
        eprint( "Missing required argument. -rel\n");
        $required_missing = 1;
    }

    &usage(1) if ( $required_missing );
    
    unless( $main::DEBUG || $nousage) {
        utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@orig_args); 
    }

    #
    # Build some options that are optional to be used in run_system_cmd
    #
    my $verbosity_opt = "";
    my $debug_opt     = "";
    my $log_opt       = "";

    $verbosity_opt = "-verbosity $main::VERBOSITY" if(defined $opt_verbosity);
    $debug_opt     = "-debug $main::DEBUG"         if(defined $opt_debug);
    $log_opt       = "-log \"$opt_log\""           if(defined $opt_log);

    # 
    # Run the tools
    #
    my $gen_bom_tool   = "gen_bom.pl";
    my $inspector_tool = "inspector.pl";

    my $cmd = "module unload bom-checker;";
    $cmd .= "module load bom-checker;";
    
    $cmd .= "$gen_bom_tool -cfg '$opt_config' -nousage";

    my ($stdout, $val) = run_system_cmd($cmd, $VERBOSITY);
    if ( $val != 0 ) {
        wprint("$PROGRAM_NAME call to '$gen_bom_tool' returned non-success status='$val'");
        wprint($stdout);
    }

    #
    # Now run the inspector.pl tool
    # 
    $cmd = "$inspector_tool -cfg \"$opt_config\" -rel \"$opt_rel\" $log_opt $debug_opt -nousage $verbosity_opt";

    ($stdout, $val)= run_system_cmd($cmd, $VERBOSITY); 
    iprint($stdout);

    exit($val); # 0 means success, other value means failure
}

######################################### Common functions #########################################
sub usage($) {
    my $status = shift;
    my $msg = <<HERE
USAGE:  $PROGRAM_NAME -cfg <config_file> -rel <release file>

Please make sure that you throw quotes around filenames, espcially ones that
contain dashes in their name.

Optional Args : 
    -log <filename>     Custom Logfile
    -v <#>              Verbosity level
    -nousage            Do not report script usage information
    -dryrun             Avoid doing anything that would change the environment
    -debug <#>          Debug messaging level 
    -verbosity <#>      Messaging berbosity level 
    -help               Show this USAGE message

Example: $PROGRAM_NAME -cfg "lp54-ckt-bom.cfg" -rel "d850_rel.txt" -debug 2 
HERE
;

    exit $status;
}

