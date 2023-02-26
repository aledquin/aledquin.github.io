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
    
    if((@ARGV == 0)) {
        eprint "arguments missing\n";
        exit;	
    }

    
    unlink "rm ./results/jitter_summary.csv";
    
    $idx=0;
    my @corner_read = read_file("corner_list.txt");
#    open my $FILE, "corner_list.txt" or die $!;
    
    foreach my $FILE (@corner_read) {
            chomp $FILE;
            $corner[$idx] = $FILE;
            $idx++;
    }
    
    $BW = $ARGV[0];
    $fhpf = $ARGV[1];
    my $Fo = $ARGV[2];
    
    $num = $idx;
    
    $end = 0;
    $idx = 0;
    $jitter_cnt = 0;
    
    my @FILEOUT = (); # ">./results/jitter_summary.csv" or die $!;
    
    push @FILEOUT, ",Freq,PLLBW,CDRBW,PhaseRJ(ps),PeriodRJ(ps)\n";
    
    while ($end == 0) {
    
        $curr_corner = $corner[$idx];
    
        @fields = split /_/, $curr_corner;
        $corner = $fields[0];
        $R = $fields[1];
        $vdd = $fields[2];
        $beol = $fields[3];
        $temp = $fields[4];
    
        $dir = "Run_${corner}_${R}_${vdd}_${beol}_${temp}";
    
        run_system_cmd("cd $dir; ./scripts/calc_jitter2.pl out.printac0 $BW $fhpf $Fo > jitter.dat", "$VERBOSITY");
    
        my @JITFILE = read_file("$dir/jitter.dat");
        #combine the jitter results into one spreadsheet
        $str = "$dir";
        foreach my $JITFILES (@JITFILE) {
            chomp $JITFILES;
            $temp = $JITFILES;
            $temp =~ s/[ ]+//g;
            @fields2 = split /=/, $temp;
            $val = $fields2[1];
            $str = $str . ",$val";
        }
        push @FILEOUT, "$str\n";
        if ($idx >= ($num-1)) {
            $end = 1;
        }
        $idx++;
    }
    my $writefile_out = Util::Misc::write_file(\@FILEOUT, "./results/jitter_summary.csv");
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
