#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Pod::Usage;
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
    my $beol;
    my @corner = ();
    my $corner;
    my $curr_corner;
    my $dir;
    my $end;
    my @fields = ();
    my $idx =0;
    my $num;
    my $R;
    my $temp;
    my $vdd;
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    my $opt_help = "";
    ($opt_help) = process_cmd_line_args();

        utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);
    
#	if((@ARGV == 0)) {
#        eprint "Script to generate all parsweep directory\n";
#		exit;	
#	}
    
    if (defined $ARGV[0]) {
        $corner[0] = $ARGV[0];
    } else {
        my @FILE = read_file("corner_list.txt");
        foreach my $corner_list (@FILE) {
            chomp $corner_list;
            if ($corner_list !~ /^\*/) {
                $corner[$idx] = $corner_list;
                $idx++;
            }
        }
    }
    
    $num = $idx;
    
    $end = 0;
    $idx = 0;
    my @RUNFILE = ();
    while ($end == 0) {
    
        $curr_corner = $corner[$idx];
        @fields = split /_/, $curr_corner;
        $corner = $fields[0];
        $R = $fields[1];
        $vdd = $fields[2];
        $beol = $fields[3];
        $temp = $fields[4];
    
        $dir = "Run_${corner}_${R}_${vdd}_${beol}_${temp}";
    
        run_system_command("cd $dir; ./scripts/gen_parsweep_run_dir.pl", "$VERBOSITY");
    
        push @RUNFILE, "cd ${dir}\n";
        push @RUNFILE, "source run_parsweep.csh\n";
        push @RUNFILE, "cd ..\n";
    
        if ($idx >= ($num-1)) {
            $end = 1;
        }
    
        $idx++;
    }
    my $writefile_out = Util::Misc::write_file(\@RUNFILE,"run_parsweep.csh");
    Util::Messaging::iprint("Run complete\n");
}

sub print_usage {
    my $ScriptPath = shift;
    Util::Messaging::nprint("Current script path:  $ScriptPath\n");
    Util::Messaging::nprint("If path to corner_list.txt is not given as arguement, Please run in the directory where the file exists.\n");
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
