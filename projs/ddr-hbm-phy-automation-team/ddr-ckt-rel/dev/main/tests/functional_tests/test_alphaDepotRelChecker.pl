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
use lib "$RealBin/lib";
use TestUtils;

our $STDOUT_LOG   = undef; 
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $AUTO_APPEND_NEWLINE = 1;
our $DDR_DA_DEFAULT_P4WS = "p4_func_tests";
our $VERSION      = get_release_version();

sub Main(){
    my $PWD            = getcwd();
    # to ensure we don't get 'prototype mismatch sub main::process_corners_file again
    my $scriptName     = "test_alphaDepotRelChecker_repeater_qa.sh";
    my $ddrcktrelBin   = "$RealBin/../../bin";
    my $ddrcktrelTdata = "$RealBin/../data/alphaDepotRelChecker";
    my %t = ( 
        '01'=>{
            'description' => "Test process_corners_files",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$ddrcktrelTdata",
            'scriptDir'   =>"$PWD",      # this test generates/writes the script here
            'scriptName'  =>"$scriptName",
        },
    );

    my $workspace    = $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;
    my $opt_cleanup  = 1;
    my $opt_coverage = 0;
    my $opt_help     = 0;
    my $opt_tnum     = 0;
    my $orig_coverage = 0;
    my $orig_cleanup = 0;

    ($workspace, $orig_cleanup, $orig_coverage, $opt_help, $opt_tnum) = 
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

        $opt_cleanup  = $orig_cleanup;
        $opt_coverage = $orig_coverage;

        my $scriptFilename = $href_args->{'scriptDir'} . "/" . $href_args->{'scriptName'} ;
        if ( 0 != generate_script( $PWD, $scriptFilename, $opt_coverage, $ddrcktrelBin, $ddrcktrelTdata) ){
            eprint("Failed to create the script needed to run this test!\n");
            return -1;
        }
        $opt_cleanup  = 0;
        $opt_coverage = 0;

        viprint(LOW, "Running test script '$href_args->{testScript}' $tstnum\n");
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
        );

       if ( $status != 0 ){
            dprint(LOW, "$tstnum: common main returned status = $status\n");
            my $tempfile = "/tmp/${tstnum}_$href_args->{'testScript'}_$$.log";
            unlink $tempfile if ( -e $tempfile );
            my $ostatus  = open my $FOUT, ">", $tempfile ; #nolint open>
            my $seeFile = "";
            if ( $ostatus ){
                print $FOUT "$href_args->{'scriptName'} $cmdline_args\n";
                print $FOUT "$stdout\n";
                my $log1 = "${PWD}/gen_ckt_cell_cfgs.pl.log";
                if ( -e $log1) {
                    print $FOUT "\n$log1\n";
                    print $FOUT "-----------------------------\n";
                    my @log1out = read_file( $log1 );
                    foreach my $line ( @log1out){
                        print $FOUT "$line\n";
                    }
                    unlink $log1;
                }                
                my $log2 = "${PWD}/alphaDepotRelChecker.pl.log";
                if ( -e $log2) {
                    print $FOUT "\n$log2\n";
                    print $FOUT "-----------------------------\n";
                    my @log2out = read_file( $log2 );
                    foreach my $line ( @log2out){
                        print $FOUT "$line\n";
                    }
                    unlink $log2;
                }
                close($FOUT);
                $seeFile = " See $tempfile ";
            }
           
            print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
            $nfails += 1;
            if ( $opt_cleanup) {
                cleanup_test( $scriptFilename, $PWD );
            }
        }else{
            print("PASSED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}\n");
            cleanup_test( $scriptFilename, $PWD);
        }
    } # end foreach test

    if ( $nfails  ){
        print("FAILED: ($nfails/$ntests) $RealScript\n");
    }else{
        print("PASSED: ($ntests/$ntests) $RealScript\n");
    }
   
    exit($nfails);
} # end Main

sub cleanup_test($$){
    my $filename = shift;
    my $cwd      = shift;

    my @removeFiles = ( 
        $filename, 
        "${cwd}/alphaDepotRelChecker.pl.log",
        "${cwd}/inspector.pl.log",
        "${cwd}/gen_bom.pl.log",
        "${cwd}/gen_ckt_cell_cfgs.pl.log",
        "${cwd}/MM.filenames.optional.txt",
        "${cwd}/MM.filenames.txt",
        "${cwd}/MM.href.txt",
        "${cwd}/repeater-d851-2.00a--config.cfg"
    );

    viprint(LOW, "Cleaning up generated log files and script.\n");
    foreach my $fname ( @removeFiles ){
        unlink $fname if ( -e $fname);
    }
   
    return 0;
}

sub generate_script($$$$){
    my $cwd      = shift;   # current working directory
    my $filename = shift;   # full filepath to the script file we want to make
    my $coverage = shift;   # modify calling perl scripts for Coverage Stats
    my $bindir   = shift;   # directory we expect to find gen_ckt_cell_cfgs.pl
    my $tdata    = shift;   # Where we expect the test data to be. mainifest.xlsx and our copy of the original legalRelease.txt file
    
    my $opt_debug      = $DEBUG > 0     ? "-debug $DEBUG" : "";
    my $opt_verbosity  = $VERBOSITY > 0 ? "-verbosity $VERBOSITY" : "";
    my $coveragePrefix = $coverage > 0  ? test_createPerlCoveragePrefix($coverage) : "";

    # Using << HereDoc to construct a script
    my $contents = <<"END_CONTENTS"
#!/bin/csh -x
module unload bom-checker
module load bom-checker
${coveragePrefix}${bindir}/gen_ckt_cell_cfgs.pl -proj "lpddr54/d851-lpddr54-tsmc16ffc18/rel2.00_cktpcs" -phase final -manifest "${tdata}/manifest.xlsx" -output "${cwd}/repeater-d851-2.00a--config.cfg" -release repeater $opt_debug $opt_verbosity
${coveragePrefix}${bindir}/alphaDepotRelChecker.pl -cfg "${cwd}/repeater-d851-2.00a--config.cfg" -rel "${tdata}/abmlogs/repeater_relqa.txt" -log "${cwd}/repeater-d851-2.00a" $opt_debug $opt_verbosity
END_CONTENTS
;

    viprint(LOW, "Writing contents:\n'$contents'\n");
    my $status = write_file( $contents, $filename);
    if ( ! defined $status ){
        return -1;
    }elsif ( $status == TRUE ) {
        iprint("Created test script named '$filename'!\n");
    } elsif ($status eq NULL_VAL ){
        fprint("write_file returned NULL_VAL, unable to create '$filename'!\n");
        return -1;
    }else{
        fprint("Unexpected return value from write_file()\n");
        return -1;
    }

    # chmod on file so it's executable
    chmod(0755, $filename );

    return 0; # success
}


sub create_cmdline_args($;$){
    my $href_args = shift;
    my $workspace = shift;
    my $cmd = "";

    return $cmd;
}

&Main();


