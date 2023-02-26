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
use Util::DateUtilities; # Today, get_YMD_from_jira_CreatedDate

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
    my $href = {
            'P80001562-79669' => {
                    'fields/created' => '2020-09-09T08:19:57.872-0700',
                    'fields/updated' => '2021-03-08T22:19:23.859-0800'
            },
            'P80001562-79670' => {
                    'fields/created' => '2020-09-09T08:20:01.223-0700',
                    'fields/duedate' => '2020-09-11',
                    'fields/updated' => '2021-03-08T22:18:01.408-0800'
            },
            'P80001562-79710' => {
                    'fields/created' => '2020-09-09T12:14:20.139-0700',
                    'fields/updated' => '2021-04-09T06:53:50.737-0700'
            },
    };
    my @list_of_YMD__got;
    my @list_of_YMD__expected = qw(
                2020-09-09 N/A-N/A-N/A 2021-03-08
                2020-09-09 N/A-N/A-N/A 2021-03-08
                2020-09-09 N/A-N/A-N/A 2021-04-09
    );

    foreach my $jira_id ( sort keys %$href ){
        my $cnt++;
        my($y,$m,$d);
        ($y,$m,$d) = get_YMD_from_jira_CreatedDate( $href->{$jira_id}{'fields/created'} );
        push(@list_of_YMD__got , "$y-$m-$d" );
        $cnt++;
        ($y,$m,$d) = get_YMD_from_jira_CreatedDate( $href->{$jira_id}{'fields/duedate'} );
        push(@list_of_YMD__got , "$y-$m-$d" );
        $cnt++;
        ($y,$m,$d) = get_YMD_from_jira_CreatedDate( $href->{$jira_id}{'fields/updated'} );
        push(@list_of_YMD__got , "$y-$m-$d" );
        $cnt++;
    }
    is_deeply( \@list_of_YMD__got, \@list_of_YMD__expected, "'get_YMD_from_jira_CreatedDate' ... unit tests" );

    done_testing();
    exit(0);
}
############    END Main    ####################

