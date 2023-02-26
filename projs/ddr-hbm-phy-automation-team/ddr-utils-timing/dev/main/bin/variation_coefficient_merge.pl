#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Cwd;

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




########################################################################################
## Author        : Nandagopan G                                                        #
## Functionality : For merging variation coefficients of different voltage to one file # 
########################################################################################
sub Main() {
my ($stdout,$stderr) = capture { run_system_cmd("rm -rf variation_coefficient_merged","$VERBOSITY"); };

if ($ARGV[0] eq "-help")
{
  Util::Messaging::iprint("Usage : variation_coefficient_merge.pl <path 1 where etm directory is present> <path 2 where etm directory is present> ...\n");
  exit(0);
}

my $a = @ARGV;

if ($a == 0)
{
  print ("Please type \"variation_coefficient_merge.pl -help\" for usage\n");
  exit;
}

my ($stdout1,$stderr1) = run_system_cmd("mkdir variation_coefficient_merged","$VERBOSITY");
chdir("variation_coefficient_merged");
my ($stdout2,$stderr2) = run_system_cmd("touch pvt","$VERBOSITY");
my ($stdout3,$stderr3) = run_system_cmd("ls $ARGV[0]/ | grep etm | cut -d '_' -f2 | sort -u >> pvt","$VERBOSITY");

my @FR = Util::Misc::read_file("pvt");
foreach my $b (@FR)
{
  chomp $b;
  my ($stdout4,$stderr4) = run_system_cmd("mkdir -p Run_${b}_etm/xtor_variations","$VERBOSITY");
  my ($stdout5,$stderr5) = run_system_cmd("touch Run_${b}_etm/xtor_variations/set_variation_parameters.tcl","$VERBOSITY");
  my $i = 0;
  while ($i < $a)
  {
    my ($stdout6,$stderr6) = run_system_cmd("cat $ARGV[$i]/Run_${b}_etm/xtor_variations/set_variation_parameters.tcl >> Run_${b}_etm/xtor_variations/set_variation_parameters.tcl","$VERBOSITY");
    $i = $i+1;
  }
}
}
