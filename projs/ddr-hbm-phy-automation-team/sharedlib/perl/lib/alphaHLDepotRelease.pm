############################################################
#  Utility functions for the DDR/HBM Release Flow
#  Author : Others + Patrick Juliano
############################################################
#
# Modification History:
# 001 James Laderoute   9/20/2022
#     Adding REs to processLegalReleaseFile
#       releasePmMailDist "value"
#       releaseMailDist   "value"
#       releaseTCMailDist "value"
#       layout_tag        "value"
#       utility_name      "value"
#       releaseIgnoreMacro {value1 value2} 
#       ferel             "value"
#       releaseBranch     "value"
#       releaseTCMacro
#       releaseShimMacro    {}
#       releaseUtilityMacro {}
# 002 James Laderoute   9/21/2022
#   Adding REs to processLegalReleaseFile
#       defIgnore
#       releaseRepeaterMacro
#       releaseTCMacro
#       utility_tag_layers
#   more to look into
#       repeater_name
#       UtilityName
#   Questionable tokens found in various release files
#       timingLibs
#       releaseUtilityName    ## name of UTILITY library macro for CKT release
#                             to customer, defaults to dwc_ddrphy_utility_cells
# 003 James Laderoute 11/18/2022
#     Modified readLegalRelease so it only takes 1 argument, the filename.
#     All the information is now returned to the caller.
#
package alphaHLDepotRelease;

use strict;
use warnings;
use List::MoreUtils qw(indexes);
use Cwd;
use Carp;
use Cwd 'abs_path';
use Capture::Tiny qw/capture/;
use YAML::XS qw(LoadFile);
use Data::Dumper;
use Storable qw(dclone);
$Data::Dumper::Sortkeys = sub { [sort keys %{$_[0]}] };

use FindBin qw($RealBin $RealScript);
use lib "$RealBin/.";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::P4;

use Exporter;

# nolint [Modules::ProhibitAutomaticExportation]
our @ISA   = qw(Exporter);
our @EXPORT_OK = qw(hashCheck);
our @EXPORT    = qw( 
  firstAvailableFile arrangeStacks stackMatch
  countDirtysAndWarnings getCadHome 
  processLegalReleaseFile
  readLegalRelease readNtFile readTopCells readStreamLayerMap
  parseLegalVerifFile
  process_corners_file
  readCornersFromLegalVcCorners
  checkPinCheckExist
  getCktSpecsFile
  verify_perforce_setup
  get_project_files_path 
  adjust_cmd_for_perl_coverage
  check_if_macros_are_legal
  coverStackCheck
  verifyRelVersion
);

#--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%
#  Used for the CKT team release flow scripts
#--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%

#-------------------------------------------------------------------------------
#  Parse the input to get the path to the project files
#   my ( $projPathAbs, $fname_projMacroFile, 
#        $fname_projNtFile, $fname_projRelFile, $p4client ) = get_project_files_path
#  Typically, DDR_DA_MAIN only ever used for functional testing purposes, and 
#      is the path to the data directory where input files are stored for tests.
#      Ex:  setenv DDR_DA_MAIN /u/$USER/git/ddr-ckt-rel/dev/main/
#-------------------------------------------------------------------------------
sub get_project_files_path($$$$){
   print_function_header();
   my $projPathAbs = shift;
   my $projType    = shift;
   my $proj        = shift;
   my $projRel     = shift;

   my $prePath;
   
   if ( exists $ENV{'DDR_DA_MAIN'} ){
       $prePath = $ENV{'DDR_DA_MAIN'};
   }else{
       $prePath = "/tmp";
   }

   #--------------------------------------------------------------------
   # Assumption here is the following:  
   #    critical input files for functional testing the ddr-ckt-rel flow 
   #    are stored in tests/data directory, w/the subdir being the name of
   #    the script being tested. The filename gets prefix'd by the 
   #    project SPEC ($projSPEC = $projType.$proj/$projRel)
   my $func_test_path = "$prePath/tests/data/$RealScript";
   $func_test_path .= "/$projType.$proj.$projRel";
   #--------------------------------------------------------------------
   my $fname_TopCells= firstAvailableFile(
                          "$func_test_path.topcells.txt",
                          "$projPathAbs/design/topcells.txt",
                          "$projPathAbs/design_unrestricted/topcells.txt",
                          "$projPathAbs/pcs/design/topcells.txt");
   my $fname_NT      = firstAvailableFile(
                          "$func_test_path.alphaNT.config",
                          "$projPathAbs/design/timing/nt/ntFiles/alphaNT.config",
                          "$projPathAbs/design_unrestricted/timing/nt/ntFiles/alphaNT.config");
   my $fname_Release = firstAvailableFile(
                          "$func_test_path.legalRelease.txt",
                          "$projPathAbs/design/legalRelease.txt",
                          "$projPathAbs/design_unrestricted/legalRelease.txt",
                          "$projPathAbs/pcs/design/legalRelease.txt");
   my $fname_Verif   = firstAvailableFile(
                          "$func_test_path.legalVerifs.txt",
                          "$projPathAbs/design/legalVerifs.txt",
                          "$projPathAbs/design_unrestricted/legalVerifs.txt",
                          "$projPathAbs/pcs/design/legalVerifs.txt");
   dprint(CRAZY, "'TopCells'     = '$fname_TopCells'\n" );
   dprint(CRAZY, "'NT'           = '$fname_NT'\n" );
   dprint(CRAZY, "'legalRelease' = '$fname_Release'\n" );
   dprint(CRAZY, "'legalVerif'   = '$fname_Verif'\n" );
   prompt_before_continue(CRAZY);
      # topcells is not a TCL file, skip
      # alphaNTconfig has variables that we must skip
      # legalRelease
      # legalVerifs is NOT TCL
   if( 0 ){
      my $aref= [ $fname_Release  ];
      foreach my $fname ( @$aref ){
         #--------------------------------------------------------------------
         #  'check_config_file' Returns:
         #       0 = success, no failures
         #       1 = failed, invalid config 
         #      -1 = the filename does not exist
         #      -2 = this subroutine does not support the supplied format
         #-------------------------------------------------------------------------------------
         if( check_config_file($fname, 'TCL') ){
             fatal_error( "Found invalid format in the input file: '$fname'.\n" )
                if( check_config_file($fname) );
         }
      }
   }

   print_function_footer();
   return ( $fname_TopCells, $fname_NT, $fname_Release, $fname_Verif );
}

#-------------------------------------------------------------------------------
#  0. input:  hash from TopCells, $opt_macros
   #  1. throw eprint if cmdline macro found that's not in TopCells
#  2. throw fatal_error if cmdline macro defined but empty
#  3. throw fatal_error if found any macros at cmdline not found in TopCells
#  4. throw fatal_error if found any macros at cmdline not found in TopCells
#  5. output/result :  @macros = all macros from TopCells || @macros = all macros from cmdline
#-------------------------------------------------------------------------------
sub check_if_macros_are_legal($$){
    print_function_header();
    my $href_TopCells = shift;
    my $opt_macros    = shift;

    my $errorFound = FALSE;

    my @legal_macros_list;
    
    ## if command line macros are specified, use that list
    if( defined $opt_macros ){
        my @cmdline_macros = split(/\,|\s+/,$opt_macros);
        wprint( "Macro names specified at cmd line '$opt_macros' are invalid...skipping!\n" ) unless( @cmdline_macros );
        ## validate command line macros
        foreach my $macro ( @cmdline_macros ){
            if( !defined $href_TopCells->{$macro} ){
                eprint("Macro from cmd line '$macro' is _NOT_ legal because it's not in project macro file (i.e. TopCells).\n");
                $errorFound = TRUE;
            }else{
                viprint(LOW, "Macro name from cmd line is legal...found in Topcells : '$macro'\n" );
                push( @legal_macros_list, $macro );
            }
        }
        if( $errorFound ){
            eprint("One or more macros specified at cmd line were not found in TopCells. Fix and re-run...\n" );
            #fatal_error("One or more macros specified at cmd line were not found in TopCells. Fix and re-run...\n", 1 );
        }
    }else{
        wprint( "Macro names not specified at cmd line. Using all macros from Top Cells.\n" );
        ## if no cmdline macro(s) specified, use all legal macros from top cells
        @legal_macros_list = (keys %$href_TopCells);
    }

    dprint(HIGH, "Using macros list: ". pretty_print_aref(\@legal_macros_list)."\n" );
    unless( @legal_macros_list ){
        if( exists $ENV{DA_RUNNING_UNIT_TESTS}){
            eprint( "Final list of macro names to run script on is empty ... something went wrong.\n" );
        }else{
            fatal_error( "Final list of macro names to run script on is empty ... something went wrong.\n" );
        }
    }

    return( @legal_macros_list);
}

#------------------------------------------------------------------------------
sub coverStackCheck($$){
    print_function_header();
   my @coverStacks    = @{$_[0]}; 
   my $aref_allStacks = $_[1];

   foreach my $coverStack ( @coverStacks ){
      if( grep{/$coverStack/} @$aref_allStacks ){
         s/$coverStack/${coverStack}_both/g for(@$aref_allStacks);
      }else{
         push(@$aref_allStacks, "${coverStack}_cover");
      }
   }
}





#-------------------------------------------------------------------------------
#  During unit and/or functional testing, want to pre-pend calls to perl
#      so that they get the coverage stats created.
#-------------------------------------------------------------------------------
sub adjust_cmd_for_perl_coverage($){
    my $tool = shift;
    my $db = "";

    if( exists $ENV{'DDR_DA_COVERAGE'} ){
        if ( exists $ENV{'DDR_DA_COVERAGE_DB'} ){
            # This tells where to create the cover_db file
            $db = "=-db,$ENV{'DDR_DA_COVERAGE_DB'}"
        }
        else{
            $db = "=-db,test_cover_db";
        }

        $tool =  "/depot/perl-5.14.2/bin/perl -MDevel::Cover${db} $tool";
    }
    return( $tool );
}

#------------------------------------------------------------------------
#  Find the first file that exists on disk from the list provided as
#  input. This subroutine should return NULL_VAL if no files are found.
#------------------------------------------------------------------------
sub firstAvailableFile {
   my @inFiles = @_;

   foreach my $inf ( @inFiles ){
      if ( exists $ENV{'DDR_DA_SKIP_YAML_FIRSTAVAILABLEFILE'} ){
          if ((defined $inf) && ( $inf =~ m/\.yml$/ ) ){
              $inf = "/no/such/dir/ever/foobar.nofile";
          }
      }

      if( defined($inf) && (-e $inf) ){
         dprint(LOW, "Found file to process ...\n\t'$inf'\n" );
         return $inf;
      }else{
         dprint(MEDIUM, "Checked file but doesn't exist: \n\t'$inf'\n" );
      }
   }
   wprint( "None of these files exist: \n\t". join("\n\t",@inFiles) ."\n" );
   return( NULL_VAL );
}


#-------------------------------------------------------------------------------
#  Arrange stacks appropriately
#-------------------------------------------------------------------------------
sub arrangeStacks {
    print_function_header();
    my $ERROR = "ERROR!";

    my $firstStack  = shift;
    my $secondStack = shift;

    # metal stack names can be like:
    #    8M_2X_hv_1Ya_h_4Y_vhvh
    #    1P10M2T0F2A0C
    # P10020416-39282 need to support UMC metal names
    my ($umc_dummy1,$fnum) = ($firstStack  =~ /^(1P)?([0-9]+)M(_)?.*/);
    my ($umc_dummy2,$snum) = ($secondStack =~ /^(1P)?([0-9]+)M(_)?.*/);

    # Error checking 
    if (!$fnum || !$snum ) {return $ERROR;}
    if( $fnum < $snum)    { return ($firstStack,$secondStack); }
    elsif(  $fnum > $snum ){ return ($secondStack,$firstStack); }
    else { return $ERROR; }
}

#-------------------------------------------------------------------------------
#  Automatically try to match metal_stack and metal_stack_ip
#-------------------------------------------------------------------------------
sub stackMatch($$$){
   print_function_header();
   my @mStack         = @{$_[0]};
   my @mStackIp       = @{$_[1]};
   my $href_stackHash =   $_[2] ;  # [output] gets built in this function

   my $stackC = 0; my $matched = 0;
   foreach my $mstck (@mStack ){
      my $ms = $mstck;
      foreach my $ipstck (@mStackIp ){
         my $msip = $ipstck;
         $ms   =~ s/[0-9]+//g;
         $msip =~ s/[0-9]+//g;
         if( $ms =~ m/($msip)/ ){
             $href_stackHash->{$mstck} = $ipstck;
             iprint( "Stack pattern match found for $mstck - $ipstck\n" ); 
             $matched++;
         }else{ next; }
      }
   }
   if( !$matched ){
      dprint(LOW, "metal_stack:" . join(" ,", @mStack) . "\n");
      dprint(LOW, "metal_stack_ip:" . join(" ,", @mStackIp) . "\n");
      fatal_error( "None of metal stack patterns in 'metal_stack' variable match ".
              "with 'metal_stack_ip' variable\n", 1 );
   }
   return();
}

