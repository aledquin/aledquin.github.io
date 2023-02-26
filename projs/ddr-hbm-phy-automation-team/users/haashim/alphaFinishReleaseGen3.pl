#!/depot/perl-5.14.2/bin/perl

use Getopt::Long;
use Pod::Usage;
use File::Copy;

ShowUsage() unless(@ARGV);

my $releaseName;
my $tech;
my $version = "dev";
my $comment;
my $macros;
my $help;
my $checkin = 1;
my $mailRecipients;
my $rtlBranch = "Unspecified";
my $debug = 1;
my $crr = 0;
$result = GetOptions(
    "releaseName=s" => \$releaseName,
    "tech=s" => \$tech,
    "version=s" => $version,
    "description=s" => \$comment,
    "checkin!" => \$checkin,
    "crr!" => \$crr,
    "rtlBranch=s" => \$rtlBranch,
    "debug!" => \$debug,
    "mailRecipients=s" => \$mailRecipients,
    "help" => \$help,
    "h" => \$help
    );

if ($help) {ShowUsage()}

@logPatterns = ("\\.log","\\.pass\$","\\.results\$","\\.xml\$");

my $argOK = 1;
$argOK &= CheckRequiredArg("releaseName", $releaseName);
$argOK &= CheckRequiredArg("comment", $comment);
if (!$argOK) {die "Exiting on missing required argument(s)\n"}

my $user = $ENV{USER};
my $scratch = $ENV{udescratch};
#my $lynxHome = "$scratch/$user/p4_lynx/lynx_workspace";
my $lynxHome = "/u/$user/lynx_workspace";
#/remote/proj/lynx_ip_release/users/$user/lynx_workspace";
my $blockPath = ($version eq "dev") ? "blocks" : "releases/$version/blocks";
my $blockFile = "$lynxHome/$blockPath/$tech/$releaseName/scripts_block/conf/block.tcl";
#my $blockFile = "$lynxHome/$blockPath/$tech/$releaseName/scripts_build/conf/block.tcl";

if (!(-e $blockFile)) {die "Error:  Cannnot file $blockFile\n"}

$TMP = (defined $ENV{TMP}) ? $ENV{TMP} : ".";

##  Look up stuff in the block.tcl by sourcing into tclsh and printing the value for each SVAR
my $tclscript = "$TMP/temp.tcl";
open SH, ">$tclscript";
print SH "source $blockFile\n";
print SH "foreach varName [array names SVAR] {puts \"\$varName=\$SVAR(\$varName)\"}\n";
print SH "exit\n";
close SH;

my @o = `tclsh $tclscript`;
unlink $tclscript;
my %blockSvars;
foreach (@o) {if ($_ =~ /(\S+)\s*=\s*(\S+)/) {$blockSvars{$1}=$2}}

my $dropoffDir = $blockSvars{dropoff_dir};
my $base_names = $blockSvars{base_names};
my $project_name = $blockSvars{project_name};

my $argOK = 1;
$argOK &= CheckRequiredSvar("dropoff_dir", $dropoffDir);
$argOK &= CheckRequiredSvar("base_names", $base_names);
if (!$argOK) {die "Exiting on missing required SVAR\n"}

$dropoffDir = resolveLink($dropoffDir);
if (!(defined $dropoffDir)) {die "Error: Cannot find dropoff_dir in $blockFile\n"}


my $user = $ENV{USER};
#my $mailRecipients = "clouser\@synopsys.com";
#print "$mailCmd\n";

##  Quick lookup of dropoff_dir
#open BLK,$blockFile;
#while ($line = <BLK>) {if ($line =~ /^\s*set\s+SVAR\(dropoff_dir\)\s+\"(\S+)\"/) {$dropoffDir = $1; last}}
#close BLK;
#print "$dropoffDir\n";

chdir $dropoffDir;
my @ipTypes = glob("*");

#my $dropoffQADir = $dropoffDir."_qadata";
#print "dropoff_dir = $dropoffDir, $dropoffQADir\n";
my $dstLogDir = $dropoffDir."/macro/doc/qalogs";
#my $srcLogDir = "$lynxHome/$blockPath/$tech/$releaseName/qa_step/logs";
#my $srcLogDir = "$lynxHome/$blockPath/$tech/$releaseName/qa_step/";
my $srcLogDir = "$lynxHome/builds/$releaseName/qa_step/";

##  A summary is proving maddeningly difficult to generate.

