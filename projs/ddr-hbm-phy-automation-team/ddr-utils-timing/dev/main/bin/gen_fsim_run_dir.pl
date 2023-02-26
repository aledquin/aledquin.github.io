#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     ;
use Cwd 'abs_path';
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Pod::Usage;
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
    write_stdout_log($LOGFILENAME);
    local $?;   ## adding this will pass the status of failure if the script
                ## does not compile; otherwise this will always return 0
    footer(); 
}

sub Main {
    my ($dir,$end);
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
    my @corner =();
    my $corner;
    my $curr_corner = 0;
    my $found_param_col;
    my $R;
    my $str_param;
    my $value;
    my $vdd;
    my $post;
    my @runfile = ();
    
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
        my @read_corner = read_file("corner_list.txt");    
        foreach my $FILE (@read_corner) {
            chomp $FILE;
            if ($FILE !~ /^\*/) {
                $corner[$idx] = $FILE;
                $idx++;
            }
        }
    }
    $num = $idx;
    $end = 0;
    $idx = 0;    
    while ($end == 0) {
        $curr_corner = $corner[$idx];
        if(defined $curr_corner) {
            @fields = split /_/, $curr_corner;
            $corner = $fields[0];
            $R = $fields[1];
            $C = $fields[2];
            $vdd = $fields[3];
            $beol = $fields[4];
            $temp = $fields[5];
            $dir = "Run_${corner}_${R}_${C}_${vdd}_${beol}_${temp}";
            iprint "$dir\n";            
            run_system_cmd("mkdir $dir", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../cmd_file.txt .", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../run_sim_fsim.csh run_sim.csh", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../netlist/input.ckt .", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../netlist/netlist_${beol}.spf netlist.spf", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../param.cmd .", "$VERBOSITY");
            if ($post == 1) {
                run_system_cmd("cd $dir; ln -s ../../model_inc/lib_${corner}_post.inc model.inc", "$VERBOSITY");
            } else {
                run_system_cmd("cd $dir; ln -s ../../model_inc/lib_${corner}.inc model.inc", "$VERBOSITY");
            }
            run_system_cmd("cd $dir; ln -s ../../model_inc/lib_${R}.inc model_res.inc", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../model_inc/lib_${C}.inc model_cap.inc", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../model_inc/temp_${temp}C.inc temp.inc", "$VERBOSITY");
        #   run_system_cmd("cd $dir; ln -s ../../netlist/mbcoreplldig_star_nominal_110.spf netlist.spf", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../probes/probes.inc .", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../tb_params/params.inc .", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../model_inc/supply_${vdd}.inc supply.inc", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../measure/measure.inc .", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../../analysis/analysis.inc .", "$VERBOSITY");
            run_system_cmd("cd $dir; ln -s ../scripts .", "$VERBOSITY");
            push @runfile, "cd ${dir}\n";
            push @runfile, "source run_sim.csh\n";
            push @runfile, "cd ..\n";
            if ($idx >= ($num-1)) {
                $end = 1;
            }
            $idx++;
        }
    }
    my $writefile_out = Util::Misc::write_file(\@runfile,"run.csh");
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
