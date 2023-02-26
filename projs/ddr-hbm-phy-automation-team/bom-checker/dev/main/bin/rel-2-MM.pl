#!/depot/perl-5.14.2/bin/perl -w
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
use Config::General;
use Excel::Writer::XLSX;
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::Excel;
use Text::ASCIITable;

our $PROGRAM_NAME = $RealScript;
our $VERSION      = '1.0';
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
#----------------------------------#


BEGIN { our $AUTHOR = 'Patrick Juliano'; header(); } 
   Main();
END { footer(); }



########  YOUR CODE goes in Main  ##############

sub Main{
     my( $opt_debug, $opt_verbosity, $opt_help, $opt_nousage_stats,
       $opt_rel, $opt_cfg, $opt_nopdv, $opt_nopvt ) = process_cmd_line_args();

     utils__script_usage_statistics( abs_path($PROGRAM_NAME), $VERSION )
              unless( defined $opt_debug || $DEBUG || $opt_nousage_stats ); 
   
   #---------------------------------------------
   # Load CFG file containing strings to swap out
   my ($href_cfg, $aref_warnings) = load_config_file( $opt_cfg );

   #---------------------------------------------
   # Load file containing list of files in release
   my @lines = read_file( $opt_rel );
   iprint( "Release file contains '" .scalar(@lines). "' lines.\n" );
   dprint(HIGH, "Release file contains '" .scalar(Dumper \@lines). ":\n" );

   #my @newlines = map { s|//depot/products/[^\/]*?/[^\/]*?/[^\/]*?/[^\/]*?/[^\/]*?/[^\/]*?|synopsys/product_name/version|g; s|\d.\d+\w+/macro/||g; $_;} @lines;
   #iprint( "NEW Release file contains '" .scalar(@newlines). "' lines.\n" );
   #dprint(HIGH, "NEW Release file contains '" .scalar(Dumper \@newlines). ":\n" );
   #iprint( "Release file contains '" .scalar(@lines). "' lines.\n" );
   #dprint(HIGH, "Release file contains '" .scalar(Dumper \@lines). ":\n" );
   #---------------------------------------------
   iprint( "Analyzing release content ...\n" );
   prompt_before_continue(HIGH);
   my %hash = gather_release_stats(\@lines);
   dprint(HIGH, scalar(Dumper \%hash) . "\n" );

   #---------------------------------------------
   iprint( "Building BOM data structure for release.\n" );
   #  Unique versions are used for each component, and should be ignored for purposes of accounting later
   my %bom = build_bom_data_structure( \@lines );
   dprint(HIGH, "Dumping the \%bom data structure.\n" );
   prompt_before_continue(HIGH);
   dprint(HIGH, scalar(Dumper \%bom) . "\n" );
   prompt_before_continue(HIGH);

   my @views = keys $hash{view};
   my @components = keys $hash{component};
   iprint( "Found following view names: " .pretty_print_aref(\@views). "\n" ); 
   iprint( "Found following component names: " .pretty_print_aref(\@components). "\n" ); 
   dprint(SUPER, scalar(Dumper $href_cfg) . "\n" );
   #prompt_before_continue();

   #---------------------------------------------
   #  swap out the strings with variables in BOM data struct with 
   #    with equivalent var names defined in CFG file
     swapper( $opt_nopdv, $opt_nopvt, $href_cfg, \%bom );
     dprint(HIGH, "Dumping the \%bom data structure (after variable substring substitution.\n" );
     prompt_before_continue(HIGH);
     dprint(HIGH, scalar(Dumper \%bom) . "\n" );
     prompt_before_continue(HIGH);
   #---------------------------------------------

   #-----------------------------------------------------------------
   # Start building the report to print to STDOUT/file etc
   #
   #---------------------------------------------
   my $href_file_accounting;
   foreach my $view ( sort @views ){
      $href_file_accounting = determine_components_mapping_of_files_in_each_view( \%bom , $view, $href_file_accounting);
   }
   dprint(CRAZY, scalar(Dumper $href_file_accounting) . "\n" );

   #---------------------------------------------
   # Build the column titles/headers
   my $aref_release_names = $href_cfg->{release_name};
   my @col_hdrs = report__print_title_row( $aref_release_names, @components );

   my $t = Text::ASCIITable->new({ headingText => "Main Manifest" });
   $t->setOptions( {undef_as=>"-", alignHeadRow=>'center'} );
   # Build table based on manager names
   $t->setCols(@col_hdrs);
   $t->setOptions('reportErrors',0);
   $t->addRowLine();
   $t->setOptions('reportErrors',1);
   my $release_padder = get_MM_row_release_padder($aref_release_names);

   vhprint(LOW, "Release Count  => " . @$aref_release_names ."\n"  );
   vhprint(LOW, "Release Names  => " . pretty_print_aref($aref_release_names) ."\n"  );
   dprint(HIGH, "Release padder => $release_padder\n" );
   #---------------------------------------------

   my @manifest_lines;
   foreach my $view ( sort @views ){
      report__which_components_have_which_files_foreach_view( $release_padder, \@manifest_lines, \%bom, $href_file_accounting, $view, \@components );
   }

    report__which_components_have_which_files_without_view( $release_padder, \@manifest_lines, \%bom, $href_file_accounting,
               '', \@components );

   #dprint(LOW, scalar( Dumper \@manifest_lines ). "\n" );
   foreach my $elem ( @manifest_lines ){
      $t->addRow( split(/,/, $elem));
   }
   $t->addRowLine();

   #------------------
   # Convert ASCII table to 2-D array
   my $aref_table = convert_ASCII_Table_2_aref_of_aref( $t );
   #------------------
   # Dump head of the ASCII table
   prompt_before_continue(SUPER);
   my $head_of_table = join("\n", (split(/\n/, $t))[0..10]);
   vhprint(LOW, "\n$head_of_table\n" );
   dprint(SUPER, "\n$t\n" );
   #------------------
   # Write XLS
   my $fname_xls = 'mm.xlsx';
   my $workbook =  xls_open( $fname_xls );
   # setup 3 formats for the column headers
   my $format_cent      = get_format_cent( $workbook );
   my $format_vert      = get_format_vert( $workbook );
   my $format_blueheader = get_format_blueheader( $workbook );

   my $TABLE_HEADERS_ROW = 7;
   my @format_table;
   my $col;
   for( $col=0; $col < scalar(@$aref_release_names); $col++ ){
      $format_table[$TABLE_HEADERS_ROW][$col]=$format_vert;
   }
   $format_table[$TABLE_HEADERS_ROW][$col]=$format_cent;
   $col++;  # skip columns "View" & "fileSPEC"
   $format_table[$TABLE_HEADERS_ROW][$col]=$format_cent;
   $col++;  # skip columns "View" & "fileSPEC"
   # Assume as many as 10 components
   my $max_col = $col + 10;
   while( $col <= $max_col ){
      $format_table[$TABLE_HEADERS_ROW][$col++]=$format_vert;
   }
   #
   my $mycol=0;
   my @row_index_nums;
   while( $mycol <= $max_col ){
      $format_table[$TABLE_HEADERS_ROW-1][$mycol] = $format_blueheader;
      $format_table[$TABLE_HEADERS_ROW-2][$mycol] = $format_blueheader;
      push(@row_index_nums, $mycol++);
   }
   # Typical MM has row w/ cell names on  row 8
   unshift(@$aref_table, ['']);
   unshift(@$aref_table, ['']);
   unshift(@$aref_table, ['']);
   unshift(@$aref_table, ['']);
   $aref_table->[$TABLE_HEADERS_ROW-2]= \@row_index_nums;
   $aref_table->[$TABLE_HEADERS_ROW-1]=[  ('bom')x20  ]; 
   my $worksheet = xls_add_sheet_from_aref_of_aref( $workbook, 'table', $aref_table, \@format_table );
   xls_close( $fname_xls, $workbook );

   my @table_rows = (split(/\n/, $t));
   write_file( \@table_rows, 'MM.table.txt' );
   hprint("Manifest contains " .@$aref_table. " total lines.\n");
   exit(0);
}
############    END Main    ####################

