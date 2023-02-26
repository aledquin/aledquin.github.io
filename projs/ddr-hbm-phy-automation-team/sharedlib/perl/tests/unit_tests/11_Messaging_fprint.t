use strict;
use warnings;
use 5.14.0;

use Test2::Bundle::More;
use File::Temp;
use Term::ANSIColor;
$Term::ANSIColor::EACHLINE = "\n";  # Resets the color after each newline...

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::Messaging;

our $DEBUG = 0;
our $VERBOSITY = 0;

BEGIN {
    plan(2); 
}

sub Main() {
    my $expected1 = colored("-F- This is test1\n", 'white on_red');
    my $expected2 = colored("-F- This is test2\n", 'white on_red');
   
    eval {
        ok(stderr_is(\&fprint, "This is test1\n", $expected1), 'Test fprint() STDERR');
        ok(stderr_is(\&fprint, "This is test2\n", $expected2), 'Test fprint() STDERR');
    };

    done_testing();

    return 0;
}

sub get_temp_filename($){
    my $prefix = shift;
    my $fh = File::Temp->new(
        TEMPLATE => "${prefix}_test_XXXXX",
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}

sub stderr_is($$$) {
    my $ref_print  = shift;
    my $print_what = shift;
    my $expected   = shift;
    my $temp_file  = get_temp_filename("fprint");
    do {
        local *STDERR;
        unlink($temp_file) if ( -e $temp_file );
        open(STDERR, '>', $temp_file) || return 0;
        $ref_print->($print_what);
    };
    my $fh;
    open($fh, '<', $temp_file) || return 0;
    my @lines = <$fh>;
    close($fh);
    #unlink($temp_file) if ( -e $temp_file);
    return( $lines[0] eq $expected);
}

Main();

