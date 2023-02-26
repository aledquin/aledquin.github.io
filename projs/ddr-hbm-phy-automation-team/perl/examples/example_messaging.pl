#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;

use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../lib/";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;

our $VERBOSITY           = FUNCTIONS; # try using NONE and run this again, what happens?
our $AUTO_APPEND_NEWLINE = 1;
our $STDOUT_LOG          = EMPTY_STR;
our $DEBUG               = LOW;


sub Main(){
    iprint( "This text will be printed in the default color for the console with a '-I-' prefix\n");
    hprint( "Highlighted for grabbing attention\n" );
    wprint( "This text will be colored yellow\n" );
    eprint( "This text will be colored red\n" );
    p4print("This is green for printing p4 commands to the user.\n");
    
    my $threshold = FUNCTIONS;
    vwprint( $threshold, "vwprint only prints if \$main::VERBOSITY >= $threshold\n" );

    #Try to comment the $AUTO_APPEND_NEWLINE and see what happens
    hprint( "Multi\nLined\nPrint" );
    iprint( "This line ends with two newline characters. \n\n"  );
    wprint( "This line does not end with a newline character."  );
    eprint( "This line ends with a single newline character.\n" );
    
    my $sca = "scalar";
    dprint(LOW,"\$sca(scalar)    => $sca");
    my @arr = (1,2,3,4);
    dprint(LOW,"\@arr(array ref) => ".pretty_print_aref(\@arr));
    my %has = qw(key1 value1
                 key2 value2
                 key3 value3);
    $has{'arrRef'} = \@arr;
    my %subHash = qw(sk1 v1
                     sk2 v2
                     sk3 v3);
    $has{'subHashRef'} = \%subHash;
    dprint(LOW,"\%has(hash ref)  => ".pretty_print_href(\%has));

    
    write_stdout_log("${RealScript}.log");
    fatal_error( "The script will terminate after this statement" );
    iprint( "This won't be printed\n");
    exit(0);
}

Main();

