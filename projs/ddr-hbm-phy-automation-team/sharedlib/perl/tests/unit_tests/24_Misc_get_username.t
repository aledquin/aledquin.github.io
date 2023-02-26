use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use FindBin qw($RealBin $RealScript);
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
#use Test2::Tools::Compare;
use Test2::Bundle::More;

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

our $PROGRAM_NAME = $0;
our $AUTHOR_NAME  = 'James Laderoute';
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $DEBUG_LOG = undef;
#----------------------------------#


Main();

########  YOUR CODE goes in Main  ##############
sub Main {
    my %tests = (
        '01'=>{ 
            'expected' => $ENV{'USER'}
        },
    );

    utils__process_cmd_line_args();
    # Current planned test count
    my $ntests = keys %tests;
    plan($ntests);

    #-------------------------------------------------------------------------
    #  Test 'get_username'
    #-------------------------------------------------------------------------
    foreach my $key (sort keys(%tests)) {
        my $expected = $tests{"$key"}{'expected'};
        my $uname = &get_username();
        ok( $uname eq $expected, "get_username $key $expected vs $uname");
    }

    done_testing();
    exit(0);
}
############    END Main    ####################


#-------------------------------------------------------------------------
#  Dummy usage function
#-------------------------------------------------------------------------
sub usage(){
    return(0);
}

1;
