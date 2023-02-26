use strict;
use warnings;
use v5.14.2;

use Test2::Bundle::More;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;

our $DEBUG      = 0;
our $VERBOSITY  = 0;
our $STDOUT_LOG = undef; 
our $DA_RUNNING_UNIT_TESTS = 1;

sub Main() {
    plan(66);
    my @levels = (
        NONE,
        LOW,       
        MEDIUM,    
        FUNCTIONS, 
        HIGH,      
        SUPER,     
        CRAZY,     
        INSANE,     
        );
    my $filename = "$RealBin/../data/${RealScript}.lis";

    my $testcount=0;
    my $FID;
    open($FID, "<", $filename ) || die "Unable to find $filename";

    my $AU;
    my $createGolden = 0; # set this to 1 if you need to fix the expected results

    if ( $createGolden ){
        open($AU, ">", "${filename}.au");
    }

    foreach my $debug ( @levels ) {
        $main::DEBUG = $debug;
        foreach my $halt_level ( @levels ) {
            my $expected_stdout = <$FID> ;
            chomp( $expected_stdout );
            $testcount++;
            my $got = stdout_is($testcount, \&prompt_before_continue, $halt_level);
            if ( $createGolden ){
                print $AU "$got\n";
            }

            ok( $got eq $expected_stdout, "prompt_before_continue GOT='$got' EXPECTED='$expected_stdout' DEBUG=$debug HALT=$halt_level");
        }
    }
    close($FID);
    close($AU) if ( $createGolden );

    my $got = &stdout_is( ($testcount+1), \&prompt_before_continue, undef );
    ok( $got eq "EMPTY_STRING" );
    $got = &stdout_is( ($testcount+2), \&prompt_before_continue, 'hello' );
    ok( $got eq "EMPTY_STRING" );

    done_testing();
}

sub get_temp_filename(){
    my $fh = File::Temp->new(
        TEMPLATE => 'unit_test_01_Misc_prompt_before_continue_stdout_XXXXX',
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}


sub stdout_is($$$$) {
    my $testnum    = shift;
    my $ref_func   = shift;
    my $halt_level = shift;

    my $temp_file  = get_temp_filename();
    do {
        local *STDOUT;
        unlink($temp_file) if ( -e $temp_file );
        open(STDOUT, '>', $temp_file) || return 0;
        $ref_func->($halt_level);
    };


    my $fh;
    open($fh, '<', $temp_file) || return 0;
    my @lines = <$fh>;
    my $nlines = @lines;
    close($fh);
    unlink($temp_file) if ( -e $temp_file);
    
    my $gotvalue = $lines[0] || 'EMPTY_STRING';

    return( $gotvalue );
}

Main();

