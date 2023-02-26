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
use Cwd qw( abs_path getcwd );
use Cwd;
use Carp qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

use Data::Dumper;
use Getopt::Long;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);


#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = FALSE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version() || '2022.11'; 



our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
BEGIN { our $AUTHOR='Multiple Authors'; header(); } 
&Main();
END {
   write_stdout_log($LOGFILENAME);
   footer(); 
}


my ($debug,$opt_help);

sub Main {
   utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);

   &process_cmd_line_args();

my (@corner,$curr_param,$corner,$curr_corner,$dir,$end,@fields,$idx,$max,$min,$N,$num,$num_iter,$param,$step_size,$temp,$vdd);

my $ScriptPath = "";
foreach (my @toks) {$ScriptPath .= "$_/"}
$ScriptPath = abs_path($ScriptPath);


my @FILE = read_file("param.cmd");

foreach my $FILE  (@FILE) {
	chomp();
	if ($FILE !~ /^\*/) {
		@fields = split / /, $FILE;
		$param = $fields[0];
		$max = $fields[1];
		$min = $fields[2];
		$N = $fields[3];
	}
}


#$param = $ARGV[0];
#$max = $ARGV[1];
#$min = $ARGV[2];
#$N = $ARGV[3];

$step_size = ($max-$min)/$N;

$num_iter = $N+1;

$curr_param = $min;

$num = $idx;

$end = 0;
$idx = 0;


my ($stdout0, $stderr0) = run_system_cmd  ("rm -rf Param_${param}", "$VERBOSITY");
my ($stdout1, $stderr1) = run_system_cmd  ("mkdir Param_${param}", "$VERBOSITY");

while ($end == 0) {

	$curr_corner = $corner[$idx];

	@fields = split /_/, $curr_corner;
	$corner = $fields[0];
	$vdd = $fields[1];
	$temp = $fields[2];

	#$dir = "Run_${curr_param}";
	$dir = "Run_${idx}";

	#print "$dir\n";
	
	my ($stdout2, $stderr2) = run_system_cmd  ("cd Param_${param} mkdir $dir", "$VERBOSITY");
	my ($stdout3, $stderr3) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../run_sim.csh .", "$VERBOSITY");
	my ($stdout4, $stderr4) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../cmd_file.txt .", "$VERBOSITY");
	my ($stdout5, $stderr5) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../model.inc .", "$VERBOSITY");
	my ($stdout6, $stderr6) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../model_res.inc .", "$VERBOSITY");
	my ($stdout7, $stderr7) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../model_cap.inc .", "$VERBOSITY");
	my ($stdout8, $stderr8) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../temp.inc .", "$VERBOSITY");
	my ($stdout9, $stderr9) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../probes.inc .", "$VERBOSITY");
	#my ($stdout0, $stderr0) = capture { run_system_cmd  ("cd Param${param}/$dir; ln -s ../../params.inc .");
	#my ($stdout0, $stderr0) = capture { run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../supply.inc");
	my ($stdout10, $stderr10) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../measure.inc .", "$VERBOSITY");
	my ($stdout11, $stderr11) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../input.ckt .", "$VERBOSITY");
	my ($stdout12, $stderr12) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../netlist.spf .", "$VERBOSITY");
	my ($stdout13, $stderr13) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../analysis.inc .", "$VERBOSITY");

	if ($param eq "xVDD") {
		my ($stdout14, $stderr14) = run_system_cmd  ("sed -e 's/${param}=[0-9a-zA-Z-]*\.[0-9a-zA-Z-]*/${param}=${curr_param}/' supply.inc > temp", "$VERBOSITY");
		my ($stdout15, $stderr15) = run_system_cmd  ("cp temp Param_${param}/$dir/supply.inc", "$VERBOSITY");
		my ($stdout16, $stderr16) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../params.inc .", "$VERBOSITY");
	} else {
		my ($stdout17, $stderr17) = run_system_cmd  ("sed -e 's/${param}=[0-9a-zA-Z-]*\.[0-9a-zA-Z-]*/${param}=${curr_param}/' params.inc > temp", "$VERBOSITY");
		my ($stdout18, $stderr18) = run_system_cmd  ("cp temp Param_${param}/$dir/params.inc", "$VERBOSITY");
		my ($stdout19, $stderr19) = run_system_cmd  ("cd Param_${param}/$dir; ln -s ../../supply.inc", "$VERBOSITY");
	}

	my ($stdout20, $stderr20) =  run_system_cmd  ("rm temp", "$VERBOSITY");
	
	my $RUNFILE1 = write_file("cd Param_${param}/${dir}\n","run_parsweep.csh");
        my $RUNFILE2 = write_file("source run_sim.csh\n","run_parsweep.csh",">");
        my $RUNFILE3 = write_file("cd ../../\n","run_parsweep.csh",">");

	if ($idx >= ($num_iter-1)) {
		$end = 1;
	}
	
	$curr_param = $curr_param + $step_size;
	
	$idx++;
}


}


sub process_cmd_line_args(){
    my ($opt_help,$opt_dryrun,$opt_debug,$opt_verbosity);

    my $success = GetOptions(
                "help|h"         => \$opt_help,
                "dryrun!"        => \$opt_dryrun,
                "debug=i"        => \$opt_debug
	); 

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    &usage(0) if $opt_help;
    &usage(1) unless( $success );

    return;  
}    

sub usage($) {
my $exit_status = shift || '0';
    my $USAGE = <<EOusage;

    Usage: gen_parsweep_run_dir.pl [-h|-help]

    -h or -help  this help message
    
     gen_parsweep_run_dir.pl {>>options}  

EOusage
nprint ("$USAGE");
exit;
}    