#+
# Function: _arefDeepCopy
#
# Arguments:
#   what:  Some name for dprint statements
#   target: reference to the target array 
#   source: reference to the source array 
#
# Returns:
#   None
#
# Example:
#
#     my @array1;
#     my @array2;
#     # copies @array1 into @array2 
#     my $aref_out = _arefDeepCopy("array2", \%array1, \%array2);
#-
sub _arefDeepCopy($$$){
    my $what        = shift;
    my $aref_target = shift;
    my $aref_source = shift;

    return [] if ( ! $aref_source );

    dprint(LOW, "BEFORE: _arefDeepCopy '$what' target='" .
        Dumper($aref_target) ."'\n");

    $aref_target = dclone($aref_source);

    dprint(LOW, "AFTER: _arefDeepCopy '$what' target='" .
        Dumper($aref_target) . "'\n");

    return $aref_target;
}

sub _arefDeepCopyAlt($$){
    my $aref_target = shift;
    my $aref_source = shift;
    
    if ( $aref_target && $aref_source ) {
        foreach my $item ( @$aref_source ) {
            push( @$aref_target, $item);
        }
    }
}




#+
# Function: _hrefDeepCopy
#
# Arguments:
#   what:   some name for dprints
#   target: reference to the target hash
#   source: reference to the source hash
#
# Returns:
#   reference to a hash 
#
# Example:
#
#     my %hash1;
#     my %hash2;
#     # copies hash2 to hash1
#     my $href_out = _hrefDeepCopy("hash2", \%hash1, \%hash2);  #-
#-
sub _hrefDeepCopy($$$){
    my $what        = shift;
    my $href_target = shift;
    my $href_source = shift;

    return {} if ( ! $href_source );

    dprint(LOW, "BEFORE:\$my $what=". Dumper($href_target) ."\n");
    
    $href_target = dclone($href_source);

    dprint(LOW, "AFTER:\$my $what=". Dumper($href_target) ."\n");

    return $href_target;
}

#-------------------------------------------------------------------------------
#  Read the legalRelease file into a hash ... used in Seed, LibRelease
#-------------------------------------------------------------------------------
# NOTES:
#    alphaHLDepotSeed uses the $autoMatch returned value to call
#    stackMatch( \@metalStacks, \@metalStacksIp, \%stackHash); 
#    but processLegalReleaseFile() does this internally and returns
#    this via hash 'stackHash' 
#
#
sub readLegalRelease($){
    print_function_header();
    my $fname_projRelFile = shift;

    my $href_layersOverrides     ;  
    my $href_supplyPinsOverrides ; 
    my $href_areaOverrides       ;
    my $href_bndLayer            ;
    my $aref_timingLibs          ;
    my $aref_repeaterMacro       ;
    my $aref_utilityMacro        ;
    my $aref_allowed_timing_cases; 
    my $href_stackHash           ;
    my $href_releaseMacro        ;
    my $href_referenceGdses      ;
    my $href_shimMacros          ; 
    my $href_phyvMacros          ;
    my $aref_CtlMacs             ;
    my $href_repeaterSubMacros   ;
    my %returned;
    processLegalReleaseFile( $fname_projRelFile, \%returned); 

    # OSE = old side effect (of original readLegalRelease function )
    # PLRF = processLegalReleaseFile
    my $rel                      = $returned{'rel'};
    my $p4ReleaseRoot            = $returned{'p4ReleaseRoot'}; # /u/$USER/p4_ws/
    my $referenceDateTimeLibs    = $returned{'referenceDateTime'};
    my $process                  = $returned{'process'};
    my $metalStack               = $returned{'metalStack'};
    my $metalStackIp             = $returned{'metalStackIp'};
    my $metalStackCover          = $returned{'metalStackCover'};
    my $layers                   = $returned{'layers'};
    my $supplyPins               = $returned{'supplyPins'};
    my $releaseShimMacro         = $returned{'releaseShimMacro'};
    my $releasePhyvMacro         = $returned{'releasePhyvMacro'};
    my $releaseUtilityMacro      = $returned{'releaseUtilityMacro'};
    my $releaseRepeaterMacro     = $returned{'releaseRepeaterMacro'};
    my $projDiskArchiveLibFiles  = $returned{'projDiskArchiveLibFiles'};
    my $coverStackExists         = exists $returned{'metalStackCover'};
    my $calibre_verifs           = $returned{'calibre_verifs'};
    my $verif_remove             = $returned{'verif_remove'};
    my $verif_addi               = $returned{'verif_addi'};
    my $aref_customerMacro       = $returned{'customerMacro'};

    if ( exists $returned{'ctlMacs'} &&
         defined $returned{'ctlMacs'} ){
        foreach my $elem ( @{$returned{'ctlMacs'}} ){
            push( @$aref_CtlMacs, $elem);
        }
    }
    my $releaseDefMacro          = $returned{'releaseDefMacro'};
    my $autoMatch                = $returned{'autoMatch'}; # added to PLRF

    #
    # We only need to copy to the passed-in (input) variables
    #
    $aref_timingLibs   = _arefDeepCopy( 'timingLibs', $aref_timingLibs, 
        $returned{'timingLibs'} );
    $aref_repeaterMacro= _arefDeepCopy( 'repeaterMacro',$aref_repeaterMacro, 
        $returned{'repeaterMacro'} );
    if ( exists $returned{'utilityMacro'} ) {
        $aref_utilityMacro = _arefDeepCopy( 'utilityMacro', $aref_utilityMacro,  
            $returned{'utilityMacro'});
    }else{
        $aref_utilityMacro = [];
    }
    $aref_CtlMacs      = _arefDeepCopy( 'ctlMacs', $aref_CtlMacs, 
        $returned{'ctlMacs'});
    $aref_allowed_timing_cases= _arefDeepCopy( 'allowedTimingCases', 
        $aref_allowed_timing_cases, $returned{'allowedTimingCases'});

    $href_repeaterSubMacros   = _hrefDeepCopy( 'repeaterSubMacros', 
        $href_repeaterSubMacros, $returned{'repeaterSubMacros'}); 
    $href_supplyPinsOverrides = _hrefDeepCopy( 'supplyPinsOverrides', 
        $href_supplyPinsOverrides, $returned{'supplyPinsOverrides'}); 
    $href_areaOverrides       = _hrefDeepCopy( 'areaOverrides',
        $href_areaOverrides, $returned{'areaOverrides'});
    $href_bndLayer            = _hrefDeepCopy( 'bndLayer',
        $href_bndLayer, $returned{'bndLayer'});
    $href_layersOverrides     = _hrefDeepCopy( 'layersOverrides', 
        $href_layersOverrides, $returned{'layersOverrides'} );
    $href_releaseMacro        = _hrefDeepCopy( 'releaseMacro', 
        $href_releaseMacro, $returned{'releaseMacro'});
    $href_referenceGdses      = _hrefDeepCopy( 'referenceGdses',
        $href_referenceGdses, $returned{'referenceGdses'});
    if ( exists $returned{'stackHash'} ){
        $href_stackHash           = _hrefDeepCopy( 'stackHash', $href_stackHash, 
            $returned{'stackHash'});
    }else{
        $href_stackHash = {};
    }

    $href_shimMacros          = _hrefDeepCopy( 'shimMacros', $href_shimMacros, 
        $returned{'shimMacros'});
    $href_phyvMacros          = _hrefDeepCopy( 'phyvMacros', $href_phyvMacros, 
        $returned{'phyvMacros'});
    dprint(CRAZY+1, "\$my legal_phyvMacros=".scalar(Dumper $href_phyvMacros)."\n" );
    dprint(CRAZY+1, "\$my legal_shimMacros=".scalar(Dumper $href_shimMacros)."\n" );
    prompt_before_continue(CRAZY+1);

    my $aref_icv_report_list     = $returned{'icv_report_list' };
    my $aref_calibre_report_list = $returned{'calibre_report_list'};

    # NOTE: readLegalRelease did not return the Gdses, it fills in
    # the passed in reference to a hash. So the caller of readLegalRelease
    # can then just look at what got filled in.

    print_function_footer();
    return( $rel, $p4ReleaseRoot, $referenceDateTimeLibs, $process, 
        $metalStack, $metalStackIp, $metalStackCover, $href_stackHash,
        $layers, $href_layersOverrides, $supplyPins, $href_supplyPinsOverrides, 
        $href_areaOverrides, $href_bndLayer, $releaseShimMacro, $releasePhyvMacro, 
        $releaseUtilityMacro, $releaseRepeaterMacro, $projDiskArchiveLibFiles,
        $coverStackExists, 
        $releaseDefMacro, 
        $autoMatch,
        $href_shimMacros, 
        $href_phyvMacros, 
        $href_releaseMacro,
        $href_repeaterSubMacros,
        $aref_timingLibs,
        $href_referenceGdses,
        $aref_utilityMacro,
        $aref_CtlMacs,
        $aref_repeaterMacro,
        $aref_allowed_timing_cases,
        $calibre_verifs, 
        $verif_remove, 
        $verif_addi, 
        $aref_customerMacro,
        $aref_icv_report_list, 
        $aref_calibre_report_list); 
} # END readLegalRelease

