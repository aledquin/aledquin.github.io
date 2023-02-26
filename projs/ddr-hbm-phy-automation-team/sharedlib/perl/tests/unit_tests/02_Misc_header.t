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
    plan(3);

    my @expected = (
'',
'',
'#######################################################',
'###  Date , Time\s+:.*',
'###  Begin Running\s+:.*',
'###  Author\s+:.*',
'###  Release Version\s+:.*',
'#######################################################',
'',
    );

    ok( &stderr_is( \&header, \@expected ), "header()" );
    ok( &stderr_is( \&header, \@expected ), "header()" );
    ok( &stderr_is( \&header, \@expected ), "header()" );

    done_testing();
}

sub get_temp_filename(){
    my $fh = File::Temp->new(
        TEMPLATE => 'unit_test_02_Misc_header_stderr_XXXXX',
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}


sub stderr_is($$$) {
    my $ref_func        = shift;
    my $aref_expected   = shift;

    my $temp_file  = get_temp_filename();
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
    #unlink($temp_file) if ( -e $temp_file);

    my $passed=1;
    foreach my $line ( @lines ) {
        chomp($line);
        my $expected = shift( @$aref_expected ) || '';
        if ( $line !~ m/$expected/ ) {
            $passed = 0;
            last;
        }
    }

    return( $passed );
}

Main();

