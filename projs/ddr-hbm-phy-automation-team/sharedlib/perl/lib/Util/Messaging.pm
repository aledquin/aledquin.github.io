############################################################
#Utility messaging functions
#
#  Author : James Laderoute
############################################################
package Util::Messaging;

use strict;
use warnings;
use Data::Dumper;
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/";
use Util::CommonHeader; 
use Util::Misc;


use Term::ANSIColor;
$Term::ANSIColor::EACHLINE = "\n";  # Resets the color after each newline...

use base 'Exporter';
# Symbols (subs or vars) to export by default 
our @EXPORT = qw[
  logger
  write_stdout_log
  vhprint 
  viprint 
  vwprint 
  veprint
  dprint 
  dprint_dumper
  sprint 
  iprint 
  hprint 
  wprint 
  eprint 
  fprint
  fatal_error 
  nprint
  gprint
  p4print
  get_msg_line_and_sub
];
#-----------------------------------------------------------------
#  Print subroutines 
#-----------------------------------------------------------------

#-----------------------------------------------------------------
sub auto_append_newline($){
    my $msg = shift;

    if( defined($main::AUTO_APPEND_NEWLINE) ){
        $msg =~ s/\n/\n    /g;
        $msg =~ s/\s*$/\n/;
    }
    return( $msg );
}

#-----------------------------------------------------------------
#  Intended for use with all print utilities, and function 
#     header/footer.
#  Remove from the call stack, those functions that need to
#     behave in special manner.
#
#  Returns strings that include the line # and subroutine call
#     stack. Caller can control frame of the call stack, to ensure
#     proper context is created.
#
#  Example string:
#      Main -> 55 myfirst -> 233 mymiddle -> 241 mylast -> -I- messages
#-----------------------------------------------------------------
sub get_msg_line_and_sub($;$){
    my $frame = shift;    
    my $regex = shift;    

    my $call_stack = "";
    my $line_msg   = "";
    if( (defined $main::DEBUG && $main::DEBUG >= HIGH) ||
        (defined $main::DEBUG && $main::DEBUG >= LOW && 
         defined $main::VERBOSITY && $main::VERBOSITY >= HIGH) ){

        my $mycall_stack = Util::Misc::get_call_stack(0);
        my @depth   = ($mycall_stack =~ m/->/g);
        my $mydepth = $#depth + 1;
        
        #  Call stack looks like this 
        #      Main -> myfirst -> mymiddle -> mylast -> Util::Messaging::iprint -> Util::Messaging::get_msg_line_and_sub
        #  We want to remove the stack associated with this subroutin, and other Util subroutines
        #  And, we want to add line numbers for each call of a sub, so final result is:
        #
        #      Main -> 55 myfirst -> 233 mymiddle -> 241 mylast -> -I- messages
        #  
        #  Interpretation:
        #      sub 'myfrist' is called on line 55 of file with Main() in it
        #      sub 'mymiddle' is called on line 233 of file with mymiddle() in it
        #      sub 'mylast' is called on line 241 of file with mylast() in it
        for( my $i=$mydepth-1; $i >= 0; $i--){
            my $line  = (caller($i))[2];
            $mycall_stack =~ s/-> ([^\d])/-> $line $1/;
            $mycall_stack =~ s/-> \d+ Util::Messaging::get_msg_line_and_sub$//;
            $mycall_stack =~ s/(-> \d+) Util::Messaging::.*$/$1 :/;
            $line_msg = $mycall_stack;
        }
    }

    return( $line_msg  );
}


#-----------------------------------------------------------------
# normal print:
# normal print with no prefix and log it
#-----------------------------------------------------------------
sub nprint($){
    my $msg = shift;

    $msg = auto_append_newline( $msg );
    print($msg); 
    logger($msg);
    return( TRUE );
}

#-----------------------------------------------------------------
# informational print:
# normal print with '-I- ' prefix and log it
#-----------------------------------------------------------------
sub iprint($;$){
    my $msg   = "-I- ".shift; 
    my $frame = shift || 1; 

    $msg = auto_append_newline( $msg );
    $msg = get_msg_line_and_sub($frame) ."$msg";
    print "$msg";
    logger($msg); 
    return( TRUE );
}