#-------------------------------------------------------------------------------
#  This version of the subroutine for parsing the legalRelease.txt file is the
#      one that will be supported. Use this one, not the other. 
#  Read the legalRelease file into a hash ... used in BehaveRelease, PhyvRelease
#-------------------------------------------------------------------------------
sub processLegalReleaseFile($$){
   print_function_header();
   my $fname_projRelFile = shift;
   my $href_legalRelease = shift;

   my @default_report_list         = ("ant", "drc", "erc", "lvs", "drcint"); # the default list of reports to be generated 
   my @default_icv_report_list     = @default_report_list;
   my @default_calibre_report_list = @default_report_list;
   my $utilityMacroDefault  = 'dwc_ddrphy_utility_cells';
   my $repeaterMacroDefault = 'dwc_ddrphy_repeater_cells';
   my @allowedTiming = ( "ccsn","ccsn_lvf","lvf","nldm" );
 
   $href_legalRelease->{'allowedTimingCases'} = \@allowedTiming;

   my $autoMatch=1;

   if ( $fname_projRelFile =~ m/\.yml$/ ) {
       _read_yaml_legalRelease($href_legalRelease, $fname_projRelFile, \$autoMatch, \@default_report_list, \@allowedTiming);
   }else{
       _read_tcl_legalRelease($href_legalRelease, $fname_projRelFile, \$autoMatch, \@default_report_list, \@allowedTiming);
   }
   
   ##--------------------------------------------------------------------------
   ## ensure that the release variables are set, else abort (exit) !
   ##--------------------------------------------------------------------------
   hashCheck('rel',          'rel',             $href_legalRelease, $fname_projRelFile, 'exit');
   hashCheck('p4ReleaseRoot','p4_release_root', $href_legalRelease, $fname_projRelFile, 'exit');
   hashCheck('metalStack',   'metal_stack',     $href_legalRelease, $fname_projRelFile, 'exit');
   hashCheck('metalStackIp', 'metal_stack_ip',  $href_legalRelease, $fname_projRelFile, 'exit');
   hashCheck('layers',       'layers',          $href_legalRelease, $fname_projRelFile, 'exit');
   hashCheck('supplyPins',   'supply_pins',     $href_legalRelease, $fname_projRelFile, 'exit');
   
   ##--------------------------------------------------------------------------
   ## check if variables are set, else warn user (do not exit)
   ##--------------------------------------------------------------------------
   hashCheck('process',              'process',      $href_legalRelease, $fname_projRelFile, 'warn');
   hashCheck('lefdiffRel',           'lef_diff_rel', $href_legalRelease, $fname_projRelFile, 'warn');
   hashCheck('metalStackCover',      'metal_stack_cover', $href_legalRelease, $fname_projRelFile, 'warn');
   hashCheck('releaseCtlMacro',      'releaseCtlMacro', $href_legalRelease, $fname_projRelFile, 'warn');
   hashCheck('releaseShimMacro',     'releaseShimMacro', $href_legalRelease, $fname_projRelFile, 'warn');
   hashCheck('releasePhyvMacro',     'releasePhyvMacro', $href_legalRelease, $fname_projRelFile, 'warn');
   hashCheck('releaseRepeaterMacro', 'releaseRepeaterMacro', $href_legalRelease, $fname_projRelFile, 'warn');
   hashCheck('referenceDateTime',    'reference_date_time', $href_legalRelease, $fname_projRelFile, 'warn');

   if ( ! exists( $href_legalRelease->{'timingLibs'} )){
       fatal_error( "Failed to find 'timing_libs' timing libs types in "
              ."project release file:\n\t'$fname_projRelFile'\n");
       return();
   }

   unless( exists $href_legalRelease->{'timingLibs'} ){ 
       fatal_error( "Failed to find 'timing_libs' timing libs types in "
              ."project release file:\n\t'$fname_projRelFile'\n", 1 );
       return();
   }

   unless( exists $href_legalRelease->{'referenceDateTime'} ){
      $href_legalRelease->{'referenceDateTime'} = '14 days ago';
      wprint("Setting 'referenceDateTime' to ". $href_legalRelease->{'referenceDateTime'}. "\n");
   }

   # P10020416-38478
   # set defaults
   my %propList = (
       'calibre_verifs'=>{ 'default' => 'false' },
       'verif_remove'  =>{ 'default' => NULL_VAL },
       'verif_addi'    =>{ 'default' => NULL_VAL },
   );
   # P10020416-38478
   foreach my $prop ( keys %propList ) {
       my $href_value = $propList{"$prop"};
       set_default_if_needed( 
            $prop,
            $href_value->{'default'},
            $href_legalRelease);
   }
   # Now build the output array refs for icv_report_list
   # P10020416-39615
   if ( exists $href_legalRelease->{'verif_remove'} && $href_legalRelease->{'verif_remove'} ne NULL_VAL ){
       viprint(LOW, "Before verif_remove icv_report_list: " . join(',', @default_icv_report_list) . "\n");
       foreach my $item ( split /\s+/, $href_legalRelease->{'verif_remove'} ) {
          @default_icv_report_list     =  map { $_ ne $item ? $_ : "" } @default_icv_report_list;
       }
       # The above map code will replace the removed items with an empty string. So, we want to build a new
       # array minus the empty strings.
       my @temp_list = @default_icv_report_list;
       @default_icv_report_list = ();
       foreach my $item (@temp_list){
           if ( $item ne "") {
               push(@default_icv_report_list, $item);
           }
       }
       viprint(LOW, "After verif_remove icv_report_list: " . join(',', @default_icv_report_list) . "\n");
   }
   if ( exists $href_legalRelease->{'verif_addi'} && ($href_legalRelease->{'verif_addi'} ne NULL_VAL) ) {
       viprint(LOW, "Before verif_addi: icv_report_list: " . join(',', @default_icv_report_list) . "\n");
       foreach my $item ( split /\s+/,$href_legalRelease->{'verif_addi'}){
           push(@default_icv_report_list, lc($item)) if !grep{$_ eq $item}@default_icv_report_list;
       }
       viprint(LOW, "After verif_addi: icv_report_list: " . join(',', @default_icv_report_list) . "\n");
   }
   # Now build the output array refs for calibre_report_list
   viprint(LOW, "Before looking for calibre_verifs the default_calibre_list is " . join(',', @default_calibre_report_list) . "\n");
   if ( $href_legalRelease->{'calibre_verifs'} eq 'false' ){
       @default_calibre_report_list = (); # empty the list
   }else{
       if ( exists $href_legalRelease->{'verif_remove'} && $href_legalRelease->{'verif_remove'} ne NULL_VAL ){
           viprint(LOW, "Before verif_remove calibre_report_list: " . join(',', @default_calibre_report_list) . "\n");
           foreach my $item ( split /\s+/, $href_legalRelease->{'verif_remove'} ) {
              @default_calibre_report_list =  map { $_ ne $item ? $_ : "" } @default_calibre_report_list;
           }
           # The above map code will replace the removed items with an empty string. So, we want to build a new
           # array minus the empty strings.
           my @temp_list = @default_calibre_report_list;
           @default_calibre_report_list = ();
           foreach my $item (@temp_list){
               if ( $item ne "") {
                   push(@default_calibre_report_list, $item);
               }
           }
           viprint(LOW, "After verif_remove calibre_report_list: " . join(',', @default_calibre_report_list) . "\n");
       }
       if ( exists $href_legalRelease->{'verif_addi'} && ($href_legalRelease->{'verif_addi'} ne NULL_VAL) ) {
           viprint(LOW, "Before verif_addi: calibre_report_list: " . join(',', @default_calibre_report_list) . "\n");
           foreach my $item ( split /\s+/,$href_legalRelease->{'verif_addi'}){
               push(@default_calibre_report_list, lc($item)) if !grep{$_ eq $item}@default_calibre_report_list;
           }
           viprint(LOW, "After verif_addi: calibre_report_list: " . join(',', @default_calibre_report_list) . "\n");
       }
   }
   # P10020416-38478
   $href_legalRelease->{'calibre_report_list'} = [ @default_calibre_report_list ];
   $href_legalRelease->{'icv_report_list'}     = [ @default_icv_report_list ];


   # Additional processing for the release variables
   
   # Adding cvcp cvpp vflag to default prune list
   if ( defined( $href_legalRelease->{'cdlPruneCells'} )){
      $href_legalRelease->{'cdlPruneCells'} = $href_legalRelease->{'cdlPruneCells'} . " cvcp* cvpp* vflag*";
   }
   
   ## set default for release GDS/CDL
   unless( defined($href_legalRelease->{'relGdsCdl'}) ){
      $href_legalRelease->{'relGdsCdl'} = 'HIPRE';
      viprint(LOW, "\tSetting release GDS/CDL to '$href_legalRelease->{'relGdsCdl'}' ".
                   "default value.\n");
   }
  
   #--------------------------------------------------------------------------
   ## set default for shim release GDS 
   unless( defined($href_legalRelease->{'relGdsShim'}) ){
      $href_legalRelease->{'relGdsShim'} = 'drcint';
      viprint(LOW, "\tSetting release GDS of shim macros to '$href_legalRelease->{'relGdsShim'}' ".
                   "default value.\n");
   }
   
   #--------------------------------------------------------------------------
   if( defined $href_legalRelease->{'releaseShimMacro'} ){
      my @fields = split ' ',$href_legalRelease->{'releaseShimMacro'};
      foreach my $field (@fields){
         $href_legalRelease->{'shimMacros'}->{$field} = [$field];
      }
   }
   
   #--------------------------------------------------------------------------
   if( defined $href_legalRelease->{'releasePhyvMacro'} ){
      my @fields = split(' ',$href_legalRelease->{'releasePhyvMacro'});
      foreach my $field (@fields){
         $href_legalRelease->{'phyvMacros'}->{$field} = [$field];
      }
   }

   #--------------------------------------------------------------------------
   ## set utility macro name
   my $isRelUtil = 0;
   
   if( !defined($href_legalRelease->{'utilityMacro'})
       || !@{$href_legalRelease->{'utilityMacro'}} ){
         push(@{$href_legalRelease->{'utilityMacro'}},$utilityMacroDefault);
         viprint(LOW, "\tSetting utility macro name to '$utilityMacroDefault' default value.\n");
   }
   
   ## set utility macro cells
   foreach my $util (@{$href_legalRelease->{'utilityMacro'}}) {
      if( defined($href_legalRelease->{'releaseMacro'}->{$util}) ){
         $isRelUtil++; 
      }
   }

   unless( $isRelUtil ) {
      unless( defined($href_legalRelease->{'releaseUtilityMacro'}) ){
         wprint("Failed to find 'releaseUtilityMacro' utility macro cells in ".
                "'$fname_projRelFile' project release file.\n");
      }else{
         my @fields = split(/\s+/,$href_legalRelease->{'releaseUtilityMacro'});
         foreach my $utilityMac (@{$href_legalRelease->{'utilityMacro'}}) { 
            $href_legalRelease->{'phyvMacros'}->{$utilityMac} = [(@fields)]; 
         }
      }
   }else{
      foreach my $utilityMac (@{$href_legalRelease->{'utilityMacro'}}) {
         my @fields = split(/\s+/,$href_legalRelease->{'releaseMacro'}->{$utilityMac});
         $href_legalRelease->{'phyvMacros'}->{$utilityMac} = [(@fields)];
      }
   }

   #--------------------------------------------------------------------------
   ## set repeater macro name
   my $isRelRep  = 0;

   if ( exists $href_legalRelease->{'repeaterMacro'} ){
       unless( defined $href_legalRelease->{'repeaterMacro'} && @{$href_legalRelease->{'repeaterMacro'}} ){ 
           push(@{$href_legalRelease->{'repeaterMacro'}}, $repeaterMacroDefault);
           viprint(LOW, "\tSetting repeater macro name to '$repeaterMacroDefault' default value.\n");
       }
   }else{
       push(@{$href_legalRelease->{'repeaterMacro'}}, $repeaterMacroDefault);
       viprint(LOW, "\tSetting repeater macro name to '$repeaterMacroDefault' default value.\n");
   }


   foreach my $rep ( @{$href_legalRelease->{'repeaterMacro'}} ){
      if( defined $href_legalRelease->{'releaseMacro'}->{$rep} ){
         $isRelRep++; 
      }
   }
   
   ## set repeater macro cells if any
   unless( $isRelRep ) {
      unless( defined $href_legalRelease->{'releaseRepeaterMacro'} ){
         wprint( "Failed to find 'releaseRepeaterMacro' repeater macro cells in ".
                 "'$fname_projRelFile' project release file.\n");
      }else{
         my @fields = split(/\s+/,$href_legalRelease->{'releaseRepeaterMacro'});
         foreach my $repeaterMac (@{$href_legalRelease->{'repeaterMacro'}}) {
            $href_legalRelease->{'repeaterSubMacros'}->{$repeaterMac} = [(@fields)]; 
         }
      }
   }else{
      foreach my $repeaterMac ( @{$href_legalRelease->{'repeaterMacro'}} ){
         my @fields = split(/\s+/,$href_legalRelease->{'releaseMacro'}->{$repeaterMac});
         $href_legalRelease->{'repeaterSubMacros'}->{$repeaterMac} = [(@fields)]; 
      }
   }
   #--------------------------------------------------------------------------
   ## set ctl macro cells if any
   my @ctlMacs;
   if( defined $href_legalRelease->{'releaseCtlMacro'} ){
       @ctlMacs = split(/\s+/, $href_legalRelease->{'releaseCtlMacro'} );
   }
   $href_legalRelease->{'ctlMacs'} = \@ctlMacs;
   #--------------------------------------------------------------------------
   ## Process Metal Stacks
   $href_legalRelease->{'autoMatch'} = $autoMatch; 

   if ( $main::DEBUG >= LOW ) {
       if ( ! exists  $href_legalRelease->{'metalStack'} ){
           dprint(LOW, "No metalStack in legalRelease hash\n");
       }else{
           dprint_dumper(LOW, "metalStack value: " , $href_legalRelease->{'metalStack'});
       }

       if ( ! exists  $href_legalRelease->{'metalStackIp'} ){
           dprint(LOW, "No metalStackIp in legalRelease hash\n");
       }else{
           dprint_dumper(LOW, "metalStackIp value: " , $href_legalRelease->{'metalStackIp'});
       }

   }
   my @metalStacks   = split(/\s+/, $href_legalRelease->{'metalStack'}   );
   my @metalStacksIp = split(/\s+/, $href_legalRelease->{'metalStackIp'} );
   if( $autoMatch ){
      my %stackHash;
      stackMatch( \@metalStacks, \@metalStacksIp, \%stackHash);
      $href_legalRelease->{'stackHash'} = \%stackHash;
   }

   dprint_dumper(CRAZY, "\%legalRelease => ", $href_legalRelease);
   
   print_function_footer();
   # End of processLegalReleaseFile
}

sub _convert_to_lowercase($$) {
    my $varname = shift;
    my $href_legalRelease = shift;

    if ( $varname eq "timing_libs" && exists $href_legalRelease->{"$varname"} ) {
        # force the value to be lowercase value
        $href_legalRelease->{"$varname"} = [map{lc}@{$href_legalRelease->{"$varname"}}];
    }

    return;
}
sub _convert_aref_to_string($$){
    my $key               = shift;
    my $href_legalRelease = shift;
    # The keys in this are names expected to be found in our internal
    # legal release hash table (not the yaml names).
    my %vars_aref_to_string = (
        "releasePhyvMacro" => 1,
        "releaseCtlMacro"  => 1,
        "releaseDefMacro"  => 1,
    );


    if ( exists $href_legalRelease->{"$key"} && (exists $vars_aref_to_string{"$key"} )){
        # we expect this to be a list coming from YAML (an aref), but we want it to
        # be a string when returning our hash table.
        my $aref_list = $href_legalRelease->{"$key"};
        if ( ! isa_aref( $aref_list )){
            fatal_error("Expected an array ref for $key !\n");
        }
        my $newvalue = join(" ", @$aref_list);
        $href_legalRelease->{"$key"} = $newvalue;
    }
}


sub _convert_to_aref($$) {
    my $varname = shift;
    my $href_legalRelease = shift;

    # These are the variables that we need to post-process to convert
    # them to array references if they are a scalar.
    # Note: these names are the names before mapping occurs to our internal names.
    # So, these are what you would see in the legalRelease file itself.
    my %vars_to_aref = (
        "timing_libs"          => 1,
        "repeater_name"        => 1,
        "utility_macro"        => 1,
        "utility_name"         => 1,
        "releaseRepeaterMacro" => 1,
        "releaseTCMacro"       => 1,
        "customerMacro"        => 1,
    );

    return  if ( ! exists $vars_to_aref{"$varname"} );

    if ( exists $href_legalRelease->{"$varname"} ) {
        my $value =  $href_legalRelease->{"$varname"};
        # should be a scalar string with spaces; we convert it to an array ref
        # but it's also possible it could already be an array ref
        if ( isa_scalar($value) ) {
            $href_legalRelease->{"$varname"} = [split(/\s/,$value)];
        }
    }

    return;
}


