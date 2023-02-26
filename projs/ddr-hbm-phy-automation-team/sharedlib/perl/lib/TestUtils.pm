package TestUtils;
#
# NOTE: This perl module should reside in the lib folder under the
#       test area. The test area is TOOL/dev/main/t/ 
#
#
# nolint [Modules::ProhibitAutomaticExportation]
use strict;
use warnings;

use Getopt::Std;
use Getopt::Long;
use Cwd     qw( abs_path );

use FindBin qw($RealBin $RealScript);
use lib "$RealBin/.";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;
#use lib "$RealBin/";
use Comparator;

use Exporter;

our @ISA    = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT = qw(
         getScriptExe
         test_scripts__get_options
         test_scripts__check_for_errs
         test_scripts__cleanup
         test_scripts__main
         test_createPerlCoveragePrefix
);

#-----------------------------------------------------------------------------
sub is_python_script($){
    my $script = shift;
    return TRUE if ( $script =~ m/\.py$/ );
    return FALSE;
}

#-----------------------------------------------------------------------------
# Returns ( $nerrors, $stdout, $script_status )
#
sub test_scripts__main{
    my $testNumber  = shift;
    my $opt_cleanup = shift;
    my $opt_coverage= shift;
    my $testScript  = shift;
    my $testDataDir = shift;
    my $scriptDir   = shift;
    my $scriptName  = shift;
    my $cmdline_args= shift;
    my $workspace   = shift;
    my $func_compare= shift;
    my $func_user_data = shift;

    my $diffTheFiles    = $ENV{'DDR_DA_COMPARATOR_DIFF'};
    my @generated_files = ( "$testScript.log" );
    my $USER            = $ENV{'USER'};
    my $scriptExe       = "${scriptDir}/${scriptName}" ;
    #---------------------------------------------------------------------------
    # Default behavior is to use the scriptDir/scriptName passed to the sub.
    #     However, sometimes, rather than use the scripts from the clone  of
    #     the Git repo, need to test the actual release (beta, production, etc).
    #---------------------------------------------------------------------------
    if( $ENV{LOADEDMODULES} =~ m/ddr-ckt-rel/ ){
        wprint( "Found ddr-ckt-rel in the modules loaded into the ENV.\n" );
        $scriptExe = "${scriptName}" ;
        ($scriptExe, undef) = run_system_cmd( "which ${scriptName}" );
        chomp($scriptExe);
        eprint( "Over-riding script path...using ENV defaults: \n\t '$scriptExe'.\n" );
        #prompt_before_continue( NONE );
    }
    # Override the script path based on an env variable.
    $scriptExe = getScriptExe( $scriptName, $scriptExe );

    if ( ! -e $scriptExe ){ 
        eprint( "Unable to locate script '$scriptExe'!" );
        return (-1,"",-1);
    }

    my $coveragePrefix = "";
    if ( $opt_coverage ) {
        if ( is_python_script($scriptName) ) {
            my $cappend = "";
            $cappend = " -a " if ( $testNumber > 1);
            $coveragePrefix = "/depot/Python/Python-3.8.0/bin/coverage run $cappend";
        } else {
            if ( ! exists $ENV{'DDR_DA_COVERAGE'} ) {
                wprint("The -coverage option was used but the env var DDR_DA_COVERAGE is missing!");
                iprint("You should \n\tsetenv DDR_DA_COVERAGE 1\n\tsetenv DDR_DA_COVERAGE_DB database_filename\n");
            }

            $coveragePrefix = test_createPerlCoveragePrefix($opt_coverage);
        }
    }
    my ($stdout, $status) = run_system_cmd("${coveragePrefix}$scriptExe ${cmdline_args}", 
        $main::VERBOSITY);
    viprint(LOW, $stdout);
    my $nerrors = test_scripts__check_for_errs( $stdout, $status, $scriptName );
    if ( $nerrors ){
        dprint(MEDIUM, "Got errors=$nerrors calling test_scripts__check_for_errs\n");
        return (-1 * $nerrors, $stdout, $status);
    }

    # Check for any uninitialized messages in the output
    my $remove_logs = "ok" ;
    if ( $stdout =~ m/uninitialized/i ){
        wprint "There are some instances of 'Use of uninitialized value' in the output" ;
        $remove_logs="no" ;
        my @lines = split('\n',$stdout);
        foreach my $line ( @lines) {
            chomp $line;
            if ( $line =~ m/uninitialized/i ){
                print("$line\n");
            }
        }
    }

    ##
    ##  COMPARATOR Logic Here
    ##
    my $p4ws="";
    if ( $func_compare ) {
        $nerrors = $func_compare->($workspace, $testDataDir, $testScript, $testNumber, $func_user_data);
        $p4ws = $workspace if ( $workspace);
    }else{
        $p4ws="";
        if( defined $workspace ){ $p4ws = abs_path("/u/$USER/$workspace"); }
        $nerrors = comparator( $p4ws,
            $testDataDir, $testScript,
            $testNumber, $diffTheFiles); 
    }

    if ( $nerrors > 0 ) {
        eprint( "FAILED ${testScript}_${testNumber} comparator stage with '$nerrors' errors. Using p4ws='$p4ws'\n" );
        dprint(MEDIUM, "TestUtils: Got errors=$nerrors calling comparator with p4ws='$p4ws'\n");
        return (-1, $stdout, $status);
    } else {
        viprint(LOW, "${testScript}_${testNumber} comparator stage passed with p4ws='$p4ws'.\n" );
    }

    # clean up logs
    if ( $remove_logs eq "ok" && $opt_cleanup ) {
        test_scripts__cleanup( @generated_files );
    }

    return (0, $stdout, $status);
}

 
#-----------------------------------------------------------------------------
sub test_scripts__cleanup{
    my @files = @_;

    viprint(LOW, "CLEANING UP" );
    foreach my $dirty ( @files ) {
        if ( -e $dirty){ 
            unlink $dirty;
        }
    }
    return( TRUE );
}
 
