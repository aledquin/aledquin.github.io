############################################################
#
# Miscellaneous Utility functions
#
#  Author : Patrick Juliano
#  Author : Bhuvan Challa
#  Author : James Laderoute
############################################################
package Util::Misc;

use strict;
use warnings;

use Cwd;
use Carp;
use File::Spec::Functions qw( catfile );
use Devel::StackTrace;
use File::Basename;
use File::Copy;
use Text::ASCIITable;
use Term::ANSIColor;
use Getopt::Std;
use Cwd 'abs_path';
use Capture::Tiny qw/capture tee/;
use MIME::Lite;
use Data::Dumper;
use Time::HiRes qw( usleep gettimeofday tv_interval clock_gettime clock_getres);
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/";
use Util::CommonHeader;
use Util::Messaging;

$Data::Dumper::Sortkeys = sub { [sort keys %{$_[0]}] };
my $START_TIME=0;

use Exporter;

our @ISA   = qw(Exporter);

# Symbols (subs or vars) to export by default 
our @EXPORT    = qw(
  alert
  prompt_before_continue
    reconcileDuplicates
    arrayContains
  header footer 
  print_function_header print_function_footer 
  pretty_print_href pretty_print_aref pretty_print_aref_of_arefs 
  isa_scalar isa_aref isa_href isa_int isa_num
  get_max_val
  get_min_val
  normalize   
  get_the_date 
  append_arrays 
  compare_lists 
  read_file_aref read_file write_file is_safe_to_write_file
  utils__process_cmd_line_args utils__script_usage_statistics 
  send_an_email 
  get_call_stack get_caller_sub_name get_subroutine_name 
  run_system_cmd  
  run_system_cmd_array
  unique_scalars 
  get_first_index grab_contents_inside_brackets
  regex_with_interpolation 
  get_value_from_regex_in_lines 
  get_all_values_from_regex_in_lines
  convert_ASCII_Table_2_aref_of_aref
  get_hex_for_color_triplet
  ExtractTextBlock
  trim da_copy check_p4_quota 
  check_config_file
  parse_project_spec
  get_username
  get_release_version
  da_is_script_in_list_of_obsolete_versions
  da_get_toolname
  da_findSubdirs
  prompt_user_yesno
  da_is_latest_version
  );

# ljames comments from meeting with patrick
# get_first_index grab_contents_inside_brackets # parsing
#  regex_with_interpolation 
#  get_value_from_regex_in_lines 
#  get_all_values_from_regex_in_lines # parsing files regex

# Symbols to export by request 
our @EXPORT_OK = qw();

# _check_tcl_config_file is an internal function used by the exported
# function named check_config_file()
#
# Arguments:
#   filename:
#       The full path to a config file
#
# Returns:
#   0 = parsed ok, no issues
#   1 = Did not parse as expected
#
sub _check_tcl_config_file($) {
    my $filename = shift;

    my $tclsh_exe = "/depotbld/RHEL5.5/tcl8.5.2/bin/tclsh8.5";
   
    # Since we are expecting a tcl script here for our config file, we can
    # simply use the tcl parser on this file to see if it passes or not.
    #
    my ($stdout, $exit_value) = run_system_cmd("$tclsh_exe $filename", $main::VERBOSITY );
    if ( $exit_value ) {
        vwprint(LOW, $stdout);
    }

    if ( $exit_value != 0 ) {
        $exit_value = 1;
    }

    return $exit_value;
}

#-------------------------------------------------------------------------------------
# check_confg_file takes a filename and verifies that it's valid
#
# Arguments:
#   filename:
#       The full path to a config file
#   format:
#       [optional] Specifies the type of config it is. Ex. TCL, JSON, other. 
#
#  Returns:
#       0 = success, no failures
#       1 = failed, invalid config 
#      -1 = the filename does not exist
#      -2 = this subroutine does not support the supplied format
#-------------------------------------------------------------------------------------
sub check_config_file($;$) {
    print_function_header();
    my $filename = shift;
    my $format   = shift || "TCL"; # the default is TCL

    return -1 if ( ! -e $filename ); 
    if ( $format ne "TCL" ) {
        Util::Messaging::eprint("check_config_file does not currently support config type '$format'\n");
        return -2;
    }

    my $status = _check_tcl_config_file( $filename );

    print_function_footer();

    return $status;
}

#-------------------------------------------------------------------------------------
#  Take the tables produced by the CPAN Text::ASCII 
#  parses ascii art and converts to a perl table and returns it
#-------------------------------------------------------------------------------------
#{@tbd} cvt aref_of_aref to Ascii Table, did we want to rename this?

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
         Util::Messaging::dprint(CRAZY, "found '" . @cols ."' cols in table line break\n" );
      }elsif( $row =~ m/^\|\s*(.*?)\s*\|$/ ){
         @cols = split(/\s*\|\s*/, $1);
         Util::Messaging::dprint(CRAZY, "Found '" . @cols ."' cols in table data row.\n" );
      }
      Util::Messaging::dprint(SUPER, pretty_print_aref( \@cols ). "\n" );
      $table[$r] = \@cols;
      $r++;
      prompt_before_continue(CRAZY);
   }
   return( \@table );
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
        Util::Messaging::wprint( "In '$subname', arg1 NAN: '$num1'\n" );
     }
  }else{
     Util::Messaging::wprint( "In '$subname', arg1 undefined: '$num1'\n" );
  }
  # If defined, check if it's a number, else issue warning.
  if( defined $num2 ){
     unless( isa_num($num2) ){
        Util::Messaging::wprint( "In '$subname', arg2 NAN: '$num2'\n" );
     }
  }else{
     Util::Messaging::wprint( "In '$subname', arg2 undefined: '$num2'\n" );
  }

  #-------------------------------
  # Now, return the right value to caller
  if( defined $num1 && defined $num2 ){
     if( isa_num($num1) && isa_num($num2) ){
        return( $num1 ) if( $num1 >= $num2 );
        return( $num2 ) if( $num2 >= $num1 );
        # Should not be possible to reach this line of code below.
        Util::Messaging::eprint( "In number comparison, error occurred: \n\t arg1=>'$num1' arg2=>'$num2'\n" );
     }else{
        if( isa_num($num1) ){ return( $num1 ) }
        if( isa_num($num2) ){ return( $num2 ) }
        return( NULL_VAL );
     }
  }else{
     # At least 1 argument was not defined, return the value
     #    of the valid argument.
     if( defined $num1 && isa_num($num1) ){
        return( $num1 ); 
     }elsif( defined $num2 && isa_num($num2) ){
        return( $num2 ); 
     }else{
        # Neither argument was defined and also a number, so return null val
        return( NULL_VAL );
     }
  }
}


#------------------------------------------------------------------
# get_min_val : return the smaller of two numbers
#------------------------------------------------------------------
sub get_min_val($$){
  my $num1 = shift;
  my $num2 = shift;

  my $subname = get_subroutine_name();

  #-------------------------------
  # perform error checking and report issues to user
  # If defined, check if it's a number, else issue warning.
  if( defined $num1 ){
     unless( isa_num($num1) ){
        Util::Messaging::wprint( "In '$subname', arg1 NAN: '$num1'\n" );
     }
  }else{
     Util::Messaging::wprint( "In '$subname', arg1 undefined: '$num1'\n" );
  }
  # If defined, check if it's a number, else issue warning.
  if( defined $num2 ){
     unless( isa_num($num2) ){
        Util::Messaging::wprint( "In '$subname', arg2 NAN: '$num2'\n" );
     }
  }else{
     Util::Messaging::wprint( "In '$subname', arg2 undefined: '$num2'\n" );
  }

  #-------------------------------
  # Now, return the right value to caller
  if( defined $num1 && defined $num2 ){
     if( isa_num($num1) && isa_num($num2) ){
        return( $num1 ) if( $num1 <= $num2 );
        return( $num2 ) if( $num2 <= $num1 );
        # Should not be possible to reach this line of code below.
        Util::Messaging::eprint( "In number comparison, error occurred: \n\t arg1=>'$num1' arg2=>'$num2'\n" );
     }else{
        if( isa_num($num1) ){ return( $num1 ) }
        if( isa_num($num2) ){ return( $num2 ) }
        return( NULL_VAL );
     }
  }else{
     # At least 1 argument was not defined, return the value
     #    of the valid argument.
     if( defined $num1 && isa_num($num1) ){
        return( $num1 ); 
     }elsif( defined $num2 && isa_num($num2) ){
        return( $num2 ); 
     }else{
        # Neither argument was defined and also a number, so return null val
        return( NULL_VAL );
     }
  }
}



