#!/depot/perl-5.14.2/bin/perl
###############################################################################
# Name    : test_ibis_quality.pl
# Author  : Harsimrat Singh Wadhawan
# Date    : 14 February, 2022
# Purpose : Test the IBIS Quality script on different inputs.
###############################################################################
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use List::Util qw(shuffle); 
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use FindBin qw($RealBin $RealScript);
# use Switch;


use lib "$FindBin::Bin/../../lib/perl";
use lib "$RealBin/..";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DS;
# use utilities;

#----------------------------------#
#our $STDOUT_LOG  = undef;    # Log msg to var => OFF
our $STDOUT_LOG  ='';   # Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $VERSION   = 1.00;
#----------------------------------#

BEGIN { our $AUTHOR='Harsimrat Singh Wadhawan'; header(); } 
    Main();
END {
   if( defined( $main::STDOUT_LOG) ){
      if( $main::STDOUT_LOG ne '' ){ 
         write_file( [split(/\n/, $STDOUT_LOG)], "${PROGRAM_NAME}.log");
      }
   }
   footer(); 
}

# Get options and initalise neessary variables for locating files.
sub initialise_script {
    
    my ($p4, $local, $test_location);

	## get specified args
	my $success = GetOptions(
		"p4"        => \$p4,
		"local"     => \$local,	
        "d=s"	    => \$DEBUG  ,
        "v=s"  		=> \$VERBOSITY
	);

    if ($p4 and $local) {
        fatal_error("Only one of p4 or local should be specified.\n");
    }

    if ($p4) {
        $test_location = "p4";
    }
    elsif ($local) {
        $test_location = "local";
    }
    else {
        $test_location = "local";
    }

    return $test_location;

}

########  YOUR CODE goes in Main  ##############
sub Main {

    my ( $test_location ) = initialise_script();        
    my @reports   = (
        "//depot/products/ddr54/project/d807-ddr54-gf12lpp18/ckt/rel/dwc_ddrphy_txrxdq_ew/1.00a/macro/ibis/correlation_reports/dwc_ddrphy_dq_ew_clp_plot_d4.pdf",                
        "//depot/products/lpddr5x_mphy/project/d900-lpddr5xm-tsmc5ff12/ckt/rel/dwc_lpddr5xmphy_txrxac_ew/1.00a/macro/ibis/correlation_reports/dwc_lpddr5xmphy_ac_ew_clp_plot_d5.pdf",        
    );

    my @testcases;
    foreach my $report (@reports){

        ######### -Download File- #############    
        my $file_name = time()."fom-test.pdf";
        my ($out, $ret) = run_system_cmd("p4 -q print $report > $file_name", $VERBOSITY);
        
        ######### -Test file- #############
        ($out, $ret) = run_system_cmd("ibis/dev/main/bin/FOM.pl -filename $file_name", $VERBOSITY);
        iprint ($out."\n");

        # ######### -Remove file- #############
        ($out, $ret) = run_system_cmd("rm -rf $file_name", $VERBOSITY);

    }    

}
############    END Main    ####################