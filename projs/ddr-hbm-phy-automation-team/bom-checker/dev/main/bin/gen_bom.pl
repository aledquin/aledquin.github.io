#!/depot/perl-5.14.2/bin/perl -w

#################################################################################
#
#  Name    : MainManifest-2-bomconfig.pl
#  Author  : Patrick Juliano
#  Date    : Feb 2019
#  Purpose : this takes the BOM as input (CSV file format) and spits out the
#            the BOM file list.
#
#################################################################################
 
use strict;
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Getopt::Long;
use Data::Dumper;
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::Excel;
use Manifest;
use ViCi;

$Data::Dumper::Sortkeys = sub { [sort keys %{$_[0]}] };
#---- GLOBAL VARs------------------#
our $DIRNAME = dirname(abs_path $0);
our $PROGRAM_NAME = $RealScript;
our $AUTHOR_NAME  = 'Patrick Juliano'; 
our $VERSION      = '1.0';
#our $STDOUT_LOG=undef;   # Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Log msg to var => ON
our %globals; 
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
#----------------------------------#
use constant BOM_STANDARD => 'bom';
use constant BOM_OPTIONAL => 'bom_optional';
#----------------------------------#
use constant DESIGNATOR_MANDATORY => 'x';
use constant DESIGNATOR_OPTIONAL  => 'o';
use constant DESIGNATOR_INVALID   => '-';
use constant DESIGNATOR_SKIP      => 's';
use constant DESIGNATOR_CONDITIONAL=>'c';
#----------------------------------#
use constant NULL_VAL   => 'N/A';
#----------------------------------#
BEGIN { our $AUTHOR='Patrick Juliano'; header(); }
   Main();
