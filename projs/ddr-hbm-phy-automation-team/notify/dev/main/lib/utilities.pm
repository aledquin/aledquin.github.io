############################################################
#Utility functions
#
#  Author : Patrick Juliano
#  Author : Bhuvan Challa
############################################################
package utilities;

use strict;
use Cwd;
use Carp;
use File::Spec::Functions qw( catfile );
use Devel::StackTrace;
use File::Basename;
use Getopt::Std;
use Cwd 'abs_path';
use Term::ANSIColor;
$Term::ANSIColor::EACHLINE = "\n";  # Resets the color after each newline...
use Capture::Tiny qw/capture/;
use MIME::Lite;
use Data::Dumper;
$Data::Dumper::Sortkeys = sub { [sort keys %{$_[0]}] };

print "-PERL- Loading Package: ". __PACKAGE__ ."\n";

use Exporter;

our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw( 
  halt vhprint viprint vwprint veprint
  dprint iprint hprint wprint eprint fatal_error logger
  header footer print_function_header print_function_footer
  purple_shades blue_shades cyan_shades yellow_shades gold_shades red_shades green_shades
  pretty_print_href pretty_print_aref pretty_print_aref_of_arefs isa_scalar isa_aref isa_href isa_int isa_num
  get_max_val normalize get_the_date append_arrays
  compare_lists report_list_compare_stats
  get_release_target_file_list read_file write_file
  utils__process_cmd_line_args utils__script_usage_statistics send_an_email
  get_call_stack get_caller_sub_name get_subroutine_name 
  run_system_cmd list__get_unique_scalars
  get_first_index grab_contents_inside_brackets
  regex_with_interpolation get_value_from_regex_in_lines get_all_values_from_regex_in_lines
  read_main_manifest_from_xlsx_file
  xls_open xls_close xls_add_sheet_from_aref_of_aref convert_ASCII_Table_2_aref_of_aref
);

# Symbols to export by request 
our @EXPORT_OK = qw();


#----------------------------------#
use constant TRUE  => 1;
use constant FALSE => 0;
use constant NULL_VAL => 'N/A';
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

#-----------------------------------------------------------------
#  Print subroutines 
#-----------------------------------------------------------------
sub vhprint { my $threshold=shift; my $msg="-I- ".shift; if($main::VERBOSITY>=$threshold){ print colored("$msg", 'yellow' ); logger($msg); } }
sub viprint { my $threshold=shift; my $msg="-I- ".shift; if($main::VERBOSITY>=$threshold){ print         "$msg";           logger($msg); } }
sub vwprint { my $threshold=shift; my $msg="-W- ".shift; if($main::VERBOSITY>=$threshold){ print colored("$msg", 'cyan' ); logger($msg); } }
sub veprint { my $threshold=shift; my $msg="-E- ".shift; if($main::VERBOSITY>=$threshold){ print colored("$msg", 'red'  ); logger($msg); } }

sub  iprint { my $str=shift; my $msg="-I- $str"; print "$msg"; logger($msg); }
# hprint -> highlight print : use this to draw user attention to an info message
sub  hprint { my $str=shift; my $msg="-I- $str"; print colored("$msg", 'yellow'); logger($msg); }
sub  wprint { my $str=shift; my $msg="-W- $str"; print colored("$msg", 'cyan'  ); logger($msg); }
sub  eprint { my $str=shift; my $msg="-E- $str"; print colored("$msg", 'red'   ); logger($msg); }
 
sub  fatal_error { my $str =shift; my $msg = "-F- $str"; print STDERR colored("$msg", 'white on_red' ); print STDERR "\n"; logger($msg); exit(); }
sub  dprint { my $threshold=shift; my $str=shift; my $msg = "-D- $str"; if( $main::DEBUG >= $threshold ){ print colored("$msg",'blue'); logger($msg); } } 


#-------------------------------------------------------------------------------------
#  Take the tables produced by the CPAN Text::ASCII 
#-------------------------------------------------------------------------------------
sub convert_ASCII_Table_2_aref_of_aref($){
   my $t = shift;
   my @lines = split(/\n/, $t);
   my @table;
   my $r=0;
   foreach my $row ( @lines ){
      my @cols;
      if( $row =~ m/^\+-*-+$/ ){
         # found a table line break
         @cols = split(/\+[^\+]*/, $row);
         dprint(CRAZY, "found '" . @cols ."' cols in table line break\n" );
      }elsif( $row =~ m/^\|\s*(.*?)\s*\|$/ ){
         @cols = split(/\s*\|\s*/, $1);
         dprint(CRAZY, "Found '" . @cols ."' cols in table data row.\n" );
      }
      dprint(SUPER, pretty_print_aref( \@cols ). "\n" );
      $table[$r] = \@cols;
      $r++;
      halt(CRAZY);
   }
   return( \@table );
}
#--------------------------------------------------------------------------------
# Create an XLS ... from a 2 dimensional array
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
sub xls_open($){
   my $fname_XLS = shift;

   if( -e $fname_XLS ){
      iprint( "XLS file exists: '$fname_XLS'...removing\n" );
      unlink( $fname_XLS );
   }

   viprint(LOW, "Creating XLS ... \n" );
   my $workbook = Excel::Writer::XLSX->new($fname_XLS);
   fatal_error( "FAILED: Unable to create workbook.\n") unless( defined $workbook ); 
   
   return( $workbook );
}

sub xls_close($$){
   my $fname_XLS = shift;
   my $workbook  = shift;
   $workbook->close() or confess "Error closing XLS file: '$fname_XLS'.\n";
   viprint(LOW, "Done writing XLS file: '$fname_XLS'\n" );
}