#-----------------------------------------------------------------
# verbosity informational print:
# if the VERBOSITY is equal to or higher than the first argument, normal print
# with '-I- ' prefix and log it
#-----------------------------------------------------------------
sub viprint($$){
    my $threshold = shift;
    my $msg       = shift;
    
    if( defined($main::VERBOSITY) && ($main::VERBOSITY>=$threshold)){
        iprint( $msg, 2 );
    } 
    return( TRUE );
}

#-----------------------------------------------------------------
# warning print:
# print in yellow with '-W- ' prefix and log it
#-----------------------------------------------------------------
sub wprint($;$){
    my $msg   = "-W- ".shift; 
    my $frame = shift || 1; 

    $msg = auto_append_newline( $msg );
    $msg = get_msg_line_and_sub($frame) ."$msg";
    print colored("$msg", 'yellow');
    logger($msg); 
    return( TRUE );
}

#-----------------------------------------------------------------
# verbosity warning print:
# if the VERBOSITY is equal to or higher than the first argument, print in yellow
# with '-W- ' prefix and log it
#-----------------------------------------------------------------
sub vwprint($$){
    my $threshold = shift; 
    my $msg       = shift; 
    
    if( defined($main::VERBOSITY) && ($main::VERBOSITY>=$threshold)){ 
        wprint( $msg, 2 );
    } 
    return( TRUE );
}

#-----------------------------------------------------------------
# error print:
# print in red with '-E- ' prefix and log it
#-----------------------------------------------------------------
sub eprint($;$){
    my $msg   = "-E- ".shift;
    my $frame = shift || 1; 

    $msg = auto_append_newline( $msg );
    $msg = get_msg_line_and_sub($frame) ."$msg";
    print colored("$msg", 'red');
    logger($msg);
    return( TRUE );
}

#-----------------------------------------------------------------
# verbosity error print:
# if the VERBOSITY is equal to or higher than the first argument, print in red
# with '-E- ' prefix and log it
#-----------------------------------------------------------------
sub veprint($$){
    my $threshold = shift; 
    my $msg       = shift; 

    if( defined($main::VERBOSITY) && ($main::VERBOSITY>=$threshold) ){
        eprint( $msg, 2 );
    }
    return( TRUE );
}

#-----------------------------------------------------------------
# debug print and do a Dumper call on whatever ref passed in:
# if DEBUG is equal to or higher than the first argument, print in dark blue
# with '-D- ' prefix and log it
#-----------------------------------------------------------------
sub dprint_dumper{
    my $threshold = shift;
    my $text      = shift;  # this could be undefined
    my $someref   = shift;  # this can be an array-ref or hash-ref

    if( defined($main::DEBUG) && ($main::DEBUG >= $threshold) ){
        my $msg = "-D-";
        if ( $text ) {
            $msg = "-D- ".$text;
        }
        $msg .=  scalar(Dumper $someref) ."\n" if ( $someref );

        $msg = auto_append_newline( $msg );
        $msg = get_msg_line_and_sub(1) ."$msg";
            print colored($msg, 'blue');
            logger($msg); 
    }
    return( TRUE );
} 


#-----------------------------------------------------------------
# debug print:
# if DEBUG is equal to or higher than the first argument, print in dark blue
# with '-D- ' prefix and log it
#-----------------------------------------------------------------
sub dprint{
    my $threshold = shift;
    my $text      = shift;  # this could be undefined

    if( defined($main::DEBUG) && ($main::DEBUG >= $threshold) ){
        my $msg = "-D-";
        if ( $text ) {
            $msg = "-D- ".$text;
        }

        $msg = auto_append_newline( $msg );
        $msg = get_msg_line_and_sub(1) ."$msg";
            print colored($msg, 'blue');
            logger($msg); 
    }
    return( TRUE );
} 

#-----------------------------------------------------------------
# fprint: 
# print in red on white with '-F- ' prefix and log it. 
#
# NOTE: One should ONLY set FPRINT_NOEXIT during unit testing.
#
# Takes 1 required argument
#
# Required: 
#   msg: message string
#
#-----------------------------------------------------------------
sub fprint($) { 
    my $msg       = "-F- ".shift; 

    $msg = auto_append_newline( $msg );
    print STDERR colored("$msg", 'white on_red' ); 
    print STDERR "\n";
    logger($msg);
}

