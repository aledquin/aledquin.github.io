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

my $ScriptPath = "";
foreach (my @toks) {$ScriptPath .= "$_/"}
$ScriptPath = abs_path($ScriptPath);


 my ($beol, $C, @corner, $curr_corner, $dir, $end, @fields, @fields2, $found_measure, $found_param_col, $idx, $k, @meas, $meas_cnt, $num, $param, $R, $str, $str_param, $temp, $value, $vdd, $corner);
 
 
my ($stdout0, $stderr0) =  run_system_cmd  ("rm ./results/results_summary.csv", "$VERBOSITY");

my @FILE = read_file("corner_list.txt");

$idx=0;

foreach my $FILE (@FILE) {

        chomp();
	if ($FILE !~ /^\*/) {
        	$corner[$idx] = $FILE;
        	$idx++;
	}
}


##read the measure statements to get the values
my @FILE_MEAS = read_file("../measure/measure.inc");
$meas_cnt = 0;

foreach my $FILE_MEAS (@FILE_MEAS) {

	chomp();
	if ($FILE_MEAS =~ /^.MEASURE/) {
		@fields = split /[ ]+/, $FILE_MEAS;
		$temp = $fields[2];
		$temp =~ tr/A-Z/a-z/;
		$meas[$meas_cnt] = $temp;
		#print "Measure = $meas\n";
		$meas_cnt++;
	}
}


$num = $idx;

$end = 0;
$idx = 0;
$found_measure = 0;
$found_param_col = 0;


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

	my @DATAFILE = read_file("../measure/measure.inc");

#	print FILE "*****************************\n";
#	print FILE "Corner = $dir\n";
#	print FILE "*****************************\n";
	$str = $dir;
	$str_param = "";

	foreach my $DATAFILE (@DATAFILE) {

		chomp();

		if ($DATAFILE =~ /job concluded/) {
                	if ($found_param_col == 0) {
				my $runfile1 = write_file("$str_param\n","./results/results_summary.csv");
                              	$found_param_col = 1;
                        }
                        my $runfile2 = write_file("$str\n","./results/results_summary.csv",">");

                }
		#print "$_\n";
		$temp = $DATAFILE;
		$temp =~ s/^/ /;
		$temp =~ s/=/= /g;
		$temp =~ s/ /  /g;
		$temp =~ s/[ ]+/ /g;
		@fields2 = split / /, $temp;
		$param = $fields2[1];
		for ($k=0; $k<$meas_cnt; $k++) {
			if ($param eq "$meas[$k]=") {
				#print "$_\n";
				#print "$temp\n";
				$param = $meas[$k];	
				$value = $fields2[2];
				$value =~ s/a/e-18/;
				$value =~ s/f/e-15/;
				$value =~ s/p/e-12/;
				$value =~ s/n/e-9/;
				$value =~ s/u/e-6/;
				$value =~ s/m/e-3/;
				$value =~ s/k/e3/;
				$value =~ s/x/e6/;
				$value =~ s/g/e9/;
				if ($param eq "dcycle") {
					if ($value < 0) {
						$value = 100+$value;
					}
				}
				$str_param = $str_param . ",$param";
				$str = $str . ",$value";
			}
		}
	}


	if ($idx >= ($num-1)) {
		$end = 1;
	}

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

    Usage: gen_results.pl [-h|-help]

    -h or -help  this help message
    
     gen_results.pl {>>options}  

EOusage
nprint ("$USAGE");
exit;
}    
