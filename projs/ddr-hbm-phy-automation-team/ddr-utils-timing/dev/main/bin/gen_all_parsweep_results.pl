#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Pod::Usage;
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
    my $beol;
    my @corner = ();
    my $corner;
    my $curr_corner;
    my %data = ();
    my $dir;
    my $end;
    my @fields = ();
    my @fields2 = ();
    my $hdr_marker;
    my $hdr_str;
    my $i;
    my $idx = 0;
    my $j;
    my $measure;
    my $num;
    my $num_param;
    my $param;
    my @param_val = ();
    my $R;
    my $slope;
    my $str;
    my $str_gain;
    my $temp;
    my $vdd;
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    my $opt_help = "";
    ($opt_help) = process_cmd_line_args();
	if((@ARGV == 0)) {
        iprint "Script to generate all parsweep results\n";
		exit;
	}
    utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);
    my @FILE = read_file("corner_list.txt");
    foreach my $file (@FILE) {
        chomp $file;
        if ($file !~ /^\*/) {
           $corner[$idx] = $_;
           $idx++;
        }
    }
    
    $param = $ARGV[0];
    $measure = $ARGV[1];
    
    run_system_command("rm ./results/Param_${param}_${measure}.csv", "$VERBOSITY");
    
    $num = $idx;
    
    $end = 0;
    $idx = 0;
    
    while ($end == 0) {
    
        $curr_corner = $corner[$idx];
    
        @fields = split /_/, $curr_corner;
        $corner = $fields[0];
        $R = $fields[1];
        $vdd = $fields[2];
        $beol = $fields[3];
        $temp = $fields[4];
    
        $dir = "Run_${corner}_${R}_${vdd}_${beol}_${temp}";
    
        run_system_command("cd $dir; ./scripts/gen_parsweep_results.pl", "$VERBOSITY");
        my @FILE_sweep = read_file("$dir/Param_${param}/${measure}_sweep.csv");
        $j = 0;
        foreach my $sweep (@FILE_sweep) {
            chomp $sweep;
            if ($sweep =~ /^[0-9]/) {
                @fields2 = split /,/, $sweep;
                #print "debug = $fields2[1]\n";
                $data{$curr_corner}[$j] = $fields2[1]; 
                $param_val[$j] = $fields2[0];
                #print "Param = $param_val[$j]\n";
                #print "Value = $data{$curr_corner}[$j]\n";
                $j++;
                $num_param = $j;
            }
        }
        if ($idx >= ($num-1)) {
            $end = 1;
        }
        $idx++;
    }
    
    #consolidate data into one *.csv file
#    open my $FILEOUT, ">", "./results/Param_${param}_${measure}.csv" or die $!;
#    open my $FILEOUT2, ">", "./results/Param_${param}_${measure}_Gain.csv" or die $!;
    my @FILEOUT =();
    my @FILEOUT2 =();
    $hdr_marker = 0;
    
    $hdr_str = "$param";
    
    for ($i=0; $i<$num_param; $i++) {
        $str = "$param_val[$i]";
        $str_gain = "$param_val[$i]";
        for ($j=0; $j<$idx; $j++) {
            $hdr_str = $hdr_str . ",$corner[$j]";
            $str = $str . ",$data{$corner[$j]}[$i]";
            if ($i>0) {
                $slope = ($data{$corner[$j]}[$i]-$data{$corner[$j]}[$i-1])/($param_val[$i]-$param_val[$i-1]);
                $str_gain = $str_gain . ",$slope";
            } else {
                $str_gain = $str_gain . ",";
            }
        }
        if ($hdr_marker == 0) {
            push @FILEOUT, "$hdr_str\n";
            push @FILEOUT2, "$hdr_str\n";
            $hdr_marker = 1;
        }
        push @FILEOUT, "$str\n";
        push @FILEOUT2, "$str_gain\n";
    }
    my $writefile_out = Util::Misc::write_file(\@FILEOUT,"./results/Param_${param}_${measure}.csv");
    my $writefile_out2 = Util::Misc::write_file(\@FILEOUT2,"./results/Param_${param}_${measure}_Gain.csv");
    Util::Messaging::iprint("Run complete\n");
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
