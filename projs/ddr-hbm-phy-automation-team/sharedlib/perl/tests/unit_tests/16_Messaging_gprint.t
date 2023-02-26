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
    my $expected1 = colored("This is test1\n", 'green');
    my $expected2 = colored("This is test2\n", 'green');
    my $expected3 = colored("This is test1", 'green');
    my $expected4 = colored("This is test2", 'green');
    my $expected5 = colored("This is test1\n", 'green');
    my $expected6 = colored("This is test2\n", 'green');
   
    plan(8); 
    ok(stdout_is(\&gprint, "This is test1\n", $expected1), 'Test gprint() STDOUT');
    ok(stdout_is(\&gprint, "This is test2\n", $expected2), 'Test gprint() STDOUT');
    ok(stdout_is(\&gprint, "This is test1",   $expected3), 'Test gprint() STDOUT');
    ok(stdout_is(\&gprint, "This is test2",   $expected4), 'Test gprint() STDOUT');
    $main::AUTO_APPEND_NEWLINE = TRUE;
    ok(stdout_is(\&gprint, "This is test1\n", $expected1), 'Test gprint() STDOUT');
    ok(stdout_is(\&gprint, "This is test2\n", $expected2), 'Test gprint() STDOUT');
    ok(stdout_is(\&gprint, "This is test1",   $expected5), 'Test gprint() STDOUT');
    ok(stdout_is(\&gprint, "This is test2",   $expected6), 'Test gprint() STDOUT');

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

