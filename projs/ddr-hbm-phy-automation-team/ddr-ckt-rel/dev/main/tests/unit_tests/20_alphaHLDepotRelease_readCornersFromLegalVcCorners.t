use strict;
use warnings;
use 5.14.0;

use Test2::Bundle::More;
use File::Temp;
use Data::Dumper;
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../lib/perl/";
use alphaHLDepotRelease;
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;


our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $FPRINT_NOEXIT = 1;

sub Main() {

    my %tests = (
        test1 => {
            'msg'              => "Test file does not exist",
            'rel_header_base'  => "headerbase?",
            'proj_abs_path'    => "$RealBin/../data/alphaHLDepotRelease",
            'expected'         => [ ],
            'error_text'       => "-F- Failed to find legalVcCorners.csv",
        },
        test2 => {
            'msg'              => "File found but it's empty",
            'rel_header_base'  => "headerbase?",
            'proj_abs_path'    => "$RealBin/../data/alphaHLDepotReleaseHasDesignLegalVcCorners",
            'expected'         => [ ],
            'error_text'       => "-F- No contents found in",
        },
        test3 => {
            'msg'              => "Ensure we do not get into an infinite loop",
            'rel_header_base'  => "headerbase?",
            'proj_abs_path'    => "$RealBin/../data/alphaHLDepotReleaseHasDesignLegalVcCornersInfiniteLoop",
            'expected'         => [ ],
            'error_text'       => "-F- release corners header file only has whitespace",
        },
        test4 => {
            'msg'              => "Checking file has contents but invalid",
            'rel_header_base'  => "headerbase?",
            'proj_abs_path'    => "$RealBin/../data/alphaHLDepotReleaseHasDesignLegalVcCornersInvalid",
            'expected'         => [ ],
            'error_text'       => "-F- release corners header file was not as expected",
        },
        test5 => {
            'msg'              => "Checking a valid file",
            'rel_header_base'  => "Corner Type\tCase\tCore Voltage (V)\tPLL Voltage (V)\tIO Voltage (V)\tTemperature (C)\tExtraction Corner",
            'proj_abs_path'    => "$RealBin/../data/alphaHLDepotReleaseHasDesignLegalVcCornersValid",
            'expected'         => [ 'case110p0v99c' ],
        },
        test6 => {
            'msg'              => "Checking existing file but not using floating point for IO voltage",
            'rel_header_base'  => "Corner Type\tCase\tCore Voltage (V)\tPLL Voltage (V)\tIO Voltage (V)\tTemperature (C)\tExtraction Corner",
            'proj_abs_path'    => "$RealBin/../data/alphaHLDepotReleaseHasDesignLegalVcCornersdBadVoltage",
            'expected'         => [ 'case110p0v99c' ],
            'error_text'       => 'VC release corners 20 PLL voltage is expected to be',
        },
    );

    my $ntests = keys(%tests);
    plan($ntests);

    foreach my $test ( sort keys %tests ) {
        my $msg             = $tests{$test}->{'msg'};
        my $rel_header_base = $tests{$test}->{'rel_header_base'};
        my $proj_abs_path   = $tests{$test}->{'proj_abs_path'};
        my $aref_expected   = $tests{$test}->{'expected'};
        my @corners_vc;
       
        if ( exists $tests{$test}->{'error_text'} ) {
            my $file_stderr = "/tmp/${RealScript}_stderr_$$";
            my $file_stdout = "/tmp/${RealScript}_stdout_$$";
            do {
                local *STDERR;
                local *STDOUT;
                open(STDERR, ">", $file_stderr) || die "$!";
                open(STDOUT, ">", $file_stdout) || die "$!";
                @corners_vc = &readCornersFromLegalVcCorners($rel_header_base, 
                    $proj_abs_path);
            };
            if ( -e $file_stderr && ! -z $file_stderr) {
                my $errorText = $tests{$test}->{'error_text'};
                my @list = read_file( $file_stderr );
                my $content = join "\n",@list;
                ok( $content =~ m/$errorText/, "$test $msg" );
            }
        }else{
            @corners_vc = &readCornersFromLegalVcCorners( $rel_header_base, 
                $proj_abs_path);
            is_deeply( \@corners_vc, $aref_expected, "$test $msg");
        }
    }

    done_testing();

    return 0;
}

Main();

