use strict;
use warnings;
use Carp qw(cluck confess croak);
use Test2::Bundle::More;
use Test::Exception;
use File::Spec::Functions;


use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../bin/";
use lib "$RealBin/../../lib/perl/";

use alphaHLDepotRelease;
use Util::Misc;
use Util::Messaging;
use Util::CommonHeader;


our $DEBUG     = 0;
our $VERBOSITY = 0;

sub TestMain() {

    utils__process_cmd_line_args();

    if ( ! exists( $ENV{'DDR_DA_MAIN'} ) ){
        my $user = get_username();
        my $default_ddr_da_main = "/u/$user/GitLab/ddr-hbm-phy-automation-team/";
        if ( ! -e "$default_ddr_da_main/ddr-ckt-rel") {
            $default_ddr_da_main = "/u/$user/gitlab/ddr-hbm-phy-automation-team/";
        }
        if ( ! -e "$default_ddr_da_main/ddr-ckt-rel" ){
            $default_ddr_da_main = "/u/$user/GitLab/";
        }
        if ( ! -e "$default_ddr_da_main/ddr-ckt-rel" ){
            $default_ddr_da_main = "/u/$user/gitlab/";
        }
        if ( ! -e "$default_ddr_da_main/ddr-ckt-rel" ){
            $default_ddr_da_main = "/u/$user/GitLab/ddr-hbm-phy-automation-team";
        }
        my $ddr_da_main = "${default_ddr_da_main}/ddr-ckt-rel/dev/main/";

        $ENV{'DDR_DA_MAIN'} = $ddr_da_main;
        wprint("This test requires DDR_DA_MAIN be defined but it's not!\nDefaulting to $ddr_da_main");
    }

    my $USER        = get_username();
    my $p4_dest     = "msip_cd_${USER}";
    my $projType    = 'lpddr5x';
    my $projName    = 'd931-lpddr5x-tsmc3eff-12';
    my $projRel     = 'rel1.00_cktpcs';
    #my $projPathAbs = "/remote/cad-rep/projects/$projType/$projName/$projRel";
    my $projPathAbs = "$ENV{DDR_DA_MAIN}/tests/data/alphaHLDepotBehaveRelease/$projType.$projName.$projRel";
    my %tests = (
        test1 => {
            'input'    => [ $projPathAbs, $projType, $projName, $projRel ],
            'expected' => [ 
                "$ENV{DDR_DA_MAIN}/tests/data/alphaHLDepotBehaveRelease/$projType.$projName.$projRel.topcells.txt",
                "$ENV{DDR_DA_MAIN}/tests/data/alphaHLDepotBehaveRelease/$projType.$projName.$projRel.alphaNT.config",
                "$ENV{DDR_DA_MAIN}/tests/data/alphaHLDepotBehaveRelease/$projType.$projName.$projRel.legalRelease.txt",
                "$ENV{DDR_DA_MAIN}/tests/data/alphaHLDepotBehaveRelease/$projType.$projName.$projRel.legalVerifs.txt",
            ], 
        },
    );


    my $ntests = keys(%tests) ;
    plan($ntests);
    my $tnum=0;

    my $savedebug     = $DEBUG;
    my $saveverbosity = $VERBOSITY;

    # Test #2 -- verify subroutine
    $DEBUG     = $savedebug;
    $VERBOSITY = $saveverbosity;
    foreach my $test ( keys %tests ) {
        $tnum++;
        my $aref_input = $tests{$test}->{'input'};
        my $p1 = $aref_input->[0];
        my $p2 = $aref_input->[1];
        my $p3 = $aref_input->[2];
        my $p4 = $aref_input->[3];
        #sprint("p1=$p1,  p2=$p2, p3=$p3, p4=$p4\n");
        my $expected   = $tests{$test}->{'expected'};
        my @result;
        do {
            unless( $DEBUG ){
            }
                local *STDOUT;
                local *STDERR;
                open(STDOUT, '>>', "/dev/null") || return 0;
                open(STDERR, '>>', "/dev/null") || return 0;
            my $tmp = $RealScript;
            $RealScript = 'alphaHLDepotBehaveRelease';
            @result     = get_project_files_path($p1, $p2, $p3, $p4  );
            $RealScript = $tmp;
        };
        #sprint("got='" . join(",",@result) ."'\n");
        is_deeply( \@result, $expected, "Running test number $tnum out of a total of $ntests tests for alphaHLDepotBehaveRelease ");
    }

    done_testing();

    return 0; # success
}

TestMain();