if (!(-e $srcLogDir)) {die "Error:  $srcLogDir does not exist\n"}

if (!(-e $dstLogDir)) {system "p4 sync -q $dstLogDir/..."}  ## If desination log directory does not exist, p4 sync it, just in case.
if ( (-e $dstLogDir))
{
    ##  Log directory exists.  Open existing files for edit
    print "Opening existing qalogs directory for edit\n";
    my @files = `find $dstLogDir -type f`;
    if ($checkin) {foreach $f (@files) {my @o = `p4 edit $f`}}
}
else {
    system "mkdir -p $dstLogDir";
    if (!(-e $dstLogDir)) {
	print "Error:  $dstLogDir not created\n";
	exit;
    }
}

my $sumFile;
if ($checkin) {
    $sumFile = "$dstLogDir/$releaseName.hiprelynx_sum";
    genSummary($srcLogDir, $sumFile);
    system "cp $sumFile /tmp";
    print "Copying hiprelynx log files\n";
    CopyLogs($srcLogDir, $dstLogDir);  ## Copies selected files.

    ##  Zip up the qalogs.
    system "cd $dstLogDir; tar -cf /tmp/qalogs.tar *; cd -";
    system "rm -rf $dstLogDir/*";
    system "gzip /tmp/qalogs.tar";
    system "mv /tmp/qalogs.tar.gz $dstLogDir";
    system "cp /tmp/$releaseName.hiprelynx_sum $sumFile";

}


if ($checkin) {
    print "P4 adding any new files\n";
    my @files = `find $dropoffDir -type f`;
    foreach $f (@files) 
    {
	if (-l $f) {print "$f is a link, skipping\n"} else {my @o = `p4 add $f`}
    }
}
## Make sure all files are open for edit
if ($checkin) {
    print "Making sure all files are open for edit\n";
    my @o = `p4 edit $dropoffDir/...`;
}

my @crrFiles = `p4 opened $dropoffDir/...`;
if ($crr) {
    $crrFileName = "$dropoffDir/macro/doc/ckt_release.txt";
    open CRR,">$crrFileName";
    print CRR "##############################################################################\n";
    print CRR "#                                                                            #\n";
    print CRR "# Copyright (c) 2016 Synopsys Inc. All rights reserved.                      #\n";
    print CRR "#                                                                            #\n";
    print CRR "# Synopsys Proprietary and Confidential. This file contains confidential     #\n";
    print CRR "# information and the trade secrets of Synopsys Inc. Use, disclosure, or     #\n";
    print CRR "# reproduction is prohibited without the prior express written permission    #\n";
    print CRR "# of Synopsys, Inc.                                                          #\n";
    print CRR "#                                                                            #\n";
    print CRR "# Synopsys, Inc.                                                             #\n";
    print CRR "# 690 East Middlefield Road                                                  #\n";
    print CRR "# Mountain View, California 94043                                            #\n";
    print CRR "# (800) 541-7737                                                             #\n";
    print CRR "#                                                                            #\n";
    print CRR "##############################################################################\n";
    print CRR "#################################################\n";
    print CRR "# P4 Versions of Deliverables\n";
    print CRR "#################################################\n";
}

foreach my $crrFile (@crrFiles) {
    my @t = split(/\s+/, $crrFile);
    my $crrDepotFile = $t[0];
    if ($crrDepotFile =~ /^(.*\/\.nfs.*)#\d+$/) {
	system "p4 revert $1";
	print "Info: Ignoring $crrDepotFile\n";
	next;
    }
    if ($crr) {print CRR "p4 sync -f $crrDepotFile\n"}
}

if ($crr) {
    print CRR "#################################################\n";
    close CRR;
    #	print "p4 add $crrFileName\n";
    system "p4 add $crrFileName";
    #	print "done\n";
}

my $sumFileDepot;
my $lastline;
my @o2;
if ($checkin) {
    print "Submitting ... ";
    $sumFileDepot = `p4 opened $sumFile`;
    my @t = split(/\s+/, $sumFileDepot);
    $sumFileDepot = $t[0];
    
    @o2 =  `p4 submit -f revertunchanged -d \"$comment\" $dropoffDir/...`;
    $lastLine = pop(@o2);
}

my $changelist;
if (($lastLine =~ /Change\s+(\d+)\s+submitted/)) {$changelist = $1}
if (($lastLine =~ /Submitting\s+change\s+(\d+)/)) {$changelist = $1}

