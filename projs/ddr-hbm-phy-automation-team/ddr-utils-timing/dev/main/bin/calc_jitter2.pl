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
use Cwd qw( abs_path getcwd );
use Cwd;
use Carp qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = FALSE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#
##------------------------------------------------------------------
##  Gather run statistics for the script
##     First argument is name of the script.
##     Second argument is the script version. (ie. 2022ww10)
##     Third argument (optional) is an aref, used
##          to capture the cmd line arguments and log them.
##------------------------------------------------------------------
our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
BEGIN { our $AUTHOR='Multiple Authors'; header(); } 
&Main();
END {
   write_stdout_log("${LOGFILENAME}");
   footer(); 
   utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);
}

use Data::Dumper;
use Getopt::Long;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

#
##  Constants
our $LOG_INFO = 0;
our $LOG_WARNING = 1;
our $LOG_ERROR = 2;
our $LOG_FATAL = 3;
our $LOG_RAW = 4;



#####################################################################################################################################################################

my ($debug,$opt_help);

sub Main {

($debug,$opt_help)
            = process_cmd_line_args();    

    if ( $opt_help ) {
        usage();
    }

#if($#ARGV == 0) {
#    print_usage();
#     exit 0
# }

my $filename = $ARGV[0];
my $PLLBW = $ARGV[1];
my $Fhpf = $ARGV[2];
my $Fo = $ARGV[3];

#$Fo = 1.2e9;
#$Fi1 = 1e6;
#$Fi2 = 100e6;

#open(my $FILE, "$filename") or die $!;
my @FILE = read_file("$filename");

my $idx=0;
my $pnsum = 0;
my @freq = "";
my @val = "";
foreach (@FILE) {

        chomp();

	$_ =~ s/^[ ]+//;
	
	my @fields = split /[ ]+/, $_;
	if ($_ =~ /^[0-9]/) {
		$freq[$idx] = $fields[0];
		$freq[$idx] =~ s/p/e-12/;
		$freq[$idx] =~ s/n/e-9/;
		$freq[$idx] =~ s/u/e-6/;
		$freq[$idx] =~ s/m/e-3/;
		$freq[$idx] =~ s/k/e3/;
		$freq[$idx] =~ s/x/e6/;
		$freq[$idx] =~ s/g/e9/;
		$val[$idx] = $fields[1];
		$val[$idx] =~ s/p/e-12/;
		$val[$idx] =~ s/n/e-9/;
		$val[$idx] =~ s/u/e-6/;
		$val[$idx] =~ s/m/e-3/;
		$val[$idx] =~ s/k/e3/;
		$val[$idx] =~ s/x/e6/;
		$val[$idx] =~ s/g/e9/;
		#print "Freq = $freq[$idx], Val = $val[$idx]\n";
		$idx++;
	}
	
}


my $size = $idx;

my $perpnsum = 0.0;

my ($temp,$temp2,$j,$deltaf) = "";
##Integrate to calculate phase jitter and period jitter
for (my $idx=1; $idx<$size; $idx++) {
	##if (($freq[$idx] >= $Fi1) && ($freq[$idx] <= $Fi2)) {
	if ($freq[$idx] <= ($Fo*0.5)) {
		$temp = (($val[$idx])**2)*((($freq[$idx]/$PLLBW)**2)/(1+($freq[$idx]/$PLLBW)**2))*((($freq[$idx]/$Fhpf)**2)/(1+($freq[$idx]/$Fhpf)**2));
		$temp2 = $temp*(sin(3.14*$freq[$idx]/$Fo))**2;
		$j = $idx-1;
		$deltaf = $freq[$idx]-$freq[$j];
		$pnsum = $pnsum + $temp*$deltaf;
		$perpnsum = $perpnsum + $temp2*$deltaf;
	}
}

my $phase_rj = 1e12*(1.0/(2*3.14*$Fo))*sqrt($pnsum);
my $period_rj = 1e12*(1.0/(2*3.14*$Fo))*sqrt(4.0*$perpnsum);

iprint ("Carrier Frequency = $Fo\n");
iprint ("PLL Bandwidth= $PLLBW\n");
iprint ("CDR bandwidth= $Fhpf\n");
iprint ("Phase RJ (ps) = $phase_rj\n");
iprint ("Period RJ (ps) = $period_rj\n");
}


sub process_cmd_line_args(){
    my ($debug,$opt_help,$opt_dryrun,$opt_debug,$opt_verbosity);


    my $success = GetOptions(
               "help|h"          => \$opt_help,
               "dryrun!"         => \$opt_dryrun,
               "debug=i"         => \$opt_debug,
               "verbosity=i"     => \$opt_verbosity
        );


    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    &usage(0) if $opt_help;
    &usage(1) unless( $success );

    return ($opt_debug,$opt_help)	

}

sub usage($) {
my $exit_status = shift || '0';
    my $USAGE = <<EOusage;

    Script to caculate jitter values.
EOusage

    nprint ("$USAGE");
    exit;    
}
