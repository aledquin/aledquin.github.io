#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Cwd     qw(getcwd);
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use Getopt::Std;
use Getopt::Long;
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

our $STDOUT_LOG   = undef; 
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $AUTO_APPEND_NEWLINE = 1;
my $DDR_DA_DEFAULT_P4WS = "p4_func_tests";

&Main();

sub Main(){
    my $USER            = $ENV{'USER'};
    my $PerlScriptName  = "<SCRIPT-NAME>";
    my $PerlScriptExe   = "$RealBin/../../bin/${PerlScriptName}" ;
    my $Product         = "lpddr5x";
    my $Project         = "d931-lpddr5x-tsmc3eff-12";
    my $Macro           = "dwc_lpddr5xphy_ato_ew";
    my $Release         = "rel1.00_cktpcs";
    my $WorkSpace       = $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;
    my @generated_files = ( "$RealScript.log" );
    my $opt_cleanup     = 1;

    ($WorkSpace, $opt_cleanup) = get_options( $WorkSpace );

    my $ScriptArgs     = "-p4ws ${WorkSpace} ${Product}/${Project}/${Release} -macros ${Macro}" ;

    if ( ! -e $PerlScriptExe ){ 
        fatal_error( "Unable to locate script '$PerlScriptExe'!" );
    }

    my ($stdout, $status) = run_system_cmd("$PerlScriptExe ${ScriptArgs}", 
        $VERBOSITY);
    print $stdout;
    if ($status != 0){ 
        fatal_error "FAILED $PerlScriptName"    ;
    }

    if ( $stdout =~ m/Error|-E-|-F-/i ){
        fatal_error("FAILED $PerlScriptName") ;
    }
    # Check for any error messages in the output
    my $remove_logs = "ok" ;
    if ( $stdout =~ m/uninitialized/i ){
        wprint "There are some instances of 'Use of uninitialized value' in the output" ;
        $remove_logs="no" ;
    }

    # clean up logs
    if ( $remove_logs eq "ok"){ 
        if ( $opt_cleanup ) {
            iprint "CLEANING UP" ;
            foreach my $dirty ( @generated_files ) {
                if ( -e $dirty){ 
                    unlink $dirty;
                }
            }
        }
    }

    iprint "PASSED $PerlScriptName\n";
    exit 0;
}

sub get_options($) {
    my $opt_help       = 0;
    my $opt_debug      = 0;
    my $opt_verbosity  = 0;
    my $opt_cleanup    = 1;
    my $opt_workspace  = shift;

    my $get_status = GetOptions(
        "help"        => \$opt_help,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "cleanup!"      => \$opt_cleanup,
        "p4ws=s"      => \$opt_workspace,
    );
    if ( $opt_help ){
        display_help();
        exit(0);
    }
    $main::VERBOSITY = $opt_verbosity if ( $opt_verbosity );
    $main::DEBUG     = $opt_debug     if ( $opt_debug );

    return ($opt_workspace, $opt_cleanup);
}

sub display_help(){
    print("Usage:\n\n");
    print("\t$RealScript [-debug #] [-verbosity #] [-help]\n");
    print("\t    [-p4ws PATH] -[no]cleanup\n");
    print("\nDefaults:\n\n");
    print("\t-debug     0\n");
    print("\t-verbosity 0\n");
    print("\t-nohelp\n");
    print("\t-p4ws      '$DDR_DA_DEFAULT_P4WS'\n");
    print("\t-cleanup\n");
    return;
}

