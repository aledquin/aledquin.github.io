#!/depot/perl-5.14.2/bin/perl
#!/depot/perl-5.8.0/bin/perl
###############################################################################
#
# Name    : alphaSiSpvtRunSeparate.pl
# Author  : N/A
# Date    : N/A
# Purpose : N/A
#
# Modification History
# 			2022-05-26 12:38:49 => Adding Perl template. HSW.
###############################################################################
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
use Carp qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Cwd;
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;


#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR;              # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version();
our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
#--------------------------------------------------------------------#

BEGIN { our $AUTHOR = 'Multiple Authors'; header(); }

END {
    write_stdout_log("$LOGFILENAME");
    footer();
    utils__script_usage_statistics( "$PROGRAM_NAME", $VERSION );
}

use Getopt::Long;
use File::Basename;
use Cwd 'abs_path';
use Pod::Usage;
use File::Copy;
use File::Basename;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use List::Util qw( min max );

ShowUsage("$RealBin/$RealScript") unless(@ARGV);


  my ($help,$config,$runscript,$inst,$netlist,$postProc,$pvtconfig,$hspiceVersion,$finesimVersion,$siliconsmartVersion,@pvtList,$pvtNum);
  my $mail = 1;
  my $commonSetup = undef;
  my $qsubArgs = " ";
  my $submit=1;
  my $macro = undef;
  my $libDir = undef;
  my $runDir = "./";my $result = GetOptions(
    "submit!" => \$submit,
    "pvtconfig=s" => \$pvtconfig,
    "config=s" => \$config,
    "netlist=s" => \$netlist,
    "inst=s" => \$inst,
    "runscript=s" => \$runscript,
    "help" => \$help,
    "qsubArgs=s" => \$qsubArgs,
    "postProc=s" => \$postProc,
    "h" => \$help,
    "runDir=s" => \$runDir,
    "macro=s" => \$macro,
    "libDir=s" => \$libDir,
    "mail!" => \$mail,
    "commonSetup=s" => \$commonSetup,
    "pvtNum=s" => \ $pvtNum
    );

&ShowUsage("$RealBin/$RealScript") if ($help);;
&Main();
sub Main {

if(length($pvtNum) > 1) {
    @pvtList = split (",", $pvtNum);
} else {
    @pvtList = $pvtNum;
}

my $ArgOK = 1;
$ArgOK &= CheckRequiredArg($macro, "macro");
$ArgOK &= CheckRequiredArg($pvtconfig, "pvtconfig");
$ArgOK &= CheckRequiredArg($config, "config");
$ArgOK &= CheckRequiredArg($netlist, "netlist");
$ArgOK &= CheckRequiredArg($inst, "inst");
$ArgOK &= CheckRequiredArg($runscript, "runscript");
if (!$ArgOK) {die "Exiting on missing required arguments\n"}

my $FileOK = 1;
my $DirOK  = 1;
$FileOK &= CheckFileRead($pvtconfig);
$FileOK &= CheckFileRead($config);
$DirOK  &= CheckDirRead($netlist);
#$FileOK &= CheckFileRead($netlist);
$FileOK &= CheckFileRead($inst);
$FileOK &= CheckFileRead($runscript);
if (!$FileOK) {die "Exiting on unreadable file(s)\n"}

#open (my $PVT, ,"$pvtconfig");
my @PVT = read_file($pvtconfig);
my $line;
my $count = 1;
my $length = scalar(@pvtList); 

#exit;
my $readspf = "";
my $flag = 0;
#DikshantR: Checking PVT spf variable is decalred or not
my $spf_count = grep {$_ =~ m/^set\s+.*_spf\s+\S+/} @PVT;

if($spf_count < $length){
    eprint("Incosistency found with some PVT_spf variable.Either they are not set or have incorrect syntax.Please check.\n    Exiting");
    exit(1);
} 

foreach my $line (@PVT) {
 my $i = 0;

 if ($line =~ m/^set\s+.*_spf\s+(\S+)/) {
	  $readspf = $macro . "_" . $1;
      $flag = 1;
 }
 if ($line =~ /^\s*create_operating_condition\s+(\S+)/) {
   while ($i < $length) {
    chomp ($pvtList[$i]);

    if ($count == $pvtList[$i]) {
        if($readspf eq "") {
            eprint("SPF variable not initialised for $1.Exiting.");
            exit;
        }
	    ProcessPVT($1, $readspf);
        $flag = 0;
        $readspf = "";
        last; 
     }
    $i = $i + 1;
    }
   $count = $count + 1;
  }  
 }

}