if ((defined $changelist) || !$checkin) { 
    print "$lastLine\n";

    if (defined $mailRecipients) {
	##  Submit apparently succeeded.
	my $changelist = $1 ;
	my $mailFile = "$TMP/mail.tmp";
	open(MAIL, ">$mailFile") || die "Error: Cannot open $mailFile for write\n";
	print MAIL "Release announcement for \"$base_names\"\n";
	print MAIL "\nRelease name: \"$releaseName\"\n";
	print MAIL "\nProject name: \"$project_name\"\n";
	print MAIL "\nrtlBranch: \"$rtlBranch\"\n";
	print MAIL "\nRelease comment: \"$comment\"\n";
	print MAIL "\nChangelist:  $changelist\n";
	print MAIL "\nQA Summary: $sumFileDepot\n";
	print MAIL "\nP4 files:\n";
	my @haves = `p4 have $dropoffDir/...`;
	foreach (@haves) {if ($_ =~ /(\/\/\S+)/) {print MAIL "$1\n"}}  ## Strip out just the depot file listing.
	print MAIL "\nHiprelynx Variables:\n";
	foreach my $svar (sort keys(%blockSvars)) {print MAIL "$svar = \"$blockSvars{$svar}\"\n"}
	close MAIL;
	my $mailCmd = "mail -s \"Release announcement for $base_names, $comment\" $mailRecipients < $mailFile";
	print "$mailCmd\n";
	system $mailCmd;
	unlink $mailFile;
    } else {
	print "Info:  mailRecipients undefined; skipping mail\n";
    }
}
else {
    print "ERROR:  Something has gone awry with the submit:\n";
    print "@o2";
}

