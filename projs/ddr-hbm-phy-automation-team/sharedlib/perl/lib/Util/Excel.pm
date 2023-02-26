############################################################
#Utility Excel functions
#
#  Author : James Laderoute
#  Author : Patrick Juliano
#  Author : Bhuvan Challa
############################################################
package Util::Excel;

use strict;
use warnings;

use Cwd;
use Carp;
use File::Spec::Functions qw( catfile );
use Devel::StackTrace;
use File::Basename;
use Getopt::Std;
use Cwd 'abs_path';
use Capture::Tiny qw/capture/;
use MIME::Lite;
use Data::Dumper;
use Excel::Writer::XLSX;
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
$Data::Dumper::Sortkeys = sub { [sort keys %{$_[0]}] };


use Exporter;

our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
  purple_shades    
  blue_shades    
  cyan_shades    
  yellow_shades    
  gold_shades 
  red_shades       
  green_shades
  read_sheet_from_xlsx_file 
  write2Excel
  xls_open
  xls_close
  xls_add_sheet_from_aref_of_aref 
);

# Symbols to export by request 
our @EXPORT_OK = qw();

#------------------------------------------------
sub purple_shades($$){
   my $shade = shift;  # shade value user wants
   my $range = shift;  # num shades

   my $r_lo = 141; my $r_hi = 223;
   my $g_lo =  77; my $g_hi = 222;
   my $b_lo = 179; my $b_hi = 241;

   my $hex = get_hex_for_color_triplet( $r_lo, $r_hi, 
                                        $g_lo, $g_hi, 
                                        $b_lo, $b_hi, 
                                       $shade, $range );
   Util::Messaging::dprint(SUPER, "hex=($hex)\n" );
   return( $hex );
}

#------------------------------------------------
sub cyan_shades($$){
   my $shade = shift;  # shade value user wants
   my $range = shift;  # num shades

   my $r_lo =   7; my $r_hi = 200;
   my $g_lo = 121; my $g_hi = 250;
   my $b_lo = 127; my $b_hi = 252;

   my $hex = get_hex_for_color_triplet( $r_lo, $r_hi, 
                                        $g_lo, $g_hi, 
                                        $b_lo, $b_hi, 
                                       $shade, $range );
   Util::Messaging::dprint(SUPER, "hex=($hex)\n" );
   return( $hex );
}

#------------------------------------------------
sub blue_shades($$){
   my $shade = shift;  # shade value user wants
   my $range = shift;  # num shades

   my $r_lo =  87; my $r_hi = 236;
   my $g_lo = 122; my $g_hi = 240;
   my $b_lo = 193; my $b_hi = 248;

   my $hex = get_hex_for_color_triplet( $r_lo, $r_hi, 
                                        $g_lo, $g_hi, 
                                        $b_lo, $b_hi, 
                                       $shade, $range );
   Util::Messaging::dprint(SUPER, "hex=($hex)\n" );
   return( $hex );
}

#------------------------------------------------
sub red_shades($$){
   my $shade = shift;  # shade value user wants
   my $range = shift;  # num shades

   my $r_lo = 255; my $r_hi = 225;
   my $g_lo =   0; my $g_hi = 200;
   my $b_lo =   0; my $b_hi = 200;

   my $hex = get_hex_for_color_triplet( $r_lo, $r_hi, 
                                        $g_lo, $g_hi, 
                                        $b_lo, $b_hi, 
                                       $shade, $range );
   Util::Messaging::dprint(SUPER, "hex=($hex)\n" );
   return( $hex );
}

#------------------------------------------------
sub green_shades($$){
   my $shade = shift;  # shade value user wants
   my $range = shift;  # num shades

   my $r_lo =   0; my $r_hi = 200;
   my $g_lo = 225; my $g_hi = 225;
   my $b_lo =   0; my $b_hi = 200;

   my $hex = get_hex_for_color_triplet( $r_lo, $r_hi, 
                                        $g_lo, $g_hi, 
                                        $b_lo, $b_hi, 
                                       $shade, $range );
   Util::Messaging::dprint(SUPER, "hex=($hex)\n" );
   return( $hex );
}