########main sub end 

sub mySymlink {
    my $sourceFile = shift;
    my $dir = shift;
    my $extra = shift;
    
    if (!$sourceFile) {return}
    $dir = abs_path($dir);
    my @t = split /\//, $sourceFile;
    my $root = pop @t;
    $sourceFile = abs_path($sourceFile);
#    print "Linking $sourceFile $dir/$root\n";
    symlink $sourceFile, "$dir/$root";
    ##  Extra used for generic names.
    if ($extra && ($root ne $extra)) {symlink $sourceFile, "$dir/$extra"}
    
}


sub ProcessPVT
{
    my $pvt = shift;
	my $spf = shift || "";
    my $dir = "$runDir/char_$pvt";
	my $link_netlist = "$netlist/$spf";
    if (-e $dir)
    {
	##  Clear out existing directory
	if (-d $dir) {run_system_cmd ("rm -rf $dir",$VERBOSITY)}
	else {wprint("$dir exists and is not a directory\n"); return}
    }

    mkdir $dir;
    ProcessConfig($config, $dir, $pvt);
    mySymlink($link_netlist, $dir, "$macro.spf");
    mySymlink($link_netlist, $dir, "$macro.sp");	
    mySymlink($inst, $dir, "$macro.inst");
    mySymlink($runscript, $dir, "run_$macro.tcl");
    mySymlink($postProc, $dir, "${macro}_postproc.tcl");
    mySymlink($commonSetup, $dir, "commonSetup");
    run_system_cmd ("cd $dir ;touch $macro.rechar",$VERBOSITY);
    run_system_cmd ("cd $dir ;touch $macro.repost",$VERBOSITY);

    if ($libDir) {
	if (!(-e $libDir)) {mkdir $libDir}
	if (-e $libDir && !(-d $libDir)) {
	    eprint("Error:  $libDir exists, not directory\n");
	}
	else {
	    mySymlink($libDir, $dir, "liberty");
	}
    }
    CreateRunScript($dir, $pvt);
}

sub CreateRunScript
{
    my $dir = shift;
    my $pvt = shift;
    my ($siliconsmartVersion,$siliconsmartModule,$hspiceVersion,$finesimVersion,$hspiceModule,$finesimModule,$stderr1,$stderr2,$stderr3) = "";
    
    #($siliconsmartVersion, $stderr1) =  run_system_cmd("grep siliconsmartVersion ../common_source/commonSetup.tcl | cut -d ' ' -f3",$VERBOSITY);
    #($finesimVersion, $stderr2) = run_system_cmd("grep finesimVersion ../common_source/commonSetup.tcl | cut -d ' ' -f3",$VERBOSITY);
    #($hspiceVersion, $stderr3) = run_system_cmd("grep hspiceVersion ../common_source/commonSetup.tcl | cut -d ' ' -f3",$VERBOSITY);
	my @CommonSetup = read_file("../common_source/commonSetup.tcl");
	foreach my $line (@CommonSetup) {
	    if($line =~ m/^#/m) {
		    next;
		} 
		if($line =~ m/siliconsmartVersion/) { 
		    $siliconsmartVersion = (split " ",$line)[-1];
		}
		if($line =~ m/finesimVersion/) { 
		   $finesimVersion  = (split " ",$line)[-1];
		}
		if($line =~ m/hspiceVersion/) { 
		    $hspiceVersion = (split " ",$line)[-1];
		}

		
	}

    
    my $fulldir = abs_path($dir);
    #open (my $SCR, ,">$fulldir/run_char.csh");
    my @SCR;
    push @SCR, "#!/bin/csh\n";
    push @SCR, "cd $fulldir\n";
    push @SCR, "module unload siliconsmart\n";
    if ((defined $siliconsmartVersion) and ($siliconsmartVersion ne "")) {$siliconsmartModule = "siliconsmart/$siliconsmartVersion"} else {$siliconsmartModule = "siliconsmart"}
    push @SCR, "module load $siliconsmartModule\n";
    push @SCR, "module unload hspice\n";
    if ((defined $hspiceVersion) and ($hspiceVersion ne '')) {$hspiceModule = "hspice/$hspiceVersion"} else {$hspiceModule = "hspice"}
    push @SCR, "module load $hspiceModule\n";
    if ((defined $finesimVersion) and ($finesimVersion ne '')) {$finesimModule = "finesim/$finesimVersion"} else {$finesimModule = "finesim"}
    push @SCR, "module unload finesim\n";
    push @SCR, "module load $finesimModule\n";
    push @SCR, "module unload ddr-utils-timing\n";
    push @SCR, "module load ddr-utils-timing\n";
	push @SCR, "setenv MACRO $macro\n";
    push @SCR, "siliconsmart -x \"source $runscript\"\n";
    my $status1 = write_file(\@SCR,"$fulldir/run_char.csh");
    chmod 0777, "$fulldir/run_char.csh";
    my $mailArg = ($mail) ? "-m ea" : "";
    if ($submit) {run_system_cmd ("qsub -P bnormal $qsubArgs -o run_char_$pvt.log -e run_char_$pvt.err -cwd $mailArg $fulldir/run_char.csh",$VERBOSITY)}

}