sub _read_yaml_legalRelease($$){
    my $href_legalRelease      = shift;
    my $fname_projRelFile      = shift;
    my $autoMatchRef           = shift;
    my $aref_defaultReportList = shift;
    my $aref_allowedTiming     = shift;

    my @default_report_list    = @$aref_defaultReportList;
    my @allowedTiming          = @$aref_allowedTiming;

    my %valid_names= (
        "area_override"               => 1,
        "boundary_layer"              => 1,
        "calibre_verifs"              => 1,
        "cdl_prune_cells"             => 1,
        "customerMacro"               => 1,
        "defIgnore"                   => 1,
        "ferel"                       => 1,
        "internalTimingMacroList"     => 1,
        "layers"                      => 1,
        "layers_override"             => 1,
        "layout_tag"                  => 1,
        "lef_diff_rel"                => 1,
        "metal_stack"                 => 1,
        "metal_stack_cover"           => 1,
        "metal_stack_ip"              => 1,
        "metal_stack_minimal"         => 1,
        "metal_stack_match"           => 1,
        "p4_release_root"             => 1,
        "process"                     => 1,
        "proj_disk_archive_lib_files" => 1,
        "reference_date_time"         => 1,
        "reference_gds"               => 1,
        "rel"                         => 1,
        "releaseBranch"               => 1,
        "releaseCtlMacro"             => 1,
        "releaseDefMacro"             => 1,
        "release_gds_cdl"             => 1,
        "release_gds_shim"            => 1,
        "releaseIgnoreMacro"          => 1,
        "releaseMacro"                => 1,
        "releaseMailDist"             => 1,
        "releasePhyvMacro"            => 1,
        "releasePmMailDist"           => 1,
        "releaseRepeaterMacro"        => 1,
        "releaseRepeaterTagLayers"    => 1,
        "releaseShimMacro"            => 1,
        "releaseTCMacro"              => 1,
        "releaseTCMailDist"           => 1,
        "releaseUtilityMacro"         => 1,
        "releaseUtilityTagLayers"     => 1,
        "repeater_name"               => 1,
        "supply_pins"                 => 1,
        "supply_pins_override"        => 1,
        "timing_libs"                 => 1,
        "utility_name"                => 1,
        "utility_tag_layers"          => 1,
        "vcrel"                       => 1,
        "verif_addi"                  => 1,
        "verif_remove"                => 1,
    );

    $YAML::XS::ForbidDuplicateKeys = 1;

    viprint(LOW, "YML: load file $fname_projRelFile\n");
    my $yaml = YAML::XS::LoadFile( $fname_projRelFile);
    my $n = keys %{$yaml};
    viprint(LOW, "There are '$n' variables set\n");

    foreach my $keyname (keys %{$yaml}) {
        viprint(LOW, "YML: keyname from yaml:  key=$keyname\n");
        if ( ! exists $valid_names{"$keyname"} ){
            eprint("UnknownLegalReleaseLine '$keyname' in '$fname_projRelFile'\n");
            next;
        }
        my $value = $yaml->{$keyname};
        # Transfer the yaml data structures and values into our expected hash table
        $href_legalRelease->{"$keyname"} = $value;
    }

    # Now we want to map the set NAME with what our perl clients expect to find
    my %mapping = ( 
        "p4_release_root"      => "p4ReleaseRoot", 
        "metal_stack"          => "metalStack",
        "metal_stack_ip"       => "metalStackIp",
        "metal_stack_minimal"  => "metalStackIp",
        "metal_stack_cover"    => "metalStackCover",
        "metal_stack_match"    => "metal_stack_match",  # special processing required
        "supply_pins"          => "supplyPins",
        "supply_pins_override" => "supplyPinsOverrides",
        "timing_libs"          => "timingLibs",       # requires special attention (expecting a scalar, convert to an array ref)
        "lef_diff_rel"         => "lefdiffRel",
        "reference_date_time"  => "referenceDateTime",
        "cdl_prune_cells"      => "cdlPruneCells",
        "layers_override"      => "layersOverrides",
        "utility_name"         => "utilityMacro",
        "release_gds_cdl"      => "relGdsCdl",
        "release_gds_shim"     => "relGdsShim",
        "reference_gds"        => "referenceGdses",
        "repeater_name"        => "repeaterMacro",
        "area_override"        => "areaOverrides",
        "boundary_layer"       => "bndLayer",
        "releaseUtilityTagLayers" => "utilityMacroTagLayers",
        "releaseRepeaterTagLayers" => "repeaterMacroTagLayers",
        "proj_disk_archive_lib_files" => "projDiskArchiveLibFiles",
    );

    my @keys = keys(%$href_legalRelease);
    foreach my $key ( @keys ) {
        iprint("Found $key ");
        my $tvalue = $href_legalRelease->{"$key"};
        if ( defined $tvalue ) {
            if ( isa_href( $tvalue ) ){
                nprint(" Value Keys='" . join(',', keys(%$tvalue)) . "'\n");
            }elsif ( isa_aref( $tvalue) ) {
                nprint( " Value List='" . join(',',@$tvalue) . "'\n");
            }else{
                nprint(" Value String='$tvalue'\n")
            }
        }else{
            nprint(" but has no value\n");
        }


        _convert_aref_to_string($key, $href_legalRelease);
        if ( exists $href_legalRelease->{"$key"} && ($key eq "releaseMacro") ) {
            # The YAML parser will see the key values as array refs... but
            # the post-processing code expects these values as strings. So, 
            # it needs to be converted to a string here.
            # This is silly, but to change the rest of the code would be more
            # work at the moment. My goal is to try and not touch the original
            # code; or as little is needed.
            my $href_releaseMacro = $href_legalRelease->{"$key"};
            if ( ! isa_href( $href_releaseMacro )){
                fatal_error("releaseMacro in .yml file is not an expected hashref!\n");
            }

            foreach my $rmKey (keys %$href_releaseMacro ){
                my $aref_value = $href_releaseMacro->{"$rmKey"};
                if ( ! isa_aref( $aref_value )) {
                    fatal_error("releaseMacro{$rmKey} in .yml file is not an expected array ref!\n");
                }

                # convert to a string with space speration
                my $scalar_value = join(" ", @$aref_value);
                $href_releaseMacro->{"$rmKey"} = $scalar_value;  # string
            }
        }

        _convert_to_aref( $key, $href_legalRelease );
        _convert_to_lowercase( $key, $href_legalRelease); 

        if ( exists $href_legalRelease->{"$key"} && $key eq "metal_stack_match" ){
            $$autoMatchRef = 0;
            my $value = $href_legalRelease->{"$key"};
            if ( ! isa_scalar( $value ) ){
                my $typestring = ref \$value;
                fatal_error("Expected to get a scalar value here but didn't! $typestring");
            }

            process_metal_stack_hash($value, $autoMatchRef, $href_legalRelease); 
            viprint(LOW, "\tFound '$value' stack matching options.\n");
        }

        # Remap key to newkey if it's found in the mapping table and also in
        # the legalRelease table.
        if ( exists $mapping{"$key"} ){
            my $value = $href_legalRelease->{"$key"};
            delete $href_legalRelease->{"$key"};

            my $newkey = $mapping{"$key"};
            $href_legalRelease->{"$newkey"} = $value;
        }
    }

    return;
}

