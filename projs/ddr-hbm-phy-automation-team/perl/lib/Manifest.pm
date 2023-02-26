package Manifest;

use strict;
use Cwd;
use Carp;
use File::Spec::Functions qw( catfile );
use Devel::StackTrace;
use File::Basename;
use FindBin;
use Getopt::Std;
use Cwd 'abs_path';
use Term::ANSIColor;
use Capture::Tiny qw/capture/;
use MIME::Lite;
use Data::Dumper;
$Data::Dumper::Sortkeys = sub { [sort keys %{$_[0]}] };
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib/";
use Util::Misc;
use Util::Messaging;

print "-PERL- Loading Package: 'Manifest.pm'\n";

use Exporter;

our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
    get_release_target_file_list
    recursively_interpolate_filespec
    load_default_configs get_all_indexes_in_list
    find_obj_in_range find_col_for_obj cross_check_manifest
    decide_if_cmp_result_is_pass_or_fail
    report_list_compare_stats 
    pre_process_bom_for_optional_views_in_phase
    
);

# Symbols to export by request 
our @EXPORT_OK = qw();

#----------------------------------#
use constant TRUE  => 1;
use constant FALSE => 0;
#----------------------------------#
use constant NONE      => 0;
use constant LOW       => 1;
use constant MEDIUM    => 2;
use constant FUNCTIONS => 3;
use constant HIGH      => 4;
use constant SUPER     => 5;
use constant CRAZY     => 6;
use constant INSANE    => 100;
#----------------------------------#
use constant NULL_VAL   => 'N/A';
#----------------------------------#


#-----------------------------------------------------------------
#  subroutines -  currently only contains subs for 
#     (1) loading configs 
#          - setup_default_configs
#          - check_CFG_file_syntax
#          - load_configs
#     (2) interpolating file SPECs
#-----------------------------------------------------------------



#----------------------------------------------------------------------------
#  Issue warning to user for invalid/unsupported specs.
#----------------------------------------------------------------------------
sub cross_check_manifest($$$$$$$$$$$){
   print_function_header();
   my $cell_name             = shift;
   my $phase_name            = shift;
   my $aref_csv_line         = shift;
   my $idx_cell_name         = shift;
   my $idx_phase_release     = shift;
   my $idx_fileSPEC          = shift;
   my $designator_mandatory  = shift;
   my $designator_optional   = shift;
   my $designator_skip       = shift;
   my $designator_invalid    = shift;
   my $designator_conditional= shift;

   my $x = $designator_mandatory  ;
   my $o = $designator_optional   ;
   my $s = $designator_skip       ;
   my $i = $designator_invalid    ; # originally, this was a '-'
   my $c = $designator_conditional;

   my $status = 'N/A';
   my %phase_vs_cell_combinations = (
      'default' => 'invalid',
      #----  Phase=MANDATORY, enumerate states for Cell
      "$x$x" => 'valid',
      "$x$o" => 'valid',
      "$x$s" => 'valid',
      "$x$i" => 'valid',
      "$x$c" => 'conditional not supported',
      #----  Phase=OPTIONAL, enumerate states for Cell
      "$o$x" => 'valid',
      "$o$o" => 'valid',
      "$o$s" => 'valid',
      "$o$i" => 'valid',
      "$s$c" => 'conditional not supported',
      #----  Phase=SKIP, enumerate states for Cell
      "$s$x" => 'valid',
      "$s$o" => 'valid',
      "$s$s" => 'valid',
      "$s$i" => 'valid',
      "$s$c" => 'conditional not supported',
      #----  Phase=INVALID, enumerate states for Cell
      "$i$x" => 'valid',
      "$i$o" => 'valid',
      "$i$s" => 'valid',
      "$i$i" => 'valid',
      "$i$c" => 'conditional not supported',
      #----  Phase=CONDITIONAL, enumerate states for Cell
      "$c$x" => 'conditional not supported',
      "$c$o" => 'conditional not supported',
      "$c$s" => 'conditional not supported',
      "$c$i" => 'conditional not supported',
      "$c$c" => 'conditional not supported',
   );
   my $designator_phase    = $aref_csv_line->[ $idx_phase_release ];
   my $designator_cell     = $aref_csv_line->[ $idx_cell_name  ];
   my $fileSPEC            = $aref_csv_line->[ $idx_fileSPEC  ];
   my $phase_vs_cell__test = $designator_phase . $designator_cell;

   if( defined $phase_vs_cell_combinations{$phase_vs_cell__test} &&
               $phase_vs_cell_combinations{$phase_vs_cell__test} eq 'valid' ){
      $status = 'valid';
   }else{
      my $err_msg;
      if( defined $phase_vs_cell_combinations{$phase_vs_cell__test} ){
         $err_msg .= $phase_vs_cell_combinations{$phase_vs_cell__test};
         $status = 'invalid';
      }else{
         unless( $designator_phase =~ m/^$x|$o|$s|$i$/ ){ $err_msg.= "Invalid PHASE specifier used: '$designator_phase'" }
         unless( $designator_cell  =~ m/^$x|$o|$s|$i$/ ){ $err_msg.= "Invalid CELL  specifier used: '$designator_cell'" }
         $status = 'invalid';
      } 
      vwprint( NONE, "Removing bom-check: Phase=>'$phase_name'=>'$designator_phase',  Cell=>'$cell_name'=>'$designator_cell',\n\t fileSPEC=>'$fileSPEC' => inspect & fix error.\n" );
      vwprint( LOW, "Invalid specificier combination used: \n\tPhase Designation = '$designator_phase'\n\tCell  Designation = '$designator_cell'\n" );
      $Data::Dumper::Varname = "VAR";
      my $string = pretty_print_aref($aref_csv_line);
      $string =~ s/\$VAR\d+\s*=\s*/BOM Line=/;
      vwprint( LOW, "$err_msg: ".$string."\n" );
   }

   return( $status );
}

