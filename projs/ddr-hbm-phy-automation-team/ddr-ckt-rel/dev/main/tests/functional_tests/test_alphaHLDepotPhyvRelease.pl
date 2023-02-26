#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : alphaHLDepotPhyvRelease_test.pl
# Author  : Ahmed Hesham(ahmedhes)
# Date    : 03/10/2022
# Purpose : The script tests the alphaHLDeoptPhyvRelease script by preparing the
#           testcases, running the release script, and checking the output in 
#           the user's perforce. It then reverts any changes and deletes any 
#           files that were created in the process.
#
# Modification History
#     000 Ahmed Hesham  03/10/2022
#         Created this script
###############################################################################
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use File::stat;
use File::Path;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use alphaHLDepotRelease;

#--------------------------------------------------------------------#
#our $STDOUT_LOG          = EMPTY_STR; # Empty String: Log msg to var => ON
our $STDOUT_LOG         = undef;     # undef       : Log msg to var => OFF
our $AUTO_APPEND_NEWLINE = 1;
our $DEBUG               = NONE;
our $VERBOSITY           = NONE;
our $PROGRAM_NAME        = $RealScript;
our $VERSION             = get_release_version();
my $DDR_DA_DEFAULT_P4WS = "p4_func_tests";
#--------------------------------------------------------------------#

