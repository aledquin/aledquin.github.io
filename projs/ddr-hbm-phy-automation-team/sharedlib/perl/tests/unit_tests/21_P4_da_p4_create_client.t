#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use v5.14.2;

use Data::Dumper;
use Capture::Tiny ':all';
use Test2::Bundle::More;
use Test2::Tools::Compare;
use File::Temp;
use Term::ANSIColor;
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
our $VERSION    = '2022ww43';

sub Main() {
    
    utils__process_cmd_line_args();

    my %tests =( 
        'test1' => {'name' => EMPTY_STR, 
                    'root' => "/tmp/test-client",
                    'views'=> [] # anonymous list (creates an array ref)
        },        
        'test2' => {'name' => "test-client", 
                    'root' => EMPTY_STR,
                    'views'=> [] # anonymous list (creates an array ref)
        },    
        'test3' => {'name' => EMPTY_STR, 
                   'root' =>  EMPTY_STR,
                   'views'=> [] # anonymous list (creates an array ref)
        },    
        'test4' => {'name' => undef, 
                    'root' => "/tmp/test-client",
                    'views'=> [] # anonymous list (creates an array ref)
        },        
        'test5' => {'name' => "test-client", 
                    'root' => undef,
                    'views'=> [] # anonymous list (creates an array ref)
        },    
        'test6' => {'name' => undef, 
                   'root' =>  undef,
                   'views'=> [] # anonymous list (creates an array ref)
        },    
        'test7' => {'name' => "test-client", 
                    'root' => "/tmp/test-client",
                    'views'=> undef 
        },
    );
    
    plan(12);

    # Test non-existant names/roots
    foreach my $key ( sort keys( %tests ) ){
        my $href_t = $tests{"$key"};
        my $name   = $href_t->{'name'};
        my $root   = $href_t->{'root'};
        my $views  = $href_t->{'views'};
        
        my $expected = NULL_VAL;
        ok( $expected eq da_p4_create_client( $name , $root, $views ), "check fail conditions for da_p4_create_client");
    }

    #--------------------------------------
    # Test successful creation
    my $expected = {};
    $expected->{'NAME'}         = "TEMP_CLIENT_DDR_HBM_A1";
    $expected->{'ROOT'}         = "/tmp/DDR_HBM_TEMP_CLIENT_A1";
    $expected->{'DEPOT2CLIENT'} = {};
    $expected->{'CLIENT2DEPOT'} = {};

    my $answer = da_p4_create_client( $expected->{'NAME'} , $expected->{'ROOT'}, []);
    dprint(LOW, "da_p4_create_client answer =>\n\t'".scalar(Dumper $answer)."'\n" );
    is_deeply($answer, $expected, 
        "da_p4_create_client '$expected->{'NAME'}' '$expected->{'ROOT'}'");
    
    my $username = get_username();
    my ($out, $ret) = run_system_cmd("p4 clients -u $username");
    vhprint(MEDIUM, "GOT:    '$out'\n");
    vhprint(MEDIUM, "EXPECT: '$expected->{'NAME'}' in stdout.\n");
    ok ($out =~ /.*$expected->{'NAME'}.*/ig, "p4 clients -u $username" );

    ($out, $ret) = run_system_cmd("p4 client -d $expected->{'NAME'}");
    if ($out !~ /.*deleted.*/ig){
        eprint("Client not deleted.\n");
    }
    
    # Test successful creation with files
    my $expected2 = {};
    $expected2->{'NAME'}         = "TEMP_CLIENT_DDR_HBM_B1";
    $expected2->{'ROOT'}         = "/tmp/DDR_HBM_TEMP_CLIENT_B1";
    $expected2->{'DEPOT2CLIENT'} = {};
    $expected2->{'CLIENT2DEPOT'} = {};
    
    my $client_name = $expected2->{'NAME'};
    my $client_root = $expected2->{'ROOT'};

    my $files_abs_path = "//depot/abc/xyz //TEMP_CLIENT_DDR_HBM_B1/abc/xyz";
    my $files = [$files_abs_path];
    my $answer2 = da_p4_create_client( $client_name , $client_root, $files);
    dprint(LOW, "da_p4_create_client answer2 =>\n\t'".scalar(Dumper $answer2)."'\n" );
    is_deeply($answer2, $expected2, "da_p4_create_client '$client_name' '$client_root'");
        
    ($out, $ret) = run_system_cmd("p4 clients -u $username");
    dprint(HIGH, $out."\n");
    ok ($out =~ /.*$client_name.*/ig, "p4 clients -u '$username'");

    ($out, $ret) = run_system_cmd("p4 client -o $client_name");
    dprint(HIGH, $out."\n");
    ok ($out =~ /.*$files_abs_path.*/ig, "p4 client -o '$client_name'");

    ($out, $ret) = run_system_cmd("p4 client -d $client_name");
    dprint(HIGH, $out."\n");
    if ($out !~ /.*deleted.*/ig){
        eprint("Client not deleted.\n");
    }

    done_testing( );
    return(0); 
}

Main();
