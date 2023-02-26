#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : ibis_release.pl
# Author  : Harsimrat Singh Wadhawan
# Date    : March 25, 2022
# Purpose : Make release package.
#           This is the release script that aims to create a release package out of this
#           Git repository. It will remove any unnecessary files and only keep the ones that
#           are need for a Shelltools release. 
#   
#           |-2022.03
#               |-ibis
#                   |-dev 
#                       |-main
#                           |-bin
#                           |-lib
#                           |-resources
###############################################################################
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Pod::Usage;
use Getopt::Std;
use JSON;
use Getopt::Long;  # GetOptions
use File::Basename qw( dirname );
use Cwd  qw( abs_path );
use Carp qw(cluck confess croak);
use FindBin qw($RealBin $RealScript);
use Time::Piece;

use lib "$FindBin::Bin/../lib";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::CommonHeader;
use Data::Dumper;
use POSIX qw(strftime); #strftime
use File::Slurper 'read_text';

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $VERSION      = '2022.03';
#--------------------------------------------------------------------#

use constant CFG_HOME => "/u/wadhawan/Desktop/Harsimrat/IBIS_QA/Config/config.json";

BEGIN{ our $AUTHOR='wadhawan'; header(); } 
Main();
END{
    write_stdout_log("${PROGRAM_NAME}.log");
    footer(); 
}

########  YOUR CODE starts here. Create a Main subroutine.  ##############

sub Main{

    my %options  = ( 'cfg'=>1, );
    my %defaults = ( 'cfg' => CFG_HOME );
    my @required = ();
    
    my ($config, $test, $subrelease) = script_process_cmd_line_args( \%options, \%defaults, \@required ); 
    
    unless( $options{'nousage_stats'} ){
        #utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@ARGV );
    }

    ##############################################################################
    # Ensure that the config file is available, otherwise use the default one.
    ##############################################################################
    if ( ! $config ) {
        wprint("Using default configuration file: ".CFG_HOME."\n");
        $config = CFG_HOME;
    }
    hprint( "Config file: $config\n");

    ##############################################################################
    # STEP #1 -- Parse JSON configuration file
    ##############################################################################    
    my $config_contents = read_text($config);
    dprint(CRAZY, $config_contents);
    if (! $config_contents ){
        fatal_error("Could not read config file contents.");
    }

    my $CFG_JSON        = decode_json($config_contents);
    if (! $CFG_JSON) {
        fatal_error("Could not decode json.");
    }
    dprint(CRAZY, Dumper($CFG_JSON)."\n");
    
    
    my $year            = strftime("%Y", localtime);;
    my $number_of_month = strftime("%m", localtime);
    my $RELEASE         = "$year.$number_of_month";  
    my $URL             = $CFG_JSON->{url};  
    my $PROJECT_ID      = $CFG_JSON->{id};
    my $PATH            = "$RELEASE/ibis/dev/main";

    if ($subrelease){
        $RELEASE = "$year.$number_of_month.$subrelease";
    }

    ##############################################################################
    # STEP #2 -- Obtain the latest tag
    ##############################################################################
    my $KEY = $ENV{GITLAB_API_KEY};
    my ($out_err, $retval) = run_system_cmd("curl --silent --header \"PRIVATE-TOKEN: $KEY\" https://snpsgit.internal.synopsys.com/api/v4/projects/$PROJECT_ID/repository/tags", $VERBOSITY);
    
    if ( $retval ){
        fatal_error ("Could not get latest tag.\n");
    }

    my $TAG_JSON = decode_json($out_err);
    if (! $TAG_JSON) {
        fatal_error("Could not decode json.");
    }
    dprint(CRAZY, Dumper($TAG_JSON)."\n");

    my @array = @{$TAG_JSON};
    my $tag_name = $array[0]->{name};
    iprint("Checking out tag: $tag_name\n");

    ##############################################################################
    # STEP #3 -- Checkout the tag
    ##############################################################################    

    hprint( "Repo URL: $URL\n");
    iprint ("Creating a release directory under: $RELEASE\n");
       
    if (! $test ) {
        my ($out_err, $retval) = run_system_cmd("git clone --single-branch -b $tag_name --recurse-submodules $URL $PATH", $VERBOSITY);
        if ( $retval ){
            fatal_error ("Could not clone directory succesfully.\n");
        }
    }

    ##############################################################################
    # STEP #4 -- Delete unnecessary files/directories.
    ##############################################################################
    my @DIRS_TO_DELETE = @{$CFG_JSON->{directories}};
    foreach my $dir (@DIRS_TO_DELETE) {
        run_system_cmd("rm -rf $PATH/$dir", $VERBOSITY);
    }

    my @FILES_TO_DELETE = @{$CFG_JSON->{files}};
    foreach my $file (@FILES_TO_DELETE) {
        run_system_cmd("rm -rf $PATH/$file", $VERBOSITY);
    }

    ##############################################################################
    # STEP #5 -- Done
    ##############################################################################
    iprint ("Release package created: $PATH\n");

}
############    END Main    ####################


#------------------------------------------------------------------------------
sub script_process_cmd_line_args($$$){
    
    my $href_options  = shift;
    my $href_defaults = shift;
    my $aref_required = shift;

    my ($config, $test, $subrelease, $help);

    my $get_status = GetOptions($href_options 
        , 'cfg=s'=> \$config
        , "d=s"  => \$DEBUG,                
        , 'verbosity' 
        , 'help' => \$help
        , 'test' => \$test
        , 'subrelease=s'=> \$subrelease
    );
    if ( $help ){
        pod2usage(   
            -verbose => 2,
            -noperldoc => 1  
        );
    }

    #
    # Make sure there are no missing REQUIRED arguments
    #
    my $have_required = 1;
    foreach my $argname ( @{$aref_required} ){
        next if $argname eq "REQUIRED_ARGUMENTS";
        if (   ! exists($href_options->{"$argname"} ) 
            || ! defined($href_options->{"$argname"} ) ){
            $have_required = 0;
            eprint( "Missing Required Argument -$argname\n" );
        }
    }
    if ( ! $have_required ){
        pod2usage(   
            -verbose => 2,
            -noperldoc => 1  
        );
        return(0);
    }

    #
    # Set defaults
    #
    foreach my $argname ( keys( %{$href_defaults} ) ){
        if ( ! exists( $href_options->{"$argname"} ) ){
            $href_options->{"$argname"} = $href_defaults->{"$argname"};
        }
    }

   # VERBOSITY will be used to control the intensity level of 
   #     messages reported to the user while running.
   my $opt_verbosity = $href_options->{'verbosity'};
   if( defined $opt_verbosity ){
      if( $opt_verbosity =~ m/^\d+$/ ){  
         $main::VERBOSITY = $opt_verbosity;
      }else{
         eprint( "Ignoring option '-v': arg must be an integer\n" );
      }
   }

   return($config, $test, $subrelease); ## success
};

__END__

=head1 NAME

ibis_release

=head1 ABSTRACT

Helps create a release for the IBIS tool.

=head1 DESCRIPTION

This script will clone the qa-scripts repository and its submodules, then remove any unnecessary files defined in the JSON configuration file specified via -cfg.

=head2 ARGS

=over 8

=item B<-help>          show this screen

=item B<-cfg>           specify the JSON configuration file.

=item B<-subrelease>    specify the subrelease number. (yyyy.mm.1, yyyy.mm.2)        

=item B<-test>          do not execute git clone command
    
=item B<-d>             specify debug value (positive integer)

=item B<-v>             specify verbosity value (positive integer)

=item B<-help>          print this message

=back

=cut