#------------------------------------------------
sub yellow_shades($$){
   my $shade = shift;  # shade value user wants
   my $range = shift;  # num shades

   my $r_lo = 255; my $r_hi = 223;
   my $g_lo = 255; my $g_hi = 222;
   my $b_lo =   0; my $b_hi = 200;

   my $hex = get_hex_for_color_triplet( $r_lo, $r_hi, 
                                        $g_lo, $g_hi, 
                                        $b_lo, $b_hi, 
                                       $shade, $range );
   Util::Messaging::dprint(SUPER, "hex=($hex)\n" );
   return( $hex );
}

#------------------------------------------------
sub gold_shades($$){
   my $shade = shift;  # shade value user wants
   my $range = shift;  # num shades

   my $r_lo = 255; my $r_hi = 200;
   my $g_lo = 225; my $g_hi = 152;
   my $b_lo = 129; my $b_hi =   0;

   my $hex = get_hex_for_color_triplet( $r_lo, $r_hi, 
                                        $g_lo, $g_hi, 
                                        $b_lo, $b_hi, 
                                       $shade, $range );
   Util::Messaging::dprint(SUPER, "hex=($hex)\n" );
   return( $hex );
}




# {@tbd@} excel related; convert into a couple of subroutines

#-------------------------------------------------------------------------------------
# read_main_manifest_from_xlsx_file($$){
sub read_sheet_from_xlsx_file($$){
   print_function_header();
   my $xlsx_file_name = shift;
   my $xlsx_sheet_name = shift;

   Util::Messaging::iprint("Reading Sheet from XLS workbook : '$xlsx_file_name' \n");
   unless( -e $xlsx_file_name ){ Util::Messaging::fatal_error("File doesn't exist: '$xlsx_file_name' ... \n" ); }

   use Spreadsheet::Read;
   my $workbook = ReadData( $xlsx_file_name ) || confess "Couldn't parse file ... not in XLSX format!\n";
   unless( defined $workbook->[0]->{sheet}->{$xlsx_sheet_name} ){
       Util::Messaging::fatal_error( "XLSX sheet named '$xlsx_sheet_name' doesn't exist in workbook named '$xlsx_file_name'\n" );
   }

   my $sheet_num = $workbook->[0]->{sheet}->{$xlsx_sheet_name};
   my $sheet = $workbook->[$sheet_num];

   my $aref;
   my $row_counter=0;
   for( my $row=$sheet->{minrow}; $row <= $sheet->{maxrow}; $row++ ){
      my @row;
      for( my $col=$sheet->{mincol}; $col <= $sheet->{maxcol}; $col++ ){
         push( @row, $sheet->{cell}[$col][$row]);
      }
      while( !defined $row[-1] ){
         #Util::Messaging::dprint( CRAZY, pretty_print_aref_of_arefs( \@row ) );
         Util::Messaging::dprint( CRAZY, "Deleting last elem of row in CSV because it's 'undef'\n" );
         delete $row[-1];
         #Util::Messaging::dprint( CRAZY, pretty_print_aref_of_arefs( \@row ) );
         #prompt_before_continue(CRAZY);
      }
      $aref->[$row_counter++] = \@row;
   }
   
   if( $main::DEBUG > MEDIUM){ pretty_print_aref_of_arefs( $aref ); }

   print_function_footer();
   return( $aref );
}

sub xls_open($){
   my $fname_XLS = shift;

   if( -e $fname_XLS ){
      Util::Messaging::iprint( "XLS file exists: '$fname_XLS'...removing\n" );
      unlink( $fname_XLS );
   }

   Util::Messaging::viprint(LOW, "Creating XLS ... \n" );
   my $workbook = Excel::Writer::XLSX->new($fname_XLS);
   Util::Messaging::fatal_error( "FAILED: Unable to create workbook.\n") unless( defined $workbook ); 
   
   return( $workbook );
}

