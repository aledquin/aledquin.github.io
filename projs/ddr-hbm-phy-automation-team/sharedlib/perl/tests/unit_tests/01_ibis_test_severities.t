#!/depot/perl-5.14.2/bin/perl -w
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Getopt::Std;
use JSON;
use Data::Dumper;
use Test2::Bundle::More;
use Term::ANSIColor;
use FindBin qw($RealBin $RealScript);
use File::Slurp;

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Messaging;
use Util::DS;
use Util::QA;

our $PROGRAM_NAME = $0;
our $AUTHOR_NAME  = 'Harsimrat Wadhawan';
our $FPRINT_NOEXIT = 1;
our $DA_RUNNING_UNIT_TESTS = 1;
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $DEBUG_LOG = undef;
#----------------------------------#

Main();

########  YOUR CODE goes in Main  ##############
sub Main {
   
    # Current planned test count
    plan(7);

    #-------------------------------------------------------------------------
    manual_tests__parse_severities();
    manual_tests__map_check_severities();    
    #-------------------------------------------------------------------------

    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup manual tests to exercise the parse_severities subroutine
#-------------------------------------------------------------------------
sub manual_tests__parse_severities() {

    my $subname = 'parse_severities';
    my $cnt     = 1;

    my $good_file = "$RealBin/../data/severity-good.json";
    my $expected_file = "$RealBin/../data/severity-no-nest.json";
    my $bad_file = "$RealBin/../data/severity-bad.json";

    # Good parsing    
    my %calculated_data = parse_severities($good_file);
    my @file_data = read_file("$expected_file");
    my $file_data = join("", @file_data);
    my %expected_data = %{JSON->new->decode($file_data)};
    is_deeply(%calculated_data, %expected_data);

    # Bad file parsing    
    my %calculated_data2 = parse_severities($bad_file);
    my %expected_data2 = ();
    is_deeply(%calculated_data2, %expected_data2);

    # Non-existent file
    my $calculated_data3 = parse_severities("/FILESYSTEM?ABCABCXYZ.JSON");
    my $expected_data3 = "0";
    is_deeply($calculated_data3, $expected_data3);

    # NULL_VAL parsing
    my $calculated_data4 = parse_severities(NULL_VAL);
    my @file_data1 = read_file("$expected_file");   
    my $file_data1 = join("", @file_data1);
    my $expected_data4 = %{JSON->new->decode($file_data1)};
    Dumper("$expected_data4\n");
    is_deeply($calculated_data4, $expected_data4);

}

#-------------------------------------------------------------------------
#  Setup manual tests to exercise the map_check_severity subroutine
#-------------------------------------------------------------------------
sub manual_tests__map_check_severities() {
    
    my $good_file = "$RealBin/../data/severity-good.json";    

    my %SEVERITIES = parse_severities($good_file);    
    
    my $expected_data = "HIGH";
    my $calculated_data = map_check_severity();
    is_deeply($expected_data, $calculated_data);

    # Check LOW and NULL value returns
    helper_NULL();
    helper_LOW();

}

#-------------------------------------------------------------------------
#  Helper for testing map_check_severity
#-------------------------------------------------------------------------
sub helper_NULL {

    my $expected_data = NULL_VAL;
    my $calculated_data = map_check_severity();
    is_deeply($expected_data, $calculated_data);

}

#-------------------------------------------------------------------------
#  Helper for testing map_check_severity
#-------------------------------------------------------------------------
sub helper_LOW {

    my $expected_data = "LOW";
    my $calculated_data = map_check_severity();
    is_deeply($expected_data, $calculated_data);

}

1;