sub get_format_cent{
   my $workbook    = shift;
   my $format_cent = $workbook->add_format();
   $format_cent->set_format_properties(
      rotation => 0,
      color    => 'black',
      bold     => 1,
      bg_color => undef,
   );
   $format_cent->set_align('center');
   $format_cent->set_align('vcenter');
   $format_cent->set_bottom();
   return( $format_cent );
}

sub get_format_vert{
   my $workbook    = shift;
   my $format_vert = $workbook->add_format();
   $format_vert->set_format_properties(
      rotation => 90,
      color    => 'black',
      bold     => 1,
      bg_color => '#CCECFF',
   );
   $format_vert->set_align('center');
   $format_vert->set_align('bottom');
   $format_vert->set_bottom();
   return( $format_vert );
}

sub get_format_blueheader{
   my $workbook    = shift;
   my $format_blueheader = $workbook->add_format();
   $format_blueheader->set_format_properties(
      rotation => 0,
      color    => 'black',
      bold     => 0,
      bg_color => '#CCECFF',
   );
   $format_blueheader->set_align('center');
   $format_blueheader->set_align('center');
   $format_blueheader->set_align('center');
   $format_blueheader->set_top();
   $format_blueheader->set_bottom();
   return( $format_blueheader );
}
#--------------------------------------------------------------------------------
# swap out the strings with variables
#--------------------------------------------------------------------------------
sub swapper{
   my $opt_nopdv= shift;
   my $opt_nopvt= shift;
   my $href_cfg = shift;
   my $href_bom = shift;

   #---------------------------------------------
   #   Now that we've built the bom data structure,
   #   replace strings with their variable name
   #   equivalent for each fileSPEC.
   foreach my $cell_name ( keys %$href_bom ){
        if( !defined $href_bom->{$cell_name}{cver} ){
           vhprint(SUPER, "BOM Not defined for cell=>$cell_name\n" );
         dprint(SUPER, scalar(Dumper $href_bom->{$cell_name}) . "\n" );
           prompt_before_continue(SUPER);
        }else{
           foreach my $view_name ( keys $href_bom->{$cell_name}{cver} ){
                  my $aref_fileSPEC_list =  $href_bom->{$cell_name}{cver}{$view_name};
                  my @filenames;
                  foreach my $fileSPEC ( sort @$aref_fileSPEC_list ){
                       $fileSPEC = swap_strings_for_vars( $opt_nopdv, $opt_nopvt, $href_cfg, $fileSPEC );
                       push(@filenames, $fileSPEC);
                  }
                  $href_bom->{$cell_name}{cver}{$view_name} = \@filenames;
           }
        }

        # Sometimes, there's file(s) at same level as the component version.
        #    For those cases, collect files in a 'misc' aref
        if( defined $href_bom->{$cell_name}{misc} ){
           vhprint(SUPER, "MISC defined for cell=>$cell_name\n" );
         dprint(SUPER, scalar(Dumper $href_bom->{$cell_name}) . "\n" );
           prompt_before_continue(SUPER);
               my @filenames;
           foreach my $fileSPEC ( sort @{$href_bom->{$cell_name}{misc}} ){
                    $fileSPEC = swap_strings_for_vars( $opt_nopdv, $opt_nopvt, $href_cfg, $fileSPEC );
                    push(@filenames, $fileSPEC);
           }
               $href_bom->{$cell_name}{misc} = \@filenames;
        }
   }
   
   return( );
}

