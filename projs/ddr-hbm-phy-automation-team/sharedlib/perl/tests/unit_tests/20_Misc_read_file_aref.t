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
        'test01' => "nosuchfile" ,
        'test02' => "$RealBin/../data/Misc_read_file_aref.txt" ,
    );
    my %expected = (
        'test01' => [-1, ["Failed to open 'nosuchfile'. Reason is 'No such file or directory'"]  ],
        'test02' => [0, ["line1","line2","line3","line4"] ] ,
    );

    my $ntests = keys %tests;
    # two sets of test, each test can potentially run ok() and is_deeply() which
    # would be 2 planned tests. We know that one of them is not expected to pass
    # the read so it won't call is_deeply(); that is why we subtract one for the
    # number of planned tests.
    plan( $ntests * 2 - 1);

    foreach my $key (sort keys(%tests)) {
        my @output  ;
        my $fname   = $tests{$key};
        my $estatus = $expected{$key}[0];
        my $arefExpectedOutput = $expected{$key}[1];

        my $status = &read_file_aref($fname, \@output);
        ok($status == $estatus, "status meets expected value");
        if ( 0 == $status ) {
            is_deeply( \@output, $arefExpectedOutput);
        }
    }

    done_testing();

    return 0;
}

Main();