#----------------------------------------------------------------------------
#  Process the BOM, convert mandatory fileSPEC to optional when phase
#      indicates an optional inclusion in release definition.
#----------------------------------------------------------------------------
sub pre_process_bom_for_optional_views_in_phase($$$$$$){
   print_function_header();
   my $aref_BOM             = shift;
   my $idx_cell_name        = shift;
   my $idx_phase_release    = shift;
   my $idx_fileSPEC         = shift;
   my $designator_optional  = shift;
   my $designator_mandatory = shift;

   foreach my $aref_csv_line ( @$aref_BOM ){
      if( $aref_csv_line->[ $idx_phase_release ] eq $designator_optional  &&
          $aref_csv_line->[ $idx_cell_name     ] eq $designator_mandatory    ){

         dprint(CRAZY, "Conditions met to convert fileSPEC from mandatory to optional:".pretty_print_aref($aref_csv_line)."\n" );
         $aref_csv_line->[ $idx_cell_name  ] = $designator_optional;
         dprint(CRAZY, "Conversion completed ...:".pretty_print_aref($aref_csv_line)."\n" );
      }
   } # foreach row in Manifest
}

#-----------------------------------------------------------------
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
#-----------------------------------------------------------------
sub decide_if_cmp_result_is_pass_or_fail($$$$){
   my $RefFiles_aref     = shift;
   my $ReleaseFiles_aref = shift;
   my $bomOnly_aref      = shift;
   my $relOnly_aref      = shift;

   my $list_equiv = FALSE;

   if( $#$RefFiles_aref == $#$ReleaseFiles_aref ){
      dprint(HIGH, "Num elements in lists REF=REL ... list-equiv=TRUE\n" );
      if( $#$bomOnly_aref +1 + $#$relOnly_aref +1 ){
         $list_equiv = FALSE;
      }else{
         $list_equiv = TRUE;
         dprint(HIGH, "REF vs REL ONLY lists equiv FALSE result\n" );
      }
   }else{
      dprint(HIGH, "Num elements in lists REF!=REL ... list-equiv=FALSE\n" );
      $list_equiv = FALSE;
   }
   if( $list_equiv ){
      dprint(HIGH, "REF vs REL cmp => TRUE \n" );
   }else{
      dprint(HIGH, "REF vs REL cmp => FALSE \n" );
   }

   return( $list_equiv );
}

