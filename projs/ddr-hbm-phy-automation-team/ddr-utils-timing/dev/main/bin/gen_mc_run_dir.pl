#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Getopt::Long;
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
    my @corner;
    my $corner;
    my @run_mc =();
    my $curr_corner;
    my $dir;
    my $end;
    my @fields;
    my $idx;
    my $num;
    my $num_iter;
    my $temp;
    my $test;
    my $vdd;
    #open FILE, "corner_list.txt" or die $!;
    $num_iter = 100;
    $num = $idx;
    $end = 0;
    $idx = 0;
    
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


        run_system_cmd("mkdir MonteCarlo", "$VERBOSITY");
    
    while ($end == 0) {
        $curr_corner = $corner[$idx];
        if(defined $curr_corner) {
            @fields = split /_/, $curr_corner;
            $corner = $fields[0];
            $vdd = $fields[1];
            $temp = $fields[2];
            $dir = "MC_${idx}";
            #print "$dir\n";    
            run_system_cmd("cd MonteCarlo; mkdir $dir", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../run_sim.csh .", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../cmd_file.txt .", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../model.inc .", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../model_res.inc .", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../model_cap.inc .", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../temp.inc .", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../probes.inc .", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../params.inc .", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../supply.inc", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../measure.inc .", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../input.ckt .", "$VERBOSITY");
            run_system_cmd("cd MonteCarlo/$dir; ln -s ../../netlist.spf .", "$VERBOSITY");
            #run_system_cmd("sed -e 's/analysis/analysis_mc/' input.ckt > temp", "$VERBOSITY");
            #run_system_cmd("cp temp MonteCarlo/$dir/input.ckt", "$VERBOSITY");
            #run_system_cmd("rm temp", "$VERBOSITY");
            $test = $idx+1;
            run_system_cmd("sed -e 's/xMidx/$test/' ../../analysis/analysis_mc.inc > temp", "$VERBOSITY");
            run_system_cmd("cp temp MonteCarlo/$dir/analysis.inc", "$VERBOSITY");
            run_system_cmd("rm temp", "$VERBOSITY");
            
            push @run_mc, "cd MonteCarlo/${dir}\n";
                push @run_mc, "source run_sim.csh\n";
                push @run_mc, "cd ../../\n";
    
            if ($idx >= ($num_iter-1)) {
                $end = 1;
            }
    
            $idx++;
        } else {
            exit;
        }
    }
    my $writefile_out = Util::Misc::write_file(\@run_mc, "run_mc.csh");
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

sub process_cmd_line_args() {
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
