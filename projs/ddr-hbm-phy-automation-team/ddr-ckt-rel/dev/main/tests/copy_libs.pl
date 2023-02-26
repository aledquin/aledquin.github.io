#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;

use Getopt::Long;
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;
use Util::P4;

our $PROGRAM_NAME = $RealScript;

our $DEBUG        = NONE;
our $VERBOSITY    = NONE;

# nolint utils__script_usage_statistics

sub Main(){

    my ($opt_p4ws) = &process_cmd_line_args();

    my $testDataDir = "$RealBin/../data";

    my %t = (
        '01'=>{
            'product' => 'lpddr5x',
            'project' => 'd931-lpddr5x-tsmc3eff-12',
            'release' => 'rel1.00_cktpcs',
            'macro'   => 'dwc_lpddr5xphy_ato_ew',
        },
        '04'=>{
            'product' => 'lpddr5x',
            'project' => 'd930-lpddr5x-tsmc5ff12',
            'release' => 'rel1.00_cktpcs',
            'macro'   => 'dwc_lpddr5xphy_repeater_cells',
        },
    );
    my @libTypes = ('lib_lvf', 'lib_pg_lvf');
    foreach my $tstnum (sort keys %t){
        my $href_args = $t{$tstnum};
        my $product = $href_args->{'product'};
        my $project = $href_args->{'project'};
        my $release = $href_args->{'release'};
        my $macro   = $href_args->{'macro'};
        my $source_dir = "/slowfs/us01dwt2p387/juliano/func_tests/projects/$product/$project/latest/design/timing/nt/$macro";
        my $dest_dir   = "/u/$ENV{'USER'}/$opt_p4ws/projects/$product/$project/latest/design/timing/nt/$macro";

        foreach my $type (@libTypes){
            run_system_cmd("mkdir -p $dest_dir/$type");
            my ($output, $exit_val) = run_system_cmd("cp -f $source_dir/$type/*.lib $dest_dir/$type/");

            if ($exit_val != 0){ ## If for some reason unable to copy, grab libs from p4 and unzip
                wprint ("Unable to copy from $source_dir , grabbing from P4 instead\n");
                # grab exact revision from CRR
                my @crr = read_file("$testDataDir/test_alphaHLDepotLibRelease_$tstnum.crr");
                $crr[0] =~ /(^.*)\/.*\/.*$/;
                my $depot_path = $1;
                # Verify if depot path is mapped to user's p4 area
                my $is_mapped = da_p4_is_in_perforce("$depot_path/...");
                if (!$is_mapped){
                    fatal_error("Please ensure you have the following path (or higher) mapped in your p4 client:\n\t" .
                            "$depot_path/...\n");
                }
                else{
                    # Sync all .libs files in the CRR
                    foreach my $line (@crr){
                        if( grep{/$type/} $line && grep{/.lib/} $line ){
                            run_system_cmd("p4 sync -f $line");
                        }
                    }
                    # Need to get local path of synced files
                    my ($out, $exit) = run_system_cmd("p4 where $depot_path");
                    my $local_path = (split ' ', $out)[-1];
                    run_system_cmd("gunzip -f $local_path/$type/*.lib.gz");
                    run_system_cmd("cp -f $local_path/$type/*.lib $dest_dir/$type/");
                    iprint ("Successfully copied libs from $depot_path/$type/ to $dest_dir/$type/\n");
                }
            }
            else{
                iprint ("Successfully copied libs from $source_dir/$type/ to $dest_dir/$type/\n");
            }                
        }   
    }

}

&Main();

#------------------------------------------------------------------------------
# 
#------------------------------------------------------------------------------
sub process_cmd_line_args() {
    my ($opt_p4ws, $opt_help);

    my $success = GetOptions(
        "help!"       => \$opt_help,
        "p4ws=s"      => \$opt_p4ws,
    );

    ## quit with usage message, if usage not satisfied
    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    &usage(1) unless( defined $opt_p4ws );

    return($opt_p4ws);
}

#------------------------------------------------------------------------------
#  script usage message
#------------------------------------------------------------------------------
sub usage($) {
    my $exit_status = shift;

    print << "EOP" ;
Description
  A script to automatically copy the lib files required to run functional tests
  for alphaHLDepotLibRelease.

USAGE : $PROGRAM_NAME -p4ws <p4_ws>

------------------------------------
Required Args:
------------------------------------
-p4ws <p4_ws>   p4 workspace for functional test

------------------------------------
Optional Args:
------------------------------------
-help           Print this screen

EOP

    exit $exit_status ;
} # usage()
