#!/depot/perl-5.14.2/bin/perl
#!/usr/bin/env perl

use strict;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
# can't find # use Data::Table::Excel qw(tables2xls tables2xlsx xls2tables xlsx2tables);
#use Directory::Scratch::Structured qw(create_structured_tree) ;
#use Data::TreeDumper;

use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/";
use Util::CommonHeader;
use Util::Messaging;

our $PROGRAM_NAME = $0; 
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
#----------------------------------#
our $DEBUG = CRAZY;
#----------------------------------#


BEGIN {  } 
   Main();
END {  }

########  YOUR CODE goes in Main  ##############
sub Main {
   process_cmd_line_args();

   my $fname_xls      = 'MM--lp54-d862-BOM.xlsx';
   my $xls_sheet_name = 'MM--lp54-BOM-v1.18';
   read_master_manifest_from_xlsx_file( $fname_xls, $xls_sheet_name );

   exit(0);
if( 0 ){
use Spreadsheet::Read;
   #$workbook = Spreadsheet::Read->new ( 'MM--lp54-d862-BOM.xlsx' );
   #my $workbook = ReadData->new( $fname_xls );
   my $workbook = ReadData( $fname_xls );
   my $sheet_num = $workbook->[0]->{sheet}->{'MM--lp54-BOM-v1.18'};
   my $sheet = $workbook->[$sheet_num];

   my $aref;
   for( my $row=$sheet->{minrow}; $row <= $sheet->{maxrow}; $row++ ){
      my $row_str = '';
      my @row;
      for( my $col=$sheet->{mincol}; $col <= $sheet->{maxcol}; $col++ ){
         #print "(R,C) =  ($row, $col) => $sheet->{cell}[$col][$row] \n";
         #$row_str .= "$sheet->{cell}[$col][$row],";
         push( @row, $sheet->{cell}[$col][$row]);
      }
   #<STDIN>; 
      $aref->[$row] = \@row;
      #chop($row_str);
      #print "row #$row:  $row_str\n";
   }
   #<STDIN>; 
   #for( my $num = 0; defined $workbook->[$num]; $num++ ){
      #print Dumper $workbook->[$num]; 
      #<STDIN>;
   #}
   
   pretty_print_aref_of_arefs($aref);
}
}
############    END Main    ####################



#-------------------------------------------------------------------------------------
#  pretty_print : 
#-------------------------------------------------------------------------------------
sub pretty_print_aref_of_arefs($){
   my $aref_MM = shift;

   my $tmp1 = $Data::Dumper::Terse;
   my $tmp2 = $Data::Dumper::Indent;

   my $row=0;
   for my $aref_line ( @$aref_MM ){
      $Data::Dumper::Terse=0;
      $Data::Dumper::Indent=0;
      print "row[$row]->" . scalar(Dumper $aref_line) . "\n";
      $row++;
   }

   $Data::Dumper::Indent=$tmp2;
   $Data::Dumper::Terse =$tmp1;
}


#-------------------------------------------------------------------------------------
#  read_master_manifest_from_xlsx_file: 
#-------------------------------------------------------------------------------------
sub read_master_manifest_from_xlsx_file($$){
   #print_function_header();
   my $xlsx_file_name = shift;
   my $xlsx_sheet_name = shift;
#--------------
   use Spreadsheet::Read;
   my $workbook = ReadData( $xlsx_file_name );
   my $sheet_num = $workbook->[0]->{sheet}->{$xlsx_sheet_name};
   my $sheet = $workbook->[$sheet_num];

   my $aref;
   for( my $row=$sheet->{minrow}; $row <= $sheet->{maxrow}; $row++ ){
      my @row;
      for( my $col=$sheet->{mincol}; $col <= $sheet->{maxcol}; $col++ ){
         push( @row, $sheet->{cell}[$col][$row]);
      }
      $aref->[$row] = \@row;
   }
   
   pretty_print_aref_of_arefs($aref);
#--------------
   #print_function_footer();
   return( $aref );
}

