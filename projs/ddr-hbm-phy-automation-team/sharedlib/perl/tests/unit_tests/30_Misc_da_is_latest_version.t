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
            'version'  =>  'dev',
            'bindir'   =>  "",
            'expected' =>  TRUE
        },
        '02'=>{
            'version'  =>  '2022.09',
            'bindir'   =>  "/remote/cad-rep/msip/tools/Shelltools/ddr-ckt-rel/2022.09/bin",
            'expected' =>  FALSE 
        },
    );

    utils__process_cmd_line_args();
    # Current planned test count
    my $ntests = keys %tests;
    plan($ntests);

    #-------------------------------------------------------------------------
    #  Test 'da_is_latest_version'
    #-------------------------------------------------------------------------
    foreach my $key (sort keys(%tests)) {
        my $scriptBin= $tests{"$key"}{'bindir'};
        my $expected = $tests{"$key"}{'expected'};
        my $version  = $tests{"$key"}{'version'};
        my $latest   = NULL_VAL;

        my $bool_ret = &da_is_latest_version( $version, $scriptBin, \$latest );
        ok( $bool_ret == $expected, "$key. da_is_latest_version expected=$expected returned=$bool_ret current version=$version latest version is $latest");
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
