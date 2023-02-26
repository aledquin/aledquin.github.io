#!/depot/perl-5.14.2/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Path;
use Cwd;

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

##  Constants
our  $LOG_INFO = 0;
our  $LOG_WARNING = 1;
our  $LOG_ERROR = 2;
our  $LOG_FATAL = 3;
our  $LOG_RAW = 4;
#--------------------------------------------------------------------#



use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);


utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);

#########################################################################
BEGIN { our $AUTHOR='DA WG'; header(); } 
&Main();
END {
   write_stdout_log("$LOGFILENAME");
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}


##########################################################################
##########################################################################
##########################################################################

sub Main {

my @params_to_be_ignored=(
"add_Parameter_name_here",
);
# list of parameters to remove from instance section SPF netlists
##########################################################################
##########################################################################
##########################################################################

my $in_file = $ARGV[0];

if (not defined($in_file)) {

Util::Messaging::eprint("wrong args, try <DSPF>\n");
exit;
}

my $out_file = "$in_file"."_RemovedParams";
my @OUT;
my @IN_FILE = Util::Misc::read_file("$in_file");
#open($OUT,">","$out_file")		|| die ("Can't open output file: $out_file");

#open ($IN_FILE,"<","$in_file")	|| die "Can't find or open in_file\n";

my $reached_ins_sec=0;
#$do_not_print=0;
foreach my $str (@IN_FILE) 

	{
		
		if ($str =~ /\*\s+Instance\s+Section/i) {
		$reached_ins_sec=1;
		push @OUT, $str;
		Util::Messaging::iprint("REACHED: $str");
		next;
		}
		elsif( $reached_ins_sec == 0) {
		
		push @OUT, $str;
		next;
		}
		
		chomp($str);
		
		foreach my $param (@params_to_be_ignored) {
		
		if ($str =~ /$param\s*\=\s*\S+/i) {
		
		$str=~ s/\s+$param\s*\=\s*\S+//i;
		
		#$a=<STDIN>;
		}
		
		}
		
				
		
		
		push @OUT , "$str\n";
		
	
	}	
;

push @OUT, "*** Processed by $0 @ARGV\n";
push @OUT, "*** List of parameters which are ignored: @params_to_be_ignored \n";
my $status = Util::Misc::write_file(\@OUT, $out_file);
}