#-------------------------------------------------------------------------------------
#  process_cmd_line_args : 
#-------------------------------------------------------------------------------------
sub process_cmd_line_args(){

   my %options=();
   getopts("hd:", \%options);
   my $opt_d = $options{d}; # debug verbosity setting
   my $help  = $options{h};


   if ( $help || ( defined $opt_d && $opt_d !~ m/^\d*$/ ) ){  
      my $msg  = "USAGE:  $PROGRAM_NAME -v # -h \n";
         $msg .= "... add debug statments with -v #\n";
      iprint( $msg );
      exit;
   }   

   # decide whether to alter DEBUG variable
   # '-v' indicates DEBUG value ... set based on user input
   if( defined $opt_d && $opt_d =~ m/^\d*$/ ){  
      $DEBUG = $opt_d;
   }

}

#-------------------------------------------------------------------------------------
#  xls2003_2_csv_converter :  code not tested, copoied from internet, assuem broken
#-------------------------------------------------------------------------------------
sub xls2003_2_csv_converter($$){
   my $fname_xls = shift;
   my $fname_csv = shift;
 
use Spreadsheet::ParseExcel; # for Excel 2003
#use Spreadsheet::XLSX; # for Excel 2007 
   my $source_excel = new Spreadsheet::ParseExcel;
   my $source_book = $source_excel->Parse($fname_xls) or croak "Could not open source Excel file '$fname_xls': $!";
   my $storage_book;
   
   foreach my $source_sheet_number ( 0 .. $source_book->{SheetCount}-1 ){
    my $source_sheet = $source_book->{Worksheet}[$source_sheet_number];
   
    print "--------- SHEET:", $source_sheet->{Name}, "\n";
   
    next unless defined $source_sheet->{MaxRow};
    next unless $source_sheet->{MinRow} <= $source_sheet->{MaxRow};
    next unless defined $source_sheet->{MaxCol};
    next unless $source_sheet->{MinCol} <= $source_sheet->{MaxCol};
   
      foreach my $row_index ( $source_sheet->{MinRow} .. $source_sheet->{MaxRow} ){
        foreach my $col_index ( $source_sheet->{MinCol} .. $source_sheet->{MaxCol} ){
           my $source_cell = $source_sheet->{Cells}[$row_index][$col_index];
           if( $source_cell ){
              #print "( $row_index , $col_index ) =>", $source_cell->Value, "\t";
              print  $source_cell->Value, "\t";
           }
        } 
        print "\n";
      } 
   }
   print "done!\n";

   return( );

}
#-------------------------------------------------------------------------------------
#  xls2007_2_csv_converter :  code not tested, copoied from internet, assuem broken
#-------------------------------------------------------------------------------------
sub xls2007_2_csv_converter($$){
   my $fname_xlsx = shift;
   my $fname_csv  = shift;
 
   use Text::Iconv;
   # convert from codeset utf-8 o windows-1251
   my $converter = Text::Iconv -> new ("utf-8", "windows-1251");

   my $source_excel = new Spreadsheet::ParseExcel->new($fname_xlsx, $converter);
   my $source_book = $source_excel->read($fname_xlsx) or croak "Could not open source Excel file '$fname_xlsx': $!";
   my $storage_book;
   
   foreach my $source_sheet_number ( 0 .. $source_book->{SheetCount}-1 ){
    my $source_sheet = $source_book->{Worksheet}[$source_sheet_number];
   
    print "--------- SHEET:", $source_sheet->{Name}, "\n";
   
    next unless defined $source_sheet->{MaxRow};
    next unless $source_sheet->{MinRow} <= $source_sheet->{MaxRow};
    next unless defined $source_sheet->{MaxCol};
    next unless $source_sheet->{MinCol} <= $source_sheet->{MaxCol};
   
      foreach my $row_index ( $source_sheet->{MinRow} .. $source_sheet->{MaxRow} ){
        foreach my $col_index ( $source_sheet->{MinCol} .. $source_sheet->{MaxCol} ){
           my $source_cell = $source_sheet->{Cells}[$row_index][$col_index];
           if( $source_cell ){
              #print "( $row_index , $col_index ) =>", $source_cell->Value, "\t";
              print  $source_cell->Value, "\t";
           }
        } 
        print "\n";
      } 
   }
   print "done!\n";

   return( );

}
