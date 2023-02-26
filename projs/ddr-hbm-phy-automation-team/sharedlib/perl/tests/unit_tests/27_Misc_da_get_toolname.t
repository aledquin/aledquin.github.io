use strict;
use warnings;
use v5.14.2;

use Test2::Bundle::More;
use File::Temp;
use Cwd 'abs_path';

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;
use TestUtils;

our $DEBUG      = 0;
our $VERBOSITY  = 0;
our $STDOUT_LOG = undef; 

our $DA_RUNNING_UNIT_TESTS = 1;
our $FPRINT_NOEXIT = 1;

sub Main() {
    plan(1);

    my $toolname = &da_get_toolname();
    ok( $toolname eq "sharedlib", "da_get_toolname toolname='$toolname', RealBin='$main::RealBin'");

    done_testing();

    return 0;
}

Main();