# {@tbd@} ; rename ; purpose is explained in comment
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
      Util::Messaging::dprint(CRAZY+2, "normalize -> $string\t= $normalized\n" );
   }
   return( @return_list );
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
# {@tbd@} explain better, show example; what does it really do, mayber rename
#-------------------------------------------------------------------------
#  Given a list of scalars or AREFs, combine them into a single
#     array and return an AREF to this new list.
#-------------------------------------------------------------------------
sub append_arrays(@){
   print_function_header();
   my @elements = @_;

   my (@combined_lists);
   foreach my $elem ( @elements ){
      #print "ref(\$elem) = ref(".ref($elem).")\n";
      if( ref($elem) eq 'ARRAY' ){
         #Util::Messaging::dprint(SUPER, "Adding ARRAY to array.\n" );
         push( @combined_lists, @$elem );
      }elsif( ref($elem) eq 'SCALAR' ){
         #Util::Messaging::dprint(SUPER, "Adding scalar to array.\n" );
         push( @combined_lists, $$elem );
      }elsif( ref($elem) eq 'HASH' ){
         #Util::Messaging::dprint(SUPER, "Attempt made to add a HASH to ARRAY!\n" );
         Util::Messaging::eprint( Carp::longmess("Error in subroutine 'append_arrays' : attempt made to append HASH to ARRAY!\n") );
      }elsif( ref($elem) eq '' ){
         #Util::Messaging::dprint(SUPER, "Adding scalar to array.\n" );
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
      Util::Messaging::dprint(INSANE, $msg );
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
      $retval_if_no_match = NULL_VAL; #  optional to pass this in
   }

   my $captured_val;
   my @captured_values;
   Util::Messaging::dprint(HIGH, "Searching for regx '$regex' => '\n" );
   foreach my $line ( @$aref_lines ){
      chomp($line);
      Util::Messaging::dprint(CRAZY, "line=$line\n");
      if( (@captured_values) = $line =~ m/$regex/ ){
          my $cnt=0;
          foreach my $elem ( @captured_values ){
             # deal with PERL's ugly handling of uninitialized vars (i.e. ='')
             #    delete uninitialized elements from the array to avoid
             #    spurious warning messages
             unless( length($elem//'') ){
                Util::Messaging::dprint(HIGH, "Delete elem ... \n" );
                delete $captured_values[$cnt];
             }
             $cnt++;
          }
          $captured_val = $1;
          Util::Messaging::dprint(SUPER, "Found regx '$regex' => val ['". join("','", @captured_values) . "']\n" );
          my @vals;
          foreach my $elem ( @captured_values ){
             if( $elem =~ m/\S+/ ){ push(@vals,$elem); }
          }
          @captured_values = @vals;
          last;
      }
   }   

   if( !@captured_values ){
      Util::Messaging::dprint(HIGH, "Did *NOT* match regx '$regex' ... so it's empty\n" );
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
   Util::Messaging::dprint(HIGH, "Searching for regx '$regex' => '\n" );
   foreach my $line ( @$aref_lines ){
      chomp($line);
      Util::Messaging::dprint(SUPER, "line=$line\n");
      if( (@captured_values) = $line =~ m/$regex/ ){
          my $cnt=0;
          foreach my $elem ( @captured_values ){
             # deal with PERL's ugly handling of uninitialized vars (i.e. ='')
             #    delete uninitialized elements from the array to avoid
             #    spurious warning messages
             unless( length($elem//'') ){
                Util::Messaging::dprint(HIGH, "Delete elem ... \n" );
                delete $captured_values[$cnt];
             }
             $cnt++;
          }
          $captured_val = $1;
          Util::Messaging::dprint(HIGH, "Found regx '$regex' => val ['". join("','", @captured_values) . "']\n" );
          my @vals;
          foreach my $elem ( @captured_values ){
             if( $elem =~ m/\S+/ ){ push(@vals,$elem); }
          }
          push(@all_captured,@vals);
          #last;
      }
   }   

   if( !@all_captured ){
      Util::Messaging::dprint(HIGH, "Did *NOT* find regx '$regex' ... so it's empty\n" );
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
#my ($curpos, $aref_loglines) = ExtractTextBlock( $FH, $curpos, $start_regex, $end_regex );
sub ExtractTextBlock($$$$){
   print_function_header();
   my $fh          = shift;   # file handle opened for read
   my $curpos      = shift;   # position to start reading from file
   my $start_regex = shift;
   my $end_regex   = shift;

   my @text_block_lines;
   my $func_name = 'ExtractTextBlock';
   my $start     = 'not found';
   my $end       = 'not found';

   Util::Messaging::dprint(SUPER, "$func_name: \$start_regex='$start_regex'\n");
   Util::Messaging::dprint(SUPER, "$func_name: \$end_regex='$end_regex'\n");
   my $cnt = 0;
   for( $curpos = tell($fh); my $line = readline($fh); $curpos = tell($fh)) {
      Util::Messaging::dprint(SUPER, "line='$line'" );
      $cnt++;
      if( $line =~ m/$start_regex/ ){
         $start='found';
         Util::Messaging::dprint(SUPER, "$func_name: found start \$line='$line'");
      }
      next unless( $start eq 'found' );
      if( $start eq 'found' && $end eq 'not found' ){
         Util::Messaging::dprint(SUPER, "$cnt: $func_name: push \$line='$line'");
         push( @text_block_lines, $line );
      }
      if( $line =~ m/$end_regex/ ){
         $end='found';
         Util::Messaging::dprint(SUPER, "$func_name: found end \$line='$line'");
         return( $curpos, \@text_block_lines ) if( $end eq 'found' );
         #if both start and end are found, but nothing in between then 
         #    then the array @text_block_lines will be undef;
      }
   }
   Util::Messaging::dprint(SUPER, "$func_name: start= $start\n" );
   Util::Messaging::dprint(SUPER, "$func_name: end  = $end  \n" );
   Util::Messaging::dprint(SUPER, "$func_name: EOF ... return from func\n") if( $curpos == -1 ) ;


   # Uh-oh, no lines were read from the file.
   if( $start eq 'not found' && $curpos == -1 ){
      if( defined($main::DEBUG) && ($main::DEBUG >= MEDIUM) ){
         my $call_stack      = get_call_stack();
         Util::Messaging::eprint( "'$call_stack': Didn't find text block demarcated by \n\tSTART\t= '$start_regex' & \n\tEND\t= '$end_regex'\n");
         return( -1, \@text_block_lines );
      }

      # Minimal messaging....
      if( defined($main::DEBUG) && ($main::DEBUG > NONE) ){
         my $subroutine_name = get_subroutine_name();
         Util::Messaging::wprint( "'$subroutine_name': no lines read from file ... text block demarcated by '$start_regex' & '$end_regex'\n");
      }
      return( -1, \@text_block_lines );
   }
   print_function_footer();
} # end sub : ExtractTextBlock

#-----------------------------------------------------------------
#  sub 'alert'
#  Helpful alert function. Shows pass or fail output and logs it 
#  to the logfile.
#  Example outpt: 
#
#	"PASS: Everything is good."
#	"FAIL: Somethign went wrong."
# 	"WARNING: Something was not found."
#
#	"PASS:CRITICAL:LOW: This check passed all constratints."
#	"FAIL:CRITICAL:HIGH: This check failed all constratints."
#	
#	Inputs arguments
#  - Integer: 
#		PASS/FAIL status	
#		If integer is 0 -> FAIL: message\n
#  		If integer is 1 -> PASS: message\n
#  		Otherwise -> message\n (printed in blue)
#  - Message: 
#		The message you want to show.
#  - Criticality: 
#		Specify the criticality of the message. Specifying this option 
#		will append CRITICAL:$criticality: after PASS or FAIL.
#-----------------------------------------------------------------
sub alert {

	my $pass        = shift;
	my $answer      = shift;
	my $criticality = shift;
   my ($COLOR_PASS_STRING, $COLOR_FAIL_STRING, $COLOR_WARNING_STRING);
	
	if (!$criticality){
		$criticality = NULL_VAL;
	}

	# Remove trailing newline character.
	chomp ($answer);

	# Decide whether to append the criticality or not.
	my $PASS_STRING = "PASS" . ( ($criticality ne NULL_VAL) ? ":CRITICAL:$criticality: " : ": ");
	my $FAIL_STRING = "FAIL" . ( ($criticality ne NULL_VAL) ? ":CRITICAL:$criticality: " : ": ");	
	my $WARNING_STRING = "WARNING: ";

	$COLOR_PASS_STRING = colored ($PASS_STRING, "green");
	$COLOR_FAIL_STRING = colored ($FAIL_STRING, "red");
	$COLOR_WARNING_STRING = colored ($WARNING_STRING, "blue");
	
	if ( $pass == 1 ) {
		my $final_string = $PASS_STRING.$answer."\n";
		print $COLOR_PASS_STRING.$answer."\n";
		logger($final_string);
	}
	elsif ( $pass == 0 ) {		
		my $final_string = $FAIL_STRING.$answer."\n";
		print $COLOR_FAIL_STRING.$answer."\n";
		logger($final_string);
	}
	else {		
		my $final_string = $WARNING_STRING.$answer."\n";
		print $COLOR_WARNING_STRING.$answer."\n";
		logger($final_string);
	}
	
	return;

}

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
   my $opt_d = $options{d}; # debug setting
   my $opt_v = $options{v}; # verbosity setting

   if ( $help || ( defined $opt_d && $opt_d !~ m/^\d+$/ ) 
              || ( defined $opt_v && $opt_v !~ m/^\d+$/ ) ){  
      my $program_name = $main::PROGRAM_NAME || ( caller(0) )[1];
      my $msg  = "USAGE:  $program_name -d # -v # -h \n";
         $msg .= "... add debug statments with -d #\n";
         $msg .= "... increase verbosity  with -v #\n";
      Util::Messaging::iprint( $msg );
      exit;
   }   

   # decide whether to alter DEBUG variable
   # '-d' indicates DEBUG value ... set based on user input
   if( defined $opt_d && $opt_d =~ m/^\d+$/ ){  
      if ( defined($main::DEBUG)){
          $main::DEBUG = $opt_d;
      }
   }

   # decide whether to alter VERBOSITY variable
   # '-v' indicates VERBOSITY value ... set based on user input
   if( defined $opt_v && $opt_v =~ m/^\d+$/ ){  
      $main::VERBOSITY = $opt_v;
   }

}

######################################## Common functions ######################################

##------------------------------------------------------------------
##  sub 'isa_num' => return TRUE (1) if 1st argument is a number
##                    else, return FALSE (0)
##------------------------------------------------------------------
sub isa_num($){
   my $var = shift;
   unless( defined $var ){
      my $call_stack = get_call_stack(); 
      Util::Messaging::wprint( "Undefined value passed : '$call_stack'\n" );
      return FALSE;
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
sub isa_scalar($){
   my $var = shift;
   unless( defined $var ){
      my $call_stack = get_call_stack(); 
      Util::Messaging::wprint( "Undefined value passed : '$call_stack'\n" );
      return FALSE;
   }

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
sub isa_int($){
   my $var = shift;
   return FALSE if !defined($var);
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
sub isa_aref($){
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
sub isa_href($){
   my $var = shift;
   if( "HASH" eq ref($var) ){ 
      return( TRUE )
   }else{ 
      return( FALSE ) 
   }
}

#------------------------------------------------------------------------------#
# These subroutines 'arrayContains'/'reconcileDuplicates' were surgically
#     extracted from alphaPinCheck.pl by Patrick Oct 2022.
#     And unit tests proved following three lines are equivalent:
#             @$aref = reconcileDuplicates( $aref_list1, $aref_list2 );
#             @$aref = simple_difference(   $aref_list1, $aref_list2 );
#    (undef, $aref ) = compare_lists(       $aref_list1, $aref_list2 );
# Given a reference to an array of scalars, will return unique elements only. 
# The behavior is similar to unix's 'uniq' command. But this function will
# only allow an array of scalers and will issue an error if you pass it something
# else. 
# 
# Example:
#
# my @array = qw(one two three two three);
# my @filtered = Util::Misc::uniq_scalars(\@array);
#    @filtered now = qw(one two three);
#------------------------------------------------------------------------------#
sub arrayContains {
    my $haystack = shift;  ##  An array reference
    my $needle   = shift;

    return 0 if ( ! defined $needle );
    return 0 if ( ! Util::Misc::isa_aref( $haystack ));

    foreach my $x (@$haystack) {
        if ( $needle eq $x ) { return 1 }
    }
    return 0;
}

#------------------------------------------------------------------------------
#  search 'subsetList' for every element in array 'allList'.
#      if you find element, ignore it. Otherwise, push element into 
#      return list.
#  return list of all elements from @allList that aren't in @subsetList
#------------------------------------------------------------------------------
sub reconcileDuplicates {
    print_function_header();
    my $allList    = shift;
    my $subsetList = shift;
    my @results = ();

    if ( ! isa_aref( $allList )){
        Util::Messaging::eprint("First argument to reconcileDuplicates() is not valid. It is not an array reference!");
        return @results;
    }

    foreach my $f (@$allList) {
        if (arrayContains($subsetList, $f)) {next}
        push @results, $f;
    }
    return @results;
}

#------------------------------------------------------------------------------
sub unique_scalars($){
   my $aref_scalars = shift;

   my %seen;
   
   # If arg passed in here is not an AREF, return empty array
   unless( isa_aref($aref_scalars) ){
      return(  );  # empty array 
   }
   # Build list of UNIQUE elements that reflects ordering in original list
   my (@ordered_list) = ( );
   # Record the list of UNIQUE elements
   foreach my $elem ( @$aref_scalars ){
      if( ref($elem) eq 'ARRAY' ){ 
         Util::Messaging::eprint("Expected SCALAR where ARRAY was found while removing redundant elements in list!\n");
         next;
      }
      if( ref($elem) eq 'HASH'  ){ 
         Util::Messaging::eprint("Expected SCALAR where HASH was found while removing redundant elements in list!\n");
         next;
      }
      if ( ! exists $seen{$elem} ) {
          push(@ordered_list, $elem);
      }
      $seen{$elem} = 1;
   }
   undef %seen;
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
      Util::Messaging::eprint( Carp::longmess("Bad argument passed to sub '$mySubName'. \nList 1 => '" . (ref $aref_L) .
                        "'\nList 2 => '" . (ref $aref_R) ));
      return( $aref_empty, $aref_empty, FALSE );
   }else{
      Util::Messaging::dprint(MEDIUM, "Good arguments passed to sub '$mySubName'\n" );
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

   my $not = 'NOT';
   if( $bool__lists_equiv ){ $not = ''; }
   Util::Messaging::dprint(HIGH, "Lists are ...$not equivalent.\n" );
   return (\@common, \@firstOnly, \@secondOnly, $bool__lists_equiv);
}


##------------------------------------------------------------------
## Purpose:
##      To check to see if it's safe to try and write this file out.
##
## Arguments:
##      filename: Required, scalar
##
## Returns:
##      1: TRUE , it is safe to try and write the file
##      0: FALSE, it is NOT safe to write the file
##
##------------------------------------------------------------------
sub is_safe_to_write_file($) {
    my $filename = shift;

    if(!defined($filename)) { return FALSE; }

    #
    # One way to find out if it's ok to write the file, is to try and write
    # the file. If it succeeds then close the file and return TRUE.
    #
    # Issue#1: This will leave a file behind if you only wanted to see if 
    #    it's ok to write the file but then the client doesn't actually write
    #    the file.
    # Issue#2: If a file already exists, then opening for write will empty
    #    the contents of the existing file. Which is ok if the client then
    #    overwrites the same filename again, but if the client didn't actually
    #    want to write something, well you wrote something or overwrote 
    #    something.
    #    
    if ( open(my $FH, '>', $filename) ) #nolint open>
    { 
        close($FH);
        return TRUE; # success, we can write to this file
    }

    if ( defined($main::DEBUG) && ( $main::DEBUG >= HIGH ) ) {
        my $subname = get_subroutine_name();
        Util::Messaging::dprint(HIGH, "$subname: Unable to write to file '$filename' : $!");
    }

    return FALSE;
}

##------------------------------------------------------------------
##  write to a output file
##
##  Arguments:
##
##      fileContent:
##          This should be an array reference.
##
##      outFileName:
##          Where to write your information to.
##
##  Returns:
##      NULL_VAL (ie. "N/A") if the wrong type of argument was passed for data
##      TRUE (1) if things went well, nothing wrong
##
##  Side Effects:
##
##      confess() is called if unable to open the file for write
##
##  Examples
##      write_file( $bigString, $fname );  # data in scalar
##      write_file( \@lines, $fname );     # data in list/array reference
##------------------------------------------------------------------
sub write_file($$;$){
    print_function_header();
    my $data        = shift;
    my $outFileName = shift;
    my $writeOptions= shift;

    $writeOptions=EMPTY_STR if ( ! $writeOptions );

    unless( isa_aref($data) || isa_scalar($data) ){
       eprint( "Expected SCALAR or AREF as input argument. Something went wrong, contact developer...\n" );
       return( NULL_VAL );
    }

    my $fh;
    if( -e $outFileName ){
        Util::Messaging::vwprint(MEDIUM, "File already exists ... over-writing: '$outFileName'\n" );
    }
    #----------------------
    # Try to open file to write ... flag errors
    unless ( open($fh, ">${writeOptions}", $outFileName) ){ #nolint open>
        my $errmsg = "Unable to write '$outFileName': $!\n";
        Util::Messaging::logger($errmsg);
        if ( defined( $main::DA_RUNNING_UNIT_TESTS)){
            Util::Messaging::eprint($errmsg);
            return;
        }else{
            confess "$errmsg"; 
        }
    }

    #----------------------
    # Write data to file
    #
    # Data is AREF
    if( isa_aref($data) ){
       my @fileContent = @{$data};
       map{chomp $_ }@fileContent; ##no critic qw(ControlStructures::ProhibitMutatingListFunctions)
       print $fh join"\n",@fileContent;
    }elsif( isa_scalar($data) ){
       # Data is SCALAR
       print $fh $data;
    }

    close($fh);
    Util::Messaging::viprint(LOW,"Wrote file successfully: '$outFileName'\n");

    return( TRUE );
}  # end  write_file

##------------------------------------------------------------------
##  read a file and return file array
##------------------------------------------------------------------
sub read_file($;$){
   print_function_header();
   my $inFileName = shift;
   my $custom_msg = shift;

   my $msg;
   unless( defined $inFileName ){
      #$main::DEBUG = 100;
      $msg = get_msg_line_and_sub(1) ."Filename not passed to 'read_file()'\n";
      #$main::DEBUG = NONE;
      Util::Messaging::eprint( $msg );
      confess;
   }
   $msg = "Unable to read '$inFileName'";
   if( (defined $custom_msg) && ($custom_msg ne NULL_VAL) ){ 
      $msg = $custom_msg;
   }

   Util::Messaging::vhprint(FUNCTIONS, "Reading file: '$inFileName'\n" );
   if( ! -e $inFileName ){
       Util::Messaging::fatal_error( "While reading file, doesn't exist: '$inFileName'\n" );
       return;  # must return here in case FPRINT_NOEXIT was defined
   }elsif( ! -r $inFileName ){
       Util::Messaging::fatal_error( "While reading file, bad permissions, not readable: '$inFileName'\n" );
       return;  # must return here in case FPRINT_NOEXIT was defined
   }elsif( -z $inFileName ){
       Util::Messaging::wprint( "While reading file, found it's zero length: '$inFileName'\n" );
   }
   my $open_return = open(my $fh, "<", "$inFileName"); #nolint open<
   if ( !$open_return ){
      if ( defined($main::DA_RUNNING_UNIT_TESTS)){
          return(my @empty_array);
      }

      $msg = Util::Messaging::get_msg_line_and_sub(1) ."$msg";
      
      confess("$msg: '$!'\n");
   }

   my @fileContent = <$fh>;
   map {chomp $_} @fileContent; ##no critic qw(ControlStructures::ProhibitMutatingListFunctions)
   close($fh);
   Util::Messaging::viprint(LOW, "File read successful: '$inFileName'\n");
   
   return(@fileContent);
}

##------------------------------------------------------------------
##  Function:
##
##      $status = read_file_aref($inFileName, \@datum, [ $readOptions ] )
##
##  Purpose:
##
##    To read a text file and store it's contents into the supplied array.
##    It will also return the status of the open call.
##
##  Arguments:
##
##      inFileName:
##          The name of the file that you want to read in
##      arefOutput:
##          A reference to an array to store the file contents. One line per
##          array element. Each line is chomped so it does not have a trailing
##          linefeed.
##      readOptions:
##          [optional] For adding special directives to the open command.
##              Example:  ':encoding(UTF-8)'
##  Returns:
##
##      0 : success, no errors reading in the file
##     -1 : failed to open the file; the error message will be placed into
##          the passed in array.
##     -2 : invalid args passed to the function
##
##  Example: 
##
##    my @datum;
##    my $errors = read_file_aref("file.txt", \@datum);
##    foreach my $text ( @datum ) {
##      print("$text\n");
##    }
##------------------------------------------------------------------
sub read_file_aref($$;$){
   print_function_header();
   my $inFileName = shift;
   my $arefOutput = shift;  # will end up holding the contents of the file or
                            # an error message if open failed.
   my $readOptions= shift;  # any special directive to the open

   # make sure the user supplied both a filename and an array ref
   if ( ! $inFileName ){
       if ( $arefOutput && isa_aref($arefOutput) ) {
           push(@$arefOutput, "Invalid filename argument passed to read_file_aref");
       }
       return -2;
   }
   if ( ! $arefOutput ){
       return -2;
   }
   if ( $arefOutput && !isa_aref($arefOutput)) {
       # didn't pass in the correct reference type. Supposed to only pass this
       # a reference to an array.  
       # Example: 
       #    my @datum;
       #    my $errors = read_file_aref("file.txt", \@datum);
       #
       return -2;
   }

   $readOptions = EMPTY_STR if ( !$readOptions); 

   dprint(INSANE+100, "Reading file: '$inFileName'\n" );

   if( !-e $inFileName ){
       Util::Messaging::eprint( "While reading file, doesn't exist: '$inFileName'\n" );
   }elsif( ! -r $inFileName ){
       Util::Messaging::wprint( "While reading file, bad permissions, not readable: '$inFileName'\n" );
   }elsif( -z $inFileName ){
       Util::Messaging::wprint( "While reading file, found it's zero length: '$inFileName'\n" );
   }

   my $open_status = open(my $fh, "<${readOptions}", "$inFileName") ; # nolint open<
   if ( $open_status ) {
       @$arefOutput = <$fh>;
       map {chomp $_} @$arefOutput; ##no critic qw(ControlStructures::ProhibitMutatingListFunctions)
       close($fh);
       Util::Messaging::viprint(LOW, "File read successful: '$inFileName'\n");
       $open_status = 0;  # meaning, no errors
   }else{
       push( @$arefOutput, "Failed to open '$inFileName'. Reason is '$!'");
       $open_status = -1;
   }

   return($open_status);
} # end read_file_aref()

##------------------------------------------------------------------
##  sub to grab content inside nested brackets
##------------------------------------------------------------------
sub grab_contents_inside_brackets($){
   print_function_header();
   my $inputFile = shift;
   my %checks;
   my %variables;
   my $test='';

   open(my $fh, '<', $inputFile) || confess "Unable to open $inputFile: $!\n"; # nolint open<
     my $fileVar = do {local $/,<$fh>};  # this slurps entire file as a string
   close( $fh );
   while( $fileVar =~ m/(.*\{((?>[^{}]+)|(?R))*\})/g ){
      my $theSet = $1;
      $test = "$test|$theSet";
      while( $theSet =~ m/(.*)\{(([^{}]|(?R))+)\}/g ){
         my ($category, $innerSet1) = ($1,$2);
         while( $innerSet1 =~ m/(.*)\{(([^{}]|(?R))+)\}/g ){
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
      next if( $vars =~ m/^.\#/ );
      next if( $vars =~ m/^$/g  );
      my($name,$value) = split(/\=/,$vars);
      $variables{$name} = $value;
   }

   return (\%variables,\%checks);
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
   Util::Messaging::dprint(SUPER, "$dec\t hex=($hex)\n" );
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

   Util::Messaging::dprint(CRAZY, "[step size => min,max,#parts]=[$val => $min,$max,$stp]\n");

   return( $val );
}

##------------------------------------------------------------------
##  Gather run statistics for the script
##     First argument is name of the script.
##     Second argument is the script version. (ie. 2022ww10)
##     Third argument (optional) is an aref, used
##          to capture the cmd line arguments and log them.
##------------------------------------------------------------------
sub utils__script_usage_statistics($$@){
   # 6/24/2022 ljames added ability to skip calling usage status if an env
   # variable is defined. This env variables tells us that we are running
   # a suite of tests and that we don't want the usage stats being run.
   return if ( exists( $ENV{'DDR_DA_SKIP_USAGE'} ) );

   print_function_header();
   my $prefix    = 'ddr-da-';        # prefixed to the tool name, easier to find our scripts
   my $script    = shift;
   my $version   = shift || 'NotSet';
   my $aref_argv = shift;

   my $tool_path= 'NA';

   #
   # It appears that most tools do not report their filename extension or
   # path in the tool_name section. 
   # I will use the tool_path to see what it gives us in Elastic gui. 
   #
   $script = basename($script, ".pl");
   if ( defined( $main::RealBin ) ) {
       $tool_path = $main::RealBin;
   }

   if ( $version eq 'NotSet' ){
       $version = Util::Misc::get_release_version( $tool_path );
   }

   my $reporter = '/remote/cad-rep/msip/tools/bin/msip_get_usage_info';
   my $rargs    = " --tool_name '${prefix}${script}' ".
                  "--stage main ". 
                  "--category ude_ext_1 ".
                  "--tool_path '$tool_path' ".
                  "--tool_version '$version'"
                  ;
   if ( $aref_argv ){
       my $command_executed = join " ", @$aref_argv;
       $rargs .= " --command '$command_executed'";
   }

   if ( ! -e $reporter ){
       Util::Messaging::eprint("Missing usage reporter tool: $reporter\n");
       return;
   }

   my $verbosity=NONE;
   run_system_cmd("$reporter $rargs", $verbosity);

   return;
}

#-------------------------------------------------------------------
# Grab the date time info
#-------------------------------------------------------------------
sub get_the_date(){
    my $dateCmd = localtime();     #Wed Sep 28 16:34:08 2022
    my ($day,$month,$date,$time,$year) = ($dateCmd =~ /^([\w]+)\s+([\w]+)\s+([\d]+)\s+([\d\:]+)\s+([\d]+)/i);
    return($day,$month,$date,$time,$year);
}

##------------------------------------------------------------------
##  Send gathered statistics to admin
##------------------------------------------------------------------
sub send_stats($$$){
   my $theTo   = shift;
   my $subject = shift;
   my $body    = shift;

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

  Util::Messaging::dprint(CRAZY, "Email diagnostics:\n
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

#+
#   run_system_cmd_array
#
#   Example:
#
#       my $long_string = run_system_cmd_array("ls *");
#       my @an_array    = run_system_cmd_array("ls *");
#       my @an_array    = run_system_cmd_array("ls *", $VERBOSITY);
#
#   Example using 3rd optional argument to get the return status from the
#   system command call.
#
#       my $ret_status  = 0;
#       my @an_array    = run_system_cmd_array("ls *", $VERBOSITY, \$ret_status);
#
#   Example that just runs the command but does not return the $stdout. But you
#   can still determine if the command failed or not by using the 3rd argument.
#
#       run_system_cmd_array("ls *", $VERBOSITY, \$ret_status);
#
sub run_system_cmd_array($;$$){
    my $cmd = shift;
    my $verbosity = shift;
    my $ref_status = shift;
   

    my ($stdout, $status) = run_system_cmd($cmd,$verbosity);

    if ( $ref_status ) {
        my $the_ref = ref($ref_status);
        if ($the_ref eq "SCALAR") {
            $$ref_status = $status;
        }else{
            eprint("run_system_cmd_array's 3rd param is not an int reference!\n");
        }
    }

    if (wantarray){
        my @return_ary = split /\n/,$stdout;
        return(@return_ary);
    } elsif ( defined wantarray){
        # scalar
        return($stdout);
    } else {
        # void
        return;
    }

}

#-----------------------------------------------------------------
#  sub 'run_system_cmd' => runs a system call using the best
#    method found over the years. Alternative used in the past
#    include:  backticks (i.e. `cmd`, qx/cmd/, system ). All
#    of the alternative had various issues with different use
#    cases and hasd drawbacks;  only 'capture' proved to
#    handle STDOUT, STDERR, and Exit Val properly, always.
#
#    Can provide verbosity to control display of cmd's
#    STDOUT & STDERR.  Return the output of the cmd along
#    with the cmd's exit value.
#
#    my ($output, $reval) = run_system_cmd( $cmd, $VERBOSITY );
#-----------------------------------------------------------------
sub run_system_cmd($;$){
   my $cmd       = shift;
   my $verbosity = shift || 0;
   
   my $call_stack = get_call_stack(1); 
   
   # nolint system
   my ($stdout, $stderr, $exit_val)=("","",0);
   Util::Messaging::sprint( "run_system_cmd '$cmd'\n" ) if( $verbosity >= LOW );
   unless( defined $main::RUN_SYSTEM_CMDS && $main::RUN_SYSTEM_CMDS == 0 ){
       if( $verbosity < MEDIUM ){
           ($stdout, $stderr, $exit_val) = capture { system( $cmd ); };
       }else{
           ($stdout, $stderr, $exit_val) = tee { system( $cmd ); };
       }
   }else{
       Util::Messaging::wprint( "Skip executing system cmd because 'RUN_SYSTEM_CMDS=0' ... \n" ) if( $verbosity >= LOW );
   }
   chomp( $stdout );
   chomp( $stderr );
   #my $stdout   = `$cmd 2>&1 `;  # capture stdout, stderr
   #my $exit_val = $?; # save exit status
   if( $verbosity >= HIGH && $exit_val == 0){
      if( $stderr ne EMPTY_STR ){
         Util::Messaging::sprint( "\tStdErr ==> $stderr\n" );
      }
   }

  #-----------------------------------------------------------------------
  #  +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
  #  | 15| 14| 13| 12| 11| 10|  9|  8|  7|  6|  5|  4|  3|  2|  1|  0|
  #  +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
  #   \-----------------------------/ \-/ \-------------------------/
  #              Exit code            core     Signal that killed
  #              (0..255)            dumped         (0..127)
  #                                  (0..1)
  #-----------------------------------------------------------------------
   if( $verbosity >= LOW && $verbosity < HIGH && $exit_val != 0 ){
      if( $exit_val == -1 ){ # Failed to start program / error of the wait(2) system call
         Util::Messaging::eprint( "Failed to execute '$cmd': $stderr\n");
      }elsif( $exit_val & 127 ){ # Check for non-zero signal
         my $errorMessage =  ($exit_val & 127);
         $errorMessage .= ($exit_val & 128) ? ' with' : ' without';
         $errorMessage .= " coredump";
         Util::Messaging::eprint( "'$cmd' died with signal $errorMessage\n");
      }else{ # No kill signal, check exit code.
         my $exit_code = $exit_val >> 8; # This is the number you said to be 255.
         if( $exit_code == 255 ){
            Util::Messaging::eprint("Failed to run \"$cmd\": $stderr");
         }else{
            # can do additional checks for other exit codes if desired
            Util::Messaging::eprint("Failed to run \"$cmd\" with exit code '$exit_code': $stderr");
         }
      }

   }
   if( $verbosity >= HIGH && $exit_val != 0 ){
      $stdout = ''  unless( defined $stdout );
      Util::Messaging::eprint( "System CMD failed!\n\tCmd\t===>'$cmd'\n".
                               "\tStdErr\t===>'$stderr'\n".
                               "\tExit Val===>'$exit_val'\n" );
      Carp::cluck(EMPTY_STR);
   }
   prompt_before_continue( INSANE+100 );
 
   return( "$stdout\n$stderr", $exit_val );
}

#-----------------------------------------------------------------
#  sub 'get_call_stack' => prints out the hierarchy of
#    calling subroutines.
#-----------------------------------------------------------------
sub get_call_stack(;$){
   my $frame = shift;

   $frame = 0 unless( defined $frame );
   my( $package,   $filename, $line,       $subroutine, $hasargs,
       $wantarray, $evaltext, $is_require, $hints,      $bitmask
     ) = caller($frame);

   my $subname;
   my @subroutines;
   for( my $i=$frame; (caller($i))[3]; $i++){
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
   if( defined( $subroutine_name ) ){
       $subroutine_name =~ s/main:://ig;
       return( $subroutine_name );
   } else {
       return( "" );
   }
}

#-----------------------------------------------------------------
#  sub 'print_function_header'
#-----------------------------------------------------------------
sub print_function_header(){
   if( defined($main::DEBUG) && ($main::DEBUG >= FUNCTIONS) ){
       my $subroutine_name =   "'" . get_caller_sub_name() . "'";
       my $str;
       $str=sprintf( "-" x20 . " Starting Function: %-25s" . "-" x20 . "\n", $subroutine_name );

       my $line_subroutine_stack = "";
       if( $main::DEBUG >= CRAZY ){
           $line_subroutine_stack = 
                          Util::Messaging::get_msg_line_and_sub(
                                2, get_subroutine_name()
                          ) . " -> ";
       }
       print $line_subroutine_stack. "-I- " . $str;
   }
   prompt_before_continue(INSANE);
}

#-----------------------------------------------------------------
#  sub 'prompt_before_continue'
#    - will automatically prefix msg with the line #
#    - if DEBUG is >INSANE, will automatically prefix msg 
#          with the call stack
#    - during DA team tests (i.e. unit test, func test)
#          do not halt script execution, ever
#-----------------------------------------------------------------
sub prompt_before_continue($){
    my $halt_level  = shift;

    #------------------------------------------------------
    if( defined($halt_level) && isa_int($halt_level)  
        && defined($main::DEBUG) && ($main::DEBUG >= $halt_level) ){

        my $line_subroutine_stack = "";
        if( $main::DEBUG >= FUNCTIONS ) {
            $line_subroutine_stack = Util::Messaging::get_msg_line_and_sub(1, get_subroutine_name());
        }

        print colored( $line_subroutine_stack ."Hit ENTER to continue ...   ", 'red' );

        defined($main::DA_RUNNING_UNIT_TESTS) && 
            $main::DA_RUNNING_UNIT_TESTS==1 ? return() : <STDIN> ;
    }
}

#-----------------------------------------------------------------
#  sub 'print_function_footer'
#-----------------------------------------------------------------
sub print_function_footer(){
   my $subroutine_name =   "'" . get_caller_sub_name() . "'";
   my $str;
   $str=sprintf( "-" x20 . " Ending Function:   %-25s" . "-" x20 . "\n", $subroutine_name );
   if( defined($main::DEBUG) && ($main::DEBUG >= FUNCTIONS) ){
       my $line_subroutine_stack = "";
       if( $main::DEBUG >= CRAZY ){
           $line_subroutine_stack = 
                          Util::Messaging::get_msg_line_and_sub(
                                2, get_subroutine_name()
                          ) . " -> ";
       }
       print $line_subroutine_stack. "-I- " . $str;
   }
   prompt_before_continue(INSANE);
}

#-----------------------------------------------------------------
#  sub 'get_release_version'
#
#  Arguments:
#
#      scriptBin:
#           [optional] Used to specify the directory that the script is
#           located in. In the script directory there should be a .version
#           file that says what version of the tool we are using. The
#           default for scriptBin if one is not supplied is the
#           global variable $main::RealBin
#
#  Returns:
#
#       A string that represents the release version of this toolset.
#       (eg. 2022.10 )
#
#  Design:
#       This routine will look for a file named '.version' in the same
#       directory that the script is located in. This is typically the
#       /bin diretory of the tool.
#
#       If the '.version' file can not be found then this script will
#       return a default version string.
#
#  Example:
#
#       my $version_string = get_release_version();
#
#-----------------------------------------------------------------
sub get_release_version(;$){
    my $scriptBin = shift;     # optional
    my $version   = "2022.12"; # default version if we can not find the script

    my $scriptBinDir = "";
    if (! $scriptBin) {
        if ( defined $main::RealBin ) {
            $scriptBin = $main::RealBin;
            $scriptBinDir = "${scriptBin}/";
        }
    }else{
        $scriptBinDir = "${scriptBin}/";
    }


    my $cmd = "${scriptBinDir}da_get_release_version.pl";
    if ( -e $cmd ) {
        ($version, my $status) = Util::Misc::run_system_cmd( "$cmd $scriptBin");
        chomp $version;
    }

    return $version;
}


#-----------------------------------------------------------------
#  sub 'header'
#-----------------------------------------------------------------
sub header(){
    return if (defined $main::DDR_DA_DISABLE_HEADER); # for unit testing
    my $program_name  = ( caller(0) )[1];
    if ( $main::PROGRAM_NAME ) {
       $program_name = $main::PROGRAM_NAME;
    }

    my $author = "ddr-da team";
    if ( $main::AUTHOR ){
       $author = $main::AUTHOR;
    }

    my $scriptBin = "";
    if ( defined $main::RealBin ) {
        $scriptBin = $main::RealBin;
    }

    my $version = Util::Misc::get_release_version(); 
    Util::Misc::da_is_script_in_list_of_obsolete_versions( $scriptBin );

    my $latest_v = NULL_VAL;
    if ( ! Util::Misc::da_is_latest_version($version, $scriptBin, \$latest_v) ){
        wprint( "You are running version '$version' which is not\n".
            "\tthe most recent release version '$latest_v'.\n");
    }

    my $username = get_username();

    # ljames - changed to use nprint() based on meeting 10/3/2022
    # To ensure this info ends up in the log file
    nprint( "\n\n#######################################################\n");
    nprint( "###  Date , Time     : '" . localtime() . "'\n");
    nprint( "###  Begin Running   : '$program_name ". join(" ",@ARGV)."'\n");
    nprint( "###  Author          : '$author'\n");
    nprint( "###  Release Version : '$version'\n");
    nprint( "###  User            : '$username'\n");
    nprint( "#######################################################\n\n");

    $Misc::START_TIME = [ gettimeofday ];
}

#-----------------------------------------------------------------
#  sub 'footer'
#-----------------------------------------------------------------
sub footer(){
   return if (defined $main::DDR_DA_DISABLE_FOOTER); # for unit testing

   my $program_name = ( caller(0) )[1];
   if ( $main::PROGRAM_NAME ) {
       $program_name = $main::PROGRAM_NAME;
   }

   if ( ! defined $Misc::START_TIME ) {
       $Misc::START_TIME = [ gettimeofday ];
   } 

   my ($seconds, $microseconds) = gettimeofday;
   my $elapsed_time             = tv_interval( $Misc::START_TIME, [$seconds, $microseconds]);
      $elapsed_time = sprintf("%.1f", $elapsed_time);

   my $version = Util::Misc::get_release_version();
   # ljames - changed to use nprint() based on meeting 10/3/2022
   # To ensure this info ends up in the log file
   nprint( "\n" );
   nprint( "#######################################################\n");
   nprint( "###  Goodbye World\n");
   nprint( "###  Date , Time     : " . localtime() . "\n");
   nprint( "###  End Running     : '$program_name'\n");
   nprint( "###  Elapsed (sec)   : '$elapsed_time'\n");
   nprint( "###  Release Version : '$version'\n");
   nprint( "#######################################################\n\n");
}

#-----------------------------------------------------------------
#  sub 'trim'
#  Function for trimming a string
#-----------------------------------------------------------------
sub trim($) { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s }

#-----------------------------------------------------------------
#  sub 'da_copy'
#  Used to copy files with built-in error checks and more info provided
#  to the user in case of failure. The subroutine may terminate unless
#  $critical is set to 0. Returns 1 in case it succeeded and 0 in case
#  it failed.
#-----------------------------------------------------------------
sub da_copy($$){
    print_function_header();
    my $sourceFile = shift;
    my $destFile   = shift;

    my $destDirName = dirname($destFile);
    $destDirName = $destFile if( -d $destFile );
    my $status = 0;
    if( !-e $sourceFile ){
        Util::Messaging::wprint("The file '$sourceFile' used in the copy operation doesn't exist.\n");
    }elsif( !-e $destDirName ){
        Util::Messaging::wprint("The destination directory '$destDirName' doesn't exist!\n".
                                "Unable to copy to '$destFile'.\n");
    }elsif( !-w $destDirName ){
        Util::Messaging::wprint("The user doesn't have write permission in the destination ".
                                "directory '$destDirName'.\n".
                                "Unable to copy to '$destFile'.\n");
    }elsif( (-e $destFile) && (!-w $destFile) ){
        Util::Messaging::wprint("The file '$destFile' is not writtable. ".
                                "Cannot complete the copy operation.\n");
    }elsif( copy($sourceFile, $destFile) ){
        Util::Messaging::viprint(HIGH, "Copied file successfully from\n\t '$sourceFile'\n      to\n\t'$destFile'\n" );
        $status = 1;
    }else{
        my $error = $!;
        if( $error =~ /Disk quota exceeded/i ){
            $error .= "\n".check_p4_quota($destFile);
        }
        Util::Messaging::eprint("Failed to copy '$sourceFile'\nto '$destFile'\n".
                                "Error: $error\n");
    }
    print_function_footer();
    return $status;
}

#
# sub 'get_username'
#
# This uses a well established way to get the username. It should work on 
# all unix /posix systems.
#
sub get_username(){
    my $username = getlogin() || getpwuid($<) || $ENV{'USER'};
    return $username;
}


#-----------------------------------------------------------------
#  sub 'check_p4_quota'
#  Checks the remaining p4 quota for the user. It can optionally take a file to check
#  whether it's located in the user's perforce or not. It will print the used/total
#  allocatted diskspace. It will also print the free diskspace on the filesystem
#  in the off-chance that the user has not reached the quota but the filesystem
#  is full.
#-----------------------------------------------------------------
sub check_p4_quota(;$){
    print_function_header();
    my $filePath = shift;

    my $username = get_username();
    my $p4Path = "/u/$username/p4_ws";
    my $absPath;
    if( defined($filePath) ){
        $absPath = abs_path(dirname($filePath));
    }else{
        $absPath = abs_path($p4Path);
    }
    my( $msg, $usage, $limit, $avail, $free);
    my ($foundQuota, $foundFree);
    $msg = EMPTY_STR;
    # Check that the path is in the users diskspace. Quota checking can only
    # be done on user's diskspace.
    if( !-e $p4Path ){
        $msg .= "Failed to find the user's perforce mapping at '$p4Path'";
    }else{
        my $p4PathAbs = abs_path($p4Path);
        if( $absPath !~ /$p4PathAbs/ ){
            $msg = "Failed to check the quota because the destination file is ".
                   "not located in the user's perforce.";
        }else{
            # Get the filesystem name for the user's perforce from the absolute path
            my ($fileSystem) = ($p4PathAbs =~ m|/(${\NFS})/$username|);

            # Run quota to get the report about the user's usage/limit. It includes
            # several filesystems so the stdout needs to be parsed to get the values
            # for perforce only.
            my $cmd = "quota -w";
            my ($stdout, undef) = run_system_cmd($cmd, $main::VERBOSITY);
            my @lines = split("\n",$stdout);
            my $line  = ( grep { /$fileSystem/} @lines )[0];

            # Parse the line for the user's perforce to get the usage/limit
            # Format the usage/limit to a human readable form and add units
            if( defined($line) ){
                my @items = split(/\s+/,$line);
                $usage = $items[1];
                $usage =~ s/\*$//;
                $limit = $items[2];
                $avail = sprintf("%.2f",($limit - $usage)/1024);
                $avail .= "MB";
                $usage = sprintf("%.2f",$usage/1024);
                $usage .= "MB";
                $limit = sprintf("%.2f",$limit/1024);
                $limit .= "MB";
                $foundQuota = TRUE;
            }else{
                $msg .= "Failed to find the quota for the filesystem '$fileSystem'.\n";
            }

            # Run df to get the total free space in the filesystem in the off-chance that
            # the user has not reached the limit but the filesystem is full.
            $cmd = "df -h $p4PathAbs";
            ($stdout, undef) = run_system_cmd($cmd, $main::VERBOSITY);
            @lines = split("\n",$stdout);
            $line = ( grep {/$fileSystem/} @lines )[0];
            if( defined($line) ){
                my @items = split(/\s+/,$line);
                $free = $items[3];
                $free = sprintf("%.2f",substr($free,0,-1)).substr($free,-1)."B";

                $foundFree = TRUE;
            }else{
                $msg .= "Failed to get the free space in the filesystem '$fileSystem'.\n";
            }
        }
    }
    # Get the filesystem name

    my $table = Text::ASCIITable->new({headingText => 'P4 Diskspace Usage'});
    $table->setCols('Item','Size');
    $table->alignColName('Item','center');
    $table->alignColName('Size','center');
    $table->alignCol('Size',"right");
    if( defined($foundQuota) && defined($foundFree) ){
        $table->addRow("Limit",$limit);
        $table->addRow("Usage",$usage);
        $table->addRow("Available", $avail);
        $table->addRow("Free", $free);
    }elsif( defined($foundFree) ){
        $table->addRow("Limit",$limit);
        $table->addRow("Usage",$usage);
        $table->addRow("Available", $avail);
    }elsif( defined($foundQuota) ){
        $table->addRow("Free", $free);
    }else{
        $table = undef;
    }

    if( defined($table) ){
        $msg .= $table;
    }
    print_function_footer();
    return $msg;
}

#-------------------------------------------------------------------------------
#  Verify the 1st arg is a string and matches what's expected. Otherwise,
#     print the USAGE messages and exit.
#  Usage Example:
#     my ($projType, $proj, $pcsRel) =  parse_project_spec( @ARGV );
#-------------------------------------------------------------------------------
sub parse_project_spec($$){
    print_function_header();
    my $args = shift;
    my $usage = shift;
    
    my ($projectType, $project, $pcsRelease);
    if( defined $args && $args =~ /^([^\/]+)\/([^\/]+)\/([^\/]+)$/ ){
        $projectType  = $1;
        $project      = $2;
        $pcsRelease   = $3;
    }else{
        if (exists $ENV{'DDR_DA_TESTING'} || 
            defined( $main::DA_RUNNING_UNIT_TESTS)){
            return(NULL_VAL);
        }
        else{
            eprint( "Command line argument missing! ... expected to be <project_type>/<project>/<CD_rel>\n\n" );
            &$usage(1);
            if ( defined( $main::FPRINT_NOEXIT) ){
                return (NULL_VAL, NULL_VAL, NULL_VAL);
            }

            exit(1);
        }
    }

    dprint(FUNCTIONS, "(\$projectType, \$project, \$pcsRelease) => ($projectType, $project, $pcsRelease)\n" );
 
    return( $projectType, $project, $pcsRelease );
}


#-----------------------------------------------------------------
#  sub 'da_get_toolname'
#
#  Purpose:
#
#     This subroutine will try and return the name of the tool
#     that your script is located in. It will base this on the
#     script's path as defined in the $main::RealBin global
#     variable. This script expects that the tool name is located
#     somewhere in the directory path. Above where the script is
#     located in.  For example:
#
#       TOOLNAME/dev/main/bin   --- when in GitLab and p4 dev area
#       TOOLNAME/2022.09/bin    --- when released to mirror sites
#       TOOLNAME/dev/bin        --- when released to beta mirror sites
#       sharedlib/t             --- when script is a test of sharedlib
#
#  Arguments:
#
#     scriptBin:
#       [optional] The directory path in which your script resides. If not
#       specified then it will look for $main::RealBin .
#
#  Returns:
#
#      A string representing the name of the TOOL or NULL_VAL 
#      
#  Example:
#
#       my $tool = da_get_toolname();
#
#-----------------------------------------------------------------

sub da_get_toolname(;$) {
    my $scriptBin = shift;

    my $scriptBinDir = "";
    if (! $scriptBin) {
        if ( defined $main::RealBin ) {
            $scriptBin = $main::RealBin;
            $scriptBinDir = "${scriptBin}/";
        }
    }else{
        $scriptBinDir = "${scriptBin}/";
    }
    my ($toolname, $status) = 
        run_system_cmd("${scriptBinDir}da_get_toolname.pl $scriptBin");
    chomp $toolname;

    if ( $status != 0 ) {
        $toolname = NULL_VAL;
    }

    return $toolname;
}


#-----------------------------------------------------------------
#  sub 'da_is_script_in_list_of_obsolete_versions'
#
#  Purpose:
#
#       This will check a secret file to determine if the current tool's
#       version is allowed to run or not. If it sees the tools's current
#       version in the secret file, then it will print a message and then
#       exit the application.
#
#  Arguments:
#
#    scriptBin:
#       [optional] The directory in which your script is running from.
#
#  Returns:
#
#     Nothing  
#     
#  Side Effect(s):
#
#     Will exit(-1) out of your application if your script version is deemed
#     to be obsolete.
#
#  Example:
#
#       da_is_script_in_list_of_obsolete_versions();
#
#-----------------------------------------------------------------

sub da_is_script_in_list_of_obsolete_versions(;$) {
    my $scriptBin = shift;

    my $scriptBinDir = "";

    if (! $scriptBin) {
        if ( defined $main::RealBin ) {
            $scriptBin = $main::RealBin;
            $scriptBinDir = "${scriptBin}/";
        }
    }else{
        $scriptBinDir = "${scriptBin}/";
    }

    my $script_version = Util::Misc::get_release_version($scriptBin);

    my $pl_script = "da_is_script_in_list_of_obsolete_versions.pl";
    if ( ! -e "${scriptBinDir}${pl_script}" ){
        # unable to determine if the script version is blocked or not because
        # we don't see the script used to determine this!
        return;
    }

    my ($output, $status) = 
        run_system_cmd("${scriptBinDir}${pl_script} ${script_version}");

    if ( $output eq "BLOCKED" ){
        my $xtra     = "";
        my $toolname = Util::Misc::da_get_toolname( $scriptBin );
        if ( $toolname ne NULL_VAL ){
            $xtra     = "To get the latest try:\n"
                . "\t module unload $toolname \n"
                . "\t module load $toolname \n";
        }
        my $msg = <<END_OF_MSG
The version of the script you are using $script_version is obsolete. There are newer versions
available to use. $xtra
END_OF_MSG
;
        Util::Messaging::eprint( $msg );
        exit(1);
    }

    return;
}

#+
#  Function:
#       da_is_latest_version
#
#  Required Arguments:
#       current_version:
#           What version are you comparing against?
#
#       scriptBin:  
#           The /bin folder that holds the script.
#
#  Optional Arguments:
#       ref_latest_version:
#           A reference to a scalar string to be filled in with the most
#           recent version available.
#
#  Returns:
#       TRUE or FALSE;  TRUE if your version is the latest; false otherwise
#-
sub da_is_latest_version($$;$){
    my $current_version    = shift;
    my $scriptBin          = shift;
    my $ref_latest_version = shift;

    if ( $current_version eq "dev" ){
        return TRUE;
    }

    if ( $scriptBin =~ m|^(.*/Shelltools)/([^/]*)/(.*)/| ){
        my $shelltools_dir = $1;
        my $tool_name      = $2;
        my $tool_version   = $3;

        if ( $current_version eq NULL_VAL ){
            $current_version = $tool_version;
        }


        # is there a more recent version?  Look in Shelltools area.
        my @files = run_system_cmd_array("ls -t ${shelltools_dir}/${tool_name}/");
        my $top_version = shift @files;
        $top_version = shift @files if ( $top_version eq "dev");
        $top_version = shift @files if ( $top_version eq "testing");
        $top_version = shift @files if ( $top_version eq "dev");

        dprint(HIGH, "\ncurrentVersion: $current_version\ntool_version: $tool_version\ntop_version: $top_version\n");
        $$ref_latest_version = $top_version if ( $ref_latest_version );

        if ( $top_version && ($current_version ne $top_version) ) {
            return FALSE;
        }
    }

    return TRUE; # True, the current_version is NOT the latest version
}


#-------------------------------------------------------------------------------
#   List out all subdirectories at a non P4 directory path
#-------------------------------------------------------------------------------
sub da_findSubdirs($){
   print_function_header();
   my $filePath = shift;
   my @dirs; 
   unless (defined $filePath){
      dprint(HIGH, "File path was not defined!\n");
      return NULL_VAL;
   }
   unless (-e $filePath){
      dprint(HIGH, "File path does not exist: '$filePath'\n");
      return NULL_VAL;
   }
   unless (-d $filePath){
      dprint(HIGH, "File path is not a directory: '$filePath'\n");
      return NULL_VAL;
   }
   opendir my $dh, $filePath
   or die "$0: opendir: $!"; 
   while (defined(my $name = readdir $dh)) {
      @dirs = grep {-d "$filePath/$_" && ! /^\.{1,2}$/} readdir($dh);        
   }
   my @sorted_dirs = sort(@dirs);
   return @sorted_dirs;
}

#-------------------------------------------------------------------------------
#   Prompt the user Yes/No with an optional default answer and a limit to the
#   number of unsuccessful entries
#-------------------------------------------------------------------------------
sub prompt_user_yesno($;$$){
    print_function_header();
    my $message      = shift;
    my $defaultValue = shift;
    my $limit        = shift;

    $limit = 3 unless( isa_int($limit) );
    my $yesno = "Y/N";
    if( defined($defaultValue) && $defaultValue =~ /y(es?)?/i){
        $yesno = "Y/n";
        $defaultValue = "Y";
    }elsif( defined($defaultValue) && $defaultValue =~ /no?/i){
        $yesno = "y/N";
        $defaultValue = "N";
    }

    my $response;
    my $counter = 1;
    while( $counter <= $limit ) {
        wprint("The answer is not Y or N, please try again!\n") if( $counter > 1);
        hprint("$message [$yesno]\n");
        $response = <STDIN>;
        if( $response =~ /^y(es?)?$/i ){
            return "Y";
        }elsif( $response =~ /^no?$/i ){
            return "N";
        }elsif( $response =~ /^\s*$/ && defined($defaultValue) ){
            return $defaultValue;
        }
        $counter++;
    }

    if( defined($defaultValue) ){
        return( $defaultValue );
    }else{
        return EMPTY_STR;
    }

    print_function_footer();
}
################################
# A package must return "TRUE" #
################################

1;