#------------------------------------------------------------------
#  get the array index(es) of the range named
#------------------------------------------------------------------
sub get_all_indexes_in_list($$$){
   my $aref      = shift;
   my $range_name= shift;
   my $offset    = shift;

   unless( defined $offset ){ $offset = 0; }
   unless( @$aref ){ 
      wprint( Carp::longmess("Empty array passed unexpectedly!\n") );
   }
   unless( defined $range_name  &&  $range_name =~ m/\S+/ ){ 
      wprint( Carp::longmess("undefined value passed unexpectedly!\n") );
   }
   if( $offset == @{$aref}-1 ){
      wprint( Carp::longmess("offset=$offset, AREF=>\n" . scalar(Dumper $aref) . "\n") );
   }
   my (@indexes) = grep { $aref->[$_] eq $range_name }  ( $offset .. @{$aref}-1 );

   dprint(SUPER, "Searching Line =>". pretty_print_aref( $aref ) . "\n" );
   dprint(SUPER, "range_name=> $range_name\n" );
   dprint(CRAZY, "offset=> $offset \n" );
   dprint(CRAZY, "index=>". pretty_print_aref( \@indexes ) . "\n" );
   return( defined $indexes[0] ? @indexes : "" );
}

#------------------------------------------------------------------
#   search for the named obj in the named range 
#------------------------------------------------------------------
sub find_obj_in_range ($$$$$) {
   my $aref_csv   = shift;
   my $range_name = shift;
   my $obj_name   = shift;
   my $row__derive_range = shift;
   my $row__search_for_obj_in_range = shift;
 
   dprint(CRAZY, "ary => \n". pretty_print_aref_of_arefs( $aref_csv ) ."\n" );
   dprint(HIGH, "(range , obj) => ($range_name , $obj_name) \n" );
   dprint(SUPER, "(row to search for range , row to search for obj) => ($row__derive_range, $row__search_for_obj_in_range) \n" );
   my @col_indexes = get_all_indexes_in_list( 
                                $aref_csv->[$row__derive_range],
                                $range_name, 0
                            );
   dprint(HIGH, "The BOM is defined for collowing column indexes => ". pretty_print_aref( \@col_indexes ) ."\n" );

   # When the BOM that was specified is not found in the xls, the column index array will be empty!
   #     Check for condition and return 'not found'
   if( $col_indexes[0] eq '' ){ 
      return( 'not found' );
   }
   my $first_index = $col_indexes[0];
   my $last_index  = $col_indexes[-1];

   #----------------------------------------------
   my @my_obj_col_indexes = get_all_indexes_in_list( 
                                $aref_csv->[$row__search_for_obj_in_range],
                                $obj_name,
                                $first_index
                            );
   my $found_index = $my_obj_col_indexes[0];
   my $num_indexes = scalar @my_obj_col_indexes;
   viprint(MEDIUM,"Found cell '$obj_name' in following columns: ". join(',', @my_obj_col_indexes) ."\n" );
   if( $num_indexes > 1 ){
      eprint( "Cell '$obj_name' in BOM '$num_indexes' times. Using data from column '$found_index'\n" );
   }

   if( !isa_int($found_index) || $found_index > $last_index ){
      eprint( "Looked for obj '$obj_name' from index '$first_index', found it here: '$found_index' \n" );
      $found_index = 'not found';
      wprint( "\$found_index='$found_index' \n" );
   }else{
      dprint(MEDIUM, "Looked for obj '$obj_name' from index '$first_index', found it here: '$found_index' \n" );
   }
   return( $found_index );
}



