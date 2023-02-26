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

    if ($opt_help) {
        iprint "This is script to read files from montecarlo directory and populate mc_op_results_summary.csv file.\n";
        exit;
    }

    run_system_cmd("rm mc_op_results_summary.csv", "$VERBOSITY");
    
    $idx=0;
    $num_iter = 100;    
    $num = $idx;    
    $end = 0;
    $idx = 0;
    $found_measure = 0;
    $j = 0;
    $inst_num = 0;
    
    my @mc_op = ();

    while ($end == 0) {
        $dir = "MC_${idx}";
        my @MonteCarlo = read_file("MonteCarlo/$dir/out.dp0");
        $found_op = 0;
        $hdr_flag = 0;
        $hdr_str = "";
        $val_str = "";
        $inst_num = 0;
        $inst_cnt = 0;
        $done = 0;
        foreach my $DATAFILE (@MonteCarlo) {
            chomp $DATAFILE;
            if ($DATAFILE =~ /mosfets/) {
                if ($done == 1) {
                    $found_op = 1;
                }
                $done = 1;
            }
            if ($found_op == 1) {
                if (($found_trans == 1) && ($DATAFILE =~ /^$/)) {
                    $found_trans = 0;
                    $value{$inst}[$idx] = $vth;
                    $inst_arr[$inst_cnt] = $inst;
                    #print "Vt = $vth\n";
                    #print "Inst = $inst\n";
                    $inst_cnt++;
                }
                if ($found_trans == 1) {
                    @fields = split /[ ]+/, $DATAFILE;
                    $mosparam = $fields[1];
                    $val = $fields[2];
                    
                    if ($mosparam eq "element") {
                        $inst = $val;
                    #    print "$inst\n";
                    }
                    if ($mosparam eq "vth") {
                        $vth = $val;
                        $vth =~ s/a/e-18/;
                        $vth =~ s/f/e-15/;
                        $vth =~ s/p/e-12/;
                        $vth =~ s/n/e-9/;
                        $vth =~ s/u/e-6/;
                        $vth =~ s/m/e-3/;
                    }
                }    
                if ($_ =~ /subckt/) {
                    $found_trans = 1;
                }    
                if ($_ =~ /operating point/) {
                    $found_op = 0;
                }                
            }    
            if (($found_op==1) && ($found_op_old == 0)) {
            }
            $found_op_old = $found_op;
    
        }
        $inst_num = $inst_cnt;
        #run_system_cmd("rm -rf MonteCarlo/$dir", "$VERBOSITY");
           if ($idx >= ($num_iter-1)) {
            $end = 1;
        }
        $idx++;
    }
    ##calculate the min and max and sigma from the distribution
    push @mc_op, ",AVG,STDDEV\n";
    for ($i=0; $i<$inst_num; $i++) {
        $sum = 0.0;
        for ($j=0; $j<$num_iter; $j++) {
            $sum = $sum + $value{$inst_arr[$i]}[$j];
        }
        $mean = $sum/$num_iter;    
        $sum = 0.0;
        for ($j=0; $j<$num_iter; $j++) {
            $sum = $sum + ($value{$inst_arr[$i]}[$j]-$mean)**2;
        }
        $stddev = sqrt($sum/$num_iter);
        #percentage of nominal (3sigma)
        #$per_var = 3*100*$stddev/$mean;    
        $str = "$inst_arr[$i],$mean,$stddev";    
        push @mc_op, "$str\n";
    
    }
    my $writefile_out = Util::Misc::write_file(\@mc_op, "mc_op_results_summary.csv");
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

