#!/depot/perl-5.14.2/bin/perl
#!/usr/bin/env perl

use strict;
use Devel::StackTrace;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use Getopt::Long;
use Excel::Writer::XLSX;

use lib dirname(abs_path $0) . '/../lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Excel;
use Util::Messaging;
use Manifest;

our $DIRNAME = dirname(abs_path $0);
our $PROGRAM_NAME = $0; 
our $AUTHOR_NAME  = 'Patrick Juliano'; 
our $VERSION      = '1.0';
#----------------------------------#
use constant COL__VIEWS => 5;
use constant COL__CELLS => 3; # for cell/component names
use constant COL__VIEWS => 5; #
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $STDOUT_LOG   = undef;

#----------------------------------#

my $views_to_group = 'atpg|calibre|hspice|ibis|icv|include|timing';

BEGIN { header(); } 
   Main();
END { write_stdout_log("${PROGRAM_NAME}.log"); footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {
   my ( $opt_debug, $optHelp, $fname_rel_pkg ) = process_cmd_line_args( );
   $Data::Dumper::Indent = 1;

	 utils__script_usage_statistics( abs_path($PROGRAM_NAME), $VERSION ); 

   # Capture every line (filespec) from the release package 
   #    and store in array ref
   my $aref_rel_lines = get_release_target_file_list( $fname_rel_pkg );
   my @lines = grep { $_ !~ /Latest$/ } @$aref_rel_lines;
   my $aref_release = \@lines;
 
   # Build an array of arefs. Each aref stores an ordered list composed
   #    from the names of the directories and/or files.
   my @ary_bom;
   foreach my $line ( @$aref_release ){
      push( @ary_bom, tokenize_filespecs( $line ));
   }
   
   # Build a list of the component names --> inspect the path depth COL__CELLS
   # Build a list of the view names --> inspect the path depth COL__VIEWS
   my %hash_grouping_info;
   foreach my $line ( @$aref_release ){
      my @columns = split(/\//, $line);
      #print pretty_print_aref( \@columns );
      if( defined $columns[COL__CELLS] ){ $hash_grouping_info{components}{names}{$columns[COL__CELLS]}++; }
      if( defined $columns[COL__VIEWS] ){ $hash_grouping_info{views}{names}{$columns[COL__VIEWS]}++;      }
   }
   dprint(HIGH, Dumper \%hash_grouping_info );

   #---------------------------------------------------------------------------
   # For each COMPONENT, find the filespecs with the name in it. Use that list for coloring the rows.
   #    Build a list of the domains used later for grouping rows.
   foreach my $obj ( keys %{$hash_grouping_info{components}{names}} ){
      $hash_grouping_info{components}{$obj}{rows}    = find_row_of_bom_obj( $aref_release, $obj );
      $hash_grouping_info{components}{$obj}{domains} = find_row_domains_of_bom_obj( $hash_grouping_info{components}{$obj}{rows} );
   }

   #---------------------------------------------------------------------------
   # For each VIEW, find the filespecs with the name in it. Use that list for coloring the rows.
   #    Build a list of the domains used later for grouping rows.
   my @ary_views = qw( atpg calibre hspice ibis icv include timing );
   foreach my $obj ( keys %{$hash_grouping_info{views}{names}} ){
      $hash_grouping_info{views}{$obj}{rows}    =  find_row_of_bom_obj( $aref_release, $obj );
      #  We don't want to turn every view into a group 
      next unless( $obj =~ m/$views_to_group/ );
      $hash_grouping_info{views}{$obj}{domains} =  find_row_domains_of_bom_obj( $hash_grouping_info{views}{$obj}{rows} );
   }
   
   #---------------------------------------------------------------------------
   # '@ary_bom' stores AREFs, each of which has different number of 
   #    elements and is based on the file tree depth.
   #    (1) Record the max # elements on any given line, this represents
   #         the maxdepth of the file tree. 
   #    (2) For each AREF, add elements so that the list length is the same
   #         for every AREF and matches the max # elements.
   my $max_depth_of_filetree=find_max_col_index_of_list_of_arefs( @ary_bom );
   pad_lines_for_max_depth( $max_depth_of_filetree, @ary_bom );
  
   
   #---------------------------------------------------------------------------
   # 
   #my $regex = '\w*';
   #my @component_row_boundarys = setup_row_groupings( COL__CELLS, $regex, @ary_bom );
      #$regex = 'timing';
   #my @view_row_boundarys      = setup_row_groupings( COL__VIEWS, $regex, @ary_bom );
   
   @ary_bom = depopulate_redundant_prefix_from_filespec( @ary_bom );
   dprint(CRAZY, pretty_print_aref_of_arefs( \@ary_bom ) );
   write_excel( \@ary_bom , $fname_rel_pkg , \%hash_grouping_info );
   exit(0);
}

############    END Main    ####################

###############################################################################
##  Search for domains. Domain is a pair of row #s (Start Row # , Stop Row # )
##     This sub returns a list of domains (i.e. row pairs) in an aref
##     $aref->[0] = "start_row1:stop_row1"   # bounds for 1st domain found
##     $aref->[1] = "start_row1:stop_row1"   # bounds for 2nd domain found
##     each of the rows accordingly.
sub find_row_domains_of_bom_obj($){
   print_function_header();
   my $aref_of_row_nums = shift;  # ordered list of row nums with breaks in the sequence

   my $aref_domains;
   # setup initial conditions for the loop
   my $previous_row = $aref_of_row_nums->[0] -1;
   my $domain_start = $aref_of_row_nums->[0];
   my $domain_stop;
      my $row;
   for(my $cnt=0; defined($aref_of_row_nums->[$cnt]); $cnt++ ){
      $row = $aref_of_row_nums->[$cnt];
      dprint(CRAZY, "row=$row, prev_row=$previous_row\n" );
      # when the current row is adjacent to the previous row, no domain break 
      if( $row == ($previous_row+1) ){
         $previous_row = $row;
      }else{
      # when the current row is NOT adjacent to the previous row, we found a domain break 
         $domain_stop=$previous_row;
         dprint(CRAZY, "domain(start,stop)=> $domain_start:$domain_stop\n" );
         push(@$aref_domains, "$domain_start:$domain_stop");
         # reset the domain bounds
         $domain_start = $row;
         $previous_row = $row;
      }
      unless( defined($aref_of_row_nums->[$cnt+1] )){  
         # this is the last element, and by definition end of the current domain
         $domain_stop=$row;
         dprint(CRAZY, "last line: domain(start,stop)=> $domain_start:$domain_stop\n" );
         push(@$aref_domains, "$domain_start:$domain_stop");
      }
   }

   dprint( MEDIUM, "Domains found:" . pretty_print_aref($aref_domains) . "\n");
   return( $aref_domains );
}

###############################################################################
## Record the row #'s where each view can be found so we can color
##     each of the rows accordingly.
sub find_row_of_bom_obj($$){
   print_function_header();
   my $aref_of_lines = shift;
   my $obj_regex    = shift;

   my @ary_row_nums;
   my $row=-1;
   foreach my $line ( @$aref_of_lines ){
      $row++;
      if( $line =~ m|/$obj_regex/| ){
         push( @ary_row_nums, $row );
      }
   }
   dprint( HIGH, "Row numbers w/item '$obj_regex': ".pretty_print_aref(\@ary_row_nums)."\n" );
   return( \@ary_row_nums ); # return list of pairs .. 'start row:end row'
}


###############################################################################
sub write_excel($){
   print_function_header();
   my $aref = shift;
   my $fname_rel_pkg = shift;
   my $href_obj_rows_domains = shift;

   my @ary_bom = @$aref;

   iprint( "Writing Excel file ...\n" );
   system( "sleep 1" );
   my $xls_fname = "${fname_rel_pkg}.xlsx";
   my $xls_ref   = Excel::Writer::XLSX->new("$xls_fname");
   my $sumSheet  = $xls_ref->add_worksheet("Summary");

   # Register 'named' colors availble in the sheet
   my %colors_table = get_color_map( $xls_ref );

   # Store the name of the color to be used in the same cell as will be colored 
   #     in the BOM
   my @color_map = color_the_bom_cells( @ary_bom );


   my $grpDepth = 1; 
   my ($minRow,     $maxRow);
   my  $minCol;  my $maxCol = scalar( @{$ary_bom[0]} ); 
   # Setup the colorization for the registered components
   foreach my $list ( qw( components views ) ){
      foreach my $obj ( keys %{$href_obj_rows_domains->{$list}} ){
         dprint(HIGH, Dumper $href_obj_rows_domains->{$list}{$obj}{domains} );
         foreach my $domain ( @{$href_obj_rows_domains->{$list}{$obj}{domains}} ){
            ($minRow, $maxRow) = ($domain=~m/^(\d+):(\d+$)/);
            if( $list eq 'views'){
               $grpDepth = 2; 
               $minCol   = COL__VIEWS; 
            }
            if( $list eq 'components' ){
               $grpDepth = 1; 
               $minCol   = COL__CELLS; 
            }
            dprint(HIGH, "$obj : DOMAIN = $domain  (minRow,maxRow)=($minRow,$maxRow) (minCol,maxCol)=($minCol,$maxCol) \n");
   
            create_a_grouping( $xls_ref, $sumSheet, $grpDepth, $minRow, $maxRow );
         }
      }
   }
   
   #   $minCol = COL__VIEWS;
   #   $grpDepth = 2;

   # Setup the groups by domain and depth
   #foreach my $domain ( %$href_obj_rows_domains ){
   #}
   
   # Setup the colorization for the registered components BEFORE the views
   $minCol = COL__CELLS;

   dprint( SUPER, pretty_print_href($href_obj_rows_domains)."\n" );
   foreach my $obj ( keys %{$href_obj_rows_domains->{components}} ){
      color_the_rows_for_obj( \@color_map, $href_obj_rows_domains->{components}{$obj}{rows}, $obj, $minCol, $maxCol );
   }
   $minCol = COL__VIEWS;
   # Setup the colorization for the registered views
   foreach my $obj ( keys %{$href_obj_rows_domains->{views}} ){
      color_the_rows_for_obj( \@color_map, $href_obj_rows_domains->{views}{$obj}{rows}, $obj, $minCol, $maxCol );
   }
#   dprint( FUNCTIONS, pretty_print_aref_of_arefs( \@color_map )."\n" );

   # Apply the colors defined for each of the cells
   my $maxRow = scalar( @ary_bom );
   for(my $row=0; $row < $maxRow; $row++ ){
      my $maxCol = scalar( @{$ary_bom[$row]} );  
      for(my $col=0; $col < $maxCol;  $col++ ){
         my $cell_value =  $ary_bom[$row][$col];
         my $color_name =  $color_map[$row][$col];
         unless( defined $colors_table{$color_name} ){  $color_name = 'default'; }
         $sumSheet->write( $row, $col, $cell_value, $colors_table{$color_name} ); 
      }
   }

   $xls_ref->close;
   iprint( "Wrote Excel file: '$xls_fname'\n" );
}

###############################################################################
#  Setup Groupings & colorize based on transition between components
sub create_a_grouping{
   print_function_header();
   my $xls_ref  = shift;
   my $sumSheet = shift;
   my $grpDepth = shift;
   my $minRow   = shift;
   my $maxRow   = shift;

   for( my $row=$minRow+1; $row <= $maxRow; $row++ ){
      if( $row > 700 && $row < 1000 ){
         dprint(CRAZY, "set_row($row, undef, undef, undef, $grpDepth, 0 )\n" );
      }
      $sumSheet->set_row($row, undef, undef, undef, $grpDepth, 0 );
   }

}

###############################################################################
sub color_the_rows_for_obj($$){
   #print_function_header();
   my $aref   = shift;  # aref of the colors that will be applied later
   my $aref_rows = shift;
   my $obj_name  = shift;
   my $minCol = shift;
   my $maxCol = shift;

   foreach my $row ( @$aref_rows ){
      my $color=$obj_name; color_the_row( $aref, $row, $minCol, $maxCol, $color );
   }
   return();
}

###############################################################################
##  setup the cell colors for first 3 rows and first 3 cols
sub color_the_bom_cells($@){
   print_function_header();
   my @ary_bom = @_;

   my $maxRow = scalar( @ary_bom ); 
   my $maxCol = scalar( @{$ary_bom[0]} );  

   my @color_map;
   setup_colors_for_base_path( \@color_map, $maxRow , $maxCol );

   return( @color_map );
}

###############################################################################
sub setup_colors_for_base_path($$){
   print_function_header();
   my $color_map_aref = shift;
   my $maxRow = shift;
   my $maxCol = shift;

   # apply the colors to the 1st three rows because the base path
   #     always starts with synopsys/dwc_${product_name}/${vici_ver_number}
   my $col; my $minRow; my $color;
   $col=0; $minRow=0; $color='synopsys'; color_the_col( $color_map_aref, $col, $minRow, $maxRow, $color );
   $col=1; $minRow=1; $color='dwc';      color_the_col( $color_map_aref, $col, $minRow, $maxRow, $color );
   $col=2; $minRow=2; $color='viciver';  color_the_col( $color_map_aref, $col, $minRow, $maxRow, $color );

   # apply the colors to the 1st three col because the base path
   #     always starts with synopsys/dwc_${product_name}/${vici_ver_number}
   my $row; my $minCol; 
   $row=0; $minCol=0; $color='synopsys'; color_the_row( $color_map_aref, $row, $minCol, $maxCol, $color );
   $row=1; $minCol=1; $color='dwc';      color_the_row( $color_map_aref, $row, $minCol, $maxCol, $color );
   $row=2; $minCol=2; $color='viciver';  color_the_row( $color_map_aref, $row, $minCol, $maxCol, $color );
}

###############################################################################
sub color_the_col($$$$$){ 
   my $aref_color_map = shift;
   my $col    = shift;
   my $minRow = shift;
   my $maxRow = shift;
   my $color  = shift;

   for(my $row=$minRow; $row < $maxRow; $row++ ){
      $aref_color_map->[$row][$col] = $color;
      dprint( CRAZY, pretty_print_aref( $aref_color_map->[$row] ) ."\n" );
   }
}

###############################################################################
sub color_the_row($$$$$){ 
   #print_function_header();
   my $aref_color_map = shift;
   my $row    = shift;
   my $minCol = shift;
   my $maxCol = shift;
   my $color  = shift;

   for(my $col=$minCol; $col < $maxCol; $col++ ){
      $aref_color_map->[$row][$col] = $color;
   }
   dprint( CRAZY, pretty_print_aref( $aref_color_map->[$row] ) ."\n" );
}

###############################################################################
sub get_color_map($){
   print_function_header();
   my $xls_ref = shift;

   my %colors;
   my $shade_num = 1;
   my $max_num_shades = 9;
   my $color = '#'.purple_shades( 1, $max_num_shades );
   $colors{'default'} = $xls_ref->add_format(
                      align  => 'left',
                      bg_color  => '#ECF4F8',
                      size => '12',
                  );
   $colors{'synopsys'}= $xls_ref->add_format(
                      bg_color  => '#'.purple_shades( 1, $max_num_shades ),
                      align  => 'left', size => '16',
                  );
   $colors{'dwc'}     = $xls_ref->add_format(
                      bg_color  => '#'.purple_shades( 3, $max_num_shades ),
                      align  => 'left', size => '15',
                  );
   $colors{'viciver'} = $xls_ref->add_format(
                      bg_color  => '#'.purple_shades( 5, $max_num_shades ),
                      align  => 'left', size => '14',
                  );
   # Setup the colors for each of the views
   # views => ( atpg behavior calibre def gds hspice ibis icv include interface lef netlist oasis rtl spyglass timing );
   #
   # yellow shades
   $colors{'calibre'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.yellow_shades( 9, $max_num_shades ),   );
   $colors{'def'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.yellow_shades( 8, $max_num_shades ),   );
   $colors{'gds'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.yellow_shades( 6, $max_num_shades ),   );
   $colors{'icv'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.yellow_shades( 6, $max_num_shades ),   );
   $colors{'lef'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.yellow_shades( 5, $max_num_shades ),   );
   $colors{'oasis'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.yellow_shades( 6, $max_num_shades ),   );
   # red shades
   $colors{'behavior'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.red_shades( 9, $max_num_shades ),     );
   $colors{'netlist'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.red_shades( 7, $max_num_shades ),     );
   $colors{'include'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.red_shades( 5, $max_num_shades ),     );
   $colors{'interface'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.red_shades( 3, $max_num_shades ),     );
   $colors{'rtl'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.red_shades( 1, $max_num_shades ),     );
   # green shades
   $colors{'hspice'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.green_shades( 3, $max_num_shades ),     );
   $colors{'ibis'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.green_shades( 7, $max_num_shades ),     );
   $colors{'ibis_ami'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.green_shades( 7, $max_num_shades ),     );
   $colors{'timing'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.green_shades( 9, $max_num_shades ),     );
   # cyan
   $colors{'atpg'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.cyan_shades( 3, $max_num_shades ),     );
   $colors{'upf'}   = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.cyan_shades( 5, $max_num_shades ),     );
   $colors{'spyglass'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.cyan_shades( 7, $max_num_shades ),     );

   #----- Hard Components------------------------------------------------------
   $colors{'acx4_ew'}   = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 1, $max_num_shades ),     );
   $colors{'acx4_ns'}   = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 1, $max_num_shades ),     );
   $colors{'dbyte_ew'}   = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 1, $max_num_shades ),     );
   $colors{'dbyte_ns'}   = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 1, $max_num_shades ),     );
   $colors{'se_ew'}     = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 1, $max_num_shades ),     );
   $colors{'sec_ew'}    = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 1, $max_num_shades ),     );
   $colors{'diff_ew'}   = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 1, $max_num_shades ),     );
   $colors{'master'}   = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 2, $max_num_shades ),     );
   $colors{'master_ew'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 2, $max_num_shades ),     );
   $colors{'master_ns'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 2, $max_num_shades ),     );
   $colors{'utility_cells'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.red_shades( 8, $max_num_shades ),     );
   $colors{'clktree_repeater'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.red_shades( 8, $max_num_shades ),     );
   $colors{'repeater_cells'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.red_shades( 8, $max_num_shades ),     );
   #----- Soft Components------------------------------------------------------
   $colors{'ctb'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 6, $max_num_shades ),     );
   $colors{'phyinit'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 7, $max_num_shades ),     );
   $colors{'firmware'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.gold_shades( 8, $max_num_shades ),     );
   $colors{'doc'}  = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.purple_shades( 7, $max_num_shades ),     );
   $colors{'example'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.purple_shades( 8, $max_num_shades ),     );
   $colors{'installed_corekit'} = $xls_ref->add_format( align  => 'left', size => '11',
                      bg_color  => '#'.purple_shades( 9, $max_num_shades ),     );
   return( %colors );
}

