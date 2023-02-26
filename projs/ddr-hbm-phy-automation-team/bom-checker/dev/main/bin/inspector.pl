#!/depot/perl-5.14.2/bin/perl

#################################################################################
#
#  Name    : inspector.pl
#  Author  : Patrick Juliano, Bhuvan Challa
#  Date    : Jan 2020
#  Purpose : this inspects the SNPS release pkg and compares it to the BOM.
#            Any differences in directory structure and/or filenames is 
#            flagged and reported to user to investigate.
#
#################################################################################
use strict;
use File::Basename;
use Data::Dumper;
use Capture::Tiny qw/capture/;
use Cwd;
use Term::ANSIColor;
use List::MoreUtils qw/uniq/;
use List::Util 'max';
use Getopt::Long;
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::Excel;
use Manifest;
use Excel::Writer::XLSX;

#---- GLOBAL VARs------------------#
#our $STDOUT_LOG  = undef;       # Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR;   # Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $VERSION      = '1.0';
#----------------------------------#

our %globals;

BEGIN { header(); } 
   Main();
END   { write_stdout_log("${PROGRAM_NAME}.log"); footer(); }

sub Main {
   my $cwd = getcwd();

 
   my ( $opt_config_file, $fname_rel_pkg, $fname_ref_list, $fname_refopt_list,
        $opt_fname_logfiles_basename, $opt_nousage ) = process_cmd_line_args();

   unless( $DEBUG || defined $opt_nousage ){ utils__script_usage_statistics($PROGRAM_NAME, $VERSION); }
   #----------------------------------------------------------------------------
   #  Load the defaults for the CFG so user doesn't need to do anything 
   #     for most projects
   #----------------------------------------------------------------------------
   load_default_configs( \%globals, $opt_config_file );

   #----------------------------------------------------------------------------
   #  User can define the BOM filenames (both std and optional) in the
   #     user CFG file.  If user has specified them in the CFG, use
   #     those names, otherwise use the default names.
   #----------------------------------------------------------------------------
   unless( defined $fname_ref_list    ){ $fname_ref_list    = $globals{fname_BOM_TXT}; }
   unless( defined $fname_refopt_list ){ $fname_refopt_list = $globals{fname_BOM_TXT_optional}; }
   check_cmd_line_args( $fname_rel_pkg, $fname_ref_list, $fname_refopt_list, $opt_fname_logfiles_basename );
   
   dprint(SUPER, "Current working directory = '$cwd'\n");
   dprint( MEDIUM, "CFG ... globals--> \n" . pretty_print_href( \%globals) ."\n");
   print STDERR "-I- Using configs for Release '" . $globals{'release_to_check'} . "'\n"; 
   my ($cfg, $href_misc) = $globals{$globals{'release_to_check'}}->();

   #------------------------------------------------------------------------
   # Sometimes, versions of filenames differ, or user just wants to inspect
   #     a fraction of the release (e.g. inspect a few components, not all)
   #     Grab the waivers and sterlization regexes.
   #------------------------------------------------------------------------
   my $aref_waiver_regexes__REF    = $href_misc->{inspector__REF_waivers};
   my $aref_waiver_regexes__REL    = $href_misc->{inspector__REL_waivers};
   my $href_sterilize_regexes__REF = $href_misc->{inspector__REF_find_n_replace};
   my $href_sterilize_regexes__REL = $href_misc->{inspector__REL_find_n_replace};
   dprint(SUPER, pretty_print_aref($aref_waiver_regexes__REF) ."\n");
   dprint(SUPER, pretty_print_aref($aref_waiver_regexes__REL) ."\n");

   #-------------------------------------------------------------------------
   #  Load the REFERENCE (REF) and RELEASE (REL) file lists.
   #-------------------------------------------------------------------------
   my $RefFiles_aref     = get_bom_file_list( 'STANDARD BOM', $fname_ref_list    );
   my $RefOptFiles_aref  = get_bom_file_list( 'OPTIONAL BOM', $fname_refopt_list );
   my $ReleaseFiles_aref = get_release_target_file_list( $fname_rel_pkg );


   #-------------------------------------------------------------------------
   #  Remove elements that are directories because they terminate with a '/'
   #-------------------------------------------------------------------------
   (@$ReleaseFiles_aref) = grep {$_ !~ /\/$/} @$ReleaseFiles_aref;
   (@$RefFiles_aref)     = grep {$_ !~ /\/$/} @$RefFiles_aref;

   #-------------------------------------------------------------------------
   #  Remove redundant names in the file lists.
   #-------------------------------------------------------------------------
   @{$RefFiles_aref}     = unique_scalars( $RefFiles_aref     );
   @{$RefOptFiles_aref}  = unique_scalars( $RefOptFiles_aref  );
   @{$ReleaseFiles_aref} = unique_scalars( $ReleaseFiles_aref );

    #-------------------------------------------------------------------------
    #  Feature: 'Sterilize'/'Find-n-Replace'
    #-------------------------------------------------------------------------
    # original motivation : while comparing 2 releases with different version
    #    numbers, then directory path with version #'s differing causes 100%
    #    mismatch. Use a HREF of regexes to swap/replace strings as needed to
    #    sterlize the names and allow for a smart comparison.
    #    
    #    Recently, this has been found to be useful for other purposes as 
    #    well. This step should be performed before the waivers are applied.
    #-------------------------------------------------------------------------
     $RefFiles_aref     = sterilize_REGEX_in_filenames( 'REFerence',          $RefFiles_aref,     $href_sterilize_regexes__REF );
     $RefOptFiles_aref  = sterilize_REGEX_in_filenames( 'Optional REFerence', $RefOptFiles_aref,  $href_sterilize_regexes__REF );
     $ReleaseFiles_aref = sterilize_REGEX_in_filenames( 'RELease',            $ReleaseFiles_aref, $href_sterilize_regexes__REL );
     
   #---------------------------------------------------------------------------
   # Process the OPTIONAL fileSPECs. If a fileSPEC is optional, then we should
   #    search the REL for it, and if found, add to COMMON list
   #    (i.e. match successful). If NOT found in REL, add as a waiver
   #    to REF list so it gets removed from the REF
   #    since it's optional and not required.  Since some
   #    of the optional files were in the REL, treat them as
   #    though they were in std BOM so the accounting works.
   #---------------------------------------------------------------------------
   my( $common_optional_files_aref, $aref_optional_files_in_bom_only, undef, undef )=
               compare_lists( $RefOptFiles_aref , $ReleaseFiles_aref );
    
   #-------------------------------------------------------------------------
   # For those files that were designated 'o' (optional) in the MM/BOM and
   # that were found in the REL, we want to add those to the REF.  Why? 
   # Because we want them to be added to the COMMON list. In order to get the
   # accounting / analysis right, we'll add them to the BOM since we know
   # they won't cause mismatches.
   #-------------------------------------------------------------------------
   my $my_size_before = $#$RefFiles_aref + 1;
   $RefFiles_aref = append_arrays( @$RefFiles_aref , $common_optional_files_aref);
   my $my_size_after = $#$RefFiles_aref + 1;
   wprint( "Std BOM after adding optional files found in REL (New/Orig) => '$my_size_after'/'$my_size_before'\n");

   #-------------------------------------------------------------------------
   # For those files that were designated 'o' (optional) in the MM/BOM and
   # that were NOT found in the REL, we're going to ADD to the BOM also. But,
   # this is unexpected because it will cause the accounting / analysis to 
   # be wrong by treating optional files as mandatory and show them as 
   # missing. I made decision to avoid the analysis problem by adding them
   # to the waiver list as well, so they don't get added to the 'BOM_only'
   # total, or any other totals.
   #-------------------------------------------------------------------------
   my $my_size_before = $#$RefFiles_aref + 1;
   $RefFiles_aref = append_arrays( @$RefFiles_aref , $aref_optional_files_in_bom_only );
   my $my_size_after = $#$RefFiles_aref + 1;
   wprint( "Std BOM after adding optional files NOT found in REL (New/Orig) => '$my_size_after'/'$my_size_before'\n");

      #-------------------------------------------------------------------------
      # Next, add waivers for the REF list using the list of
      # Optional Files Not found in the REL
      #-------------------------------------------------------------------------
      $aref_waiver_regexes__REF = append_arrays( @$aref_waiver_regexes__REF,
                                                 $aref_optional_files_in_bom_only );

   #-------------------------------------------------------------------------
   #  Filter lists (REF & REL) using the list of waivers. Store the filenames
   #     that were removed from each of the original lists.
   #-------------------------------------------------------------------------
   my ($aref_waiver_fname_pairs__in_REF, $aref_waiver_fname_pairs__in_REL);
   my ($aref_waiver_optional_fnames__in_REF);
   ($aref_waiver_optional_fnames__in_REF, $RefFiles_aref )=
                  apply_waivers_to_list( 'reference', $RefFiles_aref,     $aref_optional_files_in_bom_only );
   ($aref_waiver_fname_pairs__in_REF, $RefFiles_aref     )=
                  apply_waivers_to_list( 'reference', $RefFiles_aref,     $aref_waiver_regexes__REF );
   ($aref_waiver_fname_pairs__in_REL, $ReleaseFiles_aref )=
                  apply_waivers_to_list( 'release',   $ReleaseFiles_aref, $aref_waiver_regexes__REL );

   #-------------------------------------------------------------------------
   # In the list of waivered files in the REF, find the optional files and alter 
   # the msg reported in the waiver file so user is clear that soruce of the
   # waiver is from it being designated 'o' (i.e. optional).
   #-------------------------------------------------------------------------
   map { $_ =~ s/^(\S+) <=> \1$/optional filespec <=> \1 / } @$aref_waiver_optional_fnames__in_REF;
   ($aref_waiver_fname_pairs__in_REF) = append_arrays( @$aref_waiver_fname_pairs__in_REF, $aref_waiver_optional_fnames__in_REF );

  #-------------------------------------------------------------------------
  #  START: process the feature provided by the assertion '${_ALL_}'
  #-------------------------------------------------------------------------
     # The BOM calls for copying any contents of a file directory, but doesn't
     #    specify any more than 'all' the contents. In order to use this
     #    feature, the filspec in the MANIFEST should include "/${_ALL_}".
     #    This filespec gets transformed to a regex where everything preceding
     #    ${_ALL_} is the regex, and this filespec is removed from the MANIFEST.
     #    Later, the regex is applied as a waiver against the RELEASE. 
     my $aref_regexes_based_on_ALL_keyword =
                process_special_case_ALL__in_REF( 'reference', $RefFiles_aref );
     
     # Now that we've created waiver regex for the '${_ALL_}' cases, we
     #    can go ahead and remove file SPECs from REFERENCE list that use
     #    keyword ${_ALL_} to avoid invalid checks between REF & REL; must
     #    be completed before final comparison is performed.
     my $my_size_before = $#$RefFiles_aref + 1;
     @$RefFiles_aref = grep { $_ !~ /\$\{_ALL_\}$/ } @$RefFiles_aref;
     my $my_size_after = $#$RefFiles_aref + 1;
     my $diff = $my_size_before - $my_size_after;
     wprint( "Removed '$diff' fileSPECs with '\${_ALL_}' from 'reference'. List Size (New/Orig) => '$my_size_after'/'$my_size_before'\n" );

   # So, now that REF had files removed, remove the appropriate files from the REL as well.
   # This must occur after the comparison because MM may have fileSPECs that should be
   # cross-checked between REF<=>REL *BEFORE* ${_ALL_} because ${_ALL_} could end
   # up removing those that collide.
  #-------------------------------------------------------------------------
  #  Nearly done ... addressing the ${_ALL_} Feature
  #-------------------------------------------------------------------------

     # Perform comparative analysis between the REFERENCE & RELEASE. Recall,
     # the REFERENCE includes the optional files that we know match in the
     # RELEASE 
     my( $common_aref, $bomOnly_aref, $relOnly_aref, $list_equiv )=
                        compare_lists( $RefFiles_aref , $ReleaseFiles_aref );

     #-------------------------------------------------------------------------
     # Now that the list of files that were ONLY in the RELEASE is known, we
     #    need to apply waivers using regexes derived from the ${_ALL_} keyword.
     #    This provides the list of files filtered out by the ${_ALL_} keyword.
     #-------------------------------------------------------------------------
     my $aref_ReleaseOnlyFiles_removed_by_ALL_keyword;

     #-------------------------------------------------------------------------
     # Supress STDOUT to avoid invalid messages from the function call to
     #   'apply_waivers_to_list'
     #-------------------------------------------------------------------------
     {
         $|=1; local *STDOUT;
         open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!";

        ($aref_ReleaseOnlyFiles_removed_by_ALL_keyword, $relOnly_aref)=
                    apply_waivers_to_list( 'release-only since BOM calls for a directory slurp!',
                             $relOnly_aref, $aref_regexes_based_on_ALL_keyword );
         close STDOUT;
          $|=0;
     }
     #-------------------------------------------------------------------------
     my $cnt = scalar(@$aref_ReleaseOnlyFiles_removed_by_ALL_keyword);

     #-------------------------------------------------------------------------
     #  Apply waivers returns full waiver format :  $waiver <=> $target
     #  Since these come in pairs, just retain the actual file name 
     #  found in the REL ($target) 
     #-------------------------------------------------------------------------
     my @RELonly_files_found_by_ALL_keyword = @$aref_ReleaseOnlyFiles_removed_by_ALL_keyword;
     map { $_ =~ s/^(\S+) <=> (\1\S+)$/\2/ } @RELonly_files_found_by_ALL_keyword;
     dprint( SUPER, "RELonly files removed by _ALL_:\n\t\t\t" . 
              pretty_print_aref_of_arefs( \@RELonly_files_found_by_ALL_keyword )
              . "\n");

     #-------------------------------------------------------------------------
     # For the REL files, keep only those that were not filtered-out by the ${_ALL_}
     #   Warning : do this only after original comparison is made.
     #   We want to retain the original waiver <=> target messages, so 
     #   discard the new values.
     #-------------------------------------------------------------------------
    (undef, $ReleaseFiles_aref) = apply_waivers_to_list( 'release using ${_ALL_} keyword!', 
                                           $ReleaseFiles_aref,
                                           \@RELonly_files_found_by_ALL_keyword ,
                                         );

   # Treat ${_ALL_} same as how waivers are treated. And, append
   #    the list of add'l files filtered out by the ${_ALL_} keyword
   map { $_ =~ s/^(\S+) <=> (\1\S+)$/\1\$\{_ALL_\} <=> \2/ } @$aref_ReleaseOnlyFiles_removed_by_ALL_keyword;
   push( @$aref_waiver_fname_pairs__in_REL, @$aref_ReleaseOnlyFiles_removed_by_ALL_keyword ); 

   #---------------------------------------------------------------------------
   # OK, so now we have each of the lists (i.e. REL + REF) in their final form
   #    so compare them. Generate report of the comparative analysis
   #---------------------------------------------------------------------------
   #  Now that ALL the list processing has been completed, recompute the status
   #  boolean "list-equiv", which is used to decide PASS/FAIL of the comparison
   #    For the purposes of reporting to user final 'PASS' vs 'FAIL' status,
   #      PASS can only occur if the following are true:
   #          (1)  REF and REL have same # of elements (after all waivers applied etc)
   #          (2)  no mismataches => that's true when there's 
   #          zero files in the REF-only and zero files in the REL-only
   #---------------------------------------------------------------------------
   #
   $list_equiv = decide_if_cmp_result_is_pass_or_fail( $RefFiles_aref , $ReleaseFiles_aref ,
                                                       $bomOnly_aref  , $relOnly_aref      );
   my( $msg, $skip ) = report_list_compare_stats( $RefFiles_aref, $ReleaseFiles_aref,  
                                     $common_aref, $bomOnly_aref, $relOnly_aref, $list_equiv );
   #Report the analysis result 
   print "$msg\n";
   logger($msg);

   my $fnamePrefix    = $globals{'release_to_check'};
   my $fnameSTDOUTLOG = "$fnamePrefix--stdout.log";
   if( defined $opt_fname_logfiles_basename ){
      $fnamePrefix = $opt_fname_logfiles_basename;
      $fnameSTDOUTLOG = "$fnamePrefix--stdout.log";
   }
   
   my $reportName     = "$fnamePrefix--report.xlsx";
   my $theReport      = Excel::Writer::XLSX->new("$reportName");
   my $stdoutSheet    = $theReport->add_worksheet("stdout");
   my $reference_final= $theReport->add_worksheet("reference_final");
   my $release_final  = $theReport->add_worksheet("release_final");
   my $refOnly        = $theReport->add_worksheet("ref_only");
   my $relOnly        = $theReport->add_worksheet("rel_only");
   my $common         = $theReport->add_worksheet("common");
   my $waiveRef       = $theReport->add_worksheet("waived_ref");
   my $waiveRel       = $theReport->add_worksheet("waived_rel");
   my $smartDiff      = $theReport->add_worksheet("smart_diff");

   my $stdoutComment    = "Log of the tool's STDOUT messages";
   my $refFinalComment  = "Reference files after applying (1) waivers (2) find-n-replace pairs";
   my $relFinalComment  = "Release   files after applying (1) waivers (2) find-n-replace pairs";
   my $relOnlyComment   = "Release only files";
   my $refOnlyComment   = "Reference only files";
   my $commonComment    = "Common files";
   my $waiveRelComment  = "Waived release files";
   my $waiveRefComment  = "Waived reference files";
   my $smartDiffComment = "Smart difference command";

   my $boldFormat = $theReport->add_format(
       align  => 'center',
       valign => 'center',
   );
   $boldFormat->set_bold();  

   # $PROGRAM_NAME : Strip off the directory path prefix if it's there...
   # ...so log files are written where user invoked script -> $PWD
   write_file( [sort @$RefFiles_aref     ], "$fnamePrefix--reference.log" );
   write_file( [sort @$ReleaseFiles_aref ], "$fnamePrefix--release.log"   );
   write_file( [sort @$bomOnly_aref      ], "$fnamePrefix--ref_only.log"  );
   write_file( [sort @$relOnly_aref      ], "$fnamePrefix--rel_only.log"  );
   write_file( [sort @$common_aref       ], "$fnamePrefix--common.log"    );

   # Writing to excel report
   write2Excel( [], $stdoutSheet, $stdoutComment, $boldFormat);
   write2Excel( [sort @$RefFiles_aref     ], $reference_final, $refFinalComment, $boldFormat ); 
   write2Excel( [sort @$ReleaseFiles_aref ], $release_final  , $relFinalComment, $boldFormat ); 
   write2Excel( [sort @$bomOnly_aref      ], $refOnly        , $refOnlyComment , $boldFormat ); 
   write2Excel( [sort @$relOnly_aref      ], $relOnly        , $relOnlyComment , $boldFormat ); 
   write2Excel( [sort @$common_aref       ], $common         , $commonComment  , $boldFormat ); 

   # Write logs to record the pairs of (waiver <=> filename) applied to the REL & REF
   write_file( [sort @$aref_waiver_fname_pairs__in_REF ] , "$fnamePrefix--waivered_files.ref.log" );
   write_file( [sort @$aref_waiver_fname_pairs__in_REL ] , "$fnamePrefix--waivered_files.rel.log" );

   # Writing to excel report
   write2Excel( [sort @$aref_waiver_fname_pairs__in_REF ], $waiveRef, $waiveRefComment, $boldFormat );
   write2Excel( [sort @$aref_waiver_fname_pairs__in_REL ], $waiveRel, $waiveRelComment, $boldFormat ); 

   ## smart diff command
   my $smartCmd = "compare_sort.pl -rel $fnamePrefix--release.log -ref $fnamePrefix--reference.log  [-macro <macroName>] [-view <viewName>]";
   $smartDiff->write(0,0,$smartDiffComment,$boldFormat);
   $smartDiff->write(1,0,$smartCmd);
   print "\n----------\nSmart diff:\n";
   print "$smartCmd\n----------\n\n";
   
   logger( "\n----------\nSmart diff:\n" );
   logger( "$smartCmd\n----------\n\n" );

   iprint("Excel report created: $reportName\n" );
   iprint("Log file written: '$fnameSTDOUTLOG'\n" );

   my $FP;
   open($FP,">$fnameSTDOUTLOG") || warn "Can't open $fnameSTDOUTLOG: $!";
      print $FP $STDOUT_LOG;
   close($FP);
   
   ## Writing stdout to excel report
   write2Excel( [split(/\n/,$STDOUT_LOG)], $stdoutSheet, $stdoutComment, $boldFormat);

   exit( 0 );
}