#-----------------------------------------------------------------------------
# used by the functional test scripts named test_${script_to_test}_##.pl
# returns the number of errors found
#-----------------------------------------------------------------------------
sub test_scripts__check_for_errs{
    my $stdout = shift;
    my $status = shift;
    my $script = shift;

    if ($status != 0){ 
        dprint(LOW , "return val $status ... FAILED $script\n" );
        return( 1 );
    }

    #
    # At this point, the script itself returned success and not a failure.
    # But, we want to look at the output of the script that was generated
    # and see if we find any lines of text that look like they could be an
    # error.
    #

    my @linesOfStdOut = split('\n', $stdout);
    my $lineNo=0;
    my $foundErr=0;
    foreach my $line ( @linesOfStdOut ) {
        $lineNo++;
        next if ( $line =~ m/^-I-/); # in case the -I- has word ERROR in it
        next if ( $line =~ m/^-W-/); # in case the -W- has word ERROR in it

        if ( $line =~ m/ERROR\s+|-E-|-F-/ ){
            $foundErr ++;
            dprint(LOW , "Found an error message on line $lineNo\t$line\n");
        }

        if ( $line =~ m/uninitialized value/) {
            $foundErr ++;
            dprint(LOW , "Found a problem with uninitialized value $lineNo\t$line\n");
        }

        if ( $line =~ m/Global symbol .* requires explicit package/) {
            $foundErr ++;
            dprint(LOW , "Found a problem with Global variables $lineNo\t$line\n");
        }
   }

    return( $foundErr );
}