#-----------------------------------------------------------------
# fatal_error:
# print in red on white with '-F- ' prefix and log it. Terminate afterwards
# unless FPRINT_NOEXIT is set to 1
#
# Takes 1 required argument and one optional argument.
#
# Required: message string
# Optional: status value to use in exit() call
#
#-----------------------------------------------------------------
sub fatal_error($;$) { 
    my $msg       = shift; 
    my $exit_stat = shift;

    if( !defined($exit_stat)){
        $exit_stat = -1; # default exit val indicates FAIL
    }

    fprint($msg);

    defined($main::FPRINT_NOEXIT) && $main::FPRINT_NOEXIT==1 ?
        return() : exit( $exit_stat );
}


#-----------------------------------------------------------------
# system command print:
#-----------------------------------------------------------------
sub sprint($;$){
    my $msg  = "-S- ".shift; 
    my $frame = shift || 1; 
    
    $msg = auto_append_newline( $msg );
    $msg = get_msg_line_and_sub($frame) ."$msg";
    print colored("$msg", 'magenta'); 
    logger($msg);
    return( TRUE );
}

#-----------------------------------------------------------------
# highlight print:
# print in cyan with '-I- ' prefix and log it
#-----------------------------------------------------------------
sub hprint($;$){ 
    my $msg   = "-I- ".shift;
    my $frame = shift || 1; 
    
    $msg = auto_append_newline( $msg );
    $msg = get_msg_line_and_sub($frame) ."$msg";
    print colored("$msg", 'bright_yellow'); 
    logger($msg);
    return( TRUE );
}

#-----------------------------------------------------------------
# verbosity highlight print:
# if the VERBOSITY is equal to or higher than the first argument, print in cyan
# with '-I- ' prefix and log it
#-----------------------------------------------------------------
sub vhprint($$){
    my $threshold = shift;
    my $msg       = shift;

    if( defined($main::VERBOSITY) && ($main::VERBOSITY>=$threshold) ){
        hprint( $msg, 2 );
    }
    return( TRUE );
}

#-----------------------------------------------------------------
# green print:
# print in green with no prefix and log it
#-----------------------------------------------------------------
sub gprint($;$){
    my $msg   = shift;
    my $frame = shift || 1; 

    $msg = auto_append_newline( $msg );
    $msg = get_msg_line_and_sub($frame) ."$msg";
    print colored("$msg", 'green');
    logger($msg);
    return( TRUE );
}

#-----------------------------------------------------------------
# p4 print:
# print in green with no prefix
# 8/15/2022 ljames - added logger() to this function per request
#           from Patrick Juliano.
#-----------------------------------------------------------------
sub p4print($;$){
    my $msg   = shift;
    my $frame = shift || 1; 

    $msg = auto_append_newline( $msg );
    $msg = get_msg_line_and_sub($frame) ."$msg";
    print colored("$msg", 'green'); 
    logger($msg); 
    return( TRUE );
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
    return( TRUE );
}

#
# Write any info captured in our global STDOUT_LOG to disk.
#
# Returns:
#   0 : success
#   1 : failed
#   
# Globals:
#      main::STDOUT_LOG:
#          This global is used to accumulate text messsages
#          from our messaging logger() routine.
#
sub write_stdout_log($){
   Util::Misc::print_function_header();
   my $out_file = shift;
   if( ! defined($out_file) ){
       wprint("write_stdout_log call is missing the required 1st argument!\n");
       return 1; # 1 is fail and 0 is success
   }

   # only write to STDOUT_LOG if it's defined
   if( defined( $main::STDOUT_LOG ) ){
      # only write if some contents exists in STDOUT_LOG
      if( $main::STDOUT_LOG ne EMPTY_STR ){
          #
          # 2/18/2022 write_file() will exit the application if it fails.
          # We don't wan't to exit the script using this if we can not write
          # out the log file for some unknown reason. So do a quick check
          # to see if we can write a file here.
          #
          if ( TRUE == Util::Misc::is_safe_to_write_file($out_file) ) {
              my @output = split(/\n/, $main::STDOUT_LOG);
              push(@output, "\n");
              Util::Misc::write_file( \@output, $out_file );
          } else {
              return 1; # was not able to write the file for some reason
          }
      }
   }

   return( 0 );
}

################################
# A package must return "TRUE" #
################################

1;

