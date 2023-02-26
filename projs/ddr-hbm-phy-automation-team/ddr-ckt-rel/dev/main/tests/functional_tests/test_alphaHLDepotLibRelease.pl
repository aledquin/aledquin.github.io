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
#  Test Summary
#  Test #1 : alphaHLDepotLibRelease lpddr5x/d931-lpddr5x-tsmc3eff-12/rel1.00_cktpcs -macros dwc_lpddr5xphy_ato_ew
#  Test #2 (no area corner cases): alphaHLDepotLibRelease lpddr5x/d931-lpddr5x-tsmc3eff-12/rel1.00_cktpcs -macros dwc_lpddr5xphy_utility_blocks
#  Test #3 : alphaHLDepotLibRelease lpddr5x/d931-lpddr5x-tsmc3eff-12/rel1.00_cktpcs -macros dwc_lpddr5xphycover_acx2_top_ew
#  Test #4 : alphaHLDepotLibRelease lpddr5x/d930-lpddr5x-tsmc5ff12/rel1.00_cktpcs -macros dwc_lpddr5xphy_repeater_cells
#  Test #5 : alphaHLDepotLibRelease lpddr54/d890-lpddr54-tsmc5ff-12/rel1.00_cktpcs -macros dwc_ddrphy_utility_blocks
#  Test #6 : alphaHLDepotLibRelease lpddr54/d850-lpddr54-tsmc5ffp12/rel2.00_cktpcs -macros dwc_ddrphy_utility_blocks
#  Test #7 : alphaHLDepotLibRelease ddr5/d912-ddr5-tsmc3eff-12/rel1.00_cktpcs -macros dwc_ddr5phy_tcoil_replica_ew

our $STDOUT_LOG   = undef; 
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $AUTO_APPEND_NEWLINE = 1;
my $DDR_DA_DEFAULT_P4WS = "p4_func_tests";