################################################################################
sub find_max_index_of_aref($){
    my $aref = shift;
    return( $#$aref );
}

################################################################################
sub find_max_col_index_of_list_of_arefs(@){
   print_function_header();
    my @ary = @_;

    my $max=0;
    foreach my $aref ( @ary ){
       my $len = find_max_index_of_aref( $aref );
       if( $len > $max ){ $max=$len; }
    }
    return( $max );
}

################################################################################
#  Remove the redundant info from the paths ... given input lines below
#  
#   synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/example/
#   synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/master_ns/
#   synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/master_ns/2.00a/gds/6M_1X_h_1Xa_v_1Ya_h_2Y_vh/dwc_ddrphymaster_top_ns.gds
#   synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/master_ns/2.00a/gds/6M_1X_h_1Xa_v_1Ya_h_2Y_vh/layerMap_6M_1X_h_1Xa_v_1Ya_h_2Y_vh.txt
#   synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/master_ns/2.00a/include/${_ALL_}
#   synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/master_ns/2.00a/include/*.v
#   synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/master_ns/2.00a/include/atpg_primitives.v
#   synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/master_ns/2.00a/include/std_primitives.v
#
#   this sub will depopulate the unnecessary file tree information
#
#   synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/example/
#   synopsys/dwc_lpddr54_phy_cuamd_tsmc6ff18/2.00a/master_ns/
#                                                            2.00a/gds/6M_1X_h_1Xa_v_1Ya_h_2Y_vh/dwc_ddrphymaster_top_ns.gds
#                                                                                               /layerMap_6M_1X_h_1Xa_v_1Ya_h_2Y_vh.txt
#                                                                  include/${_ALL_}
#                                                                         /*.v
#                                                                         /atpg_primitives.v
#                                                                         /std_primitives.v
################################################################################
sub depopulate_redundant_prefix_from_filespec(@){
   print_function_header();
   my @ary_bom = @_;

   dprint( MEDIUM, "Num array elements : " . scalar(@ary_bom) . "\n" );
   for(my $num=scalar(@ary_bom)-1;  $num >= 1 ; $num-- ){
      for(my $col=0; $col < scalar(@{$ary_bom[$num]});  $col++ ){
         if( $col < scalar(@{$ary_bom[$num-1]}) ){
            #print "checking [$num][$col] <-> [". ($num-1) ."][$col] \t". $ary_bom[$num][$col] ."<->". $ary_bom[$num-1][$col] ."\n";
            if( $ary_bom[$num][$col] eq $ary_bom[$num-1][$col] ){ $ary_bom[$num][$col] = ""; }
            #<STDIN>;
         }
      }
      for(my $col=0; $col < scalar(@{$ary_bom[$num]});  $col++ ){
          #print "$ary_bom[$num][$col],\t";
      }
      #print "\n";
   }
   return( @ary_bom );
}
 
################################################################################
sub tokenize_filespecs($){
   my $line = shift;

   chomp( $line );
   # turn each directory/filename into an element in a list
   my @directories = split(/\//, $line);
   #print Dumper \@directories;
   #<STDIN>;
   my @dirs_n_fname;
   if( $line =~ m/\/$/ ){
      @dirs_n_fname = map {$_ . '/'} @directories;
   }else{
      @dirs_n_fname = map {$_ . '/'} @directories;
      $dirs_n_fname[-1] =~ s/\/$//;
   }
      
   return( \@dirs_n_fname );
};

###############################################################################
sub prep_manifest_for_customers{
   print_function_header();
   my $Manifest_input = shift;

   my $temp_dirname = 'junker-deleteme-abandon-me-now';
   #my $Manifest_input = "MM.filenames.txt";
   my $Manifest = dirname(abs_path $0) .  "/$Manifest_input.scrubbed.txt";
   dprint(LOW, "Manifest input file name is => '$Manifest_input'\n" );
   dprint(LOW, "Manifest output file name is => '$Manifest'\n" );

   my $fh;
   open($fh, $Manifest_input ) || confess  "I'm gonna die!\n";
	 while( my $line=<$fh> ){
   chomp( $line );
      $line =~ s/\/([^\/]+)$//;
      # Create the directory paths and files
      my $cmd = "mkdir -p  $temp_dirname/$line";
      run_system_cmd( $cmd , NONE );
         $cmd = "touch $temp_dirname/$line/$1";
      run_system_cmd( $cmd , NONE );
   }
   close($fh);

   # Create a file that contains the same input you'd get from a TAR listing ... 
   #     the key here is that the format returned from find matches TAR.
   my $cmd = "cd $temp_dirname; find synopsys \\\( -type d -printf \"\%p/\\n\" , -type f -print \\) >  $Manifest";
   run_system_cmd( $cmd , $DEBUG );

   return( $Manifest );
}


###############################################################################
# The data structure passed into this function is an arry of arefs. Each aref
#     points to a list of elements and the length can vary. So, pad those
#     lists that are short than then max, so that all lists are of uniform
#     length.
#     Example -  array passed to this function
#     $ary[0] = [ 'syn' ];
#     $ary[1] = [ 'syn', 'd812' ];
#     $ary[2] = [ 'syn', 'd812', '1.00a' ];
#     $ary[3] = [ 'syn', 'd812', '1.00a', 'acx4_ew' ];
#
#     Example -  array passed back from function
#     $ary[0] = [ 'syn', ''    , ''     , ''        ];
#     $ary[1] = [ 'syn', 'd812', ''     , ''        ];
#     $ary[2] = [ 'syn', 'd812', '1.00a', ''        ];
#     $ary[3] = [ 'syn', 'd812', '1.00a', 'acx4_ew' ];
#
sub pad_lines_for_max_depth($@){
   print_function_header();
   my $max_depth_of_filetree = shift;
   my @ary_bom_lines = @_;

   dprint( MEDIUM, "\$max_depth_of_filetree=$max_depth_of_filetree\n" );
   foreach my $aref_bom_line ( @ary_bom_lines ){
      if( $DEBUG > HIGH ){
      dprint( HIGH, "BEFORE padding ... \n" );
      print Dumper \$aref_bom_line;
      }
      for(my $col=$#$aref_bom_line+1; $col <= $max_depth_of_filetree; $col++){
         unless( defined $aref_bom_line->[$col] ){
            $aref_bom_line->[$col] = "";
         }
      }
      if( $DEBUG > HIGH ){
      dprint( HIGH, "AFTER padding ... \n" );
      print Dumper \$aref_bom_line;
      }
   }
}


###############################################################################
sub process_cmd_line_args(){
	 my ( $config, $opt_debug, $optHelp, 
           $fname_rel_pkg,  $fname_rel_pkg_file_list, 
           $fname_reference_list, $opt_fname_logfiles_basename );
	 GetOptions( 
		    "rel=s"	   => \$fname_rel_pkg,
		    "debug=i"	 => \$opt_debug,
		    "help"	   => \$optHelp, # Prints help
	 );

   # decide whether to alter DEBUG variable
   # '--debug' indicates DEBUG value ... set based on user input
   if( defined $opt_debug && $opt_debug =~ m/^\d*$/ ){  
      $main::DEBUG = $opt_debug;
   }

	 # Set an error flag ...
	 my $error = FALSE;
   unless( defined $fname_rel_pkg ){
	    eprint( "Missing option '-rel' ... must provide valid relase pkg to be used as the reference for inspecting the release!\n" );
	    $error = TRUE;
	 }
	 if( $error ){ fatal_error( "Found errors that must be fixed ... aborting!\n" ); }
	 return( $opt_debug, $optHelp, $fname_rel_pkg );
};