###############################################################################
##   End MAIN
###############################################################################

#------------------------------------------------------------------------------
# Find all the File SPECs that employ the ${_ALL_} keyword
#------------------------------------------------------------------------------
sub process_special_case_ALL__in_REF($$){
   print_function_header();
   my $list_name     = shift;
   my $RefFiles_aref = shift;

   my $aref_filespecs_with_ALL_keyword = [];
   foreach my $elem ( @$RefFiles_aref ){
      my $filespec = $elem; # $elem is an alias for the elements in the list
                            # but I don't want to that behavior.
      if( $filespec =~ m/\$\{_ALL_\}/ && $filespec !~ m/\/\$\{_ALL_\}$/ ){
         # OK => rtl/lp4/${_ALL_}
         # not OK => rtl/lp4${_ALL_}
         eprint( "Use of the special keyword \${_ALL_} incorrect! Can only be terminate a File SPEC (e.g. rtl/\${_ALL_}.\n" );
      }elsif(  $filespec =~ m/\/\$\{_ALL_\}$/ ){
         # remove the ${_ALL_} from the filespec
         # For the ${_ALL_} assertion to work, must ensure that you capture the last '/' in the path
         $filespec =~ s/\$\{_ALL_\}$//;
         push( @{$aref_filespecs_with_ALL_keyword}, $filespec);
      }else{
         dprint( CRAZY , "skipping $filespec \n" );
      }
   }
   return( $aref_filespecs_with_ALL_keyword );
}