#+
# Subroutine Name:
#
#   getScriptExe
#
# Purpose:
#
#   This function determines the full path to the script that you wish
#   to run. If a special env variable is defined, then it will assume
#   that you have done a 'module load TOOLNAME' and that the script can
#   be found by doing a unix 'which SCRIPT' command.
#
# Arguments:
#
#  PerlScriptName:
#       The name of the script you are looking for. (eg. alphaHLDepotSeed)
#       This should include the script's extension (if it has one).
#
#  PerlScriptExe:
#       The default path to the script file.
#
#  envVarName:
#       [optional] You can choose the environment variable name to key off.
#       The default is DDR_DA_USE_WHICH_EXE
#
#       If the env var exists and is set to nothing, then it will try and
#       find the exe by using the tcsh command 'which'.  This looks in the
#       $PATH env variable to try and find the script name. This works best
#       when you are using 'module load TOOL'
#
#       If the env var exists and points to a folder, then that folder will
#       be prefixed to the supplied script name and will get returned.
#
#       If the env var exists and is set to something, that something will
#       be assumed to be the full path to the script file.
#-
sub getScriptExe($$;$){
    my $PerlScriptName = shift;
    my $PerlScriptExe  = shift;
    my $envVarName     = shift;

    $envVarName = 'DDR_DA_USE_WHICH_EXE' if ( ! $envVarName );

    if ( exists( $ENV{$envVarName}) ){
        my $envVarValue = $ENV{$envVarName};
        if ( $envVarValue eq "" ){
            my ($which_script, $retval) = run_system_cmd("/bin/tcsh -c 'which $PerlScriptName'", $main::VERBOSITY);
            #my $which_script = `/bin/tcsh -c 'which $PerlScriptName'`;
            chomp $which_script;  # remove trailing linefeed
            $PerlScriptExe = $which_script;
        }else{
            if ( -d $envVarValue ){
                # If the env var points to a directory; then we want to prefix
                # the script name with this directory path.
                $PerlScriptExe = "${envVarValue}/${PerlScriptName}";
            }else{
                $PerlScriptExe = $envVarValue;
            }
        }
    }

    return $PerlScriptExe;
}

sub test_createPerlCoveragePrefix($) {
    my $add_coverage = shift;
    if ( ! $add_coverage ){
        return "";
    }

    my $DDR_DA_COVERAGE_DB = $ENV{'DDR_DA_COVERAGE_DB'};
    if ( ! $DDR_DA_COVERAGE_DB ) {
        $DDR_DA_COVERAGE_DB = "testutils_cover_db";
    }
    return "/depot/perl-5.14.2/bin/perl -MDevel::Cover=-db,${DDR_DA_COVERAGE_DB} ";
}


#-----------------------------------------------------------------------------
sub test_scripts__get_options($) {
    my $opt_workspace  = shift;
    my $opt_help       = 0;
    my $opt_debug      ;
    my $opt_verbosity  ;
    my $opt_cleanup    = 1;
    my $opt_coverage   = 0;
    my $opt_tnum       = 0; # test number
    my $opt_randomize  = 1; # default is to randomize (ljames added 10/18/2022 for alphaHLDepotLibRelease tests)

    my $get_status = GetOptions(
        "help"        => \$opt_help,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "cleanup!"    => \$opt_cleanup,
        "p4ws=s"      => \$opt_workspace,
        "coverage!"   => \$opt_coverage,
        "testnum=i"   => \$opt_tnum,
        "randomize!"  => \$opt_randomize,
    );
    if ( $opt_help ){
        test_scripts__display_help();
    }
    $main::VERBOSITY = $opt_verbosity if ( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if ( defined $opt_debug );

    return ($opt_workspace, $opt_cleanup, $opt_coverage, $opt_help, $opt_tnum, $opt_randomize);
}

#-----------------------------------------------------------------------------
sub test_scripts__display_help($){
    my $script = shift || 'script' ;

    print("Usage:\n\n");
    print("\t$script [-debug #] [-verbosity #] [-help]\n");
    print("\t    [-p4ws PATH] -[no]cleanup\n");
    print("\nDefaults:\n\n");
    print("\t-debug     0\n");
    print("\t-verbosity 0\n");
    print("\t-testnum   0\n");
    print("\t-nohelp    \n");
    print("\t-p4ws      NULL\n");
    print("\t-cleanup   \n");
    print("\t-coverage  \n");
    return;
}



################################
# A package must return "TRUE" #
################################


1;

__END__


