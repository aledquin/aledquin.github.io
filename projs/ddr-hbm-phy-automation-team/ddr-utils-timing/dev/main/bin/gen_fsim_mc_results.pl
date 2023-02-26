#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Getopt::Long;

use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Cwd;
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
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#

use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

BEGIN { our $AUTHOR='IN08 Timing team'; header(); } 
&Main();
END {
    write_stdout_log( $LOGFILENAME );
    local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
    footer();
    }

sub Main {
    my $dir;
    my $end;
    my @fields = ();
    my @fields2 = ();
    my $found_measure;
    my $i;
    my $idx;
    my $j;
    my $k;
    my $max;
    my $mean;
    my @meas = ();
    my $meas_cnt;
    my $min;
    my $num;
    my $num_iter;
    my $num_params;
    my $param;
    my @param_arr = ();
    my $path;
    my $per_var;
    my $stddev;
    my $str;
    my $sum;
    my $temp;
    my $val;
    my %value = ();
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    my $opt_help = "";
    ($opt_help) = process_cmd_line_args();
    
	if((@ARGV == 0)) {
        eprint "Script to generate all parsweep results\n";
		exit;
	}
    utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);

    unlink "mc_results_summary.csv";
    
    ##read the measure statements to get the values
    my @inc = read_file("../../measure/measure.inc");
    $meas_cnt = 0;
    
    foreach my $FILE_MEAS (@inc) {
    
        chomp $FILE_MEAS;
        if ($FILE_MEAS =~ /^.MEASURE/) {
            @fields = split /[ ]+/, $_;
            $temp = $fields[2];
            $temp =~ tr/A-Z/a-z/;
            $meas[$meas_cnt] = $temp;
            #print "Measure = $meas\n";
            $meas_cnt++;
        }
    }
    
    $idx=0;
    $num_iter = 100;
    
    $num = $idx;
    
    $end = 0;
    $idx = 0;
    $found_measure = 0;
    $j = 0;
    my @mc_results_summary = ();
    
    while ($end == 0) {
        
        $dir = "MC_${idx}";
    
        #open my $DATAFILE, "<", "MonteCarlo/$dir/out.lis";
        $path = "MonteCarlo/$dir/out.log";
        
        $temp = $meas[0];
        run_system_command("grep $temp= $path > scratch", "$VERBOSITY");
    
        for ($k=1; $k<$meas_cnt; $k++) {
            $temp = $meas[$k];
            run_system_command("grep $temp= $path >> scratch", "$VERBOSITY");
        }
    
    my @scratch = read_file("scratch");
        $j = 0;
    
        foreach my $DATAFILE (@scratch) {
    
            chomp @scratch;
    
            $temp = @scratch;
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
                    $temp =~ s/k/e3/;
                    $temp =~ s/x/e6/;
                    $temp =~ s/g/e9/;
                    if ($param eq "dcycle") {
                        if ($temp < 0.0) {
                            $temp = 100+$temp;
                        }
                    }
                    $value{$param}[$idx] = $temp;
                    $j++;
                    $num_params = $j;
                }
            }    
        }    
        run_system_command("rm scratch", "$VERBOSITY");
    
        if ($idx >= ($num_iter-1)) {
            $end = 1;
        }
    
        $idx++;
    }
    
    ##calculate the min and max and sigma from the distribution
    push @mc_results_summary, ",AVG,MAX,MIN,STDDEV,PER_VAR\n";
    
    for ($i=0; $i<$num_params; $i++) {
        $sum = 0.0;
        for ($j=0; $j<$num_iter; $j++) {
            $sum = $sum + $value{$param_arr[$i]}[$j];
        }
        $mean = $sum/$num_iter;
    
        $sum = 0.0;
        for ($j=0; $j<$num_iter; $j++) {
            $sum = $sum + ($value{$param_arr[$i]}[$j]-$mean)**2;
        }
        $stddev = sqrt($sum/$num_iter);
        $max = -1e100;
        $min = 1e100;
        for ($j=0; $j<$num_iter; $j++) {
            $val = $value{$param_arr[$i]}[$j]; 
            if ($val > $max) {
                $max = $val;
            }
            if ($val < $min) {
                $min = $val;
            }
        }
        #percentage of nominal (3sigma)
        $per_var = 3*100*$stddev/$mean;
    
        $str = "$param_arr[$i],$mean,$max,$min,$stddev,$per_var";
    
        push @mc_results_summary, "$str\n";
    
    }
    
    
    my $writefile_out = Util::Misc::write_file(\@mc_results_summary,"mc_results_summary.csv");
}

sub print_usage {
    my $ScriptPath = shift;
    Util::Messaging::nprint("Current script path:  $ScriptPath\n");
    pod2usage(0);
}

sub process_cmd_line_args() {
    my ( $opt_help, $opt_dryrun, 
         $opt_debug,  $opt_verbosity );

    my $success = GetOptions(
        "help"        => \$opt_help,           # Prints help
     );

    if( defined $opt_dryrun ){
        $main::TESTMODE = TRUE;
    }

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    &print_usage("$RealBin/$PROGRAM_NAME") if $opt_help;
    &print_usage("$RealBin/$PROGRAM_NAME") unless( $success );
    #&usage(1) unless( defined $opt_projSPEC );
   return( $opt_help );
};