#------------------------------------------------------------------------------
## sub designed to use a hash-ref of pairs<=>(search pattern/replace string) to
##    find content in the filenames and replace it, allowing for succesful
##    matching of relevant filename content.
##    Examples :
##           REFRENCE contains synopsys/dwc_ddr54_phy_tsmc6/0.90a/ibis
##           RELEASE  contains synopsys/dwc_ddr54_phy_tsmc6/1.00a/ibis
##       then use these search/replace pattterns and pass into this sub
##           '0.90a => VER'
##           '1.00a => VER'
##       which alters names to the following
##           REFRENCE => synopsys/dwc_ddr54_phy_tsmc6/VER/ibis
##           RELEASE  => synopsys/dwc_ddr54_phy_tsmc6/VER/ibis
##       so now comparison will report a match
#------------------------------------------------------------------------------
sub sterilize_REGEX_in_filenames ($$$){
  print_function_header();
  my $list_name            = shift;
  my $aref_Files           = shift;
  my $href_waiver_regexes  = shift;

  my $aref_filtered_list = [];
  my $aref_list_of_elems_filtered_by_regex = [];
  my $size_filtered=0;

  foreach my $target ( @{$aref_Files} ){
    my $not_found = TRUE;
    foreach my $search ( sort keys %$href_waiver_regexes ){
      my $replace = $href_waiver_regexes->{$search};
      if( $target =~ m/$search/ ){
        $target = regex_with_interpolation( $target, $search, $replace );
        push( @{$aref_list_of_elems_filtered_by_regex},  "$search/$replace <=> $target" );
        dprint(SUPER, "Filtered LIST (waiver regex <=> target : '$search/$replace' <=> '$target'\n" );
      }
    }
    push( @{$aref_filtered_list}, $target );
  }
  my $size_orig = $#$aref_Files + 1;
  wprint( "Sterilized '$size_filtered'/'$size_orig' elements from the list...'$list_name' \n" );
  return( $aref_filtered_list );
}

