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
    my $beol;
    my $C;
    my @corner;
    my $corner;
    my $curr_corner;
    my $found_param_col;
    my $R;
    my $str_param;
    my $value;
    my $vdd;
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    my $opt_help = "";
    ($opt_help) = process_cmd_line_args();
    
	if(!(-e "corner_list.txt")) {
        eprint "Script not run in correct directory\n";
		exit;
	}
    utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);
	
    unlink "rm ./results/results_summary.csv";
    my @corner_list = read_file("corner_list.txt");
    
    $idx=0;
    foreach my $file (@corner_list) {
        chomp $file;
        if ($file !~ /^\*/) {
                $corner[$idx] = $file;
                $idx++;
        }
    }
    ##read the measure statements to get the values
    my @measure = read_file("../measure/measure.inc");
    $meas_cnt = 0;
    foreach my $FILE_MEAS (@measure) {    
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
    
    $num = $idx;
    $end = 0;
    $idx = 0;
    $found_measure = 0;
    $found_param_col = 0;
    
    my @results_summary = ();
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
    
        my @log = read_file("$dir/out.log");
    #    push @results_summary, "*****************************\n";
    #    push @results_summary, "Corner = $dir\n";
    #    push @results_summary, "*****************************\n";
        $str = $dir;
        $str_param = "";
        foreach my $DATAFILE (@log) {
            chomp $DATAFILE;    
            if ($DATAFILE =~ /Ended at/) {
                 if ($found_param_col == 0) {
                    push @results_summary, "$str_param\n";
                    $found_param_col = 1;
                }
                push @results_summary, "$str\n";
            }
            #print "$_\n";
            $temp = $_;
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
    my $writefile_out = Util::Misc::write_file(\@results_summary, "./results/results_summary.csv");
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