sub _read_tcl_legalRelease($$){
   my $href_legalRelease      = shift;
   my $fname_projRelFile      = shift;
   my $autoMatchRef           = shift;
   my $aref_defaultReportList = shift;
   my $aref_allowedTiming     = shift;

   my @default_report_list = @$aref_defaultReportList;
   my @allowedTiming       = @$aref_allowedTiming;

   my @legalReleaseFile = read_file($fname_projRelFile, "Failed to open project release file: '$fname_projRelFile'\n");
   iprint( "Reading '$fname_projRelFile' project release file...\n" );
   
   $$autoMatchRef = 1;
   my $lineno     = 0; 
   foreach my $line ( @legalReleaseFile ){
      $lineno++;
      ## prune comments
      $line =~ s/\#.*//;
      ## find release value
      if( $line =~ /^\s*set\s+rel\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'rel'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'rel'}' release version.\n");
      ## find releaseTCMacro 
      }elsif( $line =~ /^\s*set\s+releaseTCMacro\s+\{([^\}]+)\}\s*$/i ){
         $href_legalRelease->{'releaseTCMacro'} = [split(/\s+/, $1)];
         viprint(LOW, "\tFound '[$1]' release TC macros.\n");
      ## find calibre_verifs
      }elsif( $line =~ /^\s*set\s+calibre_verifs\s+\"([^\"]+)\"\s*$/i ){ # P10020416-38478
          my $prop = 'calibre_verifs';
          # expect #1 to be "true" or "false"
          my $bool_value = $1;
          $href_legalRelease->{"$prop"} = 'false' if ( $bool_value =~ m/false/i );
          $href_legalRelease->{"$prop"} = 'true'  if ( $bool_value =~ m/true/i );
          unless ( exists $href_legalRelease->{"$prop"} ){
              eprint( "\t'$bool_value' is not a valid $prop value.\n");
              eprint( "\tValid $prop: \"true\", \"false\" .\n");
              exit(1);
          }
          viprint(LOW, "\tFound '$bool_value' for $prop\n");
      ## find verif_addi
      }elsif( $line =~ /^\s*set\s+verif_addi\s+\"([^\"]+)\"\s*$/i ){ # P10020416-38478
          my $prop = 'verif_addi';
          $href_legalRelease->{"$prop"} = $1;
          my @got = split(/\s+/, $1);
          viprint(LOW, "\tFound $prop'". join(" ", @got ) . "'\n");
      ## find verif_remove 
      }elsif( $line =~ /^\s*set\s+verif_remove\s+\"([^\"]+)\"\s*$/i ){ # P10020416-38478
          my $prop = 'verif_remove';
          $href_legalRelease->{"$prop"} = $1;
          my @valid_values = @default_report_list;
          verify_allowed($prop, \@valid_values, $href_legalRelease, "exit");
      ## find customerMacro {dwc_ddrphy_utility_blocks dwc_ddrphy_utility_cells}
      }elsif( $line =~ /^\s*set\s+customerMacro\s+{(.*)}\s*$/i ){ # P10020416-38478
          my $prop = 'customerMacro';
          $href_legalRelease->{"$prop"} = [split(/\s+/, $1)]; 
          viprint(LOW, "\tFound '$1' $prop\n");
      ## find customerMacro "dwc_ddrphy_utility_blocks dwc_ddrphy_utility_cells"
      }elsif( $line =~ /^\s*set\s+customerMacro\s+\"([^\"]+)\"\s*$/i ){ # P10020416-38478
          my $prop = 'customerMacro';
          $href_legalRelease->{"$prop"} = [split(/\s+/, $1)]; 
          viprint(LOW, "\tFound '$1' $prop\n");
      ## find defIgnore 
      }elsif( $line =~ /^\s*set\s+defIgnore\s+\{([^\}]+)\}\s*$/i ){
         $href_legalRelease->{'defIgnore'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'defIgnore'}' defIgnore.\n");
      ## find vcrel 
      }elsif( $line =~ /^\s*set\s+vcrel\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'vcrel'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'vcrel'}' vc release version.\n");
      ## find ferel 
      }elsif( $line =~ /^\s*set\s+ferel\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'ferel'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'ferel'}' fe release version.\n");
      ## find utility_tag_layers 
      }elsif( $line =~ /^\s*set\s+utility_tag_layers\s+\"([^\"]+)\"\s*$/i) {
        $href_legalRelease->{'utility_tag_layers'} = $1;
        viprint(LOW, "\tFound '$1' utility_tag_layers\n");
      ## find releaseBranch
      }elsif( $line =~ /^\s*set\s+releaseBranch\s+\"([^\"]+)\"\s*$/i) {
        $href_legalRelease->{'releaseBranch'} = $1;
        viprint(LOW, "\tFound '$1' releaseBranch\n");
      ## find releasePmMailDist
      }elsif( $line =~ /^\s*set\s+releasePmMailDist\s+\"([^\"]+)\"\s*$/i) {
        $href_legalRelease->{'releasePmMailDist'} = $1;
        viprint(LOW, "\tFound '$1' releasePmMailDist\n");
      ## find releaseMailDist
      }elsif( $line =~ /^\s*set\s+releaseMailDist\s+\"([^\"]+)\"\s*$/i) {
        $href_legalRelease->{'releaseMailDist'} = $1;
        viprint(LOW, "\tFound '$1' releaseMailDist\n");
      ## find releaseTCMailDist
      }elsif( $line =~ /^\s*set\s+releaseTCMailDist\s+\"([^\"]+)\"\s*$/i) {
        $href_legalRelease->{'releaseTCMailDist'} = $1;
        viprint(LOW, "\tFound '$1' releaseTCMailDist\n");
      ## find layout_tag 
      }elsif( $line =~ /^\s*set\s+layout_tag\s+\"([^\"]+)\"\s*$/i) {
        $href_legalRelease->{'layout_tag'} = $1;
        viprint(LOW, "\tFound '$1' layout_tag\n");
      ## find p4 release path root value
      }elsif( $line =~ /^\s*set\s+p4_release_root\s+[\"\{]([^\"]+)[\"\}]\s*$/i 
              || $line =~ /^\s*set\s+p4_release_root\s+\{([^\"]+)\s+/i ){
         $href_legalRelease->{'p4ReleaseRoot'} = $1;
         $href_legalRelease->{'p4ReleaseRoot'} =~ s/\s+.*//;;
         viprint(LOW, "\tFound '$href_legalRelease->{'p4ReleaseRoot'}' p4 release path root ".
                      "(for /u/$ENV{'USER'}/p4_ws/).\n");
      ## find process value
      }elsif( $line =~ /^\s*set\s+process\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'process'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'process'}' release process.\n");
      ## find metal stack value
      }elsif( $line =~ /^\s*set\s+metal_stack\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'metalStack'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'metalStack'}' release foundry ".
                      "metal stack.\n");
      ## find IP metal stack value
      }elsif( $line =~ /^\s*set\s+metal_stack_ip\s+\"([^\"]+)\"\s*$/i 
              || $line =~ /^\s*set\s+metal_stack_minimal\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'metalStackIp'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'metalStackIp'}' release IP metal stack.\n");
      ## find covercell metal stack value
      }elsif( $line =~ /^\s*set\s+metal_stack_cover\s+\"([^\"]*)\"\s*$/i ){
         $href_legalRelease->{'metalStackCover'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'metalStackCover'}' release cover metal stack.\n" );
      ## matching ip/top stack
      }elsif( $line =~ /^\s*set\s+metal_stack_match\s+\{([^\"]+)\}\s*$/i ){
         $$autoMatchRef = 0;
         my $found = $1;
         process_metal_stack_hash($found, $autoMatchRef, $href_legalRelease);
         viprint(LOW, "\tFound '$found' stack matching options.\n");
      ## find timing macro list
      }elsif( $line =~ m/^\s*set\s+internalTimingMacroList\s+{(.*)}\s*$/i){
         $href_legalRelease->{'internalTimingMacroList'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'internalTimingMacroList'}' timing macro list.\n");
      ## find layers value
      }elsif( $line =~ /^\s*set\s+layers\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'layers'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'layers'}' release layers.\n");
      ## find layers override value
      }elsif( $line =~ /^\s*set\s+layers_override\(([^\)]+)\)\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'layersOverrides'}->{$1} = $2;
         viprint(LOW, "\tFound '$href_legalRelease->{'layersOverrides'}->{$1}' release layers ".
                      "override for macro '$1'.\n");
      ## find supply pins value
      }elsif( $line =~ /^\s*set\s+supply_pins\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'supplyPins'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'supplyPins'}' release supply pin layers.\n");
      ## find supply pins override value
      }elsif( $line =~ /^\s*set\s+supply_pins_override\(([^\)]+)\)\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'supplyPinsOverrides'}->{$1} = $2;
         viprint(LOW, "\tFound '$href_legalRelease->{'supplyPinsOverrides'}->{$1}' release supply ".
                      "pin override layers for macro '$1'.\n");
      ## find reference GDS files for DI usage
      }elsif( $line =~ /^\s*set\s+area_override\(([^\)]+)\)\s+\"([^\"]+)\"\s*$/i ){
           ## find area override to read from LEF instead of pininfo
           ## $href_areaOverrides->{$1} = $2;
           $href_legalRelease->{'areaOverrides'}->{$1} = $2;
           viprint(LOW, "    Found '$href_legalRelease->{'areaOverrides'}->{$1}' area override for macro $1.\n" );
      }elsif( $line =~ /^\s*set\s+boundary_layer\(([^\)]+)\)\s+\"([^\"]+)\"\s*$/i ){
           ## find boundary layer for metric calculation (e.g. set boundary_layer "100:1")
           $href_legalRelease->{'bndLayer'} = $1;
           viprint(LOW, "    Found '$href_legalRelease->{'bndLayer'}' boundary layer.\n" );
      }elsif( $line =~ /^\s*set\s+reference_gds\(([^\)]+)\)\s+\{([^\{]+)\}\s*$/i ){
         $href_legalRelease->{'referenceGdses'}->{$1} = $2;
         viprint(LOW, "\tFound '$href_legalRelease->{'referenceGdses'}->{$1}' reference GDS files ".
                      "for macro '$1'.\n");
      ## find release GDS/CDL, default calibre
      ##   allows using ICV GDS/CDL files for release, **only** applies to TSMC N7 where Calibre is waived
      }elsif( $line =~ /^\s*set\s+release_gds_cdl\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'relGdsCdl'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'relGdsCdl'}' release GDS/CDL ".
                      "location for macro '$1'.\n");
      ## find shim release GDS, default drcint
      }elsif( $line =~ /^\s*set\s+release_gds_shim\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'relGdsShim'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'relGdsShim'}' release GDS".
                      "location of shim macros for macro '$1'.\n");
      ## find LEF diff release
      }elsif( $line =~ /^\s*set\s+lef_diff_rel\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'lefdiffRel'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'lefdiffRel'}' LEF diff release version.\n");
      ## find cells to prune from CDL
      }elsif( $line =~ /^\s*set\s+cdl_prune_cells\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'cdlPruneCells'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'cdlPruneCells'}' cells to prune CDL netlist.\n");
      ## find reference date time stamp
      }elsif( $line =~ /^\s*set\s+reference_date_time\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'referenceDateTime'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'referenceDateTime'}' reference ".
                      "date time stamp.\n");
      ## find shim release macros value
      }elsif( $line =~ /^\s*set\s+releaseShimMacro\s+\{([^\}]*)\}\s*$/i ){
         if ( $1 || $1 eq "" ) {
             $href_legalRelease->{'releaseShimMacro'} = $1;
             viprint(LOW, "\tFound '$href_legalRelease->{'releaseShimMacro'}' shim release macros.\n");
         }
      ## find shim releaseIgnoreMacro value
      }elsif( $line =~ /^\s*set\s+releaseIgnoreMacro\s+\{([^\}]+)\}\s*$/i ){
         $href_legalRelease->{'releaseIgnoreMacro'} = [split(/\s+/, $1)];
         viprint(LOW, "\tFound '".join(" ",@{$href_legalRelease->{'releaseIgnoreMacro'}}).
             "' release ignore macros.\n");
      ## find PHYV release macros value
      }elsif( $line =~ /^\s*set\s+releasePhyvMacro\s+\{([^\}]+)\}\s*$/i ){
         $href_legalRelease->{'releasePhyvMacro'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'releasePhyvMacro'}' PHYV release macros.\n");
      ## find utility macro name
      }elsif( $line =~ /^\s*set\s+utility_name\s+\{([^\}]+)\}\s*$/i ){
         $href_legalRelease->{'utilityMacro'} = [split(/\s+/, $1)];
         viprint(LOW, "\tFound '".join(" ",@{$href_legalRelease->{'utilityMacro'}}).
                      "' utility macro name.\n");
      ## find utility macro name in double quotes 
      }elsif( $line =~ /^\s*set\s+utility_name\s+\"([^\"]+)\"\s*$/i) {
         $href_legalRelease->{'utilityMacro'} = [split(/\s+/, $1)];
         viprint(LOW, "\tFound '".join(" ",@{$href_legalRelease->{'utilityMacro'}}).
                      "' utility macro name.\n");
      ## find repeater macro name
      }elsif( $line =~ /^\s*set\s+repeater_name\s+[\"\{]([^\"]*)[\"\}]\s*$/i ){
         $href_legalRelease->{'repeaterMacro'} = [split(/\s+/, $1)];
         viprint(LOW, "\tFound '".join(" ",@{$href_legalRelease->{'repeaterMacro'}}).
                      "' repeater macro name.\n");
      ## find utility release macros value
      }elsif( $line =~ /^\s*set\s+releaseUtilityMacro\s+\{([^\}]*)\}\s*$/i ){
          if ( $1 ){
             $href_legalRelease->{'releaseUtilityMacro'} = $1;
             viprint(LOW, "\tFound '$href_legalRelease->{'releaseUtilityMacro'}' utility macro ".
                          "release cells.\n");
          }
      ## find utility macro tag layers
      }elsif( $line =~ /^\s*set\s+releaseUtilityTagLayers\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'utilityMacroTagLayers'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'utilityMacroTagLayers'}' utility macro ".
                      "tag layers.\n");
      ## find repeater release macros value  in double quotes
      }elsif( $line =~ /^\s*set\s+releaseRepeaterMacro\s+\"([^\"]*)\"\s*$/i ){
         $href_legalRelease->{'releaseRepeaterMacro'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'releaseRepeaterMacro'}' repeater macro ".
                      "release cells.\n");
      ## find repeater release macros value
      }elsif( $line =~ /^\s*set\s+releaseRepeaterMacro\s+\{([^\}]+)\}\s*$/i ){
         $href_legalRelease->{'releaseRepeaterMacro'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'releaseRepeaterMacro'}' repeater macro ".
                      "release cells.\n");
      ## find repeater macro tag layers
      }elsif( $line =~ /^\s*set\s+releaseRepeaterTagLayers\s+\"([^\"]+)\"\s*$/i ){
         $href_legalRelease->{'repeaterMacroTagLayers'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'repeaterMacroTagLayers'}' repeater macro ".
                      "tag layers.\n");
      ## find release macros topcell name followed by the list of subcells
      }elsif( $line =~ /^\s*set\s+releaseMacro\{(\S+)\}\s+\{([^\}]+)\}\s*$/i ){
         $href_legalRelease->{'releaseMacro'}->{$1} = $2;
         viprint(LOW, "\tFound '$href_legalRelease->{'releaseMacro'}->{$1}' utility macro ".
                      "release cells.\n")
      ## find ctl release macros name  
      }elsif( $line =~ /^\s*set\s+releaseCtlMacro\s+\{([^\}]*)\}\s*$/i ){
         $href_legalRelease->{'releaseCtlMacro'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'releaseCtlMacro'}' ctl macro release cells.\n");
      ## find variable to archive LIB files on project disk
      }elsif( $line =~ /^\s*set\s+proj_disk_archive_lib_files\s*$/i ){
         ## ljames fix 9/13/2022: it was '$projDiskArchiveLibFiles'
         $href_legalRelease->{'projDiskArchiveLibFiles'} = 1;
         viprint(LOW, "\tFound '$href_legalRelease->{'projDiskArchiveLibFiles'}' project disk archive LIB files tag.\n" );
      }elsif( $line =~ /^\s*set\s+timing_libs\s+\{([^\}]+)\}\s*$/i ){
         $href_legalRelease->{'timingLibs'} = [split(/\s/,$1)];
         $href_legalRelease->{'timingLibs'} = [map{lc}@{$href_legalRelease->{'timingLibs'}}];
         #  Example: @timingLibs = (nldm, lvf);
         my $invalid = 0;
         foreach my $tl ( @{$href_legalRelease->{'timingLibs'}} ){
            if( !grep{/^$tl$/} @allowedTiming ){
               eprint( "'$tl' is not a valid timing_libs value.\n");
               $invalid += 1;
            }
         }
         if( $invalid ){
             eprint( "\tValid timing_libs:". join(" ", @allowedTiming ) ."\n");
             exit(1);
         }

         viprint(LOW, "\tFound timing libs: '". 
                        join( " ", @{$href_legalRelease->{'timingLibs'}}) ."'\n" );
      ## find def release macros name  
      }elsif( $line =~ /^\s*set\s+releaseDefMacro\s+\{([^\}]+)\}\s*$/i ){
         dprint(CRAZY+1, "DefMacro Debug line='$line'\n" );
         $href_legalRelease->{'releaseDefMacro'} = $1;
         viprint(LOW, "\tFound '$href_legalRelease->{'releaseDefMacro'}' def macro release cells.\n" );
      }else{
          my $skip=0;
          $skip=1 if ( $line =~ m/^\s*$/ );
          $skip=1 if ( $line =~ m/^\s*#/ );
          if ( ! $skip ){
              # Raising this to an Error from a Warning was requested by Golnar
              eprint("UnknownLegalReleaseLine at '$lineno' file '$fname_projRelFile' line '$line'\n");
          }
      }
   } ## end foreach my $line ( @legalReleaseFile )   

   return;
} # end of _read_tcl_legalRelease( 

sub process_metal_stack_hash($$$) {
    my $scalar_value      = shift;
    my $autoMatchRef      = shift;
    my $href_legalRelease = shift;

    my @stackMatches = split(/\s+/,$scalar_value);
    foreach my $match (@stackMatches) {
        $match =~ s/^\s+|\s+$//g;
        my ( $ipstack, $topstack ) = split(/\s+/,$match);
        if( $ipstack eq "" || $topstack eq "" ){ 
            wprint("Incorrect stack match setup. Script will try to auto match ip stack and top stack\n".
                "\tCorrect format is 'set metal_stack_match {metal_stack_ip1 metal_stack_1,".
                "metal_stack_ip2 metal_stack_2}'\n");
            $$autoMatchRef = 1;
        }else{
            ($ipstack, $topstack) = arrangeStacks($ipstack, $topstack);
            if( $ipstack =~ /ERROR/ ){ 
                wprint("Possible incorrect stack match setup. Script will try to auto match ip".
                    " stack and top stack\n\t Correct format is 'set metal_stack_match".
                    " {metal_stack_ip1 metal_stack_1, metal_stack_ip2 metal_stack_2}'\n");
                $$autoMatchRef = 1;
            }else{
                $href_legalRelease->{'stackHash'}->{"$topstack"} = $ipstack; 
            }
        }
    }
}

