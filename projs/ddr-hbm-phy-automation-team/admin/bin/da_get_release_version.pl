#!/depot/perl-5.14.2/bin/perl
#+
# Purpose:
#   
#   Looks for a /bin/.version file and prints the version out.
#
# Author:
#   James Laderoute
#
# Created:
#   2022/09/26
#
# Example:
#
#   da_get_release_version.pl {some_path_to_the_bindir}
#
# Example inside a script:
#
#   my ($output, $status) = run_system_cmd("da_get_release_version.pl $main::RealBin:");
#   chomp $output;
#   my $version = $output;
#
# History:
#   001 James Laderoute 2022/09/26
#       Created this script.
#   002 James Laderoute 2022/10/19
#       Updated version number to 2022.11
#-

# nolint utils__script_usage_statistics
# nolint open<
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
use Cwd;
use Carp    qw( cluck confess croak );

use FindBin qw($RealBin $RealScript);

# NOTE:  Trying to make this script independent of Util:: perl modules
#        The reason, because to locate the sharedlib/lib/Util in this script
#        would cause problems when it gets copied to Shelltools area.

my $EMPTY_STR = "";
my $TRUE      = 1;
my $FALSE     = 0;

our $VERSION = '2022.11';

sub Main(){

    my $binDir = shift @ARGV;

    my $version = getReleaseVersion($binDir);
    print "$version\n";
    exit(0);
}


sub getReleaseVersion(;$){
    my $scriptBin = shift;     # optional

    my $default_release_version  = $main::VERSION;
    my $version = "";

    if ( ! $scriptBin ){
        $scriptBin = $main::RealBin;
    }

    # We would like the version string to express the Shelltools release version
    # So, we will try and figure it out.
    # The release will contain a .version file from 2022.10 on. 
    # Look at the current bin area for it.
    if ( $scriptBin ) {
        my $vfile = "${scriptBin}/.version";
        if ( -e $vfile ) {
            my @contents;
            my $rstatus = __read_file_aref( $vfile, \@contents );
            if ( ! $rstatus ) {
                foreach my $txt ( @contents ){
                    chomp $txt;
                    next if ( $txt =~ m/^\s*$/ ); # blank lines
                    next if ( $txt =~ m/^\s*#/ ); # comment lines
                    $version = $txt;
                    last;  # we got something, assume it's a version string
                }
            }
        }
    }

    if ( $version eq "" ) {
        $version = $default_release_version;
    }

    return $version;
}

# NOTE: copied this from Util/Misc.pm
#
sub __isa_aref($){
   my $var = shift;
   if( "ARRAY" eq ref($var) ){ 
      return( $TRUE )
   }else{ 
      return( $FALSE ) 
   }
}

# NOTE: copied this from Util/Misc.pm
#
sub __read_file_aref($$;$){
   my $inFileName = shift;
   my $arefOutput = shift;  # will end up holding the contents of the file or
                            # an error message if open failed.
   my $readOptions= shift;  # any special directive to the open

   # make sure the user supplied both a filename and an array ref
   if ( ! $inFileName ){
       if ( $arefOutput && __isa_aref($arefOutput) ) {
           push(@$arefOutput, "Invalid filename argument passed to read_file_aref");
       }
       return -2;
   }
   if ( ! $arefOutput ){
       return -2;
   }
   if ( $arefOutput && !__isa_aref($arefOutput)) {
       # didn't pass in the correct reference type. Supposed to only pass this
       # a reference to an array.  
       # Example: 
       #    my @datum;
       #    my $errors = read_file_aref("file.txt", \@datum);
       #
       return -2;
   }

   $readOptions = $EMPTY_STR if ( !$readOptions); 

   my $open_status = open(my $fh, "<${readOptions}", "$inFileName") ;
   if ( $open_status ) {
       @$arefOutput = <$fh>;
       map {chomp $_} @$arefOutput;   ##no critic qw(ControlStructures::ProhibitMutatingListFunctions)
       close($fh);
       $open_status = 0;  # meaning, no errors
   }else{
       push( @$arefOutput, "Failed to open '$inFileName'. Reason is '$!'");
       $open_status = -1;
   }

   return($open_status);
}



Main();