#------------------------------------------------------------------------------
#   my $aref_waiver_fname_pairs__in_REF =
#           apply_waivers_to_list( 'reference',   $RefFiles_aref, $aref_waiver_regexes__REF );
#   my $aref_waiver_fname_pairs__in_REL = 
#           apply_waivers_to_list( 'release', $ReleaseFiles_aref, $aref_waiver_regexes__REL );
#   my $aref_ReleaseFiles_removed_by_ALL_keyword =
#           apply_waivers_to_list( 'only_release', $relOnly_aref, $aref_regexes_based_on_ALL_keyword );
#
#   Apply waivers to the list.  Return the list of files waived and the new
#       list with waived files removed.
#------------------------------------------------------------------------------
sub apply_waivers_to_list ($$$){
  print_function_header();
  my $list_name            = shift;
  my $aref_Files           = shift;
  my $aref_waiver_regexes  = shift;

  my $aref_list_after_applying_waivers = [];
  my $aref_list_of_elems_filtered_by_regex = [];

   #dprint( $DEBUG, "Tracking ALL waiver list:\n" .
                   #scalar( Dumper($aref_waiver_regexes) ) );
  foreach my $target ( @{$aref_Files} ){
    my $not_found = TRUE;
    foreach my $waiver_regex ( @{$aref_waiver_regexes} ){
       # quote (disable) pattern metacharacters 
       # Removed the \Q\E to allow the regex special characters to be interpreted as intended
       if( $target =~ m/$waiver_regex/ ){
          push( @{$aref_list_of_elems_filtered_by_regex},  "$waiver_regex <=> $target" );
          dprint(SUPER, "Filtered '$list_name' LIST (waiver regex <=> target : '$waiver_regex' <=> '$target'\n" );
          $not_found = FALSE;
          last;
       }
       unless( $waiver_regex =~ m/waive/ ){
          dprint(SUPER, "'$list_name' LIST (waiver regex <!=> target :\n\t'$waiver_regex' <=>\n\t'$target'\n" );
          prompt_before_continue(SUPER);
       }
    }
    push( @{$aref_list_after_applying_waivers}, $target )  if( $not_found == TRUE );
  }
  
  # Compute totals for the lists.
  my $num_elem_removed = $#$aref_list_of_elems_filtered_by_regex + 1;
  my $size_orig = $#$aref_Files + 1;
  
  my $size_filtered = $#$aref_list_after_applying_waivers + 1;
  wprint( "Waived '$num_elem_removed' targets from the list ... '$list_name'. List Size (New/Orig) => '$size_filtered'/'$size_orig'\n" );
  return( $aref_list_of_elems_filtered_by_regex , $aref_list_after_applying_waivers );
}