sub xls_add_sheet_from_aref_of_aref($$$$){
   my $workbook   = shift;
   my $sheet_name = shift;
   my $aaref       = shift;
   my $aaref_format= shift;

   viprint(LOW, "Adding sheet '$sheet_name' to XLS ... \n" );

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
         dprint(INSANE, "(row,col,val)=>($r,$c,$value)\n" );
         dprint(INSANE, "(row,col,val,clen)=>($r,$c,$value,".length($value).",".$col_width{$c}.")\n" );
         halt(INSANE);
      }
   }
   #dprint(NONE, scalar(Dumper \%col_width) . "\n" );
   #halt(NONE);
   # Auto-size columns
   for( my $c=0; $c < $max_cols; $c++ ){
      unless( isa_num($col_width{$c}) ){
          $col_width{$c} = 10;
       }
       $worksheet->set_column( $c, $c, $col_width{$c});
   }
   return( $worksheet );
}

#-------------------------------------------------------------------------------------
#  read_master_manifest_from_xlsx_file: 
#-------------------------------------------------------------------------------------
sub read_main_manifest_from_xlsx_file($$){
   print_function_header();
   my $xlsx_file_name = shift;
   my $xlsx_sheet_name = shift;

   print STDERR "-I- Reading Main Manifest from file : '$xlsx_file_name' \n";
   unless( -e $xlsx_file_name ){ fatal_error("File doesn't exist: '$xlsx_file_name' ... \n" ); }

   use Spreadsheet::Read;
   my $workbook = ReadData( $xlsx_file_name ) || confess "Couldn't parse file ... not in XLSX format!\n";
   unless( defined $workbook->[0]->{sheet}->{$xlsx_sheet_name} ){
       fatal_error( "XLSX sheet named '$xlsx_sheet_name' doesn't exist in workbook named '$xlsx_file_name'\n" );
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
         #dprint( CRAZY, pretty_print_aref_of_arefs( \@row ) );
         dprint( CRAZY, "Deleting last elem of row in CSV because it's 'undef'\n" );
         delete $row[-1];
         #dprint( CRAZY, pretty_print_aref_of_arefs( \@row ) );
         #halt(CRAZY);
      }
      $aref->[$row_counter++] = \@row;
   }
   
   if( $main::DEBUG > MEDIUM){ pretty_print_aref_of_arefs( $aref ); }

   print_function_footer();
   return( $aref );
}

#------------------------------------------------------------------
# get_max_val : return the larger of two numbers
#------------------------------------------------------------------
sub get_max_val($$){
  my $num1 = shift;
  my $num2 = shift;

  my $subname = get_subroutine_name();

  #-------------------------------
  # perform error checking and report issues to user
  # If defined, check if it's a number, else issue warning.
  if( defined $num1 ){
     unless( isa_num($num1) ){
        wprint( "In '$subname', arg1 NAN: '$num1'\n" );
     }
  }else{
     wprint( "In '$subname', arg1 undefined: '$num1'\n" );
  }
  # If defined, check if it's a number, else issue warning.
  if( defined $num2 ){
     unless( isa_num($num2) ){
        wprint( "In '$subname', arg2 NAN: '$num2'\n" );
     }
  }else{
     wprint( "In '$subname', arg2 undefined: '$num2'\n" );
  }

  #-------------------------------
  # Now, return the right value to caller
  if( defined $num1 && defined $num2 ){
     if( isa_num($num1) && isa_num($num2) ){
        return( $num1 ) if( $num1 >= $num2 );
        return( $num2 ) if( $num2 >= $num1 );
        # Should not be possible to reach this line of code below.
        eprint( "In number comparison, error occurred: \n\t arg1=>'$num1' arg2=>'$num2'\n" );
     }else{
        if( isa_num($num1) ){ return( $num1 ) }
        if( isa_num($num2) ){ return( $num2 ) }
        return( NULL_VAL );
     }
  }else{
     # At least 1 argument was not defined, return the value
     #    of the valid argument.
     if( defined $num1 ){
        return( $num1 ); 
     }elsif( defined $num2 ){
        return( $num2 ); 
     }else{
        # Neither argument was defined, return null val
        return( NULL_VAL );
     }
  }
}

#------------------------------------------------------------------
#  normalize : accepts a list of strings, and returns list of
#     strings.  Length of returned strings are the same. Spaces
#     are padded as prefix when necessary.
#------------------------------------------------------------------
sub normalize(@){
   my $max=0;
      my @return_list = ();
   foreach my $string ( @_ ){
      $max = length $string if( $max < length $string );
   } 
   foreach my $string ( @_ ){
      my $padding = $max - length( $string);
      my $normalized=$string;
         my $pad="";
      for( my $i=0; $padding-$i>0; $i++ ){
         $pad .= " ";
      }
      $normalized = $pad.$string;
      push(@return_list, $normalized);
      dprint(CRAZY+2, "normalize -> $string\t= $normalized\n" );
   }
   return( @return_list );
}

#------------------------------------------------------------------
#  logger : store message into a GLOBAL VAR: STDOUT_LOG
#     This is cumulative so that all msgs can be logged and 
#     dumped into a file that captures STDOUT.
#------------------------------------------------------------------
sub logger($){
   my $msg = shift;
   if( defined $main::STDOUT_LOG ){
      $main::STDOUT_LOG .= $msg;
   } 
}

#------------------------------------------------------------------
#  pretty_print :  print 1 aref per line
#------------------------------------------------------------------
sub pretty_print_href($){
   my $href = shift;

   my $tmp1 = $Data::Dumper::Terse;
   my $tmp2 = $Data::Dumper::Indent;
   $Data::Dumper::Terse=0;
   $Data::Dumper::Indent=1;
   my $str =  scalar(Dumper $href);
   $Data::Dumper::Indent=$tmp2;
   $Data::Dumper::Terse =$tmp1;

   $str =~ s/\$VAR1 = //;
   return( $str );
}