########  YOUR CODE goes in Main  ##############
sub Main {
   my ( $workspace, $opt_archive, $opt_gitlabPath, $opt_nousage_stats,
        $opt_cleanup, @opt_testcase ) = process_cmd_line_args();
   $workspace = $workspace || $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;
   
   my $keepFiles;
   # Total number of testcases
   my $testcasesNumber = 7;
   # If no testcases are specified, run all of them
   if( !@opt_testcase ){
      @opt_testcase = (1..$testcasesNumber);
      hprint("No testcase was specified, running all testcases!\n");
   }
   # Keep the files only if a single testcase was specified
   elsif( @opt_testcase == 1 ){
      $keepFiles = 1;
   }
   if( defined($opt_cleanup) ){
      if( $opt_cleanup ){
         $keepFiles = 0;
      }else{
         $keepFiles = 1;
      }
   }
   
   my $user = Util::Misc::get_username();
   my $fname_testcasesTarball = firstAvailableFile(
           "/u/$user/$workspace/wwcad/msip/projects/training/".
                   "t125-training-tsmc7ff-1.8v/rel1.00_releaseflow/design/phyv/testcases.tar.gz",
           "/u/$user/$workspace/projects/training/".
                   "t125-training-tsmc7ff-1.8v/rel1.00_releaseflow/design/phyv/testcases.tar.gz",
           "/u/$user/$workspace/wwcad/msip/projects/training/".
                   "t125-training-tsmc7ff-1.8v/rel1.00_releaseflow/design/phyv/dwc_ddrphy_diff_io_ew_testcase.tar.gz",
           "/u/$user/$workspace/wwcad/msip/projects/training/".
                   "t125-training-tsmc7ff-1.8v/rel1.00_releaseflow/design/phyv/dwc_ddrphy_utility_blocks_testcase.tar.gz",
               );
   unless( -e $fname_testcasesTarball ){
      fatal_error("The testcases tarball does not exist!\n");
   }

   # The number of failed testcases
   my $failedTestcases = 0;
   #------------------------------------------------------------------------
   # Setup the verification path, where the testcase files are copied
   # and untarred
   #------------------------------------------------------------------------
   unless( -e $opt_archive ){
      fatal_error("Verification path '$opt_archive' does not exist.\n");
   }   
   my $verifPathAbs  = abs_path($opt_archive) ."/$user";

   #------------------------------------------------------------------------
   # Create the verif directory and untar the files into it
   # the verif
   #------------------------------------------------------------------------
   unless( -e $verifPathAbs ){
      mkdir($verifPathAbs) || confess("Failed to create the directory ".
                                      "'$verifPathAbs'!\n");
   }
   my $cmd = "tar -zxvf $fname_testcasesTarball -C $verifPathAbs";
   my ($stdout,$runstatus) = run_system_cmd($cmd,$VERBOSITY-1);
   if ( $runstatus ) {
       fatal_error("Error when trying '$cmd' !\n\tStdOut='$stdout'\n");
   }

   hprint("Extracted the testcase files into '$verifPathAbs'\n");

   foreach my $index (@opt_testcase){
      prompt_before_continue(MEDIUM);

      my ( $pkgType, $macro, $libName, $metalStack, $metalStackIp, %verifMap);
      $pkgType = "";
      #dwc_ddrphy_diff_io_ew
      #HIPRE PKG
      if( $index == 1 ){
         $macro                = "dwc_ddrphy_diff_io_ew";
         $libName              = "dwc_ddrphy_diff_io";
         $metalStack           = "13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2R";
         $metalStackIp         = "6M_1X_h_1Xa_v_1Ya_h_2Y_vh";
         $pkgType              = "HIPRE";
      }
      #dwc_ddrphy_utility_blocks
      elsif( $index == 2 ){
         $macro                = "dwc_ddrphy_utility_blocks";
         $libName              = "dwc_ddrphy_utility";
         $metalStack           = "13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_MIM";
         $metalStackIp         = "13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_MIM";
      }
      #dwc_ddrphy_repeater_cells
      elsif( $index == 3 ){
         $macro                = "dwc_ddrphy_repeater_cells";
         $libName              = "dwc_ddrphy_repeater";
         $metalStack           = "13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2R";
         $metalStackIp         = "6M_1X_h_1Xa_v_1Ya_h_2Y_vh";
      }
      #dwc_ddrphycover_dwc_ddrphydiff_top_ew
      elsif( $index == 4 ){
         $macro                = "dwc_ddrphycover_dwc_ddrphydiff_top_ew";
         $libName              = "dwc_ddrphycover";
         $metalStack           = "13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_MIM";
         $metalStackIp         = "13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_MIM";
      }
      #dwc_ddrphy_techrevision
      elsif( $index == 5 ){
         $macro                = "dwc_ddrphy_techrevision";
         $libName              = "dwc_ddrphy_techrevision";
         $metalStack           = "13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2R";
         $metalStackIp         = "6M_1X_h_1Xa_v_1Ya_h_2Y_vh";
      }
      #dwc_ddrphy_decapvaa_vdd2_ew
      elsif( $index == 6 ){
         $macro                = "dwc_ddrphy_decapvaa_vdd2_ew";
         $libName              = "dwc_ddrphy_decap";
         $metalStack           = "13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2R";
         $metalStackIp         = "6M_1X_h_1Xa_v_1Ya_h_2Y_vh";
      }
      #dwc_ddrphy_gradient_master_ew
      elsif( $index == 7 ){
         $macro                = "dwc_ddrphy_gradient_master_ew";
         $libName              = "dwc_ddrphy_gradient";
         $metalStack           = "13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2R";
         $metalStackIp         = "6M_1X_h_1Xa_v_1Ya_h_2Y_vh";
      }
      #Testcase was not found 
      else{
         fatal_error("There is no testcase with this number: '$index' !\n");
      }

      hprint("Starting testcase $index: $macro\n");
      #------------------------------------------------------------------------
      # define TARGET the release area where files will be copied to
      #------------------------------------------------------------------------
      my $relPath = "/u/$user/$workspace/products/training/project/"
                   ."t125-training-tsmc7ff-1.8v/ckt/rel/${macro}/1.00a/macro";
      unless( -e $relPath ){
         eprint("Couldn't find the testcase release directory ".
                "'$relPath'! Skipping testcase '${macro}'...\n");
         next;
      }
      my $relPathAbs = abs_path($relPath);
      viprint(LOW,"The release directory for this testcase is '$relPathAbs'\n");
      #------------------------------------------------------------------------
      prompt_before_continue(MEDIUM);
      
      # Create the verifMap with the paths and the modification time
      create_verifMap($macro, $metalStack, $metalStackIp, $relPathAbs, \%verifMap);
            
      #------------------------------------------------------------------------
      # If this is a HIPRE pkg, edit the path in the xml file.
      if( $pkgType eq "HIPRE" ){
         adjust_xml_path($verifPathAbs, $metalStack, $libName, $macro);
      }
      # Call the script
      viprint(LOW,"Calling the script alphaHLDepotPhyvRelease ...\n");

      #-----------------------------------------------------------------
      # Run alphaHLDepotPhyvRelease
      #-----------------------------------------------------------------
      $ENV{'DDR_DA_TESTING'} = "yes" if ( ! exists $ENV{'DDR_DA_TESTING'} );
      my $scriptCmd = adjust_cmd_for_perl_coverage( "$opt_gitlabPath/alphaHLDepotPhyvRelease" );
         $scriptCmd = create_cmdline_args( $scriptCmd );  # just -debug / -verbosity for now
         $scriptCmd .= " -nousage -p4ws $workspace ".
                      "-p $verifPathAbs/verification/training/t125-training-tsmc7ffp12/".
                      "rel1.00/$metalStack/$libName/$macro";
      my( undef, $exitval) = run_system_cmd($scriptCmd,$VERBOSITY);
      prompt_before_continue(HIGH);
      #-----------------------------------------------------------------
      
      my ( @missingFiles, @filesNotCopied, @filesNotOpened );
      check_released_files($macro, $metalStack, $metalStackIp,
                           \%verifMap, \@missingFiles, \@filesNotCopied, 
                           \@filesNotOpened);
      prompt_before_continue(MEDIUM);
                           
      #Capture errors and warnings from the log file
      my ( @failMessage, @errors, @warnings );
      my $logStatus = process_log_file($verifPathAbs, $relPathAbs, \@missingFiles,
                                       \@failMessage, \@errors, \@warnings);
      prompt_before_continue(MEDIUM);
      
      #Check the pincheck shell file
      my ($shellError, $fname_shell) = check_pincheck_shell_file($workspace, 
         $macro, $relPathAbs,$verifPathAbs, $opt_gitlabPath, $metalStackIp, \@missingFiles);
      prompt_before_continue(MEDIUM);
      
      #Print all of the errors
      my $issues = print_errors($shellError, $logStatus, $exitval, \@missingFiles,
                                \@filesNotCopied, \@filesNotOpened, \@failMessage,
                                \@errors, \@warnings);
      if( $issues != 0 ){
         $failedTestcases++;
      }
      prompt_before_continue(MEDIUM);
      
      #Revert if this was not the only testcase to be run
      #and delete the copied files
      unless( defined($keepFiles) ){
         my $fname_pincheckLog = "$relPathAbs/${macro}.pincheck";
         my $fname_lefdiffLog  = "$relPathAbs/${macro}.lefdiff";
         revert_and_delete_files($macro, $metalStack, $metalStackIp, $relPathAbs, $verifPathAbs,
                                 $fname_shell, $fname_pincheckLog, $fname_lefdiffLog,
                                 \%verifMap);
      }
      
      hprint("Finished testcase $index: ${macro}!\n");
   }
   if ( 0 ) {
       utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@ARGV);
   }

   if( (!defined($keepFiles) || !$keepFiles) && -e $verifPathAbs ){
      rmtree($verifPathAbs) || confess("Failed to delete the copied ".
                                       "testcase files at '$verifPathAbs': $!\n");
      viprint(LOW,"Deleted the copied testcase files at '$verifPathAbs'!\n");
   }else{
      veprint(LOW,"Failed to find the copied testcase files at '$verifPathAbs'!\n");
   }

   exit($failedTestcases);  
}  
############    END Main    ####################
 