#------------------------------------------------------------------------------
# Must return an array, even if empty;
#------------------------------------------------------------------------------
sub get_bom_file_list ($) {
  print_function_header();
  my $type = shift;
  my $fname = shift;

  iprint("Reading '$type' list from file: '$fname'\n" );
  my @reference = read_file( $fname );
  iprint("Total # lines: " . scalar(@reference) ."\n" );
  # strip out directories
  dprint(LOW, "Removing filespecs where only directory names specified w/out content: \n" . join("\n", grep {$_ =~ /\/$/} @reference) . "\n" );
  @reference = grep {$_ !~ /\/$/} @reference;
  # Make sure that \@reference is an ARRAY reference. 
  unless( @reference ){
     @reference = ();
  }
  return( \@reference );
}

#------------------------------------------------------------------------------
sub process_cmd_line_args(){
   my ( $opt_config, $opt_verbosity, $opt_debug, $opt_help, $fname_rel_pkg,
        $fname_reference_list, $fname_reference_optional_files_list,
        $opt_fname_logfiles_basename, $opt_nousage );

   GetOptions( 
     "cfg=s"       => \$opt_config,  # config files for check
     "rel=s"       => \$fname_rel_pkg,
     "ref=s"       => \$fname_reference_list,    
     "opt=s"       => \$fname_reference_optional_files_list,    
     "log=s"       => \$opt_fname_logfiles_basename,
     "debug=s"     => \$opt_debug,
     "help"        => \$opt_help, # Prints help
     "verbosity=s" => \$opt_verbosity,
     "nousage"     => \$opt_nousage,
   );

   # VERBOSITY will be used to control the intensity level of 
   #     messages reported to the user while running.
   if( defined $opt_verbosity ){
      if( $opt_verbosity =~ m/^\d+$/ ){  
         $main::VERBOSITY = $opt_verbosity;
      }else{
         eprint("Ignoring option '-v': arg must be an integer\n");
      }
   }

   # decide whether to alter DEBUG variable
   # '--debug' indicates DEBUG value ... set based on user input
   # Patrick : modified in order to specify a value >0 but <1
   if( defined $opt_debug ){
      if( $opt_debug =~ m/^\d+\.*\d*$/ ){  
         $main::DEBUG = $opt_debug;
      }else{
         eprint("Ignoring option '-d': arg must be an integer\n");
      }
   }

   if( defined $opt_help ){
      iprint("User needs to provide the release package filename (-rel) and the reference expected (-ref) \n" );
      iprint("Typical Command Line :   ${PROGRAM_NAME} -ref dXXX-bom-v1.14.txt -rel dwc_lpddr54_tsmc6ff18_2.00a.tgz \n" );
   }
   return( $opt_config, $fname_rel_pkg, $fname_reference_list, $fname_reference_optional_files_list, $opt_fname_logfiles_basename, $opt_nousage );
}

#------------------------------------------------------------------------------
sub check_cmd_line_args($$$){
   print_function_header();
   my $fname_rel_pkg = shift;
   my $fname_ref_list = shift;
   my $fname_refopt_list = shift;
   my $opt_fname_logfiles_basename = shift;

   # Set an error flag ...
   my $error = FALSE;
   unless( defined $fname_rel_pkg ){
      eprint( "Missing option '-rel' ... must provide valid relase pkg to be used as the reference for inspecting the release!\n" );
      $error = TRUE;
   }
   unless( defined $fname_ref_list ){
      eprint( "Missing option '-ref' ... must provide valid file to be used as the reference for inspecting the release! (Note: this filename can be defined in CFG as well)\n" );
      $error = TRUE;
   }
   unless( defined $fname_refopt_list ){
      eprint( "Missing option '-opt' ... must provide valid file to be used as the reference for inspecting the release! (Note: this filename can be defined in CFG as well)\n" );
      $error = TRUE;
   }
   if( $error ){
     fatal_error( "Found errors that must be fixed ... aborting!\n" );
   }
   return( $fname_rel_pkg, $fname_ref_list, $opt_fname_logfiles_basename );
}


#------------------------------------------------------------------------------