#--------------------------------------------------------------------------------
#  Walk thru every filename found, and mark with 'x' if it's in the BOM, otherwise
#        mark with '-'. 
#  Data Structure Details
#     Notes: 'cver' represents the removal of the component's version (e.g. 4.20)
#     Notes: $href_fnames <=> $href_file_accounting
#
#     $bom => {
#           'doc' => {
#              'misc' => [ '$fileSPEC' ... ],
#           '$component' => {
#              'cver' => {  
#                 '$view' => [ '$fileSPEC' ... ]
#
#     $href_fnames => {
#          'view1' => {
#             'fname1' => {
#                'component_name1' => 1,
#                'component_name2' => 1
#                ...
#             }
#             'fname2' => {
#                'component_name1' => 1,
#                'component_name2' => 1
#                ...
#             }
#          'view2' => {
#             'fname1' => {
#                'component_name1' => 1,
#                ...
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
#   report__which_components_have_which_files_foreach_view( $release_padder, \@manifest_lines, \%bom, $href_file_accounting, $view, \@components );
sub report__which_components_have_which_files_foreach_view($$$$$$$){
   print_function_header();
   my $release_padder     = shift;
   my $aref_manifest_line = shift;
   my $href_bom           = shift;
   my $href_all_files     = shift;
   my $view               = shift;
   my $aref_components    = shift;

   vhprint(HIGH, "view/components: '$view' ".pretty_print_aref($aref_components)."\n" );
   dprint(HIGH, "Dumping data structure 'href_all_files'\n" );
   prompt_before_continue(HIGH);
   dprint(HIGH, scalar(Dumper $href_all_files) . "\n" );
   prompt_before_continue(HIGH);
   my $href_fnames = $href_all_files->{$view};
   return() unless( defined $href_all_files->{$view} );
   foreach my $fname ( sort keys %$href_fnames ){
      my $line='';
      foreach my $component ( @$aref_components ){
        my $in_bom = "n/a";
        if( !defined $href_all_files->{$view}{$fname} ){
           hprint("not defined view/fname/component: '$view' '$fname' '$component'\n" );
           prompt_before_continue(NONE);
        }
        if( defined $href_all_files->{$view}{$fname}{$component} ){
           if( $href_all_files->{$view}{$fname}{$component} >= 1 ){
               $in_bom = 'x';  # it's in the BOM
           }else{
               $in_bom = '-';  # it's NOT in BOM
           }
        }else{
           $in_bom = '-';
        }
        $line .= "$in_bom,";
      }
      # The 4 valid releases are Eval Kit, Prelim, Pre-Final, Final
      #     Add 4 fields for the valid releases, assuming only Final is used
      $line = "$release_padder"."$view,$view/$fname,${line}";
      dprint(CRAZY,  "$line\n" );
      $line =~ s/,$//;
      push(@$aref_manifest_line, $line );
   }
   delete $href_all_files->{$view};

}