#----------------------------------------------------------------------------
# Search for the COLUMN index of the RELEASE that user wants checked.
#      User will define RELEASE name in CFG variable:
#                   $globals{'bom__phase_name'}
#      And, user needs to specify the name of the MANIFEST they want to use:
#                   $globals{'manifest__name'};
#      Code below will search and find the COLUMN index, & record it in var
#                  $globals->{'CSV_index_REL'}
#----------------------------------------------------------------------------
sub find_col_for_obj($$$){
   print_function_header();
   my $aref_MM      = shift;
   my $href_globals = shift;
   my $obj_name     = shift;

      #---------------------------------------------------------------
      # row to search for the range of columns where BOM is specified
      my $row__derive_range = $href_globals->{'row__manifest_names'}-1;
      my $range_name        = $href_globals->{'manifest__name'};
      
      #---------------------------------------------------------------
      # row to search for the release names
      my $row__search_for_obj_in_range = $href_globals->{'row__cell_names'}-1;

      #---------------------------------------------------------------
      my $val =  find_obj_in_range(
                 $aref_MM, $range_name, $obj_name,
                 $row__derive_range, $row__search_for_obj_in_range
              );
      return( $val );
}


#-----------------------------------------------------------------
#  The global CONFIG hash is loaded using some magic here.
#      Pass in a ref to the globals hash, and as long as the 
#      hash named in the CONFIG file matches the name in $main::
#      namespace declared with 'our', then this works
#      Note : the default configs are specific to the Manifest flow
#-----------------------------------------------------------------
sub load_default_configs($$) {
   my $href_globals    = shift;
   my $opt_config_file = shift;

   $href_globals = setup_default_configs( $href_globals );

   check_CFG_file_syntax( $opt_config_file );

   # Eval the CFG file, which loads the configs into %globals
   package CFG;

   use Exporter;
   use strict;
   our @ISA   = qw(Exporter);

   our %globals = %main::globals;
   do $opt_config_file;
   %main::globals=%globals;
}

#----------------------------------------------------------------------------
#  Check that the user's input CONFIG file is legal
#     PERL syntax by testing that it compiles.
#----------------------------------------------------------------------------
sub check_CFG_file_syntax($){
   my $opt_config_file = shift;

   unless( defined $opt_config_file && -e $opt_config_file ){ 
      fatal_error( "Config file doesn't exist: '$opt_config_file'\n" );
   }
   unless( $opt_config_file =~ m/\.cfg$/ ){
      fatal_error( "Config file must be type '.cfg': '$opt_config_file'\n" );
   }
  
   my ( $output, $retval ) = run_system_cmd( "perl -c $opt_config_file" , $main::DEBUG );
   if( $retval ){
      #my @number_of_lines = split(/\n/, $output);
      #print "num lines = @number_of_lines\n";
      my @first_10_lines = (split(/\n/, $output))[0..9];
      fatal_error( "Config file '$opt_config_file' has invalid syntax => \n ".join("\n",@first_10_lines)."\n" );
   }
}

