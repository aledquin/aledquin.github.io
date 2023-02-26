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
use Cwd     qw( abs_path );
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

##  Constants
our $LOG_INFO = 0;
our $LOG_WARNING = 1;
our $LOG_ERROR = 2;
our $LOG_FATAL = 3;
our $LOG_RAW = 4;
#--------------------------------------------------------------------#



use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

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


my ( @fields, $input_paramm, $max, $min, $N, $input_param, $meas_cnt, $temp, @meas, $step_size, $num_iter, $curr_param,  $dir,  $end,  @fields2,  $found_measure,  $i,  $idx,  $j,  $k,  $num,  $num_params,  $param,  @param_arr,  @param_val_arr,  %value);


    my @orig_argv = @ARGV;
    my $opt_nousage;
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    my $opt_help = "";
    ($opt_nousage) = process_cmd_line_args();
    unless( $opt_nousage or $main::DEBUG ) {
        utils__script_usage_statistics( "$PROGRAM_NAME", $main::VERSION, \@orig_argv );
    }


##open param sweep command file
my @FILE = read_file("param.cmd");

foreach (@FILE) {
	chomp();
	if ($_ !~ /^\*/) {
		@fields = split / /, $_;
		$input_param = $fields[0];
		$max = $fields[1];
		$min = $fields[2];
		$N = $fields[3];
	}
}



my @FILE_MEAS = read_file("../../measure/measure.inc");

$meas_cnt = 0;

foreach (@FILE_MEAS) {

	chomp();
	if ($_ =~ /^.MEASURE/) {
		@fields = split /[ ]+/, $_;
		$temp = $fields[2];
		$temp =~ tr/A-Z/a-z/;
		$meas[$meas_cnt] = $temp;
		#print "Measure = $meas\n";
		$meas_cnt++;
	}
}


#$input_param = $ARGV[0];
#$max = $ARGV[1];
#$min = $ARGV[2];
#$N = $ARGV[3];

$step_size = ($max-$min)/$N;

$num_iter = $N+1;

$curr_param = $min;

$idx=0;

$num = $idx;

$end = 0;
$idx = 0;
$found_measure = 0;
$j = 0;


while ($end == 0) {
	
	#$dir = "Run_${curr_param}";
	$dir = "Run_${idx}";
	#print "$dir\n";

	#open (my $DATAFILE, "Param_${input_param}/$dir/out.lis");
	my @DATAFILE = read_file("Param_${input_param}/$dir/out.lis");

	foreach (@DATAFILE) {

		chomp();
	
		if ($_ =~ /job concluded/) {
			$found_measure = 0;
			$j = 0;
		}

		$temp = $_;
		$temp =~ s/^/ /;
		$temp =~ s/=/= /g;
		$temp =~ s/ /  /g;
		$temp =~ s/[ ]+/ /g;
		@fields2 = split / /, $temp;
		$param = $fields2[1];
		for ($k=0; $k<$meas_cnt; $k++) {
			if ($param eq "$meas[$k]=") {
				$param = $meas[$k];
				$param_arr[$j] = $param;
				$temp = $fields2[2];
				$temp =~ s/a/e-18/;
				$temp =~ s/f/e-15/;
				$temp =~ s/p/e-12/;
				$temp =~ s/n/e-9/;
				$temp =~ s/u/e-6/;
				$temp =~ s/m/e-3/;
				$temp =~ s/g/e9/;
				$temp =~ s/x/e6/;
				$value{$param}[$idx] = $temp;
				$j++;
				$num_params = $j;
			}
		}
			

		if ($_ =~ /Measured values for the netlist/) {
			$found_measure = 1;
		}

	}

#	close($DATAFILE);

	$param_val_arr[$idx] = $curr_param;
	$curr_param = $curr_param + $step_size;

	#system("rm -rf MonteCarlo/$dir");

	if ($idx >= ($num_iter-1)) {
		$end = 1;
	}

	$idx++;
}

##calculate the min and max and sigma from the distribution
#print FILE ",AVG,MAX,MIN,STDDEV,PER_VAR\n";
##generate data files for each parameter for gnuplot

for ($i=0; $i<$num_params; $i++) {
	#print "hello\n";
	my @FILEOUT;
	my @FILEOUTCSV;

	push @FILEOUT, "${input_param},$param_arr[$i]\n";
	push @FILEOUTCSV, "${input_param},$param_arr[$i]\n";
	for ($j=0; $j<$num_iter; $j++) {

		push @FILEOUT, "$param_val_arr[$j] $value{$param_arr[$i]}[$j]\n";
		push @FILEOUTCSV, "$param_val_arr[$j],$value{$param_arr[$i]}[$j]\n";

	}

	my $write_status1 = write_file(\@FILEOUT, "Param_${input_param}/${param_arr[$i]}_sweep.dat");
	my $write_status2 = write_file(\@FILEOUTCSV, "Param_${input_param}/${param_arr[$i]}_sweep.csv");
	
}

}

sub print_usage {
    my $exit_status = shift;
    my $ScriptPath = shift;
    my $message_text = "Current script path:  $ScriptPath\n";
     pod2usage({
        -message => $message_text ,
        -exitval => $exit_status,
        -verbose => 0,
        }
    );
}

sub process_cmd_line_args(){
    my ( $opt_help, $opt_nousage, $opt_dryrun, 
         $opt_debug,  $opt_verbosity );

    my $success = GetOptions(
        "help"        => \$opt_help,           # Prints help
        "nousage"     => \$opt_nousage,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "dryrun!"     => \$opt_dryrun,
     );

    if((defined $opt_dryrun) && ($opt_dryrun == 1)){
        $main::TESTMODE = TRUE;
    }

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    &print_usage(0, "$RealBin/$PROGRAM_NAME") if $opt_help;
    &print_usage(1, "$RealBin/$PROGRAM_NAME") unless( $success );
    #&usage(1) unless( defined $opt_projSPEC );
   return( $opt_nousage );
};
