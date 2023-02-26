use strict;
use warnings;
use v5.14.2;

use Test2::Bundle::More;
use File::Temp;
use Cwd 'abs_path';

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../lib/perl/";
use Util::CommonHeader;
use Util::Misc;

our $DEBUG      = 0;
our $VERBOSITY  = 0;
our $STDOUT_LOG = undef; 

our $DA_RUNNING_UNIT_TESTS = 1;
our $FPRINT_NOEXIT = 1;
our $USERNAME = $ENV{'USER'};

sub Main() {

    my @files = `ls $RealBin/../data/alphaHLDepotRelease/legalRelease/*.txt`;
    my $ntests = @files;
    plan( $ntests);

    my $format = "TCL";
    my $estatus = 0;     # 0 is success, means NO errors

    foreach my $fname (sort @files) {
        chomp $fname;
        my $status = &check_config_file($fname, $format);
        ok( $status == $estatus, "check_config_file file = $fname" );
    }

    done_testing();

    return 0;
}

Main();

