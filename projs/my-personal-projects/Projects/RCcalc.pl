#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);


#-----------------------------------------------------------------
#  sub 'get_call_stack' => prints out the hierarchy of
#    calling subroutines.
#-----------------------------------------------------------------
sub tget_call_stack(){
   my(   $package,   $filename, $line,       $subroutine, $hasargs,
   $wantarray, $evaltext, $is_require, $hints,      $bitmask
   ) = caller(0);

   my $subname;
   my @subroutines;
   for( my $i=0; (caller($i))[3]; $i++){
      $subname =  ( caller($i) ) [3];
      $subname =~ s/main:://g;
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
#  sub 'trun_system_cmd' => runs a system call using the best
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
sub trun_system_cmd($$){
   my $cmd       = shift;
   my $verbosity = shift;

   my $call_stack = tget_call_stack(); 
   my ($stdout, $stderr, $exit_val) = capture { system( $cmd ); };
   chomp( $stdout );
   chomp( $stderr );
   return( "$stdout\n$stderr", $exit_val );
}

##------------------------------------------------------------------
##  Gather run statistics for the script
##     First argument is name of the script.
##     Second argument is the script version. (ie. 2022ww10)
##     Third argument (optional) is an aref, used
##          to capture the cmd line arguments and log them.
##------------------------------------------------------------------
sub tutils__script_usage_statistics($$@){
   my $prefix   = 'ddr-da-alpha_common-';        # prefixed to the tool name, easier to find our scripts
   my $script   = shift;
   my $version  = shift || '1.0';
   my $tool_path = "";

   #
   # It appears that most tools do not report thier filename extension or
   # path in the tool_name section. So, we will only pass in the name of
   # the tool and strip away the path and extensions.
   #
   $script = basename($script, ".pl");
   if ( defined( $main::RealBin ) ) {
       $tool_path = $main::RealBin;
   }

   my $reporter = '/remote/cad-rep/msip/tools/bin/msip_get_usage_info';
   my $rargs    = " --tool_name '${prefix}${script}' --stage main --category ude_ext_1 --tool_path '$tool_path' --tool_version '$version'";
   if ( ! -e $reporter ){
       print("Missing usage reporter tool: $reporter\n");
       return;
   }

   trun_system_cmd("$reporter $rargs", 0);

   return;
}

print("*************************  NOTICE ********************************\n");
print("*                                                                *\n");
print("* This script 'RCcalc.pl' has been moved out of alpha_common/bin *\n");
print("* It is now located in 'msip_shell_wiremodel_utils' 2022.03      *\n");
print("*                                                                *\n");
print("* The script has been renamed to 'msip_wiremodelRCalc'           *\n");
print("*                                                                *\n");
print("******************************************************************\n");

if ( exists( $ENV{'USER'} ) and ("$ENV{'USER'}" ne "ljames") ){
    tutils__script_usage_statistics( $RealScript, "2022ww14");
}

exit(-1);

