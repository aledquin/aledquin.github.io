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
    my $curr_param;
    my $dir;
    my $end;
    my @fields = ();
    my @fields2 = ();
    my $found_measure;
    my $i;
    my $idx;
    my $input_param;
    my $j;
    my $k;
    my $max;
    my @meas = ();
    my $meas_cnt;
    my $min;
    my $N;
    my $num;
    my $num_iter;
    my $num_params;
    my $param;
    my @param_arr = ();
    my @param_val_arr = ();
    my $step_size;
    my $temp;
    my %value = ();
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    my $opt_help = "";
    ($opt_help) = process_cmd_line_args();
    
	if(!(-e "param.cmd")) {
        eprint "Script not run in correct directory\n";
		exit;
	}
    utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);
	
    ##open param sweep command file
    my @param = read_file("param.cmd");
    
    foreach my $FILE (@param) {
        chomp $FILE;
        if ($FILE !~ /^\*/) {
            @fields = split / /, $FILE;
            $input_param = $fields[0];
            $max = $fields[1];
            $min = $fields[2];
            $N = $fields[3];
        }
    }
    
    my @measure = read_file("../../measure/measure.inc");
    
    $meas_cnt = 0;
    
    foreach my $PARAM_FILE (@param) {
        chomp $PARAM_FILE;
        if ($_ =~ /^.MEASURE/) {
            @fields = split /[ ]+/, $PARAM_FILE;
            $temp = $fields[2];
            $temp =~ tr/A-Z/a-z/;
            $meas[$meas_cnt] = $temp;
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
        $dir = "Run_${idx}";
        my @log = read_file("Param_${input_param}/$dir/out.log");
        foreach my $DATAFILE (@log) {
            chomp $DATAFILE;
            if ($DATAFILE =~ /job concluded/) {
                $found_measure = 0;
                $j = 0;
            }
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
                    $temp =~ s/g/e9/;
                    $temp =~ s/x/e6/;
                    $value{$param}[$idx] = $temp;
                    $j++;
                    $num_params = $j;
                }
            }
            if ($DATAFILE =~ /Measured values for the netlist/) {
                $found_measure = 1;
            }    
        }
        $param_val_arr[$idx] = $curr_param;
        $curr_param = $curr_param + $step_size;
        if ($idx >= ($num_iter-1)) {
            $end = 1;
        }
    
        $idx++;
    }
    
    ##calculate the min and max and sigma from the distribution
    #print FILE ",AVG,MAX,MIN,STDDEV,PER_VAR\n";
    ##generate data files for each parameter for gnuplot
    
    for ($i=0; $i<$num_params; $i++) {
        my @FILEOUT = ();
        my @FILEOUTCSV = ();
    
        push @FILEOUT, "${input_param},$param_arr[$i]\n";
        push @FILEOUTCSV, "${input_param},$param_arr[$i]\n";
        for ($j=0; $j<$num_iter; $j++) {
    
            push @FILEOUT, "$param_val_arr[$j] $value{$param_arr[$i]}[$j]\n";
            push @FILEOUTCSV, "$param_val_arr[$j],$value{$param_arr[$i]}[$j]\n";
    
        }
        my $writefile_out = Util::Misc::write_file(\@FILEOUT,"Param_${input_param}/${param_arr[$i]}_sweep.dat");
        my $writefile_out_csv = Util::Misc::write_file(\@FILEOUTCSV,"Param_${input_param}/${param_arr[$i]}_sweep.csv");
    }
    
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
