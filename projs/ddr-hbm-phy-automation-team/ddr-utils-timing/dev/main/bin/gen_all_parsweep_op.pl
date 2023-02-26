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
use Cwd     ;
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
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
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#

BEGIN { our $AUTHOR='IN08 Timing team'; header(); } 
&Main();
END {
   write_stdout_log("$LOGFILENAME");
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}


my ($debug,$opt_help);

sub Main {

    my $curr_param;
    my $device;
    my $dir;
    my $done;
    my $end;
    my @fields;
    my $found_measure;
    my $found_op;
    my $found_trans;
    my $hr;
    my $i;
    my $idx;
    my $input_param;
    my $j;
    my $max;
    my $min;
    my $mosparam;
    my $mostype;
    my $N;
    my $num;
    my $num_iter;
    my $num_params;
    my @param_arr;
    my @param_val_arr;
    my $step_size;
    my $val;
    my $valid;
    my %value;
    my $vds;
    my $vdsat;
    my $veff;
    my $vgs;
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

    ##open param sweep command file
    my @read_param = read_file("param.cmd");
    $device = $ARGV[0];
    
    foreach my $FILE (@read_param) {
    chomp $FILE;
    my @FILE = read_file("param.cmd");
    $device = $ARGV[0];    
    foreach my $FILE (@FILE) {
        chomp $FILE;
        @fields = split / /, $FILE;
        $input_param = $fields[0];
        $max = $fields[1];
        $min = $fields[2];
        $N = $fields[3];
    }
    $step_size = ($max-$min)/$N;
    $num_iter = $N+1;
    $curr_param = $min;
    $idx=0;
    $num = $idx;
    $end = 0;
    $idx = 0;
    $found_measure = 0;
    $j = 0;
    $done = 0;
    while ($end == 0) {
        $dir = "Run_${idx}";
	my @DATAFILE = read_file("Param_${input_param}/$dir/out.dp0");
        $found_op  = 0;
        $found_trans = 0;
        foreach my $DATAFILE (@DATAFILE) {
            chomp();
            if ($DATAFILE =~ /mosfets/) {
                if ($done == 1) {
                    $found_op = 1;
                }
                $done = 1;
                $j = 0;
            }
            if ($found_op == 1) {
                if (($found_trans == 1) && ($DATAFILE =~ /^$/)) {
                    $found_trans = 0;    
                    $found_trans = 0;
                    if ($mostype eq "pch") {
                        $veff = -1*($vgs-$vth)*1e3; #in mV
                        $hr = -1*($vds-$vdsat)*1e3;
                    } else {
                        $veff = ($vgs-$vth)*1e3; #in mV
                        $hr = ($vds-$vdsat)*1e3;
                    }
                    if ($valid == 1) {
                        #print "VDS=$vds\n";
                        #print "VDS=$vds\n";
                        $value{"veff"}[$idx] = $veff;
                        $param_arr[$j] = "veff";
                        $value{"hr"}[$idx] = $hr;
                        $param_arr[$j+1] = "hr";
                        $j=$j+2;
                        $num_params = $j;
                    }
                }
                if ($found_trans == 1) {
                    @fields = split /[ ]+/, $DATAFILE;
                    $mosparam = $fields[1];
                    $val = $fields[2];
                    if ($mosparam eq "model") {
                        if ($val =~ /nch/) {
                            $mostype = "nch";
                        } else {
                            $mostype = "pch";
                        }
                    }
                    if ($val =~ /^[0-9-]/) {
                        $val =~ s/a/e-18/;
                        $val =~ s/f/e-15/;
                        $val =~ s/p/e-12/;
                        $val =~ s/n/e-9/;
                        $val =~ s/u/e-6/;
                        $val =~ s/m/e-3/;
                        if ($mosparam eq "vgs") {
                            $vgs = $val;
                        }
                        if ($mosparam eq "vth") {
                            $vth = $val;
                        }
                        if ($mosparam eq "vds") {
                            $vds = $val;
                        }
                        if ($mosparam eq "vdsat") {
                            #print "$val\n";
                            $vdsat = $val;
                        }
                    }
                    if ($mosparam eq "element") {
                        if ($device eq $val) {
                            $valid = 1;
                        } else {
                            $valid = 0;
                        }
                    }
                    if (($mosparam eq "subckt") || ($mosparam eq "element") || ($mosparam eq "region") || ($mosparam eq "id") || ($mosparam eq "vgs") || ($mosparam eq "vds") || ($mosparam eq "vth") || ($mosparam eq "vdsat") || ($mosparam eq "gm") || ($mosparam eq "model") || ($mosparam eq "gds")) {
                        if ($valid == 1) {
                            #print "hello\n";
                            $value{$mosparam}[$idx] = $val;
                            $param_arr[$j] = $mosparam;
                            $j++;
                            $num_params = $j;
                        }
                    }
                }
                if ($DATAFILE =~ /subckt/) {
                    $found_trans = 1;
                }
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
        my @out_dat = ();
        my @out_csv = ();
    
        push @out_dat, "${input_param},$param_arr[$i]\n";
        push @out_csv, "${input_param},$param_arr[$i]\n";
        for ($j=0; $j<$num_iter; $j++) {
            push @out_dat, "$param_val_arr[$j] $value{$param_arr[$i]}[$j]\n";
            push @out_csv, "$param_val_arr[$j],$value{$param_arr[$i]}[$j]\n";
        }
        my $writefile_dat = Util::Misc::write_file(\@out_dat, "Param_${input_param}/${device}_${param_arr[$i]}_sweep.dat");
        my $writefile_csv = Util::Misc::write_file(\@out_csv, "Param_${input_param}/${device}_${param_arr[$i]}_sweep.csv");
    }
}
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

    &usage(0) if $opt_help;
    &usage(1) unless( $success );
   return;
}

sub usage($) {
my $exit_status = shift || '0';
    my $USAGE = <<EOusage;

    Usage:   gen_parsweep_op.pl [-help] [-h]
     
     This script is to calculate the min and max and sigma from the distribution.  

EOusage
nprint ("$USAGE");
exit;
}    


