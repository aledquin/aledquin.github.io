#!/depot/perl-5.14.2/bin/perl
#!/usr/bin/env perl

use strict;
use Devel::StackTrace;
use Data::Dumper;
use File::Copy;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use FindBin qw($RealBin $RealScript);

use lib dirname(abs_path $0) . '/../lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#----------------------------------#
#our $STDOUT_LOG   = undef;
our $STDOUT_LOG   = EMPTY_STR;
our $DEBUG        = SUPER;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $VERSION      = '1.0';
#----------------------------------#


BEGIN { header(); } 
   Main();
END { write_stdout_log("${PROGRAM_NAME}.log"); footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {
   my ($product , $user_specified_only_this_project ) = process_cmd_line_args();
   #test_find_string_in_list();
   # In this Script the following conventions are followed:
   #    products = lpddr54, ddr54, hbm2, hbm2e, hbm3
   #    products => these are found in p4 under path //depot/products/ 
   print "User specified product : '$product'\n";  
   print "User specified project : '$user_specified_only_this_project'\n";  

   fatal_error( "Project name must be in the form 'd###' and for LP54/DDR54/HBM (i.e. 'd8##')\n" ) unless( $user_specified_only_this_project =~ m/^d\d\d\d$/ || !defined $user_specified_only_this_project );
   # Setup the data structure that captures the list of projects to check
   # for a given product and stores the: 
   #      P4 path to the product tree + 
   #      list of ALL components across all projects listed +
   #      info for each project (stored in a href)
   # is stored in the top level data struct. For each project, we store
   # 'p4path' + 'components'.
   my $href_projects = build_list_of_projects( $product , $user_specified_only_this_project );
	 
   # Search P4 for list of component names in each project
	 foreach my $project ( keys %{$href_projects} ){
	    my $href_proj = $href_projects->{$project};
      dprint(SUPER, scalar( Dumper $href_proj ) . "\n" );
	    my ( @components ) = retrieve_p4_components_list( $project, $href_proj->{p4path} );
	    $href_proj->{components} = \@components;
      dprint(SUPER, scalar(Dumper \@components) . "\n" );
   }

   # Create list of components that is the UNION of all components across all projects
   # in a given product family 
	 foreach my $project ( keys %{$href_projects} ){
	    my $href_proj = $href_projects->{$project};
      foreach my $component ( @{$href_proj->{components}} ){
	       $href_projects->{all_components}{$component}++;
      }
   }
   
   #----------------------------------------------------------------------------
   foreach my $component ( sort keys %{$href_projects->{all_components}} ){
	    dprint(FUNCTIONS, "Cross-checking '$component' across all projects.\n" );
	    foreach my $project ( sort keys %{$href_projects} ){
	       next if( $project =~ m/all_components/ );
	       my $href_proj  = $href_projects->{$project};
	       my @components = @{$href_proj->{components}};
         # build a string that captures the mapping of component across the projects
         if( find_string_in_list($component, @components) ){
            $href_projects->{all_components}{$component} .= " $project"; 
         }else{
            $href_projects->{all_components}{$component} .= "  -  "; 
         }
         dprint(HIGH, "Cross-checking ... hash looks like \n". scalar(Dumper $href_projects) . "\n" ); 
      }
   }
   dprint(MEDIUM, scalar(Dumper $href_projects) . "\n" ); 

   #----------------------------------------------------------------------------
   my $report_msg = generate_report_of_components( $href_projects->{all_components} );
   print $report_msg;

   exit(0);
}

############    END Main    ####################


#---------------------------------------------------------------------------
#   Build the data structure to capture the data slurp from P4
#   EXAMPLE for the product hbm2e
#   $href = {
#       'hbm2e' => {
#           'projects' => {
#               'd714' => {
#                   'components' => [],
#                   'p4path' => '//depot/products/hbm2e/project/d714-hbm2e-tsmc7ff18/ckt/rel'
#                },
#               'd716' => {
#                   'components' => [],
#                   'p4path' => '//depot/products/hbm2e/project/d716-hbm2e-tsmc7ff18/ckt/rel'
#                },
#               'd740' => {
#                   'components' => [],
#                   'p4path' => '//depot/products/hbm2e/project/d740-hbm2e-tsmc5ffp12/ckt/rel'
#                },
#               'd741' => {
#                   'components' => [],
#                   'p4path' => '//depot/products/hbm2e/project/d741-hbm2e-ss4lpp12/ckt/rel'
#                }
#            }
#       }
#   };
#   
#---------------------------------------------------------------------------
sub build_list_of_projects(){
   my $product = shift;
   my $user_specified_only_this_project = shift;
   my $basepath = "//depot/products/$product/project/.../ckt/rel/dwc...";
   my $href;

   my $cmd = "p4 files -e $basepath";
   my ($stdout, $retval) = run_system_cmd( $cmd, $DEBUG );

   my %p4paths;
   foreach my $line ( split(/\n+/, $stdout )){
       next unless( !defined $user_specified_only_this_project || $line =~ m/$user_specified_only_this_project/ );
       chomp( $line );
       my $p4_component_path = $line;
       $p4_component_path =~ s/\/dwc.*//;
       $p4paths{p4_component_path} = $p4_component_path;
       my $project = (split( /\//, $line ))[6];
       my $proj_codename = $project;
       $proj_codename =~ s/-.*//;
       $href->{$product}{projects}{$proj_codename} = { 'p4path' => $p4_component_path, 'components' => [], };
   }

   dprint(MEDIUM, "Built this data structure for '$product' from p4 depot:\n" . scalar(Dumper $href) . "\n" );
   return( $href->{$product}{projects} );
}

#---------------------------------------------------------------------------
# REPORTING Portion of the script
#---------------------------------------------------------------------------
sub generate_report_of_components($){
   print_function_header();
   my $href = shift;

   dprint(HIGH, scalar(Dumper $href) . "\n" ); 
   #---------------------------------------------------------------------------
   # Find the max # chars in a component's name so report can have 
   #    column alignment across the rows
   my $maxlen = 0;
	 foreach my $component ( keys %{$href} ){
	    if( length $component > $maxlen ){ $maxlen = length $component; }
	 }
   dprint(MEDIUM, "MAX Character length of component is '$maxlen'\n" );
   
   #  Print the data collected on each component
   #  FORMAT :  Component Name Count  Projects it was included in a release
   #  EXAMPL :  dwc_ddrphy_por  12    d801 d802 d803 d804 d805 d806 d807 d809 d810 d819 d820 d839 
   my(@table);
	 foreach my $component ( keys %{$href} ){
      my $strlen  = length $component;
      my $padding = $maxlen - $strlen;
      my $row = "$component"." "x$padding . $href->{$component} ; 
      push(@table, $row);
   }

   #  Setup the Column Headers
   my $padding = $maxlen - length("Name of Component") -1;
   print "-"x120 . "\n";
   print "Name of Component"." "x$padding . "Cnt    Projects where Component Was Found\n";
   print "-"x120 . "\n";
   
   #  Sort (numerically) by the Component CNT value 
   my @sorted = sort { (split(/\s+/, $b))[1] <=> (split(/\s+/, $a))[1] } @table;
   
   return( join("\n", @sorted) );
}

#------------------------------------------------------------------------------
# Setup and run a couple tests on the function 'find_string_in_list'
#------------------------------------------------------------------------------
sub test_find_string_in_list () {
   print_function_header();
    my @list;
    my $elem;
    my $found = FALSE;

    @list = [ qw(1 2 3 4 5 6 7a) ];
    $elem = '7a';
    $found = find_string_in_list( $elem, @list );
    $found ? print "FALSE\n" : print "TRUE\n";

    @list = [ qw(1 2 3 4 5 6 7a) ];
    $elem = '7';
    $found = find_string_in_list( $elem, @list );
    $found ? print "FALSE\n" : print "TRUE\n";
}

#------------------------------------------------------------------------------
# Given a string and an array of strings, search for the string in the array
# If found, return TREU, otherwise return FALSE
#------------------------------------------------------------------------------
sub find_string_in_list ($@) {
   my $str  = shift;
   my @list = @_;

   my $found = FALSE;
   my $elements = join(' ' , @list);
   if( $elements =~ m/$str/ ){
      $found = TRUE;
   }else{
      $found = FALSE;
   }

   return( $found );
}

#------------------------------------------------------------------------------
#  Build hash of the components in a given project
#------------------------------------------------------------------------------
sub retrieve_p4_components_list ($) {
   print_function_header();
    my $project = shift;
    my $path    = shift;
    
    my( %components, %strange_components );
    # search p4 proj path for components ... expect they begin with dwc
    # Save the list of files from p4 so they can be cross-checked by inspector
    #   so remove everything after the '#' from p4 listing
    my $proj_fname = "$project.rel.txt";
    my $cmd = "p4 files -e $path/... |grep -v -e symlink | sed -s 's/#.*//g' > $proj_fname";
    my ($stdout, $retval) = run_system_cmd( $cmd, $DEBUG );
    iprint( "Writing list of files in release to '$proj_fname'\n" );
       $cmd = "p4 files -e $path/...";
       ($stdout, $retval) = run_system_cmd( $cmd, $DEBUG );
    foreach my $line ( split(/\n+/, $stdout) ){
        chomp($line);
        $line =~ s/\#.*$//g;
        $line =~ s|/| |g;
        #print "$line\n";
          my @tokens = split(/\s+/, $line);
        if( $tokens[8] =~ m/^dwc/ ){
            $components{$tokens[8]}++;
        }else{
            $strange_components{$tokens[8]}++;
        }
    }
    foreach my $name ( keys %strange_components ){
       wprint( "Expected component name starting w/'dwc_' ... ignored '$name'\n" );
    }
    return( keys %components  );
};


###############################################################################
sub process_cmd_line_args(){

   my( $debug_lvl, $help, $product, $project );
   GetOptions ("d=i" => \$debug_lvl,   # numeric
               "p=s" => \$product,   # string
               "j=s" => \$project,   # string
               "h"   => \$help,    # flag
   );

   if ( !defined $product || $help || ( defined $debug_lvl && $debug_lvl !~ m/^\d*$/ ) ){  
      my $msg  = "USAGE:  $PROGRAM_NAME -p <product> -j <project> \n";
         $msg .= "... add debug statments with -d #\n";
         $msg .= "Examples: \n";
         $msg .= "\t $PROGRAM_NAME -p ddr54\t -j d810 \t-d 1\n";
         $msg .= "\t $PROGRAM_NAME -p lpddr54\n";
      iprint( $msg );
      exit;
   }   

   # decide whether to alter DEBUG variable
   # '-v' indicates DEBUG value ... set based on user input
   if( defined $debug_lvl && $debug_lvl =~ m/^\d*$/ ){  
      $DEBUG = $debug_lvl;
   }

   return( ($product, $project) );
}