#-----------------------------------------------------------------
sub setup_default_configs() {
   my $globals = shift;

   #------------------------------------------------------------------------------
   # The following parameters are global settings that are required before starting
   #      to configure the details.
   # The following parameters are setting that control parsing of the MM itself.
   #------------------------------------------------------------------------------
   $globals->{'XLSX_sheet_name'}        = "MM";
   $globals->{'fname_BOM_TXT'}          = "MM.filenames.txt";
   $globals->{'fname_BOM_TXT_optional'} = "MM.filenames.optional.txt";
   $globals->{'ViCi_script'}            = "$FindBin::Bin/../scripts/get_vici_info.pl";

   #------------------------------------------------------------------------------
   # The following parameters are setting that control parsing of the MM itself.
   #     The general concept of what's needed is information that defines 
   #     where to look for critical pieces of information.
   #
   #     CSV_index_REL  => defines the column # to use for the release phase
   #          Example : user wants to check a 'Pre-Final' release defined
   #               by column 30
   #     CSV_index_FILES  => the col number where the file specs are defined
   #     CSV_index_VIEWS  => the col number where the view names are defined
   #     CSV_index_COND   => the col number where conditionals are defined
   #------------------------------------------------------------------------------
   $globals->{'CSV_index_FILES'}   = 20;   # col num-  file names
   $globals->{'CSV_index_VIEWS'}   = 19;   # col num-  view names
   $globals->{'CSV_index_COND'}    =  4;   # col num-  "condition" (in row with cell names)
   # The CSV col index is searched for & found automatically when user specifies the release name
   #      User should specify using variable : $globals{'bom__phase_name'}   
   #      Flow will set the variable : #  $globals->{'CSV_index_REL'}

   # enter row # where we expect the "manifest_name" labels 
   $globals->{'manifest__name'}      = 'BOM';  # manifest to use; checks row # "row__manifest_names"
   $globals->{'row__manifest_names'} =   '7';   # row num- manifest names (i.e. BOM, d714, d812, etc)
   $globals->{'row__cell_names'}     =   '8';   # row num-  row where cell names listed
   $globals->{'row__bom_start'}      =  '10';   # row num-  1st row of the bom details

   return( $globals );
}

#-----------------------------------------------------------------
      #################################################################################
      #  Check the cell's config hash for the value(s) that will replace the
      #      variable name found in the $filespec, and is stored in '$interpolate_me'. 
      #
      #      For example, if '$filespec'='netlist/\@{mstack}/dwc_ddrphy_master_top.cdl'
      #      then '$interpolate_me'='mstack'. Therefore, 'mstack' will be replaced
      #      using the hash-value for the corresponding hash-key 'mstack'.
      #
      #      If multiple values are expected, an ARRAY ref is expected.
      #      If single value expected, use a string.
      #      All other types are disallowed for $href->{$key}.
      #
      #      Example:
      #      user provides a config file ... and the cell MASTER has the following '$href':
      #   	    'master'  => {
			#           'dirname'     => "master",
			#           'name'        => "master",
			#           'viciname'    => "master",
			#           'mstack_regex'=> '^PHY Metal Option: (.*)$',
			#           'PVT_regex'   => '^PVT options : (.*)$', 
			#           'vici_url'    => 'http://vici/releasePageConstruct/index/id/25928/page_id/185',
			#           #'overrides'   => { 
      #               #'mstack' => [ '6M_1X_h_1Xa_v_1Ya_h_2Y_vh', '8M_1X_h_1Xa_v_1Ya_h_2Y_vh' ],
      #           #},
      #         },
      #      after ViCi datamining, this will look similar to ... and the key 'mstack' stores
      #      an ARRAY reference
      #           "master" => {
      #                "cell_name"    => "master",
      #                "dirname"      => "master",
      #                "viciname"     => "master",
      #                "mstack_regex" => "^PHY Metal Option: (.*)\$",
      #                "PVT_regex"    => "^PVT options : (.*)\$",
      #                "vici_url"     => "http://vici/releasePageConstruct/index/id/25928/page_id/185",
      #                "CSV_col_idx"  => 27,
      #                "version"      => "1.00a",
      #                "orientation"  => "N/A",
      #                "mstack"       => [ '8M_1X_h_1Xa_v_1Ya_h_4Y_vhvh', '6M_1X_h_1Xa_v_1Ya_h_2Y_vh' ],
      #                "pvt_corners"  => [ "cbest_CCbest", "cworst_CCworst",
      #                                      ...
      #                                    "rcworst_CCworst", "typical"
      #                                  ],
      #                "pvt_values" => [ "ff0p825vn40c", "ff0p825v0c", "ff0p825v125c",
      #                                      ...
      #                                  "ss0p765vn40c", "tt0p75v25c", "tt0p85v25c"
      #                              ],
      #                "pvt_combos" => [
      #                                  "ff0p825vn40c_cworst_CCworst", "ff0p825v0c_cworst_CCworst",
      #                                  "ff0p825v125c_cworst_CCworst",
      #                                      ...
      #                                  "tt0p85v25c_typical"
      #                              ],
      #           },
      #
      #      In this example, where '$filespec'='netlist/\@{mstack}/dwc_ddrphy_master_top.cdl'
      #          this sub will interpolate and expands to the following
      #
      #          'netlist/8M_1X_h_1Xa_v_1Ya_h_2Y_vh/dwc_ddrphy_master_top.cdl',
      #          'netlist/6M_1X_h_1Xa_v_1Ya_h_2Y_vh/dwc_ddrphy_master_top.cdl'
      #      
      #      Recursion is needed for the next example, where two variables are present, but context is different.
      #           '$filespec'='oasis/\@{mstack}/layerMap_${mstack}.txt'
      #
      #      In this example, the sub will interpolate and expands to the following
      #
      #          'oasis/8M_1X_h_1Xa_v_1Ya_h_2Y_vh/layerMap_8M_1X_h_1Xa_v_1Ya_h_2Y_vh.txt'
      #          'oasis/6M_1X_h_1Xa_v_1Ya_h_2Y_vh/layerMap_6M_1X_h_1Xa_v_1Ya_h_2Y_vh.txt'          
      #      and *NOT* to the following!
      #          'oasis/8M_1X_h_1Xa_v_1Ya_h_2Y_vh/layerMap_8M_1X_h_1Xa_v_1Ya_h_2Y_vh.txt'
      #          'oasis/8M_1X_h_1Xa_v_1Ya_h_2Y_vh/layerMap_6M_1X_h_1Xa_v_1Ya_h_2Y_vh.txt'
      #          'oasis/6M_1X_h_1Xa_v_1Ya_h_2Y_vh/layerMap_6M_1X_h_1Xa_v_1Ya_h_2Y_vh.txt'          
      #          'oasis/6M_1X_h_1Xa_v_1Ya_h_2Y_vh/layerMap_8M_1X_h_1Xa_v_1Ya_h_2Y_vh.txt'          
      #               
      #################################################################################
