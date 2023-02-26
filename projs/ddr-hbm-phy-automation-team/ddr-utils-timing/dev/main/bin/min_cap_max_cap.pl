#!/depot/perl-5.14.2/bin/perl
#################################################################
## Author        : Nandagopan G                                 #
## Functionality : LC to detect min cap > max cap               # 
#################################################################
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
   write_stdout_log($LOGFILENAME);
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}

sub Main {
my ($dir, @lib_arr, @lib_pg_arr, $path);
$dir = getcwd();
chomp($dir);
#my ($stdout, $stderr) = capture { run_system_cmd( "$reporter $rargs", "$VERBOSITY"); };

my ($stdout, $stderr) = capture { run_system_cmd ( "rm -rf min_cap_max_cap", "$VERBOSITY");};
my ($stdout1, $stderr1) = capture { run_system_cmd ("mkdir min_cap_max_cap", "$VERBOSITY");};
my ($stdout2, $stderr2) = capture { run_system_cmd ("touch min_cap_max_cap/min_cap_max_cap.csh min_cap_max_cap/min_cap_max_cap.tcl min_cap_max_cap/min_cap_max_cap.log", "$VERBOSITY");};

$path = "$dir/min_cap_max_cap";

my @lib_read_csh;
#open ($lib_read_csh,">>min_cap_max_cap/min_cap_max_cap.csh");

push @lib_read_csh, "#!/bin/csh\n\n";
push @lib_read_csh, "cd $path\n";
push @lib_read_csh, "module unload lc\n";
#push @lib_read_csh, "module load lc/2020.09-SP1\n";
push @lib_read_csh, "module load lc\n";
push @lib_read_csh, "lc_shell -f $dir/min_cap_max_cap/min_cap_max_cap.tcl >> $dir/min_cap_max_cap/min_cap_max_cap.log\n";
push @lib_read_csh, "exit\n";
push @lib_read_csh, "cd $dir";

my $writeStatus = Util::Misc::write_file(\@lib_read_csh, "min_cap_max_cap/min_cap_max_cap.csh", '>');

my ($syserr1, $syserr2, $lib_arr, $lib_pg_arr) = "";
($lib_pg_arr, $syserr1) = run_system_cmd("ls $dir/lib_pg/*.lib", $VERBOSITY);
($lib_arr, $syserr2) = run_system_cmd("ls $dir/lib/*.lib", $VERBOSITY);

@lib_pg_arr = split("\n", $lib_pg_arr);
@lib_arr    = split("\n", $lib_arr);

#open ($lib_read_tcl,">>min_cap_max_cap/min_cap_max_cap.tcl");
my @lib_read_tcl;

foreach my $lib_pg (@lib_pg_arr)
{
  push @lib_read_tcl, "read_lib $lib_pg\n";   
}

foreach my $lib (@lib_arr)
{
  push @lib_read_tcl, "read_lib $lib\n";   
}

push @lib_read_tcl, "quit\n";

my $writeStatus1 = Util::Misc::write_file(\@lib_read_tcl,"min_cap_max_cap/min_cap_max_cap.tcl", '>');


my ($stdout3, $stderr3) = capture {run_system_cmd ("chmod +x $dir/min_cap_max_cap/min_cap_max_cap.csh; $dir/min_cap_max_cap/min_cap_max_cap.csh", "$VERBOSITY");};

my ($stdout4, $stderr4) = capture {run_system_cmd ("rm -rf $dir/min_cap_max_cap/min_cap_max_cap.csh $dir/min_cap_max_cap/min_cap_max_cap.tcl $dir/min_cap_max_cap/lc*", "$VERBOSITY");};
my $error = `egrep -ir "error" $dir/min_cap_max_cap/min_cap_max_cap.log`;
if($error eq "") {
my ($stdout5, $stderr5) = capture {run_system_cmd("echo STATUS: PASS > $dir/min_cap_max_cap/status.log", "$VERBOSITY");};
} else {
my ($stdout6, $stderr6) = capture {run_system_cmd("echo STATUS: FAIL > $dir/min_cap_max_cap/status.log", "$VERBOSITY");};
}
}