sub CopyLogs
{
    my $src = shift;
    my $dst = shift;

#    print "CopyLogs start:  $src --> $dst\n";
    if (!(-e $dst)) {mkdir $dst}
    my $f;
    my $patt;
    foreach $f (glob("$src/*"))
    {
	my @toks = split(/\//, $f);
	my $root = pop(@toks);
	if (-d $f) {CopyLogs($f,"$dst/$root")}
	else 
	{
	    foreach $patt (@logPatterns) 
	    {
#		print "\tpatt=$patt\n";
		if ($f =~ /$patt/) 
		{
#		    print "Matched $f\n";
#		    print "Copy $f $dst/$root\n";
		    copy("$f", "$dst/$root");
		}
	    }
	}
    }
}


sub ShowUsage
{
    pod2usage(1);
}

sub CheckRequiredArg
{
    my $argName = shift;
    my $argValue = shift;

    if (defined $argValue) {return 1}
    print "Required argument \"$argName\" not provided\n";
    return 0;
}

sub CheckRequiredSvar
{
    my $argName = shift;
    my $argValue = shift;

    if (defined $argValue) {return 1}
    print "Required SVAR \"$argName\" not found in block.tcl\n";
    return 0;
}

sub resolveLink
{
    ##  Resolve link, returning actual 
    my $x = shift;

    if (-l $x)
    {

	my $y = readlink($x);
	if (substr($y,0,1) eq "/") {return $y}   ##  Link to absolute location
	else
	{
	    $x =~ s/\w+$//;  ## Strip off file name to get path.
	    return "$x$y";
	}
    }
    else {return $x}  ## not a link
}

#sub genSummary
#{
#    my $logDir = shift;
#    my $sumfile = shift;
#
#    open(SUM, ">$sumfile") || die "Error:  Cannot open $sumfile for write\n";
#
#    print SUM "Hiprelynx summary for release $releaseName\n";
#    print SUM "----------------------------------------------------------------------------------------------------------------------------------\n";
#    my @passes = glob("$logDir/*/*.pass");
#    my @fails = glob("$logDir/*/*.fail");
#
#    my %Steps;
#    genSummaryStep(\@passes, "pass", \%Steps);
#    genSummaryStep(\@fails, "fail", \%Steps);
#    my @o;
#    foreach my $step (sort keys(%Steps)) { my $line = printf SUM "%-100s:   $Steps{$step}\n", $step; push (@o, $line)}
#}

sub firstFile {
    my $globFile = shift;
    my @t = glob $globFile;
    if (@t) {return $t[0]} else {return undef}
}

sub genSummary
{
    my $logDir = shift;
    my $sumfile = shift;

    print "Creating $sumfile, $logDir\n";
    open(SUM, ">$sumfile") || die "Error:  Cannot open $sumfile for write\n";

    print SUM "Hiprelynx summary for release $releaseName\n";
    print SUM "----------------------------------------------------------------------------------------------------------------------------------\n";

    my @rawSteps = glob("$logDir/*");
    my @steps;
    foreach my $dir (@rawSteps) {
	if (!(-d $dir)) {next}
	my @t = split(/\//, $dir);
	my $step = pop @t;
	if ($step =~ /^sf_/) {next}
#	print "$dir:\n";
	my $passFile;
	my $passFileSize = 0;
	#foreach my $p (glob "$dir/*.pass") {
	foreach my $p (glob "$dir/logs/*.pass") {
	    if ($p =~ /__end.pass$/) {next}
	    $passFile = $p;
	    my @fstat = stat $passFile;
	    $passFileSize = $fstat[7];
	}
	#my $failFile = firstFile("$dir/*.fail");
	#my $logFile = firstFile("$dir/*.log");
	#my $logSumFile = firstFile("$dir/*.logsum");
	#my $genFile = firstFile("$dir/*.gen");
	my $failFile = firstFile("$dir/logs/*.fail");
	my $logFile = firstFile("$dir/logs/*.log");
	my $logSumFile = firstFile("$dir/logs/*.logsum");
	my $genFile = firstFile("$dir/logs/*.gen");
	my $passFileExist = (-e $passFile);
	my $failFileExist = (-e $failFile);
	my $genFileExist = (-e $genFile);
	my $logFileExist = (-e $logFile);
	my $autoWaive = 0;
	if ($passFileExist) {
	    $autoWaive = `grep 'RTM-204: SNPS_ERROR  : (Waived)' $passFile | wc -l`;
	}
	my $status;
	if ($passFileExist && ($passFileSize == 0) && $failFileExist && !$genFileExist && $logFileExist) {$status = "Waived"}
	elsif ($passFileExist && !$failFileExist && !$genFileExist && $logFileExist) {$status = "Pass"}
	elsif (!$passFileExist && $failFileExist && !$genFileExist && $logFileExist) {$status = "Fail"}
	elsif ($passFileExist && !$failFileExist && !$genFileExist && !$logFileExist) {$status = "Touched"}
	elsif ($passFileExist && !$failFileExist && !$genFileExist && $logFileExist && $autoWaive) {$status = "Auto-Waived"}
	else {next}
	printf SUM "%-100s:  $status\n", $step;
    }
    
    close SUM;
}


sub genSummaryStep
{
    my $files = shift;
    my $type = shift;
    my $Steps = shift;

    foreach $f (@$files)
    {
	my @toks = split(/\//, $f);
	my $root = pop(@toks);
	$root =~ s/\.$type$//;
	if ($root =~ /_gen$/) {next}
	my $old = $Steps->{$root};
	if (!(defined $old)) {$Steps->{$root} = $type}
	elsif (($old eq "pass") && ($type eq "fail")) {$Steps->{$root} = "waived"}
	elsif (($old eq "fail") && ($type eq "pass")) {$Steps->{$root} = "waived"}
    }
}

__END__
=head1 SYNOPSIS

    ScriptPath/alphaFinishRelease.pl \
    -releaseName <Release-Name> \
    -description "Comment to be included with checkin"] \
    [-tech <technology>] \
    [-version <hiprelynx version>] \
    [-[no]checkin] \
    [-rtlBranch <branch name>\ \
    [-mailRecipients "comma-separated-list"] \
    [-[no]crr]

This script is used to finish a hiprelynx release.  It copies a selected set of log and pass/fail files to the dropoff area, generates a step summary, checks the lot into perforce,
and emails an announcement.


Arguments:

=item B<-releaseName> - The hiprelynx release name. Required.

=item B<-description> - The description used for the checkin and email.  Required.

=item B<-tech> - The technology. Must match exactly the tech used by hiprelynx."

=item B<-[no]checkin - Controls whether the IP is checked into p4.  Default = 1

=item B<-rtlBranch> - The rtl branch associated  with the release.  Just used as a comment in the release mail

=item B<-mailRecipients> - comma-separated list of mail recipients for the release mail.  Mail is skipped if this is undefined

=item B<-version> - The hiprelynx version in use.  Default "dev".

=item B<-crr> - Create a crr file in the doc/ directory.  Defaults to -nocrr

=over 2

Written by John Clouser, john.clouser@synopsys.com.  Comments and suggestions are welcome.

=cut

