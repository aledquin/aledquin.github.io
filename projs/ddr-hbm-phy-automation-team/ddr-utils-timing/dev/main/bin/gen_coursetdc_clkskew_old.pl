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
    my @clktdcval = ();
    my $clkv8period;
    my @cntval = ();
    my $curr_cnt;
    my $curr_tdcval;
    my $dcofreq;
    my $exp_cnt;
    my $exp_cnt_last;
    my @fields = ();
    my $idx;
    my $last_cnt;
    my $last_curr_tdcval;
    my $num;
    my $rise_or_fall;
    my @skew = ();
    my @skewidx = ();
    my $skewidx_out;
    my $skew_out;
    my $temp;
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    my $opt_help = "";
    ($opt_help) = process_cmd_line_args();

    utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);

	if((@ARGV == 0)) {
        eprint "Script to generate all course tdc clock skew\n";
		exit;
	
	}
    
    
    $dcofreq = $ARGV[0]*1e9;
    $clkv8period = 8.0/$dcofreq;
    $rise_or_fall = $ARGV[1];
    my @countrval_sweep = read_file("Param_xclkrdly/countrval_sweep.csv");
#    open my $FILE, "<", "Param_xclkrdly/countrval_sweep.csv" or die $!;
    
    $idx = 0;
    foreach my $countrval (@countrval_sweep) {
        chomp $countrval;
        @fields = split /,/, $countrval;
        if ($fields[1] =~ /^[0-9-]/) {
            $temp = int($fields[1]);
            if (($fields[1]-$temp) > 0.5) {
                $temp++;
            }
            $cntval[$idx] = $temp;
            $skewidx[$idx] = $fields[0];
            $idx++;
        } 
    }
    $idx = 0;
    my @clkr = ();
    if ($rise_or_fall eq "1") {
        @clkr = read_file("Param_xclkrdly/clkr_clkv8r_skew_sweep.csv");
#       open my $FILE, "<", "Param_xclkrdly/clkr_clkv8r_skew_sweep.csv" or die $!;
    } else {
        @clkr = read_file("Param_xclkrdly/clkr_clkv8f_skew_sweep.csv");
#       open my $FILE, "<", "Param_xclkrdly/clkr_clkv8f_skew_sweep.csv" or die $!;
    }
    
    $idx = 0;
    foreach my $clkr_clkv8 (@clkr) {
        chomp $clkr_clkv8;
        @fields = split /,/, $clkr_clkv8;
        if ($fields[1] =~ /^[0-9-]/) {
            $temp = $fields[1];
            if (abs($temp) >= 0.5*$clkv8period) {
                if ($temp < 0) {
                    $temp = $temp+$clkv8period;
                } else {
                    $temp = $temp-$clkv8period;
                }
            }
            $skew[$idx] = $temp;
            $idx++;
            #print "$temp\n";
        } 
    }
    
    ##search for when clk_tdc_en abruptly changes to find where clkv8 fall aligns with refclk rising in clkgen
    my @clkr_clktdc = read_file("Param_xclkrdly/clkr_clktdc_skew_sweep.csv");
    $idx = 0;
    foreach my $line (@clkr_clktdc) {
        chomp $line;
        @fields = split /,/, $line;
        if ($fields[1] =~ /^[0-9-]/) {
            $temp = $fields[1];
            $clktdcval[$idx] = $temp; 
            $idx++;
            #print "$temp\n";
        }
    }
    $num = $idx;
    
    if ($rise_or_fall == 1) {
        $exp_cnt_last = 15;
        $exp_cnt = 0;
    } else {
        $exp_cnt_last = 7;
        $exp_cnt = 8;
    }
    
    ##search for the 15->0 transistion for rising edge alignment
    for ($idx=0; $idx<$num; $idx++) {
        $curr_cnt = $cntval[$idx];
    
        if (($last_cnt == $exp_cnt_last) && ($curr_cnt == $exp_cnt)) {
            $skew_out = $skew[$idx]*1e12;
            #$skewidx_out = $skewidx[$idx];
            $skewidx_out = $idx;
        }
        $last_cnt = $curr_cnt;
    }
    
    if ($rise_or_fall == 1) {
        iprint "clkv8r_clkr_skew(ps) = $skew_out @ skew_idx = $skewidx_out\n";
    } else {
        iprint "clkv8f_clkr_skew(ps) = $skew_out @ skew_idx = $skewidx_out\n";
    }
    
    ##search for abrupt change in clk_tdc location
    $last_curr_tdcval = $clktdcval[0];
    for ($idx=0; $idx<$num; $idx++) {
        $curr_tdcval = $clktdcval[$idx];
    
        if (($curr_tdcval - $last_curr_tdcval) >= 0.5) {
            $skew_out = $skew[$idx]*1e12;
            #$skewidx_out = $skewidx[$idx];
            $skewidx_out = $idx;
        }
    
        $last_curr_tdcval = $curr_tdcval;
    }
    
    
    if ($rise_or_fall == 1) {
        iprint "clkv8r_clkr_tdcskew(ps) = $skew_out @ skew_idx = $skewidx_out\n";
    } else {
        iprint "clkv8f_clkr_tdcskew(ps) = $skew_out @ skew_idx = $skewidx_out\n";
    }
}
sub print_usage {
    my $ScriptPath = shift;
    Util::Messaging::nprint("Current script path:  $ScriptPath\n");
    pod2usage(0);
}


sub process_cmd_line_args(){
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
