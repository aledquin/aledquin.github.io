#!/depot/perl-5.14.2/bin/perl
#Developed By IN08 timing team
#Maintained By Dikshant Rohatgi
#To be used to Sort the timing Arcs and Timing Arc Types in alphabetical order.
#Works as an alternative to SortArc Function of alphaLibParser package.
use strict;
use warnings;
our $ScriptPath;
BEGIN {
#    ## This bit is needed to be able to pick up the alphaLibParser package.
#    ##  It is assumed to reside in the same directory as this script.
    my @toks = split(/\//, $0);
    pop (@toks);
    $ScriptPath = join("/", @toks);
    #$ScriptPath = abs_path($ScriptPath);
#    push @INC, $ScriptPath;  ##  Need this to pick up the alphaLibParser
#    print "INC:\n";
#    foreach my $x (@INC) {
#	print "\t$x\n";
#    }
}

##  This supposedly allows use to pick up the script dir.

use FindBin;

use lib "$FindBin::Bin";
use Getopt::Long;
use File::Basename;
use Cwd 'abs_path';
use Pod::Usage;
use Data::Dumper;
use Cwd;
use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../lib/perl/";
use Util::Misc;
use Util::Messaging;
use SortArc_utils;


#
##  Constants
our $LOG_INFO = 0;
our $LOG_WARNING = 1;
our $LOG_ERROR = 2;
our $LOG_FATAL = 3;
our $LOG_RAW = 4;


our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version() || '2022.11';
our $LOGFILENAME   = getcwd() . "/$PROGRAM_NAME.log";
our $DEBUG        = 0;
our $VERBOSITY    = 0;

utils__script_usage_statistics( "ddr-da-ddr-utils-timing-$PROGRAM_NAME", $VERSION);

BEGIN { our $AUTHOR='dikshant'; header(); } 
Main()  unless caller();
END {
   local $?;   # to prevent the exit() status from getting modified
   write_stdout_log( $LOGFILENAME );
   footer(); 
}

unless(@ARGV) {ShowUsage() }

sub Main {
    my @libertyArg;
    my $outdir = "sortArcs";
    my $help;
    my $result = GetOptions(
    "outdir=s" => \$outdir,
    "help" => \$help
    );

    if ($help) {ShowUsage() }

    my @libertyFiles;

    foreach my $l (@ARGV) {push @libertyFiles, glob($l)}

    if (@libertyFiles == 0) {
        eprint("Error:  No Liberty files specified\n");
        exit 1;
    }

    my @libArray;
    foreach my $lib (@libertyFiles) {
	    if(!(-e "$lib")) {
	        eprint("Error: No $lib found\n");
		    exit 1;
	    }
        my $libFile = SortArc_utils::readLib($lib);
        if (defined $libFile) {
	        SortArc_utils::sortArcs($libFile);
	        SortArc_utils::setFilePath($libFile, $outdir);
	        SortArc_utils::writeLib($libFile);
        }

    }
}
sub ShowUsage {
    iprint("Current script path:  $ScriptPath\n");
    pod2usage(0);
}

__END__
=head1 SYNOPSIS

    ScriptPath/SortArcs.pl lib1 lib2 ... [-outdir output-dir] [-help]

B<This program> is designed to reorder the pin, pg_pin and bus bus groups, as well as the orders of timings arcs within the pin groups. 
The intent is to make pin and arc order consistent across a set of libs.

=head1 OPTIONS

=over 4

=item B<-h[elp]>  Prints this usage info

=item B<-outdir>  Specifies ths directories to write the reordered libs to.  The default is ./sortArcs.

=back


=cut
