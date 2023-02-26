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


############################################################################
## Author        : Nandagopan G                                            #
## Functionality : grep device-length combination for variation generation # 
############################################################################



sub Main {
my (@device, @device_lay, $find, $FR, $FW_lay, @length, @length_lay, $len_passed, $len_um, $line, $path, $unit, $val);




if ($ARGV[0] eq "-help" || $ARGV[0] eq "")
{
  Util::Messaging::iprint("Usage : variation_device_grep.pl <path of NT netlist [both sp and spf should be in same directory]> \n");
  exit(0);
}
$path = $ARGV[0];
#@netlist = glob("$path/*.spf");
my ($stdout, $stderr)   =    run_system_cmd   ("rm -rf variation_devices; mkdir variation_devices", "$VERBOSITY");
my ($stdout0, $stderr0) =  run_system_cmd   ("cat $path/*.spf | sed -n '/Instance/,/ENDS/p' | grep -v '*' >> variation_devices/merged_netlist", "$VERBOSITY");
my ($stdout1, $stderr1) =  run_system_cmd   ("cat $path/*.sp | grep -v '*' >> variation_devices/merged_sch_netlist", "$VERBOSITY");
my ($stdout2, $stderr2) =  run_system_cmd   ("sed 's/ /\\n/g' variation_devices/merged_netlist > variation_devices/merged_text_to_word_netlist", "$VERBOSITY");
my ($stdout3, $stderr3) =  run_system_cmd   ("sed 's/ /\\n/g' variation_devices/merged_sch_netlist > variation_devices/merged_text_to_word_sch_netlist", "$VERBOSITY");

my ($stdout4, $stderr4) =  run_system_cmd   ("mv variation_devices/merged_text_to_word_sch_netlist variation_devices/merged_sch_netlist", "$VERBOSITY");
#my ($stdout, $stderr) = capture { run_system_cmd   ("mv merged_text_to_word_netlist merged_netlist");

my ($length_lay, $syserr1)  = run_system_cmd("egrep '^l=[0-9]\\w*' './variation_devices/merged_text_to_word_netlist' | sort -u", $VERBOSITY);
my ($length, $syserr2)       = run_system_cmd("egrep '^l=[0-9]\\w*' './variation_devices/merged_sch_netlist' | sort -u", $VERBOSITY);
my ($device_lay, $syserr3)  = run_system_cmd("egrep 'nch|pch|nfet|pfet' './variation_devices/merged_text_to_word_netlist' | sort -u", $VERBOSITY);
my ($device, $syserr4)      = run_system_cmd("egrep 'nch|pch|nfet|pfet' './variation_devices/merged_sch_netlist' | sort -u", $VERBOSITY);

@length_lay = split("\n",$length_lay);
@length     = split("\n",$length);
@device_lay = split("\n",$device_lay);
@device     = split("\n",$device);

#print("@length_lay\n");
#print("@device_lay\n");

my ($stdout5, $stderr5) = run_system_cmd   ("egrep '^l=[0-9]\\w*' './variation_devices/merged_text_to_word_netlist' | sort -u > all_len_lay", "$VERBOSITY"); 
my ($stdout6, $stderr6) = run_system_cmd   ("egrep '^l=[0-9]\\w*' './variation_devices/merged_sch_netlist' | sort -u > all_len", "$VERBOSITY");
my ($stdout7, $stderr7) = run_system_cmd   ("egrep 'nch|pch|nfet|pfet' './variation_devices/merged_text_to_word_netlist' | sort -u > all_device_lay", "$VERBOSITY");
my ($stdout8, $stderr8) = run_system_cmd   ("egrep 'nch|pch|nfet|pfet' './variation_devices/merged_sch_netlist' | sort -u > all_device", "$VERBOSITY");


#open ($FR_lay,"<merged_netlist");
my @FW_lay;

foreach my $dev_lay (@device_lay)
{
  #print("dev\n");
  chomp($dev_lay);
  foreach my $len_lay (@length_lay)
  {
    #print ("Hi\n");
    chomp($len_lay);
    ($find,$syserr1)  = run_system_cmd("egrep '$dev_lay.*$len_lay | $len_lay.*$dev_lay' variation_devices/merged_netlist | head -1", "$VERBOSITY"); 
    
    #print ("$find\n");
    push @FW_lay, $find;
  }  
}    

my $writeStatus = Util::Misc::write_file(\@FW_lay,"./variation_devices/sorted_devices_layout",'>');

my $len_length = @length;

my  $i = $len_length;

while($i)
{
  if ($length[$i-1] =~ /l=(\d+\.?(\d+)?)[a-z]/)
  {
    $len_passed = $length[$i-1];
    chomp($len_passed);
    ($val,$syserr1) = run_system_cmd("echo '$len_passed' | cut -d '=' -f2", $VERBOSITY);
    chomp($val);
    $unit=chop($val);
    #print("$val\n");
    if ($unit eq "n")
    {
      $val = $val/1000; 
    }
    elsif ($unit eq "u")
    {
      $val = $val/1;
    }
    ($len_um,$syserr1) = run_system_cmd("echo 'l=${val}u'", $VERBOSITY);
  }
  
  $length[$i-1] = $len_um;

  $i = $i-1;

}

#my ($stdout, $stderr) = capture { run_system_cmd   ("egrep '^l=[0-9]\w*' merged_sch_netlist | sort -u > all_lengths");
#my ($stdout, $stderr) = capture { run_system_cmd   ("egrep 'nch|pch' merged_sch_netlist | sort -u > all_devices");
#print ("after converting : @length\n");

#print "@length\n";
#print "@device\n";

## Converting newline starting with "+" to space i.e. to a single line ##
#my ($stdout, $stderr) = capture { run_system_cmd   (q(perl -0777 -pe 's/\n\+ ?/ /g' < merged_sch_netlist > merged_sch_netlist_in_one_line));
#my ($stdout, $stderr) = capture { run_system_cmd   ("cp -rf merged_sch_netlist_in_one_line merged_sch_netlist_check");
#my ($stdout, $stderr) = capture { run_system_cmd   ("mv merged_sch_netlist_in_one_line merged_sch_netlist");
#exit;
my @FR = Util::Misc::read_file("./variation_devices/sorted_devices_layout");

NEXT_LINE :

foreach my $line (@FR)
{
  foreach my $dev (@device)
  {
    foreach my $len (@length)
    {
      chomp($line);
      chomp($dev);
      chomp($len);

      if ($line =~ $dev)
      {
        #if ($len =~ /l=(\d+\.?\d+)[a-z]/)
        #{
        #$len_um = convert($len);
        #print("$len_nm\n");
        #chomp($len_um);
        
          if ($line =~ $len)
          {
            my ($stdout9, $stderr9) = run_system_cmd  ("echo '$dev,$len' >> variation_devices/device_length_rpt", "$VERBOSITY");
            goto NEXT_LINE;
          }
       # }
      }

    }
  }
} 

my ($stdout10, $stderr10) =  run_system_cmd   ("cat variation_devices/device_length_rpt | sort -u > variation_devices/grepped_device_sort; mv variation_devices/grepped_device_sort variation_devices/device_length_rpt", "$VERBOSITY");


my ($stdout11, $stderr11) =  run_system_cmd   ("rm -rf variation_devices/merged_netlist variation_devices/merged_sch_netlist variation_devices/merged_text_to_word_netlist variation_devices/sorted_devices_layout", "$VERBOSITY");

}
