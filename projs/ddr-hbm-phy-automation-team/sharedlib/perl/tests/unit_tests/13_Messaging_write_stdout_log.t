use strict;
use warnings;
use 5.14.0;

use Test2::V0;
use Test2::Bundle::More;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::Messaging;

our $DEBUG = 0;
our $VERBOSITY = 0;
our $STDOUT_LOG = '';

sub Main() {
   
    plan(3); 
    my $filename = get_temp_filename();;
    logger("Line1");
    logger("Line2");
    logger("Line3");
    write_stdout_log($filename);
    ok( -e $filename, "Testing write_stdout_log('$filename')");
    my $fh;
    if ( open($fh, '<', $filename) ) {
        my @lines = <$fh>;
        ok( $lines[0] eq "Line1Line2Line3\n", "Testing reading $filename" ); 
        close($fh);
    }

    ok( 0 != write_stdout_log(''), "Testing passing empty filename to write_stdout_log");
    
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


Main();