#-------------------------------------------------------------------------------
#  ensure key is set in the legalrelease hash. If not, '$action' specifies
#      whether to 'exit' or 'warn' user.
#-------------------------------------------------------------------------------
sub hashCheck($$$$$){ 
    my $var               = shift;
    my $var_infile        = shift;
    my $href              = shift;
    my $fname_projRelFile = shift;
    my $action            = shift;

    if ( ! isa_href( $href ) ){
        wprint("hashCheck 2nd argument is not a hash reference!\n");
        return;
    }

    if( !exists $href->{$var} ){
       my $msg = "Failed to find '$var_infile' in release file, doesn't exist: '$fname_projRelFile'\n";
       if( $action eq 'exit' ){
           fatal_error( $msg, 1 );
           return -1;
       }else{
           wprint( $msg );
           return 1;
       }
    } else { 
       unless( defined $href->{$var} ){
          my $msg = "Failed to find '$var_infile' in release file, isn't defined: '$fname_projRelFile'\n";
          if( $action eq 'exit' ){
              fatal_error( $msg, 1 );
              return -1;
          }else{
              wprint( $msg );
              return 1;
          }
       }
    }

    return 0;
}

#-------------------------------------------------------------------------------
# Get the number of dirty/error and warnings messages in a file 
#-------------------------------------------------------------------------------
sub countDirtysAndWarnings($){
   print_function_header();
   my $file = shift;
   
   my @fileContent = read_file($file, "Failed to read '$file'");
   
   # P10020416-36256
   # In older releases of tools that created the contents of the file we
   # are parsing, it did not prefix the text lines with anything. A Dirty or
   # Warning message would be the first text encounted in the line of text.
   # Later, some scripts were modified which will prefix such lines of
   # text with -I- or -E- or -W- ; so we need to be able to handle both
   # cases. The original way, I'm using 'oldVARNAME' (eg. oldDirtysCount) and
   # handling the new way I'm just using VARNAME (eg. dirtysCount).
   my $oldDirtysCount   = grep{/^\s*Dirty|^\s*Error/i} @fileContent;
   my $oldWarningsCount = grep{/^\s*Warning/i        } @fileContent;
   my $dirtysCount      = 0;
   my $warningsCount    = 0;

   if ($oldDirtysCount == 0 and $oldWarningsCount == 0 ) {
       # So, if using the old pattern returned 0 for both greps, then it's likely
       # that we are dealing with the new output that has the -I-, etc prefixes.
       $dirtysCount   = grep{/^.*-[IWE]-.*\s*Dirty|^.*-[IWE]-.*\s*Error/i} @fileContent;
       $warningsCount = grep{/^.*-[IWE]-.*\s*Warning/i                   } @fileContent;
   }else{
       # if we did find a non-0 amount using the original patterns then we are
       # most likely dealing with the older type formatted output; in that case
       # we will use those values and not do the new pattern search.
       $dirtysCount   = $oldDirtysCount;
       $warningsCount = $oldWarningsCount;
   }

   print_function_footer();
   return($dirtysCount, $warningsCount);
}

#-------------------------------------------------------------------------------
#  sub 'getCadHome' :  look in the Project ENV file for the CAD
#      CCS area.  The vars cadhome, cadproj, cadrel, cadtech derived from
#      proj env file.  Here's example of the two lines needed:
#          setenv MSIP_CAD_PROJ_NAME c239-tsmc7ff-1.8v_st
#          setenv MSIP_CAD_REL_NAME  rel1.1.0 
#-------------------------------------------------------------------------------
sub getCadHome($) {
    print_function_header();

    my $fname_projEnv = shift;
    dprint( CRAZY, "fname_projEnv = '$fname_projEnv' \n" );

    my $cadproj = "";
    my $cadrel  = "";
    my $cadhome = "";
    my $cadtech = "";

    my $err_msg = "Couldn't read project ENV file '$fname_projEnv'";
    my @lines = read_file( $fname_projEnv, $err_msg );

    ###############################################################
    ## When the PCS uses a PROGRAM PCS instead of a CCS as the CAD
    ## reference, we need to look in the "Parent PCS" project.env
    ## file before looking for the CAD PROJ/REL variables.
    ## Full details in Jira P10020416-39914
    ###############################################################
    if(( grep( /MSIP_PARENT_PCS/, @lines ) ) && ( not grep /MSIP_CAD/, @lines )){
        hprint( "Use of Parent Program PCS detected... searching for parent...\n" );
        my $parentprod = "";
        my $parentproj = "";
        my $parentrel = "";

        foreach my $line ( @lines ){
            if( $line =~ m/setenv\s+MSIP_PARENT_PCS_PRODUCT_NAME\s+(\S+)/ ){
                $parentprod = $1;
            }
            if( $line =~ m/setenv\s+MSIP_PARENT_PCS_PROJ_NAME\s+(\S+)/ ){
                $parentproj = $1;
            }
            if( $line =~ m/setenv\s+MSIP_PARENT_PCS_REL_NAME\s+(\S+)/ ){
                $parentrel = $1;
            }
        }
        dprint( CRAZY, "parentprod = '$parentprod' \n" );
        dprint( CRAZY, "parentproj = '$parentproj' \n" );
        dprint( CRAZY, "parentrel  = '$parentrel' \n" );
        if( exists $ENV{DA_RUNNING_UNIT_TESTS}){
            return ( &getCadHome("$fname_projEnv" . ".parent", $err_msg ));
        }
        else {
            return ( &getCadHome("/remote/cad-rep/projects/$parentprod/$parentproj/$parentrel/cad/project.env") );
        }
    }
    ###############################################################

    foreach my $line ( @lines ){
        if( $line =~ m/setenv\s+MSIP_CAD_PROJ_NAME\s+(\S+)/ ){
            $cadproj = $1;
            # Extract the technology from cadproj
            if( defined $cadproj ){
                $cadproj       =~ s|"||g;  # strip out the double-quote (")
                my @citems     =  split(/-/, $cadproj);
                if( scalar(@citems) eq 3 ){
                    my $lefProcess =  $citems[1];
                    my $lefVol     =  $citems[2];
                    dprint(HIGH, "lefProcess='$lefProcess'\n");
                    dprint(HIGH, "lefVol    ='$lefVol'\n");
                    $lefVol        =~ s/[.v]//g;  ##  Remove "." and "v"
                    $cadtech       =  "${lefProcess}-$lefVol";
                }
            }
        }
        if( $line =~ m/setenv\s+MSIP_CAD_REL_NAME\s+(\S+)/ ){
            $cadrel = $1;
        }
    }
    dprint( CRAZY, "cadproj, cadrel = '$cadproj', '$cadrel'\n" );

    if( $cadproj && $cadrel ){
       $cadhome = "/remote/cad-rep/projects/cad/$cadproj/$cadrel/cad";
    }
    if( !$cadproj || !$cadrel || !$cadhome || !$cadtech ){
       my $ccslist = "";
       $ccslist .= 'MSIP_CAD_PROJ_NAME ' if ( !$cadproj);
       $ccslist .= 'MSIP_CAD_REL_NAME '  if ( !$cadrel);
       $ccslist .= 'cadhome '            if ( !$cadhome);
       $ccslist .= 'cadtech '            if ( !$cadtech);

       wprint( "Cannot find '$ccslist' CCS values from '$fname_projEnv'!\n");
    }

    dprint( CRAZY, "cadproj = '$cadproj' \n" );
    dprint( CRAZY, "cadrel  = '$cadrel'  \n" );
    dprint( CRAZY, "cadhome = '$cadhome' \n" );
    dprint( CRAZY, "cadtech = '$cadtech' \n" );

    print_function_footer();
    return( $cadproj, $cadrel, $cadhome, $cadtech );
}

#-------------------------------------------------------------------------------
#  Read project topcells.txt file and get the list of macros
#     stores them into %legalMacros hash
#-------------------------------------------------------------------------------
sub readTopCells($){
    print_function_header();
    my $fname_projMacroFile = shift;
    
    #=pod
    my %schlay;
    my @theTopCells = read_file( $fname_projMacroFile, 
            "I/O ERROR: Failed to open project macro file '$fname_projMacroFile'");
    ## read project macro file
    iprint( "Reading project macros file:\t'$fname_projMacroFile'\n");

    foreach my $line (@theTopCells) {
       chomp($line);
       $line =~ s/\#.*//;
       $line =~ s/\/layout|\/schematic//g;
       $line =~ s/\[LAY\]|\[SCH\]//g;
       $line =~ s/\s//g;
       next if( $line eq '');
       dprint(CRAZY, "TopCells File--line: '$line'\n" );
       my ($theLib,$theCell) = split(/\//,$line);
       if( $theLib eq "" || $theCell eq "") {
          fatal_error("Each line of the '$fname_projMacroFile'. project macro file are expected to be [VIEW]<libName>/<macroName>/<viewName> (or comments/blank), but is\n:$line", 1);
          exit(1); # in case fatal_error_NOEXIT is defined
       }
       $schlay{$theCell}++;
    }

    my %macros;
    foreach my $theCells ( keys %schlay ){
       if( $theCells =~ /cover/i ){
          $macros{$theCells}++;
          viprint(LOW, "    Found $theCells macro.\n" );
       }      
       if( $schlay{$theCells} >= 2 ){ 
          $macros{$theCells}++;
          viprint(LOW, "    Found $theCells macro.\n" );
       ## shim macros are allowed to have just 1 line defined in Topcells (i.e. [LAY])
       }elsif( $theCells =~ /shim|gradient|overlay/i ){
          $macros{$theCells}++;
          viprint(LOW, "    Found $theCells macro.\n" );
       }else{
          next;
       }
    }

    dprint(CRAZY, "Macros HASH extracted from TopCells File". scalar(Dumper \%macros) ."\n" );
    
    my @list_of_macro_names = keys %macros;
    ## ensure release variables set
    unless( $#list_of_macro_names ){
       fatal_error( "Failed to find any macros in '$fname_projMacroFile' project macro file.\n", 1 );
       exit 1;
    }
    
    print_function_footer();
    return( %macros );
}

#-------------------------------------------------------------------------------
#  Read project alphaNT.config file
#     Extracts PVT corner names (e.g. ffg0p825v125c) & data for each corner,
#     including : PVT corner names, power supply name + voltage, temperature.
#-------------------------------------------------------------------------------
sub readNtFile($) {
   print_function_header();
   my $fname_projNtFile = shift;

   ## read project NT file
   my @contents = read_file($fname_projNtFile, "I/O ERROR: Failed to open project NT file '$fname_projNtFile'");
   iprint("Reading project NT timing file:\t'$fname_projNtFile'\n");

   my ( @pvt_corners, %params );
   my $cnt=0;
   foreach my $line ( @contents ){
      chomp( $line );
      $cnt++;
      ## prune comments
      $line =~ s/\#.*//;
      ## find PVT corners
      if( $line =~ m/^\s*set\s+pvtCorners\s+\{\s*([^\}]+)\s*\}\s*$/i ){
         dprint(CRAZY, "alphaNT.config line $cnt: $line\n   extracted pvt list  :  '$1'\n" );
         @pvt_corners = split(/\s+/, $1);
         # P10020416-39864 - ljames - complain if this setting is using commas 
         #     for it's separator. Only spaces are allowed.
         if ( $line =~ m/,/ ) {
             fprint("Syntax Error in file: '$fname_projNtFile'\n");
             fprint("\tLine: '$line'\n");
             fatal_error("\tYour pvtCorners setting is using commas to separate each corner name.\n\tYou are required to use spaces to separate them. Please replace each comma with a space.\n");
         }
         dprint(CRAZY, "   extracted pvt values: ". pretty_print_aref(\@pvt_corners) ."\n" );
         viprint(LOW, "    Found timing corners: ". join( ', ', @pvt_corners) ."\n" );
        #  PJ 11/2021: Example cornerData statement from NT file:
        #        set cornerData(ffg0p825v0c) {VDD 0.825,VDDQ 0.57,VAA 1.21,VDDQ_VDD2H 1.21,TEMP 0,mos mos_ff,bjt bip_f,cap cap_l,diode dio_f,moscap_hv nmoscaphv_h,moscap nmoscap_h,mos_eflvt moseflvt_ff,mos_efsvt mosefsvt_ff,mos_elvt moselvt_ff,mos_hv moshv_ff,mos_lvt moslvt_ff,mos_ulvt mosulvt_ff,res res_l,xType rcc,beol typical,scPvt ffg0p825v0c}
        #  The only supply names that are valid in the 'set cornerData' statement 
        #  will be found in the 'set supplyPins' statement. Example:
        #        set supplyPins {VDD VDDQ VDDQ_VDDQ2H VAA}
      }elsif( $line =~ m/^\s*set\s+cornerData/ ){
         dprint(CRAZY, "alphaNT.config line $cnt: $line\n" );
         # Now that we have line with 'set_cornerData', process it. 
         #    Throw an error if format of line doesn't match expectation.
         if( $line =~ m/^\s*set\s+cornerData\(\s*([^\s\)]+)\s*\)\s*\{/ &&
            $line =~ m/\bV[A-Z_0-9]+\s+(\d+\.\d+)\b/                   &&  
            $line =~ m/\bTEMP\s+(\-?[\.\d]+)\b/                          ){
            ## find corner voltages
            $line =~ m/^\s*set\s+cornerData\(\s*([^\s\)]+)\s*\)\s*\{/;
            my $corner = $1;
            # Grab every supply name and voltage 
            while( $line =~ m/\b(V[A-Z_0-9]+)\s+(\d+\.\d+)\b/g ){
               $params{$corner}->{$1} = $2;
            }
            $line =~ m/\bTEMP\s+(\-?[\.\d]+)\b/;
            $params{$corner}->{'temp'} = $1;
            dprint(CRAZY, "Corner Data => ". scalar( Dumper \%params ) ."\n"  );
         }else{
            eprint( "On line '$cnt' of Project NT File '$fname_projNtFile', INVALID format of 'set cornerData'.\n".
                    "\t ==>$line\n".
                    "\t Unable to extract corner info->(supply, voltage, temp)!\n\t ==>$line\n".
                    "\t Every statement must have supply names must be in capital letters starting ".
                    "with 'V' followed by it's value (e.g. 1.21), and temperature specified as 'TEMP' ".
                    "followed by it's value (e.g. -40).\n" );
            prompt_before_continue(CRAZY);
         }
      }
   } ## end foreach @contents from file 
   ## close project NT file

   dprint(CRAZY, "Ckt Corner Params => ". scalar(Dumper \%params) ."\n"  );
   ## ensure release variables set
   if( !@pvt_corners ){
      fatal_error( "Failed to find 'pvtCorners' timing corners in '$fname_projNtFile' project NT timing file.\n", 1 );
   }
   foreach my $corner ( @pvt_corners ){
      if( !defined $params{$corner} ){
         fatal_error( "Failed to find 'pvtCorners' timing parameters for '$corner' corner in '$fname_projNtFile'".
                 " project NT timing file.\nParams => ". scalar(Dumper \%params) ."\n" , 1);
      }
   }

   return( \@pvt_corners, \%params )
}  # end of readNtFile

