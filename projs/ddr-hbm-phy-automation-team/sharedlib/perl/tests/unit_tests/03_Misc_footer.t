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
our $FPRINT_NOEXIT = 1;

sub Main() {
    plan(1);

    my @expected = (
'',
'',
'#######################################################',
'###  Goodbye World',
'###  Date , Time\s+:.*',
'###  End Running\s+:.*',
'###  Elapsed \(sec\)\s+:.*',
'###  Release Version\s+:.*',
'#######################################################',
    );

    ok( &stderr_is( \&footer, \@expected ), "footer()" );

    done_testing();

    return(1); 
}

sub get_temp_filename(){
    my $fh = File::Temp->new(
        TEMPLATE => 'unit_test_03_Misc_footer_stderr_XXXXX',
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}


sub stderr_is($$) {
    my $ref_func        = shift;
    my $aref_expected   = shift;

    my $temp_file  = get_temp_filename();
    #print("cat $temp_file\n");
    do {
        local *STDERR;
        unlink($temp_file) if ( -e $temp_file );
        open(STDERR, '>', $temp_file) || return 0;
        $ref_func->();
    };
    my $fh;
    open($fh, '<', $temp_file) || return 0;
    my @lines = <$fh>;
    close($fh);
    unlink($temp_file) if ( -e $temp_file);

    my $passed=1;
    my $lineno=0;
    foreach my $line ( @lines ) {
        chomp($line);
        $lineno += 1;
        my $expected = shift( @$aref_expected ) || '';
        #print("DEBUG:\n\t$line\n\t$expected\n");
        if ( $line !~ m/$expected/ ) {
            print("Not the same line $lineno:\n\tline     ='$line'\n\texpected ='$expected'\n");
            $passed = 0;
            last;
        }
    }

    #print("passed=$passed\n");
    return( $passed );
}

Main();
1;

