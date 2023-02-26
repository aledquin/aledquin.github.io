use strict;
use warnings;
use Getopt::Std;
use Test2::Bundle::More;
use Date::Calc qw(:all);       #  Today()
use FindBin qw($RealBin $RealScript);

use Date::Simple qw(today) ;
use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;          # for utils__process_cmd_line_args, get_the_date
use Util::Messaging;     # for dprint
use Util::DateUtilities; # Today, days_from_now

our $PROGRAM_NAME = $RealScript;
our $AUTHOR_NAME  = 'James Laderoute';
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $DEBUG_LOG = undef;
#----------------------------------#

&Main();

########  YOUR CODE goes in Main  ##############
sub Main {
    my $now='2021-06-08';

    # Date pairs, ordered lists
    my @YMD = qw( 2021-06-03  2021-05-08  2021-05-04
                  2021-06-11  2020-06-08  Patrick
                ); 
    dprint(CRAZY+10, "Test: \@YMD= (" .join(',', @YMD) .")\n" );
    dprint(NONE, "Test: \@YMD= (" .join(',', @YMD) .")\n" );

    plan(1);

    my @computed_times_expected = ( 5, 31, 35, 3, 365, NULL_VAL, 0 );
    my @computed_times;
    
    for(my $i=0; $i < scalar(@YMD); $i++ ){
       push(@computed_times, &days_from_now($YMD[$i] , $now) );
    }
    # Test single value in arg list
    my ($year, $month, $day) = Today();
    $now = "$year-$month-$day";
    push(@computed_times, &days_from_now($now) );
    is_deeply( \@computed_times, \@computed_times_expected, "'days_from_now' ... unit tests" );

    done_testing();
    exit(0);
}
############    END Main    ####################