#------------------------------------------------------------------
#  pretty_print :  print 1 aref per line
#------------------------------------------------------------------
sub pretty_print_aref($){
   my $aref = shift;

   my $tmp1 = $Data::Dumper::Terse;
   my $tmp2 = $Data::Dumper::Indent;
   $Data::Dumper::Terse=0;
   $Data::Dumper::Indent=0;
   my $str =  scalar(Dumper $aref);
   $Data::Dumper::Indent=$tmp2;
   $Data::Dumper::Terse =$tmp1;

   $str =~ s/\$VAR1 = //;
   return( $str );
}

#------------------------------------------------------------------
#  pretty_print :  print 1 aref per line
#------------------------------------------------------------------
sub pretty_print_aref_of_arefs($){
   my $aref_MM = shift;

   my $str;
   my $row=0;
   for my $aref_line ( @$aref_MM ){
      $str .= "row[$row]->" . pretty_print_aref($aref_line) . "\n";
      $row++;
   }

   return( $str );
}

#-------------------------------------------------------------------------
#  Given a list of scalars or AREFs, combine them into a single
#     array and return an AREF to this new list.
#-------------------------------------------------------------------------
sub append_arrays (@) {
   print_function_header();
   my @elements = @_;

   my (@combined_lists);
   foreach my $elem ( @elements ){
      #print "ref(\$elem) = ref(".ref($elem).")\n";
      if( ref($elem) eq 'ARRAY' ){
         #dprint(SUPER, "Adding ARRAY to array.\n" );
         push( @combined_lists, @$elem );
      }elsif( ref($elem) eq 'SCALAR' ){
         #dprint(SUPER, "Adding scalar to array.\n" );
         push( @combined_lists, $$elem );
      }elsif( ref($elem) eq 'HASH' ){
         #dprint(SUPER, "Attempt made to add a HASH to ARRAY!\n" );
         eprint( Carp::longmess("Error in subroutine 'append_arrays' : attempt made to append HASH to ARRAY!\n") );
      }elsif( ref($elem) eq '' ){
         #dprint(SUPER, "Adding scalar to array.\n" );
         push( @combined_lists, $elem );
      }
   }

   return( \@combined_lists );
}
 

#------------------------------------------------------------------
#  get the array index of the object named
#------------------------------------------------------------------
sub get_first_index($$$){
   my $obj_name  = shift;
   my $aref      = shift;
   my $offset    = shift;

   unless( defined $offset ){ $offset = 0; }
   my ($index) = grep { $aref->[$_] eq $obj_name }  ( $offset .. @{$aref}-1 );

   return( defined $index ? $index : "" );
}

#------------------------------------------------------------------------------
#  REGEX engine only interpolates once, not twice. When needing to use
#     capturing variables (i.e. $1, $2) in search/replace expressions,
#     must perform search + 1st-pass interpolation oustide of the regex, then
#     perform the search/replacement operation.
#------------------------------------------------------------------------------
sub regex_with_interpolation($$$){
   print_function_header();
   my $target = shift;
   my $search = shift;
   my $replace= shift;

   my $orig = $target;
   my $msg  = "original string=> $orig\n\tsearch     => $search\n\treplace    => $replace\n\tnew string => ";
   if( $target =~ m/$search/ ){
      my @match = (undef,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15);
      $replace =~ s/\$(\d)/$match[$1]/g;
      $target =~ s/$search/$replace/g;
      $msg .= "$target\n";
      dprint(INSANE, $msg );
  }

  return( $target );
}

