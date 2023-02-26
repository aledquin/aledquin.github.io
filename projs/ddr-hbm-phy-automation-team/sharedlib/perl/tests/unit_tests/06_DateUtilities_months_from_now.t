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
use Util::DateUtilities; # Today, months_from_now

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
                    2021-07-08  2021-01-01  2020-12-30
                    2020-02-00  2020-12-00
                ); 
    dprint(CRAZY+10, "Test: \@YMD= (" .join(',', @YMD) .")\n" );

    my @computed_times_expected = ( 0, 1, 1, 1, 5, 5, NULL_VAL, NULL_VAL, 0 );
    my @computed_times;
    
    for(my $i=0; $i < scalar(@YMD); $i++ ){
        push(@computed_times, months_from_now($YMD[$i] , $now) );
    }
    # Test single value in arg list
    my ($year, $month, $day) = Today();
    $now = "$year-$month-$day";
    push(@computed_times, months_from_now($now) );
    is_deeply( \@computed_times, \@computed_times_expected, "'months_from_now' ... unit tests" );

    done_testing();
    exit(0);
}
############    END Main    ####################