#--------------------------------------------------------------------------------
sub report__which_components_have_which_files_without_view($$$$$$){
   print_function_header();
   my $release_padder     = shift;
   my $aref_manifest_line = shift;
   my $href_bom           = shift;
   my $href_all_files     = shift;
   my $ignore_me          = shift;
   my $aref_components    = shift;
   #-----------------------------------------
   
   foreach my $fname ( sort keys %$href_all_files ){
      my $line='';
      foreach my $component ( @$aref_components ){
        my $in_bom = "n/a";
        dprint(CRAZY+1, "file,component='$fname','$component'\n" );
        if( defined $href_all_files->{$fname}{$component} ){
           if( $href_all_files->{$fname}{$component} >= 1 ){
               $in_bom = 'x';  # it's in the BOM
           }else{
               $in_bom = '-';  # it's NOT in BOM
               #dprint(LOW, "filename <=> component : defined, not in bom\n");
           }
        }else{
           #dprint(LOW, "filename <=> component : not defined\n");
           $in_bom = '-';
        }
        $line .= "$in_bom,";
      }
      # The 4 valid releases are Eval Kit, Prelim, Pre-Final, Final
      #     Add 4 fields for the valid releases, assuming only Final is used
      $line = "$release_padder"."doc,$fname,${line}";
      dprint(SUPER,  "$line\n" );
      $line =~ s/,$//;
      push(@$aref_manifest_line, $line);
   }
}

