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
use Util::DateUtilities; # Today, delta_weeks

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

    # Date pairs, ordered lists
    my @YMD_earlier = qw( 2016-12-31 2019-12-30  2020-12-30  2020-01-01  2020-01-01  2020-01-01  2020-02-10  2020-10-03  2020-10-00  2020-10-00 ); 
    my @YMD_later   = qw( 2017-01-01 2021-01-01  2021-01-01  2021-12-30  2020-12-30  2020-02-00  2020-03-10  2020-12-30  2020-12-30  2020-12-00 ); 
    dprint(CRAZY+10, "Test: \@YMD_earlier   = (" .join(',', @YMD_earlier ) .")\n" );
    dprint(CRAZY+10, "Test: \@YMD_later     = (" .join(',', @YMD_later   ) .")\n" );

    my @computed_times_expected = ( 0, 52, 0, 104, 52, NULL_VAL, 4, 12, NULL_VAL, NULL_VAL );
    my @computed_times;

    if( scalar(@YMD_earlier) == scalar(@YMD_later) ){
        for(my $i=0; $i < scalar(@YMD_earlier); $i++ ){
            push(@computed_times, delta_weeks( $YMD_earlier[$i], $YMD_later[$i] ) );
        }
    }else{
        fatal_error( "In ". get_call_stack() ."\n ...the list sizes were different!\n");
    }

    is_deeply( \@computed_times, \@computed_times_expected, "'delta_weeks' ...  unit tests" );

    done_testing();
    exit(0);
}
############    END Main    ####################

