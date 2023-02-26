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
            'msg'         => "Test file does not exist",
            'legal_vfile' => "$RealBin/../data/alphaHLDepotRelease/legal_no_vfile.txt",
            'expected'    => { 'abc' => 1 },
            'error_text'  => "-F- While reading file.*",
        },
        test2 => {
            'msg'         => "Test file is empty",
            'legal_vfile' => "$RealBin/../data/alphaHLDepotRelease/legal_empty_vfile.txt",
            'expected'    =>{ 'abc' => 1 },
            'error_text'  => "-F- Failed to find any verifs.*",
            'warning_text'=> "-W- While reading file.*",
        },
        test3 => {
            'msg'         => "Test file is not empty but contains invalid data",
            'legal_vfile' => "$RealBin/../data/alphaHLDepotRelease/legal_invalid_vfile.txt",
            'expected'    =>{ 'abc' => 1 },
            'error_text'  => "-F- Each line of the .*project verif file are expected to be.*",
        },
        test4 => {
            'msg'         => "File exists and contains valid data",
            'legal_vfile' => "$RealBin/../data/alphaHLDepotRelease/legal_valid_vfile.txt",
            'expected'    => { 
                               'calibre/ant' => 'ant',
                               'calibre/drc' => 'drc',
                               'calibre/erc' => 'erc',
                               'calibre/lvs' => 'lvs',
                               'icv/ant' => 'ant',
                               'icv/drc' => 'drc',
                               'icv/erc' => 'erc',
                               'icv/lvs' => 'lvs',
                           },
        },
    );

    my $ntests = keys(%tests);
    plan($ntests);

    foreach my $test ( sort keys %tests ) {
        my $msg           = $tests{$test}->{'msg'};
        my $legal_vfile   = $tests{$test}->{'legal_vfile'};
        my $href_expected = $tests{$test}->{'expected'};
        my %legalVerifs ;
       
        if ( exists $tests{$test}->{'error_text'} ) {
            my $file_stderr = "/tmp/19_alphaHLDepotRelease_parseLegalVerifFile_errors$$";
            my $file_stdout = "/tmp/19_alphaHLDepotRelease_parseLegalVerifFile_warnings$$";
            do {
                local *STDERR;
                local *STDOUT;
                open(STDERR, ">", $file_stderr) || die "$!";
                open(STDOUT, ">", $file_stdout) || die "$!";
                %legalVerifs = &parseLegalVerifFile($legal_vfile);
            };
            if ( -e $file_stderr && ! -z $file_stderr) {
                my $errorText = $tests{$test}->{'error_text'};
                my @list = read_file( $file_stderr );
                my $content = join "\n",@list;
                ok( $content =~ m/$errorText/, $msg );
            }
        }else{
            %legalVerifs = &parseLegalVerifFile($legal_vfile);
            is_deeply( \%legalVerifs, $href_expected, "$test: parseLegalVerifFile - $msg");
        }
    }

    done_testing();

    return 0;
}

Main();