#-------------------------------------------------------------------------------
# Create the verifMap according to the macro, which includes the path and the
# modification time for each item.
#-------------------------------------------------------------------------------
sub create_verifMap($$$$$){
   print_function_header();
   my $macro               = shift;
   my $metalStack          = shift;
   my $metalStackIp        = shift;
   my $relPathAbs          = shift;
   my $href_verifMap       = shift;
    
   my $filepath;
   # Verification reports
   my( @verifsList, @verifsTypes );
   @verifsList  = qw(icv);
   @verifsTypes = qw(ant drc erc lvs);
   if( $macro eq "dwc_ddrphycover_dwc_ddrphydiff_top_ew" ){
      @verifsList  = qw(icv);
   }elsif( $macro eq "dwc_ddrphy_gradient_master_ew"){
      @verifsList  = qw();
      @verifsTypes = qw();
   }elsif( $macro eq "dwc_ddrphy_utility_blocks"){
       push(@verifsList, "calibre");
   }
   foreach my $verif (@verifsList){
      foreach my $verifType (@verifsTypes){
         $filepath =  "${relPathAbs}/${verif}/${verifType}/${verifType}_${macro}_${metalStack}.rpt";
         if( -e $filepath ){
            $href_verifMap->{"$verif/$verifType"}->{'path'}  = $filepath;
            $href_verifMap->{"$verif/$verifType"}->{'mtime'} = stat($filepath)->mtime;
         }else{
            fatal_error("Failed to find the verification file for $verif/$verifType at $filepath!");
         }
      }
   }
   
   # GDS and layermap
   $filepath = "${relPathAbs}/gds/${metalStackIp}/${macro}.gds.gz";
   if( -e $filepath ){
      $href_verifMap->{'gds'}->{'path'} = $filepath;
      $href_verifMap->{'gds'}->{'mtime'} = stat($filepath)->mtime;
   }else{
      fatal_error("Failed to find the GDS file at $filepath!");
   }
   if( $macro ne "dwc_ddrphy_gradient_master_ew"){
      $filepath = "${relPathAbs}/gds/${metalStackIp}/layerMap_${metalStack}.txt";
      if( -e $filepath ){
         $href_verifMap->{"layermap"}->{'path'} = $filepath;
         $href_verifMap->{"layermap"}->{'mtime'} = stat($filepath)->mtime;
      }else{
         fatal_error("Failed to find the Layermap file at $filepath!");
      }
   }
   
   # Netlist
   if( $macro ne "dwc_ddrphy_gradient_master_ew"){
      $filepath = "${relPathAbs}/netlist/${metalStackIp}/${macro}.cdl";
      if( -e $filepath ){
         $href_verifMap->{"cdl"}->{'path'} = $filepath;
         $href_verifMap->{"cdl"}->{'mtime'} = stat($filepath)->mtime;
      }else{
         fatal_error("Failed to find the CDL file at $filepath!");
      }
  }

   # LEF and Merged LEF
   if( $macro ne "dwc_ddrphy_gradient_master_ew"){
      $filepath = "${relPathAbs}/lef/${metalStackIp}/${macro}.lef";
      if( -e $filepath ){
         $href_verifMap->{"lef"}->{'path'} = $filepath;
         $href_verifMap->{"lef"}->{'mtime'} = stat($filepath)->mtime;
      }else{
         fatal_error("Failed to find the LEF file at $filepath!");
      }
      $filepath = "${relPathAbs}/lef/${metalStackIp}/${macro}_merged.lef";
      if( -e $filepath ){
         $href_verifMap->{"lef/merged"}->{'path'} = $filepath;
         $href_verifMap->{"lef/merged"}->{'mtime'} = stat($filepath)->mtime;
      }else{
         fatal_error("Failed to find the Merged LEF file at $filepath!");
      }
   }

   print_function_footer();
}