#--------------------------------------------------------------------------------
#  For a given view (i.e. gds), build a list of all the file names 
#      Then, go build an accounting hash that captures which components
#      have each given filename.
#      Each time this is called, the hash structure adds info for the next view
#      and returns the info in $href_file_accounting
#
#  Hash structure
#  $href_file_accounting = {
#          'view1' => {
#             'fname1' => {
#                'component_name1' => 1,
#                'component_name2' => 1
#                ...
#             }
#             'fname2' => {
#                'component_name1' => 1,
#                'component_name2' => 1
#                ...
#             }
#          'view2' => {
#             'fname1' => {
#                'component_name1' => 1,
#                ...
#--------------------------------------------------------------------------------
sub determine_components_mapping_of_files_in_each_view {
   print_function_header();
   my $href_bom = shift;
   my $view     = shift;
   my $href_file_accounting = shift;

   foreach my $component ( keys %$href_bom ){
         #print "comp = $component\n"; 
         #print "comp,view = $component , $view\n"; 
         #print "component = $component\n";
         my $aref_filenames = $href_bom->{$component}{cver}{$view};
         if( defined $aref_filenames ){
            #hprint( "CVER ($component , $view) => ...\n" );
            #print Dumper \$aref_filenames;
            #print "($component , $view) => [" . join(", ", @$aref_filenames) . "]\n";
            foreach my $fname ( @$aref_filenames ){
               # now that every file has been collected for a given view across all the components
               # use a hash to store which componenst have each file for a given view
               # index scheme:  view_name->filen_ame->component_name
               #print "fname = $fname\n";
               $href_file_accounting->{$view}{$fname}{$component}++;
            }
            #print Dumper $href_file_accounting;
            #prompt_before_continue();
         }
         my $aref_misc_filenames = $href_bom->{$component}{misc};
         if( defined $aref_misc_filenames ){
            #hprint( "MISC ($component , $view) => ...\n" );
            foreach my $fname ( @$aref_misc_filenames ){
               $href_file_accounting->{$fname}{$component}++;
               dprint(CRAZY, scalar(Dumper $href_file_accounting). "\n" );
            }
         }
   }
   return( $href_file_accounting );
}

#--------------------------------------------------------------------
# Build data structure that mimics the release structure.
#--------------------------------------------------------------------
sub build_bom_data_structure($){
   print_function_header();
   my $aref = shift;

   my %bom;
   my $nfs   = qr|[^/]+|;  # nfs = not forward slash
   foreach my $line ( @$aref ){
     if( $line =~ m|$nfs/$| ){
        dprint(CRAZY, "DirectoryL1=>$line\n" );  # skip - cause it's a directory and not a file
     }else{
        # Requirement is that the component is 4 lvls deep in the path SPEC
        # Requirement is that the component is 5 lvls deep in the path SPEC
        if( $line =~ m|^($nfs)/($nfs)/($nfs)/($nfs)/($nfs)/(.+$nfs)$| ){
           dprint(SUPER, "2 REL Line=>$line\n" );  # view found, capture everything after it
           my ($company, $proj, $rel, $component, $view, $bom_content) = ($line =~ m|^($nfs)/($nfs)/($nfs)/($nfs)/($nfs)/(.+$nfs)$| );
           if( $bom_content ){
               my $aref = $bom{$component}{cver}{$view};
               push( @$aref, $bom_content );
               $bom{$component}{cver}{$view} = $aref;
           }
        }elsif( $line =~ m|^($nfs)/($nfs)/($nfs)/($nfs)/($nfs)$| ){
           dprint(SUPER, "3 REL Line=>$line\n" );  #  No view in line...capture everything after component name. 
           my ($company, $proj, $rel, $component, $filename) =
                       ($line =~ m|^($nfs)/($nfs)/($nfs)/($nfs)/($nfs$)| );
           if( $filename ){
               my $aref = $bom{$component}{misc};
               push( @$aref, $filename );
               $bom{$component}{misc} = $aref;
           }
        }else{
           vwprint(MEDIUM,  "Skipping entry in BOM=> '$line'\n" );  # skip - cause it's a directory and not a file
        }
     }
   }
   return( %bom);
}

#--------------------------------------------------------------------------------
sub swap_strings_for_vars($){
   #print_function_header();
   my $opt_nopdv= shift;
   my $opt_nopvt= shift;
   my $href_cfg = shift;
   my $fileSPEC = shift;

   foreach my $string ( sort keys %$href_cfg ){
      my $var = $href_cfg->{$string};
      dprint(CRAZY+10, "BEFORE \$fileSPEC=$fileSPEC, '$string=>$var' \n" );
      $fileSPEC =~ s/\Q$string\E/$var/g;
      dprint(CRAZY+10, "AFTER \$fileSPEC=$fileSPEC, '$string=>$var' \n" );
      unless( $opt_nopdv ){
         $fileSPEC = swap_pdv_decks( $fileSPEC );
      }
      unless( $opt_nopvt ){
         $fileSPEC = swap_timing_corners( $fileSPEC );
      }
   }
   return( $fileSPEC );
}

