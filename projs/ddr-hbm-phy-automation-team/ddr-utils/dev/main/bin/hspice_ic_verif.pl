#!/depot/perl-5.14.2/bin/perl
###############################################################################
# Name    : hspice_ic_verif.pl
# Author  : Harsimrat Wadhawan
# Date    : February 17, 2022
# Purpose : Matching initial conditions between hspice netlists and testbenches.
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
use List::MoreUtils qw(uniq);
use Cwd;
use constant FIFTY   => 50;
use constant MILLION => 1000000;

use lib "$RealBin/../lib/perl/";
use Util::Misc;
use Util::Messaging;
use Util::CommonHeader;
use Util::DS;
use Util::P4;
use Util::QA;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version();
our $PREFIX       = "ddr-utils-original";
#--------------------------------------------------------------------#
 
BEGIN {
    our $AUTHOR='wadhawan';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
Main();
END {
   footer();
   write_stdout_log("$LOGFILENAME");
   utils__script_usage_statistics("$PREFIX-$RealScript","$VERSION");
}

#  Procedure:
#  - Get list of .IC files and the netlists.
#  - Extract initial condition statements.
#  - Search for the intial conditions inside the netlist.
########  YOUR CODE goes in Main  ##############
sub Main {

   my ($help, $netlist, $ic, $engine, $severities) = init();

   parse_severities($severities);
   
   if ($ic eq NULL_VAL || $netlist eq NULL_VAL){
      fatal_error ("Could not find netlist or testbench.\n");
   }

   my %hierarchy    = ();
   my @netlist_file = ();
   my @ic_file = read_file($ic);    

   my @initial_conditions = extract_intial_conditions(\@ic_file);
   dprint (HIGH, Dumper(@initial_conditions)."\n");

   if (! @initial_conditions ){
      fatal_error("No inital conditions found inside the testbench. Exiting.\n")
   }
   
   # find nets and Process
   %hierarchy = grep_nets_in_netlist($netlist);   
   my %processed_conditions = process_initial_conditions(\@initial_conditions);     
   my @matched_results      = compare_initial_conditions_and_netlists(\%processed_conditions, \%hierarchy);
   
   get_verdict_ic_verif(\@matched_results ,\%processed_conditions);
   
   my @to_delete = ($netlist, $ic);
   cleanup(\@to_delete);

}
############    END Main    ####################
 
#------------------------------------------------------------------------------
# Parse command line arguments
#------------------------------------------------------------------------------
sub init(){
    
   my ($severities, $help, $macro_arg, $netlist, $ic, $success, $engine, $project_string, $macro, $depotPath, $customDepotPath );
   ($engine, $severities) = NULL_VAL;

   ## get specified args
   $success = GetOptions(
      "help!"     => \$help,
      "macro=s"   => \$macro_arg,		
      "ic=s"      => \$ic,		
      "d=s"       => \$DEBUG,
      "proj=s"    => \$project_string,            
      "macro=s"   => \$macro,
      "netlist=s" => \$netlist,
      "engine=s"  => \$engine,
      "depotPath=s" => \$customDepotPath,
      "severity=s" => \$severities
   );

   dprint LOW, "Debugger setting: $DEBUG\n";

   if ($project_string and $macro) {

      my ($family, $project, $release) = parse_project_spec($project_string, \&usage);    

      #Set the depot path for the hspice folder
      if ($macro) {
         $depotPath = "//depot/products/$family/project/$project/ckt/rel/$macro/$release/macro/hspice";  
      }
      if ($customDepotPath) {
         $depotPath = "$customDepotPath/ckt/rel/$macro/$release/macro/hspice";	
      }

      ($netlist, $ic) = find_netlist_and_testbench($depotPath);

      # When using proj and macro, set engine to zgrep.
      #     Just another arbitrary decision.
      $engine = "zgrep";

      dprint MEDIUM, "$family $project $release $macro\n";
      dprint LOW, "The depot path is: $depotPath.\n";	

   }
   elsif ( $ic and $netlist){
      $depotPath = NULL_VAL;    
   }
   else { usage(1); }

	&usage(0) if $help;
      
   dprint LOW, "Debugger setting: $DEBUG\n";
   dprint LOW, "IC: $ic\n";
   dprint LOW, "Netlist: $netlist\n";
   return( $help, $netlist, $ic, $engine, $severities);

};

#------------------------------------------------------------------------------
# Download netlist and testbenches from Perforce.
#------------------------------------------------------------------------------
sub find_netlist_and_testbench($) {

   my $depotPath = shift;
   my $netlist   = find_netlist($depotPath);
   my $testbench = find_testbench($depotPath);

   if ($testbench eq NULL_VAL || $netlist eq NULL_VAL){      
      fatal_error ("Could not find unencrypted netlist, or testbench under Perforce path $depotPath/METAL_STACK.\n");      
   }

   my $time = time();

   my $tb  = "/tmp/$time-testbench";
   my $net = "/tmp/$time-netlist";

   wprint ("Downloading netlist file and testbench files to /tmp. File sizes may exceed disk capacity.\n");

   my ($out1, $ret1) = run_system_cmd("p4 print -q $netlist   > $net", $DEBUG);
   if ($out1 =~ /no such/ig) {
      eprint("File not downloaded for $netlist.\n");
   }

   my ($out2, $ret2) = run_system_cmd("p4 print -q $testbench > $tb", $DEBUG);
   if ($out2 =~ /no such/ig) {
      eprint("File not downloaded for $netlist.\n");
   }

   return ($net, $tb);

}

#------------------------------------------------------------------------------
# Download netlist from Perforce.
#------------------------------------------------------------------------------
sub find_testbench($) {

   my $depotPath = shift;  

   my @dirs = da_p4_dirs("$depotPath/*"); 
   dprint(HIGH, Dumper(\@dirs)."\n");

   # Always chose the first metal stack directory
   my $chosePath = $dirs[0];
   
   my @files = da_p4_files("$chosePath/...");

   # Initialise the testbench string. Assume that we are trying to find tb_common.sp
   my $chosenFile = NULL_VAL;

   # Try finding the tb_common.sp file first
   foreach my $file (@files) {

      dprint(SUPER, $file."\n");

      if ($file =~ /tb_common\.sp/ig) {
         $chosenFile = $file;
         hprint("Found TB: $chosenFile.\n");
         return $chosenFile;
      }

   }

   # If it not found then try finding a random tb_.*sp file
   foreach my $file (@files) {

      dprint(SUPER, $file."\n");

      if ($file =~ /tb_.*\.sp/ig) {
         $chosenFile = $file;
         hprint("Found TB: $chosenFile.\n");
         return $chosenFile;
      }

   }

   return $chosenFile;
   
}

#------------------------------------------------------------------------------
# Download tb from Perforce.
#------------------------------------------------------------------------------
sub find_netlist($) {

   my $depotPath = shift;  

   my @dirs = da_p4_dirs("$depotPath/*"); 
   dprint(HIGH, Dumper(\@dirs)."\n");

   # Always chose the first metal stack directory
   my $chosePath = $dirs[0];
   
   my @files = da_p4_files("$chosePath/...");

   # Initialise the testbench string. Assume that we are trying to find tb_common.sp
   my $chosenFile = NULL_VAL;

   # Try finding the tb_common.sp file first
   foreach my $file (@files) {

      dprint(SUPER, $file."\n");

      if ( $file =~ /^((?!enc_).)*$/ig ) {
         
         if ( $file =~ /(xtcc|xtsrccpcc|spf|xtrcc)/i) {

            $chosenFile = $file;
            hprint("Found netlist: $chosenFile.\n");
            return $chosenFile;

         }

      }

   }
  
   return $chosenFile;   
   
}

#------------------------------------------------------------------------------
# Get Initial condition files and netlists
#------------------------------------------------------------------------------
sub extract_intial_conditions($) {

   print_function_header();

   my $content_ref = shift;   
   my @content = @{$content_ref};   

   my @ic_lines = ();

   for my $line (@content) {

      $line = trim($line); # trim the line      

      if ($line =~ /^\.ic.*\((.*?)\)\s?+=/ig) {
         
         my $path = $1;

         #remove the equal sign if it exists
         $path =~ s/=//g;
         push(@ic_lines, $path);

      }

   }

   print_function_footer();
   return @ic_lines;

}

#------------------------------------------------------------------------------
# Return normalised grep 
#------------------------------------------------------------------------------
sub process_initial_conditions($) {

   print_function_header();
   my $ic_ref = shift;
   my @initial_conditions = @{$ic_ref};

   @initial_conditions = uniq @initial_conditions;
   my %ic_hash = ();

   for ( my $ic = 0; $ic < @initial_conditions; $ic++ ){

      my $condition = $initial_conditions[$ic];      
      my $condition_dot = $condition =~ s/\.|\//\./igr;
      $ic_hash{$ic} = $condition_dot;           
 
   }

   print_function_footer();
   return %ic_hash;

}

#------------------------------------------------------------------------------
# Clean up remaining files
#------------------------------------------------------------------------------
sub cleanup($) {

   my $ref = shift;
   my @array = @{$ref};

   foreach my $value (@array) {
      unlink($value) or die "Can't delete $value: $!\n";
   }

}

#------------------------------------------------------------------------------
# Get the verdit
#------------------------------------------------------------------------------
sub get_verdict_ic_verif($$) {

   my $match_ref   = shift;
   my $process_ref = shift;

   my %processed_conditions = %{$process_ref};
   my @matched_results      = @{$match_ref};

   if (@matched_results) {      
      hprint("\nThe following initial conditions were found in the netlist:\n");
      foreach my $result (@matched_results){
         iprint("$result\n");;
      }      
   }
   else {
      eprint("No initial conditions matched. Netlist may be encrypted, and the contents may be unreadable.\n")
   }   
      
   # Output
   if (@matched_results < keys(%processed_conditions)) {wprint("The following initial conditions were not found in the netlist:\n");}
   foreach my $ic (keys %processed_conditions){
      my $value = $processed_conditions{$ic};
      $value =~ s/^.*?\.//; #Remove the first level of the hierearchy assuming that it is "XP."
      if ( $value ~~ @matched_results )  {}
      else {
         eprint "$value\n";
      }
   }

   if (@matched_results < keys(%processed_conditions)) {
      alert(0, "HSPICE IC Verification Check Failed", map_check_severity());
   }
   else {
      alert(1, "HSPICE IC Verification Check Passed", map_check_severity());
   }
   
}

#------------------------------------------------------------------------------
# Find nets in the netlist [Unused]
#------------------------------------------------------------------------------
sub find_nets_in_netlist($) {

   print_function_header();
   my $netlist_ref = shift;
   my @netlist = @{$netlist_ref};

   my @nets = grep {/^\*\|NET X.*/} @netlist;   
   my %hierarchy = ();

   for (my $i = 0 ; $i < @nets; $i++){

      $nets[$i] =~ s/\*\|NET//g;
      $nets[$i] = trim $nets[$i];

      # Get the first level of the hierarchy, and then store the netnames by that in a hash.
      my @splat = split(/\/|\./, $nets[$i]);
      
      #convert slashes to dots
      $nets[$i] =~ s/\//\./g;
      #remove trailing capacitance information and only keep the netlist hierarchy
      $nets[$i] =~ s/\s.*//g;
      insert_at_key(\%hierarchy, $splat[0], $nets[$i]);

   }

   print_function_footer();
   return %hierarchy;

}

#------------------------------------------------------------------------------
# Grep nets in the netlist 
#------------------------------------------------------------------------------
sub grep_nets_in_netlist($) {

   print_function_header();
   my $netlist = shift;      
   my %hierarchy = ();

   # Netlist warnings 
   my $size = -s $netlist;
   dprint( LOW, "Netlist size in bytes: $size");
   if ($size > (500 * MILLION)) {
      wprint("Large file size. Use the following session to avoid crashes 'qsh -p iwork'\n");
   }

   if ($netlist =~ /enc_/) {
      wprint("Netlist may be encrypted. Contents may be unreadable.\n")
   }

   # Use grep to obtain the necessary nets
   my $command = "zgrep -e '^\*\|NET X.*' $netlist";
   my ($std, $retval) = run_system_cmd($command, $VERBOSITY);   

   if ($retval){
      eprint($std);
   }

   # Split by newline
   my @nets = split(/\n/, $std);
   
   for (my $i = 0 ; $i < @nets; $i++){

      if ($nets[$i] !~ /^\*\|NET X.*/ig){         
         next;
      }

      $nets[$i] =~ s/\*\|NET//g;
      $nets[$i] = trim $nets[$i];

      # Get the first level of the hierarchy, and then store the netnames by that in a hash.
      my @splat = split(/\/|\./, $nets[$i]);
      
      # convert slashes to dots
      $nets[$i] =~ s/\//\./g;
      # remove trailing capacitance information and only keep the netlist hierarchy
      $nets[$i] =~ s/\s.*//g;
      insert_at_key(\%hierarchy, $splat[0], $nets[$i]);

   }

   print_function_footer();
   return %hierarchy;

}

#------------------------------------------------------------------------------
# Compare initial conditions and netlist
#------------------------------------------------------------------------------
sub compare_initial_conditions_and_netlists($$) {

   print_function_header();
   my $ic_ref = shift;
   my $hierarchy_ref = shift;

   my %processed_conditions= %{$ic_ref};
   my %hierarchy= %{$hierarchy_ref};

   my @conditions_results = ();

   # Check the initial conditions and find them inside the netlists
   foreach my $key (keys %processed_conditions){
      
      my $condition = $processed_conditions{$key};

      # Input:   XP.abc.xyz.def.ghi
      # Output: [XP, abc, xyz, def, ghi]
      my @splat = split(/\./,   $condition);            
      my $top_level = $splat[0];
      dprint (INSANE, "$top_level\n");

      # Ensure that the top level TB name is removed from the hspice netlist.
      # I: XP.xbe.abc.xyz
      # O: xbe.abc.xyz
      if (! grep {/^$top_level$/} keys(%hierarchy)  ) {
         $condition =~ s/$top_level\.//g;
         $top_level = $splat[1];         
      }            
   
      foreach my $net ( @{$hierarchy{"$top_level"}} ){                        
         if ($net =~ /^\Q$condition\E\z/i ){            
            dprint (HIGH, "$top_level : $condition\n");
            push(@conditions_results, $condition);
         }
      }

   }

   print_function_footer();
   return @conditions_results;

}

sub usage($) {
   my $exit_status = shift;

   print << "EOP" ;

   USAGE : $0 [options]

   command line options:
   -ic               testbench containing initial condition statements (required)
   -netlist          unencrypted, uncompressed hspice netlist (required)
   
   -proj             specify the project string "product/project/release"
   -macro            specify the macro (ex. dwc_ddrpy_txrxac_ew)

   -d                set debugging level ( positive integer )
   -engine [zgrep]   enable searching through zgrep    
   -help             print this screen	

   USAGE WITH PROJ ARGUMENT:
   EXAMPLE: $0 -proj ddr43/d528-ddr43-ss11lpp18/1.00a -macro dwc_ddrphy_txrxca_ew

   USAGE WITHOUT PROJ ARGUMENT
   EXAMPLE: $0 -ic testbench.sp -netlist netlist.spf

EOP
   exit($exit_status);
}

__END__

=head1 NAME

hspice_ic_verif.pl

=head1 VERSION

2022ww14

=head1 DESCRIPTION

This script will check for the existence of initial conditions paths within specified netlists.

=head2 ARGS

=over 8

=item B<-proj>    specify the project string which is of the form "product/project/release" 

=item B<-macro>   specify the macro (ex. dwc_ddrphy_txrxac_ew)

=item B<-ic>      testbench with initial conditions

=item B<-netlist> unencrypted hspice netlist

=item B<-d>       set debugging level ( positive integer )

=item B<-help>    send for help
	
=back
