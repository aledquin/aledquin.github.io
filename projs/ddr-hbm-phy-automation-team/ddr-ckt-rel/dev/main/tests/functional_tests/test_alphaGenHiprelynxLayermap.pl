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

#-------------------------------------------------------------------------------
sub Main(){
    my $scriptName = "alphaGenHiprelynxLayermap.pl";
    my $goldenFile = "layerMap_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z.txt";

    my %t = ( 
        '01'=>{
            'description' => "$scriptName test",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'tech'        =>"tsmc3eff-12_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z", 
            'gds'         =>"$scriptName/dwc_lpddr5xphy_ato_ew.gds.gz",
            'outputFile'  =>"$scriptName/new_${goldenFile}",
            'mapFile'     =>"$RealBin/../../bin/alphaGenHiprelynxLayermap.tech",
            'goldenFile'  =>"$scriptName/$goldenFile",
        },
    );

    my $workspace    = $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;
    my $opt_cleanup  = 1;
    my $opt_coverage = 0;
    my $opt_help     = 0;
    my $opt_tnum     = 0;

    ($workspace, $opt_cleanup, $opt_coverage, $opt_help, $opt_tnum) = 
        test_scripts__get_options( $workspace );

    return -1  unless( $workspace );
    return  0  if( $opt_help );

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
            \&mycompare,
            $href_args
        );

       if ( $status != 0 ){
            dprint(LOW, "$tstnum: common main returned status = $status and stdout = '$stdout'\n");
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
            print("PASSED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}\n");
            my $temp_file = "$href_args->{'testDataDir'}/$href_args->{'outputFile'}";
            if ( -e $temp_file ){ 
                unlink($temp_file);
            }
        }
    }


    if ( $nfails  ){
        print("FAILED: ($nfails/$ntests) $RealScript\n");
    }else{
        print("PASSED: ($ntests/$ntests) $RealScript\n");
    }

    
    exit($nfails);
}

#-------------------------------------------------------------------------------
sub mycompare($$$$;$){
    print_function_header();
    my $workspace   = shift;
    my $testDataDir = shift;
    my $testScript  = shift;
    my $testNumber  = shift;
    my $href_args   = shift;  # href 

    my $nerrors     = 0;

    my $ignore_this  = " --ignore-matching-lines=\"#Date:\"";
       $ignore_this .= " --ignore-matching-lines=\"#Title:\"";
       $ignore_this .= " -w -B -d";  # --ignore-all-space(-w), --ignore-blank-lines(-B), --minimal(-d)
       $ignore_this .= " --strip-trailing-cr ";
    my $golden_file = "${testDataDir}/$href_args->{'goldenFile'}" ;
    my $new_file    = "${testDataDir}/$href_args->{'outputFile'}" ;
    my ($diff, $err)= run_system_cmd("diff $ignore_this $golden_file $new_file");
    chomp $diff;

    if ( $diff ne EMPTY_STR ) {
        my @diffs = split(/\n/, $diff);
        my $ndiffs=0;
        foreach my $diff (@diffs) {
            next if ( $diff =~ m/Title/);
            next if ( $diff =~ m/Date/);
            next if ( $diff =~ m/---/);
            next if ( $diff =~ m/^[a-z0-9,]+\s*$/);
            $ndiffs++;
        }
        if ( $ndiffs ) {
            dprint(MEDIUM,"mycompare: spotted a diff between $golden_file and $new_file\n");
            eprint("test_alphaGenHiprelynxLayermap.pl: mycompare()  comparator diff failed\n\t$golden_file\n\t$new_file\n");
            return 1;
        }
    }
    return 0;
}

#-------------------------------------------------------------------------------
sub create_cmdline_args($;$){
    print_function_header();
    my $href_args = shift;
    my $workspace = shift;

    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;
    my $tech      = $href_args->{'tech'};
    my $gds       = $href_args->{'gds'};
    my $output    = $href_args->{'outputFile'};
    my $mapfile   = $href_args->{'mapFile'};

    my $cmd = "";

    $cmd .= " -tech $tech"                                   if ( $tech      );
    $cmd .= " -gds $href_args->{'testDataDir'}/${gds}"       if ( $gds       );
    $cmd .= " -output $href_args->{'testDataDir'}/${output}" if ( $output    );
    $cmd .= " -mapFile $mapfile"                             if ( $mapfile   );
    $cmd .= " -debug $debug "                                if ( $debug     );
    $cmd .= " -verbosity $verbosity "                        if ( $verbosity );


    return $cmd;
}

&Main();


