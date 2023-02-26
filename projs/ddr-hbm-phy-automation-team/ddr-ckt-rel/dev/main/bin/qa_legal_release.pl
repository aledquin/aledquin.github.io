#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : qa_legal_release
# Author  : James Laderoute
# Date    : 2/7/2023
# Purpose : To examine a legal release file, to see if there might be 
#           invalid values being used or not.
#
# Modification History
#     000 ljames 2/7/2023
#         Created this script
#     001 YOURNAME DATE_OF_YOUR_CHANGES
#         Description of what you have changed.
#     
###############################################################################

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
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use alphaHLDepotRelease;   # to use the parser
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
our $STDOUT_LOG; 
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version();
our $TESTMODE     = 0;  # if set then your script should not do anything
                        # destructive like 'p4 submit' commands. Intead just
                        # print an info about it.
#--------------------------------------------------------------------#
BEGIN {
    our $AUTHOR='ljames';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
Main()  unless caller();
END {
   local $?;   # to prevent the exit() status from getting modified
   footer();
   write_stdout_log( $LOGFILENAME );
}

########  YOUR CODE goes in Main  ##############
sub Main {
   my @orig_argv    = @ARGV;  # keep this here because GetOpts modifies ARGV

   my( $opt_projSPEC, $opt_nousage, $opt_filename, $opt_p4ws ) = 
       process_cmd_line_args();

   unless( $main::DEBUG || $opt_nousage ) {
       utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@orig_argv);
   }

   my $file_name = get_legal_release_file($opt_projSPEC, $opt_filename);
   if ( ! $file_name ){
       fatal_error("Unable to locate the legalRelease.txt file!\n");
   }

   my %legalRelease;
   processLegalReleaseFile( $file_name, \%legalRelease);
   # The above function does not return anything.
   # To determine if this passed or failed we can look at some of the
   # value inside of the returned legalRelease hash table.
   #
   my $nkeys = keys %legalRelease;
   if ( $nkeys == 0 ){
       fatal_error("qa_legal_release.pl was unable to read file \"$file_name\"\n");
   }


   exit(0);  
}
############    END Main    ####################
sub get_legal_release_file($$){
   my $projSPEC = shift;
   my $filespec = shift;
   my $file_name;

   if ($projSPEC) {
       my $cad_rep_proj = "/remote/cad-rep/projects";
       my ($projType, $proj, $pcsRel) =  parse_project_spec( $projSPEC, \&usage );
       my $projPathAbs   = "${cad_rep_proj}/$projType/$proj/$pcsRel";
       my @projRelFiles;
       push (@projRelFiles, "$ENV{DDR_DA_MAIN}/tests/data/$RealScript/$projType.$proj.$pcsRel.legalRelease.yml") if ( defined $ENV{DDR_DA_MAIN} );
       push (@projRelFiles, "$ENV{DDR_DA_MAIN}/tests/data/$RealScript/$projType.$proj.$pcsRel.legalRelease.txt") if ( defined $ENV{DDR_DA_MAIN} );
       push (@projRelFiles, "$projPathAbs/design/legalRelease.yml");
       push (@projRelFiles, "$projPathAbs/design/legalRelease.txt");
       push (@projRelFiles, "$projPathAbs/design_unrestricted/legalRelease.yml");
       push (@projRelFiles, "$projPathAbs/design_unrestricted/legalRelease.txt");
       $file_name = firstAvailableFile(@projRelFiles);
    }else{
        $file_name = $filespec;
    }

    return $file_name;
}


sub usage($){
    my $exit_status = shift;
    my $message_text = "";
    my $verbose_level = 1;  ## The verbose level to use

    pod2usage({
        -message => $message_text ,
        -exitval => $exit_status,
        -verbose => $verbose_level,
        }
    );
}


#------------------------------------------------------------------------------
sub process_cmd_line_args(){
    my ( $opt_projSPEC, $opt_p4ws, $opt_debug, $opt_verbosity, $opt_help, 
         $opt_nousage,  $opt_dryrun, $opt_filename);
    my $status = GetOptions(
        "p=s"         => \$opt_projSPEC,
        "p4ws=s"      => \$opt_p4ws,
        "file=s"      => \$opt_filename,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "nousage"     => \$opt_nousage,  # when enabled, skip logging usage data
        "dryrun!"     => \$opt_dryrun,   # do not run destructive p4 commands
        "help"        => \$opt_help,     # Prints help
     );

    $main::VERBOSITY = $opt_verbosity if ( defined $opt_verbosity);
    $main::DEBUG     = $opt_debug     if ( defined $opt_debug );
    $main::TESTMODE  = 1              if ( defined $opt_dryrun && $opt_dryrun );

    if ( $opt_help ) {
        usage(0);
    }
    if ( $opt_filename && $opt_projSPEC ){
        fprint("The options -p and -file can not be used together.\n");
        usage(1);
    }
    if ( ! $opt_filename && ! $opt_projSPEC) {
        fprint("You must specify one of -p for projSPEC or -file for the full file path to the legalRelease.txt file\n");
        usage(1);
    }

    if ( ! $status ){
        # Something went wrong with the parsing of ARGV
        usage(1);
    }

    return($opt_projSPEC, $opt_nousage, $opt_filename, $opt_p4ws);
};
1;


__END__


=head1 NAME

 qa_legal_release.pl 

=head1 VERSION

 2023.02

=head1 ABSTRACT

 This lets you look at a design's legalRelease.txt file and analzye it to 
 look for problems.

=head1 SYNOPSIS

 qa_legal_release.pl \
    -p <projSPEC> \
    -file <filepath> \
    [-debug <level>] \
    [-verbosity <level>] \
    [-dryrun] \
    [-nousage] \
    [-help]

  This script was written to easily and quickly examine the legalRelease.txt file of your project.

=over 2

=item B<-p> 

  The projSPEC string. A projSPEC is a string that consists of "<project_type>/<project>/<CD_rel>" 

=item B<-file> 

  You can use -file <full-file-path> or use the -p projSPEC options to locate
  the legalRelease.txt file. You can not use both at the same time, you must
  choose one or the other way to locate the legalRelease.txt file.

=item B<-debug <level>>

=item B<-verbosity <level>>

=item B<-nousage>

=item B<-dryrun>

=item B<-help|-h> 

  Print this help message.

=back

=cut
