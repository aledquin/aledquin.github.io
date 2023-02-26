#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
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
##  This supposedly allows use to pick up the script dir.
use lib "$RealBin/../lib/perl/";
use alphaLibParser;

use Getopt::Long;
use File::Basename;
use Cwd 'abs_path';
use Pod::Usage;
use Data::Dumper;

my @libertyArg;
my $outdir = "libReorder";
my $help;
my $opt_help = FALSE;
my $debug;


    nprint ("INC:\n");
    foreach my $x (@INC) {
	nprint ("\t$x\n");
    }


#
#unless(@ARGV) {ShowUsage() }

sub Main {

#my $result = GetOptions(
#    "outdir=s" => \$outdir,
#    "help" => \$help
#    );

#if ($help) {ShowUsage() }
($debug,$outdir,$opt_help) = process_cmd_line_args();

    if ( $opt_help ) {
        usage();
    }

my @libertyFiles;

foreach my $l (@ARGV) {push @libertyFiles, glob($l)}

if (@libertyFiles == 0) {
    eprint ("Error:  No Liberty files specified\n");
    exit;
}

my @libArray;
foreach my $lib (@libertyFiles) {
    my $libFile = readLib($lib);
    if (defined $libFile) {
	sortPins($libFile);
	sortArcs($libFile);
	setFilePath($libFile, $outdir);
	writeLib($libFile);
    }

}

}

sub process_cmd_line_args(){
    my ($outdir,$opt_help,$opt_dryrun,$opt_debug,$opt_verbosity);
    my $success = GetOptions(
               "help|h"          => \$opt_help,
               "dryrun!"         => \$opt_dryrun,
               "debug=i"         => \$opt_debug,
               "verbosity=i"     => \$opt_verbosity,
	       "outdir=s"	 => \$outdir
	);

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    return ($opt_debug,$outdir,$opt_help);	
}

sub usage($) {
    my $exit_status = shift || '0';
	pod2usage($exit_status);
   
}
#sub ShowUsage {
#    print "Current script path:  $ScriptPath\n";
#    pod2usage(0);
#}

__END__
=head1 SYNOPSIS

    ScriptPath/alphaLibReorder.pl lib1 lib2 ... [-outdir output-dir] [-help]

B<This program> is designed to reorder the pin, pg_pin and bus bus groups, as well as the orders of timings arcs within the pin groups. 
The intent is to make pin and arc order consistent across a set of libs.

=head1 OPTIONS

=over 4

=item B<-h[elp]>  Prints this usage info

=item B<-outdir>  Specifies ths directories to write the reordered libs to.  The default is ./libReorder.

=back


=cut
