use strict;
use warnings;
use 5.14.2;

use Test2::Bundle::More;
use File::Temp;
use Data::Dumper;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../lib/perl/";
use alphaHLDepotRelease qw(hashCheck);
use Util::Misc;

our $DEBUG         = 0;
our $VERBOSITY     = 0;
our $FPRINT_NOEXIT = 1;

sub Main() {

    my %t = (
        '01'=> {'varkey' => 'abc', 
                'filekey' => 'abc',
                'href'   =>  { 'abc'=>'1' },
                'prf'    => "prf",
                'action' => 'warn',
                'result' => 0,
               },
        '02'=> {'varkey' => 'abc', 
                'filekey' => 'abc',
                'href'   =>  {'xyz'=>'1' },
                'prf'    => "prf",
                'action' => 'exit',
                'result' => -1
               },
        '03'=> {'varkey' => 'abc', 
                'filekey' => 'abc',
                'href'   =>  {'xyz'=>'1' },
                'prf'    => "prf",
                'action' => 'warn',
                'result' => 1
               },
    );

    my $ntests = keys(%t);
    plan($ntests);

    my $stdout_file = "/tmp/18_alphaHLDepotRelease_hashCheck_stdout$$";
    my $stderr_file = "/tmp/18_alphaHLDepotRelease_hashCheck_stderr$$";

    foreach my $testnum (sort keys %t){
        my $href_tst = $t{"$testnum"};
        my $varkey = $href_tst->{'varkey'};
        my $filekey= $href_tst->{'filekey'}; # what is expected to be in the file
        my $href   = $href_tst->{'href'};
        my $prf    = $href_tst->{'prf'};
        my $action = $href_tst->{'action'};
        my $expected_value = $href_tst->{'result'};

        my @grab_stdout ;
        my @grab_stderr ;
        my $got_value=0;

        # we want to grab STDOUT
        do {
            local *STDOUT;
            local *STDERR;
            open(STDOUT, '>', $stdout_file) || return 0;
            open(STDERR, '>', $stderr_file) || return 0;

            $got_value = &hashCheck( $varkey, $filekey, $href, $prf, $action); 
        }; 
        
        my $fh; 
        my $efh;
        if ( open($fh, '<', $stdout_file) ){
            @grab_stdout = <$fh>;
            close($fh);
        } 
        
        if ( open($efh, '<', $stderr_file) ) {
            @grab_stderr = <$efh>;
            close($efh);
        }

        unlink $stdout_file if ( -e $stdout_file);
        unlink $stderr_file if ( -e $stderr_file);

        my $ngrab = @grab_stdout;
        if ( $ngrab ){
            my $line = join ",", @grab_stdout;
            if ( $action eq "warn" && ( $line =~ m/-W-/ )) {
                $got_value = 1;
                $expected_value = 1;
            }
        }

        $ngrab = @grab_stderr;
        if ( $ngrab ){
            my $line = join ",", @grab_stderr;
            if ( $action eq "error" && ( $line =~ m/-E-/ )) {
                $got_value = 1;
                $expected_value = 1;
            }
        }

        ok( $got_value == $expected_value, "$testnum hashCheck");
    }

	done_testing();

	return 0;
}
Main();