#-----------------------------------------------------------------
#  sub 'get_value_from_regex_in_lines' => return first 
#    value from the first line matching the regex. Subsequent
#    matches are ignored.
#    If there are no matches, return 'N/A' by default.
#    However, user can specify the return value when no match 
#    is found, by passing an optional 3rd argument.
#-----------------------------------------------------------------
sub get_value_from_regex_in_lines($$@){
   print_function_header();
   my $regex      = shift;
   my $aref_lines = shift;
   my $retval_if_no_match = shift;

   unless( defined $retval_if_no_match ){
      $retval_if_no_match = 'N/A'; #  optional to pass this in
   }

   my $captured_val;
   my @captured_values;
   dprint(HIGH, "Searching for regx '$regex' => '\n" );
   foreach my $line ( @$aref_lines ){
      chomp($line);
      dprint(CRAZY, "line=$line\n");
      if( (@captured_values) = $line =~ m/$regex/ ){
          my $cnt=0;
          foreach my $elem ( @captured_values ){
             # deal with PERL's ugly handling of uninitialized vars (i.e. ='')
             #    delete uninitialized elements from the array to avoid
             #    spurious warning messages
             unless( length($elem//'') ){
                dprint(HIGH, "Delete elem ... \n" );
                delete $captured_values[$cnt];
             }
             $cnt++;
          }
          $captured_val = $1;
          dprint(SUPER, "Found regx '$regex' => val ['". join("','", @captured_values) . "']\n" );
          my @vals;
          foreach my $elem ( @captured_values ){
             if( $elem =~ m/\S+/ ){ push(@vals,$elem); }
          }
          @captured_values = @vals;
          last;
      }
   }   

   if( !@captured_values ){
      dprint(HIGH, "Did *NOT* match regx '$regex' ... so it's empty\n" );
   } 

   print_function_footer();
   if( @captured_values > 1){
      return( \@captured_values );
   }else{
      return( $captured_val // $retval_if_no_match );
   }
}

#-----------------------------------------------------------------
#  sub 'get_all_values_from_regex_in_lines' => return first 
#    value from the first line matching the regex. Subsequent
#    matches are ignored.
#    If there are no matches, return 'N/A' by default.
#    However, user can specify the return value when no match 
#    is found, by passing an optional 3rd argument.
#   This function is an extention of get_value_from_regex_in_lines
#-----------------------------------------------------------------
sub get_all_values_from_regex_in_lines($$@){
   print_function_header();
   my $regex      = shift;
   my $aref_lines = shift;
   my $retval_if_no_match = shift;
   

   unless( defined $retval_if_no_match ){
      $retval_if_no_match = 'N/A'; #  optional to pass this in
   }

   my $captured_val;
   my @captured_values; my @all_captured;
   dprint(HIGH, "Searching for regx '$regex' => '\n" );
   foreach my $line ( @$aref_lines ){
      chomp($line);
      dprint(SUPER, "line=$line\n");
      if( (@captured_values) = $line =~ m/$regex/ ){
          my $cnt=0;
          foreach my $elem ( @captured_values ){
             # deal with PERL's ugly handling of uninitialized vars (i.e. ='')
             #    delete uninitialized elements from the array to avoid
             #    spurious warning messages
             unless( length($elem//'') ){
                dprint(HIGH, "Delete elem ... \n" );
                delete $captured_values[$cnt];
             }
             $cnt++;
          }
          $captured_val = $1;
          dprint(HIGH, "Found regx '$regex' => val ['". join("','", @captured_values) . "']\n" );
          my @vals;
          foreach my $elem ( @captured_values ){
             if( $elem =~ m/\S+/ ){ push(@vals,$elem); }
          }
          push(@all_captured,@vals);
          #last;
      }
   }   

   if( !@all_captured ){
      dprint(HIGH, "Did *NOT* find regx '$regex' ... so it's empty\n" );
   } 

   print_function_footer();
   if( @all_captured > 1){
      return( \@all_captured );
   }else{
      return( $captured_val // $retval_if_no_match );
   }
}
 

#-----------------------------------------------------------------
#  Function: 'ExtractTextBlock' => 
#        Search file looking for text block (i.e. multiple lines, all contiguous).
#        The first and last line of the text block are identified using REGEX stored in
#        $start_regex & $end_regex
#  
#        If a user wishes to extract multiple text blocks from the same file, they
#        can use the file pointer position (stored in '$curpos' below) value and 
#        avoid reopening the file & scanning from the first line again. This is valueable/
#        necessary when there's more than a single text block using the same start/end
#        REGEX values.
#  
#        The first time searching for TxtBlk in the file, $curpos should be set to
#        '0' (this ensures scanning starts from the first line). The function
#        returns $curpos, which is the position of the LAST line of the TxtBlk.
#        This value can be passed into subsequent calls to initiate scanning
#        from the last known position. When searching for text blocks that are
#        repeated one-after-the-other, they will be found because the searh
#        begins with the last line of the last block and the ending REGEX is not
#        used until the starting REGEX is found.
#        Using the file pointer position is useful for use cases including:
#           (1) user searching file for multiple identical text blocks
#           (2) user searching file for multiple text blocks, and the ordering is
#               predictable, thus avoiding repeating the file I/O of searching 
#               the beginning of the file multilpe times. This gets costly for
#               big files. Memory usage is minimal as since only a single
#               line is read at a time.
#-----------------------------------------------------------------
sub ExtractTextBlock ($$$$) {
   print_function_header();
   my $fh          = shift;   # file handle opened for read
   my $curpos      = shift;   # position to start reading from file
   my $start_regex = shift;
   my $end_regex   = shift;

   my @text_block_lines = qw( );
   my $func_name = 'ExtractTextBlock';
   my $start     = 'not found';
   my $end       = 'not found';

   dprint($main::DEBUG, "$func_name: \$start_regex='$start_regex'\n");
   dprint($main::DEBUG, "$func_name: \$end_regex='$end_regex'\n");
   my $cnt = 0;
   for( $curpos = tell($fh); my $line = readline($fh); $curpos = tell($fh)) {
      $cnt++;
      if( $line =~ m/$start_regex/ ){
         $start='found';
         dprint($main::DEBUG, "$func_name: found start \$line='$line'");
      }
      next unless( $start eq 'found' );
      if( $start eq 'found' && $end eq 'not found' ){
         dprint($main::DEBUG, "$cnt: $func_name: push \$line='$line'");
         push( @text_block_lines, $line );
      }
      if( $line =~ m/$end_regex/ ){
         $end='found';
         dprint($main::DEBUG, "$func_name: found end \$line='$line'");
         return( $curpos, \@text_block_lines ) if( $end eq 'found' );
      }
   }
   dprint($main::DEBUG, "$func_name: EOF ... return from func\n");


   # Uh-oh, no lines were read from the file.
   if( $start eq 'not found' && $curpos == -1 ){
      if( $main::DEBUG >= MEDIUM ){
         my $call_stack      = get_call_stack();
         eprint( "'$call_stack': Didn't find text block demarcated by \n\tSTART\t= '$start_regex' & \n\tEND\t= '$end_regex'\n");
         if( $main::DEBUG >= SUPER ){
            exit( -1 );
         }
         return( -1, \@text_block_lines );
      }

      # Minimal messaging....
      if( $main::DEBUG > NONE ){
         my $subroutine_name = get_subroutine_name();
         wprint( "'$subroutine_name': no lines read from file ... text block demarcated by '$start_regex' & '$end_regex'\n");
      }
      return( -1, \@text_block_lines );
   }
   print_function_footer();
} # end sub : ExtractTextBlock



##------------------------------------------------------------------
##  sub 'utils__process_cmd_line_args' => enable cmd line switch for  
##       turning on settings for DEBUG,VERBOSITY.
##       Assumes DEBUG and VERBOSITY defined using 'our'
##       in namespace "$main::"
##------------------------------------------------------------------
sub utils__process_cmd_line_args(){

   my %options=();
   getopts("hd:v:", \%options);
   my $help  = $options{h};
   my $opt_d = $options{d}; # debug verbosity setting
   my $opt_v = $options{v};

   if ( $help || ( defined $opt_d && $opt_d !~ m/^\d+$/ ) 
              || ( defined $opt_v && $opt_v !~ m/^\d+$/ ) ){  
      my $PROGRAM_NAME = $main::PROGRAM_NAME || ( caller(0) )[1];
      my $msg  = "USAGE:  $PROGRAM_NAME -d # -v # -h \n";
         $msg .= "... add debug statments with -d #\n";
         $msg .= "... increase verbosity  with -v #\n";
      iprint( $msg );
      exit;
   }   

   # decide whether to alter DEBUG variable
   # '-d' indicates DEBUG value ... set based on user input
   if( defined $opt_d && $opt_d =~ m/^\d+$/ ){  
      $main::DEBUG = $opt_d;
   }

   # decide whether to alter VERBOSITY variable
   # '-v' indicates VERBOSITY value ... set based on user input
   if( defined $opt_v && $opt_v =~ m/^\d+$/ ){  
      $main::VERBOSITY = $opt_v;
   }

}

##------------------------------------------------------------------
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
sub report_list_compare_stats {
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


######################################## Common functions ######################################

##------------------------------------------------------------------
##  sub 'isa_num' => return TRUE (1) if 1st argument is a number
##                    else, return FALSE (0)
##------------------------------------------------------------------
sub isa_num ($){
   my $var = shift;
   unless( defined $var ){
      my $call_stack = get_call_stack(); 
      #wprint( "Undefined value passed : '$call_stack'\n" ) if( $verbosity >= FUNCTIONS ); 
      wprint( "Undefined value passed : '$call_stack'\n" );
   }
   if( $var =~ m/^\+*-*\d+?\.*\d*$/ ){ 
      return( TRUE )
   }else{ 
      return( FALSE ) 
   }
}

##------------------------------------------------------------------
##  sub 'isa_scalar' => return TRUE (1) if 1st argument is an scalar
##                    else, return FALSE (0)
##------------------------------------------------------------------
sub isa_scalar ($){
   my $var = shift;

   if( ref \$var eq 'SCALAR' ){
      return( TRUE )
   }else{ 
      return( FALSE ) 
   }
}

##------------------------------------------------------------------
##  sub 'isa_int' => return TRUE (1) if 1st argument is an integer
##                    else, return FALSE (0)
##------------------------------------------------------------------
sub isa_int ($){
   my $var = shift;
   if( $var =~ m/^\d+$/ ){ 
      return( TRUE )
   }else{ 
      return( FALSE ) 
   }
}

##------------------------------------------------------------------
##  sub 'isa_aref' => return TRUE (1) if 1st argument is an 'ARRAY'
##                    else, return FALSE (0)
##------------------------------------------------------------------
sub isa_aref ($){
   my $var = shift;
   if( "ARRAY" eq ref($var) ){ 
      return( TRUE )
   }else{ 
      return( FALSE ) 
   }
}

##------------------------------------------------------------------
##  sub 'isa_href' => return TRUE (1) if 1st argument is an 'HASH'
##                    else, return FALSE (0)
##------------------------------------------------------------------
sub isa_href ($){
   my $var = shift;
   if( "HASH" eq ref($var) ){ 
      return( TRUE )
   }else{ 
      return( FALSE ) 
   }
}

#------------------------------------------------------------------------------#
# Given an array of scalars, will return unique elements only. 
# my @array = qw(one two three two three);
# my @filtered = list__uniquify_scalars(@array);
#    @filtered = qw(one two three);
#------------------------------------------------------------------------------#
sub list__get_unique_scalars($){
   my $aref_scalars = shift;

   my %seen;
   
   # If arg passed in here is not an AREF, return empty array
   unless( isa_aref($aref_scalars) ){
      return(  );  # empty array 
   }
   # Record the list of UNIQUE elements
   foreach my $elem ( @$aref_scalars ){
      if( ref($elem) eq 'ARRAY' ){ 
         eprint("Expected SCALAR where ARRAY was found while removing redundant elements in list!\n");
         next;
      }
      if( ref($elem) eq 'HASH'  ){ 
         eprint("Expected SCALAR where HASH was found while removing redundant elements in list!\n");
         next;
      }
      $seen{$elem} = 1;
   }
   # Build list of UNIQUE elements that reflects ordering in original list
   my (@ordered_list) = ( );
   foreach my $elem ( @$aref_scalars ){
      if( exists $seen{$elem} ){
         push(@ordered_list, $elem);
         delete $seen{$elem};
      }
   }
   return( @ordered_list );
}

##------------------------------------------------------------------
##  Compare two lists/arrays and return elements common, 
##                    elements in first/second array only
##------------------------------------------------------------------
sub compare_lists($$){
   print_function_header();
   my $aref_L = shift;
   my $aref_R = shift;
   my $aref_empty = [];
   my (%seenL, %seenR, @left, @right);
    
   my $mySubName = get_subroutine_name();
   unless ( isa_aref($aref_L) && isa_aref($aref_R) ){
      eprint( Carp::longmess("Bad argument passed to sub '$mySubName'. \nList 1 => '" . (ref $aref_L) .
                        "'\nList 2 => '" . (ref $aref_R) ));
      return( $aref_empty, $aref_empty, FALSE );
   }else{
      dprint(MEDIUM, "Good arguments passed to sub '$mySubName'\n" );
   }

   foreach ( @$aref_L ){ $seenL{$_}++ }
   foreach ( @$aref_R ){ $seenR{$_}++ }
   @left  = @$aref_L;
   @right = @$aref_R;

   my @bag = sort(@left, @right);
   my (%intersection, %union, %Lonly, %Ronly, %LorRonly);
   my $LsubsetR_status = my $RsubsetL_status = 1;
   my $LequivalentR_status = 0;

   foreach ( keys %seenL ){
      $union{$_}++;
      exists $seenR{$_} ? $intersection{$_}++ : $Lonly{$_}++;
   }

   foreach ( keys %seenR ){
      $union{$_}++;
      $Ronly{$_}++ unless (exists $intersection{$_});
   }

   $LorRonly{$_}++ foreach ( (keys %Lonly), (keys %Ronly) );

   $LequivalentR_status = 1 if ( (keys %LorRonly) == 0);

   foreach ( @left ){
      if( ! exists $seenR{$_} ){
         $LsubsetR_status = 0;
         last;
      }
   }
   foreach ( @right ){
      if( ! exists $seenL{$_} ){
         $RsubsetL_status = 0;
         last;
      }
   }
   my @common = sort keys(%intersection);
   my @firstOnly = sort keys(%Lonly);
   my @secondOnly = sort keys(%Ronly);
   my $bool__lists_equiv = $LequivalentR_status;

   return (\@common, \@firstOnly, \@secondOnly, $bool__lists_equiv);
}

##------------------------------------------------------------------
##  write to a output file
##------------------------------------------------------------------
sub write_file {
   print_function_header();

    my @fileContent = @{$_[0]};
    my $outFileName = $_[1];
    map{chomp $_}@fileContent;
    open(my $fh, ">$outFileName") || die "Unable to write '$outFileName': $!\n";
    print $fh join"\n",@fileContent;
    close($fh);
    iprint("Write successful: '$outFileName'\n");
}

##------------------------------------------------------------------
##  read a file and return file array
##------------------------------------------------------------------
sub read_file {
      print_function_header();
   my $inFileName = $_[0];
   open(my $fh, "$inFileName") || die "Unable to read '$inFileName': $!\n";
   my @fileContent = <$fh>;
   map{chomp $_}@fileContent;
     close($fh);
   iprint("Read successful: '$inFileName'\n");
   return(@fileContent);
}

##------------------------------------------------------------------
##  read a file and return file array
##------------------------------------------------------------------

###################################################################
sub get_release_target_file_list ($) {
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

##------------------------------------------------------------------
##  sub to grab content inside nested brackets
##------------------------------------------------------------------
sub grab_contents_inside_brackets {
   print_function_header();
   my $inputFile = $_[0];
   my %checks;
   my %variables;
   my $test;

   open(my $fh, $inputFile) || die "Unable to open $inputFile: $!\n";
   my $fileVar = do {local $/,<$fh>};
   while( $fileVar =~ /(.*\{((?>[^{}]+)|(?R))*\})/g ){
      my $theSet = $1;
      $test = "$test|$theSet";
      while( $theSet =~ /(.*)\{(([^{}]|(?R))+)\}/g ){
         my ($category, $innerSet1) = ($1,$2);
         while( $innerSet1 =~ /(.*)\{(([^{}]|(?R))+)\}/g ){
            my $type = $1;
            my @checks = split(/\n/,$2);
            foreach my $check ( @checks ){
               $check =~ s/\s+//g;
               $type =~ s/\s+//g;
               next if ($type eq "");
               next if($check =~ /^$/g);
               my($theCheck,$cond) = split(/\=\>/,$check);
               $category =~ s/\s+//g;
               $theCheck =~ s/\s+//g;
               $checks{$category}{$type}{$theCheck} = $cond;
            }
         }
      }
   }
   $fileVar =~ s/$test//g;
   my @allVars = split(/\n/,$fileVar);
   foreach my $vars ( @allVars ){
      $vars =~ s/\s+//g;
      next if($vars =~ /^.\#/);
      next if($vars =~ /^$/g);
      my($name,$value) = split(/\=/,$vars);
      $variables{$name} = $value;
   }

   return (\%variables,\%checks);
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
   dprint(SUPER, "hex=($hex)\n" );
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
   dprint(SUPER, "hex=($hex)\n" );
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
   dprint(SUPER, "hex=($hex)\n" );
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
   dprint(SUPER, "hex=($hex)\n" );
   return( $hex );
}

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
   dprint(SUPER, "hex=($hex)\n" );
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
   dprint(SUPER, "hex=($hex)\n" );
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
   dprint(SUPER, "hex=($hex)\n" );
   return( $hex );
}


#------------------------------------------------
sub get_hex_for_color_triplet($$$$$$$$){
   my $r_lo = shift; my $r_hi = shift; 
   my $g_lo = shift; my $g_hi = shift; 
   my $b_lo = shift; my $b_hi = shift; 
   my $shade= shift; my $range= shift;

   return( "000000" ) unless( isa_int( $shade) && isa_int( $range ) && int($shade) >= 1 && int($range) >= 1  && $shade <= $range );
   my $r = $r_lo+ int( ($shade-1) * my_range_interpolate( $r_lo, $r_hi, $range-1) );
   my $g = $g_lo+ int( ($shade-1) * my_range_interpolate( $g_lo, $g_hi, $range-1) );
   my $b = $b_lo+ int( ($shade-1) * my_range_interpolate( $b_lo, $b_hi, $range-1) );

   if( $r >255 ){ $r=255; }
   if( $g >255 ){ $g=255; }
   if( $b >255 ){ $b=255; }
   my $dec = sprintf("(r,g,b)=(%3d,%3d,%3d)", $r, $g, $b);
   my $hex = sprintf("%2X%2X%2X", $r, $g, $b);
   dprint(SUPER, "$dec\t hex=($hex)\n" );
   return( $hex );
}

##------------------------------------------------------------------
##  Gather run statistics for the script
##------------------------------------------------------------------
sub my_range_interpolate($$$){
   my $min = shift;
   my $max = shift;
   my $stp = shift;

   #unless( $min 
   my $val = ($max-$min)/$stp;

   dprint(CRAZY, "[step size => min,max,#parts]=[$val => $min,$max,$stp]\n");

   return( $val );
}

##------------------------------------------------------------------
##  Gather run statistics for the script
##     First argument is name of the script.
##     Second argument (optional) is an aref, used
##          to capture the cmd line arguments and log them.
##------------------------------------------------------------------
sub utils__script_usage_statistics {
   print_function_header();
   my $script   = shift;

   my $mySubName = get_subroutine_name();
   my $call_stack = get_call_stack(); 
   my $aref_args;
   my $body;
   if( defined $_[0] ){
      $aref_args = $_[0];
      if( isa_aref($aref_args) ){
         $body  = "'$mySubName': 2nd argument passed: \n\t==>". join(",", @$aref_args) ;
      }else{
         $body  = "'$mySubName': 2nd argument needs to be an AREF but is not. Check value-> '$aref_args'" ;
         $aref_args= [ "Invalid parameter passed into $mySubName ... No cmd line args captured." ];
      }
      dprint(CRAZY, "$call_stack\n\t$body\n" );
      halt(CRAZY);
   }else{
      $body  = "2nd argument not found: \n\t". join(",", @_) ."\n";
      viprint(HIGH, "$call_stack\n\t..in '$mySubName'\n\t...$body" );
      $aref_args= [ "No cmd line args captured." ];
   }

   my $bscript = basename($script);
   $bscript    =~ s/\..*//g;
   my $csvStats= "/u/juliano/usage_stats/$bscript.csv";
   my $admins  = "juliano\@synopsys.com";
   chomp(my $machine = `hostname`);
   my $curdir = getcwd();
   my ($site) = ($machine =~ /^([a-z0-9]{4})/i);
   my ($day,$month,$date,$time,$year) = get_the_date();
   #emailing admins run information
   #Format: To, subject, content
   chomp(my $dateCmd = `date`);
      $body .= "User: $ENV{USER}\nScript: $script\nArgs: ".
      join(":",@$aref_args)."\nSite: $site\n";
      $body .= "Machine: $machine\nRun Dir: $curdir\nDate: $dateCmd";
   my $msg = "$year,$month,$date,$site,$script,$ENV{USER},$machine,$curdir,".join(":",@$aref_args)."\n";
   if( open(STATS, ">>$csvStats") ){
      #Format: Year month date site machine user script path
      print STATS $msg;
      close( STATS );
      chmod 0775, $csvStats;
      send_stats($admins,"$bscript Usage Stats",$body);
   }else{
      $body .= "\nAttention: Couldn't write stats to $csvStats";
      send_stats( $admins, "ATTN: $bscript Usage Stats. Unable to write to stats.csv", $body );
   }
}

#-------------------------------------------------------------------
# Grab the date time info
#-------------------------------------------------------------------
sub get_the_date(){
   chomp(my $dateCmd = `date`);
   my ($day,$month,$date,$time,$year) = ($dateCmd =~ /^([\w]+)\s+([\w]+)\s+([\d]+)\s+([\d\:]+)\s+[a-z]+\s+([\d]+)/i);
   return($day,$month,$date,$time,$year);
}

##------------------------------------------------------------------
##  Send gathered statistics to admin
##------------------------------------------------------------------
sub send_stats($$$){
   my ($theTo, $subject, $body) = @_;
   my $from = $ENV{USER} . '@' . 'synopsys.com';
   my $fileName; my $msg;
   $msg = MIME::Lite->new(
      From     => $from,
      To       => $theTo,
      Subject  => $subject,
      Data     => "$body\n", 
      Type     => "multipart/mixed" 
   );
   $msg->attach(
      Type  => "text",
      Data  => $body,
   );
   $msg->send(); 
}

#-----------------------------------------------------------------
sub convert_email_text_to_html($){
   my $msg_txt = shift;

# Convert the message to HTML.
my $html = $msg_txt;

#$html =~ s/&/&amp;/g;
#$html =~ s/</&lt;/g;
#$html =~ s/>/&gt;/g;

# Add header and formatting.
$html = <<"__EOI__";
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
<title>NOTIFY flow => ... </title>
<style>
table, th, td {
  border: 1px solid black;
}
</style>
</head>
<body>
$html
</p>
</body>
</html>
__EOI__
   use Encode qw(encode);

   # Convert to bytes.
   my $msg_html = encode("UTF-8", $html);
   return( $msg_html );
}

#-----------------------------------------------------------------
sub send_an_email(@){
   print_function_header();
   my ($to,$cc,$subject,$body,$from) = @_;

  unless( defined $from && $from =~ m/\w+/ ){
     $from = "$ENV{USER}\@synopsys.com";
  }

  dprint(CRAZY, "Email diagnostics:\n
\t From     => $from,
\t To       => $to,
\t Cc       => $cc,
\t Subject  => $subject" );

  $body = convert_email_text_to_html( $body );
   my $msg = MIME::Lite->new(
      From     => $from,
      To       => $to,
      Cc       => $cc,
      Subject  => $subject,
      Type     => 'text/html',
      #Type     => "multipart/mixed" 
      Data     => "$body\n", 
   );
   $msg->send(); 

   $msg = MIME::Lite->new(
      From     => $from,
      To       => 'juliano',
      Cc       => 'juliano',
      Subject  => $main::PROGRAM_NAME ."=>". $subject,
      Data     => "<pre>   FROM: $from\n   TO  : $to\n   CC  : $cc\n</pre>$body\n", 
      Type     => 'text/html',
   );
   $msg->send(); 
}

#-----------------------------------------------------------------
#  sub 'run_system_cmd' => runs a system call using the best
#    method found over the years. Alternative used in the past
#    include:  backticks (i.e. `cmd`, qx/cmd/, system ). All
#    of the alternative had various issues with different use
#    cases and hasd drawbacks;  only 'capture' proved to
#    handle STDOUT, STDERR, and Exit Val properly, always.
#
#    Can provide verbosity to control display of 
#    cmd's STDOUT & STDERR.  Return the output of the cmd
#    along with the cmd's exit value.
#-----------------------------------------------------------------
sub run_system_cmd ($$) {
   my $cmd       = shift;
   my $verbosity = shift;

   my $call_stack = get_call_stack(); 
   iprint( "Subroutine Call Stack: '$call_stack'\n" ) if( $verbosity >= FUNCTIONS );
   iprint( "Running system command : '$cmd' ... \n" ) if( $verbosity >= LOW );

   my ($stdout, $stderr, $exit_val) = capture { system( $cmd ); };
   chomp( $stdout );
   chomp( $stderr );
   #my $stdout   = `$cmd 2>&1 `;  # capture stdout, stderr
   #my $exit_val = $?; # save exit status
   iprint( "System CMD details!\n\tCmd\t===>'$cmd'\n\tStdOut\t===>'$stdout'\n\tStdErr\t===>'$stderr'\n\tExit Val===>'$exit_val'\n" ) if( $verbosity >= HIGH && $exit_val == 0); 

  #-----------------------------------------------------------------------
  #  +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
  #  | 15| 14| 13| 12| 11| 10|  9|  8|  7|  6|  5|  4|  3|  2|  1|  0|
  #  +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
  #  
  #   \-----------------------------/ \-/ \-------------------------/
  #              Exit code            core     Signal that killed
  #              (0..255)            dumped         (0..127)
  #                                  (0..1)
  #-----------------------------------------------------------------------
   if( $verbosity >= LOW ){
      if( $exit_val == -1 ){ # Failed to start program / error of the wait(2) system call
         die "Failed to execute '$cmd': $!";
      }elsif( $exit_val & 127 ){ # Check for non-zero signal
         die "'$cmd' died with signal", ($exit_val & 127), ($exit_val & 128) ? 'with' : 'without', " coredump";
      }else{ # No kill signal, check exit code.
         my $exit_code = $exit_val >> 8; # This is the number you said to be 255.
         if( $exit_code == 255 ){
            confess("Failed to run \"$cmd\": $!");
            exit $exit_code;
         }else{
            # can do additional checks for other exit codes if desired
         }
      }

      if( $exit_val ){
         $stdout = ''  unless( defined $stdout );
         eprint( "System CMD failed!\n\tCmd\t===>'$cmd'\n\tStdOut\t===>'$stdout'\n\tStdErr\t===>'$stderr'\n\tExit Val===>'$exit_val'\n" );
      }else{
         print( "Success!\n" );
      }
   }
 
   return( "$stdout\n$stderr", $exit_val );
}

#-----------------------------------------------------------------
#  sub 'get_call_stack' => prints out the hierarchy of
#    calling subroutines.
#-----------------------------------------------------------------
sub get_call_stack {
   my(   $package,   $filename, $line,       $subroutine, $hasargs,
   $wantarray, $evaltext, $is_require, $hints,      $bitmask
   ) = caller(0);

   my $subname;
   my @subroutines;
   for( my $i=0; (caller($i))[3]; $i++){
      $subname =  ( caller($i) ) [3];
      $subname =~ s/main:://g;
      #print "\$i = '$i' : caller(\$i)[3] : " . (caller($i))[3] .  "\n";
      #print "subname \ $subname\n";
      push(@subroutines, $subname);
   }
   @subroutines = reverse @subroutines;
   pop(@subroutines);
   my $callstack = "";
   my $spacer = " -> ";
   foreach my $name ( @subroutines ){
      $callstack .= "$name" . $spacer;
   }
   $callstack =~ s/$spacer$//;
   return( $callstack );
}

#-----------------------------------------------------------------
#  sub 'get_subroutine_name': get the name of the subroutine
#     that called this sub.
#-----------------------------------------------------------------
sub get_subroutine_name(){
   my $subroutine_name = ( caller(1) )[3];
   $subroutine_name =~ s/main:://ig;
   return( $subroutine_name );
}
 
#-----------------------------------------------------------------
#  sub 'get_caller_sub_name': get the name of the subroutine
#     that called the subroutine that invoked this sub.
#-----------------------------------------------------------------
sub get_caller_sub_name(){
   my $subroutine_name = ( caller(2) )[3];
   $subroutine_name =~ s/main:://ig;
   return( $subroutine_name );
}

#-----------------------------------------------------------------
#  sub 'print_function_header'
#-----------------------------------------------------------------
sub print_function_header(){
   my $subroutine_name =   "'" . get_caller_sub_name() . "'";
   my $str;
   $str=sprintf( "-" x20 . " Starting Function: %-25s" . "-" x20 . "\n", $subroutine_name );
   if( $main::DEBUG >= FUNCTIONS ){
      iprint( $str );
   }
   halt(INSANE);
}

#-----------------------------------------------------------------
#  sub 'halt'
#-----------------------------------------------------------------
sub halt($){
    my $halt_level = shift;
    if( defined $halt_level && isa_int($halt_level) && $main::DEBUG >= $halt_level ){
       eprint( "Hit ENTER to continue ..." );
       <STDIN>;
    }
}

#-----------------------------------------------------------------
#  sub 'print_function_footer'
#-----------------------------------------------------------------
sub print_function_footer(){
   my $subroutine_name =   "'" . get_caller_sub_name() . "'";
   my $str;
   $str=sprintf( "-" x20 . " Ending Function:   %-25s" . "-" x20 . "\n", $subroutine_name );
   if( $main::DEBUG >= FUNCTIONS ){
      iprint( $str );
   }
   halt(INSANE);
}

#-----------------------------------------------------------------
#  sub 'header'
#-----------------------------------------------------------------
sub header(){
   my $PROGRAM_NAME = ( caller(0) )[1];
   print STDERR "\n\n#######################################################\n";
   print STDERR "###  Date , Time   : " . localtime() . "\n";
   print STDERR "###  Begin Running : '$PROGRAM_NAME'\n";
   if( defined $main::AUTHOR ){
      print STDERR "###  Author        : '$main::AUTHOR'\n";
   }
   print STDERR "#######################################################\n\n";
}

#-----------------------------------------------------------------
#  sub 'footer'
#-----------------------------------------------------------------
sub footer(){
   print STDERR "\n\n#######################################################\n";
   print STDERR "###  Goodbye World\n";
   my $PROGRAM_NAME = ( caller(0) )[1];
   print STDERR "###  End Running : '$PROGRAM_NAME'\n";
   print STDERR "#######################################################\n\n";
}

################################
# A package must return "TRUE" #
################################

1;

