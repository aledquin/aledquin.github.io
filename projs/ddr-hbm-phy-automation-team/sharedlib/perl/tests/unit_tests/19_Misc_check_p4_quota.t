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

our $DEBUG      = 0;
our $VERBOSITY  = 0;
our $STDOUT_LOG = undef; 

our $DA_RUNNING_UNIT_TESTS = 1;
our $FPRINT_NOEXIT = 1;
our $USERNAME = $ENV{'USER'};

sub Main() {
    my $trainingPath = "/u/$USERNAME/p4_ws/depot/products/training";
    my $p4Path = "$trainingPath/project/t125-training-tsmc7ff-1.8v/ckt/rel/dwc_ddrphy_txrxdqs_ns/1.00a/macro/dwc_ddrphy_txrxdqs_ns.pincheck";
    if ( ! -e $p4Path ) {
        print("-F- $RealScript won't work for you because you are missing the file '$p4Path' !\n");
        if ( ! -e $trainingPath ) {
            print("--- '$trainingPath' path is missing!\n");
        }
        exit(1);
    }

    my $absPath = abs_path($p4Path);

    my %tests = (
        'test01' => "nosuchfile" ,
        'test02' => "$RealBin/../data/test1" ,
        'test03' => "" ,
        'test04' => "$absPath" ,
    );
    my %expected = (
        'test01' => "Failed to check the quota because the destination file is not located in the user's perforce." ,
        'test02' => "Failed to check the quota because the destination file is not located in the user's perforce." ,
        'test03' => "Failed to check the quota because the destination file is not located in the user's perforce." ,
        'test04' => "Failed to find the quota for the filesystem .*" ,
    );

    my $ntests = keys %tests;
    plan( $ntests);

    foreach my $key (sort keys(%tests)) {
        my $fname = $tests{$key};
        # subroutine reference to sub 'check_p4_quota'
        my $value = &capture_stdout( \&check_p4_quota, $fname||"" );
        ok( $value =~ m/$expected{$key}/  , "'$key'  check_p4_quota => '$value'" );
    }

    done_testing();

    return 0;
}

sub get_temp_filename(){
    my $fh = File::Temp->new(
        TEMPLATE => 'testXXXXX',
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}


sub capture_stdout($$) {
    my $ref_func   = shift;
    my $func_param = shift;
    my $return_value = "";

    my $temp_file_stdout  = get_temp_filename();
    my $temp_file_stderr  = get_temp_filename();
    do {
        local *STDOUT;
        local *STDERR;
        unlink($temp_file_stdout) if ( -e $temp_file_stdout );
        unlink($temp_file_stderr) if ( -e $temp_file_stderr );
        open(STDOUT, '>', $temp_file_stdout) || return "";
        open(STDERR, '>', $temp_file_stderr) || return "";
        $return_value = $ref_func->($func_param);
    };
    unlink( $temp_file_stdout) if ( -e $temp_file_stdout );
    unlink( $temp_file_stderr) if ( -e $temp_file_stderr );

    return( "$return_value" );
}

Main();

