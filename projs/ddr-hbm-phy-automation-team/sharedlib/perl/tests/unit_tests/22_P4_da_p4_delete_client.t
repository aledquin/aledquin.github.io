#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use v5.14.2;

use Capture::Tiny ':all';
use Test2::Bundle::More;
use Test2::Tools::Compare;
use File::Temp;
use File::Path qw(make_path);
use Term::ANSIColor;
use Data::Dumper;
use Cwd 'abs_path';
$Term::ANSIColor::EACHLINE = "\n";  # Resets the color after each newline...
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::P4;
use Util::Misc;
use Util::Messaging;

our $STDOUT_LOG = undef;
our $DEBUG      = 0;
our $VERBOSITY  = 0;
our $VERSION    = '2022.11';

sub Main() {
    
    utils__process_cmd_line_args();

    test_basic_deletion();
    test_deletion_with_nonexistant_client();
        
    done_testing( );
    return(0); 
}

sub test_basic_deletion {

     # Test successful creation with files
    my $expected2 = {};
    $expected2->{'NAME'}         = "TEMP_CLIENT_DDR_HBM_2";
    $expected2->{'ROOT'}         = "/tmp/DDR_HBM_TEMP_CLIENT_2";
    $expected2->{'DEPOT2CLIENT'} = {};
    $expected2->{'CLIENT2DEPOT'} = {};
    
    my $client_name = $expected2->{'NAME'};

    my $abs_path = "//depot/abc/xyz //TEMP_CLIENT_DDR_HBM_2/abc/xyz";
    my $files = [$abs_path];
    my $answer2 = da_p4_create_client( $client_name , $expected2->{'ROOT'}, $files);
    is_deeply($answer2, $expected2, "da_p4_create_client $client_name disk:'$expected2->{'ROOT'}'");
        
    # Ensure that the client has been created
    my $username = get_username();
    my ($out, $ret) = run_system_cmd("p4 clients -u $username", $VERBOSITY);
    dprint(HIGH, "p4 clients -u OUT:\n".$out."\n");
    ok ($out =~ /.*$client_name.*/ig, "p4 clients -u $username");

    # Delete the client
    da_p4_delete_client($answer2);
    dprint(HIGH, "ran da_p4_delete_client(\$answer2)\n");

    # Ensure that the client has been deleted
    ($out, $ret) = run_system_cmd("p4 clients -u $username", $VERBOSITY);
    dprint(HIGH, "p4 clients -u OUT:\n".$out."\n");
    ok ($out !~ /.*$client_name.*/ig, "da_p4_delete_client test");

}

sub test_deletion_with_nonexistant_client {
    
    # Test successful creation with files
    my $expected2 = {};
    $expected2->{'NAME'}         = "TEMP_CLIENT_DDR_HBM_2";
    $expected2->{'ROOT'}         = "/tmp/DDR_HBM_TEMP_CLIENT_2";
    $expected2->{'DEPOT2CLIENT'} = {};
    $expected2->{'CLIENT2DEPOT'} = {};
    
    dprint(INSANE, Dumper($expected2)."\n");

    # Make temporary path
    my $directory = $expected2->{'ROOT'};
    make_path $directory;

    # Ensure that the client has been created
    my $username = get_username();
    
    # Delete the client without creating it
    da_p4_delete_client($expected2);

    dprint (HIGH, Dumper( -d "$directory")."\n");

    my $answer = defined(-d $directory);
    if ($answer eq ''){
        ok (1, 1, "da_p4_delete_client nonexistant force-ok answer='$answer'");
    }
    else {
        ok (1, 0, "da_p4_delete_client nonexistant force-notok answer='$answer'");
    }
}

Main();
