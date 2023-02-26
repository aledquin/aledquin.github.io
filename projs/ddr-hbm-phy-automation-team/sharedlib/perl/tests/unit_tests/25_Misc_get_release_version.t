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
    my $hidden_file = "$RealBin/.version";
    my @list;
    my $rstatus = read_file_aref( $hidden_file, \@list );
    my $from_hidden_file = "2022.11";
    if ( ! $rstatus ) {
        $from_hidden_file = $list[0];
    }
    my $test_scriptbin= "$RealBin/../data/test_get_release_version";

    my %tests = (
        '01'=>{ 
            'input'    => undef,
            'expected' => $from_hidden_file 
        },
        '02'=>{ 
            'input'    => $test_scriptbin,
            'expected' => 'TestVersionValue', 
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
        my $bin_dir  = $tests{"$key"}{'input'};

        my $got_version = &get_release_version( $bin_dir );
        ok( $got_version eq $expected, "get_release_version $key $expected vs $got_version");
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
