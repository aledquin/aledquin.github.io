#!/depot/perl-5.14.2/bin/perl
#+
# Purpose:
#   
#   Looks in secret area for a file that contains a list of version numbers
#   that should be blocked.  So if a script's release version string matches
#   one in the file list, then this script prints "BLOCKED" otherwise it
#   will print "NOTBLOCKED"
#
# Author:
#   James Laderoute
#
# Created:
#   2022/09/26
#
# Example:
#
#   da_is_script_in_list_of_obsolete_versions.pl {version_of_script}
#
# Example inside a script:
#
#   my ($output, $status) = run_system_cmd("da_is_script_in_list_of_obsolete_versions.pl 2022.10");
#   chomp $output;
#   if ( $output eq "BLOCKED" ){
#       print("Some message letting the user know it's blocked\n");
#       exit(1);
#   }
#
# History:
#   001 James Laderoute 2022/09/26
#       Created this script.
#   002 James Laderoute 2022/10/19
#       Updated $VERSION to 2022.11
#-

# nolint utils__script_usage_statistics
#
use strict;
use warnings;

use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib/perl/";
use lib "$RealBin/../perl/lib";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

our $VERSION = '2022.11';

sub Main(){

    my $script_version = shift @ARGV;
    if ( $script_version ) {
        chomp $script_version;
    }

    my $result = __da_is_script_in_list_of_obsolete_versions($script_version);
    print "$result\n";
    exit(0);
}

sub __da_is_script_in_list_of_obsolete_versions($) {
    my $script_version = shift;

    my $alpha_dir       = "/remote/proj/alpha/alpha_";
       $alpha_dir      .= "common/bin";  #nolint
    my $secret_file     = "${alpha_dir}/ddr_da_releases.txt";
    my $developers_file = "${alpha_dir}/ddr_da_developers.txt";

    if ( exists( $ENV{'DDR_DA_TIMEBOMB_FILE'} )){
        $secret_file = $ENV{'DDR_DA_TIMEBOMB_FILE'};
    }
    if ( exists( $ENV{'DDR_DA_DEVELOPERS_FILE'} )){
        $developers_file = $ENV{'DDR_DA_DEVELOPERS_FILE'}; 
    }

    if ( ! -e $secret_file ){ # if no secret file is found then exit
        return ("NOTBLOCKED");
    }

    if ( -e $developers_file ){
        my $user = Util::Misc::get_username();
        my @content ;
        my $status = Util::Misc::read_file_aref( $developers_file, \@content );
        foreach my $user_name ( @content ){
            chomp $user_name;

            next if ( $user_name =~ m/^\s*$/); # skip empty lines
            next if ( $user_name =~ m/^\s*#/); # skip comments

            if ( $user eq $user_name ){
                return("NOTBLOCKED");
            }
        }
    }

    if ( ! $script_version ) {
        my $status;
        my $binDir = $main::RealBin;
        ($script_version, $status) = Util::Misc::run_system_cmd( "da_get_release_version.pl $binDir" );
        chomp $script_version;
        if ( $script_version eq NULL_VAL ){
            $script_version = $VERSION;  # the default version
        }
    }
    # is this version in the secret file?
    my $found_version = 0;
    my @contents;
    my $read_status = Util::Misc::read_file_aref( $secret_file, \@contents );
    foreach my $end_version ( @contents ) {
        chomp $end_version;
        next if ( $end_version =~ m/^\s*$/); # skip empty lines
        next if ( $end_version =~ m/^\s*#/); # skip comments
        $found_version = 1 if ( $end_version eq $script_version );
    }

    return "NOTBLOCKED" if ( ! $found_version );
    return "BLOCKED";
}

Main();

