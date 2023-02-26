#!/depot/perl-5.14.2/bin/perl

###############################################################################
#
# Name    : alphaFinishRelease.pl
# Author  : John Clouser
# Date    : N/A
# Purpose : submit qalogs for final release of HL simulation files
#
# Modification History
#     000 John Clouser N/A 
#         Created this script
#     001 Haashim Shahzada June 7th, 2022
#         Bringing up to DDR CKT DA WG standards
#     
###############################################################################
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use File::Copy;
use Data::Dumper;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd;
use Carp    qw( cluck confess croak );
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::P4;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE; 
our $VERBOSITY    = NONE;
our $TESTMODE     = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version();
our $TEMPDIR      = "/tmp";

#--------------------------------------------------------------------#

##------------------------------------------------------------------
##  Gather run statistics for the script
##     First argument is name of the script.
##     Second argument is the script version. (ie. 2022ww10)
##     Third argument (optional) is an aref, used
##          to capture the cmd line arguments and log them.
##------------------------------------------------------------------


BEGIN {
    our $AUTHOR='clouser, haashim';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
Main();
END {
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer();
   write_stdout_log( $LOGFILENAME );
}

our @g_logPatterns ;
our $g_releaseName;

sub Main {
    ShowUsage(1) unless(@ARGV);

    #Variables 
    my ( $tech, $comment, $macros, $help, $nousage, $vdebug, $mailRecipients, $p4ws );
    my $opt_version = 'dev';
    my $checkin   = 1;
    my $rtlBranch = "Unspecified";
    my $crr       = 0;

    my @orig_argv = @ARGV;     # keep this here cause GetOpts modifies ARGV

    my $success = GetOptions(
        "releaseName=s"     => \$g_releaseName,
        "tech=s"            => \$tech,
        "version=s"         => $opt_version,
        "description=s"     => \$comment,
        "checkin!"          => \$checkin,
        "crr!"              => \$crr,
        "rtlBranch=s"       => \$rtlBranch,
        "verbosity=i"       => \$VERBOSITY,
        "nousage"           => \$nousage,
        "debug=i"           => \$DEBUG,
        "test"              => \$TESTMODE,
        "p4ws=s"            => \$p4ws,
        "mailRecipients=s"  => \$mailRecipients,
        "help"              => \$help,
        "h"                 => \$help
        );

    $opt_version = "dev" unless( defined $opt_version );
    if ($help) {ShowUsage(0)} #documentation -h

    unless( $nousage || $main::DEBUG ){ utils__script_usage_statistics($PROGRAM_NAME, $VERSION, \@orig_argv);  }
    @g_logPatterns = ("\\.log","\\.pass\$","\\.results\$","\\.xml\$");

    my $isargOK = 1;
    $isargOK &= CheckRequiredArg("releaseName", $g_releaseName);
    $isargOK &= CheckRequiredArg("comment", $comment);

    if (!$isargOK) {
        fatal_error("Exiting on missing required argument(s)\n");
    }

    my $USERNAME  = get_username();
    my $scratch = $ENV{udescratch};
    my $lynxHome;
    #my $lynxHome = "$scratch/$USERNAME/p4_lynx/lynx_workspace";
    
    if (defined $p4ws){
        $lynxHome = "/u/$USERNAME/$p4ws/lynx_workspace";
    }else{
        $lynxHome = "/u/$USERNAME/p4_ws/lynx_workspace";
        if ( ! -e $lynxHome ) {
            $lynxHome = "/u/$USERNAME/lynx_workspace"; # fallback area
        }
    }
 
    if ( ! -e $lynxHome ){
        # This directory has to exist for this all to work.
        fatal_error( "$lynxHome is missing!\n");
    }
    dprint(LOW, "\$lynxHome is set to $lynxHome\n");

    #/remote/proj/lynx_ip_release/USERNAME/$USERNAME/lynx_workspace";
    my $blockPath = ($opt_version eq "dev") ? "blocks" : "releases/$opt_version/blocks";
    my $blockFile = "$lynxHome/$blockPath/$tech/$g_releaseName/scripts_block/conf/block.tcl";
    #my $blockFile = "$lynxHome/$blockPath/$tech/$g_releaseName/scripts_build/conf/block.tcl";

    if (!(-e $blockFile)){fatal_error("Cannot find file $blockFile\n")}

    my $TMP = (defined $ENV{TMP}) ? $ENV{TMP} : ".";

    ##  Look up stuff in the block.tcl by sourcing into tclsh and printing the value for each SVAR
    my $tclscript = "$TMP/temp.tcl";
    my @tcl_lines;
    push(@tcl_lines, "source $blockFile\n");
    push(@tcl_lines, "foreach varName [array names SVAR] {puts \"\$varName=\$SVAR(\$varName)\"}\n");
    push(@tcl_lines, "exit\n");
    write_file( \@tcl_lines, $tclscript );

    #my @output = `tclsh $tclscript`;
    my ($output, $errout) = run_system_cmd("tclsh $tclscript", $VERBOSITY);
    my @output;
    push(@output, split(/\n/, $output));

    unlink $tclscript;
    my %blockSvars;
    foreach (@output) {if ($_ =~ /(\S+)\s*=\s*(\S+)/) {$blockSvars{$1}=$2}}
    
    dprint_dumper(LOW, "blockSvars:", \@output);

    my $dropoffDir   = $blockSvars{"dropoff_dir"};
    my $base_names   = $blockSvars{"base_names"};
    my $project_name = $blockSvars{"project_name"};

    $isargOK = 1;
    $isargOK &= CheckRequiredSvar("dropoff_dir", $dropoffDir);
    $isargOK &= CheckRequiredSvar("base_names" , $base_names);

    if(!$isargOK) {fatal_error("Exiting on missing required SVAR HERE\n");}
    
    dprint(LOW, "$dropoffDir\n $base_names\n");

    $dropoffDir = resolveLink($dropoffDir);
    if (!(defined $dropoffDir)) {fatal_error("Cannot find dropoff_dir in $blockFile\n")}

    chdir $dropoffDir;
    my @ipTypes = glob("*");

    #my $dropoffQADir = $dropoffDir."_qadata";
    #print "dropoff_dir = $dropoffDir, $dropoffQADir\n";
    my $dstLogDir = $dropoffDir."/macro/doc/qalogs";
    #my $srcLogDir = "$lynxHome/$blockPath/$tech/$g_releaseName/qa_step/logs";
    #my $srcLogDir = "$lynxHome/$blockPath/$tech/$g_releaseName/qa_step/";
    my $srcLogDir = "$lynxHome/builds/$g_releaseName/qa_step/";

    ##  A summary is proving maddeningly difficult to generate.

    if (!(-e $srcLogDir)) {fatal_error("$srcLogDir does not exist\n");}

    if (!(-e $dstLogDir)) {run_system_cmd("p4 sync -q $dstLogDir/...", $VERBOSITY);}

    if ( (-e $dstLogDir)){
        ##  Log directory exists.  Open existing files for edit
        iprint ("Opening existing qalogs directory for edit\n");
        my ($files, $errout) = run_system_cmd("find $dstLogDir -type f", $VERBOSITY);
        my @files = split(/\n/, $files);
        if ($checkin) {
            foreach my $f (@files){
                my ($output, $errout) = run_system_cmd("p4 edit $f", $VERBOSITY);
                my @output = split(/\n/, $output);
                dprint_dumper(LOW, "p4 edit $f: ", \@output);
            }
        }
    } else {
        run_system_cmd("mkdir -p $dstLogDir", $VERBOSITY);
        if (!(-e $dstLogDir)) {
            fatal_error ("$dstLogDir not created\n");
        }
    }

    my $sumFile;
    if ($checkin) {
        my $fname_sum = "${g_releaseName}.hiprelynx_sum";
        $sumFile = "$dstLogDir/$fname_sum";
        genSummary($srcLogDir, $sumFile);
        my ($stdout, $runstatus) = run_system_cmd("cp $sumFile ${TEMPDIR}", $VERBOSITY);
        if ( ! -e "${TEMPDIR}/${fname_sum}" ) {
            # shouldn't happen...  but if it does then we should consider this
            # a fatal error.
            fatal_error("alphaFinishReleaseGen.pl failed to copy $sumFile to ${TEMPDIR} !.\n\tStdOut='$stdout'\n");
        }

        iprint ("Copying hiprelynx log files\n");
        CopyLogs($srcLogDir, $dstLogDir);  ## Copies selected files.

        ##  Zip up the qalogs.
        ($stdout, $runstatus) = run_system_cmd("cd $dstLogDir; tar -cf ${TEMPDIR}/qalogs.tar *; cd -", $VERBOSITY);
        if ( ! -e "${TEMPDIR}/qalogs.tar" ) {
            # shouldn't happen...  but if it does then we should consider this
            # a fatal error.
            fatal_error("alphaFinishReleaseGen.pl failed to tar ${TEMPDIR}/qalogs.tar!\n\tStdOut='$stdout'\n");
        }

        run_system_cmd("rm -rf $dstLogDir/*", $VERBOSITY);
        run_system_cmd("gzip ${TEMPDIR}/qalogs.tar", $VERBOSITY);
        run_system_cmd("mv ${TEMPDIR}/qalogs.tar.gz $dstLogDir", $VERBOSITY);
        run_system_cmd("cp ${TEMPDIR}/${fname_sum} $sumFile", $VERBOSITY);
        chmod 0775, $sumFile or die "Couldn't chmod $sumFile";
        chmod 0775, "$dstLogDir/qalogs.tar.gz";
        # Remove the temporary file that was in the /tmp/ area
        unlink( "${TEMPDIR}/${fname_sum}" ) if ( -e "${TEMPDIR}/${fname_sum}" );
    }

    if ($checkin){
        iprint ("P4 adding any new files\n");
        my ($files, $errout) = run_system_cmd("find $dstLogDir -type f", $VERBOSITY);
        my @files = split(/\n/, $files);
        dprint_dumper(LOW,"results of find $dstLogDir: ", \@files);
        foreach my $f (@files) {
            if (-l $f) { 
                wprint ("$f is a link, skipping\n")
            } else {
                my @qaFiles = da_p4_files("$dropoffDir/macro/doc/...");
                dprint_dumper(HIGH, "p4 files from $dropoffDir/macro/doc/ are:", \@qaFiles);
                if (scalar @qaFiles >= 2){
                    my ($output, $errout) = run_system_cmd("p4 edit $f", $VERBOSITY);
                    dprint_dumper(HIGH, "p4 edit $f:", \$output);
                    hprint ("Adding file $f \n");
                    if ($errout != 0){
                        eprint("Failure with 'p4 edit '$f'' command!\n");
                        eprint("run_system_cmd returned '$output'\n");
                    }
                } else {
                    my ($output, $errout) = run_system_cmd("p4 add $f", $VERBOSITY);
                    dprint_dumper(HIGH, "p4 add $f:", \$output);
                    hprint ("Adding file $f \n");
                    if ($errout != 0){
                        eprint("Failure with 'p4 add '$f'' command!\n");
                        eprint("run_system_cmd returned '$output'\n");
                    }
                }  
            } 
        }
    }

    ## Make sure all files are open for edit
    if ($checkin) {
        iprint ("Making sure all files are open for edit\n");
        my ($output, $exit_status) = run_system_cmd("p4 edit $dstLogDir/...", $VERBOSITY);
        dprint_dumper(HIGH, "p4 edit $dstLogDir: ", \$output);
    }
    
    my ($crrFiles, $exit_status) = run_system_cmd("p4 opened $dropoffDir/...", $VERBOSITY);
    dprint_dumper(HIGH, "p4 opened $dropoffDir:", \$crrFiles);
    my @crrFiles = split(/\n/, $crrFiles);
    my $crrFileName = "";

    my @p4_cmds;
    foreach my $crrFile (@crrFiles) {
        my @t = split(/\s+/, $crrFile);
        my $crrDepotFile = $t[0];
        if ($crrDepotFile && $crrDepotFile =~ /^(.*\/\.nfs.*)#\d+$/) {
            my ($output, $exit_status) = run_system_cmd("p4 revert $1", $VERBOSITY);
            wprint ("Ignoring $crrDepotFile\n");
            if ($exit_status != 0){
                eprint("p4 revert $1 has failed\n");
                eprint("run_system_cmd returned $output\n");
                next;
            }
            if( $crr ){
                push(@p4_cmds, "p4 sync -f $crrDepotFile\n" );
            }
        }
    }

    my @crr_lines;
    if( $crr ){
        $crrFileName = "$dropoffDir/macro/doc/ckt_release.txt";
        push(@crr_lines, "##############################################################################\n" );
        push(@crr_lines, "#                                                                            #\n" );
        push(@crr_lines, "# Copyright (c) 2016 Synopsys Inc. All rights reserved.                      #\n" );
        push(@crr_lines, "#                                                                            #\n" );
        push(@crr_lines, "# Synopsys Proprietary and Confidential. This file contains confidential     #\n" );
        push(@crr_lines, "# information and the trade secrets of Synopsys Inc. Use, disclosure, or     #\n" );
        push(@crr_lines, "# reproduction is prohibited without the prior express written permission    #\n" );
        push(@crr_lines, "# of Synopsys, Inc.                                                          #\n" );
        push(@crr_lines, "#                                                                            #\n" );
        push(@crr_lines, "# Synopsys, Inc.                                                             #\n" );
        push(@crr_lines, "# 690 East Middlefield Road                                                  #\n" );
        push(@crr_lines, "# Mountain View, California 94043                                            #\n" );
        push(@crr_lines, "# (800) 541-7737                                                             #\n" );
        push(@crr_lines, "#                                                                            #\n" );
        push(@crr_lines, "##############################################################################\n" );
        push(@crr_lines, "#################################################\n" );
        push(@crr_lines, "# P4 Versions of Deliverables\n" );
        push(@crr_lines, "#################################################\n" );
        push(@crr_lines, @p4_cmds);
        push(@crr_lines, "#################################################\n" );
        write_file( \@crr_lines, $crrFileName );
        #	print "p4 add $crrFileName\n";
        run_system_cmd("p4 add $crrFileName", $VERBOSITY);
        #	print "done\n";
    }

    my $sumFileDepot;
    my $lastLine;
    my $o2str;
    my @o2;
    if ($checkin) {
        p4print ("Submitting ... \n");
        ($sumFileDepot, my $errout) = run_system_cmd("p4 opened $sumFile", $VERBOSITY);
        my @t = split(/\s+/, $sumFileDepot);
        dprint_dumper(LOW,"p4 opened $sumFile:", \@t);
        $sumFileDepot = $t[0];
        # p4print("Please submit files in changelist to P4 manually, auto-submit coming soon.\n");
        if ($TESTMODE != 0) {
            $lastLine = "Change 000000 submitted";
        } else {
            my ($o2str, $exit_status) = run_system_cmd("p4 submit -f revertunchanged -d \"$comment\" $dropoffDir/...", $VERBOSITY);
            if ($exit_status != 0){
                eprint("There was an issue with the p4 submit\n");
                eprint("run_system_cmd returned $o2str\n");
            } #print @o2;
            dprint_dumper(LOW, "p4 submit -f revertunchanged...: ", \@o2);
            $lastLine = $o2str;
            #print $lastLine;
        }
    }
    
    my $changelist;
    if (($lastLine =~ /Change\s+(\d+)\s+submitted/))  {$changelist = $1;}
    if (($lastLine =~ /Submitting\s+change\s+(\d+)/)) {$changelist = $1;}

    if ((defined $changelist) || !$checkin || $TESTMODE) { 
        print "$lastLine\n";
        if (defined $mailRecipients) {
        ##  Submit apparently succeeded.
            my $changelist = $1;
            my $mailFile = "$TMP/mail.tmp";
            #---------------------
              my @mail_lines;
              push(@mail_lines, "Release announcement for \"$base_names\"\n" );
              push(@mail_lines, "\nRelease name: \"$g_releaseName\"\n" );
              push(@mail_lines, "\nProject name: \"$project_name\"\n" );
              push(@mail_lines, "\nrtlBranch: \"$rtlBranch\"\n" );
              push(@mail_lines, "\nRelease comment: \"$comment\"\n" );
              push(@mail_lines, "\nChangelist:  $changelist\n" );
              push(@mail_lines, "\nQA Summary: $sumFileDepot\n" );
              push(@mail_lines, "\nP4 files:\n" );
              my ($haves, $err) = run_system_cmd("p4 have $dropoffDir/...", $VERBOSITY);
              my @haves = split(/\s+/, $haves);
              foreach (@haves) {
                  if ($_ =~ /(\/\/\S+)/) {
                       push(@mail_lines, "$1\n" );
                  }
              }  ## Strip out just the depot file listing.
               push(@mail_lines, "\nHiprelynx Variables:\n" );
              foreach my $svar (sort keys(%blockSvars)) {
                   push(@mail_lines, "$svar = \"$blockSvars{$svar}\"\n" );
              }
              write_file( \@mail_lines, $mailFile );
            #---------------------
            my $mailCmd = "mail -s \"Release announcement for $base_names, $comment\" $mailRecipients < $mailFile";
            print "$mailCmd\n";
            run_system_cmd($mailCmd, $VERBOSITY);
            unlink $mailFile;
        } else {
            print "Info:  mailRecipients undefined; skipping mail\n";
        }
        exit 0;
    } else {
        dprint_dumper(LOW, "o2 array is: ", \@o2);
        fatal_error("Something has gone awry with the submit");        
    }
}

sub CopyLogs {
    my $src = shift;
    my $dst = shift;
    #print "CopyLogs start:  $src --> $dst\n";
    if (!(-e $dst)) {
        if ( 0 == mkdir($dst)){
            fatal_error("$PROGRAM_NAME:CopyLogs was unable to create directory '$dst'\n");
        }
    }
    foreach my $f (glob("$src/*")){
        my @toks = split(/\//, $f);
        my $root = pop(@toks);
        if (-d $f) {
            CopyLogs($f,"$dst/$root");
        } else {
            foreach my $patt (@g_logPatterns){
                #print "\tpatt=$patt\n";
                if ($f =~ /$patt/){
                    #print "Matched $f\n";
                    #print "Copy $f $dst/$root\n";
                    copy("$f", "$dst/$root");
                }
            }
        }
    }
}

sub ShowUsage($) {
    my $status = shift;

    #reads pod documentation and prints messages
    pod2usage({
            -pathlist => "$RealBin",
            -exitval => $status,
            -verbose => 1 });
}

sub CheckRequiredArg
{
    my $argName = shift;
    my $argValue = shift;

    if (defined $argValue) {return 1}
    eprint ("Required argument \"$argName\" not provided\n");
    return 0;
}

sub CheckRequiredSvar
{
    my $argName = shift;
    my $argValue = shift;

    if (defined $argValue) {return 1}
    eprint ("Required SVAR \"$argName\" not found in block.tcl\n");
    return 0;
}

sub resolveLink
{
    ##  Resolve link, returning actual 
    my $x = shift;
    if (-l $x){
        my $y = readlink($x);
        if (substr($y,0,1) eq "/") {
            return $y ##  Link to absolute location
        } else {
            $x =~ s/\w+$//;  ## Strip off file name to get path.
            return "$x$y";
        }
    } else {return $x;}  ## not a link
}

#sub genSummary
#{
#    my $logDir = shift;
#    my $sumfile = shift;
#
#    open(SUM, ">$sumfile") || die "Error:  Cannot open $sumfile for write\n";
#
#    print SUM "Hiprelynx summary for release $g_releaseName\n";
#    print SUM "----------------------------------------------------------------------------------------------------------------------------------\n";
#    my @passes = glob("$logDir/*/*.pass");
#    my @fails = glob("$logDir/*/*.fail");
#
#    my %Steps;
#    genSummaryStep(\@passes, "pass", \%Steps);
#    genSummaryStep(\@fails, "fail", \%Steps);
#    my @output;
#    foreach my $step (sort keys(%Steps)) { my $line = printf SUM "%-100s:   $Steps{$step}\n", $step; push (@output, $line)}
#}

sub firstFile {
    my $globFile = shift;
    my @t = glob $globFile;
    if (@t) {
        return $t[0];
    } else {
        return; # P10020416-36366 no need to return undef;
    }
}

sub genSummary
{
    my $logDir = shift;
    my $sumfile = shift;

    hprint( "Creating $sumfile, $logDir\n" );

    my @sum_lines;
    push(@sum_lines, "Hiprelynx summary for release $g_releaseName\n" );
    push(@sum_lines, '-' x130 . "\n" );

    my @rawSteps = glob("$logDir/*");
    my @steps;
    foreach my $dir ( @rawSteps ){
	    if (!(-d $dir)) {next;}
	    my @t = split(/\//, $dir);
	    my $step = pop @t;
	    if ($step =~ /^sf_/) {next;}
        #print "$dir:\n";
	    my $passFile;
	    my $passFileSize = 0;
	    foreach my $p (glob "$dir/logs/*.pass") {
	        if ($p =~ /__end.pass$/) {next}
	        $passFile = $p;
	        my @fstat = stat $passFile;
	        $passFileSize = $fstat[7];
	    }
	    #my $failFile       = firstFile("$dir/*.fail");
    	#my $logFile        = firstFile("$dir/*.log");
    	#my $logSumFile     = firstFile("$dir/*.logsum");
    	#my $genFile        = firstFile("$dir/*.gen");
    	my $failFile        = firstFile("$dir/logs/*.fail");
    	my $logFile         = firstFile("$dir/logs/*.log");
    	my $logSumFile      = firstFile("$dir/logs/*.logsum");
    	my $genFile         = firstFile("$dir/logs/*.gen");
    	my $passFileExist   = ($passFile && -e $passFile);
    	my $failFileExist   = ($failFile && -e $failFile);
    	my $genFileExist    = ($genFile  && -e $genFile);
    	my $logFileExist    = ($logFile  && -e $logFile);
    	my $autoWaive       = 0;

    	if ($passFileExist) {
            my ($output, $err) = run_system_cmd("grep 'RTM-204: SNPS_ERROR  : (Waived)' $passFile | wc -l", $VERBOSITY);
            $autoWaive = split(/\n/, $output);
        }
    	my $status;
    	if ($passFileExist && ($passFileSize == 0) && $failFileExist && !$genFileExist && $logFileExist) {
            $status = "Waived";
        } elsif ($passFileExist && !$failFileExist && !$genFileExist && $logFileExist) {
            $status = "Pass";
        } elsif (!$passFileExist && $failFileExist && !$genFileExist && $logFileExist) {
            $status = "Fail";
        } elsif ($passFileExist && !$failFileExist && !$genFileExist && !$logFileExist) {
            $status = "Touched";
        } elsif ($passFileExist && !$failFileExist && !$genFileExist && $logFileExist && $autoWaive) {
            $status = "Auto-Waived";
        } else {
            next;
        }
        push(@sum_lines, sprintf("%-100s:  $status\n", $step) );
    }
    write_file( \@sum_lines, $sumfile );
}

sub genSummaryStep
{
    my $files = shift;
    my $type = shift;
    my $Steps = shift;

    foreach my $f (@$files){
        my @toks = split(/\//, $f);
        my $root = pop(@toks);
        $root =~ s/\.$type$//;

        if ($root =~ /_gen$/) {next;}

        my $old = $Steps->{$root};

        if (!(defined $old)) {
            $Steps->{$root} = $type;
        }
        elsif (($old eq "pass") && ($type eq "fail")) {
            $Steps->{$root} = "waived";
        }
        elsif (($old eq "fail") && ($type eq "pass")) {
            $Steps->{$root} = "waived";
        }
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
    [-[no]crr] \
    [-testmode]

Common usage example: alphaFinishReleaseGen.pl -releaseName <macro>_<rel_version> -desc <p4 submit description> -tech <technology>

This script is used to finish a hiprelynx release.  It copies a selected set of log and pass/fail files to the dropoff area, generates a step summary, checks the lot into perforce,
and emails an announcement.


Arguments:

=item B<-releaseName>

The hiprelynx release name. Required.

=item B<-description>    

The description used for the checkin and email.  Required.

=item B<-tech>           

The technology. Must match exactly the tech used by hiprelynx.

=item B<-[no]checkin     

Controls whether the IP is checked into p4.  Default = 1

=item B<-rtlBranch>

The rtl branch associated  with the release.  Just used as a comment in the release mail

=item B<-mailRecipients>

comma-separated list of mail recipients for the release mail.  Mail is skipped if this is undefined

=item B<-version>

The hiprelynx version in use.  Default "dev".

=item B<-crr>

Create a crr file in the doc/ directory.  Defaults to -nocrr

=item B<-testmode>

When you use -testmode, it will not do a p4 submit 

=over 2

Written by John Clouser, Haashim Shahzada. Send comments and suggestions to ddr-ckt-da-wg@synopsys.com


=cut