#-----------------------------------------------------------
#  The names of PDV decs are redictable in SNPS releases,
#     today, for ICV and CALIBRE. So, rather than rely on
#     users to craft tricky regex, let's hardcode/automate
#     it as native feature.
#  With out this subroutine, user will need to add lines
#     such as the following to their CFG
#     drc/=\@{pdvs}/
#     /drc_=/\${pdvs}_
#-----------------------------------------------------------
sub swap_pdv_decks($){
   #print_function_header();
   my $fileSPEC = shift;

     my @pdvs = qw( ant erc drcdm drcdpd drcmini drcpm drcautomotive drcpode drcshdmim esd pad padfc dfm lup );
   
   if( $fileSPEC =~ m/(_wb)*\.(rpt|waive)$/ ){
      dprint(CRAZY+1, "Found PDV file => $fileSPEC \n" );
      foreach my $pdv ( @pdvs ){
         if( $fileSPEC =~ m|$pdv/${pdv}_| ){
            $fileSPEC =~ s|$pdv/${pdv}_|\\\@{pdvs}/\${pdvs}_|;
            dprint(CRAZY+1, "Found PDV '$pdv'=> $fileSPEC \n" );
         }
      }
   }
   return( $fileSPEC );
}

#-----------------------------------------------------------
#  Can't hard code timing corners (easily) in the CFG file
#  So, using regex here instead since they should work for
#  any/all products
#-----------------------------------------------------------
sub swap_timing_corners($){
   #print_function_header();
   my $fileSPEC = shift;
   if( $fileSPEC =~ m/_(ff|ss)g*\dp\d+\S+c_(cbest|cworst|rcbest|rcworst)_(CCbest|CCworst)(_pg)*\.(db|lib|sdf)(.gz)*$/ ){
      if( defined $4 && defined $5 && defined $6 ){
         $fileSPEC =~ s/_(ff|ss)g*\dp\d+\S+c_(cbest|cworst|rcbest|rcworst)_(CCbest|CCworst)(_pg)*\.(db|lib|sdf)(.gz)*$/_\\\@\{pvt_corners\}$4.$5$6/;
      }elsif( defined $4 && defined $5 ){
         $fileSPEC =~ s/_(ff|ss)g*\dp\d+\S+c_(cbest|cworst|rcbest|rcworst)_(CCbest|CCworst)(_pg)*\.(db|lib|sdf)(.gz)*$/_\\\@\{pvt_corners\}$4.$5/;
      }elsif( defined $5 ){
         $fileSPEC =~ s/_(ff|ss)g*\dp\d+\S+c_(cbest|cworst|rcbest|rcworst)_(CCbest|CCworst)(_pg)*\.(db|lib|sdf)(.gz)*$/_\\\@\{pvt_corners\}.$5/;
      }
      dprint(CRAZY+1, "found timing1=> $fileSPEC \n" );
   }
   if( $fileSPEC =~ m/_(ff|ss|tt)g*\dp\d+\S+c(_pg)*\.(db|lib|sdf)(.gz)*$/ ){
      $fileSPEC =~ s/_(ff|ss|tt)g*\dp\d+\S+c(_pg)*\.(db|lib|sdf)$/_\\\@\{pvt_corners\}$2.$3$4/;
      dprint(CRAZY+1, "found timing2=> $fileSPEC \n" );
   }
   if( $fileSPEC =~ m/_tt\dp\d+\S+c_typical(_pg)*\.(db|lib|sdf)(.gz)*$/ ){
      if( defined $3 ){
         $fileSPEC =~ s/_tt\dp\d+\S+c_typical(_pg)*\.(db|lib|sdf)(.gz)*$/_\\\@\{pvt_corners\}.$2$3/;
      }else{
         $fileSPEC =~ s/_tt\dp\d+\S+c_typical(_pg)*\.(db|lib|sdf)(.gz)*$/_\\\@\{pvt_corners\}.$2/;
      }
      dprint(CRAZY+1, "found timing3=> $fileSPEC \n" );
   }
   return( $fileSPEC );
}

