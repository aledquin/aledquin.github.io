#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Cwd;
use Cwd 'abs_path';
use Pod::Usage;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = FALSE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version() || '2022.11'; # Syntax: YYYYww##[.#] optional day 1-7
                                # The work week number can be found in
                                # your outlook calendar. The days are 1=sunday
                                # 2=monday ... 7=saturday
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
   write_stdout_log("${LOGFILENAME}.log");
   footer(); 
   utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);
}



#ShowUsage() unless(@ARGV);

my $opt_help = FALSE;
my $debug;
my $refLib;
my $testLib;
my $verbose = 0;
my $output = "comparison.txt";
my $sisVersion = "siliconsmart";  ##  Default module
my $absolute_tolerance = 0.005;
my $relative_tolerance = 0.05;
#my $help = 0;
#my $result = GetOptions(
#		     "refLib=s" => \$refLib,
#		     "testLib=s" => \$testLib,
#		     "verbose!" => \$verbose,
#		     "output=s" => \$output,
#		     "sisVersion=s" => \$sisVersion,
#		     "absolute_tolerance=f" => \$absolute_tolerance,
#		     "relative_tolerance=f" => \$absolute_tolerance,
#		     "help|h" => \$help
#		     );
#
#if ($help) {ShowUsage()}

sub Main {

($debug,$refLib,$testLib,$output,$sisVersion,$absolute_tolerance,$relative_tolerance,$opt_help)
            = process_cmd_line_args();

my $time = time();

    if ( $opt_help ) {
        usage();
    }

$output = abs_path($output);

my $argOK = 1;
$argOK &= CheckRequiredArg("refLib", $refLib);
$argOK &= CheckRequiredArg("testLib", $testLib);
if (!$argOK) {die "Exiting on missing required argument(s)\n"}

my $fileOK = 1;
$fileOK &= CheckFileRead($refLib);
$fileOK &= CheckFileRead($testLib);
if (!$fileOK) {die "Exiting on missing required file(s)\n"}

my $tmp = $ENV{TMP};
#my $tmp = "./";
if (!(defined $tmp)) {$tmp="./"}

my $sisScript = "$tmp/alphaCompareLib_$time.tcl";
my $sisCmd = "compare_liberty -ref_lib $refLib -test_lib $testLib -output $output";
if ($verbose) {$sisCmd .= " -verbose"}
#open my $SIS, ">$sisScript";

#print $SIS "define_parameters validation {\n";
#print $SIS "    set absolute_tolerance $absolute_tolerance\n";
#print $SIS "    set relative_tolerance $relative_tolerance\n";
#print $SIS "    set product_tolerance 0\n";
#print $SIS "}\n";
#
#print $SIS "$sisCmd\n";
#print $SIS "exit\n";
my @SIS;
my $SIS = "define_parameters validation {
set absolute_tolerance $absolute_tolerance
set relative_tolerance $relative_tolerance
set product_tolerance 0
}
$sisCmd
exit";
push @SIS,"$SIS\n";
my $status = write_file(\@SIS, $sisScript);
#close $SIS;

my $script = "$tmp/alphaCompareLib_$time.csh";
#open my $SCR, ">$script";
#print $SCR "#!/bin/csh\n";
#print $SCR "module unload siliconsmart\n";
#print $SCR "module load $sisVersion\n";
#print $SCR "siliconsmart $sisScript\n";
#close $SCR;
my @SCR;
my $SCR = "#!/bin/csh
module unload siliconsmart
module load $sisVersion
siliconsmart $sisScript";
push @SCR,"$SCR\n";
my $status1 =  write_file(\@SCR, $script);

chmod 0777, $script;
#print "Executing $script\n";
iprint ("Info:  Comparing $testLib to $refLib\n");
unlink $output;
nprint ("$output\n");
#my @sisOutput = `$script`;
#foreach (@sisOutput) {print}
unlink $script;
unlink $sisScript;
}


sub CheckFileRead
{
    my $file = shift;
    return (-r $file);

}

sub CheckRequiredArg
{
    my $argName = shift;
    my $argValue = shift;

    if (defined $argValue) {return 1}
    eprint ("Required argument \"$argName\" not provided\n");
    return 0;
}

sub process_cmd_line_args(){

my ($refLib,$testLib,$output,$sisVersion,$absolute_tolerance,$relative_tolerance,$opt_help,$opt_dryrun,$opt_debug,$opt_verbosity);


    my $success = GetOptions(
               "help|h"    => \$opt_help,
	       "refLib=s"  => \$refLib,
	       "testLib=s" => \$testLib,
               "dryrun!"   => \$opt_dryrun,
               "debug=i"   => \$opt_debug,
               "verbosity=i"     => \$opt_verbosity,
               "output=s" => \$output,
               "sisVersion=s" => \$sisVersion,
               "absolute_tolerance=f" => \$absolute_tolerance,
               "relative_tolerance=f" => \$absolute_tolerance
	    ); 

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    &usage(0) if $opt_help;
    &usage(1) unless( $success );

    return ($opt_debug,$refLib,$testLib,$output,$sisVersion,$absolute_tolerance,$relative_tolerance,$opt_help);
}


sub usage($) {
my $exit_status = shift || '0';
    my $USAGE = <<EOusage;

    ScriptPath/alphaCompareLib.pl \
    -refLib <Reference-lib> \
    -testLib <Test-lib> \
    [-output <output-file-name>] \
    [-absolute_tolerance <abstol> \
    [-relative_tolerance <reltol> \
    [-sisVersion <siliconsmart module>]

This script will compare two Liberty files using the siliconsmart compare_liberty function. For more details, see the silionsmart manual.


item B<-h> B<-help>

Prints this help

item B<-refLlib> The reference lib.  Required.

item B<-testLib>  The test lib. Required.

item B<-output> The name of the output file. Defaults to ./comparison.txt

item B<-[no]verbose>  Verbosity.

item B<-sisVersion>  The siliconsmart module to use, ex "siliconsmart/2014.09-SP2".  Defaults to the default module.

item B<-absolute_tolerance> Absolute tolerance.  Default: 0.005

item B<-relative_tolerance> relative tolerance.  Default: 0.05

EOusage
nprint ("$USAGE");
exit;

}

__END__

