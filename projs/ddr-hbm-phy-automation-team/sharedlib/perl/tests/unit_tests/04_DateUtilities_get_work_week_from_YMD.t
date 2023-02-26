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
use Util::DateUtilities; # Today, get_work_week_from_YMD

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
    my @list_of_YMD = qw(
        violating dates 2001-0-0 2001-01-00 2001-00-00 2001-01-00

        1901-01-01 2001-01-01 2019-01-01
        2021-10-01 2022-11-01 2024-12-01
        3010-01-01 2024-12-31 2025-01-01

        2012-01-01 2012-12-31 2013-01-01 2013-12-31 
        2014-01-01 2014-12-31 2015-01-01 2015-12-31 
        2016-01-01 2016-12-31 2017-01-01 2017-12-31 
        2018-01-01 2018-12-31 2019-01-01 2019-12-31 

        2020-01-01 2020-12-31 2021-01-01 2021-12-31 
        2022-01-01 2022-12-31 2023-01-01 2023-12-31 
        2024-01-01 2024-12-31 2025-01-01 2025-12-31 
        2026-01-01 2026-12-31 2027-01-01 2027-12-31 

        2028-01-01 2028-12-31 2029-01-01 2029-12-31 
    );
    my @list_of_work_weeks__got;
    my @list_of_work_weeks__expected = qw(
        N/A N/A N/A N/A N/A N/A 
            1  1  1
            39 44 48
            1 53  1

            0	53	1	53
            1	53	1	53
            0	52	0	52
            1	53	1	53

            1	53	0	52
            0	52	0	52
            1	53	1	53
            1	53	0	52

            0	52	1	53
    );

    foreach my $YMD ( @list_of_YMD ){
        my ($y, $m, $d) =  split(/-/, $YMD);
        dprint(CRAZY, '($y, $m, $d)'." = ($y, $m, $d)\n" );
        push( @list_of_work_weeks__got , get_work_week_from_YMD($y,$m,$d) );
        my $i++;
    }

    is_deeply( \@list_of_work_weeks__got, \@list_of_work_weeks__expected, "'get_work_week_from_YMD' ... unit tests" );

    done_testing();
    exit(0);
}
############    END Main    ####################

