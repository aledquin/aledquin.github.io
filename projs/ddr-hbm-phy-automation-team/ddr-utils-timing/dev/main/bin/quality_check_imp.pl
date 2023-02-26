#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Data::Dumper ;
use Parse::Liberty;
use File::Find;
use List::MoreUtils qw(:all);
use List::MoreUtils qw{ uniq };
use Sort::Fields;
use List::Util qw( first );
use Scalar::Util qw{ looks_like_number };
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd;
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

#--------------------------------------------------------------------#
#our $std_err_LOG  = undef;     # undef       : Log msg to var => OFF
our $std_err_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.10';
#--------------------------------------------------------------------#

BEGIN { our $AUTHOR='IN08 Timing team'; header(); } 
&Main();
END {
   write_stdout_log( $LOGFILENAME );
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}


sub Main {
    my $opt_help;
    my $sis;
    my $nt;
    my $macro;
    my $lef;
    my $includearg;
    my $path;
    my $lvf;
    my $opt_debug;
    my $opt_verbosity;
    my $run = "sis";

    my @orig_argv = @ARGV;
    my $opt_nousage;
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    ($lvf, $sis, $nt, $macro, $lef, $path, $includearg,$opt_help,$opt_nousage) = process_cmd_line_args();
    unless( $opt_nousage or $main::DEBUG ) {
        utils__script_usage_statistics( "$PROGRAM_NAME", $main::VERSION, \@orig_argv );
    }

    my @includeList = ();
    if (defined $includearg) {
##  macro list is explicitely defined.
    @includeList = Tokenify($includearg);
}    
if ((grep{ /^1$/} @includeList) || (grep{ /all/} @includeList)) {
    iprint "###############1. alphaSummarizeNtWarnings.pl###############\n\n";    
    if(defined $nt) {$run = "nt";
        $run = "nt";
        unlink("$path/$macro/etm_timing_report.csv", "$path/$macro/internal_timing_report.csv");
        chdir "$path/$macro";
        iprint "Running command: alphaSummarizeNtWarnings.pl\n";
        my ($std_err0, $std_out0) = run_system_cmd("cd $path/$macro", $VERBOSITY);
        my ($std_err1, $std_out1) = run_system_cmd("alphaSummarizeNtWarnings.pl", $VERBOSITY); ## running command
#        eprint "$std_err1, $std_out1\n";
        eprint "$std_err1\n" if($std_out1 != 0);
        gprint "Run successful!\n" if ((-e "$path/$macro/etm_timing_report.csv") && (-e "$path/$macro/internal_timing_report.csv")); ## checks if correct log files are formed post run.
    } else { iprint "sis setup found. Skipping check alphaSummarizeNtWarnings.pl\n"; } ## script not run for sis macros
    nprint "\n";
}
if ((grep{ /^2$/} @includeList) || (grep{ /all/} @includeList)) {
#if (grep{ /^2$/} @includeList) {
    iprint "###############2. alphaCompileLibs.pl#######################\n\n";
    my ($std_err2, $std_out2) = run_system_cmd("rm -rf $path/$macro/quality_checks/alphaCompileLibs", $VERBOSITY);
    my ($std_err3, $std_out3) = run_system_cmd("mkdir -p $path/$macro/quality_checks/alphaCompileLibs", $VERBOSITY);
    
    #FOR NLDM
    if(!defined $lvf) {
        iprint "Runs are nldm.\n";
        chdir "$path/$macro/lib_pg";
        iprint "Running command: alphaCompileLibs.pl\n";
        my ($std_err5, $std_out5) = run_system_cmd("alphaCompileLibs.pl", $VERBOSITY);
        my ($std_err6, $std_out6) = run_system_cmd("cp $path/$macro/lib_pg/compile.log $path/$macro/quality_checks/alphaCompileLibs/compile.log", $VERBOSITY);
        eprint "$std_err5\n" if($std_out5 != 0);
        chdir "$path/$macro/lib";
        my ($std_err7, $std_out7) = run_system_cmd("alphaCompileLibs.pl", $VERBOSITY);
        my ($std_err8, $std_out8) = run_system_cmd("cat $path/$macro/lib/compile.log >> $path/$macro/quality_checks/alphaCompileLibs/compile.log", $VERBOSITY);
        eprint "$std_err7\n" if($std_out7 != 0);
        gprint "Run successful!\n" if ((-e "$path/$macro/quality_checks/alphaCompileLibs/compile.log") && ($std_out5 == 0) && ($std_out7 == 0));
    } else {
        iprint "Runs are lvf.\n";
        chdir "$path/$macro/lib_pg";
        iprint "Running command: alphaCompileLibs.pl -lvf\n";
        my ($std_err5, $std_out5) = run_system_cmd("alphaCompileLibs.pl -lvf", $VERBOSITY);
        eprint "$std_err5\n" if($std_out5 != 0);
        my ($std_err6, $std_out6) = run_system_cmd("cp $path/$macro/lib_pg/compile.log $path/$macro/quality_checks/alphaCompileLibs/compile.log", $VERBOSITY);
        chdir "$path/$macro/lib";
        my ($std_err7, $std_out7) = run_system_cmd("alphaCompileLibs.pl -lvf", $VERBOSITY);
        my ($std_err8, $std_out8) = run_system_cmd("cat $path/$macro/lib/compile.log >> $path/$macro/quality_checks/alphaCompileLibs/compile.log", $VERBOSITY);
        eprint "$std_err7\n" if($std_out7 != 0);
        gprint "Run successful!\n" if ((-e "$path/$macro/quality_checks/alphaCompileLibs/compile.log") && ($std_out5 == 0) && ($std_out7 == 0));
    } 
    nprint "\n";
}
if ((grep{ /^3$/} @includeList) || (grep{ /all/} @includeList)) {
#if (grep{ /^3$/} @includeList) {
    iprint "###############3. msip_hipreLibertyCheck####################\n\n";

        my ($std_err9, $std_out9) = run_system_cmd("rm -rf $path/$macro/quality_checks/msip_hipreLibertyCheck", $VERBOSITY);
        my ($std_err10, $std_out10) = run_system_cmd("mkdir -p $path/$macro/quality_checks/msip_hipreLibertyCheck", $VERBOSITY);
        chdir "$path/$macro/quality_checks/msip_hipreLibertyCheck";
#        `msip_hipreLibertyCheck -libFiles $path/$macro/lib_pg/*.lib -dbFiles $path/$macro/lib_pg/*.db -checkDuplicateAttributes -checkOperatingConditions -checkTiming -checkMaxCap -checkBusOrder -checkArc -checkDerate -checkPt`;
#        iprint "Running command: msip_hipreLibertyCheck -libFiles $path/$macro/lib_pg/*.lib -dbFiles $path/$macro/lib_pg/*.db -checkDuplicateAttributes -checkOperatingConditions -checkTiming -checkMaxCap -checkBusOrder -checkDerate -checkPt\n";
        iprint "Running command: msip_hipreLibertyCheck -libFiles $path/$macro/lib_pg/*.lib -dbFiles $path/$macro/lib_pg/*.db -checkDuplicateAttributes -checkOperatingConditions -checkTiming -checkMaxCap -checkBusOrder -checkDerate -checkPt\n";
        my ($std_err11, $std_out11) = run_system_cmd("msip_hipreLibertyCheck -libFiles $path/$macro/lib_pg/*.lib -dbFiles $path/$macro/lib_pg/*.db -checkDuplicateAttributes -checkOperatingConditions -checkTiming -checkMaxCap -checkBusOrder -checkDerate -checkPt", $VERBOSITY);
#        my ($std_err11, $std_out11) = run_system_cmd("msip_hipreLibertyCheck -libFiles $path/$macro/lib_pg/*.lib -dbFiles $path/$macro/lib_pg/*.db -all", $VERBOSITY);
        eprint "$std_err11\n" if($std_out11 != 0);
        gprint "Run successful!\n\n" if($std_out11 == 0); #if ((grep -d, glob("$path/$macro/quality_checks/msip_hipreLibertyCheck/*") && ($std_out11 == 0)));
        nprint "\n";
    }
    if ((grep{ /^4$/} @includeList) || (grep{ /all/} @includeList)) {
#    if (grep{ /^4$/} @includeList) {
    iprint "###############4. alphaLibCheckMonotonicSetupHold.pl########\n\n";
        my ($std_err12, $std_out12) = run_system_cmd("rm -rf $path/$macro/quality_checks/alphaLibCheckMonotonicSetupHold", $VERBOSITY);
        my ($std_err13, $std_out13) = run_system_cmd("mkdir -p $path/$macro/quality_checks/alphaLibCheckMonotonicSetupHold", $VERBOSITY);        
        chdir "$path/$macro/quality_checks/alphaLibCheckMonotonicSetupHold";
        iprint "Running command: alphaLibCheckMonotonicSetupHold.pl $path/$macro/lib_pg\n";
        my ($std_err14, $std_out14) = run_system_cmd("alphaLibCheckMonotonicSetupHold.pl $path/$macro/lib_pg", $VERBOSITY);
        gprint "Run successful!\n" if (($std_out14 == 0) && (-d "$path/$macro/quality_checks/alphaLibCheckMonotonicSetupHold/MONOTONICLOGS"));
#        gprint "Run successful!\n" if (-d "$path/$macro/quality_checks/alphaLibCheckMonotonicSetupHold/MONOTONICLOGS");
        nprint "\n";
    }
    if ((grep{ /^5$/} @includeList) || (grep{ /all/} @includeList)) {
#if (grep{ /^5$/} @includeList) {
    
        iprint "###############5. alphaPinCheck.pl##########################\n\n";
        if(defined $lef) {
        my ($std_err15, $std_out15) = run_system_cmd("rm -rf $path/$macro/quality_checks/alphaPinCheck", $VERBOSITY);
        my ($std_err16, $std_out16) = run_system_cmd("mkdir -p $path/$macro/quality_checks/alphaPinCheck", $VERBOSITY);
        chdir "$path/$macro/quality_checks/alphaPinCheck";
        iprint "Running command: alphaPinCheck.pl -macro $macro -lef $lef/$macro\_merged.lef -liberty $path/$macro/lib_pg/'*'.lib -libertynopg $path/$macro/lib/'*'.lib > $path/$macro/quality_checks/alphaPinCheck/pincheck.log\n";
        my ($std_err17, $std_out17) = run_system_cmd("alphaPinCheck.pl -macro $macro -lef $lef/$macro\_merged.lef -liberty $path/$macro/lib_pg/'*'.lib -libertynopg $path/$macro/lib/'*'.lib > $path/$macro/quality_checks/alphaPinCheck/pincheck.log", $VERBOSITY);
    } else { eprint "lef not mentioned.Skipping check\n"}
    nprint "\n";
    }
    if ((grep{ /^6$/} @includeList) || (grep{ /all/} @includeList)) {
#    if (grep{ /^6$/} @includeList) {
    iprint "###############6. tool_log.pl###############################\n\n";
    chdir "$path/$macro";
    iprint "Running command: tool_log.pl $path $macro $run\n";
    my ($std_err18, $std_out18) = run_system_cmd("tool_log.pl $path $macro $run", $VERBOSITY);
    eprint "$std_err18\n" if ($std_out18 != 0);
    gprint "Run successful!\n" if (($std_out18 == 0) && (-d "$path/$macro/grep_result"));
    nprint "\n";
}
if ((grep{ /^7$/} @includeList) || (grep{ /all/} @includeList)) {
#if (grep{ /^7$/} @includeList) {
    iprint "###############7. msip_grep.pl##############################\n\n";
    chdir "$path/$macro";
    iprint "Running command: msip_grep.pl\n";
    my ($std_err19, $std_out19) = run_system_cmd("msip_grep.pl", $VERBOSITY);
    eprint "$std_err19\n" if ($std_out19 != 0);
    gprint "Run successful!\n" if (($std_out19 == 0) && (-d "$path/$macro/msip_grep"));
    nprint "\n";
}
if ((grep{ /^8$/} @includeList) || (grep{ /all/} @includeList)) {
#if (grep{ /^8$/} @includeList) {
    iprint "###############8. pin_check.pl##############################\n\n";
    chdir "$path/$macro";
    iprint "Running command: pin_check.pl $run $macro setup\n";
    my ($std_err20, $std_out20) = run_system_cmd("pin_check.pl $run $macro setup", $VERBOSITY);
    eprint "$std_err20" if ($std_out20 != 0);
    gprint "Run successful!\n" if ($std_out20 == 0);
    iprint "Running command: pin_check.pl $run $macro lib\n";
    my ($std_err21, $std_out21) = run_system_cmd("pin_check.pl $run $macro lib", $VERBOSITY);
    eprint "$std_err21\n" if ($std_out21 != 0);
    gprint "Run successful!\n" if ($std_out21 == 0);
    iprint "Running command: pin_check.pl $run $macro subckt\n";
    my ($std_err22, $std_out22) = run_system_cmd("pin_check.pl $run $macro subckt", $VERBOSITY);
    eprint "$std_err22\n" if ($std_out22 != 0);
    gprint "Run successful!\n" if ($std_out22 == 0);
    nprint "\n";
}
if ((grep{ /^9$/} @includeList) || (grep{ /all/} @includeList)) {
    iprint "###############9. lvf_qa.pl#################################\n\n";
    chdir "$path/$macro";
    iprint "Running command: lvf_qa.pl $path $macro $run\n";
    my ($std_err23, $std_out23) = run_system_cmd("lvf_qa.pl $path $macro $run", $VERBOSITY);
    eprint "$std_err23\n" if ($std_out23 != 0);
    gprint "Run successful!\n" if (($std_out23 == 0) && (-d "$path/$macro/LVF_REPORT"));
    nprint "\n";
}
if ((grep{ /^10$/} @includeList) || (grep{ /all/} @includeList)) {
    iprint "###############10. getSetupHold_worst_slack.pl##############\n\n";
    iprint "Running command: getSetupHold_worst_slack.pl timing -csv\n";
    chdir "$path/$macro";
    my ($std_err24, $std_out24) = run_system_cmd("getSetupHold_worst_slack.pl timing -csv", $VERBOSITY);
    eprint "$std_err24\n" if ($std_out24 != 0);
    gprint "Run successful!\n" if (($std_out24 == 0) && (-e "$path/$macro/WorstHold.csv") && (-e "$path/$macro/WorstSetup.csv"));
#    nprint "\n";
}
}