sub xls_close($$){
   my $fname_XLS = shift;
   my $workbook  = shift;
   $workbook->close() or confess "Error closing XLS file: '$fname_XLS'.\n";
   Util::Messaging::iprint("Done writing XLS file: '$fname_XLS'\n" );
}

#--------------------------------------------------------------------------------
# Given a XLS workbook and sheet_name we write out the data to the sheet.
# The data needs to be delivered as an array-ref of an array-ref. Each
# cell in the worksheet corresponds to an element in the data structure.
#
# Create an XLS sheet ... from a 2 dimensional array
#    1st dimension represent rows ... the second dimension the columns
#    $aref[0] = [ 10, 11, 12, 13, 14, 15 ];
#    $aref[1] = [ 20, 21, 22, 23, 24, 25 ];
#    $aref[2] = [ 30, 31, 32, 33, 34, 35 ];
#
#    Columns in XLS are A, B, C, D, E
#    Rows    in XLS are 1, 2, 3, 4, 5
#
#    The $aref will be mapped into the XLS as follows...
#         A    B    C    D    E    F
#    1    10   11   12   13   14   15
#    2    20   21   22   23   24   25
#    3    30   31   32   33   34   35
#--------------------------------------------------------------------------------
#    Theferfore, the mapping above reveals the more detailed 
#         explanation below.
#--------------------------------------------------------------------------------
#         A            B            C            D            E            F
#    1    $aref[0][0]  $aref[0][1]  $aref[0][2]  $aref[0][3]  $aref[0][4]  $aref[0][5]  
#--------------------------------------------------------------------------------
sub xls_add_sheet_from_aref_of_aref($$$$){
   my $workbook   = shift;
   my $sheet_name = shift;
   my $aaref       = shift;
   my $aaref_format= shift;

   vUtil::Messaging::iprint(LOW, "Adding sheet '$sheet_name' to XLS ... \n" );

   my $worksheet = $workbook->add_worksheet( $sheet_name );

   my %col_width;
   my $max_cols=0;
   my $num_rows = @$aaref;
   for( my $r=0; $r < $num_rows; $r++ ){
      my $num_cols = @{$aaref->[$r]};
      $max_cols = get_max_val( $max_cols, $num_cols );
      for( my $c=0; $c < $num_cols; $c++ ){
         my $value = $aaref->[$r][$c];
         my $format= $aaref_format->[$r][$c];
         #$worksheet->write($r, $c, $value, $format);
         $worksheet->write($r, $c, $value, $format );
         $col_width{$c} = get_max_val( length($value), $col_width{$c} );
         Util::Messaging::dprint(INSANE, "(row,col,val)=>($r,$c,$value)\n" );
         Util::Messaging::dprint(INSANE, "(row,col,val,clen)=>($r,$c,$value,".length($value).",".$col_width{$c}.")\n" );
         prompt_before_continue(INSANE);
      }
   }
   #Util::Messaging::dprint(NONE, scalar(Dumper \%col_width) . "\n" );
   #prompt_before_continue(NONE);
   # Auto-size columns
   for( my $c=0; $c < $max_cols; $c++ ){
      unless( isa_num($col_width{$c}) ){
          $col_width{$c} = 10;
       }
       $worksheet->set_column( $c, $c, $col_width{$c});
   }
   return( $worksheet );
}
#------------------------------------------------------------------------------
#
# Example:
#   write2Excel([sort @$bomOnly_aref], $refOnly, $refOnlyComment, $boldFormat); 
#
sub write2Excel($$$$){
    my $file_ref = shift;
    my $sheet    = shift;
    my $comment  = shift; 
    my $format   = shift; 

    my @file = @{$file_ref};

    my $row = 0;
    my $col = 0;
    $sheet->write( $row, $col, $comment, $format );
    $row++;
    foreach my $line ( @file ){
        $sheet->write( $row, $col, $line );
        $row++;
    }
}


################################
# A package must return "TRUE" #
################################

1;
