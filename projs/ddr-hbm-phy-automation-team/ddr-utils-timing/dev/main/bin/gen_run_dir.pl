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

my ($beol, $C, @corner, $curr_corner, $dir, $end, @fields, $idx, $num, $post, $R, $temp, $vdd, $corner);

my $ScriptPath = "";
foreach (my @toks) {$ScriptPath .= "$_/"}
$ScriptPath = abs_path($ScriptPath);


$idx=0;
$post = 0;

if ((defined $ARGV[0]) && ($ARGV[0] ne "post")) {
	$corner[0] = $ARGV[0];
} else {
	if (defined $ARGV[0]) {
		if ($ARGV[0] eq "post") {
			$post = 1;
		}
	}


        my @FILE = read_file("corner_list.txt");
	foreach my $FILE (@FILE) {
        	chomp();
		if ($FILE !~ /^\*/) {
        		$corner[$idx] = $FILE;
        		$idx++;
		}
	}
}

$num = $idx;

$end = 0;
$idx = 0;

#open (my $RUNFILE, ">","run.csh") or die $!;

while ($end == 0) {

	$curr_corner = $corner[$idx];

	@fields = split /_/, $curr_corner;
	$corner = $fields[0];
	$R = $fields[1];
	$C = $fields[2];
	$vdd = $fields[3];
	$beol = $fields[4];
	$temp = $fields[5];

	$dir = "Run_${corner}_${R}_${C}_${vdd}_${beol}_${temp}";

	nprint ("$dir\n");
	
	my ($stdout, $stderr) =  run_system_cmd  ("mkdir $dir", "$VERBOSITY");
#	my ($stdout0, $stderr0) = capture { run_system_cmd  ("cd $dir; ln -s ../../../cmd_file.txt .");
	my ($stdout0, $stderr0) = run_system_cmd  ("cd $dir; ln -s ../../run_sim.csh .", "$VERBOSITY");
	my ($stdout1, $stderr1) = run_system_cmd  ("cd $dir; ln -s ../../cmd_file.txt .", "$VERBOSITY");
	my ($stdout2, $stderr2) = run_system_cmd  ("cd $dir; ln -s ../../netlist/input.ckt .", "$VERBOSITY");
	my ($stdout3, $stderr3) = run_system_cmd  ("cd $dir; ln -s ../../netlist/netlist_${beol}.spf netlist.spf", "$VERBOSITY");
	my ($stdout4, $stderr4) = run_system_cmd  ("cd $dir; ln -s ../../param.cmd .", "$VERBOSITY");
	if ($post == 1) {
		my ($stdout5, $stderr5) =  run_system_cmd  ("cd $dir; ln -s ../../model_inc/lib_${corner}_post.inc model.inc", "$VERBOSITY");
	} else {
		my ($stdout6, $stderr6) =  run_system_cmd  ("cd $dir; ln -s ../../model_inc/lib_${corner}.inc model.inc", "$VERBOSITY");
	}
	my ($stdout7, $stderr7) = run_system_cmd  ("cd $dir; ln -s ../../model_inc/lib_${R}.inc model_res.inc", "$VERBOSITY");
	my ($stdout8, $stderr8) = run_system_cmd  ("cd $dir; ln -s ../../model_inc/lib_${C}.inc model_cap.inc", "$VERBOSITY");
	my ($stdout9, $stderr9) = run_system_cmd  ("cd $dir; ln -s ../../model_inc/temp_${temp}C.inc temp.inc", "$VERBOSITY");
#	my ($stdout0, $stderr0) = capture { run_system_cmd  ("cd $dir; ln -s ../../netlist/mbcoreplldig_star_nominal_110.spf netlist.spf");
	my ($stdout10, $stderr10) = run_system_cmd  ("cd $dir; ln -s ../../probes/probes.inc .", "$VERBOSITY");
	my ($stdout11, $stderr11) = run_system_cmd  ("cd $dir; ln -s ../../tb_params/params.inc .", "$VERBOSITY");
	my ($stdout12, $stderr12) = run_system_cmd  ("cd $dir; ln -s ../../model_inc/supply_${vdd}.inc supply.inc", "$VERBOSITY");
	my ($stdout13, $stderr13) = run_system_cmd  ("cd $dir; ln -s ../../measure/measure.inc .", "$VERBOSITY");
	my ($stdout14, $stderr14) = run_system_cmd  ("cd $dir; ln -s ../../analysis/analysis.inc .", "$VERBOSITY");
	my ($stdout15, $stderr15) = run_system_cmd  ("cd $dir; ln -s ../scripts .", "$VERBOSITY");
	
	my $RUNFILE1 = write_file("cd ${dir}\n","run.csh");
        my $RUNFILE2 = write_file("source run_sim.csh\n","run.csh",">");
        my $RUNFILE3 = write_file("cd ..\n","run.csh",">");


	if ($idx >= ($num-1)) {
		$end = 1;
	}

	$idx++;
}

#close($RUNFILE);
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

    Usage: gen_run_dir.pl [-h|-help]

    -h or -help  this help message
    
     gen_run_dir.pl {>>options}  

EOusage
nprint ("$USAGE");
exit;
}    


