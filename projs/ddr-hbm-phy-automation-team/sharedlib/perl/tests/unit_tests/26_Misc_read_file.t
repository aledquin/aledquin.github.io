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
        'test01' => [-1, []],
        'test02' => [0, ["line1","line2","line3","line4"] ] ,
    );

    my $ntests = keys %tests;
    plan( $ntests);

    foreach my $key (sort keys(%tests)) {
        my @output  ;
        my $fname   = $tests{$key};
        my $estatus = $expected{$key}[0];
        my $arefExpectedOutput = $expected{$key}[1];

        do {
            local *STDERR;
            open(STDERR, ">>", "/dev/null");
            @output = &read_file($fname );
        };

        my $nlines = @output;
        is_deeply( \@output, $arefExpectedOutput);
    }

    done_testing();

    return 0;
}

Main();

