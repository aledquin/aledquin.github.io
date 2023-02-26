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
use File::Copy;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use FindBin qw($RealBin $RealScript);
# use Switch;


use lib "$RealBin/../../lib/perl/";
use lib "$RealBin/..";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DS;
# use utilities;
use Util::P4;
use lib "$RealBin";
use lib::testlib;

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
    
    my ($p4, $local, $norun, $test_location);

	## get specified args
	my $success = GetOptions(
		"p4"        => \$p4,
		"local"     => \$local,
        "norun"	    => \$norun,
        "d=s"	    => \$DEBUG    		
	);

    if ($p4 and $local) {
        fatal_error("Only one of p4 or local should be specified.\n");
    }

    if ($p4) {
        $test_location = "p4";
    }
    elsif ($norun){
        $test_location = "norun"
    }
    else {
        $test_location = "local";
    }

    return $test_location;

}

########  YOUR CODE goes in Main  ##############
sub Main {

    my ( $test_location ) = initialise_script();
    dprint(LOW, "Running on: $test_location\n");

    my @project_hash = @{filter_projects(1)};
    dprint HIGH, Dumper(@project_hash)."\n";

    my @testcases;
    foreach my $key (@project_hash){

        my %hash = %{$key};        
        my $command = "ibis_electrical.pl -proj $hash{product}/$hash{project}/$hash{release} -macro $hash{macro}";
        p4print($command."\n");
        push (\@testcases, $command);

    }
    dprint (LOW, Dumper(@testcases)."\n");

    if ($test_location =~ /p4/) {
        run_on_module(\@testcases);
    }
    elsif ($test_location =~ /norun/) {
        # NOP
    }
    else {
        run_inside_repository(\@testcases);
    }

}
############    END Main    ####################

sub run_inside_repository($) {

    my $arr_ref = shift;
    my @testcases = @{$arr_ref};

    chdir("$RealBin/../bin");
    
    foreach my $command ( @testcases ){

        hprint("Running: $command\n");
        my ($output, $retval) =  run_system_cmd($command, $VERBOSITY);

        iprint ($output);
        iprint("Finished command\n\n");

        run_system_cmd("mv ./*log ../t/.", $VERBOSITY);

    }

}

sub run_on_module($) {

    my $arr_ref = shift;
    my @testcases = @{$arr_ref};

    chdir("$RealBin/../bin");
    my ($out, $ret) = run_system_cmd("module load ibis/dev", $VERBOSITY);
    
    foreach my $command ( @testcases ){

        hprint("Running: $command\n");
        my ($output, $retval) =  run_system_cmd($command, $VERBOSITY);

        iprint ($output);
        iprint("Finished command\n\n");

        run_system_cmd("mv ./*log ../t/.", $VERBOSITY);

    }

}