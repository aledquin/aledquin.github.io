use strict;
use warnings;
use 5.14.0;

use Test2::Bundle::More;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::Messaging;

our $DEBUG = 0;
our $AUTO_APPEND_NEWLINE = 1;

BEGIN {
    plan(2); 
}

sub Main() {
    
    ok(stdout_is(\&iprint, "This is a test", "-I- This is a test\n"), 
        'Test AUTO_APPEND_NEWLINE');
    ok(stdout_is(\&iprint, "This is a second test\n\n", "-I- This is a second test\n"), 
        'Test AUTO_APPEND_NEWLINE');


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

sub stdout_is($$$) {
    my $ref_print  = shift;
    my $print_what = shift;
    my $expected   = shift;
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
    return( $lines[0] eq $expected);
}

Main();