sub ProcessConfig
{
    ## Copies config file to run dir, replacing assignment of active_pvts to current pvt.
    my $config = shift;
    my $dir = shift;
    my $pvt = shift;


    my $fixedConfig = "configure_d589.tcl";
    my ($name,$path,$suffix) = fileparse($config,qr/\.[^.]*/);
    my $dstconfig = "$dir/$name$suffix";
    #open (my $CFG, ,$config);
    #open (my $DST, ,">$dstconfig");
	my @DST;
	my @CFG = read_file($config);
    foreach my $line (@CFG) {
	    if($line =~ m/^(\s*)set\s+(::)?active_pvts\s+.*/) {
            if(defined $2) {
                $line =~ s/^(\s*)set\s+(::)?active_pvts\s+.*/${1}set ${2}active_pvts $pvt/g;
            } else {
                $line =~ s/^(\s*)set\s+(::)?active_pvts\s+.*/${1}set active_pvts $pvt/g;
            }
			}
            push @DST, $line;
    }
    my $writeStatus =  write_file(\@DST, $dstconfig);
    if ("$name$suffix" ne $fixedConfig) {
	symlink "$name$suffix", "$dir/fixedConfig";
    }
}

sub CheckRequiredArg
{
    my $ArgValue = shift;
    my $ArgName = shift;
    if (!defined $ArgValue)
    {
	eprint("Error:  Required argument \"$ArgName\" not supplied\n");
	return 0;
    }
    return 1;
}
sub CheckFileRead
{
    my $filename = shift;
    if (!(-r $filename))
    {
	eprint("Error: Cannot open $filename for read\n");
	return 0;
    }
    return 1;
}
sub CheckDirRead
{
    my $dirname = shift;
    if (!(-e $dirname))
    {
	print "Error: Cannot find $dirname for read\n";
	return 0;
    }
    return 1;
}
sub ShowUsage
{
    my $ScriptPath = shift;
    iprint("Current script path:  $ScriptPath\n");
    pod2usage(0);

}


__END__

=head1 SYNOPSIS

    ScriptPath/alphaSiSpvtRunSeparate.pl \
    -config <config-file> \
    [-pvtconfig <pvt-config-file> \]
    -netlist <netlist> \
    -inst <inst-file> \
    -runscript <SiS-run-file> \
    [-help \]
    [-h]

This script allows siliconsmart runs to be broken into separate jobs, one for each pvt. Each job is separately qsub'ed.

=item B<config-file> 
The SiS config file.  Required.

=item B<pvt-config-file>
The the config file in which the pvt corners are defined.. Can be the same as config-file, if organized as a single file.

=item B<netlist>
The netlist to use. Required.

=item B<inst-file>
The inst file to use. Required.

=item B<SiS-run-file>
The SiS tcl script that runs the characterization.

