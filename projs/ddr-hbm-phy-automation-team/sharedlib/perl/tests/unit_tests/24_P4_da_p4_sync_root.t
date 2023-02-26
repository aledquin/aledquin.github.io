#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use v5.14.2;

use Capture::Tiny ':all';
use Test2::Bundle::More;
use Test2::Tools::Compare;
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

    test_basic_sync();    
        
    done_testing( );
    return(0); 
}

sub test_basic_sync {

    # Create temporary client
    my $abs_path = "//wwcad/msip/projects/alpha/alpha_common/wiremodel/... //TEMP_CLIENT_DDR_HBM_2/wwcad/msip/projects/alpha/alpha_common/wiremodel/...";
    my $files = [$abs_path];
    my $client = da_p4_create_client( "TEMP_CLIENT_DDR_HBM_2" , "/tmp/DDR_HBM_TEMP_CLIENT_2", $files);
    
    # Sync the root
    my ($out,$err) = da_p4_sync_root($client);

    my $file = (-e "$client->{'ROOT'}/wwcad/msip/projects/alpha/alpha_common/wiremodel/README.txt");
    dprint(HIGH,$file);    

    if ($file) {
        ok(1,1);
    }
    else {
        ok(1,0);
    }

    # Delete the client
    da_p4_delete_client($client);

}

Main();
