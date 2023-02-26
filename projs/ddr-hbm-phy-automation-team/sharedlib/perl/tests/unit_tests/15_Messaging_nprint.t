use strict;
use warnings;
use 5.14.0;

use Test2::Bundle::More;
use File::Temp;
use Term::ANSIColor;
$Term::ANSIColor::EACHLINE = "\n";  # Resets the color after each newline...

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Messaging;

our $DEBUG = 0;
our $AUTO_APPEND_NEWLINE;

sub Main() {
    my $expected1 = "This is test1\n";
    my $expected2 = "This is test2\n";
   
    plan(6); 
    ok(stdout_is(\&nprint, "This is test1\n", $expected1), 'Test nprint() STDOUT');
    ok(stdout_is(\&nprint, "This is test2\n", $expected2), 'Test nprint() STDOUT');
    $main::AUTO_APPEND_NEWLINE = TRUE;
    ok(stdout_is(\&nprint, "This is test1\n", $expected1), 'Test nprint() STDOUT');
    ok(stdout_is(\&nprint, "This is test2\n", $expected2), 'Test nprint() STDOUT');
    ok(stdout_is(\&nprint, "This is test1", $expected1), 'Test nprint() STDOUT');
    ok(stdout_is(\&nprint, "This is test2", $expected2), 'Test nprint() STDOUT');


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
    #unlink($temp_file) if ( -e $temp_file);
    return( $lines[0] eq $expected);
}

Main();

