#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd;
use Cwd     qw( abs_path );
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


BEGIN { our $AUTHOR='IN08 Timing team'; header(); } 
&Main();
END {
   write_stdout_log("$LOGFILENAME");
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}
sub Main {
    my $beol;
    my $BW;
    my @corner = ();
    my $corner;
    my $curr_corner;
    my $dir;
    my $end;
    my $fhpf;
    my @fields = ();
    my @fields2 = ();
    my $idx;
    my $jitter_cnt;
    my $num;
    my $R;
    my $str;
    my $temp;
    my $val;
    my $vdd;
    my $done;
    my $found_measure;
    my $found_op;
    my $found_op_old;
    my $found_trans;
    my $hdr_flag;
    my $hdr_str;
    my $i;
    my $inst;
    my @inst_arr;
    my $inst_cnt;
    my $inst_num;
    my $j;
    my $mean;
    my $mosparam;
    my $num_iter;
    my $stddev;
    my $sum;
    my $val_str;
    my %value;
    my $vth;
    my $k;
    my $max;
    my @meas;
    my $meas_cnt;
    my $min;
    my $num_params;
    my $param;
    my @param_arr;
    my $path;
    my $per_var;
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
    
    run_system_cmd("rm mc_results_summary.csv", "$VERBOSITY");
    
    ##read the measure statements to get the values
    my @read_measure = read_file("../../measure/measure.inc");
#    open my $FILE_MEAS, "<", "../../measure/measure.inc" or die $!;
    
    $meas_cnt = 0;
    
    foreach my $FILE_MEAS (@read_measure) {    
        chomp $FILE_MEAS;
        if ($FILE_MEAS =~ /^.MEASURE/) {
            @fields = split /[ ]+/, $FILE_MEAS;
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
    
#    open my $FILE, ">", "mc_results_summary.csv" or die $!;
    my @mc_results = ();
    while ($end == 0) {
        
        $dir = "MC_${idx}";
        $path = "MonteCarlo/$dir/out.lis";
        $temp = $meas[0];
        run_system_cmd("grep $temp= $path > scratch", "$VERBOSITY");
    
        for ($k=1; $k<$meas_cnt; $k++) {
            $temp = $meas[$k];
            run_system_cmd("grep $temp= $path >> scratch", "$VERBOSITY");
        }
        my @read_scratch = read_file("scratch");
#        open my $DATAFILE, "<", "scratch" or die $!;
    
        $j = 0;
    
        foreach my $DATAFILE (@read_scratch) {    
            chomp $DATAFILE;    
            $temp = $DATAFILE;
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
        run_system_cmd("rm scratch", "$VERBOSITY");
        if ($idx >= ($num_iter-1)) {
            $end = 1;
        }    
        $idx++;
    }
    
    ##calculate the min and max and sigma from the distribution
    push @mc_results, ",AVG,MAX,MIN,STDDEV,PER_VAR\n";
    
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
        push @mc_results, "$str\n";    
    }
    my $writefile_out = Util::Misc::write_file(\@mc_results, "mc_results_summary.csv");
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
