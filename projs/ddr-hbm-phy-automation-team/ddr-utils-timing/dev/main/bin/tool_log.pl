#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd;
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $PREFIX       = "ddr-utils-timing";
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#



use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);


utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);

#########################################################################
BEGIN { our $AUTHOR='DA WG'; header(); } 
&Main();
END {
   write_stdout_log("$LOGFILENAME");
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}



sub Main {

my ($FR, $macro, $p, $paths, $tool, $db_pg_time, $db_time , $lib_pg_time, $lib_time);

my $help = process_cmd_line_args();

if (defined $help)
{
  Util::Messaging::iprint("Usage : tool_log.pl <path till macro directory> <macro name> <sis/nt>\n");
  exit(0);
}

if ($ARGV[0] eq "" | $ARGV[1] eq "" | $ARGV[2] eq "")
{
  Util::Messaging::eprint("Usage : tool_log.pl <path till macro directory> <macro name> <sis/nt>\n");
  exit(1);
}


$paths = $ARGV[0];


$macro = $ARGV[1];

$tool = $ARGV[2];



chdir("$paths/$macro");
my ($stdout1, $stderr1) =  run_system_cmd   ("rm -rf grep_result", "$VERBOSITY");
my ($stdout2, $stderr2) =  run_system_cmd   ("mkdir grep_result", "$VERBOSITY");


if (lc($tool) eq "sis")
{
  my ($pvt_no,$stderrr1) = run_system_cmd("ls lib_pg/*.lib | wc -l",$VERBOSITY);  
#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("egrep -i 'I am executing a custom post-proc command|Program time' run_char*.log > grep_result/run_char_run_end.txt");
#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("egrep -i 'I am executing a custom post-proc command|Program time' char_*c/siliconsmart.log > grep_result/sis_run_end.txt");
#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("egrep -i 'setup|hold' lib*/*.lib | grep -v 'threshold_pct' > grep_result/setup_hold.txt");
#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("egrep -i 'error|failed' run_char_*.log | grep -v -i ', 0 Failed' > grep_result/error_run_char.txt");
#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("egrep -i 'error|failed' char_*c/siliconsmart.log | grep -v -i ', 0 Failed' > grep_result/error_siliconsmart.txt");
#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("egrep -i 'siliconsmart|finesim|hspice' char_*c/siliconsmart.log | egrep 'SiliconSmart version|Simulator used' >  grep_result/tool_version.txt");
#######################################################################################db_count####################################################
  #open(my $db_count, ">","grep_result/lib_db_count") or die "Could not open file $!";
  my @db_count;
  my @import; 
  my ($lib_lib_count,$stderrr3) = run_system_cmd("ls lib/*.lib | wc -l",$VERBOSITY);
  my ($lib_db_count,$stderrrr4) = run_system_cmd("ls lib/*.db | wc -l",$VERBOSITY);
  my ($lib_pg_lib_count,$stderr5) = run_system_cmd("ls lib_pg/*.lib | wc -l",$VERBOSITY);
  my ($lib_pg_db_count,$stderr6) = run_system_cmd("ls lib_pg/*.db | wc -l",$VERBOSITY);
  push @db_count ,"lib:   lib count is  $lib_lib_count";
  push @db_count ,"lib:   db count is   $lib_db_count";
  push @db_count ,"lib_pg:lib count is  $lib_pg_lib_count";
  push @db_count ,"lib_pg:db count is   $lib_pg_db_count";
  my $status1 = write_file(\@db_count,"grep_result/lib_db_count");
#######################################################################################db_count####################################################

#######################################################################################import####################################################
  #open(my $import, ">","grep_result/import") or die "Could not open file $!";
  my ($import_count,$stderrr7) = run_system_cmd("egrep 'Begin import|Done import' char_*c/siliconsmart.log | wc -l",$VERBOSITY);
  push @import ,"===================================================\n";
  push @import ,"== import count (Should be twice that of corner) ==\n";
  push @import ,"===================================================\n\n";
  push @import ,"import count: $import_count";
  push @import ,"pvtcorner count: $pvt_no";
  if($import_count == eval{2*$pvt_no}) {
   push @import ,"import STATUS: PASS";
  } else {
   push @import ,"import STATUS: FAIL";
  }
  my $status2 = write_file(\@import,"grep_result/import");

#######################################################################################import####################################################

#######################################################################################configure####################################################
  #open(my $configure, ">","grep_result/configure") or die "Could not open file $!";
  my @configure;
  my ($configure_count,$stderrr8) = run_system_cmd("egrep 'Begin configure|Done configure' char_*c/siliconsmart.log | wc -l",$VERBOSITY);
  push @configure, "======================================================\n";
  push @configure, "== Configure count (Should be twice that of corner) ==\n";
  push @configure ,"======================================================\n\n";
  push @configure ,"Configure count: $configure_count";
  push @configure ,"pvtcorner count: $pvt_no";
  if($configure_count == eval{2*$pvt_no}) {
   push @configure ,"Configure STATUS: PASS";
  } else {
   push @configure ,"Configure STATUS: FAIL";
  }
  my $status3 = write_file(\@configure,"grep_result/configure");
#######################################################################################configure####################################################

#########################################################################################characterize##################################################
  #open(my $characterize, ">","grep_result/characterize") or die "Could not open file $!";
  my @characterize;
  my ($characterize_count,$stderrr9) = run_system_cmd("egrep 'Begin characterize|Done characterize' char_*c/siliconsmart.log | wc -l",$VERBOSITY);
  push @characterize ,"=========================================================\n";
  push @characterize ,"== characterize count (Should be twice that of corner) ==\n";
  push @characterize ,"=========================================================\n\n";
  push @characterize ,"characterize count: $characterize_count";
  push @characterize ,"pvtcorner count: $pvt_no";
  if($characterize_count == eval{2*$pvt_no}) {
   push @characterize ,"characterize STATUS: PASS";
  } else {
   push @characterize ,"characterize STATUS: FAIL";
  }
  my $status4 = write_file(\@characterize,"grep_result/characterize");
#########################################################################################characterize##################################################

##########################################################################################model#################################################################
  #open(my $model, ">","grep_result/model") or die "Could not open file $!";
  my @model;
  my ($model_count,$stderrr10) = run_system_cmd("egrep 'Begin model|Done model' char_*c/siliconsmart.log | wc -l",$VERBOSITY);
  push @model ,"==================================================\n";
  push @model, "== model count (Should be twice that of corner) ==\n";
  push @model, "==================================================\n\n";
  push @model ,"model count: $model_count";
  push @model ,"pvtcorner count: $pvt_no";
  if($model_count == eval{2*$pvt_no}) {
   push @model ,"model STATUS: PASS";
  } else {
   push @model ,"model STATUS: FAIL";
  }
  my $status5 = write_file(\@model,"grep_result/model");
#########################################################################################model########################################################################


 my ($stdout3, $stderr3) =  run_system_cmd   ("egrep 'SiliconSmart version' char_*c/siliconsmart.log | awk '{print \$NF}' | sort -u > grep_result/SiS_version.txt", "$VERBOSITY");
} 

elsif (lc($tool) eq "nt")
{

  my ($stdout4, $stderr4) =  run_system_cmd   ("egrep -i 'error|failed' timing/*/timing.log > grep_result/timing_error.log", "$VERBOSITY");
  my ($stdout5, $stderr5) =  run_system_cmd   ("egrep -i 'error|failed' timing/*/NT.err > grep_result/NT_err.log", "$VERBOSITY");
  my ($stdout6, $stderr6) =  run_system_cmd   ("egrep -i 'error|failed' ntManager*.log > grep_result/ntmanager_error.log", "$VERBOSITY");
  #my ($stdout1, $stderr1) = capture { run_system_cmd   ("grep -i 'hspice' timing/*/* | grep -i 'HSPICE' > grep_result/hspice_version");
  my ($stdout7, $stderr7) =  run_system_cmd   ("grep -i -A2 'nanotime' timing/*/timing.log | grep -i 'version' | awk '{print \$3}' | sort -u > grep_result/nt_version", "$VERBOSITY");
  my ($stdout8, $stderr8) =  run_system_cmd   ("egrep -i 'setup|hold' lib*/*.lib | grep -v 'threshold_pct' > grep_result/setup_hold.txt", "$VERBOSITY");
  my ($stdout9, $stderr9) =  run_system_cmd   ("grep '.lib created successfully' ntManager*.log | wc > grep_result/lib_create_count", "$VERBOSITY");
  my ($stdout10, $stderr10) =  run_system_cmd   ("echo lib > grep_result/lib_db_count", "$VERBOSITY");
  my ($stdout11, $stderr11) =  run_system_cmd   ("ls lib/*.lib | wc >> grep_result/lib_db_count", "$VERBOSITY");
  my ($stdout12, $stderr12) =  run_system_cmd   ("echo lib_db >> grep_result/lib_db_count", "$VERBOSITY");
  my ($stdout13, $stderr13) =  run_system_cmd   ("ls lib/*.db | wc >> grep_result/lib_db_count", "$VERBOSITY");
  my ($stdout14, $stderr14) =  run_system_cmd   ("echo lib_pg >> grep_result/lib_db_count", "$VERBOSITY");
  my ($stdout15, $stderr15) =  run_system_cmd   ("ls lib_pg/*.lib | wc >> grep_result/lib_db_count", "$VERBOSITY");
  my ($stdout16, $stderr16) =  run_system_cmd   ("echo lib_pg_db >> grep_result/lib_db_count", "$VERBOSITY");
  my ($stdout17, $stderr17) =  run_system_cmd   ("ls lib_pg/*.db | wc >> grep_result/lib_db_count", "$VERBOSITY");
  my ($stdout18, $stderr18) =  run_system_cmd   ("grep -i 'Diagnostics summary' timing/*/timing.log | wc > grep_result/timing_log_end", "$VERBOSITY");
  my ($stdout19, $stderr19) =  run_system_cmd   ("grep -i 'stack trace' timing/*/timing.log | wc > grep_result/stack_trace", "$VERBOSITY");
}

my ($stdout20, $stderr20) =  run_system_cmd   ("touch grep_result/lib_wc", "$VERBOSITY");
my ($stdout21, $stderr21) =  run_system_cmd   ("touch grep_result/lib_size grep_result/lib_pg_size grep_result/db_size grep_result/db_pg_size", "$VERBOSITY");
my ($stdout22, $stderr22) =  run_system_cmd   ("touch grep_result/lib_pg_wc", "$VERBOSITY");
my ($stdout23, $stderr23) =  run_system_cmd   ("echo '  wc  lib' >> grep_result/lib_wc", "$VERBOSITY");
my ($stdout24, $stderr24) =  run_system_cmd   ("echo '  wc  lib_pg' >> grep_result/lib_pg_wc", "$VERBOSITY");
my ($stdout25, $stderr25) =  run_system_cmd   ("wc -l lib/*.lib >> grep_result/lib_wc", "$VERBOSITY");
my ($stdout26, $stderr26) =  run_system_cmd   ("wc -l lib_pg/*.lib >> grep_result/lib_pg_wc", "$VERBOSITY");
my ($stdout27, $stderr27) =  run_system_cmd   ("du -ch lib/*.lib | grep -v total >> grep_result/lib_size", "$VERBOSITY");
my ($stdout28, $stderr28) =  run_system_cmd   ("du -ch lib/*.db | grep -v total >> grep_result/db_size", "$VERBOSITY");
my ($stdout29, $stderr29) =  run_system_cmd   ("du -ch lib_pg/*.lib | grep -v total >> grep_result/lib_pg_size", "$VERBOSITY");
my ($stdout30, $stderr30) =  run_system_cmd   ("du -ch lib_pg/*.db | grep -v total >> grep_result/db_pg_size", "$VERBOSITY");

my ($stdout31, $stderr31) =  run_system_cmd   ("rm -rf pvt", "$VERBOSITY");
my ($stdout32, $stderr32) =  run_system_cmd   ("ls lib/*.lib | cut -d '.' -f1 | rev | cut -d '_' -f1 | rev > pvt", "$VERBOSITY");
my ($stdout33, $stderr33) =  run_system_cmd   ("rm -rf grep_result/lib.txt grep_result/lib_pg.txt grep_result/function.txt grep_result/lib_pg_db_time_stamp grep_result/lib_db_time_stamp", "$VERBOSITY");
#my ($stdout1, $stderr1) = capture { run_system_cmd   ("touch grep_result/lib_neg_delay.txt");
#my ($stdout1, $stderr1) = capture { run_system_cmd   ("touch grep_result/lib_pg_neg_delay.txt");
#my ($stdout1, $stderr1) = capture { run_system_cmd   ("touch grep_result/function_lib.txt");
#my ($stdout1, $stderr1) = capture { run_system_cmd   ("touch grep_result/function_lib_pg.txt");
#open(my $lib_neg_delay, ">","grep_result/lib_neg_delay.txt") or die "Could not open file $!";
#open(my $lib_pg_neg_delay, ">","grep_result/lib_pg_neg_delay.txt") or die "Could not open file $!";
#open(my $related_power_gnd_pin, ">","grep_result/related_power_gnd_pin") or die "Could not open file $!";
#open(my $function_lib, ">","grep_result/function_lib.txt") or die "Could not open file $!";
#open(my $function_lib_pg, ">","grep_result/function_lib_pg.txt") or die "Could not open file $!";
#open(my $lib_zero_val, ">","grep_result/lib_zero_val.txt") or die "Could not open file $!";
#open(my $lib_pg_zero_val, ">","grep_result/lib_pg_zero_val.txt") or die "Could not open file $!";
#my ($stdout1, $stderr1) = capture { run_system_cmd   ("touch grep_result/related_power_gnd_pin");

my @lib_neg_delay;
my @lib_pg_neg_delay;
my @related_power_gnd_pin;
my @function_lib;
my @function_lib_pg;
my @lib_zero_val;
my @lib_pg_zero_val;

my ($stdout34, $stderr34) =  run_system_cmd   ("touch grep_result/lib_pg_db_time_stamp", "$VERBOSITY");
my ($stdout35, $stderr35) =  run_system_cmd   ("touch grep_result/lib_db_time_stamp", "$VERBOSITY");
my ($stdout36, $stderr36) =  run_system_cmd   ("Corners:\n", "$VERBOSITY");

my @PVT_FR = read_file("pvt");
foreach my $p (@PVT_FR)
{
  chomp($p);
#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("echo ${p} >> grep_result/lib_neg_delay.txt");
# my ($stdout1, $stderr1) = capture { run_system_cmd   ("echo ${p} >> grep_result/lib_pg_neg_delay.txt");

#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("echo ${p} >> grep_result/function_lib.txt");
#################################################################function_lib######################################################################################
  push @function_lib ,"$p:\n";
  my ($find_finction_lib,$stderrr11) = run_system_cmd("grep -n 'function' lib/*$p*.lib",$VERBOSITY);
  if($stderrr11) {
  push @function_lib ,"STATUS: PASS\n";
  push @function_lib ,"Info  : No function is present\n\n";
  } else {
    if($ARGV[1] =~ /clk/) {
      push @function_lib ,"$find_finction_lib";
      push @function_lib ,"STATUS : PASS\n";
      push @function_lib ,"Warning: function is present. But it can be waived in clock cells.\n\n";
    } else {
      push @function_lib ,"$find_finction_lib";
      push @function_lib ,"STATUS : FAIL\n\n";
    }
  }
#################################################################function_lib######################################################################################	

#################################################################function_lib_pg######################################################################################
  push @function_lib_pg ,"$p:\n";
  my ($find_finction_lib_pg,$stderrr12) = run_system_cmd("grep -n 'function' lib_pg/*$p*.lib",$VERBOSITY);
  if($stderrr12) {
  push @function_lib_pg ,"STATUS: PASS\n";
  push @function_lib_pg ,"Info  : No function is present\n\n";
  } else {
    if($ARGV[1] =~ /clk/) {
      push @function_lib_pg ,"$find_finction_lib";
      push @function_lib_pg ,"STATUS : PASS\n";
      push @function_lib_pg ,"Warning: function is present. But it can be waived in clock cells.\n\n";
    } else {
      push @function_lib_pg ,"$find_finction_lib";
      push @function_lib_pg ,"STATUS : FAIL\n\n";
    }
  }
#################################################################function_lib_pg######################################################################################	 



#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("echo ${p} >> grep_result/function_lib_pg.txt");
#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("echo ${p} >> grep_result/lib_zero_val.txt");
#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("echo ${p} >> grep_result/lib_pg_zero_val.txt");
#  my ($stdout1, $stderr1) = capture { run_system_cmd   ("echo ${p} >> grep_result/related_power_gnd_pin");
  my ($stdout37, $stderr37) =  run_system_cmd   ("echo '$p' >> grep_result/lib_pg_db_time_stamp", "$VERBOSITY");
  my ($stdout38, $stderr38) =  run_system_cmd   ("echo '$p' >> grep_result/lib_db_time_stamp", "$VERBOSITY");



##########################################################################################related_power_gnd_pin#######################################################################  
  push @related_power_gnd_pin ,"$p\n";
  my ($related_power_pin,$stderrr13) = run_system_cmd("grep -c 'related_power_pin' lib_pg/*$p*.lib",$VERBOSITY);
  my ($related_ground_pin,$stderrr14) = run_system_cmd("grep -c 'related_ground_pin' lib_pg/*$p*.lib",$VERBOSITY);
  my ($related_pg_pin,$stderrr15) = run_system_cmd("grep -c 'pg_pin.*{' lib_pg/*$p*.lib",$VERBOSITY);
  push @related_power_gnd_pin ,"No of related_power_pin: $related_power_pin";
  push @related_power_gnd_pin ,"No of related_ground_pin: $related_ground_pin";  
  push @related_power_gnd_pin ,"No of pg_pins: $related_pg_pin\n";  
##########################################################################################related_power_gnd_pin#######################################################
 
#############################################################################################lib_neg_delay##################################################################
    my ($stdout1, $stderr1) =  run_system_cmd   ("cat -n lib/*$p*.lib  | egrep -v 'k_process|k_temp|k_volt' > grep_result/lib_with_line", "$VERBOSITY");
    my ($cell_rise_lib,$stderrr16) = run_system_cmd("sed -n '/cell_rise/,/}/p' grep_result/lib_with_line | grep '\\-[0-9]' | grep -v 'e\-'",$VERBOSITY);
    my ($cell_fall_lib,$stderrr17) = run_system_cmd("sed -n '/cell_fall/,/}/p' grep_result/lib_with_line | grep '\\-[0-9]' | grep -v 'e\-'",$VERBOSITY);
    my ($rise_transition_lib,$stderrr1) = run_system_cmd("sed -n '/rise_transition/,/}/p' grep_result/lib_with_line | grep '\\-[0-9]' | grep -v 'e\-'",$VERBOSITY);
    my ($fall_transition_lib,$stderrr2) = run_system_cmd("sed -n '/fall_transition/,/}/p' grep_result/lib_with_line | grep '\\-[0-9]' | grep -v 'e\-'",$VERBOSITY);
    my ($mpw_lib,$stderr3) = run_system_cmd("sed -n '/min_pulse_width/,/}/p' grep_result/lib_with_line | grep '\\-[0-9]' | grep -v 'e\-'",$VERBOSITY);
#    print "min_pulse_width: $mpw_lib\n";


    if ($stderrr16 and $stderrr17 and $stderrr1 and $stderrr2 and $stderr3 ) {
       push @lib_neg_delay ,"$p: STATUS: PASS\n";
    } else {
        push @lib_neg_delay ,"$p: STATUS: FAIL\n";
        push @lib_neg_delay ,"$cell_rise_lib" if(length $cell_rise_lib > 1);
        push @lib_neg_delay ,"$cell_fall_lib" if(length $cell_fall_lib > 1);
        push @lib_neg_delay ,"$rise_transition_lib" if(length $rise_transition_lib > 1);
        push @lib_neg_delay ,"$fall_transition_lib" if (length $rise_transition_lib > 1);
        push @lib_neg_delay ,"$mpw_lib" if(length $mpw_lib > 1);
    }

#############################################################################################lib_neg_delay##################################################################

#############################################################################################lib_pg_neg_delay##################################################################
    my ($stdout39, $stderr39) =  run_system_cmd   ("cat -n lib_pg/*$p*.lib | egrep -v 'k_process|k_temp|k_volt' > grep_result/lib_pg_with_line", "$VERBOSITY");

    my ($cell_rise_lib_pg,$stderrr3) = run_system_cmd("sed -n '/cell_rise/,/}/p' grep_result/lib_pg_with_line | grep '\\-[0-9]' | grep -v 'e\-'",$VERBOSITY);
    my ($cell_fall_lib_pg,$stderrr4) = run_system_cmd("sed -n '/cell_fall/,/}/p' grep_result/lib_pg_with_line | grep '\\-[0-9]' | grep -v 'e\-'",$VERBOSITY);
    my ($rise_transition_lib_pg,$stderr5) = run_system_cmd("sed -n '/rise_transition/,/}/p' grep_result/lib_pg_with_line | grep '\\-[0-9]' | grep -v 'e\-'",$VERBOSITY);
    my ($fall_transition_lib_pg,$stderr6) = run_system_cmd("sed -n '/fall_transition/,/}/p' grep_result/lib_pg_with_line | grep '\\-[0-9]' | grep -v 'e\-'",$VERBOSITY);
    my ($mpw_lib_pg,$stderr7) = run_system_cmd("sed -n '/min_pulse_width/,/}/p' grep_result/lib_with_line | grep '\\-[0-9]' | grep -v 'e\-'",$VERBOSITY);
#    print "min_pulse_width: $mpw_lib_pg\n";

    if ($stderrr3  and $stderrr4 and $stderr5 and $stderr6 and $stderr7 ) {
        push @lib_pg_neg_delay ,"$p: STATUS: PASS\n";
    } else {
        push @lib_pg_neg_delay ,"$p: STATUS: FAIL\n";
        push @lib_pg_neg_delay ,"$cell_rise_lib_pg" if(length $cell_rise_lib_pg > 1);
        push @lib_pg_neg_delay ,"$cell_fall_lib_pg" if(length $cell_fall_lib_pg > 1);
        push @lib_pg_neg_delay ,"$rise_transition_lib_pg" if(length $rise_transition_lib_pg > 1);;
        push @lib_pg_neg_delay ,"$fall_transition_lib_pg" if(length $fall_transition_lib_pg > 1);
        push @lib_pg_neg_delay ,"$mpw_lib_pg" if(length $mpw_lib_pg > 1);
    }

#############################################################################################lib_pg_neg_delay##################################################################

#############################################################################################lib_zero_val##################################################################
  push @lib_zero_val ,"$p: ";

  my ($lib_zero_val_value,$stderrr7) = run_system_cmd("cat -n lib/*$p*.lib | egrep -v 'k_process|k_temp|k_volt' | egrep -w ' 0.0| 0.00| 0.000| 0\,| 0.0000| 0.0000| 0.00000| 0.000000|\"0.0|\"0.00|\"0\,|\"0.000|\"0.0000|\"0.0000|\"0.00000|\"0.000000' | egrep -v 'process|tempe|pct|index|derate|default_output_pin_cap'",$VERBOSITY);
  if ($stderrr7) {
   push @lib_zero_val ,"STATUS: PASS\n\n";
  } else {
   push @lib_zero_val ,"STATUS: FAIL\n\n";
   push @lib_zero_val ,"$lib_zero_val_value\n";
  }
#############################################################################################lib_zero_val##################################################################

#############################################################################################lib_pg_zero_val##################################################################
 push @lib_pg_zero_val ,"$p: ";

  my ($lib_pg_zero_val_value,$stderrr8) = run_system_cmd("cat -n lib_pg/*$p*.lib | egrep -v 'k_process|k_temp|k_volt' | egrep -w ' 0.0| 0.00| 0.000| 0\,| 0.0000| 0.0000| 0.00000| 0.000000|\"0.0|\"0.00|\"0\,|\"0.000|\"0.0000|\"0.0000|\"0.00000|\"0.000000' | egrep -v 'process|tempe|pct|index|derate|default_output_pin_cap'",$VERBOSITY);
  chomp($lib_pg_zero_val_value);
  if ($stderrr8) {
   push @lib_pg_zero_val ,"STATUS: PASS\n\n";
  } else {
   push @lib_pg_zero_val ,"STATUS: FAIL\n\n";
   push @lib_pg_zero_val ,"$lib_pg_zero_val_value\n";
  }
#############################################################################################lib_pg_zero_val##################################################################

  
  my $lib_pg_name = glob("lib_pg/*$p*.lib") || "";
  my $lib_name = glob("lib/*$p*.lib") || "";
  my $db_pg_name = glob("lib_pg/*$p*.db") || "";
  my $db_name = glob("lib/*$p*.db") || "";
  if (-e $lib_pg_name) {
      ($lib_pg_time,$stderrr1) = run_system_cmd("stat -c %Y lib_pg/*$p*.lib",$VERBOSITY);
  }
  if (-e $lib_pg_name) {
      ($lib_time,$stderrr1) = run_system_cmd("stat -c %Y lib/*$p*.lib",$VERBOSITY);
  }
  if (-e $db_pg_name) {
      ($db_pg_time,$stderrr1) = run_system_cmd("stat -c %Y lib_pg/*$p*.db",$VERBOSITY);
  }
  if (-e $db_name) {
      ($db_time,$stderrr1) = run_system_cmd("stat -c %Y lib/*$p*.db",$VERBOSITY);
  }
  
  if ((defined $lib_pg_time) && (defined $lib_time) && defined($db_pg_time)) {
      if ($lib_pg_time > $db_pg_time) {
     my ($stdout42, $stderr42) =  run_system_cmd   ("echo 'ISSUE : PLEASE COMPILE AGAIN' >> grep_result/lib_pg_db_time_stamp", "$VERBOSITY");
  } else {
     my ($stdout43, $stderr43) =  run_system_cmd   ("echo 'STATUS: PASS\n' >> grep_result/lib_pg_db_time_stamp", "$VERBOSITY");
  }
}
   if ((defined $lib_time) && (defined $db_time) && ($lib_time > $db_time)) {
     my ($stdout44, $stderr44) =  run_system_cmd   ("echo 'ISSUE : PLEASE COMPILE AGAIN' >> grep_result/lib_db_time_stamp", "$VERBOSITY");
  } else {
     my ($stdout45, $stderr45) =  run_system_cmd   ("echo 'STATUS: PASS\n' >> grep_result/lib_db_time_stamp", "$VERBOSITY");
  }
}
#print "$paths/$macro # $ARGV[0] ##$ARGV[1]\n";
iprint("Running operating_condition.pl\n");
my ($st1,$ste1) = run_system_cmd("$RealBin/operating_condition.pl $ARGV[0]",$VERBOSITY);
iprint("Running min_cap_max_cap.pl\n");
my ($st2,$ste2) = run_system_cmd("$RealBin/min_cap_max_cap.pl",$VERBOSITY);
iprint("Running max_capacitance.pl\n")
;my ($st3,$ste3) = run_system_cmd("$RealBin/max_capacitance.pl -lib $ARGV[0]/$ARGV[1]/lib_pg",$VERBOSITY);

#print("$ste1\n");
#print("***\n$ste2\n");
#print("##\n$ste3\n");
my $status_1 = write_file(\@lib_neg_delay, "grep_result/lib_neg_delay.txt" ); 
my $status_2 = write_file(\@lib_pg_neg_delay,"grep_result/lib_pg_neg_delay.txt");
my $status_3 = write_file(\@related_power_gnd_pin,"grep_result/related_power_gnd_pin") ;
my $status_4 = write_file(\@function_lib, "grep_result/function_lib.txt"); 
my $status_5 = write_file(\@function_lib_pg, "grep_result/function_lib_pg.txt");
my $status_6 = write_file(\@lib_zero_val, "grep_result/lib_zero_val.txt");
my $status_7 = write_file(\@lib_pg_zero_val, "grep_result/lib_pg_zero_val.txt");
return(0);
}

sub process_cmd_line_args(){
    my ($opt_dryrun, $opt_debug,  $opt_verbosity, $opt_help);

    my $success = GetOptions(
        "dryrun!"     => \$opt_dryrun,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "help"        => \$opt_help,           # Prints help
     );

    if( defined $opt_dryrun ){
        $main::TESTMODE = TRUE;
    }

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    #&usage(1) unless( defined $opt_projSPEC );
   
   return($opt_help);
};