END { write_stdout_log("${PROGRAM_NAME}.log"); footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {
   #---------------------------------------------------------------------------------
   # Inherit the variable value from the $misc inside the defined release
   #---------------------------------------------------------------------------------
   my @release_variables_that_inherit = qw(
               vici_url pdvs
               orientation_regex
                    mstack_regex
                       PVT_regex 
   );
	 my ( $opt_config_file, $opt_debug, $opt_verbosity, $optHelp, $opt_nousage_stats ) = process_cmd_line_args();

	 utils__script_usage_statistics( abs_path($PROGRAM_NAME), $VERSION ) unless( $DEBUG || $opt_nousage_stats ); 
   #----------------------------------------------------------------------------
   #  (1) Load the defaults for the CFG so user doesn't need to do anything 
   #     for most projects.
   #  (2) check syntax of config file
   #  (3) load config file
   #----------------------------------------------------------------------------
   load_default_configs( \%globals, $opt_config_file );
   
   #------------------------------------------------------------------------------
   # The following parameters are global settings that shouldn't be configured
   #      by the user. Generally, only the script author should alter these
   #      settings. These lived in the CFG file originally, but it was confusing
   #      for users.
   #------------------------------------------------------------------------------
   dprint( MEDIUM, "CFG ... globals--> \n" . pretty_print_href( \%globals) ."\n" );
  
   #------------------------------------------------------------------------------
   # the CFG file is architected to allow multiple releases to be defined; therefore,
   #    user must specify, by name, the instance they want checked.
   #------------------------------------------------------------------------------
   if( defined $globals{'release_to_check'} ){
      viprint(LOW, "Checking release '". $globals{'release_to_check'} . "'\n" );
      if( defined $globals{$globals{'release_to_check'}} ){
         $globals{$globals{'release_to_check'}}->();
      }else{
         fatal_error( "In CFG file, can't find name of the release requested: '". $globals{'release_to_check'} . "'\n" );
      }
   }

   # $cfg => will contain the list of components and the settings for each 
   #      EXAMPLE :  
   #         $cfg = {
	 #              'phyinit'  => {
	 #	              'dirname'     => "phyinit",
	 #	              'cell_name'   => "phyinit",
	 #	              'viciname'    => "phyinit",
	 #	              'mstack_regex'=> '',
	 #	              'PVT_regex'   => '',
	 #	              'vici_url'    => 'http://vici/releasePageConstruct/index/id/25928/page_id/185',
	 #	              'version_regex'=> '^phyinit : (\S+-\S+-\S+$)',
	 #	              'overrides'   => { 
   #                    'orientation' => 'N/A',
	 #                },
   #              },
   # href_misc => contains settings for the release 
   #      includes :  base_path, vici_url, mstack_regex, PVT_regex,
   #                  inspector__REF_waivers , inspector__REF_find_n_replace  
   #                  inspector__REL_waivers , inspector__REL_find_n_replace
   my ($cfg, $href_misc) = $globals{$globals{'release_to_check'}}->();

   automagically_inherit_values_for_component_cfgs( $cfg, $href_misc, $href_misc->{vars_that_get_inherited_by_cells} );
   dprint( MEDIUM, "CFG ... globals--> \n" . pretty_print_href( \%globals) ."\n" );


   #----------------------------------------------------------------------------
   #  Load XLS as a CSV file.  Load config hash ref for all cells in release.
   #----------------------------------------------------------------------------
   print STDERR "-I- Generating BOM for Release '" . $globals{'release_to_check'} . "'\n"; 
   my $aref_MM  = read_sheet_from_xlsx_file( $globals{'fname_MM_XLSX'}  ,
                                                       $globals{'XLSX_sheet_name'} );

   #----------------------------------------------------------------------------
   # In XLSX, find the column of the RELEASE user wants checked.
   #----------------------------------------------------------------------------
   $globals{'CSV_index_REL'} = find_col_for_obj( $aref_MM, \%globals, $globals{'bom__phase_name'} );
   dprint( MEDIUM, "Found release to use in col #". $globals{'CSV_index_REL'} ."\n" );
   #----------------------------------------------------------------------------
 
   #----------------------------------------------------------------------------
   #  In CFG file, user registers names of components they want to have checked.
   #     So, verify that those component names exist in the MM XLS as well.
   #     If component to check is in the MM, capture the colum # in $cfg.
   #----------------------------------------------------------------------------
   foreach my $cell_name ( sort( unique_scalars($globals{bom__cell_names}) )){
      # Must check that the cell_names provided in $globals{'bom__cell_names'} are also
      #    specified in the $globals{'release_to_check'}. If not, warn user and skip
      #    the bad cell name provided.
      unless( defined $cfg->{$cell_name} ){
         my $err_msg  = "-CFG ERR- User listed cell name '$cell_name' in \$globals{'bom__cell_names'},\n";
            $err_msg .= " but was NOT found in release \$globals{'release_to_check'} => " . $globals{'release_to_check'} ."\n";
         fatal_error( $err_msg );
      }
      #----------------------------------------------------------------------------
      #  Find the col # of the the component name
      #----------------------------------------------------------------------------
      $cfg->{$cell_name}->{'CSV_col_idx'} = find_col_for_obj( $aref_MM, \%globals, $cell_name );
   }

   #----------------------------------------------------------------------------
   #  Extract from ViCi each component's attributes:
   #     (1)  version                (2)  orientation
   #     (3)  metal stack names      (4)  PVT ...
   #     Results are stored in the $cfg hash, for each cell individually
   #     since the ViCi URl can be unique per cell.
   #     User can control the regex for extracting ViCi content, but defaults
   #     exist that work for the standard use cases.
   #----------------------------------------------------------------------------
   my %vici_pages; my %vici_info; my @vici_info;
   slurp_component_attributes_from_vici( $cfg , sort @{$globals{bom__cell_names}}  );

   foreach my $cell_name ( sort @{$globals{bom__cell_names}} ){
      #----------------------------------------------------------------------------
      # Handle overrides req'd due to the many corner cases that violate the
      #     'standard convention'. The requirement is that the name of the override
      #      specified needs to match the name of the field you want overridden.
      #----------------------------------------------------------------------------
      if( defined $cfg->{$cell_name}{overrides} ){
         foreach my $override_name ( keys %{$cfg->{$cell_name}{overrides}} ){
            dprint( LOW, "Override found for '$override_name' for component '$cell_name'\n" ); 
            dprint( LOW, "Replacing '". scalar( Dumper $cfg->{$cell_name}{$override_name} ) ."' with '".
                                scalar( Dumper $cfg->{$cell_name}{overrides}{$override_name} ) ."'\n"
                  );
            $cfg->{$cell_name}{$override_name} = $cfg->{$cell_name}{overrides}{$override_name};
         }
      }
      #################
      # Avoid fatal error by checking to see if the mstack AREF has any elements.
      my $mstack_name_string;
      if( defined $cfg->{$cell_name}{mstack} && $cfg->{$cell_name}{mstack} ne '' ){
      if( defined $cfg->{$cell_name}{mstack}[0] ){
            # $aref has 1 or more elements
            $mstack_name_string =  "[ " . join(",", @{$cfg->{$cell_name}{mstack}}) . " ], ";
         }else{
            # $aref = [];
            # $aref has no elements and will throw an error 
            $mstack_name_string =  "[ ]," ;
         }
      }else{
         # $aref = [];
         # $aref has no elements and will throw an error 
         $mstack_name_string =  "[ ]," ;
      }
      if( $DEBUG ){  # this avoid warning messages if one of the strings below is undefined
         dprint( MEDIUM, "component [name, orient, version, mstack, CSV_col_index] => " .
                    "['$cell_name', '$cfg->{$cell_name}{orientation}', " .
                    "'$cfg->{$cell_name}{version}', " .  $mstack_name_string . 
                    "'$cfg->{$cell_name}{CSV_col_idx}']\n" 
         );
      }
      # If orientation = N/A ... make it blank. => "['$cell_name', '$cfg->{$cell_name}{orientation}', " .
   }

#exit;
   foreach my $cell_name ( sort keys %$cfg ){
      check_the_dictionary_literals_only( $globals{local_dictionary}{allowed_literals}, $cfg->{$cell_name} );
      check_local_dictionary_lists_only(  $globals{local_dictionary}{allowed_lists}, 
                                          $cfg->{$cell_name},
                                          $cell_name,
      );
   }

   #----------------------------------------------------------------------------
   # drop all rows from XLS preceding the start of the BOM
   #----------------------------------------------------------------------------
   #  Convention is when param 'row__bom_start' = 10, it refers to row 10 of xls.
   #     Since array in perl starts with index '0' and xlsx starts with index '1',
   #     adjust user param to match perl index conventions.
   my $line_of_bom_start = $globals{row__bom_start}-1;
   my $last_elem = @{$aref_MM}-1;  # scalar assignment capture size-of-list 
   dprint(SUPER, "BOM starts on line # '$line_of_bom_start'\n" );
   dprint(SUPER, "last line of BOM on line # '$last_elem'\n" );
   my @lines_of_bomspec = @{$aref_MM}[$line_of_bom_start..$last_elem];

   #----------------------------------------------------------------------------
   #  New feature : users want to be able to indicate that a fileSPEC is
   #      mandatory (marked 'x' in the Main Manifest) for a given view BUT
   #      can be considered optional ('o') in a specific phase
   #  Why? allows early delivery of a view to be cross-checked when it's avail
   #      but not flag errors when it's not available.
   #  Action required to enable is to pre-process the BOM and to convert
   #      'x' for those fileSPECs where an 'o' is recorded for the given'
   #      phase being checked.
   #----------------------------------------------------------------------------
   foreach my $cell_name ( @{$globals{bom__cell_names}} ){
      foreach my $aref_csv_line ( @lines_of_bomspec ){
         my $status_checked = cross_check_manifest(
                            $cell_name, $globals{'bom__phase_name'}, 
                            $aref_csv_line, $cfg->{$cell_name}{CSV_col_idx} ,
                            $globals{CSV_index_REL}, $globals{CSV_index_FILES},
                            DESIGNATOR_MANDATORY  , DESIGNATOR_OPTIONAL   ,
                            DESIGNATOR_INVALID    , DESIGNATOR_SKIP       ,
                            DESIGNATOR_CONDITIONAL,
                          );
      }
      #pre_process_bom_for_optional_views_in_phase( \@lines_of_bomspec , 
      #              $cfg->{$cell_name}{CSV_col_idx} ,
      #              $globals{CSV_index_REL} ,
      #              $globals{CSV_index_FILES} ,
      #              DESIGNATOR_OPTIONAL ,
      #              DESIGNATOR_MANDATORY
      #);
   }


   #----------------------------------------------------------------------------
   #  Build the BOM for each of the cells in the release.
   #----------------------------------------------------------------------------
   foreach my $cell_name ( @{$globals{bom__cell_names}} ){
      $cfg->{$cell_name}{+BOM_STANDARD}  = build_BOM_for__CELL(
                          \@lines_of_bomspec , $cfg->{$cell_name},
                          $cfg->{$cell_name}{CSV_col_idx}, DESIGNATOR_MANDATORY
      );
   }
   foreach my $cell_name ( @{$globals{bom__cell_names}} ){
      $cfg->{$cell_name}{+BOM_OPTIONAL}  = build_BOM_for__CELL(
                           \@lines_of_bomspec , $cfg->{$cell_name},
                           $cfg->{$cell_name}{CSV_col_idx}, DESIGNATOR_OPTIONAL
      );
   }

   #----------------------------------------------------------------------------
   #  Write file to record the data structure that records this Manifest.
   #----------------------------------------------------------------------------
   if( $DEBUG ){
      my $outFileName = "MM.href.txt";
      print STDERR "-I- Writing file : '$outFileName' \n";
	    open(my $fh, ">$outFileName") || die "Unable to write '$outFileName': $!\n";
	       print $fh scalar(Dumper $cfg) . "\n";
	    close($fh);
	    print STDERR "-I- Done writing file: '$outFileName'\n";
   }
   #----------------------------------------------------------------------------

   #----------------------------------------------------------------------------
   #  Stream out the files in the Manifest ...
   #----------------------------------------------------------------------------
   unless( defined $href_misc->{base_path} ){
      fatal_error( "Must define the 'base_path' in 'misc' for this release!\n" );
   }

   my $aref_bom_files           = stream_bom_to_file_list ( $cfg, BOM_STANDARD, $href_misc->{base_path} );
   my $aref_bom_optional_files  = stream_bom_to_file_list ( $cfg, BOM_OPTIONAL, $href_misc->{base_path} );
 
   dprint(CRAZY, 'BOM is recorded as =>[' . join(",\n", @$aref_bom_files) . "]\n" );
   my $outFileName = $globals{'fname_BOM_TXT'} || 'MM.filenames.txt';
   write_file( $aref_bom_files, $outFileName );
      $outFileName = $globals{'fname_optional_BOM_TXT'} || 'MM.filenames.optional.txt';
   write_file( $aref_bom_optional_files, $outFileName );
   #----------------------------------------------------------------------------

   exit(0);
}
############    END Main    ####################


#----------------------------------------------------------------------------
#  Search ViCi for orientation, version, metal stack names, PVT ...
#----------------------------------------------------------------------------
sub slurp_component_attributes_from_vici($@){
   print_function_header();
   my $cfg             = shift;
   my @component_names = @_;

   my (%vici_url, %vici_pages, @vici_info);

   foreach my $component ( @component_names  ){
      my $url = $cfg->{$component}{vici_url};
      # Avoid unpredictable results by checking to see if the vici_url is likely to work.
      if( defined $url && $url =~ m|^http://vici/| ){
         # Check to see if the ViCi URL has already been harvested ... if not 
         # initialized, return '0' and conditional becomes true (i.e. !0). So,
         # mark this URL has 'not found yet'.
         unless( exists $vici_url{$url} ){
            $vici_url{$url} = 'new url'; #not initialized
         }
         unless( $vici_url{$url} eq 'found' ){ 
            $vici_url{$url} = 'found';
            viprint( LOW, "Running Command: $globals{'ViCi_script'} $url \n" );
            my $cmd = "$globals{'ViCi_script'} $url";
            my ($stdout, $retval) = run_system_cmd( $cmd, 1 );
            if( $retval ){
               fatal_error( "Invalid return val from the cmd '$cmd'.\n" );
            }
            @vici_info  = split(/\n+/, $stdout);
         }
         dprint( HIGH, "ViCi Dump:\n" . scalar(Dumper \@vici_info) );
         
         #################
         # Check that the ViCi page was valid and if any information retrieved
         if( !defined $vici_info[2] || $vici_info[2] =~ m/Failed to open url/
                                    && $vici_info[2] !~ /^[\+]+$/ ){
            fatal_error( "Invalid ViCi URL provided for in config file '$component'! " );
         }else{
            $vici_pages{$url} = \@vici_info;
            # Extract the version, orientation, mstack, pvt values from the VICI DUMP
            grab_vici_info( $component, $cfg, $vici_pages{$url} );
         }
      }else{
         wprint( "ViCi URL for '$component' is not defined...skipping ViCi meta-data slurp. This may cause bad results!\n" );
      }
      dprint( HIGH, "Cell Config for '$component': \n" . scalar(Dumper $cfg->{$component}) . "\n");
   }

   return();
}

#------------------------------------------------------------------------------
# stream_dir_tree :  use this to mimic output TAR cmd produces
#
#    if you pass in a path such as:
#          synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/
#    this sub will return the following list:
#         'synopsys/',
#         'synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/',
#         'synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/'
#    
#------------------------------------------------------------------------------
sub stream_dir_tree ($) {
   print_function_header();
   my $base_path = shift;

   my $aref_bom_files;
   my $str= '[^/]+';
   my $regex= '[^/]+';

   #print "\$regex = $regex\n";
   # Account for lines starting with : '//depot'
   # orig: while( $base_path =~ m|^($regex/)| ){
   while( $base_path =~ m|^(/*$regex/)| ){
       push( @$aref_bom_files, $1);
       $regex .= "/$str";
   }
#   print Dumper $aref_bom_files;
#   print_function_footer();
   return( @$aref_bom_files );
}

#------------------------------------------------------------------------------
#  Only stream out the BOM for the 1. cells and 2. views
#  that were requested.
#------------------------------------------------------------------------------
sub stream_bom_to_file_list($$){
   print_function_header();
   my $href_bom  = shift;
   my $bom_type  = shift;
   my $base_path = shift;
   my $aref_bom_files;

   # build string of all the cells in the bom
   my $string_of_all_cells_in_requested_bom;
   foreach my $cell_name ( @{$globals{bom__cell_names}} ){
       $string_of_all_cells_in_requested_bom .= "$cell_name ";
   }

   push( @$aref_bom_files, stream_dir_tree( $base_path ) );
   foreach my $cell ( keys %$href_bom ){
      # only process those cells that were in the requested list.
      next unless ( $string_of_all_cells_in_requested_bom =~ m/$cell/ );
      # Automatically build the base path for the file ...
      #     $base_path/${dirname}_${orientation}/$version/
      #        but, if orientation = 'N/A'
      #     $base_path/${cell_name}/$version/
      if( defined $href_bom->{$cell}{'base_path'} ){  
         $base_path = $href_bom->{$cell}{'base_path'};
      }
      my $path = $base_path . '/' .  $href_bom->{$cell}{'dirname'};
      if( !defined $href_bom->{$cell}{'orientation'} || $href_bom->{$cell}{'orientation'} eq NULL_VAL ){
         $path .= "/";
      }else{
         #$path .= $href_bom->{$cell}{'orientation'} . "/";
         $path .= '\@{orientation}/';
      }

      $path =~ s|([^/])//|$1/|g;  # strip off trailing '/' when $version is empty
      push( @$aref_bom_files, recursively_interpolate_filespec($href_bom->{$cell}, $path) );
      $path .= $href_bom->{$cell}{'version'}
               if( defined $href_bom->{$cell}{'version'} &&
                           $href_bom->{$cell}{'version'} ne NULL_VAL );
                   
      $path =~ s|([^/])//|$1/|g;  # strip off trailing '/' when $version is empty
      dprint( MEDIUM, "Streaming BOM for cell '$cell'\n" );
      dprint( MEDIUM, "Base Path is ... '$path'\n" );
         foreach my $view ( keys %{$href_bom->{$cell}{$bom_type}} ){
            my $aref_view = $href_bom->{$cell}{$bom_type}{$view};
            # only process those views that have filespecs
            next unless( $#{$aref_view} >= 0 );
            my $fname_path = "$path";

            $Data::Dumper::Varname = "$cell...";
            dprint(MEDIUM, join "Streaming BOM ... '$cell/$view'\n" , scalar(Dumper $aref_view) , "\n");
            dprint(MEDIUM, "$fname_path\n");
            if( defined $aref_view &&  $#$aref_view+1 > 0){
               foreach my $fname ( sort @$aref_view ){
                  my $fname_target = "$fname_path/$fname";
                     $fname_target =~ s|([^/])//|$1/|g; 
                  push( @$aref_bom_files, recursively_interpolate_filespec($href_bom->{$cell}, $fname_target) );
               }
            }else{
               # For cases where the 'view' is not an array of file names, 
               # assumption is that the 'view' is actually a filename itself.
               my $fname_target = "$fname_path";
                  $fname_target =~ s|//+|/|g;  # strip off trailing '/' when $version is empty
               # For the special case of @orientation ... this was not interpolated
               #    during 1st pass. Now that the filespecs are all expanded, create
               #    as many components as required by $orientation
               push( @$aref_bom_files, recursively_interpolate_filespec($href_bom->{$cell}, $fname_target) );
            };
         }
   }


   $Data::Dumper::Varname = "VAR";
   $aref_bom_files = [ sort @{ $aref_bom_files } ];
   return( $aref_bom_files );
}
 
#------------------------------------------------------------------------------
#  Record the list of views required for a given cell in the BOM
#      This grouping is particularly useful for debugging behaviors later
#------------------------------------------------------------------------------
sub get_views($$$){
   print_function_header();
   my $aref_MM  = shift;
   my $cell_idx = shift;
   my $cell_name= shift;

#----------------------------------#
   my $x= DESIGNATOR_MANDATORY  ;
   my $o= DESIGNATOR_OPTIONAL   ;
   my $i= DESIGNATOR_INVALID    ;
   my $s= DESIGNATOR_SKIP       ;
   my $c= DESIGNATOR_CONDITIONAL;
#----------------------------------#
   my $href_views;
   my $row = -1;
      foreach my $aref_csv_line ( @$aref_MM ){
         $row++;
         next if( $cell_idx eq 'not found' );
         # Skip the fileSPEC unless and 'x' or 'o' is defined for the RELEASE + CELL
         if( $aref_csv_line->[$globals{'CSV_index_REL'} ] =~ m/^$x|$o$/ &&
            $aref_csv_line->[$cell_idx] =~ m/^$x|$o$/  ){
   
            my $view = $aref_csv_line->[ $globals{CSV_index_VIEWS} ];
            dprint(CRAZY, "\$globals{CSV_index_VIEWS} => '$globals{CSV_index_VIEWS}'\n" );
            # Include the fileSPEC as long as view is a string
            if( $view =~ m/\S+/ ){
               $href_views->{$view} = TRUE;
            }else{
               # Shouldn't ever have a view name that's empty ... something went wrong
               my $msg  = "Illegal name used for the view: ''\n" ;
                  $msg .= "See row '$row' in xlsx->'". join(' ', @$aref_csv_line) ."'\n";
               eprint( $msg );

            }
         }
      }
   my @ary_views = keys %$href_views;
   return( @ary_views );
}

#------------------------------------------------------------------------------
#  Parse the MM and cross-ref with component CFG. Generate the BOM 
#     and store in CFG hash ref. 
#
#  foreach my $cell_name ( @{$globals{bom__cell_names}} ){
#     $cfg->{$cell_name}{'bom'}  = 
#                   build_BOM_for__CELL( $aref_BOM , $cfg->{$cell_name},
#                                                   $cfg->{$cell_name}{CSV_col_idx}
#                                      );
#  }
#
#   $globals{'row__manifest_names'}= '7';   # NOT used in MM-2-bc.pl yet
#
#
#   build_BOM_for__CELL( \@lines_of_bomspec , $cfg->{$cell_name},
#                             $cfg->{$cell_name}{CSV_col_idx}
#------------------------------------------------------------------------------
sub build_BOM_for__CELL($){
   print_function_header();
   my $aref_BOM      = shift;
   my $href_cells    = shift;
   my $idx_cell_name = shift;
   my $designator    = shift;
   dprint(SUPER, "Building BOM for designator '$designator'\n" );

   my $conditional = $globals{'conditional'} || 0;
   my $version     = $href_cells->{'version'};
   my $cell_name   = $href_cells->{'cell_name'};

   my @ary_views = get_views( $aref_BOM, $idx_cell_name, $cell_name );
   my $msg = sprintf( "Views for '%-9s'=> [". join(", ", sort @ary_views) ."]\n", $cell_name );
   dprint(HIGH, $msg );

   my $href;
   foreach my $view ( @ary_views ){
      my @files;
      foreach my $aref_csv_line ( @$aref_BOM ){
            my $str = $aref_csv_line->[ $globals{CSV_index_FILES} ];
         next unless( $aref_csv_line->[ $globals{CSV_index_VIEWS} ] eq $view  );
         my $d_rel  = $aref_csv_line->[$globals{CSV_index_REL}];
         my $d_cell = $aref_csv_line->[$idx_cell_name];

         #  
         my $add_file='ERR';
         if( $designator eq DESIGNATOR_MANDATORY ){
            if( $d_rel eq DESIGNATOR_MANDATORY && $d_cell eq DESIGNATOR_MANDATORY ){
               $add_file = TRUE;
            }else{
               $add_file = FALSE;
            }
         }elsif( $designator eq DESIGNATOR_OPTIONAL ){
            if( $d_rel eq DESIGNATOR_OPTIONAL || $d_cell eq DESIGNATOR_OPTIONAL ){
               $add_file = TRUE;
            }else{
               $add_file = FALSE;
            }
         }

         dprint(CRAZY, "For cell '$cell_name' and view '$view', test if file in BOM: '$str'\n" );
         dprint(CRAZY, "   designator for rel  '$aref_csv_line->[$globals{CSV_index_REL}]' \n" );
         dprint(CRAZY, "   designator for cell '$aref_csv_line->[$idx_cell_name]' \n" );
         dprint(CRAZY, "Decision to add cell => '$add_file'\n" );
         if(  $add_file  &&
             ($aref_csv_line->[ $globals{CSV_index_COND}  ] eq DESIGNATOR_INVALID   ||
              $aref_csv_line->[ $globals{CSV_index_COND}  ] eq DESIGNATOR_SKIP      ||
              $aref_csv_line->[ $globals{CSV_index_COND}  ] eq $conditional ) &&
              $aref_csv_line->[ $globals{CSV_index_VIEWS} ] eq $view  ){
              dprint(SUPER, "Conditions met to add file to list ...:  '$str' \n" );
            
            # Use the dictionaries to find variables to interpolate (swap/replace)
            # file_SPEC_variables => this is a hash in the CFG where user can setup default values
            #      for the variables they define.  This is useful for setting single value for a variable
            #      used everywhere. Example : 'process'
            $str = find_replace_all_literals_in_dictionary(
                             $globals{local_dictionary}{allowed_literals} , $href_cells, $str );
            $str = find_replace_all_literals_in_dictionary(
                             $globals{global_dictionary}{allowed_literals}, $globals{file_SPEC_variables}, $str );
            
            # Interpolate the lists recursively
            my @interpolated_files_list = recursively_interpolate_filespec( $href_cells, $str );
            push(@files, @interpolated_files_list );
         }else{  # Conditions not met to add to the BOM/MM for this cell
            dprint(SUPER, "Conditions NOT met ... skipping file.\n" );
         }
      } # foreach file name in Manifest
      $href->{$view} = \@files;
   } # foreach view 
   return( $href );
}

#------------------------------------------------------------------------------
#  Check the dictionary to ensure the literals (1) aren't ARRAYs/LISTs and 
#     (2) are defined in the component HASH after ViCi has been
#     data-mined. If not in the HASH, provide a Warning. Since this sub
#     is cross-checking the component HASH, it's not suitable for checking
#     the Global Dictionary.
#
#      Valid Dictionary Definition at the time of authoring :
#           $globals{'local_dictionary'} = {
#              'allowed_literals' =>  [  qw( cell_name orientation version )  ],
#              'allowed_lists'    =>  [  qw( mstack pvt_combos pvt_values pvt_corners )  ],
#           };
#------------------------------------------------------------------------------
sub check_the_dictionary_literals_only($$){
   print_function_header();

   my $aref_variable_names = shift;
   my $href_cells          = shift;

   foreach my $variable_name ( @{$aref_variable_names} ){ 
      if( ! defined $href_cells->{$variable_name} && $DEBUG > LOW ){
         wprint( "Registered variable '$variable_name' NOT defined in Component ". $href_cells->{'cell_name'}."  ... won't be used during file SPEC expansion/interpolation.\n" );
      }elsif( isa_aref( $href_cells->{$variable_name} ) ){
         dprint( CRAZY, "In Dictionary (local), variable name registered => '$variable_name' \n");
         fatal_error( "File SPEC Variable registered as literal contains list! => '$variable_name', fix input CFG file\n" );
      }
   }
   return( 0 );
}

#------------------------------------------------------------------------------
#  Check the names of LISTs in the Local Dictionary to see if they are used
#      and/or defined in the Component HASH after datamining L.
#------------------------------------------------------------------------------
sub check_local_dictionary_lists_only($$$){
   print_function_header();

   my $aref_list_names = shift;
   my $href_cells      = shift;
   my $cell_name       = shift;

   foreach my $list_name ( @{$aref_list_names} ){ 
      if( defined $href_cells->{$list_name} ){
         if( isa_aref($href_cells->{$list_name}) ){
         }else{
           unless( $href_cells->{$list_name} eq NULL_VAL ){
              if( $DEBUG > LOW ){
                 wprint( "File SPEC Variable '$list_name' registered as LIST but isn't a list in CFG for '$cell_name'.\n" );}
              }
         }
      }else{ # not defined , nothing to check
         if( $DEBUG > LOW ){
              wprint( "File SPEC Variable '$list_name' registered as LIST but isn't defined in CFG for '$cell_name'.\n" );
         }
      }
   }
   return( '' );
}


#------------------------------------------------------------------------------
#  Grab each variable in the dictionary and swap-replace in the file SPEC.
#      The Local Dictionary should have been cross-checked by another sub
#      already. The Global Dictionary is by definition global and 
#      there are hashes to cross-check for existence.
#
#      Valid Dictionary Definition at the time of authoring :
#           $globals{'global_dictionary'} = {
#              'allowed_literals' =>  [  qw( phyPrefix uniqPrefix )  ],
#           };
#           $globals{'local_dictionary'} = {
#              'allowed_literals' =>  [  qw( cell_name orientation version )  ],
#              'allowed_lists'    =>  [  qw( mstack pvt_combos pvt_values pvt_corners )  ],
#           };
#------------------------------------------------------------------------------
sub find_replace_all_literals_in_dictionary($$$$){
   print_function_header();
   my $aref_variable_names = shift;
   my $href                = shift;
   my $filespec            = shift;

   foreach my $variable_name ( @{$aref_variable_names} ){ 
      dprint( CRAZY, "In Dictionary (local), variable name registered => '$variable_name' \n");
      if( defined $href->{$variable_name} ){
         if( $href->{$variable_name} ne NULL_VAL  ){
            my $value = $href->{$variable_name};
            $filespec =~ s/\$\{$variable_name}/$value/g;
         }else{
            $filespec =~ s/\$\{$variable_name}//g;
         }
      }
   }

   return( $filespec );
}

#------------------------------------------------------------------------------
sub process_cmd_line_args(){
   print_function_header();
	 my ( $config, $opt_debug, $opt_verbosity, $optHelp, $opt_nousage_stats );
	 GetOptions( 
		    "cfg=s"       => \$config,     # config files for check
		    "debug=s"	    => \$opt_debug,
		    "verbosity=s" => \$opt_verbosity,
		    "nousage"	    => \$opt_nousage_stats,    # when enabled, skip logging usage data
		    "help"	      => \$optHelp,    # Prints help

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
	 return( $config, $opt_debug, $opt_verbosity, $optHelp, $opt_nousage_stats );
};


#-------------------------------------------------------------------------------------
# automagically_inherit_values_for_component_cfgs : add default values for
#    each component rather than require user to specify, since same value is used
#    for every component most of the time.
#    Will read the list of var 
   #------------------------
   # Use global defined ViCi URL if none specified for the component.
   #    If no ViCi URL is desired, then it can be accomplished by
   #    using 'overrides', which are recorded later in the algo.
   #    Or, it can be ignored completely and achieve same result.
   # Use global defined regex for extracting PVT & metal stack info from ViCi.
#-------------------------------------------------------------------------------------
sub automagically_inherit_values_for_component_cfgs($$$){
   print_function_header();
   my $cfg            = shift;
   my $href_misc      = shift;
   my $aref_var_names = shift;

   foreach my $component_name ( keys %$cfg ){
      my $msg;
      foreach my $var ( @$aref_var_names ){
         unless( defined $cfg->{$component_name}{$var} ){
            if( defined $var && defined $href_misc->{$var} ){
            $cfg->{$component_name}{$var} = $href_misc->{$var};
            #------------------------
            $msg = "Using default value for '$var' ... for component '$component_name'\n";
            $msg .= "\t\t  $cfg->{$component_name}{$var} \n";
            dprint(MEDIUM, $msg );
            #------------------------
            }else{
               $msg = "Not defined: var '$var' ... or var in component '$component_name'\n";
               dprint(LOW, $msg );
            }
         }
      }
   #----------------------------------------------------------------------------
   #  To reduce configs user must specify, perform some magic.
   #     By default, automatically inherit the 'dirname', 'viciname', and
   #     the 'cell_name' from the COMPONENT (i.e. $cfg->{COMPONENT_NAME}
   #     FWIW, the COMPONENT named must match the name in the XLSX.
   #----------------------------------------------------------------------------
      foreach my $special_name ( qw(dirname viciname cell_name) ){
         unless( defined $cfg->{$component_name}{$special_name} ){
            #------------------------
            $msg = "Using component name '$component_name' for special name '$special_name'\n";
            dprint(HIGH, $msg );
            #------------------------
            $cfg->{$component_name}{$special_name} = $component_name;
         }
         #------------------------
         # For debugging
         my $msg = "component_name = $component_name ... \n";
            $msg = "\t $special_name = ".  $cfg->{$component_name}{$special_name} ."\n";
         dprint(MEDIUM, $msg );
         #------------------------
      } 
   }
}

