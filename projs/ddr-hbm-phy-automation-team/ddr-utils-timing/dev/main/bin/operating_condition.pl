#!/depot/perl-5.14.2/bin/perl
#################################################################
## Author        : Nandagopan G                                 #
## Functionality : Check operating condition consistency        # 
#################################################################
use strict ;
use warnings ;
use Pod::Usage ;
use Data::Dumper ;
use File::Copy ;
use Getopt::Std ;
use Getopt::Long ;
use File::Basename qw( dirname ) ;
use File::Spec::Functions qw( catfile ) ;
use Cwd ;
use Carp    qw( cluck confess croak ) ;
use FindBin qw( $RealBin $RealScript ) ;

use lib "$RealBin/../lib/perl/" ;
use Util::CommonHeader ;
use Util::Misc ;
use Util::Messaging ;
use File::Basename qw( dirname basename ) ;

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

sub Main {
my ($default_op_cnd, $lib_path, $lib_pvt, $op_cond);
my @lib_pg_read;
my @lib_read;

$lib_path = $ARGV[0];

if (!defined $ARGV[0])
{
  Util::Messaging::iprint("Usage : operating_condition.pl <macro directory path>\n");
  exit;
}

if ($ARGV[0] eq "-help")
{
  Util::Messaging::iprint("Usage : operating_condition.pl <macro directory path>\n");
  exit;
}

my ($lib_pg_read,$stdRunErr1) = run_system_cmd("ls $lib_path/lib_pg/*.lib",$VERBOSITY);
@lib_pg_read = split("\n",$lib_pg_read);


my ($lib_read, $stdRunErr2) = run_system_cmd("ls $lib_path/lib/*.lib", $VERBOSITY);
@lib_read = split("\n",$lib_read);

if (-d "grep_result")
{
  if (-e "grep_result/lib_op_cond.txt")
  {
     my ($stdout, $stderr) = run_system_cmd  ("rm -rf grep_result/lib_op_cond.txt", "$VERBOSITY");
  }
}
else
{
  my ($stdout1, $stderr1) = run_system_cmd ("mkdir grep_result", "$VERBOSITY");
}
#open ($lib_op_cond,">>$path/grep_result/lib_op_cond.txt");
#open ($lib_op_cond,">>grep_result/lib_op_cond.txt");
my @lib_op_cond;
foreach my $lib_pg (@lib_pg_read)
{
  #print "$lib_pg\n";
  #exit;
  
  chomp($lib_pg);
  my ($stdRunErr3, $stdRunErr4, $stdRunErr5) = "";
  
  ($lib_pvt,$stdRunErr3)  = run_system_cmd("ls $lib_pg | rev | cut -d '.' -f2 | cut -d '_' -f2 | rev", $VERBOSITY);
  chomp($lib_pvt);
  ($default_op_cnd, $stdRunErr4) = run_system_cmd("egrep 'default_operating_conditions' $lib_pg | awk '{print \$3}' | cut -d ':' -f2 | cut -d '\;' -f1 | cut -d '\"' -f2", $VERBOSITY);
  chomp($default_op_cnd);

  ($op_cond,$stdRunErr5)  = run_system_cmd("egrep ' operating_conditions' $lib_pg | grep -v -i end | cut -d '(' -f2 | cut -d ')' -f1 | cut -d '\"' -f2", $VERBOSITY);
  chomp($op_cond);

  push @lib_op_cond,  "LIB PVT                : $lib_pvt\n";
  push @lib_op_cond,  "OPERATING COND         : $op_cond\n";
  push @lib_op_cond,  "DEFAULT OPERATING COND : $default_op_cnd\n\n";
  
 
  if ($lib_pvt eq $op_cond)
  {
    push @lib_op_cond,  "LIB PVT AND OPERATING CONDITION MATCHES\n"; 
  }
  else
  {
    push @lib_op_cond,  "LIB PVT AND OPERATING CONDITION DOES NOT MATCHES : ERROR\n";
  }

  if ($lib_pvt eq $default_op_cnd)
  {
    push @lib_op_cond, "LIB PVT AND DEFAULT OPERATING CONDITION MATCHES\n"; 
  }
  else
  {
    push @lib_op_cond, "LIB PVT AND DEFAULT OPERATING CONDITION DOES NOT MATCHES : ERROR\n";
  }
   
  push @lib_op_cond, "=================================\n";
  push @lib_op_cond, "=================================\n";
}

foreach my $lib (@lib_read)
{
  chomp($lib);
  my ($stdRunErr3, $stdRunErr4, $stdRunErr5) = "";
  
  
  ($lib_pvt,$stdRunErr3) = run_system_cmd("ls $lib | rev | cut -d '.' -f2 | cut -d '_' -f1 | rev", $VERBOSITY);
  chomp($lib_pvt);

  ($default_op_cnd, $stdRunErr4) = run_system_cmd("egrep 'default_operating_conditions' $lib | awk '{print \$3}' | cut -d ':' -f2 | cut -d '\;' -f1 | cut -d '\"' -f2", $VERBOSITY);
  chomp($default_op_cnd);

 ($op_cond,$stdRunErr5)  = run_system_cmd("egrep ' operating_conditions' $lib | grep -v -i end | cut -d '(' -f2 | cut -d ')' -f1 | cut -d '\"' -f2", $VERBOSITY);
  chomp($op_cond);

  push @lib_op_cond,  "LIB PVT                : $lib_pvt\n";
  push @lib_op_cond,  "OPERATING COND         : $op_cond\n";
  push @lib_op_cond,  "DEFAULT OPERATING COND : $default_op_cnd\n\n";
  
 
  if ($lib_pvt eq $op_cond)
  {
    push @lib_op_cond,  "LIB PVT AND OPERATING CONDITION MATCHES\n"; 
  }
  else
  {
    push @lib_op_cond,  "LIB PVT AND OPERATING CONDITION DOES NOT MATCHES : ERROR\n";
  }

  if ($lib_pvt eq $default_op_cnd)
  {
    push @lib_op_cond,  "LIB PVT AND DEFAULT OPERATING CONDITION MATCHES\n"; 
  }
  else
  {
    push @lib_op_cond,  "LIB PVT AND DEFAULT OPERATING CONDITION DOES NOT MATCHES : ERROR\n";
  }
   
  push @lib_op_cond,  "=================================\n";
  push @lib_op_cond,  "=================================\n";
}

my $WriteStatus = write_file(\@lib_op_cond, "grep_result/lib_op_cond.txt", ">");
}
