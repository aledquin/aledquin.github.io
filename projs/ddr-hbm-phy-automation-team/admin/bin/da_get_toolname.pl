#!/depot/perl-5.14.2/bin/perl
#+
# Purpose:
#   To be used by other scripts to try and determine which tool they are
#   associated with.
#
# Author:
#   James Laderoute
#
# Created:
#   2022/09/26
#
# Example:
#
#   da_get_toolname.pl {some_path_to_the_bindir}
#
# Example inside a script:
#
#   my ($output, $status) = run_system_cmd("da_get_toolname.pl $main::RealBin:");
#   chomp $output;
#   my $toolname = $output;
#
# History:
#   001 James Laderoute 2022/09/26
#       Created this script.
#-

# nolint utils__script_usage_statistics

use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use FindBin qw($RealBin $RealScript);

our $DEBUG     = 0;
our $VERBOSITY = 0;
my $NULL_VAL   = 'N/A';

sub Main(){
    my $symScript = $0;             # name of the program (even if it's a symlink)
    my $binDir    = shift @ARGV;

    if ( ! $binDir ) {
        $binDir = $main::RealBin; # the abs_path of the script location
    }

    # if $symScript is a symbolic link, then return rel2abs of $0
    if ( -l $symScript ){
        $binDir = File::Basename::dirname( File::Spec->rel2abs($symScript) ); 
    }

    if ( $DEBUG ) {
        print "DEBUG: symScript is '$symScript'\n";
        print "DEBUG: binDir is '$binDir'\n";
    }


    my $toolname = getToolName($binDir);
    print "$toolname\n";
    exit(0);
}

sub getToolName($){
    my $binDir = shift;

    if ( $binDir ){
        my @dirs    = split( "/", $binDir );
        my @dirsRev = reverse @dirs;
        my $folder  = shift @dirsRev;

        #print ("\$folder='$folder'\n");
        #print ("\$dirsRev ='" . join(",", @dirsRev) . "'\n");

        if ( $folder eq "bin" ){
            $folder = shift @dirsRev;
            if ( $folder eq "main") {
                $folder = shift @dirsRev;
                if ( $folder eq "dev"){
                    $folder = shift @dirsRev;
                    return $folder;  # this should be the tool name
                } # when /dev/main/bin
            }else{
                # if folder is not 'main' then it's probably a release version.
                # We can check that using a regular expression
                # Releases are like  2022.10-3 or 2022.10
                if ( $folder eq "dev" ) {
                    $folder = shift @dirsRev;
                    return $folder;
                } # when dev/bin

                if ( $folder =~ m/^\d\d\d\d\.\d+/ ){
                    # Most likely is a release version
                    $folder = shift @dirsRev;  # should be the toolname
                    return $folder;
                } # when DATE/bin
            }
        }elsif($folder eq "admin") {
            $folder = shift @dirsRev;
            #print ("\$folder='$folder'\n");
            #print ("\$dirsRev ='" . join(",", @dirsRev) . "'\n");
            return "sharedlib";

        }elsif($folder eq "t" || $folder eq "tests" || $folder eq "unit_tests" ){
            $folder = shift @dirsRev;
            if ( $folder eq "sharedlib"){
                return $folder;
            } # when sharedlib/t
            if ( $folder eq "tests"){
                $folder = shift @dirsRev;
                if ( $folder eq "perl" ){
                    $folder = shift @dirsRev;
                    if ( $folder eq "sharedlib") {
                        return $folder;
                    }
                }
            }
            
            if( $folder eq "main" ){
                $folder = shift @dirsRev;
                if ( $folder eq "dev"){
                    $folder = shift @dirsRev;
                    return $folder;  # this should be the tool name
                } # when dev/main/t
            } # when tests/
        } # when tests
    }

    return( $NULL_VAL );
}

Main();