sub Tokenify
{
    my $line = shift;
    $line =~ s/^\s*(.*)\s+$/$1/;
    return split(/\s+/, $line);
}


sub print_usage($$) {
    my $script_path = shift;
    my $status      = shift;
    iprint << "EOP" ;
Description

USAGE : $PROGRAM_NAME [options] -path <arg> -macro <arg> -nt -lvf -include <arg>

------------------------------------
Required Args:
------------------------------------
-macro    <arg>  
-path     <arg>
-sis|nt
-lvf
-include <arg>
------------------------------------
Optional Args:
------------------------------------
-help             iprint this screen
-verbosity  <#>    iprint additional messages ... includes details of system calls etc. 
                   Must provide integer argument -> higher values increases verbosity.
-debug      <#>    iprint additional diagnostic messagess to debug script
                   Must provide integer argument -> higher values increases messages.
------------------------------------------
The script runs following checks in order:
1)  alphaSummarizeNtWarnings.pl
2)  alphaCompileLibs.pl
3)  msip_hipreLibertyCheck
4)  alphaLibCheckMonotonicSetupHold.pl
5)  alphaPinCheck.pl
6)  tool_log.pl
7)  msip_grep.pl
8)  pin_check.pl
9)  lvf_qa.pl
10) getSetupHold_worst_slack.pl
------------------------------------------
EOP

    pod2usage({
            -pathlist => "$RealBin",
            -exitval => $status,
            -verbose => 1 });
}


sub process_cmd_line_args(){
    my ( $opt_lvf, $opt_sis, $opt_nt, $opt_macro, $opt_lef, $opt_path, $opt_includearg,
         $opt_help, $opt_nousage, $opt_dryrun, $opt_debug, $opt_verbosity );

    my $success = GetOptions(
        "lvf"         => \$opt_lvf,
        "sis"         => \$opt_sis,
        "nt"          => \$opt_nt,
        "macro=s"     => \$opt_macro,
        "lef=s"       => \$opt_lef,
        "path=s"      => \$opt_path,
        "include=s"   => \$opt_includearg,
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
   return( $opt_lvf, $opt_sis, $opt_nt, $opt_macro, $opt_lef, $opt_path, $opt_includearg,$opt_help,$opt_nousage );
};