sub recursively_interpolate_filespec($$) {
   print_function_header();

   my $href     = shift;
   my $filespec = shift;

   my @ary__interpolated_files;

   if( $filespec =~ m/\\\@/ ){
      my ($pre, $interpolate_me, $post) = ($filespec =~ m/(.*?)\\\@\{(.*?)\}(.*)/);
      dprint( CRAZY, "FileSpec = '$filespec'\n" );
      dprint( CRAZY, '($pre, $interpolate_me, $post) = ' . "\n\t\t\t$pre\n\t\t\t$interpolate_me\n\t\t\t$post\n" );
   
      my (@files_to_interpolate);
      my $fname;
      # Verify the variable encountered is in the dictionary ... if not, issue warning
      #    and strip preceding '\' to avoid re-processing same variable in recursive loop.
      if( ! defined $href->{$interpolate_me} ){
         $fname = $pre.'@{'.$interpolate_me.'}'.$post;
         wprint("'$interpolate_me' is used in the fileSpec '$fname', but is _NOT_ defined!\n");
         push(@files_to_interpolate, $fname); 
      }else{
         #################################################
         # Check the data types make sense                 
         #  
         my ($fname, @values_to_insert );
         if( ref($href) eq 'HASH' && isa_aref($href->{$interpolate_me}) ){
            dprint( CRAZY, "For cell '$href->{viciname}' : [" . join("," ,@{$href->{$interpolate_me}}) . "]\n" );
            @values_to_insert = @{$href->{$interpolate_me}};
         }elsif( ref($href) eq 'HASH' && ref($href->{$interpolate_me}) eq '' ){
            $values_to_insert['0'] = $href->{$interpolate_me};
         }else{
            eprint( "Expected data type HASH ... ref type  =>'" . ref($href) . "'\n" );
            eprint( "For the key/value pair in HASH,   key =>'" . $interpolate_me . "'\n" );
            eprint( "For the key/value pair in HASH, value =>'" . $href->{$interpolate_me} . "'\n" );
            eprint( "For the key/value pair in HASH, value type =>'" . ref( $href->{$interpolate_me} ) . "'\n" );
            eprint( "Expected HASH value type to be 'ARARY' or ''. Contact $main::AUTHOR_NAME for help.\n");
         }
         if( ! @values_to_insert > 0         ){
            $fname = $pre.'@{'.$interpolate_me.'}'.$post;
            wprint( "'$interpolate_me' not defined in fileSPEC '$fname'!\n" );
           # push( @files_to_interpolate, $fname ); 
            return( @ary__interpolated_files );
         }else{
            #################################################################################
            #  Now that we know we have expected data types, start the
            #      interpolation recursion
            foreach my $element ( @values_to_insert ){
               my $post_tmp = $post; # do not overwrite the variable '$post'
               $post_tmp =~ s/\$\{$interpolate_me\}/$element/g;
               $fname = $pre . $element . $post_tmp;
               #print $fname . "\n";
               dprint( CRAZY, "value '$element'...filespec is now '$fname'\n" );
               push(@files_to_interpolate, $fname); 
            }
         }
 
      } # if variable is not in the dictionary
      dprint( CRAZY, "Files to interpolate ... " . scalar(Dumper \@files_to_interpolate) . "\n" );
      foreach my $file ( @files_to_interpolate ){
         push(@ary__interpolated_files, recursively_interpolate_filespec( $href, $file ) );
      }
   }else{
         push(@ary__interpolated_files, $filespec );
   }

   dprint( CRAZY, "Returning result =>\n" );
   dprint( CRAZY, scalar(Dumper \@ary__interpolated_files) ."\n");
   #print_function_footer();
   return( @ary__interpolated_files );
}


