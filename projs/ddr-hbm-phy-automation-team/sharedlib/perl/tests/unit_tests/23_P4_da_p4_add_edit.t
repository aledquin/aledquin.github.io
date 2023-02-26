#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use v5.14.2;

use Capture::Tiny ':all';
use Test2::Bundle::More;
use Test2::Tools::Compare;
#use File::Slurp;
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
our $DEBUG      = NONE;
our $VERBOSITY  = NONE;
our $VERSION    = '2022ww35';

sub Main() {
    
    utils__process_cmd_line_args();

    test_basic_add();    
        
    done_testing( );
    return(0); 
}

sub test_basic_add {

    # Create temporary client
    my $abs_path = "//wwcad/msip/projects/alpha/alpha_common/wiremodel/... //TEMP_CLIENT_DDR_HBM_2/wwcad/msip/projects/alpha/alpha_common/wiremodel/...";
    my $files = [$abs_path];
    my $client = da_p4_create_client( "TEMP_CLIENT_DDR_HBM_2" , "/tmp/DDR_HBM_TEMP_CLIENT_2", $files);
    
    # Sync the root
    my ($out,$err) = run_system_cmd("p4 -c $client->{'NAME'} sync $client->{'ROOT'}/...");

    my $file = get_temp_filename("$client->{'ROOT'}/wwcad/msip/projects/alpha/alpha_common/wiremodel");
    dprint(HIGH,$file);    

    my $retval = da_p4_add_edit($client, $file);

    ok ($retval, 1);        

    # Delete the client
    da_p4_delete_client($client);

}

sub get_temp_filename($){
    
    my $location = shift;

    my $file = "$location/TEMP.LOG";

    # write out a whole file from a scalar
    Util::Misc::write_file("TESTING FILE FOR ADDING", $file);

    return $file;

}

Main();
