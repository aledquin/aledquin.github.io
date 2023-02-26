use strict;
use warnings;
use 5.14.0;

use Test2::Bundle::More;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::Messaging;
use Util::CommonHeader;

our $DEBUG = 0;

BEGIN {
    plan(4); 
}

sub Main() {
    
    ok(stdout_is(\&iprint, "This is a test\n", "-I- This is a test\n"), 
        'Test iprint() STDOUT');
    ok(stdout_is(\&iprint, "This is a second test\n", "-I- This is a second test\n"), 
        'Test iprint() STDOUT');

$DEBUG = CRAZY+1;

    is_deeply(stdout_is(\&iprint, "This is a test\n")       , "Main -> 29 stdout_is -> 55 :-I- This is a test\n"       , 'Test iprint() DEBUG > CRAZY+1');
    is_deeply(stdout_is(\&iprint, "This is a second test\n"), "Main -> 30 stdout_is -> 55 :-I- This is a second test\n", 'Test iprint() DEBUG > CRAZY+1');

    done_testing();

    return 0;
}

sub get_temp_filename(){
    my $fh = File::Temp->new(
        TEMPLATE => 'unit_test_01_Messaging_iprint_stdout_XXXXX',
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}

sub stdout_is($$$) {
    my $ref_print  = shift;
    my $print_what = shift;
    
    my $temp_file  = get_temp_filename();
    do {
        local *STDOUT;
        unlink($temp_file) if ( -e $temp_file );
        open(STDOUT, '>', $temp_file) || return 0;
        $ref_print->($print_what);
    };
    my $fh;
    open($fh, '<', $temp_file) || return 0;
    my @lines = <$fh>;
    close($fh);
    unlink($temp_file) if ( -e $temp_file);
    return( $lines[0] );
}

Main();