#-------------------------------------------------------------------------------
#  This is intended to look for existing pincheck files and overwrite them.
#-------------------------------------------------------------------------------
sub replace_with_empty($){
   print_function_header();
   my $file = shift;

   if( -e $file ){
      my $cmd = "p4 edit $file";
      my $fh;
      run_system_cmd($cmd, $VERBOSITY);
      #-----------------------------
      # overwrite the file, with empty content.
      write_file( EMPTY_STR, $file);
   }

   print_function_footer();
}

#-------------------------------------------------------------------------------
sub adjust_xml_path(){
   print_function_header();
   my $verifPathAbs = shift;
   my $metalStack   = shift;
   my $libName      = shift;
   my $macro        = shift;
   
   my $xmlFile = "$verifPathAbs/verification/training/t125-training-tsmc7ffp12/".
                 "rel1.00/$metalStack/$libName/$macro/HIPRE/MSIP_CD_HIPRE_PREFS.xml";
   if( -e $xmlFile ){
      my @contents = read_file( $xmlFile);
      
      my @updated_contents;
      foreach my $line (@contents){
         $line =~ s|\${VERIF}|$verifPathAbs|;
         push(@updated_contents, $line);
      }
      write_file( \@updated_contents, $xmlFile);
   }else{
      fatal_error("XML file '$xmlFile' does not exist!");
   }

   print_function_footer();
}

#-------------------------------------------------------------------------------
## Check that:
##    1- The files exist
##    2- The files have been copied from the verif
##    3- The files are opened for edit in p4?
sub check_released_files{
   print_function_header();
   my $macro               = shift;
   my $metalStack          = shift;
   my $metalStackIp        = shift;
   my $href_verifMap       = shift;
   my $aref_missingFiles   = shift;
   my $aref_filesNotCopied = shift;
   my $aref_filesNotOpened = shift;
   
   my $filepath;
   if( keys(%{$href_verifMap}) ){
      foreach my $verif (keys %{$href_verifMap}){
         $filepath = $href_verifMap->{$verif}->{'path'};
         if( -e $filepath ){
            my $mtime = stat($filepath)->mtime;
            # Check if the files have been modified since calling the script.
            if( $href_verifMap->{$verif}->{'mtime'} < $mtime ){
               viprint(LOW,"The verification file '$filepath' has been successfully updated!\n");
            }else{
               veprint(LOW,"The verification file '$filepath' has ".
                            "not been updated!\n");
               prompt_before_continue(MEDIUM);
               push(@$aref_filesNotCopied,$filepath);
            }
         }else{
            veprint(LOW,"Cannot find the verification file '$filepath'!\n");
            push(@$aref_missingFiles,$filepath);
         }
      }
   }else{
      eprint("No verification files in the verif map in the testcase setup!\n");
   }
   
   print_function_footer();
}

