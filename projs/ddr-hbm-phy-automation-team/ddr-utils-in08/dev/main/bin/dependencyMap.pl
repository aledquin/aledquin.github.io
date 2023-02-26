#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Clone 'clone';
use List::MoreUtils qw/uniq/;
use Capture::Tiny qw/capture/;
use Getopt::Long;
use Cwd;


use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;


#
##  Constants
our $LOG_INFO = 0;
our $LOG_WARNING = 1;
our $LOG_ERROR = 2;
our $LOG_FATAL = 3;
our $LOG_RAW = 4;


#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#


use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);


utils__script_usage_statistics( $PROGRAM_NAME, $VERSION);

BEGIN {
    our $AUTHOR='DDR DA';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
END {
   footer();
   write_stdout_log( $LOGFILENAME );
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
}

sub Main {
my $path;my $file;my $output;
my @inputs = @ARGV;
GetOptions (
	"path=s" => \$path,
	"file=s" => \$file,
	"out=s"	 => \$output
);
my $Usage = "Description: Script that creates dependency map for the bbSim files
	$0 -path <design/sim path>
	$0 -file <bbSim file(s) separated by comma>
";

if(!$output) { $output = "missingDependentFiles.txt"; }
my @missedDeps;
my $start = time();
my @allFiles; my $dpath;


if(defined($path) && ($path !~ /\/design\/sim/i)) { print $Usage; exit; } 
elsif(defined($file) && $file =~ /\.bbSim/i) { 
	FILDEF: if($file !~ /\/design\/sim/) { $path = getcwd(); $file = "$path/$file"; }
	if($file !~ /\/bbSim\//i) { print $Usage; exit; }
	($path) = ($file =~ /^(\/.*\/)bbSim\//i); }
elsif(!$path && !$file) { print $Usage; exit; }	
elsif(defined($path) && ($path =~ /\/design\/sim/i)) { if($path =~ /\.bbSim/) { $file = $path; goto FILDEF; } } 
else { print $Usage; exit; }


unless($path =~ /\/$/) { $path = "$path\/"; }
($dpath) = ($path =~ /^(\/.*\/design\/sim\/)/g);
my @files = split(/\,/,$file);
@allFiles = `find -L $path -type f -not -path \"*\/netlist_testbench\/*" \| grep -v data \| grep -v \\\~ \| grep -v \"\.nfs\"`;	
my @allCorners = grep {/\.corners/} @allFiles;
@allCorners = grep {$_ ne ''} @allCorners;
my $corC=0;
GETCOR:
my $cornerFile = $allCorners[$corC];
if($cornerFile eq "") { $corC++; goto GETCOR; }
my @anotherArray = @{clone(\@allFiles)}; 
chomp(@anotherArray);
my @woP = @{clone(\@allFiles)}; s/$dpath//g for(@woP);
my $allPos = "source\|\\.tcl\|\\.va\|\\.py\|\\.inc\|\\.sp\|\\.corners\|\\.variants\|\\.sh\|\\.vec\|\\.measure\|\\.plot\|\\.pl\|\\.raw\|\\.dat\|INCLUDE\|CORNERS_LIST\|SPICE_COMMAND\|PLOT_CONFIG\|MEASURE_CONFIG\|_REPORT\|VARIANTS_\|GDS";
chomp(@allFiles); 
my $tech = getProcess($cornerFile);
my %allDeps; my @bbSimList;
my %theMap;

foreach my $eachFile (@allFiles) {
	next if($eachFile =~ /\.sp/i && $eachFile =~ /\/project\//i || $eachFile =~ /\/cscope\//i || $eachFile =~ /\.txt/i || $eachFile =~ /\.[a-z]*log/i || ($eachFile !~ /scripts/i && $eachFile !~ /\.[a-z]+/i) || $eachFile =~ /\/netlist/i);
	my ($macro) = ($eachFile =~ /\/design\/sim\/([a-z0-9\-\_\.\+]+)\//i);
	next if($macro eq "");
	my @calls = run_system_cmd_array("grep -E \'$allPos\' $eachFile"); 
	@calls = grep {'!/^\$|#|^\*|USAGE|^\-|\.data|^file.*|Binary.*|\:|\;|\[|\]|\<|\>|\(|\)/i'} @calls; @calls = uniq(@calls);
	chomp(@calls);
	if($eachFile =~ /\.bbSim/i) {
		my $i=0; 
		while ($calls[$i] ne '') {
			if($calls[$i] =~ /INCLUDE/ && $calls[$i] =~ /all/) {
				$calls[$i] =~ s/INCLUDE.*all\s+(.*)/$1/g;
				my @allIncs = split(/\s+/,$calls[$i]);
				foreach my $aI (@allIncs) {  unless($aI =~ /^\//) { $aI =~ s/^.*\/([a-z0-9_\-\.]+)\b/$1/ig; } }
				splice @calls,$i,0,@allIncs;
				$i += @allIncs;
			}
			else {
				$calls[$i] = (split(/\s+/,$calls[$i]))[-1];
				unless($calls[$i] =~ /^\//) { $calls[$i] =~ s/^.*\/([a-z0-9_\-\.]+)\b/$1/ig; }
				$i++;
			}
		}
	}
	elsif($eachFile =~ /\/scripts\//i) {
		foreach my $call (@calls) {
			my @nc = (split(/\s+/,$call));
			$call = (grep {/\.pl|\.sh|\.py|\.tc|\.c/i} @nc)[0];
			if($call =~ /\)|\(/) { $call = "" ; next;}
			unless($call =~ /^\//) { $call =~ s/^.*\/([a-z0-9_\-\.]+)\b/$1/ig; }
		}
	}
	else { 
		my $i=0;
		while ($calls[$i] ne '') {
			if($calls[$i] =~ /\.option/ig) {
				my @newC = split(/\s+/,$calls[$i]);
				@newC = grep {/\.va|\.py|\.inc|\.sp|\.corners|\.variants|\.sh|\.vec|\.measure|\.plot|\.pl|\.raw|\.dat|\.tcl/} @newC;
				foreach my $nc (@newC) {  $nc =~ s/\"|\=//g; unless($nc =~ /^\//) { $nc =~ s/^.*\/([a-z0-9_\-\.]+)\b/$1/ig; } }
				$calls[$i] = "";
				splice @calls,$i,-1,@newC;
				$i += @newC;
			} else {
				if($calls[$i] =~ /source/ && $calls[$i] !~ /^source/) { $calls[$i] = ""; next; }
				if ($calls[$i] =~ /SUBCKT/ig || $calls[$i] =~ /\:/g || $calls[$i] =~ /\=/g ) {$calls[$i] = ""; next; }
				$calls[$i] =~ s/source\s+(.*)/$1/ig;
				$calls[$i] =~ s/\.inc.*\'(.*)\'.*/$1/ig;	
				$calls[$i] =~ s/\.vec.*\'(.*)\'.*/$1/ig;				
				$calls[$i] =~ s/\.inc.*\"(.*)\".*/$1/ig;	
				$calls[$i] =~ s/\.vec.*\"(.*)\".*/$1/ig;
				unless($calls[$i] =~ /^\//) { $calls[$i] =~ s/.*\/([a-z0-9_\-\.]+)\b/$1/ig; }
				$i++;
			}
		}
	}
	@calls = uniq(@calls);
	@calls = grep {$_ ne ''} @calls;
	foreach my $call (@calls) {
		$call =~ s/\s+//g;
		if($call =~ /\=/) { $call = ""; next; } 
		my $temp = $call ; 
		$call =~ s/_process\.sp/_$tech\.sp/g; 
		unless($call =~ /^\//) { 
			my $temp = $call;
			$call = (grep {/\b$macro\b/ && /\b$call\b/} @woP)[0]; 
			if($call eq "") { push (@missedDeps,"Missing:$temp\nFrom:$eachFile\n\n"); }
		} 
		else { 	
			my $theFile; my($stdout,$stderr) = capture { $theFile = `ls $call`; }; 
			if($stderr) { push (@missedDeps,"Missing:$call\nFrom:$eachFile\n\n"); }
			$call = "";
		}
	} 
	@calls = grep {$_ ne ''}@calls;
	$eachFile =~ s/.*\/design\/sim\/(.*)/$1/g;
	push(@bbSimList,$eachFile) if($eachFile =~ /\.bbSim/i); 
	chomp(@calls);
	if(@calls) { $allDeps{$eachFile} = \@calls; }
}
print "\n";

#Creating a map
foreach my $bbSimFile (@bbSimList) {
	if(defined($file)) { $file =~ s/^.*\/design\/sim\/(.*)\b/$1/ig; next unless($bbSimFile =~ /$file/); }
	my @list = ("$bbSimFile");
	push(@list, buildTree(\%allDeps,$bbSimFile));
	if(@list) { $theMap{$bbSimFile} = \@list; }
	foreach my $lis (@list) {
		$lis = (grep {/$lis/} @anotherArray)[0];
	}
	iprint join"\n",@list,"\n----\n";
}

if(@missedDeps) { 
	my @fh;
	push @fh, "******************************************* Missing dependent files **********************************************\n";
	push @fh,@missedDeps;
	iprint "Please view $output\n"; 
	write_file(\@fh, $output);
}
my $end = time();

my $tot = ($end - $start);
iprint "Time $tot sec\n";
}

sub buildTree {
	my %list = %{$_[0]}; my $bbF = $_[1]; my @theTree;
	if(!defined(@{$list{$bbF}})) { return ""; }
	@theTree = @{$list{$bbF}};
	@theTree = grep{$_ ne ''}@theTree;
	foreach my $theRoot (@theTree) {  if(defined(@{$list{$theRoot}})) { push(@theTree, buildTree(\%list,$theRoot)); } }
	return uniq(@theTree);
}

sub getProcess {
	my $corner = $_[0];
	chomp($corner);
	my $corFirst = `grep LIB $corner | head -n 1 | sed -E \'s\/\\s\.\*\/\/g\' `;
	chomp($corFirst);
	return($corFirst);
}






	
