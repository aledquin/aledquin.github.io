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


use lib "$RealBin/../lib/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use lib "$RealBin/lib";
use TestUtils;

our $STDOUT_LOG   = undef; 
our $DEBUG        = undef;
our $VERBOSITY    = undef;
our $PROGRAM_NAME = $RealScript;
our $AUTO_APPEND_NEWLINE = 1;
our $DDR_DA_DEFAULT_P4WS = "p4_func_tests";


#------------------------------------------------
sub my_comparator($$$$$){
    my $workspace      = shift;
    my $testDataDir    = shift;
    my $testScript     = shift;
    my $testNumber     = shift;
    my $func_user_data = shift;

    iprint("my_comparator: does nothing so far\n" );
    return( 0 );
}
sub my_test($$$$){
    my $test_script_results = shift;
    my $href_args           = shift;
    my $tstnum              = shift;
    my $cmdline_args        = shift;
    
    iprint("Running test output '$test_script_results'\n");
    if( defined $test_script_results ){
        my( $output, $exit_val ) = run_system_cmd( $test_script_results, $VERBOSITY );
        if( $exit_val != 0 ){
            my $tempfile = "/tmp/${tstnum}_$href_args->{'testScript'}_$$.log";
            my $ostatus  = open my $FOUT, ">", $tempfile ; #nolint open>
            my $seeFile = "";
            if ( $ostatus ){
                print $FOUT "$href_args->{'scriptName'} $cmdline_args\n";
                print $FOUT "DEBUG: script comparison errors by running command:\n'$test_script_results'\n";
                print $FOUT "$output\n";
                close($FOUT);
                $seeFile = " See $tempfile ";
            }

            print( "FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}$seeFile\n" );
        }
        return $exit_val;
    }
    return 0;
}

#------------------------------------------------
sub Main(){
    my $scriptName = "dcck_reports.pl";
    my $testDataDir = "$RealBin/../data";
    my %t = ( 
        '01'=>{
            'description' => "basic testing for dcck_reports.pl",
            'testScript'  => "$RealScript",
            'testDataDir' => "$testDataDir",
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'inc'         => "$RealBin/../tdata/dcck_reports.pl/"
                  ."lpddr5x.d931-lpddr5x-tsmc3eff-12.1.00a_cktpcs.design.sim.txrxcs_pdk0p9.data.tb_txrxcs_power_s3_post_Sept20_dcck/dcck_options.inc",
            'dir'         => "$RealBin/../tdata/dcck_reports.pl/"
                  ."lpddr5x.d931-lpddr5x-tsmc3eff-12.1.00a_cktpcs.design.sim.txrxcs_pdk0p9.data.tb_txrxcs_power_s3_post_Sept20_dcck/",
            'extraArgs'   => "",
            # is_deeply -> must point to a script that evalues the results : exit val=0 => PASS, else FAIL
            'is_deeply'   => "$RealBin/../tdata/dcck_reports.pl/"
                       ."lpddr5x.d931-lpddr5x-tsmc3eff-12.1.00a_cktpcs.design.sim.txrxcs_pdk0p9.data.tb_txrxcs_power_s3_post_Sept20_dcck/compare.csv.files $testDataDir",
        },
    );

    my $workspace    = $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;
    my $opt_cleanup  = 1;
    my $opt_coverage = 0;
    my $opt_help     = 0;
    my $opt_tnum     = 0;

    ($workspace, $opt_cleanup, $opt_coverage, $opt_help, $opt_tnum) = 
        test_scripts__get_options( $workspace );
    if ( ! $workspace ) {
        return -1;
    }
    if ( $opt_help ) {
        return 0;
    }


    my $ntests = keys(%t);
    my $nfails = 0;
    foreach my $tstnum (sort keys %t) {
        if ( $opt_tnum ) {
            my $num = $tstnum + 0;     # convert string of number to a number
            next if ( $num != $opt_tnum );
        }

        my $href_args = $t{"$tstnum"};
        viprint(LOW, "Running $href_args->{'testScript'} $tstnum\n");
        my $cmdline_args = create_cmdline_args( $href_args,  $workspace );

        my ($status,$stdout) = test_scripts__main(
            $tstnum,
            $opt_cleanup,
            $opt_coverage,
            $href_args->{'testScript'},
            $href_args->{'testDataDir'},
            $href_args->{'scriptDir'},
            $href_args->{'scriptName'},
            $cmdline_args,
            $workspace,
            \&my_comparator
        );

       if ( $status != 0 ){
            dprint(LOW, "$tstnum: common main returned status = $status\n");
            my $tempfile = "/tmp/${tstnum}_$href_args->{'testScript'}_$$.log";
            my $ostatus  = open my $FOUT, ">", $tempfile ; #nolint open>
            my $seeFile = "";
            if ( $ostatus ){
                print $FOUT "$href_args->{'scriptName'} $cmdline_args\n";
                print $FOUT "$stdout\n";
                close($FOUT);
                $seeFile = " See $tempfile ";
            }
            
            print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
            $nfails += 1;
        }else{
            my $RESULT = my_test( $href_args->{'is_deeply'} , $href_args, $tstnum, $cmdline_args);
            if( $RESULT == 0 ){
                print("PASSED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}\n");
            }else{
                print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}\n");
                $nfails += 1;
            }
        }
    }


    if ( $nfails ){
        print("FAILED: ($nfails/$ntests) $RealScript\n");
    }else{
        print("PASSED: ($ntests/$ntests) $RealScript\n");
    }

    
    exit($nfails);
}


#-----------------------------------------------------
sub create_cmdline_args($;$){
    my $href_args = shift;
    my $workspace = shift;
    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;
   
    my $inc  = $href_args->{'inc'};
    my $dir  = $href_args->{'dir'};
    my $extra= $href_args->{'extraArgs'};

    my $cmd = "";
    $cmd .= " -inc $inc";
    $cmd .= " -dir $dir";
#    $cmd .= " -p4ws ${workspace} "    if ( $workspace );
    $cmd .= " -debug $debug "         if ( $debug );
    $cmd .= " -verbosity $verbosity " if ( $verbosity );
    $cmd .= " ${extra} "              if ( $extra );

    return $cmd;
}

&Main();