#------------------------------------------------------------------------------
#  Read the file 'legalVerifs.txt' to get the verification types for this project
#------------------------------------------------------------------------------
sub parseLegalVerifFile {
    print_function_header();
    my $projVerifFile = shift;

    my %legalVerifs;

    ## read project verif file (legalVerifs.txt)
    my @contents = read_file( $projVerifFile, "I/O ERROR: Failed to open VERIF file '$projVerifFile'");
    iprint("  Reading $projVerifFile project verif timing file...\n");
    my $line_no=0;
    foreach my $line ( @contents ) {
        $line_no++;
        ## prune comments
        $line =~ s/\#.*//;
        ## find verifs
        if( $line =~ m|^\s*(([^\s/]+)/([^\s/]+))\s*$|i ){
            $legalVerifs{$1} = $3;
            viprint(LOW, "\tFound '$1' verif.\n" );
            ## validate verif tool is supposed/expected
            if(($2 ne 'icv') && ($2 ne 'calibre')){
                fatal_error("Project legalVerifs file doesn't have expected verification tools, 'icv' or 'calibre'."
                      ."\t See line '$line_no':\n\t $line\n");
                return; ## in case fatal_error_NOEXIT is used
            }
        }
        ## ignore blank lines (or comments only)
        elsif($line =~ m/^\s*$/){
        }
        ## error out for illegal lines
        else{
            fatal_error("Each line of the $projVerifFile: '$line_no' project verif file are "
                  . "expected to be <verifTool>/<verifName> " 
                  . "(or comments/blank), but is:\n$line", 1);
            return; ## in case fatal_error_NOEXIT is used
        }
    } ## end foreach @contents 

    ## ensure release variables set
    unless( keys %legalVerifs ){
       fatal_error( "Failed to find any verifs in project verif file:\n\t '$projVerifFile'", 1);
       return; ## in case fatal_error_NOEXIT is used
    }

    return( %legalVerifs );
}


#------------------------------------------------------------------------------
#  check the p4 path is valid, and that the release area has been sync'd 
#      to the perforce server. 
#------------------------------------------------------------------------------
sub verify_perforce_setup{
    print_function_header();
    my $p4PathBase    = shift;
    my $p4ReleaseRoot = shift;
    my $p4path        = shift;
    my $p4client      = shift;

    if(! -e $p4PathBase){
        eprint("P4 path does not exist:\n\t$p4PathBase");
        eprint("  Please ensure that sym-link is correct and points to your P4 workspace.");
        wprint( "Creating Directory ... make sure it's correct, then re-run:\n\t mkdir -p $p4PathBase" );
        run_system_cmd( "mkdir -p $p4PathBase" );
        fatal_error("  Cannot proceed. Fix P4 path errors first ... exiting!\n", 1);
        return -1; # added this for unit testing reasons
    }
    if(! -e $p4path){
        eprint( "Release path does not exist:\n\t$p4path");
        eprint( "Please ensure your Perforce Client work space contains the following and is sync'd:\n"
               ."\t//depot/$p4ReleaseRoot/... //$p4client/$p4ReleaseRoot/..." );
        wprint( "Creating Directory ... make sure it's correct, then re-run:\n\t mkdir -p $p4path" );
        my ($stdout, $retval) = run_system_cmd( "mkdir -p $p4path" );
        # At this point we don't care if mkdir worked or didn't work; we will fatal out anyways
        fatal_error(" Cannot proceed. Fix release path errors first '$p4path' ... exiting!\n", 1);
        return -1; # added this for unit testing reasons
    }
    print_function_footer();
    return 1; # added for unit testing reasons
}

#-------------------------------------------------------------------------------
#   Checking for the existance of alphaPinCheck files at a P4 directory path
#      return NULL_VAL if P4 path doesn't exist on disk
#      return TRUE if pin check file is on disk
#      return FALSE if can't find pin check file, but path exists
#-------------------------------------------------------------------------------
sub checkPinCheckExist($){
   print_function_header();
   my $filePath = shift;

   #is file path defined?
   unless (defined $filePath){
      dprint(HIGH,"File path was not defined!\n");
      return NULL_VAL;
   }

   unless ($filePath =~ m|//depot/|){
      dprint(HIGH,"File path does not start with //depot/: '$filePath'\n");
      return NULL_VAL;
   }

   my @p4Files = da_p4_files("$filePath");

   unless (@p4Files){
      dprint(HIGH, "P4 Files command came back empty: '$filePath'\n");
      return NULL_VAL;
   }

   foreach my $file (@p4Files){ 
      # restructure regex so that it looks for pincheck/metalstack/alphaPinCheck
      if ($file =~ m|/pincheck/${\NFS}/alphaPinCheck\.\w+$|){  
         return TRUE;
      }
   }
   return FALSE
}

