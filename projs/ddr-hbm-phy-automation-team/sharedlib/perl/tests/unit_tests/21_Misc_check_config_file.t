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
our $USERNAME = $ENV{'USER'};

sub Main() {
    my %tests = (
        'test01' => ["nosuchfile" , undef],
        'test02' => ["$RealBin/../data/Misc_check_config_file.config" , "TCL"],
        'test03' => ["$RealBin/../data/Misc_check_config_file.config" , "JSON"],
        'test04' => ["$RealBin/../data/Misc_check_config_file_bad.config" , "TCL"],
        'test05' => ["$RealBin/../data/Misc_check_config_file_sample.txt" , "TCL"],
    );
    my %expected = (
        'test01' => [-1],
        'test02' => [0],
        'test03' => [-2],
        'test04' => [1],
        'test05' => [0],
    );

    my $ntests = keys %tests;
    plan( $ntests);

    foreach my $key (sort keys(%tests)) {
        my $fname   = $tests{$key}[0];
        my $format  = $tests{$key}[1];
        my $estatus = $expected{$key}[0];

        my $status = &check_config_file($fname, $format);
        $format = "undef" if ( !defined $format );
        ok( $status == $estatus, "check_config_file $key file = $fname config = $format" );

    }

    done_testing();

    return 0;
}

Main();

