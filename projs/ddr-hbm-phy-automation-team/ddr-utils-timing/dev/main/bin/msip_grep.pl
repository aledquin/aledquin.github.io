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
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = Cwd::getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || 2022.11; # Syntax: YYYYww##[.#] optional day 1-7
                                # The work week number can be found in
                                # your outlook calendar. The days are 1=sunday
                                # 2=monday ... 7=saturday
#--------------------------------------------------------------------#

use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

utils__script_usage_statistics("$PREFIX-$RealScript", $VERSION);

BEGIN { our $AUTHOR='DA WG'; header(); } 
&Main();
#&_run_unit_tests();
END {
   Util::Messaging::write_stdout_log($LOGFILENAME);
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}

#################################################################
## Author        : Nandagopan G                                 #
## Functionality : Grep logs from msip quality check folder     # 
#################################################################
sub Main {
  my ($stdout, $stderr) = capture { run_system_cmd ("rm -rf msip_grep", "$VERBOSITY");};
  my ($stdout1, $stderr1) = capture { run_system_cmd ("mkdir msip_grep", "$VERBOSITY");};
#system ("touch msip_grep/count");
  my ($stdout2, $stderr2) = capture { run_system_cmd  ("touch msip_grep/checks.txt", "$VERBOSITY");};
  my ($stdout3, $stderr3) = capture { run_system_cmd  ("touch msip_grep/error_run_log.txt", "$VERBOSITY");};
  my ($stdout4, $stderr4) = capture { run_system_cmd  ("echo 'mandatory checks' >> msip_grep/checks.txt", "$VERBOSITY");};
  my ($stdout5, $stderr5) = capture { run_system_cmd  ("echo 'checkArc,checkBusOrder,checkDerate,checkDuplicateAttributes,checkMaxCap,checkOperatingConditions,checkPt,checkTiming,createVerilogTestBench' >> msip_grep/checks.txt", "$VERBOSITY");};
  my ($stdout6, $stderr6) = capture { run_system_cmd  ("echo 'checks ran' >> msip_grep/checks.txt", "$VERBOSITY");};
  my ($stdout7, $stderr7) = capture { run_system_cmd  ("cat quality_checks/msip_hipreLibertyCheck/alphaLibertyCheck_summary.log | grep -i 'info:.*c' >> msip_grep/checks.txt", "$VERBOSITY");};

  my ($stdout8, $stderr8) = capture { run_system_cmd  ("grep -i error quality_checks/msip_hipreLibertyCheck/alphaLibertyCheck.log >> msip_grep/error_run_log.txt", "$VERBOSITY");};

  my ($stdout9, $stderr9) = capture { run_system_cmd   ("touch msip_grep/fail_check.txt", "$VERBOSITY");};
  my ($stdout10, $stderr10) = capture { run_system_cmd   ("touch msip_grep/warning_check.txt", "$VERBOSITY");};
  my ($stdout11, $stderr11) = capture { run_system_cmd   ("cat quality_checks/msip_hipreLibertyCheck/alphaLibertyCheck_summary.log | grep -i 'fail' | awk '{print \$2}' >> msip_grep/fail_check.txt", "$VERBOSITY");};
  my ($stdout12, $stderr12) = capture { run_system_cmd   ("cat quality_checks/msip_hipreLibertyCheck/alphaLibertyCheck_summary.log | grep -i 'warning' | awk '{print \$2}' >> msip_grep/warning_check.txt", "$VERBOSITY");};
  #open (my $FR_fail, "<msip_grep/fail_check.txt") or die ("There are no failures\n");
  my @FR_fail;
  my @FR_warn;
  my ($readErr1, $readErr2) = "";
  my $CT = 0;
  (@FR_fail, $readErr1) = Util::Misc::read_file("msip_grep/fail_check.txt");
  foreach my $a (@FR_fail) 
  {
    chomp $a;
    if ($a ne "checkTiming")
    {
      my ($stdout13, $stderr13) = capture { run_system_cmd   ("echo 'Check: $a'  >> msip_grep/fail_log.txt", "$VERBOSITY");};
      my ($stdout14, $stderr14) = capture { run_system_cmd   ("grep -i 'error' quality_checks/msip_hipreLibertyCheck/used_files_$a/*.err >> msip_grep/fail_log.txt", "$VERBOSITY");};
    }
    else 
    {
     $CT = 1; 
      my ($stdout15, $stderr15) = capture { run_system_cmd   ("cp -rf quality_checks/msip_hipreLibertyCheck/TOTAL_ERRORS.LOG msip_grep/", "$VERBOSITY");};
    }
  }

  (@FR_warn, $readErr2) = Util::Misc::read_file("msip_grep/warning_check.txt");
  #open (my $FR_warn, "<msip_grep/warning_check.txt") or die ("There are no warnings\n");
  
  foreach my $b (@FR_warn)
  {
    chomp $b;
    if ($b ne "checkTiming")
    {
      my ($stdout16, $stderr16) = capture { run_system_cmd    ("echo 'Check: $b'  >> msip_grep/warning_log.txt", "$VERBOSITY");};
      my ($stdout17, $stderr17) = capture { run_system_cmd    ("grep -i 'warning' quality_checks/msip_hipreLibertyCheck/used_files_$b/* >> msip_grep/warning_log.txt", "$VERBOSITY");};
    }
    else 
    {
      $CT = 1; 
      my ($stdout18, $stderr18) = capture { run_system_cmd    ("cp -rf quality_checks/msip_hipreLibertyCheck/TOTAL_ERRORS.LOG msip_grep/", "$VERBOSITY");};
    }
  }
#}

if ($CT == 0)
{
  my ($stdout19, $stderr19) = capture { run_system_cmd    ("echo 'No non-monotonicity issues' > msip_grep/TOTAL_ERRORS.LOG", "$VERBOSITY");};
}
my ($stdout20, $stderr20) = capture { run_system_cmd    ("rm -rf msip_grep/fail_check.txt  msip_grep/warning_check.txt", "$VERBOSITY");};

}