#-------------------------------------------------------------------------------
#  check that pincheck shell script is the same as GR (golden reference).
#-------------------------------------------------------------------------------
sub check_pincheck_shell_file{
   print_function_header();
   my $workspace         = shift;
   my $macro             = shift;
   my $relPathAbs        = shift;
   my $verifPathAbs      = shift;
   my $gitlabPathAbs     = shift;
   my $metalStackIp      = shift;
   my $aref_missingFiles = shift;
   
   
   viprint(LOW,"Checking the pincheck shell file vs the GR.\n");

   my $fname_shell = firstAvailableFile(
                        "${relPathAbs}/pincheck/$metalStackIp/alphaPinCheck.${macro}",
                        "${relPathAbs}/alphaPinCheck.${macro}");
   my $fname_GR    = "${relPathAbs}/alphaPinCheck.${macro}_GR";
   
   if( !-e $fname_shell ){
      my $shellError = "pincheck shell file '$fname_shell' does not exist!\n";
      veprint(LOW,$shellError);
      push(@$aref_missingFiles,$fname_shell);
      return($shellError,$fname_shell);
   }elsif( -z $fname_shell ){
      my $shellError = "pincheck shell file '$fname_shell' is empty!\n";
      veprint(LOW,$shellError);
      push(@$aref_missingFiles,$fname_shell);
      return($shellError,$fname_shell);
   }
   if( !-e $fname_GR ){
      fatal_error("pincheck shell GR file '$fname_GR' does not exist!\n");
   }
   
   my @shellLines = read_file($fname_shell);
   my @GRLines    = read_file($fname_GR); 
   
   my $shellError;
   #Get the date from the generated pincheck file to place it into 
   #the GR file
   my $date;
   foreach my $line (@shellLines){
      if( ($date) = ($line =~ /(-since '[^']+')/) ){
         last;
      }
   }
   if( !defined($date) ){
      $shellError = "Failed to find the date in the pincheck shell file!\n".
                    "Cannot comapre the file with the GR.\n";
      veprint(LOW,$shellError);
   }else{
      my $relPathUser = $relPathAbs =~ s|\S+/$workspace|/u/\$USER\/$workspace|r;
      foreach my $line (@GRLines){
         dprint(LOW, "GR orig => $line ");
         $line =~ s|\S*/alphaPinCheck.pl|$gitlabPathAbs/alphaPinCheck.pl|g;
         $line =~ s|\S*/macro|$relPathUser|g;
         $line =~ s|[^ '\"]*/verification|$verifPathAbs/verification|g;
         $line =~ s|-since '[^']+'|$date|g;
         dprint(LOW, "GR new  => $line ");
      }

      chomp($shellLines[-1]);
      chomp($GRLines[-1]);
      if( @shellLines ~~ @GRLines){
         viprint(LOW,"The files are matched.\n");
      }else{
         $shellError = "The pincheck shell file does not match the GR file!\n";
         veprint(LOW,$shellError);
         if( $#shellLines ne $#GRLines ){
            veprint(LOW,"The number of lines of the generated pincheck file and the GR file do not match!\n");
         }else{
            foreach my $ind (0..$#shellLines){
               if($shellLines[$ind] ne $GRLines[$ind]){
                  veprint(MEDIUM,"SHELL Line: '$shellLines[$ind]'\n");
                  veprint(MEDIUM,"GR    Line: '$GRLines[$ind]'\n");
               }
            }
         }
         if($VERBOSITY >= HIGH){
            write_file(\@shellLines,"${fname_shell}.copy");
            write_file(\@GRLines,"${fname_GR}.copy");
         }      
      }

   }
   
   print_function_footer();
   return($shellError, $fname_shell);
}

#-------------------------------------------------------------------------------
sub print_errors{
   print_function_header();
   my $shellError          = shift;
   my $logStatus           = shift;
   my $exitval             = shift;
   my $aref_missingFiles   = shift;
   my $aref_filesNotCopied = shift;
   my $aref_filesNotOpened = shift;
   my $aref_failMessage    = shift;
   my $aref_errors         = shift;
   my $aref_warnings       = shift;
   
   my $issues = 0;
   vhprint(LOW,"Summary of issues:\n");
   if( $exitval == 0 ){
      viprint(LOW, "The exit value was 0");
   }else{
      eprint("The exit value was $exitval!");
      $issues++;
   }
   if( $logStatus eq "PASS" ){
      viprint(LOW, "The log file matches the GR log!");
   }else{
      eprint("The log file does not match the GR log: $logStatus");
      $issues++;
   }
   if( @$aref_errors ){
      eprint("The following error(s) were detected in the log file:\n".
             join("\n",@$aref_errors) ."\n");
      $issues++;
   }else{
      viprint(LOW,"No errors in the log file!\n");
   }
   if( @$aref_warnings ){
      wprint("The following warning(s) were detected in the log file:\n".
             join("\n",@$aref_warnings) ."\n");
      $issues++;
   }else{
      viprint(LOW,"No warnings in the log file!\n");
   }
   if( defined(@$aref_failMessage) ){
      eprint("The script failed with the following message:\n".
             "\t". join("\t",@$aref_failMessage) ."\n");
   }else{
      if( @$aref_missingFiles ){
         eprint("The following file(s) were not found:\n".
                join("\n\t",@$aref_missingFiles) ."\n");
         $issues++;
      }else{
         viprint(LOW,"No missing files!\n");
      }
      if( @$aref_filesNotCopied ){
         eprint("The following file(s) were not copied correctly:\n".
                join("\n\t",@$aref_filesNotCopied) ."\n");
         $issues++;
      }else{
         viprint(LOW,"All of the files were copied correctly!\n");
      }
      if( @$aref_filesNotOpened ){
         eprint("The following file(s) were not checked-out:\n".
                join("\n\t",@$aref_filesNotOpened) ."\n");
         $issues++;
      }else{
         viprint(LOW,"All of the files were checked-out correctly!\n");
      }
      if( defined($shellError) ){
         eprint($shellError);
         $issues++;
      }else{
         viprint(LOW,"The pincheck shell file matches the GR file!\n");
      }
      if( $issues == 0 ){
         hprint("The testcase ran without issues!\n");
      }
   }
   print_function_footer();
   return $issues;
}

#-------------------------------------------------------------------------------
sub process_log_file{
   print_function_header();
   my $verifPathAbs      = shift;
   my $relPathAbs        = shift;
   my $aref_missingFiles = shift;
   my $aref_failMessage  = shift;
   my $aref_errors       = shift;
   my $aref_warnings     = shift;

   
   my $GRLogFile = "$relPathAbs/alphaHLDepotPhyvRelease.log_GR";
   my $scriptLogFile = "alphaHLDepotPhyvRelease.log";
   my $status = EMPTY_STR;
   if( -e $GRLogFile && -e $scriptLogFile ){
      my @GRLines = read_file( $GRLogFile );
      my @lines   = read_file( $scriptLogFile );
      # Remove the empty lines and the lines starting with #
      @GRLines = grep {! /^#|^\s*$/} @GRLines;
      @lines   = grep {! /^#|^\s*$/} @lines;
      # Replace the paths in GR with the callers paths
      foreach my $line (@GRLines){
         # verification path
         $line =~ s|[^\s'\"]*/verification|$verifPathAbs/verification|g;
         $line =~ s|[^\s'\"]*/macro|$relPathAbs|g;
      }
      if( @GRLines ~~ @lines ){
         viprint(LOW, "The log file matches the GR log!");
         $status = "PASS";
      }else{
         veprint(LOW, "The log file does not match the GR log!");
         $status = "Mismatched files";
         if( $#GRLines != $#lines ){
             eprint("The log file and the GR have mismatched number of lines: $#lines vs. $#GRLines!");
         }else{
            for( my $index = 0; $index <= $#GRLines; $index++){
               if( $GRLines[$index] ne $lines[$index] ){
                  eprint("GR:  ^$GRLines[$index]\$");
                  eprint("log: ^$lines[$index]\$");
               }
            }
         }
      }
   }elsif( -e $scriptLogFile ){
      my @lines = read_file( $scriptLogFile );
      my $lineStatus = 0;
      ## Loop through the log file and copy the warnings and errors
      foreach my $line (@lines){
         if( $line =~ /^-I-/){
            $lineStatus = 0;
         }elsif( $line =~ /^-W-/ ){
            $lineStatus = 1;
            push(@$aref_warnings,$line);
         }elsif( $line =~ /^-E-/ ){
            $lineStatus = 2;
            push(@$aref_errors,$line);
         }elsif( $line =~ /^-F-/ ){
            $lineStatus = 3;
            push(@$aref_failMessage,$line);
         }else{
            if( $lineStatus == 1 ){
               push(@$aref_warnings,$line);
            }elsif( $lineStatus == 2 ){
               push(@$aref_errors,$line);
            }elsif( $lineStatus == 3 ){
               push(@$aref_failMessage,$line);
            }
         }
      }
      $status = "Missing GR log";
   }else{
      veprint(LOW,"Log file does not exist!\n");
      push(@$aref_missingFiles,$scriptLogFile);
      $status = "Missing log file";
   }
   
   print_function_footer();
   return $status;
}

#-------------------------------------------------------------------------------
sub revert_and_delete_files{
   print_function_header();
   my $macro             = shift;
   my $metalStack        = shift;
   my $metalStackIp      = shift;
   my $relPathAbs        = shift;
   my $verifPathAbs      = shift;
   my $fname_shell       = shift;
   my $fname_pincheckLog = shift;
   my $fname_lefdiffLog  = shift;
   my $href_verifMap     = shift;
   
   # Revert the release files
   foreach my $verif ( keys(%{$href_verifMap}) ){
      my $fname_rel = $href_verifMap->{$verif}->{'path'};
      revert_if_opened($fname_rel);
      
      #Delete the copied lef file used in the lefdiff
      if( $verif eq 'lef' ){
         my $fname_bak = "${fname_rel}.bak";
         if( -e $fname_bak ) {
            unlink($fname_bak) || confess("Failed to delete the file '$fname_bak': $!\n");
            viprint(LOW,"Deleted the copied lef file '$fname_bak'!\n");
         }
      }
   }

   #Delete the pincheck and lefdiff log files
   revert_if_opened($fname_pincheckLog);
   revert_if_opened($fname_lefdiffLog);
   delete_if_not_tracked($fname_pincheckLog);
   delete_if_not_tracked($fname_lefdiffLog);

   #Delete the pincheck shell file
   if( -e $fname_shell ){
      revert_if_opened($fname_shell);
      delete_if_not_tracked($fname_shell);
   }else{
      veprint(LOW,"Couldn't find the pincheck shell file '$fname_shell'!\n");
   }
   
   #Delete the release script log files
   my $scriptLogFile = "alphaHLDepotPhyvRelease.log";
   if( -e $scriptLogFile ){
      unlink($scriptLogFile) || confess("Failed to delete the file '$scriptLogFile': $!\n");
      viprint(LOW,"Deleted the log file '$scriptLogFile'!\n");
   }else{
      veprint(LOW,"Couldn't find the log file '$scriptLogFile'!\n");
   }
   
   my $scriptP4LogFile = "alphaHLDepotPhyvRelease.p4";
   if( -e $scriptP4LogFile ){
      unlink($scriptP4LogFile) || confess("Failed to delete the file '$scriptP4LogFile': $!\n");
      viprint(LOW,"Deleted the log file '$scriptP4LogFile'!\n");
   }else{
      veprint(LOW,"Couldn't find the log file '$scriptP4LogFile'!\n");
   }
   
   print_function_footer();
}

#-------------------------------------------------------------------------------
sub revert_if_opened{
   print_function_header();
   my $file = shift;
   
   my $cmd = "p4 opened $file";
   my ( $stdout, $retval ) = run_system_cmd($cmd, $VERBOSITY-1);
   if( $stdout =~ /file\(s\) not opened/){
      viprint(LOW,"The file '$file' is not checked-out!\n");
   }else{
      $cmd = "p4 revert $file";
      run_system_cmd($cmd, $VERBOSITY);
      viprint(LOW,"Reverted the file '$file'!\n");
   }
   
   print_function_footer();
}

#-------------------------------------------------------------------------------
sub delete_if_not_tracked(){
   print_function_header();
   my $file = shift;
   
   my $cmd = "p4 files $file";
   my ( $stdout, $retval ) = run_system_cmd($cmd, $VERBOSITY-1);
   if( $stdout =~ /no such file\(s\)/ && -e $file ){
      unlink($file) || confess("Failed to delete the file '$file': $!\n");
      viprint(LOW,"Deleted the file '$file'!\n");
   }

   print_function_footer();
}

#------------------------------------------------------------------------------
sub process_cmd_line_args($){
    my (@opt_testcase, $opt_workspace, $opt_archive, $opt_debug, $opt_verbosity, $opt_gitlabPath, $optHelp, $opt_nousage_stats, $opt_cleanup );
    GetOptions(
        "p4ws=s"        => \$opt_workspace,
        "archive=s"     => \$opt_archive,     
        "testcase=i"    => \@opt_testcase,     
        "debug=i"       => \$opt_debug,
        "verbosity=i"   => \$opt_verbosity,
        "gitlabPath=s"  => \$opt_gitlabPath,
        "nousage"       => \$opt_nousage_stats,  # when enabled, skip logging usage data
        "cleanup!"      => \$opt_cleanup,
        "help"          => \$optHelp,            # Prints help
     );
  
   $main::DEBUG     = $opt_debug      if( defined $opt_debug );
   $main::VERBOSITY = $opt_verbosity  if( defined $opt_verbosity );
   
   if( defined $optHelp ){
      pod2usage( -verbose => 2, -exit_val => 0);
   }
   unless( defined $opt_archive ){
       $opt_archive = "$RealBin/../data";
       unless( -d $opt_archive ){
           fatal_error( "User didn't specify '-archive <path>' ... default path is not"
                  ." a directory!:\n\t'$opt_archive'" );
       }
   }
   
   if( defined($opt_gitlabPath) ){
      unless( -d $opt_gitlabPath ){
         fatal_error("The gitlab path provided '$opt_gitlabPath' does not exist!\n");
      }
   }else{
      $opt_gitlabPath = firstAvailableFile( "$RealBin/../../bin",
                                            "$ENV{GITROOT}/ddr-ckt-rel/dev/main/bin",
                                            "/u/$ENV{USER}/Gitlab/ddr-hbm-phy-automation-team/ddr-ckt-rel/dev/main/bin",
                                            "/u/$ENV{USER}/GitLab/ddr-hbm-phy-automation-team/ddr-ckt-rel/dev/main/bin",
                                            "/u/$ENV{USER}/gitlab/ddr-hbm-phy-automation-team/ddr-ckt-rel/dev/main/bin"
                                          );
      unless( -d $opt_gitlabPath ){
         fatal_error("The default gitlab path '~/GitLab' does not exist!\n".
                "Please provide the path to your gitlab repository using the ".
                "-g <gitlab_repository_path> option.\n");
      }
   }

   unless( -d $opt_gitlabPath ){
      fatal_error("Failed to find the release scripts directory in the GitLab repository ".
             "'$opt_gitlabPath'!\n");
   }
   $opt_gitlabPath = abs_path($opt_gitlabPath);

   return( $opt_workspace, $opt_archive, $opt_gitlabPath, 
           $opt_nousage_stats, $opt_cleanup, @opt_testcase );
}
            
#----------------------------------------------
sub create_cmdline_args($){
    my $tool      = shift;
    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;
   
    #  my $scriptCmd = "$tool -nousage -v $VERBOSITY -debug $DEBUG -p4ws $workspace ".
    #                  "-p $verifPathAbs/verification/training/t125-training-tsmc7ffp12/".
    #                  "rel1.00/$metalStack/$libName/$macro";

    my $cmd = "$tool";
    $cmd .= " -debug $debug "         if ( $debug );
    $cmd .= " -verbosity $verbosity " if ( $verbosity );

    return $cmd;
}



Main();

__END__

=head1 NAME

alphaHLDepotPhyvRelease_Test.pl

=head1 VERSION

2022ww15


=head1 SYNOPSIS

This script runs the testcases for the alphaHLDepotPhyvRelease script and checks
if it ran without issues.

=head1 DESCRIPTION

This script prepares the testcases files for the alphaHLDepotPhyvRelease script
by unpacking the testcase into the local path specified. Then it calls the 
release script with the necessary arguments and checks output. After the
test is done the scripts deletes all of the files that were created in the
process. 

The testcase files can be found in '.tar.gz' format at
   //wwcad/...

While the release path is set to
   //depot/...

The release directory includes a captured cmd GR file that contains calls to
scripts and functions that are not executed because they require actual 
verification files instead of the dummy verification files present in the 
testcases.

The checks done include:

=over 8

=item B<Verification files>   Ensuring that the verification files have been 
                              copied correctly

=item B<Captured cmd file>     Comparing the captured cmd file versus the GR

=item B<pincheck shell file>  Comparing the pincheck shell file versus the GR

=item B<Log file>             Reading the release script log file to check for
                              errors and warnings

=back

=head1 USAGE

./alphaHLDepotPhyvRelease_Test.pl [Options] localPath

=head1 OPTIONS

=over 4

=item B<-help>             Prints this screen.

=item B<-testcase>         Specify a single or multiple testcase to run. If a 
                           single testcase was specified then the files
                           created/checked-out during runtime will be kept as
                           is. If no testcase was specified, all of the 
                           testcases will be run and the files 
                           created/checked-out during runtime will be
                           removed/reverted.

=item B<-verbosity> B<#>      Print additional messages... Includes details of 
                           system calls, etc..
                           Must provid integer argument where higher values 
                           increase verbosity.

=item B<-info>      B<#>      Print software debug diagnostic messages.
                           Must provid integer argument where higher values 
                        

=back

=head1 RELEASE SCRIPT ARGUMENTS

The arguments passed to the release script are:

=over 4

=item B<-t>    To set it to testing mode.

=item B<-v #>  The verbosity level passed to the testing script is also passed
               to the release script.

=item B<-i #>  The info level passed tot he testing script is also passed to
               release script.

=back

=cut