#--------------------------------------------------------------------------------
#  If you have 2 release, the row of the MM
#     needs to have a '-' for all the releases
#--------------------------------------------------------------------------------
sub get_MM_row_release_padder($){
   my $aref_release_names = shift;

   my $release_count = @$aref_release_names;
   if( $release_count < 1 ){
      vhprint(LOW, "Release Count=> $release_count\n"  );
      fatal_error( "You must have 1 or more releases defined in the CFG file using variable named 'release_name'!\n" );
   }else{
      my $releases_padder;
      for(my $i=0; $i<$release_count; $i++ ){
         $releases_padder .= "-,";
      }
      return( $releases_padder );
   }
}

#-----------------------------------------------------------
#  Subroutine 'load_config_file' :  
#-----------------------------------------------------------
sub check_config_file ($) {
   print_function_header();
   my $href_cfg = shift;
   my( @warnings );
   return( @warnings );
}

sub load_config_file ($) {
   print_function_header();
   my $fname = shift;

   unless( -e $fname ){
      fatal_error( "Config file doesn't exist: '$fname'\n" ); 
   }
   my $conf = Config::General->new(
       -ConfigFile => $fname,
       -MergeDuplicateBlocks  => TRUE,
   );
   my %config = $conf->getall;

   my @warnings = check_config_file( \%config );
   if( scalar(@warnings) > 0 ){
      wprint( join("\n-W- ", @warnings) );
      print "\n";
   }

   dprint(CRAZY, "Policy CFG file loaded in HREF...\n".
                              scalar(Dumper \%config)."\n" );

   print_function_footer();
   return( \%config, \@warnings );
}


#--------------------------------------------------------------------------------
#  Print the 1st row of the report => title / column headers
#--------------------------------------------------------------------------------
sub report__print_title_row {
   print_function_header();
   my $aref_release_names = shift;
   my (@components)       = @_;

   my $title_row='';
   foreach my $name ( @$aref_release_names ){
      $title_row .= "$name,";
   }
   $title_row .= "view,fileSPEC,";
   foreach my $component ( @components ){
      $title_row .= "$component,";
   }
   dprint(HIGH, "Title Row of XLSX : $title_row\n" );

   return( split(/,/, $title_row) );
}

