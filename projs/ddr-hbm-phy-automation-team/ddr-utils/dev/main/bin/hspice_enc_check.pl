#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : hspice_enc_check.pl
# Author  : Helen Cui
# Date    : 09/03/2022
# Purpose : Ensure that the hspice netlists are encrypted.
#
# Modification History
#     000 Helen Cui  09/03/2022
#         Created this script
#     001 Helen Cui 31/03/2022
#         Deleted unused functions
#     002 Haashim Shahzada 09/08/2022
#         Adding severities functionality
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
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Cwd;
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::P4;
use Util::QA;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $PREFIX       = "ddr-utils-original";
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version(); 
#--------------------------------------------------------------------#

BEGIN {
    our $AUTHOR='Helen Cui';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
Main();
END {
    local $?;   ## adding this will pass the status of failure if the script
                ## does not compile; otherwise this will always return 0
    footer();
    write_stdout_log("$LOGFILENAME");
    utils__script_usage_statistics("$PREFIX-$RealScript","$VERSION");
}

########  YOUR CODE goes in Main  ##############
sub Main {


   my ($paths, $severities) = init();   
   
   parse_severities($severities);

   if (!$paths) {
     
     eprint("Please specify the path\n");
     pod2usage(0);
     exit(0);

   }
		 
   my @files = glob "$paths/*.enc_*" ;
   
   if (!@files) {
     
     eprint("No enc files found in this directory\n");
     pod2usage(0);
     exit(0);

   }
   
   foreach my $file_enc (@files) {

      my @file = read_file( $file_enc );

      my $encrypted = 0;
      for (my $i = 0; $i < $#file; $i = $i + 1) {
      
         if($file[$i] =~ /.PROT/) {
	
	         $encrypted = $encrypted + 1;
            
         }
         
         else {
         
            $encrypted = $encrypted;
            
         }

      }

      get_verdict_enc_check($encrypted);
   }

   run_system_cmd("rm -rf $paths", 0);
     
}
############    END Main    ####################

#------------------------------------------------------------------------------
# Parse command line arguments
#------------------------------------------------------------------------------
sub init(){

      
   my ($severities, $help, $path, $ic, $success, $project_string, $macro, $depotPath, $customDepotPath );

   $severities = NULL_VAL;

   ## get specified args
   $success = GetOptions(
      "help!"     => \$help,
      "d=s"       => \$DEBUG,
      "proj=s"    => \$project_string,            
      "macro=s"   => \$macro,
      "path=s"    => \$path,      
      "depotPath=s" => \$customDepotPath,
      "severity=s" => \$severities
   );
	
   if ($help){
      &usage(0);
	}
   
   dprint LOW, "Debugger setting: $DEBUG\n";

   if ($project_string and $macro) {
 
      my ($family, $project, $release) = parse_project_spec($project_string, \&usage);    

      # Set the depot path for the hspice folder
      if ($macro) {
         $depotPath = "//depot/products/$family/project/$project/ckt/rel/$macro/$release/macro/hspice";  
      }
      if ($customDepotPath) {
         $depotPath = "$customDepotPath/ckt/rel/$macro/$release/macro/hspice";	
      }

      dprint MEDIUM, "$family $project $release $macro\n";
      dprint LOW, "The depot path is: $depotPath.\n";	

      $path = get_netlists($depotPath);

   }
   elsif ( $path ){
      $path = $path;    
   }
   else { 
      # pod2usage(   -verbose => 2,
      #        		  -noperldoc => 1  );
      &usage(1);
   }
    
   dprint LOW, "Debugger setting: $DEBUG\n";
   return( $path, $severities );

};

#------------------------------------------------------------------------------
# Download netlist and testbenches from Perforce.
#------------------------------------------------------------------------------
sub get_netlists($) {

   my $depotPath = shift;
   my $path      = find_netlists($depotPath);
   my @array     = @{$path};

   if ($path eq NULL_VAL){      
      fatal_error ("Could not find files under Perforce path $depotPath.\n");      
   }

   my $time = time();
   my $directory = time()."-enc-check";
   my $PATH = "/tmp/$directory";

   # Make directory
   mkdir($PATH);

   hprint ("Downloading encrypted netlists to $PATH.\n");

   foreach my $file (@array) {

      my @array_of_splits = split("/", $file);
      my $filename        = $array_of_splits[-1];
      my $net             = "$PATH/$filename";

      if ($filename !~ /enc_/ig) {
         next;
      }

      dprint (HIGH, "Downloading $file to $net. File sizes may exceed disk capacity.\n");

      my ($out1, $ret1) = run_system_cmd("p4 print -q $file > $net", $DEBUG);
      if ($out1 =~ /no such/ig) {
         eprint("File not downloaded for $file.\n");
      }

  }

   return ($PATH);

}

#------------------------------------------------------------------------------
# Download tb from Perforce.
#------------------------------------------------------------------------------
sub find_netlists($) {

   my $depotPath = shift;  

   my @dirs = da_p4_dirs("$depotPath/*"); 
   dprint(HIGH, Dumper(\@dirs)."\n");

   # Always chose the first metal stack directory
   my $chosePath = $dirs[0];
   
   my @files = da_p4_files("$chosePath/...");
  
   return \@files;   
   
}

sub get_verdict_enc_check($){
   my $encrypted = shift;
   
   if($encrypted > 0){
      alert(1, "This file is encrypted!", map_check_severity());
   } else {
      alert(0, "This file is not encrypted!", map_check_severity());      
   }
}

sub usage($) {
   my $exit_status = shift;

   print << "EOP" ;

   USAGE : $0 [options]

   command line options:
   -proj             specify the project string "product/project/release"
   -macro            specify the macro (ex. dwc_ddrpy_txrxac_ew)

   -d                set debugging level ( positive integer )
   -help             print this screen
   -severity         use a custom severities.json file	
   -depotPath        use a custom depotPath for the views (required for lp5x/ddr5 projects)

   USAGE WITH PROJ ARGUMENT:
   EXAMPLE: $0 -proj ddr43/d528-ddr43-ss11lpp18/rel1.00_cktpcs -macro dwc_ddrphy_txrxca_ew

EOP
   exit($exit_status);
}

__END__

=head1 NAME

hspice_enc_check

=head1 VERSION

2022ww22

=cut

our $VERSION = 2022ww14;

=head1 ABSTRACT

Ensure that the hspice netlists are encrypted.

=head1 DESCRIPTION

Check if the hspice netlists are encrypted.

=head1 OPTIONS

=head2 ARGS

=over 8

=item B<-h> 'usage: ./hspice_enc_check.pl -path <path to the directory containing hspice netlists>'

=back

=cut