#-------------------------------------------------------------------------------
#   Checks for the existance of ckt specs files at a P4 path and
#      returns NULL_VAL if P4 path is invalid/does not exist
#              or if the ckt specs file does not exist
#      returns the P4 path to the ckt specs file if the file exists
#-------------------------------------------------------------------------------
sub getCktSpecsFile($$){
    print_function_header();
    my $p4_path = shift;
    my $macro = shift;

    my $cktSpecsFile;
    # Ckt specs file may contain multiple macros 
    # (e.g. dwc_lpddr5xphy_txrxac_txrxdq_txrxdqs_spec.docx)
    # and includes a stripped down version of the macro name.

    ##strip beginning of macro name e.g. dwc_lpddr5xphy_
    $macro =~ s/dwc_[a-zA-Z0-9]+_//;
    ##strip any orientation
    $macro =~ s/_ew|_ns//; 
    ##remove any remaining underscores
    $macro =~ s/_//;
    my ($stdout, $stderr) = run_system_cmd("p4 files -e $p4_path/... | grep $macro | grep 'docx' ");

    if (!$stderr){
        #capture path before revision number
        ($cktSpecsFile) = ($stdout =~ /(.*)#/);
        viprint(LOW, "Found ckt specs file for $macro: $cktSpecsFile\n");
        print_function_footer();
        return $cktSpecsFile;
    }
    else{
        viprint(LOW, "Did not find ckt specs file for $macro\n");
        print_function_footer();
        return NULL_VAL;
    }
    
}

#-------------------------------------------------------------------------------
# Returns:
#   an array of values
#
sub readCornersFromLegalVcCorners($$) {
    my $relCornersHeaderBase = shift;
    my $projPathAbs          = shift;

    my @corners_vc;
    my $relCornersFile = firstAvailableFile(
        "$projPathAbs/design/legalVcCorners.csv",
        "$projPathAbs/design_unrestricted/legalVcCorners.csv");

    if ( ! defined $relCornersFile  || $relCornersFile eq NULL_VAL ){
        fatal_error("Failed to find legalVcCorners.csv file using '$projPathAbs'\n");
        return;
    }

    ## open release corners files
    my @contents = read_file( $relCornersFile, 
        "I/O ERROR: Failed to open file '$relCornersFile'");
    iprint("\tReading $relCornersFile release corners file...\n");

    unless (  @contents ) {
        fatal_error("No contents found in '$relCornersFile' !\n");
        return;
    }
    my $nlines = @contents;

    ## grab header and check it is expected
    my $relCornersHeader = shift @contents; 
    chomp $relCornersHeader;

    my $nth_line=0;
    ## if first header is comment or empty, grab next line
    $relCornersHeader =~ s/\#.*//;
    while($relCornersHeader =~ /^\s*$/ ){
        $relCornersHeader = shift @contents ;
        if ( defined $relCornersHeader ) {
            chomp $relCornersHeader ;
            $relCornersHeader =~ s/\#.*//;
        }else{
            last;
        }
        # prevent infinite loop
        $nth_line++;
        if ( $nth_line > $nlines){
            last;
        }
    }

    if ( ! defined $relCornersHeader ){
        fatal_error("release corners header file only has whitespace: '$relCornersFile'\n");
        return; 
    }


    ## now that comment and empty lines are gone, should have the real header
    if($relCornersHeader ne $relCornersHeaderBase){
        fatal_error("release corners header file was not as expected ".
            "(exactly 7 fields with tab delimiting).\n".
            "Found: $relCornersHeader\n  Expected: $relCornersHeaderBase");
        return;
    }

    ## loop through release corners
    foreach( @contents ){
        ## grab and split fields
        my @fields = split '\t';
        ## validate the number of fields of each line
        if($#fields != 6){
            fatal_error("$relCornersFile VC release corners file must have 7 fields".
                    " and has ".($#fields+1).".\n$_");
            return;
        }
        ## store fields
        my $procs_field = lc($fields[1]);
        my $volts_field = $fields[2];
        my $pllvolt     = $fields[3];
        my $iovolt      = $fields[4];
        my $temps_field = $fields[5];
        my $rcxts_field = $fields[6];
        ## check for empty fields
        if($procs_field eq ''){
            fatal_error("$relCornersFile VC release corners file must have non-empty Case field.\n$_"); return;}
        if($volts_field eq ''){
            fatal_error("$relCornersFile VC release corners file must have non-empty Voltage field.\n$_"); return;}
        if($pllvolt eq ''){
            fatal_error("$relCornersFile VC release corners file must have non-empty PLL Voltage field.\n$_"); return;}
        if($iovolt eq ''){
            fatal_error("$relCornersFile VC release corners file must have non-empty IO Voltage field.\n$_"); return;}
        if($temps_field eq ''){
            fatal_error("$relCornersFile VC release corners file must have non-empty Temperature field.\n$_"); return;}
        if($rcxts_field eq ''){
            fatal_error("$relCornersFile VC release corners file must have non-empty Extractions field.\n$_"); return;}
        ## split fields into units and prep special characters
        $procs_field =~ s/[\s\/\,]+/,/g;
        $volts_field =~ s/[\s\/\,]+/,/g;
        $temps_field =~ s/[\s\/\,]+/,/g;
        $rcxts_field =~ s/[\s\/\,]+/,/g;
        my @procs = split ',',$procs_field;
        my @volts = split ',',$volts_field;
        my @temps = split ',',$temps_field;
        my @rcxts = split ',',$rcxts_field;
        $iovolt   =~ s/\s*([\d\.]+)v?\s*/$1/i;
        $pllvolt  =~ s/\s*([\d\.]+)v?\s*/$1/i;
        ## generate corners for each line
        foreach my $proc (@procs){
            foreach my $volt (@volts){
                foreach my $temp (@temps){
        #            foreach $rcxt (@rcxts)
                    ## validate voltages
                    if(!($volt =~ /\d+\.\d+/)){
                        fatal_error("$relCornersFile VC release corners $volt core voltage is expected to be #.# only.\n$_"); return;}
                    if(!($iovolt =~ /\d+\.\d+/)){
                        fatal_error("$relCornersFile VC release corners $iovolt IO voltage is expected to be #.# only.\n$_"); return;}
                    if(!($pllvolt =~ /\d+\.\d+/)){
                        fatal_error("$relCornersFile VC release corners $pllvolt PLL voltage is expected to be #.# only.\n$_"); return;}
                    if(!($temp =~ /\d+/)){
                        fatal_error("$relCornersFile VC release corners $temp temperature is expected to be # only.\n$_"); return;}

                    ## create text strings
                    my $volt_txt = $volt;
                    #$volt_txt =~ s/\.0+$//;
                    $volt_txt    =~ s/(\.\d+)0+$/$1/;
                    $volt_txt    =~ s/\./p/;
                    my $temp_txt = $temp;
                    $temp_txt    =~ s/\-/n/;
                    $temp_txt    =~ s/\.0+$//;
                    $temp_txt    =~ s/(\.\d+)0+$/$1/;
                    $temp_txt    =~ s/\./p/;
        #            $corner = "${proc}${volt_txt}v${temp_txt}c_${rcxt}";
                    my $corner   = "${proc}${volt_txt}v${temp_txt}c";
                    ## store corner info
                    my %corners_vc_params;
                    $corners_vc_params{$corner}->{'volt'}      = $volt;
                    $corners_vc_params{$corner}->{'temp'}      = $temp;
                    $corners_vc_params{$corner}->{'VDD'}       = $volt;
                    $corners_vc_params{$corner}->{'VDDQ'}      = $iovolt;
                    $corners_vc_params{$corner}->{'VDD2H'}     = $iovolt;
                    $corners_vc_params{$corner}->{'VAA'}       = $pllvolt;
                    $corners_vc_params{$corner}->{'VAA_VDD2H'} = $pllvolt; #  see Jira P10020416-36560
                    push( @corners_vc, $corner);
                } ## @temps
            } ## @volts
        } ## @procs
    } ## end  looking at @contents

    ## print timing corners
    logger("\tFound VC timing corners: ".join(', ', @corners_vc)."\n");

    return(@corners_vc);

} # end readCornersFromLegalVcCorners

#------------------------------------------------------------------------
# START SUB for processing CFH
# Sample File: /remote/cad-rep/projects/lpddr54/d850-lpddr54-tsmc5ffp12/rel2.00_cktpcs/design/legalVcCorners.csv
# Corner Type	Case	Core Voltage (V)	PLL Voltage (V)	IO Voltage (V)	Temperature (C)	Extraction Corner
# Standard Product\tFF\t0.825\t1.98\t0.57 (LPDDR5)\t-40 / 0 / 125\tcbest_CCbest, cworst_CCworst, rcbest_CCbest, rcworst_Ccworst
# Standard Product\tFF\t0.935\t1.98\t0.57 (LPDDR5)\t-40 / 0 / 125\tcbest_CCbest, cworst_CCworst, rcbest_CCbest, rcworst_Ccworst
# Standard Product\tSS\t0.765\t1.62\t0.45 (LPDDR5)\t-40 / 0 / 125\tcbest_CCbest, cworst_CCworst, rcbest_CCbest, rcworst_Ccworst
# Standard Product\tSS\t0.675\t1.62\t0.45 (LPDDR5)\t-40 / 0 / 125\tcbest_CCbest, cworst_CCworst, rcbest_CCbest, rcworst_Ccworst
# Standard Product\tTT\t0.85\t1.80\t0.50 (LPDDR5)\t25\ttypical
# Standard Product\tTT\t0.75\t1.80\t0.50 (LPDDR5)\t85\ttypical
# Standard Product\tTT\t0.75\t1.80\t0.50 (LPDDR5)\t25\ttypical
#------------------------------------------------------------------------
sub process_corners_file($$$){
   print_function_header();
   my $relCornersHeaderBase   = shift;
   my $fname_relCornersFile   = shift;
   my $href_corners_vc_params = shift;
   
   ## open release corners files
   my @cfh_contents = read_file( $fname_relCornersFile, 
       "I/O ERROR: Failed to open corners file '$fname_relCornersFile'");
   viprint(LOW, "Reading release corners file:\t'$fname_relCornersFile'\n" );
   ## grab header and check it is expected
   my $relCornersHeader = shift @cfh_contents;
   chomp( $relCornersHeader );
   $relCornersHeader =~ s/\#.*//;
   ## if first header is comment or empty, grab next line
   while( $relCornersHeader =~ /^\s*$/ ){
      $relCornersHeader = shift @cfh_contents;
      chomp( $relCornersHeader );
      $relCornersHeader =~ s/\#.*//;
   }
   
   ## now that comment and empty lines are gone, should have the real header
   if( $relCornersHeader ne $relCornersHeaderBase ){
      fatal_error( "Release corners file header is not as expected ".
              "(exactly 7 fields with tab delimiting).\n".
              "  Found: $relCornersHeader\n".
              "  Expected: $relCornersHeaderBase\n", 1 );
   }

   my @corners_vc;
   ## loop through release corners
   foreach ( @cfh_contents ){
      ## grab and split fields
      my @fields = split '\t';
      ## validate the number of fields of each line
      if( $#fields != 6 ){
         fatal_error( "'$fname_relCornersFile' VC release corners file".
                 " must have 7 fields and has ".($#fields+1).".\n$_\n", 1 );
      }
      #dprint(NONE, "Fields Array: ". scalar(Dumper \@fields). "\n" );
      #----------------------------------------
      # Sample LINE => Standard Product\tTT\t0.85\t1.80\t0.50 (LPDDR5)\t25\ttypical
      # Fields Array = [
      #   'Standard Product', 'TT',
      #    '0.85'           , '1.80',
      #    '0.50 (LPDDR5)'  , '25',
      #    'typical ]
      #----------------------------------------
      my $procs_field = lc($fields[1]);
      my $vdds_field  = $fields[2];
      my $vaa         = $fields[3];
      my $vddq        = $fields[4];
      my $temps_field = $fields[5];
      my $rcxts_field = $fields[6];  # not used outside this subroutine (legacy?)
      ## check for empty fields
      my $common = "'$fname_relCornersFile' VC release corners file must have non-empty";
      if( $procs_field eq '' ){ fatal_error( $common ." Case field.\n$_\n", 1        ); }
      if( $vdds_field  eq '' ){ fatal_error( $common ." Voltage field.\n$_\n", 1     ); }
      if( $vaa         eq '' ){ fatal_error( $common ." PLL Voltage field.\n$_\n", 1 ); }
      if( $vddq        eq '' ){ fatal_error( $common ." IO Voltage field.\n$_\n", 1  ); }
      if( $temps_field eq '' ){ fatal_error( $common ." Temperature field.\n$_\n", 1 ); }
      if( $rcxts_field eq '' ){ fatal_error( $common ." Extractions field.\n$_\n", 1 ); }
      ## split fields into units and prep special characters
      $procs_field =~ s/[\s\/\,]+/,/g;
      $vdds_field  =~ s/[\s\/\,]+/,/g;
      $temps_field =~ s/[\s\/\,]+/,/g;
      $rcxts_field =~ s/[\s\/\,]+/,/g;
      my @procs = split ',',$procs_field;
      my @vdds  = split ',',$vdds_field;
      my @temps = split ',',$temps_field;
      my @rcxts = split ',',$rcxts_field;
      $vddq  =~ s/\s*([\d\.]+)v?\s*\(?.*\)?\s*$/$1/i;
      $vaa   =~ s/\s*([\d\.]+)v?\s*\(?.*\)?\s*$/$1/i;
      #---------------------------------------------
      ## generate corners for each line
      foreach my $proc ( @procs ){
         foreach my $vdd ( @vdds ){
            foreach my $temp ( @temps ){
               ## validate voltages
               my $suffix = "voltage is expected to be #.# only.\n$_ \n";
               if( !($vdd  =~ /^\d+\.\d+$/) ){ fatal_error( $common ." '$vdd' core $suffix",1 ); }
               if( !($vddq =~ /^\d+\.\d+$/) ){ fatal_error( $common ." '$vddq' IO $suffix", 1  ); }
               if( !($vaa  =~ /^\d+\.\d+$/) ){ fatal_error( $common ." '$vaa' PLL $suffix", 1  ); }
               if( !($temp =~ /^\-?\d+$/  ) ){ fatal_error( $common ." '$temp' temperature is expected to be # only.\n$_ \n", 1   ); }
               ## create text strings
               my $vdd_txt = $vdd;
               $vdd_txt  =~ s/(\.\d+)0+$/$1/;
               $vdd_txt  =~ s/\./p/;
               my $temp_txt = $temp;
               $temp_txt =~ s/\-/n/;
               $temp_txt =~ s/\.0+$//;
               $temp_txt =~ s/(\.\d+)0+$/$1/;
               $temp_txt =~ s/\./p/;
               #$corner = "${proc}${vdd_txt}v${temp_txt}c_${rcxt}";
               my $corner = "${proc}${vdd_txt}v${temp_txt}c";
               ## store corner info
               $href_corners_vc_params->{$corner}{'temp'} = $temp;
               $href_corners_vc_params->{$corner}{'VSS'}  = 0;
               $href_corners_vc_params->{$corner}{'VDD'}  = $vdd;
               $href_corners_vc_params->{$corner}{'VDDQ'} = $vddq;
               $href_corners_vc_params->{$corner}{'VAA'}      = $vaa;
               $href_corners_vc_params->{$corner}{'VDD2H'}    = $vddq; # see Jira P10020416-36560
               $href_corners_vc_params->{$corner}{'VAA_VDD2H'}= $vaa;  # see Jira P10020416-36560
               push @corners_vc, $corner;
            } # end 'for temp'
         } # end 'for vdds'
      } # end 'for procs'
   } ## end reading @cfh_contents of file

   dprint(CRAZY, "Done Processing '$fname_relCornersFile' ... passing back array:\n".
                 scalar(Dumper \@corners_vc). "\n" );
   
   return( @corners_vc );
}

sub _tokenify {
    ## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = trim(shift);
    return split(/\s+/, $line);
}

#+
#   readStreamLayerMap()
#
#   Purpose:
#       To read a stream layer map file, parse out the components and
#       place them into the specified hash table.
#
#   Arguments:
#       filename:
#           [input], The file spec of the stream file
#
#       href_layermap:
#           [in/out], A reference to a hash table which will hold the layer
#           data read in from the file.
#
#   Returns:
#       0   Success, no errors in reading in the file.
#       1   Failed to read in the file successfully
#
#   Example:
#
#       my %layermap;
#       my $status = readStreamLayerMap("file.txt", \%layermap);
#-
sub readStreamLayerMap($$){
    my $filename      = shift;
    my $href_layermap = shift;

    my @mapContent;
    my $readErrors = read_file_aref( $filename, \@mapContent);
    if ( $readErrors ){
        wprint("readStreamLayerMap: Failed to read file '$filename'\n");
        return 1;
    }

    foreach my $line ( @mapContent ){
        $line =~ s/\#.*//g;  ## uncomment line
        my @toks = _tokenify($line);
        if (@toks == 0) {next}  ## Ignore blank lines
        if (@toks >= 4) {
            my $layerName   = $toks[0];
            my $purposeName = $toks[1];
            my $gdsLayer    = $toks[2];
            my $gdsPurpose  = $toks[3];
            $href_layermap->{"${gdsLayer}_${gdsPurpose}"} = "$layerName.$purposeName";
        }else{
            wprint("Unrecognized layerMap line \"$line\"; skipping\n");
        }
    }  # END for

    return 0;
}

sub verify_allowed($$$){
    my $prop              = shift;
    my $aref_allow        = shift;
    my $href_legalRelease = shift;
    my $invalid_action    = shift; # "exit" or "noexit"

    my @got     = split /\s/, $href_legalRelease->{"$prop"};
    my $invalid = 0;
    foreach my $value ( @got ){
      if( $value && !grep {/^$value$/} @$aref_allow ){
          eprint( "'$value' is not a valid $prop value.\n");
          $invalid += 1;
      }
    }
    if ( $invalid ) {
        eprint( "\tValid $prop:". join(" ", @$aref_allow) . "\n");
        exit(1) if ( $invalid_action eq "exit" );
    }else{
        viprint(LOW, "\tFound $prop'". join(" ", @got ) . "'\n");
    }
}

sub set_default_if_needed($$$){
    my $prop    = shift;
    my $default = shift;
    my $href_legalRelease = shift;

    return FALSE if ( $default eq NULL_VAL);

    my $was_needed = FALSE;

    unless( exists $href_legalRelease->{"$prop"} ){
       $href_legalRelease->{"$prop"} = $default ;
       wprint("Setting '$prop' to \"$default\".\n");
       $was_needed = TRUE;
   }

   return ($was_needed);
}

#-------------------------------------------------------------------------------
#   Checks if the release version is valid when using the $opt_rel argument
#   (release version override). Valid only when the version provided exists
#   AND the version from legalRelease does not exist. Jira P10020416-39944 
#-------------------------------------------------------------------------------
sub verifyRelVersion($$$$){
    my $p4ReleaseRoot   = shift;
    my $legalRelVersion = shift;
    my $relOverride     = shift;
    my $aref_macros     = shift;

    my $macros_valid = TRUE;

    foreach my $macro (@$aref_macros){
        if (da_p4_is_in_perforce("//depot/$p4ReleaseRoot/ckt/rel/$macro/$legalRelVersion/macro/...") == 1){
            wprint("Release $legalRelVersion exists in depot for macro $macro." . 
                   " Defaulting to rel $legalRelVersion\n");
            return $legalRelVersion; 
        }
        else{
            if (da_p4_is_in_perforce("//depot/$p4ReleaseRoot/ckt/rel/$macro/$relOverride/macro/...") == 0){
                $macros_valid = FALSE;
                wprint("Could not find release $relOverride for macro $macro." .
                       " ALL macros provided must have rel $relOverride in depot" . 
                       " Defaulting to rel $legalRelVersion\n");
                return $legalRelVersion;
            }
        }
    }
    if ($macros_valid eq TRUE){
        gprint("Release override with rel $relOverride valid... using $relOverride.\n");
        return $relOverride;
    }

    return $legalRelVersion;

    
}

#--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%
################################
# A package must return "TRUE" #
################################

1;
