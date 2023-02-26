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

BEGIN {
    plan(4); 
}

sub Main() {
    my $expected1 = colored("-D- This is 06_Messaging_dprint test1\n", 'blue');
    my $expected2 = colored("-D- This is 06_Messaging_dprint test2\n", 'blue');
  
    is_deeply( stdout2_is(\&dprint, 0, "This is 06_Messaging_dprint test1\n"), $expected1, 'Test test1 dprint() STDOUT');
    is_deeply( stdout2_is(\&dprint, 0, "This is 06_Messaging_dprint test2\n"), $expected2, 'Test test2 dprint() STDOUT');

    $DEBUG = 1001;
       $expected1 = colored("Main -> 31 stdout2_is -> 59 :-D- This is 06_Messaging_dprint test1\n", 'blue');
       $expected2 = colored("Main -> 32 stdout2_is -> 59 :-D- This is 06_Messaging_dprint test2\n", 'blue');
    is_deeply( stdout2_is(\&dprint, 0, "This is 06_Messaging_dprint test1\n"), $expected1, 'Test test3 dprint() STDOUT');
    is_deeply( stdout2_is(\&dprint, 0, "This is 06_Messaging_dprint test2\n"), $expected2, 'Test test4 dprint() STDOUT');
    $DEBUG = 0;

    done_testing();

    return 0;
}

sub get_temp_filename(){
    my $fh = File::Temp->new(
        TEMPLATE => 'dprint_testXXXXX',
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}

sub stdout2_is($$$$) {
    my $ref_print  = shift;
    my $threshold  = shift;
    my $print_what = shift;

    my $temp_file  = get_temp_filename();
    do {
        local *STDOUT;
        unlink($temp_file) if ( -e $temp_file );
        open(STDOUT, '>', $temp_file) || return 0;
        $ref_print->($threshold, $print_what);
    };
    open(my $fh, '<', $temp_file) || return 0;
    my @lines = <$fh>;
    close($fh);
    unlink($temp_file) if ( -e $temp_file);
    my $nlines = @lines;
    if ( $nlines == 0 ) {
        return 0;
    }

    return( $lines[0] );
}

Main();