##-----------------------------------------------------------------------------
##  sub 'report_list_compare_stats' : 
##      requires two input lists ... 
##        1. list of files in REFERENCE/BOM <=> aref_bom
##        2. list of files in REL <=> aref_rel
##      ... and three lists derived from the sub 'compare_lists'
##        3. list of files in COMMON 
##        4. list of files in REF/BOM only 
##        5. list of files in REL only 
##      ... and a scalar capturing whether the REF=REL perfectly 
##        6. SCALAR ... TRUE / FALSE  => REF == REL / REF != REL
##      AND, this will return 2 values ... 
##        1. SCALAR = string capturing entire reporting message
##        2. ARY REF = computed values ... used for testing purposes
##------------------------------------------------------------------
sub report_list_compare_stats($$$$$$){
   print_function_header();
   my $aref_ref          = shift;
   my $aref_rel          = shift;
   my $aref_common       = shift;
   my $aref_ref_only     = shift;
   my $aref_rel_only     = shift;
   my $bool__lists_equiv = shift;


   my $mySubName = get_subroutine_name();
   my $bad_args_passed_to_sub = TRUE;
   my $cnt_ref_list;
   my $cnt_rel_list;

   my $cnt_common  ;
   my $cnt_ref_only;
   my $cnt_rel_only;

   unless( isa_aref( $aref_ref      ) &&
           isa_aref( $aref_rel      ) &&
           isa_aref( $aref_common   ) &&
           isa_aref( $aref_ref_only ) &&
           isa_aref( $aref_rel_only )     ){
      eprint( ("Bad argument passed to sub '$mySubName'. Expected ARRAY references.\n") ); 
      $cnt_ref_list = $cnt_rel_list = $cnt_common = $cnt_ref_only = $cnt_rel_only = 0;
      $bad_args_passed_to_sub = TRUE;
   }else{
      $bad_args_passed_to_sub = FALSE;
      dprint(FUNCTIONS, "Good arguments passed to sub '$mySubName'\n" );
      $cnt_ref_list = @{$aref_ref};
      $cnt_rel_list = @{$aref_rel};

      $cnt_common   = @{$aref_common};
      $cnt_ref_only = @{$aref_ref_only};
      $cnt_rel_only = @{$aref_rel_only};
   }

   my $status; my $match; my $rel_in_ref;
   my $total = $cnt_ref_list; 
   if( $total ==0 || $cnt_ref_list ==0 || $cnt_rel_list ==0 ){
      $status = "ERR!"; $match = "ERR!"; $rel_in_ref = "ERR!";
      if( $bad_args_passed_to_sub ){
         $cnt_ref_list = $cnt_rel_list = $cnt_common = $cnt_ref_only = $cnt_rel_only = '-';
      }
   }else{
      if( $bool__lists_equiv ){ 
         $status = "PASS"; 
      }else{
         $status = "FAIL"; 
      }
      $match = ($cnt_common*100/$total);
      $match = sprintf("%3.1f", $match);
      $rel_in_ref = 100*($cnt_rel_list - $cnt_rel_only)/$cnt_rel_list ;
      $rel_in_ref = sprintf("%3.1f", $rel_in_ref);
   }
   my $report_msg;
   $report_msg .= sprintf("-" x100 . "\n");
   $report_msg .= sprintf("%-9s%-11s%-11s%-10s%-10s%-8s%-21s%-18s\n",
                          "Status", "REF Files", "REL Files",
                          "REF Only", "REL Only", "Common", "(%REF found in REL)", "(%REL found in REF)");
   $report_msg .= sprintf("-" x100 . "\n");
   $report_msg .= sprintf("%-9s%-11s%-11s%-10s%-10s%-8s%-21s%-18s\n",
   $status, $cnt_ref_list, $cnt_rel_list,
   $cnt_ref_only, $cnt_rel_only, $cnt_common, $match, $rel_in_ref);

   return( $report_msg, [$status, $cnt_ref_list, $cnt_rel_list,
           $cnt_ref_only, $cnt_rel_only, $cnt_common, $match ]   );
}

