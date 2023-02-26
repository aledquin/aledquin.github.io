use strict;
use warnings;
use 5.14.0;

use Test2::Bundle::More;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::Messaging;

our $DEBUG = 0;
our $STDOUT_LOG = '';

BEGIN {
    plan(3); 
}

sub Main() {
   
    logger("Line1");

    ok( $STDOUT_LOG eq "Line1", "Testing logger()");

    logger("Line2");
    ok( $STDOUT_LOG eq "Line1Line2", "Testing logger()");


    $STDOUT_LOG = undef;
    logger("Line3");
    ok( ! $STDOUT_LOG , "Testing logger()");

    done_testing();

    return 0;
}

Main();