#--------------------------------------------------------------------------
# Generate stats on how many files are in the company vs component vs view
#     categories. Example for USB3.1 below:
#  $href = {
#          'company' => {
#                         'synopsys' => 1134
#                       },
#          'component' => {
#                           'doc' => 4,
#                           'macro' => 76,
#                           'phy' => 204,
#                           'pma' => 635,
#                           'upcs' => 215
#                         },
#          'proj' => {
#                      'dwc_c10pcie3phy_cuint_a2_tsmc7ff18_x1ns' => 1134
#                    },
#          'view' => {
#                      'atpg' => 169,
#                      'behavior' => 8,
#                      'bscan' => 2,
#                      'dwc_c10pcie3phy_ate_test_bench_appnote.pdf' => 1,
#                      'dwc_c10pcie3phy_cuint_a2_tsmc7ff18_x1ns_databook.pdf' => 1,
#                      'dwc_c10pcie3phy_pcs_databook.pdf' => 1,
#                      'gds' => 10,
#                      'ibis_ami' => 27,
#                      'icv' => 30,
#                      'include' => 47,
#                      'interface' => 13,
#                      'ipxact' => 7,
#                      'lef' => 10,
#                      'netlist' => 7,
#                      'pi' => 23,
#                      'readme_4.01a.txt' => 1,
#                      'rtl' => 127,
#                      'sim' => 23,
#                       'spyglass' => 27,
#                      'synth' => 22,
#                      'testbench' => 180,
#                      'timing' => 388,
#                      'upf' => 10
#                    }
#        };
#     
#--------------------------------------------------------------------------
sub gather_release_stats($){
   print_function_header();
   my $aref=shift;

   my %hash;    my %bom;
   my $cnt=0;
   my $halt = 0;
   foreach my $line ( @$aref ){
      $cnt++;
      #print "line '$cnt' => '$line'\n";
      #prompt_before_continue();
      if( $line =~ m|^([^/]+?)/([^/]+?)/([^/]+?)/([^/]+?)/\S+| ){
         my ($company, $proj, $rel, $component, $view, $file);
         if( $line =~ m|^([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/\S+| ){
            ($company, $proj, $rel, $component, $view)=($line =~ m|^([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)/\S+| );
         }elsif( $line =~ m|^([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)([^/]+)$| ){
            # Detect when there is a file rather than a view on the line of the release content provided
            ($company, $proj, $rel, $component, $file)=($line =~ m|^([^/]+)/([^/]+)/([^/]+)/([^/]+)/([^/]+)$| );
         }
         if( defined $company && $company eq 'synopsys' ){  
            $hash{company}{$company}++;
            $hash{proj}{$proj}++;
            $hash{component}{$component}++;
            #if( $view =~ m/^\S+\.(pdf|xlsx|txt)$/ ){
               #$hash{doc}{$view}++;
            #}else{
               #$hash{view}{$view}++;
            #}
            if( defined $view ){
               $hash{view}{$view}++;
            }elsif( defined $file ){
               viprint(MEDIUM,"Found file! :\n\tline=$line\n\tfile=$file\n" );
               $hash{doc}{$file}++;
            }else{
               hprint("Was not able to categorize this line in the release content =>\n\tline=$line\n\tfile=$file\n" );
            }
         }
     }else{
        vwprint(MEDIUM, "Release filename unexpected, on line '$cnt' => '$line'\n" );
        $halt++;
        if( $halt > 100 ){
           eprint( "Exceed maximum allowed warnings ... skipping res of lines in release file.\n" );
           last;
        }
     }
   }
   
   if( $halt > 100 ){
      hprint( "The path/filename for each entry in the release should start with '". 'synopsys/$proj/$relVer/$cell_name/$view_name/' ."'.\n" );
      prompt_before_continue(NONE);
   }
   
   return( %hash );
}

#------------------------------------------------------------------------------
sub process_cmd_line_args(){
   print_function_header();
     my ( $opt_debug, $opt_verbosity, $opt_help, $opt_nousage_stats,
        $opt_rel, $opt_cfg, $opt_nopdv, $opt_nopvt );
     GetOptions( 
            "rel=s"       => \$opt_rel,
            "cfg=s"       => \$opt_cfg,
            "nopdv"       => \$opt_nopdv,      # when enabled, automagically compact the ICV/Calibre fileSPECs using internal scheme
            "nopvt"       => \$opt_nopvt,      # when enabled, automagically compact the ICV/Calibre fileSPECs using internal scheme
            "debug=s"     => \$opt_debug,      # multi purposed->(1) debug level (2) will trigger re-using JIRA xml file so query can be skipped.
            "verbosity=s" => \$opt_verbosity,
            "nousage"     => \$opt_nousage_stats,    # when enabled, skip logging usage data
            "help"        => \$opt_help,    # Prints help
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

   if( defined $opt_help ){ print_help_msg(); }

   unless( defined $opt_rel || $opt_rel == TRUE ){
       my $msg = "Must specify filename with list of RELEASE files!\n";
       print_help_msg( $msg );
   }
   unless( -e $opt_rel || $opt_rel == TRUE ){
       my $msg = "REL file missing: '$opt_rel' \n";
       fatal_error( $msg );
   }

   return( $opt_debug, $opt_verbosity, $opt_help, $opt_nousage_stats, 
           $opt_rel, $opt_cfg, $opt_nopdv, $opt_nopvt );
};

#------------------------------------------------------------------------------
sub print_help_msg($){
   my $msg = shift;
   
   print "Usage:  $PROGRAM_NAME -cfg <filename> \n  Options: \n";
   print "\t -rel <filename> => list of filenames in an official std SNPS Product Release ...\n";
   print "\t -cfg <filename> => config file with release names and string to replace\n";
   print "\t -nopdv          => turn off automagically compact the ICV/Calibre fileSPECs using internal scheme\n";
   print "\t -nopvt          => turn off automagically compact the PVT corners for timing collateral\n";
   print "\t -v <#>          => user message verbosity \n";
   print "\t -d <#>          => intensity of debug messaging \n";
   print "\t -h|-help        ... prints help msg\n" ;
   if( defined $msg ){ 
       fatal_error( $msg, -1 ); 
   }else{
       exit(0);
   }

}