##------------------------------------------------------------------
##  read a file and return file array
##  specific impl for special tool;  
##------------------------------------------------------------------
sub get_release_target_file_list($){
   print_function_header();
   my $fname_rel_pkg = shift;

   my @RelPkgFileList;
   my $fname_release;
   my $cmd;

   # decide whether to use 'cat' or 'tar' to obtain the file list.
   # the REL tar pkg is very large (>50GB), so using 'tar' is very slow
   # and slows iterations during testing ... 
   if( !defined $fname_rel_pkg &&  !-e $fname_rel_pkg ){
      fatal_error( "Can't find the release package file ... aborting!\n" );
      exit( -1 );
   }elsif( defined $fname_rel_pkg && -e $fname_rel_pkg ){
      if( $fname_rel_pkg =~ m/\.(tar|tgz)$/ ){
         $fname_release = $fname_rel_pkg;
         $cmd = "tar -tf $fname_release ";
      }elsif( $fname_rel_pkg =~ m/\.txt$/ ){
         $fname_release = $fname_rel_pkg;
         $cmd = "cat $fname_release ";
      }else{
         fatal_error( "Release package file (-rel '$fname_rel_pkg') must use file suffix: '.txt', 'tgz', or '.tar' ... aborting!\n" );
         exit( -1 );
      }
   }
   iprint("Reading RELEASE list from file: '$fname_release'\n");
   unless( -e $fname_release ){
      eprint( "The release pkg file specified doesn't exist: '$fname_release'\n" );
      exit( -1 );
   }
   dprint(LOW, "REL file target = '$fname_release'\n cmd=$cmd\n");

   my ($stdout, $retval) = run_system_cmd( $cmd, $main::DEBUG );
   if( $retval == 0 ){ 
      iprint( "Read successful: '$fname_release'\n" );
   }else{
      iprint( "Read failed : '$fname_release'\n" );
      eprint( "Didn't load release contents properly!");
   }
   @RelPkgFileList = split(/\n/, $stdout);
   # strip out directories

   return( \@RelPkgFileList );
}




################################
# A package must return "TRUE" #
################################

1;
 
__END__