sub Main(){
    my $scriptName = "alphaHLDepotLibRelease";
    my %t = ( 
        '01'=>{
            'description' => "dwc_lpddr5xphy_ato_ew",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'product'     =>"lpddr5x",
            'project'     =>"d931-lpddr5x-tsmc3eff-12",
            'release'     =>"rel1.00_cktpcs",
            'macro'       =>"dwc_lpddr5xphy_ato_ew",
        },
        '02'=>{
            'description' => "dwc_lpddr5xphy_utility_blocks",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'product'     =>"lpddr5x",
            'project'     =>"d931-lpddr5x-tsmc3eff-12",
            'release'     =>"rel1.00_cktpcs",
            'macro'       =>"dwc_lpddr5xphy_utility_blocks",
        },
        '03'=>{
            'description' => "dwc_lpddr5xphycover_acx2_top_ew",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'product'     =>"lpddr5x",
            'project'     =>"d931-lpddr5x-tsmc3eff-12",
            'release'     =>"rel1.00_cktpcs",
            'macro'       =>"dwc_lpddr5xphycover_acx2_top_ew",
            'fail'        => TRUE,
        },
        '04'=>{
            'description' => "dwc_lpddr5xphy_repeater_cells",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'product'     =>"lpddr5x",
            'project'     =>"d930-lpddr5x-tsmc5ff12",
            'release'     =>"rel1.00_cktpcs",
            'macro'       =>"dwc_lpddr5xphy_repeater_cells",
        },
        '05'=>{
            'description' => "dwc_ddrphy_utility_blocks",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'product'     =>"lpddr54",
            'project'     =>"d890-lpddr54-tsmc5ff-12",
            'release'     =>"rel1.00_cktpcs",
            'macro'       =>"dwc_ddrphy_utility_blocks",
        },
        ##  Added test 6 to cross-check handling of VAA pwr supply->pininfo file (see Jira P10020416-36560)
        '06'=>{
            'description' => "dwc_ddrphy_utility_blocks",
            'testScript'  => "$RealScript",
            'testDataDir' => "$RealBin/../data",
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "lpddr54",
            'project'     => "d850-lpddr54-tsmc5ffp12",
            'release'     => "rel2.00_cktpcs",
            'macro'       => "dwc_ddrphy_utility_blocks",
        },
        '07'=>{
            'description' => "dwc_ddr5phy_tcoil_replica_ew",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'product'     =>"ddr5",
            'project'     =>"d912-ddr5-tsmc3eff-12",
            'release'     =>"rel1.00_cktpcs",
            'macro'       =>"dwc_ddr5phy_tcoil_replica_ew",
        },
    );

    my $workspace    = $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;
    my $opt_cleanup  = 1;
    my $opt_coverage = 0;
    my $opt_help     = 0;
    my $opt_tnum     = 0;
    my $opt_randomize= 1;

    ($workspace, $opt_cleanup, $opt_coverage, $opt_help, $opt_tnum, $opt_randomize) = 
        test_scripts__get_options( $workspace );
    if ( ! $workspace ) {
        return -1;
    }
    if ( $opt_help){
        return 0;
    }

    my $ntests = keys(%t);
    my $nfails = 0;
    foreach my $tstnum (sort keys %t) {
        #next unless( $tstnum == 6 ); 

        if ( $opt_tnum ) {
            my $num = $tstnum + 0;     # convert string of number to a number
            next if ( $num != $opt_tnum );
        }

        my $href_args = $t{"$tstnum"};
        viprint(LOW, "Running $href_args->{'testScript'} $tstnum\n");

        my $cmdline_args = create_cmdline_args( $href_args,  $workspace, $opt_randomize );
        my ($status,$stdout,$script_status) = test_scripts__main(
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

        my $seeFile  = write_seefile($tstnum, $href_args, $stdout, $cmdline_args);
      
        # We expect some tests to fail. We will treat those as success.
        $status = 0  if ( $status != 0 && exists $href_args->{'fail'} && $href_args->{'fail'} == TRUE) ;

        if ( $status != 0 ){
            dprint(LOW, "$tstnum: common main returned status = $status\n");
            # there are some exceptions to a failure. The SUT might have 
            # returned a success status, but further processing of it's stdout
            # might show messages with text strings like ERROR,  -E-,  -F- 
            # If these are found by test_scripts__main(), it will also think
            # it's an error but might not be. If we have a -E- but a waiver
            # is allowed, then we should not consider this as an error.
            if ( $script_status == 0 ){
                dprint(LOW, "$tstnum: script status = $script_status\n");
                my $nerrors = process_exceptions( $stdout );
                if ( $nerrors > 0 ){
                     print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
                     $nfails += 1;
                }else{
                    print("PASSED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
                }
            }else{
                print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
                $nfails += 1;
            }
        }else{
            my $txtmsg = "";
            $txtmsg = " BUT NOT REALLY "  if ( $status != 0 && exists $href_args->{'fail'} && $href_args->{'fail'} == TRUE) ;
            print("PASSED${txtmsg}: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
        }
    } #foreach $tstnum


    if ( $nfails ){
        print("FAILED: ($nfails/$ntests) $RealScript\n");
    }else{
        print("PASSED: ($ntests/$ntests) $RealScript\n");
    }

    
    exit($nfails);
}

sub write_seefile($$$){
    my $tstnum    = shift;
    my $href_args = shift;
    my $stdout    = shift;
    my $cmdline_args = shift;

    my $tempfile = "/tmp/${tstnum}_$href_args->{'testScript'}_$$.log";
    my $seeFile = "";
    my @datum;
    push( @datum, "$href_args->{'scriptName'} $cmdline_args\n");
    push( @datum, "$stdout\n");
    my $ostatus = write_file( \@datum, $tempfile);
    if ( "$ostatus" ne NULL_VAL ){
        $seeFile = " See $tempfile ";
    }
    return $seeFile;
}


sub process_exceptions($){
    my $stdout = shift;

    my $nerrors = 0;
    my $look_for_get_waiver_range_nlines = 0;
    my @textlines = split(/\n/, $stdout);
    foreach my $line ( @textlines ){
        # if we spot an error - then look at the next three lines
        # in the STDOUT list to see if we see 'get waivers' within
        # the next 3 lines. If we do see this then it's not really
        # considered an error.
        if ( $line =~ m/-E-/ ){
            if ( $line =~ m/is stale|StdErr/ ){
                # if we see 'is stale' or StdErr on the same line as the
                # error; then treat this error like w warning
            }else{
                $look_for_get_waiver_range_nlines = 3;
                $nerrors++;
            }
        }elsif ( $look_for_get_waiver_range_nlines) {
            $look_for_get_waiver_range_nlines--;
            if ( $line =~ m/get waivers/ ){
                $nerrors --;
            }
        }
    }

    return $nerrors;
}



sub create_cmdline_args($;$){
    my $href_args     = shift;
    my $workspace     = shift;
    my $opt_randomize = shift;
    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;
   
    my $prod = $href_args->{'product'};
    my $proj = $href_args->{'project'};
    my $rel  = $href_args->{'release'};
    my $macro= $href_args->{'macro'};
    my $extra= $href_args->{'extraArgs'};

    my $cmd = "";
    $cmd .= " -p $prod/$proj/$rel ";
    $cmd .= " -p4ws ${workspace} "    if ( $workspace );
    $cmd .= " -macros ${macro} "      if ( $macro );
    $cmd .= " ${extra} "              if ( $extra );
    unless( $main::DEBUG ) {
        $debug     = 1 if( $opt_randomize!=0 && int( rand(10) ) > 5 );  # randomize to get better coverage
    }
    unless( $main::VERBOSITY ){
        $verbosity = 1 if( $opt_randomize!=0 && int( rand(10) ) > 5 );  # randomize to get better coverage
    }
    $cmd .= " -verbosity $verbosity " if ( $verbosity );
    $cmd .= " -debug $debug "         if ( $debug );

    return $cmd;
}


&Main();


