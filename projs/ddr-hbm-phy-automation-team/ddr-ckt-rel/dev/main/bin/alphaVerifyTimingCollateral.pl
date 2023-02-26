#!/depot/perl-5.14.2/bin/perl

#04/05/2022- Dikshant: Added LVF related enhancements in the script. The script now has -lvf switch for lvf runs
#04-09-2022- Dikshant: Removing metalStack existence check due to urgency. Will add solid check again in next release
#05-02-2022- Dikshant: Removed alphaNT_lvf.config from script. Updated checkPlotArcsCsv subroutine to check the presence of data in the array before assignment
#05-12-2022- Dikshant: Added existence check for lvf variable. JIRA: P10020416-34480
#06-01-2022-    James: Add a main() function JIRA: P10020416-34884 to pass perl_lint
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Cwd qw(getcwd abs_path);
use Carp;
use Pod::Usage;
use Date::Parse; 
use Date::Manip;
use Time::Local;
use Capture::Tiny qw/capture/;
use File::Path qw(make_path);
use File::Copy;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use alphaHLDepotRelease;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initialized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version();
#--------------------------------------------------------------------#

##  Constants used for file status.
my $FILE_NONEXIST = 0;   ##  File does not exist
my $FILE_OK       = 1;   ##  File exists and post-dates reference time
my $FILE_STALE    = 2;   ##  File exists, but predates reference time

my @InternalReportFiles = qw(
clock_arrivals.rpt
clock_network.rpt
clock.rpt
clock_tree_nets.rpt
clock_tree_pins.rpt
coverage.rpt
fanout.rpt
max_arrival.rpt
max_arrival_transition_over_50ps.rpt
max_arrival_transition_over_90ps.rpt
maxcap.rpt
max_pbsa.rpt
max_SI_nets.rpt
max_timing.rpt
maxtrans.rpt
min_arrival_transition_over_50ps.rpt
min_arrival_transition_over_90ps.rpt
min_pbsa.rpt
minpulse.rpt
min_timing.rpt
noise.rpt
noise_sources.rpt
parasitics_annotated.rpt
parasitics_not_annotated.rpt
parasitics_summary.rpt
SI_convergence.rpt
si_delay_max.rpt
si_delay_min.rpt
simulation.rpt
topology.rpt
transistor_direction.rpt
variation.rpt
);

my @toks = split(/\//, $0);
pop (@toks);
my $ScriptPath = "";
foreach (@toks) {$ScriptPath .= "$_/"}
$ScriptPath = abs_path($ScriptPath);

our $uiArg;
our @pvtCorners;
our $timingRootP4;
our $TMP;
our $timingDirs = {};
our $globalTimingFiles = {};

BEGIN {
    our $AUTHOR  = 'Ms. Mystery';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}

&Main();

END {
   local $?;   # to prevent the exit() status from getting modified
   footer();
   write_stdout_log( $LOGFILENAME );
}

sub Main(){
    my $sis = "sis";
    my $nt  = "nt";
    my $hasTiming;

    my @orig_argv = @ARGV;   # keep this here cause GetOpts modifies ARGV

    my ($opt_projSPEC, $timingRel, $macrosArg, $internalTimingMacrosArg, $metalStack, 
        $pvtCornersArg, $uiArg, $logFile, $nolog, $p4Description, $p4Logs, $arch, $nocompilecheck, 
        $nonDI, $lvf, $opt_nousage) = &process_cmd_line_args();
    
    unless( $DEBUG || defined($opt_nousage) ){
        viprint(LOW, "Reporting Usage Stats\n");
        utils__script_usage_statistics( $RealScript, $VERSION, \@orig_argv);
    }

    my ($projType, $proj, $pcsRel) =  parse_project_spec( $opt_projSPEC, \&usage );

    if (defined $lvf) {
        $sis = "sis_lvf";
        $nt = "nt_lvf";
    } 

    my $macroLogs      = 1;
    my $loggingDeferred;
    my $logFileName;
    my @deferredLog;
    if ($nolog) {
    ##  Not logging.
        $macroLogs = 0;
    } else {
        if (defined $logFile) {
            ##  Simple, single log file.
            $loggingDeferred = 0;
            $macroLogs = 0;
        } else {
            ##  No single logfile specified.  Default behavior is a separate logfile per macro.
            ##  Initially, logging is deferred, meaning that log messages will be stored, to be dumped upon the opening of
            ##  the macrro-level logfiles.
            $loggingDeferred = 1;
        }
    }

    ## Create a temp area to work with
    my $dateAndTime = str2time(localtime());
    my $username    = get_username(); 
    
    ## This needs to be defined before any call to subroutines that use $TMP (e.g. exitApp)
    $TMP = "/tmp/alphaVerifyTimingCollateral_${username}_$dateAndTime";
    mkdir $TMP;

    my $projPathAbs   = "/remote/cad-rep/projects/$projType/$proj/$pcsRel";
    ##  Quick check to see if the project provided exists:
    ##dikshant:Changed confess to warn for better error handling while testing
    if (!(-d "$projPathAbs")) {
        warn "Error: $projType/$proj/$pcsRel does not exist\n";
        exitApp(1);
    }

    my ( $projMacroFile, $projNtFile, $projRelFile, $projVerifFile ) = get_project_files_path( $projPathAbs, $projType, $proj, $pcsRel );

    my @macroList;
    if (defined $macrosArg) {
    ##  macro list is explicitely defined.
        @macroList = Tokenify($macrosArg);
    }
    
    my $fileOK = 1;
    
    my %ignoreMacro;
    my $legalReleaseVars = {};  # when using processLegalReleaseFile()
    if (-r $projRelFile) {
        ## If the legalRelease file exists, get its variables.
        dprint(LOW, "Reading legalRelease from '$projRelFile'\n");
        processLegalReleaseFile( $projRelFile, $legalReleaseVars); 
        if (defined $legalReleaseVars->{'releaseIgnoreMacro'}) {
            my $aref_releaseIgnoreMacro = $legalReleaseVars->{'releaseIgnoreMacro'};
            foreach my $m (@$aref_releaseIgnoreMacro) {$ignoreMacro{$m}=1}
        }
    } else {wprint("$projRelFile does not exist\n")}
    
    ##  Handle options that force script to look for internal timing collateral
    my @internalTimingMacroList;
    my %hasInternalTiming;
    if (defined $legalReleaseVars->{'internalTimingMacroList'}){
        @internalTimingMacroList = Tokenify($legalReleaseVars->{'internalTimingMacroList'});
    }
    if (defined $internalTimingMacrosArg) {
    ##  macro list is explicitely defined.
        @internalTimingMacroList = Tokenify($internalTimingMacrosArg);
    }
    foreach my $mn (@internalTimingMacroList) {$hasInternalTiming{$mn} = 1}
    
    if (defined $pvtCornersArg)  {
    ##  pvt corners defined on command line
        @pvtCorners = Tokenify($pvtCornersArg);
        iprint("Getting pvtCorners from command-line arg\n");
    }
    elsif (defined $legalReleaseVars->{pvtCorners}) {
    ##  pvtCorners defined in legalRelease
    ## ljames - I talked with Kevin Xie 10/20/2022 and he said there should never
    ##          be a pvtCorners in a legalRelease file. We do see them in the
    ##          project NT file (parsed via readNtFile() in alphaHLDepotRelease.pm
        @pvtCorners = Tokenify($legalReleaseVars->{pvtCorners});
        iprint("Getting pvtCorners from $projRelFile\n");
    } else {
    ## None of the above. Attempt to pick up from ntConfigFile.
        if (CheckRequiredFile($projNtFile)) {
            my ($aref_corners, $href_params) = readNtFile( $projNtFile );
            @pvtCorners = @$aref_corners;
        } else {
            $fileOK = 0;
        }
    }
    
    if (!(defined $metalStack)) {
        $metalStack = $legalReleaseVars->{'metalStack'};
    }
    
    if (@macroList == 0) {
    ## macros not spec'ed.  Need pcs/design/legalMacros.txt
        if (CheckRequiredFile($projRelFile)) {
            my @lines = read_file( $projRelFile );
            foreach my $line ( @lines ){
                $line =~ s/\#.*//g;  ## uncomment line
                my @toks = Tokenify($line);
                foreach my $t (@toks) {
                    ##  Each entry formatted as "libName/cellName"
                    my @toks1 = split(/\//, $t);
                    my $macroName = $toks1[1];
                    if (!$ignoreMacro{$macroName}) {push @macroList, $macroName} else {iprint("Ignoring $macroName\n")}
                }
            }
        } else {
            $fileOK = 0;
        }
    }
    
    if (!$fileOK) {
        eprint("Aborting on missing required file(s)\n" );
        exitApp(1);
    }
    
    if (@macroList == 0) {
        wprint("No macros read from $projRelFile\n");
        exitApp();
    }
    
    if (!(defined $metalStack)) {
        eprint("Metal stack undefined\n");
        exitApp(1);
    }
    
    if (@pvtCorners == 0) {
        wprint("No pvt corners read from $projNtFile\n");
        exitApp();
    }
    
    iprint("macros =\n");
    foreach (@macroList) {nprint("\t$_\n")}
    iprint("metalStack = $metalStack\n");
    iprint("pvtCorners = \n");
    foreach (@pvtCorners) {nprint("\t$_\n")}
    
    $timingRootP4 = "//wwcad/msip/projects/$projType/$proj/$timingRel/design/timing";
    
    #iprint("Getting filelog of $timingRootP4/...\n");
    my @filelog = `p4 filelog -m 1 -t -s $timingRootP4/...`;
    my $n = @filelog;
    if (@filelog == 0) {
        eprint("Filelog is empty.  Check path\n");
        exitApp();
    } 
    
    my $parseData = 0;  ## Flag set to enable parsing of the first line after a file is read.
    my ($file, %TimingType, $dir, $root);
    my $hasNtCollateral = my $hasSisCollateral = my $hasLibgenCollateral = 0;

    foreach my $line (@filelog) {
        if ($line =~ /^$timingRootP4\/(.*)$/ ){
            $file = $1;
            my @toks = split(/\//,$file);
            $root = pop @toks;
            $dir = join("/", @toks);
            if (!$timingDirs->{$dir}) {$timingDirs->{$dir} = []}   ##  timingDirs will contain lists of files in a given directory.
            $parseData = 1;
        } elsif ($parseData) {
            $parseData = 0;

            # EXAMPLE:
            # "... #1 change 9568638 add on 2022/02/15 07:06:03 by ayaa@udeAutoPCS_ayaa_us01 (text) 'Updating libs after decreasing '"
            if ($line =~ /^\.\.\.\s+\#(\d+)\s+change\s+(\d+)\s+(\S+) on (\S+) (\S+) by (\S+) \((\S+)\) '(.*)'/) {
                if ($3 ne "delete") {
                    my $rec = {};
                    $rec->{NAME} = $file; # example: 'nt_lvf/dwc_ddrphy_clk_master/final_rel/alphaPlotArcs_GR2021/d809_GR2021/dwc_ddrphy_clk_master_15M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p675v0c_pg.lib'
                    $rec->{ROOT} = $root;
                    $rec->{VERSION} = $1;
                    $rec->{CHANGELIST} = $2;
                    $rec->{ACTION} = $3;
                    $rec->{DATE} = $4;
                    $rec->{TIME} = $5;
                    my $cmpDateTime = str2time("$4:$5");
                    $rec->{CLIENT} = $6;
                    $rec->{CMPDATETIME} = $cmpDateTime;
                    $rec->{TYPE} = $7;
                    $rec->{DESC} = $8;
                    $globalTimingFiles->{"$file"} = $rec;
                    push @{$timingDirs->{"$dir"}}, $rec;
                    ##  Infer timing type
                    $file =~ /(\w+)\/(\w+)\//;
                    my $type = $1;
                    my $macro = $2;
                    if (!$TimingType{$macro}) {$TimingType{$macro} = {}}
                    $TimingType{$macro}->{$type} = 1;
                } # action ne "delete"
            } # if 'change' line RE matched
        } # end else parseData
    } # foreach $line in @filelog

    ##  Reduce TimingType
    foreach my $macro (keys %TimingType) {
        my @k = keys %{$TimingType{$macro}};
        $TimingType{$macro} = "@k";
    }
    
    my @etm;
    my @internal;
    my $macroData = {};   ##  This will hold all information related to timing for each macro.
    foreach my $macroName (@macroList) {
        $logFileName = "alphaVerifyTimingCollateral_${macroName}.log";
        if (!(defined $TimingType{$macroName})) {
            ##  No timing collateral at all was found for macro.
            eprint("No timing collateral found for $macroName\n");
            #close LOG;
            next;
        }
        ###  This check doesn't work unless there are files at the top level of
        #    nt, sis or libgen, which isn't always the case and isn't really
        #    required.
        #    if (!$timingDirs->{"nt/$macroName"} && !$timingDirs->{"sis/$macroName"} && !$timingDirs->{"libgen/$macroName"}) 
        #if (0) {
        #    eprint("No timing collateral found for macro $macroName\n");
        #    next;
        #}
    
        nprint "\n";
        iprint("--------------------------------------- Timing Status for macro $macroName ---------------------------------------\n");
    
            if ( $macroName =~ m/lcdl/ || $macroName =~ m/bdl/ ) { 
            if ( $arch ){
                process_arch($arch, $macroName, \@etm, \@internal);
            } else {
                eprint("No arch found with LCDL/BDL Macro\n");
                iprint("Please specify -arch option to be used. Below are the supported ones\n");
                iprint("-arch PartialNtPHY2.0  \n-arch FullyNtPHY2.0  \n-arch PHY2.0_reverse_wrap  \n-arch DDR54  \n-arch LPDDR54  \n\n ");
                exitApp();
            }

            ##  SiS flags.  Set on presence of any log or lib.
            my $sisMacro_new       = 0;
            my $someSisLibs_new    = 0;## Found at least one SiS lib    
            my $someLibgenLibs_new = 0;##  Found at least one libgen lib
    
            my $allSisLibs_new     = 1;  ##  Found all SiS libs
            my $allLibgenLibs_new  = 1;   ##  Found all libgen libs
    
            ##  Same as the above w/o metalStack
            my $someSisLibsNoms_new = 0;  ## Found at least one SiS lib
            my $someLibgenLibsNoms_new = 0;   ##  Found at least one libgen lib
    
            my $allSisLibsNoms_new     = 1;  ##  Found all SiS libs
            my $allLibgenLibsNoms_new  = 1;   ##  Found all libgen libs
    
            my $someSisPvtLogs_new = 0;  ##  At least one pvt-level SiS log found
            my $allSisPvtLogs_new  = 1;   ##  all pvt-level SiS log found
            my $sisSingleLog_new   = checkFile("$sis/$macroName/siliconsmart.log");
    
            my (@staleSisLogs_new, @okSisLogs_new, @missingSisLogs_new, @okLibgenLibs_new, @okSisLibs_new, @missingLibgenLibs_new, @missingSisLibs_new);
            ## w/o metalStack
            my (@okLibgenLibsNoms_new, @okSisLibsNoms_new, @missingLibgenLibsNoms_new, @missingSisLibsNoms_new, @staleLibs_new, @missingLogs_new);
            $macroData->{$macroName} = {};
            my $hasLibsMs_new        = 0;
            my $hasLibsNoms_new      = 0;
            my $someNtLibs_new       = 0;   ##  Found at least one NT lib
            my $allNtLibs_new        = 1;   ##  Found all NT libs
            my $someNtLibsNoms_new   = 0;   ##  Found at least one NT lib
            my $allNtLibsNoms_new    = 1;   ##  Found all NT libs
            my (@okNtLibs_new, @missingNtLibs_new, @okNtLibsNoms_new, @missingNtLibsNoms_new, @staleLibs_Nt_new, @total_staleLibs_new);
            foreach my $pvt (@pvtCorners) {
                my ($sisLog_new, $sisLib_new, $sisLibPG_new, $libgenLib_new, $libgenLibPG_new, $ntLib_new, $ntLibPG_new);
                
                ## Logs
                #    if ($sisLog =   checkFile("sis/$macroName/run_char_${pvt}.log", \@okSisLogs, \@missingSisLogs, \@staleSisLogs)) {$someSisPvtLogs = 1} else {$allSisPvtLogs = 0}
                if ($sisLog_new =   checkFile("$sis/$macroName/char_${pvt}/siliconsmart.log", \@okSisLogs_new, \@missingSisLogs_new, \@staleSisLogs_new)) {$someSisPvtLogs_new = 1} else {$allSisPvtLogs_new = 0}
                if ($sisLib_new =   checkFile("$sis/$macroName/lib/${macroName}_${metalStack}_${pvt}.lib", \@okSisLibs_new, \@missingSisLibs_new, \@staleLibs_new)) {$someSisLibs_new = 1} else {$allSisLibs_new = 0}
                if ($sisLibPG_new = checkFile("$sis/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}_pg.lib", \@okSisLibs_new, \@missingSisLibs_new, \@staleLibs_new)) {$someSisLibs_new = 1} else {$allSisLibs_new = 0}
    
                ##  Libs with metalstacks
                if ($libgenLib_new =    checkFile("libgen/$macroName/lib/${macroName}_${metalStack}_${pvt}.lib", \@okLibgenLibs_new, \@missingLibgenLibs_new, \@staleLibs_new)) {$someLibgenLibs_new = 1} else {$allLibgenLibs_new = 0}
                if ($libgenLibPG_new =  checkFile("libgen/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}_pg.lib", \@okLibgenLibs_new, \@missingLibgenLibs_new, \@staleLibs_new)) {$someLibgenLibs_new = 1} else {$allLibgenLibs_new = 0}
    
                ##  Libs without metalstacks
                if ($sisLib_new =   checkFile("$sis/$macroName/lib/${macroName}_${pvt}.lib", \@okSisLibsNoms_new, \@missingSisLibsNoms_new, \@staleLibs_new)) {$someSisLibsNoms_new = 1} else {$allSisLibsNoms_new = 0}
                if ($sisLibPG_new = checkFile("$sis/$macroName/lib_pg/${macroName}_${pvt}.lib", \@okSisLibsNoms_new, \@missingSisLibsNoms_new, \@staleLibs_new)) {$someSisLibsNoms_new = 1} else {$allSisLibsNoms_new = 0}
                if ($libgenLib_new =    checkFile("libgen/$macroName/lib/${macroName}_${pvt}.lib", \@okLibgenLibsNoms_new, \@missingLibgenLibsNoms_new, \@staleLibs_new)) {$someLibgenLibsNoms_new = 1} else {$allLibgenLibsNoms_new = 0}
                if ($libgenLibPG_new =  checkFile("libgen/$macroName/lib_pg/${macroName}_${pvt}_pg.lib", \@okLibgenLibsNoms_new, \@missingLibgenLibsNoms_new, \@staleLibs_new)) {$someLibgenLibsNoms_new= 1} else {$allLibgenLibsNoms_new = 0}
    
                $someSisLibs_new = $someSisLibsNoms_new || $someSisLibs_new;
                $someLibgenLibs_new = $someLibgenLibsNoms_new || $someLibgenLibs_new;
     
                ##  Libs with metalstacks
                if ($ntLib_new =    checkFile("$nt/$macroName/lib/${macroName}_${metalStack}_${pvt}.lib", \@okNtLibs_new, \@missingNtLibs_new, \@staleLibs_Nt_new)) {$someNtLibs_new = 1} else {$allNtLibs_new = 0}
                if ($ntLibPG_new =  checkFile("$nt/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}_pg.lib", \@okNtLibs_new, \@missingNtLibs_new, \@staleLibs_Nt_new)) {$someNtLibs_new = 1} else {$allNtLibs_new = 0}
 
                ##  Libs without metalstacks
                if ($ntLib_new =    checkFile("$nt/$macroName/lib/${macroName}_${pvt}.lib", \@okNtLibsNoms_new, \@missingNtLibsNoms_new, \@staleLibs_Nt_new)) {$someNtLibsNoms_new = 1} else {$allNtLibsNoms_new = 0}
                if ($ntLibPG_new =  checkFile("$nt/$macroName/lib_pg/${macroName}_${pvt}_pg.lib", \@okNtLibsNoms_new, \@missingNtLibsNoms_new, \@staleLibs_Nt_new)) {$someNtLibsNoms_new = 1} else {$allNtLibsNoms_new = 0}
    
                $someNtLibs_new = $someNtLibsNoms_new || $someNtLibs_new;
    
                $hasLibsMs_new = ($hasLibsMs_new || $someNtLibs_new || $someSisLibs_new || $someLibgenLibs_new);
                $hasLibsNoms_new = ($hasLibsNoms_new || $someNtLibsNoms_new || $someSisLibsNoms_new || $someLibgenLibsNoms_new);
    
            }
            if ($hasLibsMs_new) {
                iprint("Libs with metalStack were found\n");
            }
            if ($hasLibsNoms_new) {
                iprint("Libs without metalStack were found\n");
            }

            my @singleSisLogList_new;
            if ($sisSingleLog_new) {push @singleSisLogList_new, $sisSingleLog_new};
            my $nSisLog_new = (@singleSisLogList_new+@okSisLogs_new+@staleSisLogs_new);
            if (($nSisLog_new>0)) {
                iprint("Checking timing logs for errors for SiS\n");
                ##  Check log files for errors. Do so for all logs found
                if ($nSisLog_new>0) {
                    if (checkSisLogs(\@singleSisLogList_new, \@okSisLogs_new, \@staleSisLogs_new)) {iprint("Status:  SiS logs CLEAN\n\n")} else {iprint("Status:  SiS logs DIRTY\n\n")}
                }
            }
            my $qualCheckRoot = undef;
            my $busesExist;
            ##my $timingExist;  P10020416-38759 12/7/2022 ljames replacing timingExist with hasTiming; hasTiming 
            ##    is looked at after being set, but nothing was looking for timingExist variable.
            my $hasSetupHold;
            my $timingType_new;
            iprint("Checking libs for existence and creation date\n");
            my $isSisMacro_new = 0;
            my $isNtMacro_new = 0;
            my $isLibgenMacro_new = 0;
            my $libError_new = 0;
#            my $hasTiming = 0;
            if ($someSisLibs_new && !$someNtLibs_new && !$someLibgenLibs_new) {
                ##  Presumed to be an SiS macro
                $isSisMacro_new = 1;
                iprint("Only SiS libs found; All other NT-related checks will be skipped\n");
                if (!$allSisLibs_new) {
                    $libError_new = 1;
                    eprint("Missing libs:\n");
                    foreach my $lib_new (@missingSisLibs_new) {iprint("\t$lib_new\n")}
                }
                # ljames - comment out this code; nothing else uses $qualCheckRoot_new variable
                #$qualCheckRoot_new =  "$sis/$macroName/quality_checks";
                ($busesExist, $hasTiming, $hasSetupHold) = checkBusAndTimingExistence(\@okSisLibs_new);
            }
            elsif (!$someSisLibs_new && $someNtLibs_new && !$someLibgenLibs_new) {
                ##  Presumed to be an NT macro
                iprint("Only NT libs found\n");
                $isNtMacro_new = 1;
                if (!$allNtLibs_new) {
                    $libError_new = 1;
                    eprint("Missing libs:\n");
                    foreach my $lib_new (@missingNtLibs_new) {iprint("\t$lib_new\n")}
                }
                $qualCheckRoot =  "$nt/$macroName/quality_checks";
                ($busesExist, $hasTiming, $hasSetupHold) = checkBusAndTimingExistence(\@okNtLibs_new);
            }
            elsif (!$someSisLibs_new && !$someNtLibs_new && $someLibgenLibs_new) {
                ##  Presumed to be a libgen macro
                iprint("Only libgen libs found\n");
                $isLibgenMacro_new = 1;
                if (!$allLibgenLibs_new) {
                    $libError_new = 1;
                    eprint("Missing libs:\n");
                    foreach my $lib_new (@missingLibgenLibs_new) {iprint("\t$lib_new\n")}
                }
                $qualCheckRoot =  "libgen/$macroName/quality_checks";
                ($busesExist,$hasTiming,$hasSetupHold) = checkBusAndTimingExistence(\@okLibgenLibs_new);
            }
            elsif (!$someSisLibs_new && !$someNtLibs_new && !$someLibgenLibs_new) {
                ## No libs found at all.
                $libError_new = 1;
                eprint("No libs found at all; All other NT-related checks will be skipped\n");
            } else {
                ##  Libs found in more than one
                eprint("Libs found in more than one place $someNtLibs_new,$someSisLibs_new,$someLibgenLibs_new\n");
                $libError_new = 1;
                $isSisMacro_new = 0;
                $isNtMacro_new = 0;
                $isLibgenMacro_new = 0;
            ## BOZO:  Combined list of libs?
            }
    
            ##  Overall check for stale libs
            @total_staleLibs_new = (@staleLibs_new, @staleLibs_Nt_new);
            if (@total_staleLibs_new > 0) {
                $libError_new = 1;
                eprint("Stale libs found for Nt etm or Sis or Libge\n");
                dumpListFilerec(\@total_staleLibs_new, "\t\t");
            }
    
            my $libTag_new = ($libError_new) ? "DIRTY" : "CLEAN";
            iprint("Status:  Lib existence and creation time check  $libTag_new\n\n");

    #-------------------Etm Chceks -----------------------------------------# 
            if ( $arch eq "PartialNtPHY2.0" ) {
                my @staleMisc_new=();
                foreach my $newcorresfile (@etm) {
                    foreach my $pvt (@pvtCorners) {
                        if (checkFile("libgen/$macroName/$newcorresfile/${macroName}_${metalStack}_$pvt.log", undef, undef, undef)){
                            iprint("$timingRootP4/libgen/$macroName/$newcorresfile/${macroName}_${metalStack}_$pvt.log found\n");
                            my @lines_log=();
                            my $s2="$timingRootP4/libgen/$macroName/$newcorresfile/${macroName}_${metalStack}_$pvt.log";
                            @lines_log=`p4 annotate $s2`;
                            my $flag_error=0;
                            foreach my $l (@lines_log) {
                                if ( $l =~ m/Error/ || $l =~ m/ERROR/ ) {
                                    $flag_error=1;
                                    last;
                                }
                            }
                            if ( $flag_error == 0 ) {
                                iprint("No Errors found in $timingRootP4/libgen/$macroName/$newcorresfile/${macroName}_${metalStack}_$pvt.log \n");
                            } else {
                                eprint("Error found in the $timingRootP4/libgen/$macroName/$newcorresfile/${macroName}_${metalStack}_$pvt.log\n");
                            }
                        } else {
                            eprint("$timingRootP4/libgen/$macroName/$newcorresfile/${macroName}_${metalStack}_$pvt.log not found\n");
                        }
                    }
                    if (checkFile("libgen/$macroName/$newcorresfile/${macroName}.libgen", undef, undef, undef)){
                        iprint("$timingRootP4/libgen/$macroName/$newcorresfile/${macroName}.libgen found\n");
                    } else {
                        eprint("$timingRootP4/libgen/$macroName/$newcorresfile/${macroName}.libgen not found\n");
                    }
                }
            } else {
                foreach my $newcorresfile (@etm) {
                    nprint "\n\n";
                    iprint("--------------------------------------- Timing Status for new macro ETM $macroName/$newcorresfile ---------------------------------------\n\n");
                    my @word=();
                    @word = split /\//, $newcorresfile;
                    if ( $word[1] =~ m/etm_merge/ ) {
                        if (checkFile("$nt/$macroName/$newcorresfile/merge_lib.rpt", undef, undef, undef)){
                            iprint("$timingRootP4/$nt/$macroName/$newcorresfile/merge_lib.rpt found \n");
                        } else {
                            eprint("$timingRootP4/$nt/$macroName/$newcorresfile/merge_lib.rpt not found \n");
                        }
                        next;
                    }
                    my $ntMacro_new = 0;
                    my $someNtEtmLogs_new = 0;  ##  At least one nt etm log found
                    my $allNtEtmLogs_new = 1;   ##  all etm logs found
                    my $ntEtmPathsFileExists_new = 0;
                    my $ntEtmSavedSessionExists_new = 0;
                    my (@staleNtLogs_new, @okNtEtmLogs_new, @missingNtEtmLogs_new, @okNTmanagerLogs_new, @missingNTmanagerLogs_new, @staleNTmanagerLogs_new);
                    my $someNTmanagerLogs_new = 0;
                    my $allNTmanagerLogs_new = 1;
                    my @staleMisc_new=();
                    my $logError_new = 0;
                    foreach my $pvt (@pvtCorners) {
                        ##  Logs
                        my $ntEtmLog_new;
                        if ($ntEtmLog_new = checkFile("$nt/$macroName/$newcorresfile/timing/Run_${pvt}_etm/timing.log", \@okNtEtmLogs_new, \@missingNtEtmLogs_new, \@staleNtLogs_new)) {$someNtEtmLogs_new = 1} else {$allNtEtmLogs_new = 0}
    
                        ## Existence of at least one .paths file for etm
                        if (checkFile("$nt/$macroName/$newcorresfile/timing/Run_${pvt}_etm/${macroName}_${metalStack}_${pvt}.paths", undef, undef, \@staleMisc_new)) {$ntEtmPathsFileExists_new = 1}
    
                        ## Existence of at least one saved session in etm
                        if ($timingDirs->{"$nt/$macroName/$newcorresfile/timing/Run_${pvt}_etm/${macroName}_${pvt}"}) {$ntEtmSavedSessionExists_new = 1}
    
                    } #End of Pvt
    
                    ## Existence of ntManager.log
                    if (checkFile("$nt/$macroName/$newcorresfile/timing/ntManager.log", \@okNTmanagerLogs_new, \@missingNTmanagerLogs_new, @staleNTmanagerLogs_new)) {$someNTmanagerLogs_new=1} else {$allNTmanagerLogs_new=0}
    
                    #    my $logTag = ($logError) ? "DIRTY" : "CLEAN";
                    ## Lib checks
    
                    ##  Overall check for stale logs
                    if ((@staleSisLogs_new > 0) || (@staleNtLogs_new > 0)) {
                        eprint("Stale logs found for Nt Etm or Sis :\n");
                        dumpListFilerec(\@staleSisLogs_new,"\t\t");
                        dumpListFilerec(\@staleNtLogs_new, "\t\t");
                        $logError_new = 1;
                    }
    
                    my $nNtLog_new = (@okNtEtmLogs_new+@staleNtLogs_new);
                    if (($nNtLog_new>0)||($nSisLog_new>0)) {
                        iprint("Checking timing logs for errors for Nt Etm or SiS\n");
                        ##  Check log files for errors. Do so for all logs found
                        if ($nNtLog_new>0) {
                            if (checkNtLogs(\@okNtEtmLogs_new, \@staleNtLogs_new)) {iprint("Status:  NT Etm logs CLEAN\n\n")} else {iprint("Status:  NT Etm logs DIRTY\n\n")}
                        }
                    }  
                    ## Updation
                    if ($isNtMacro_new) {
                        checkexistence("$nt/$macroName/$newcorresfile/sourcefiles/constraints.tcl");
                        checkexistence("$nt/$macroName/$newcorresfile/sourcefiles/$macroName.equiv");
                        checkexistence("$nt/$macroName/$newcorresfile/sourcefiles/$macroName.mungeCfg");
                        checkexistence("$nt/$macroName/$newcorresfile/sourcefiles/$macroName.pininfoNT");
                        checkexistence("$nt/$macroName/$newcorresfile/sourcefiles/exceptions.tcl");
                        checkexistence("$nt/$macroName/$newcorresfile/sourcefiles/precheck.tcl");
                        checkexistence("$nt/$macroName/$newcorresfile/sourcefiles/prechecktopo.tcl");
                        checkexistence("$nt/$macroName/$newcorresfile/sourcefiles/prematchtopo.tcl");
                        checkexistence("$nt/$macroName/$newcorresfile/sourcefiles/user_setting.tcl");
                        checkexistence("$nt/$macroName/$newcorresfile/alphaNT.config");
    
                    } else {    
                        checkexistence("$sis/$macroName/run_$macroName.tcl");
                        checkexistence("$sis/$macroName/$macroName.inst");
                        checkexistence("$sis/common_source/commonSetup.tcl");
                    }

                    ##  The NT-specific runs.
                    if ($isNtMacro_new) {
                        ## Existence of ntManager.log
                        my $ntManagerLog_new = "";
                        if (defined $lvf) {
                            $ntManagerLog_new = "$nt/$macroName/$newcorresfile/ntManager_pocvflow.log";
                        } else {
                            $ntManagerLog_new = "$nt/$macroName/$newcorresfile/ntManager.log";
                        }
                        if (checkFile($ntManagerLog_new, undef, undef, undef)) {
                            checkNTmanagerLog("$timingRootP4/$ntManagerLog_new");
                        } else {
                            ## Missing.
                            eprint("$timingRootP4/$ntManagerLog_new is missing\n");
                        }
    
                        if (!$ntEtmPathsFileExists_new) {
                            ##  At least one NT ETM .paths file exists.
                            eprint("No .paths file found  in ETM runs\n");
                        }
    
                        if (!$ntEtmSavedSessionExists_new) {
                            ##  At least one NT ETM .paths file exists.
                            eprint("No saved session directory found for NT ETM runs\n");
                        }
    
                        #    if (!$someReportsMacro) {
                        #        ## No report files found
                        #        eprint("No .rpt files found in any NT internal run\n");
                        #    }
                        #    else {
                        #        if (!$allReportsMacro) {
                        #        eprint("Complete set of .rpt files not found for any one NT internal run\n");
                        #        }
                        #    }
                    }
                    iprint("Checking timing logs for existence and creation time\n");
                    $logError_new = 0;
                    if (!($sisSingleLog_new || $someSisPvtLogs_new || $someNtEtmLogs_new )) { 
                        ## No logs found at all.
                        eprint("No timing logs at all found !! Excluding Nt Internal Logs that will be checked later \n");
                        $logError_new = 1;
                    }
                    elsif (($sisSingleLog_new || $someSisPvtLogs_new) && $someNtEtmLogs_new) {
                        ## Sime SiS logs and some NT logs found.  Like totally weird.
                        eprint("Both SiS and NT logs found:\n");
                        iprint("\tSiS:\n");
                        if ($sisSingleLog_new) {iprint("\t\t$sisSingleLog_new->{NAME}\n")}
                        dumpListFilerec(\@okSisLogs_new, "\t\t");
                        dumpListFilerec(\@staleSisLogs_new, "\t\t");
                        iprint("\tNT:\n");
                        dumpListFilerec(\@okNtEtmLogs_new, "\t\t");
                        dumpListFilerec(\@staleNtLogs_new, "\t\t");
                        dumpListFilerec(\@staleNtLogs_new, "\t\t");
                        $logError_new = 1;
                    }
                    elsif ($sisSingleLog_new && $someSisPvtLogs_new) {
                        ##  Both single SiS and pvt-specifics found
                        eprint("Both SiS single and pvt-specific logs found:\n");
                        dumpListFilerec(\@okSisLogs_new, "\t\t");
                        dumpListFilerec(\@staleSisLogs_new, "\t\t");
                        $logError_new = 1;
                    }
                    elsif ($sisSingleLog_new && !$someSisPvtLogs_new) {
                        ##  Single log.  OK
                    }
                    elsif (!$sisSingleLog_new && $someSisPvtLogs_new) {
                        ##  pvt-specific logs.
                        if (!$allSisPvtLogs_new) {
                            ##  Missing logs
                            eprint("Missing SiS logs:\n");
                            dumpList(\@missingSisLogs_new, "\t");
                            $logError_new = 1;
                        }
                    } else {
                        ## Must be NT
                        if ($someNtEtmLogs_new && !$allNtEtmLogs_new) {
                            ##  Some missing etm logs
                            eprint("Missing NT ETM logs:\n");
                            dumpList(\@missingNtEtmLogs_new, "\t");
                            $logError_new = 1;
                        }
                    }
                }
            }

            if ( $arch eq "PartialNtPHY2.0" ) {
    #--------------Nt Internal Runs ---------------------#
                foreach my $newcorresinternalfile (@internal) {
                    print "\n";
                    iprint("--------------------------------------- Timing Status for new macro Internal $macroName/$newcorresinternalfile ---------------------------------------\n");    
                    my $ntIntSavedSessionExists_new = my $ntIntExcludedNetsExists_new = my $ntIntXtorNotAnnotated_new = 0;
                    my (@okNtIntLogs_new, @missingNtIntLogs_new, @missingNtReports_new, @okSetupLogs_new, @missingSetupLogs_new, @okNtReports_new);
                    my $someNtIntLogs_new = 0;  ##  At least one nt internal log found
                    my $allNtIntLogs_new = 1;   ##  all internal logs found
                    my $someReportsMacro_new = my $allReportsMacro_new = 0;
                    my (@staleRpts_new, @staleNtLogs_Int_new, @staleMisc_new);
                    my $someNtVariationParameter=0;
                    my $allNtVariationParameter=1;
                    my $logError_new=0;
                    foreach my $pvt (@pvtCorners) {     
                        #Logs   
                        my $ntIntLog_new = checkFile("$nt/$macroName/$newcorresinternalfile/timing/Run_${pvt}_internal/timing.log", \@okNtIntLogs_new, \@missingNtIntLogs_new, \@staleNtLogs_Int_new);
                        if ($ntIntLog_new) {$someNtIntLogs_new = 1} 
                        else {$allNtIntLogs_new = 0}
    
                        ## Existence of set_variation_parameters.tcl file under variation directory. Added with lvf related updates.
                        if (checkFile("$nt/variation/timing/Run_${pvt}_etm/xtor_variations/set_variation_parameters.tcl", \@okSetupLogs_new, \@missingSetupLogs_new, \@staleMisc_new)) {$someNtVariationParameter = 1} else {$allNtVariationParameter = 0}
    
                        ##  Existence of at least one Run_<pvt>_internal/ <macro>.excluded_Xld_nets.sorted
                        if (checkFile("$nt/$macroName/$newcorresinternalfile/timing/Run_${pvt}_internal/${macroName}.edgerates.excluded_Xld_nets.sorted", undef, undef, \@staleMisc_new)) {$ntIntExcludedNetsExists_new = 1}
    
                        ##  Existence of at least one Run_<pvt>_internal/transistors_not_annotated_all
                        if (checkFile("$nt/$macroName/$newcorresinternalfile/timing/Run_${pvt}_internal/transistors_not_annotated_all", undef, undef, \@staleMisc_new)) {$ntIntXtorNotAnnotated_new = 1}
    
                        ## Existence of at least one saved session for internal
                        if ($timingDirs->{"$nt/$macroName/$newcorresinternalfile/timing/Run_${pvt}_internal/${macroName}_${pvt}"}) {$ntIntSavedSessionExists_new = 1}
                        ##  Need exploded list of *.rpt for internal runs.
                        my $someReports_new = 0;
                        my $allReports_new = 1;
                        foreach my $rpt (@InternalReportFiles) {
                            if (checkFile("$nt/$macroName/$newcorresinternalfile/timing/Run_${pvt}_internal/$rpt", 
    			                          \@okNtReports_new, \@missingNtReports_new, \@staleRpts_new)) {
    			                $someReports_new = 1;
    			            } else {
    			                $allReports_new = 0;
    			            }
                        }
    
                        if ($someReports_new) {$someReportsMacro_new = 1}
                        if ($allReports_new) {$allReportsMacro_new = 1}
                    }#End Pvt
                    #****Nt Checks*****************************#
                    nprint "\n";
                    iprint("Checking existence of sourcefiles\n");
                    checkexistence("$nt/$macroName/$newcorresinternalfile/sourcefiles/constraints.tcl");
                    checkexistence("$nt/$macroName/$newcorresinternalfile/sourcefiles/$macroName.equiv");
                    checkexistence("$nt/$macroName/$newcorresinternalfile/sourcefiles/$macroName.mungeCfg");
                    checkexistence("$nt/$macroName/$newcorresinternalfile/sourcefiles/$macroName.pininfoNT");
                    checkexistence("$nt/$macroName/$newcorresinternalfile/sourcefiles/exceptions.tcl");
                    checkexistence("$nt/$macroName/$newcorresinternalfile/sourcefiles/precheck.tcl");
                    checkexistence("$nt/$macroName/$newcorresinternalfile/sourcefiles/prechecktopo.tcl");
                    checkexistence("$nt/$macroName/$newcorresinternalfile/sourcefiles/prematchtopo.tcl");
                    checkexistence("$nt/$macroName/$newcorresinternalfile/sourcefiles/user_setting.tcl");
                    checkexistence("$nt/$macroName/$newcorresinternalfile/alphaNT.config");
                    checkexistence("$nt/$macroName/$newcorresinternalfile/portCheck.log");

                    ## Existence of ntManager.log
                    my $ntManagerLog_new = "";
                    if (defined $lvf) {
                        $ntManagerLog_new = "$nt/$macroName/$newcorresinternalfile/ntManager_pocvflow.log";
                    } else {
                        $ntManagerLog_new = "$nt/$macroName/$newcorresinternalfile/ntManager.log";
                    }
                    iprint( "NT $ntManagerLog_new    full path $timingRootP4/$ntManagerLog_new \n");
                    if (checkFile($ntManagerLog_new, undef, undef, undef)) {
                        checkNTmanagerLog("$timingRootP4/$ntManagerLog_new");
                    } else {
                        ## Missing.
                        eprint("$timingRootP4/$ntManagerLog_new is missing\n");
                    }
                    ##  Overall check for stale logs
                    if ((@staleNtLogs_Int_new > 0)) {
                        eprint("Stale logs found for NtInternal:\n");
                        dumpListFilerec(\@staleNtLogs_Int_new, "\t\t");
                        $logError_new = 1;
                    }
                    my $nNtLog_new = (@staleNtLogs_Int_new+@okNtIntLogs_new);
                    if ($nNtLog_new>0) {
    
                        nprint "\n";
                        iprint("Checking timing logs of Nt Internal for errors\n");
                        ##  Check log files for errors. Do so for all logs found
                        if ($nNtLog_new>0) {
                            if (checkNtLogs(\@staleNtLogs_Int_new, \@okNtIntLogs_new)) {iprint("Status:  NT internal timing logs CLEAN\n\n")} else {iprint("Status:  NT internal timing logs DIRTY \n\n")}
                        }
                    }
                    #  Handle internal timing collateral.
                    ##  Internal runs are expected if NT libs were found, or if explicitely forced via option or project variable.
    
                    if (1) {
                        iprint("Internal timing runs expected\n");
                        if (!$someNtIntLogs_new) {
                            eprint("No internal NT logs found\n");
                        }
                        elsif ($someNtIntLogs_new && !$allNtIntLogs_new) {
                            ##  Some missing etm logs
                            eprint("Missing NT Internal logs:\n");
                            dumpList(\@missingNtIntLogs_new, "\t");
                            $logError_new = 1;
                        } else {
                            iprint("NT Internal logs present\n");
                        }
                        if (!$someNtVariationParameter) {
                            eprint("POCV variation coefficients files are missing\n");
                        }
                        elsif ($someNtVariationParameter && !$allNtVariationParameter) {
                            ##  Some missing etm logs
                            eprint("Missing POCV variation coefficients files:\n");
                            dumpList(\@missingSetupLogs_new, "\t");
                            $logError_new = 1;
                        } else {
                            iprint("POCV variation coefficients files are present\n");
                        }

                        ##  Presence of at least one excluded_Xld_nets.sorted
                        if (!$ntIntExcludedNetsExists_new) {
                            eprint("No $macroName/$newcorresinternalfile.excluded_Xld_nets.sorted found for any NT internal run\n");
                        } else {
                            iprint("$macroName/$newcorresinternalfile.excluded_Xld_nets.sorted found\n");
                        }
    
                        ##  Presence of at least one transistors_not_annotated_all
                        if (!$ntIntXtorNotAnnotated_new) {
                            eprint("No transistors_not_annotated_all file found for any NT internal run\n");
                        } else {
                            iprint("transistors_not_annotated_all file found\n");
                        }
    
                        ##  Presence of at least one saved session dir
                        if (!$ntIntSavedSessionExists_new) {
                            eprint("No saved session dir found for any NT internal run\n");
                        } else {
                            iprint("Saved session dir found\n");
                        }
                    }
                }
            } else {
                #--------------Nt Internal Runs ---------------------#
                foreach my $newcorresinternalfile (@internal) {
                    print "\n";
                    iprint("\n--------------------------------------- Timing Status for new macro Internal $macroName/$newcorresinternalfile ---------------------------------------\n");    
                    my $ntIntSavedSessionExists_new = my $ntIntExcludedNetsExists_new = my $ntIntXtorNotAnnotated_new = 0;
                    my (@okNtIntLogs_new, @missingNtIntLogs_new, @missingNtReports_new, @okNtReports_new, @okSetupLogs_new, @missingSetupLogs_new);
                    my $someNtIntLogs_new = 0;  ##  At least one nt internal log found
                    my $allNtIntLogs_new = 1;   ##  all internal logs found
                    my $someReportsMacro_new = my $allReportsMacro_new = 0;
                    my (@staleRpts_new, @staleNtLogs_Int_new, @staleMisc_new);
                    my $someNtVariationParameter = 0;
                    my $allNtVariationParameter = 1;
                    foreach my $pvt (@pvtCorners) {
                        #Logs   
                        my $ntIntLog_new = checkFile("$nt/$macroName/$newcorresinternalfile/timing/Run_${pvt}_internal/timing.log", \@okNtIntLogs_new, \@missingNtIntLogs_new, \@staleNtLogs_Int_new);
                        if ($ntIntLog_new ) {$someNtIntLogs_new = 1} 
                        else {$allNtIntLogs_new = 0}
    
                        ## Existence of set_variation_parameters.tcl file under variation directory. Added with lvf related updates.
                        if (checkFile("$nt/variation/timing/Run_${pvt}_etm/xtor_variations/set_variation_parameters.tcl", \@okSetupLogs_new, \@missingSetupLogs_new, \@staleMisc_new)) {$someNtVariationParameter = 1} else {$allNtVariationParameter = 0}
    
                        ##  Existence of at least one Run_<pvt>_internal/ <macro>.excluded_Xld_nets.sorted
                        if (checkFile("$nt/$macroName/$newcorresinternalfile/timing/Run_${pvt}_internal/${macroName}.edgerates.excluded_Xld_nets.sorted", undef, undef, \@staleMisc_new)) {$ntIntExcludedNetsExists_new = 1}
    
                        ##  Existence of at least one Run_<pvt>_internal/transistors_not_annotated_all
                        if (checkFile("$nt/$macroName/$newcorresinternalfile/timing/Run_${pvt}_internal/transistors_not_annotated_all", undef, undef, \@staleMisc_new)) {$ntIntXtorNotAnnotated_new = 1}
    
                        ## Existence of at least one saved session for internal
                        if ($timingDirs->{"$nt/$macroName/$newcorresinternalfile/timing/Run_${pvt}_internal/${macroName}_${pvt}"}) {$ntIntSavedSessionExists_new = 1}

                        ##  Need exploded list of *.rpt for internal runs.
                        my $someReports_new = 0;
                        my $allReports_new = 1;
                        foreach my $rpt (@InternalReportFiles) {
                            if (checkFile("$nt/$macroName/$newcorresinternalfile/timing/Run_${pvt}_internal/$rpt", 
    			                           \@okNtReports_new, \@missingNtReports_new, \@staleRpts_new)) {
    			                $someReports_new = 1;
    			            } else {
    			                $allReports_new = 0;
    			            }
                        }
                        if ($someReports_new) {$someReportsMacro_new = 1}
                        if ($allReports_new) {$allReportsMacro_new = 1}
                    }#End Pvt
                    ##  Overall check for stale logs
                    my $logError_new=0;
                    if ((@staleNtLogs_Int_new > 0)) {
                        eprint("Stale logs found for NtInternal:\n");
                        dumpListFilerec(\@staleNtLogs_Int_new, "\t\t");
                        $logError_new = 1;
                    }
                    my $nNtLog_new = (@staleNtLogs_Int_new+@okNtIntLogs_new);
                    if ($nNtLog_new>0) {
                        iprint("Checking timing logs of Nt Internal for errors\n");
                        ##  Check log files for errors. Do so for all logs found
                        if ($nNtLog_new>0) {
                            if (checkNtLogs(\@staleNtLogs_Int_new, \@okNtIntLogs_new)) {iprint("Status:  NT internal timing logs CLEAN\n\n")} else {iprint("Status:  NT internal timing logs DIRTY \n\n")}
                        }
                    }
                    #  Handle internal timing collateral.
                    ##  Internal runs are expected if NT libs were found, or if explicitely forced via option or project variable.
    
                    if (1) {
                        iprint("Internal timing runs expected\n");
                        if (!$someNtIntLogs_new) {
                            eprint("No internal NT logs found\n");
                        }
                        elsif ($someNtIntLogs_new && !$allNtIntLogs_new) {
                            ##  Some missing etm logs
                            eprint("Missing NT Internal logs:\n");
                            dumpList(\@missingNtIntLogs_new, "\t");
                            $logError_new = 1;
                        } else {
                            iprint("NT Internal logs present\n");
                        }
    
                        ##  Presence of at least one excluded_Xld_nets.sorted
                        if (!$ntIntExcludedNetsExists_new) {
                            eprint("No $macroName/$newcorresinternalfile.excluded_Xld_nets.sorted found for any NT internal run\n");
                        } else {
                            iprint("$macroName/$newcorresinternalfile.excluded_Xld_nets.sorted found\n");
                        }
    
                        ##  Presence of at least one transistors_not_annotated_all
                        if (!$ntIntXtorNotAnnotated_new) {
                            eprint("No transistors_not_annotated_all file found for any NT internal run\n");
                        } else {
                            iprint("transistors_not_annotated_all file found\n");
                        }
    
                        ##  Presence of at least one saved session dir
                        if (!$ntIntSavedSessionExists_new) {
                            eprint("No saved session dir found for any NT internal run\n");
                        } else {
                            iprint("Saved session dir found\n");
                        }
    
                        if (!$someNtVariationParameter) {
                            eprint("POCV variation coefficients are missing\n");
                            dumpList(\@missingSetupLogs_new, "\t");
                        } else {
                            iprint("POCV variation coefficients are found\n");
                        }
                    }
                }
            }    
            if ($qualCheckRoot) {
                iprint("Checking quality checks\n");
                ##  Look for the quality checks
    
                ##  Check logs depending on which libs were found, with and/or without metalStack
                my $libPatt1 = "(${macroName}_${metalStack}_{PVT}.lib|${macroName}_{PVT}.lib)";
                my $libPatt = "(${macroName}_${metalStack}_{PVT}_pg.lib|${macroName}_{PVT}_pg.lib)";
                #    checkSingleQcLog("$qualCheckRoot/alphaCompareArcs/alphaCompareArcs.log", "^Warning:", $libPatt);
    
                if (!$nocompilecheck) {checkSingleQcLog("$qualCheckRoot/alphaCompileLibs/compile.log", "^Error:", $libPatt1, undef, "^Reading")}
                if (!$nocompilecheck) {checkSingleQcLog("$qualCheckRoot/alphaCompileLibs/compile_pg.log", "^Error:", $libPatt, undef, "^Reading")}
                if ($hasSetupHold) {
                    &checkPvtQcLog("$qualCheckRoot/alphaLibCheckMonotonicSetupHold/MONOTONICLOGS", "^Non monotonic");
                } else {
                    iprint("No setup/hold arcs; Skipping CheckMonotonicSetupHold\n");
                }
                checkSingleQcLog("$qualCheckRoot/alphaPinCheck/${macroName}_pincheck.log", "DIRTY", $libPatt) unless (defined $nonDI);
                #    checkSingleQcLog("$qualCheckRoot/alphaPinCheck/alphaLibertyCheck/alphaLibertyCheck.log", undef, $libPatt);   ##  Needs error patterns
    
                ##  alphaPlotArcs stuff
                #    checkPlotArcsCsv("$qualCheckRoot/alphaPlotArcs/compare_gold", "${macroName}_report\.csv", "gold");
                #    checkPlotArcsCsv("$qualCheckRoot/alphaPlotArcs/compare_iterative", "${macroName}_report\.csv", "iterative");
    
                ##  Check existence of .pdf
                foreach my $pt ("compare_gold", "compare_iterative") {
                    # my $singlePdf = checkFile("$qualCheckRoot/alphaPlotArcs/$pt/$macroName.pdf");
                    my $singleCsv = checkFile("$qualCheckRoot/alphaPlotArcs/$pt/${macroName}_report.csv");
                    # my @missingPdf;
                    my @missingCsv;
                    # my @stalePdf;
                    my @staleCsv;
                    # my $somePvtPdf = 0;
                    # my $allPvtPdf = 1;
                    my $somePvtCsv = 0;
                    my $allPvtCsv = 1;
                    my @okCsv;
                    foreach my $pvt (@pvtCorners) {
                        #if (checkFile("$qualCheckRoot/alphaPlotArcs/$pt/${macroName}_${pvt}.pdf", \@okPdf, \@missingPdf, \@stalePdf)) {$somePvtPdf = 1} else {$allPvtPdf = 0}
                        if (checkFile("$qualCheckRoot/alphaPlotArcs/$pt/${macroName}_report_${pvt}.csv", \@okCsv, \@missingCsv, \@staleCsv)) {$somePvtCsv = 1} else {$allPvtCsv = 0}
                    }
                    ##  Report pdf presence.
                    #if (!$singlePdf && !$somePvtPdf) {
                    ##  no pdf's found at all
                    #eprint("No pdfs found, $qualCheckRoot/alphaPlotArcs/$pt/$macroName.pdf or $qualCheckRoot/alphaPlotArcs/$pt/${macroName}_{PVT}.pdf\n");
                    #}
                    #elsif ($somePvtPdf && !$allPvtPdf) {
                    #eprint("Missing pdf's:\n");
                    #dumpList(\@missingPdf, "\t");
                    #}
                    ##  Report csv presence:
                    if (!$singleCsv && !$somePvtCsv) {
                        ##  no csv's found at all
                        eprint("No csv found, $qualCheckRoot/alphaPlotArcs/$pt/${macroName}_report.csv or $qualCheckRoot/alphaPlotArcs/$pt/${macroName}_report_{PVT}.csv\n");
                    }
                    elsif ($somePvtCsv && !$allPvtCsv) {
                        eprint("Missing csv's:\n");
                        dumpList(\@missingCsv, "\t");
                    }
                    if ($singleCsv) {push @okCsv, $singleCsv};
                    foreach my $csv (@okCsv) {checkPlotArcsCsv($csv, $pt)}
                    @okCsv=();
                }
    
                ##  Liberty checks
                ##  Single logs:
                if ( $hasTiming ){
                    checkSingleQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkArc/checkArc.log", undef, undef, "Arc consistency passed");
                } else {
                    wprint("Macro has no timing, skipping checkArc. macroName='${macroName}'\n");
                }
                if ($busesExist) {&checkPvtQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkBusOrder", "^Error:")} 
                else {iprint( "No buses found in libs; Skipping checkBusOrder requirement\n")}
    
                checkSingleQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkDerate/checkDerate.log", undef, undef, "Liberty Derate Attributes Verified");
    
                ##  Separate pvt logs
                &checkPvtQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkDuplicateAttributes", "^Error:");
                &checkPvtQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkMaxCap", "^Error:");
                &checkPvtQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkOperatingConditions", "^Error:");
                checkSingleQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkPt/checkPt.log", "^Error:");
                &checkPvtQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkTiming", "^Error:");
    
                ##  Gonzo
                #    &checkPvtQcLog("$qualCheckRoot/alphaLibertyCheck/listArc");
                #    &checkPvtQcLog("$qualCheckRoot/alphaLibertyCheck/listDerate");

            }#End Qual Check root
    
            nprint "\n";
            iprint("------------------------------------------------------------------------------------------------------------------\n");
            if ($macroLogs) {
                ##  Figure out where to put the macro log in p4.
                my @timingTypeList = Tokenify($TimingType{$macroName});
                if (@timingTypeList > 1) {
                    wprint("Collateral found in multiple locations: {@timingTypeList}.  Log will be checked in under each.\n");
                }
    
                #  If multiple timingTypes are found, check in log in multiple places.    
                #    if ((($timingType eq "sis") || ($timingType eq "nt") || ($timingType eq "libgen"))) 
                #close LOG;
                foreach my $timingType (@timingTypeList) {
                    if ($p4Logs) {
                        process_log_file($p4Description, $timingRootP4, $timingType, $macroName);
                    }
                }
            }#macroslog
        } # if ( $macroName =~ m/lcdl/ || $macroName =~ m/bdl/ ) 
        else {
            ##  SiS/NT flags.  Set on presence of any log or lib.
            my $sisMacro = my $ntMacro = 0;
    
            my $someSisLibs    = 0;  ## Found at least one SiS lib
            my $someNtLibs     = 0;   ##  Found at least one NT lib
            my $someLibgenLibs = 0;   ##  Found at least one libgen lib
    
            my $allSisLibs = 1;  ##  Found all SiS libs
            my $allNtLibs = 1;   ##  Found all NT libs
            my $allLibgenLibs = 1;   ##  Found all libgen libs
    
            ##  Same as the above w/o metalStack
            my $someSisLibsNoms = 0;  ## Found at least one SiS lib
            my $someNtLibsNoms = 0;   ##  Found at least one NT lib
            my $someLibgenLibsNoms = 0;   ##  Found at least one libgen lib
    
            my $allSisLibsNoms = 1;  ##  Found all SiS libs
            my $allNtLibsNoms = 1;   ##  Found all NT libs
            my $allLibgenLibsNoms = 1;   ##  Found all libgen libs
    
            my $someSisPvtLogs = 0;  ##  At least one pvt-level SiS log found
            my $allSisPvtLogs = 1;   ##  all pvt-level SiS log found
    
            my $someNtEtmLogs = 0;  ##  At least one nt etm log found
            my $allNtEtmLogs = 1;   ##  all etm logs found
    
            my $someNtIntLogs = 0;  ##  At least one nt internal log found
            my $allNtIntLogs = 1;   ##  all internal logs found
    
            my $ntEtmPathsFileExists = my $ntEtmSavedSessionExists = my $ntIntSavedSessionExists = my $ntIntExcludedNetsExists = my $ntIntXtorNotAnnotated = 0;
    
            $macroData->{$macroName} = {};
    
            my $sisSingleLog = checkFile("$sis/$macroName/siliconsmart.log");

            $someSisPvtLogs = 0;
    
            my (@staleLibs, @staleNtLogs, @staleSisLogs, @staleMisc, @staleMisc_new, @staleRpts, @missingLogs, 
                @okNtEtmLogs, @okNtIntLogs, @missingNtEtmLogs, @missingNtIntLogs, @okSisLogs, @missingSisLogs,
                @okNtLibs, @okLibgenLibs, @okSisLibs, @missingNtLibs, @missingLibgenLibs, @missingSisLibs,
                ## w/o metalStack
                @okNtLibsNoms, @okLibgenLibsNoms, @okSisLibsNoms, @missingNtLibsNoms, @missingLibgenLibsNoms,
                @missingSisLibsNoms);
    
            my $someReportsMacro = my $allReportsMacro = 0;
            my (@missingNtReports, @okNtReports);
            my $hasLibsMs = my $hasLibsNoms = 0;
    
            my (@okNTmanagerLogs, @missingNTmanagerLogs, @staleNTmanagerLogs);
            my $someNTmanagerLogs = 0;
            my $allNTmanagerLogs = 1;
            my $someNtVariationParameter = 0;
            my $allNtVariationParameter = 1;
            my (@okSetupLogs_new, @missingSetupLogs_new);
   
            process_pvt_corners( \@pvtCorners, $macroName, $metalStack, 
                $sis, $nt, 
                \@staleLibs,                \@staleMisc,  \$hasLibsNoms, 
                \$hasLibsMs,                \@staleRpts,  \$ntIntExcludedNetsExists,
                \$ntEtmSavedSessionExists,  \$ntEtmPathsFileExists,
                \$someNtVariationParameter, \$allNtVariationParameter,
                \$ntIntXtorNotAnnotated,    \$ntIntSavedSessionExists, 

                \$allSisLibs,        \$someSisLibs,        \@okSisLibs,        \@missingSisLibs,
                \$allSisLibsNoms,    \$someSisLibsNoms,    \@okSisLibsNoms,    \@missingSisLibsNoms,
                \$allSisPvtLogs,     \$someSisPvtLogs,     \@okSisLogs,        \@missingSisLogs,        \@staleSisLogs,
                \$allNtLibs,         \$someNtLibs,         \@okNtLibs,         \@missingNtLibs,         \@staleNtLogs,
                \$allNtLibsNoms,     \$someNtLibsNoms,     \@okNtLibsNoms,     \@missingNtLibsNoms,
                \$allNtEtmLogs,      \$someNtEtmLogs,      \@okNtEtmLogs,      \@missingNtEtmLogs, 
                \$allNtIntLogs,      \$someNtIntLogs,      \@okNtIntLogs,      \@missingNtIntLogs,      
                                                           \@okNtReports,      \@missingNtReports,   
                \$allLibgenLibs,     \$someLibgenLibs,     \@okLibgenLibs,     \@missingLibgenLibs, 
                \$allLibgenLibsNoms, \$someLibgenLibsNoms, \@okLibgenLibsNoms, \@missingLibgenLibsNoms,
                                                           \@okSetupLogs_new,  \@missingSetupLogs_new,  \@staleMisc_new,
                \$someReportsMacro, \$allReportsMacro );

            ## Existence of ntManager.log
            if (defined $lvf) {
                if (checkFile("$nt/$macroName/timing/ntManager_pocvflow.log", \@okNTmanagerLogs, \@missingNTmanagerLogs, @staleNTmanagerLogs)) {
                    $someNTmanagerLogs=1
                } else {
                    $allNTmanagerLogs=0
                }
            } else  {
                if (checkFile("$nt/$macroName/timing/ntManager.log", \@okNTmanagerLogs, \@missingNTmanagerLogs, @staleNTmanagerLogs)) {
                    $someNTmanagerLogs=1
                } else {
                    $allNTmanagerLogs=0
                }
            }
    
            if ($hasLibsMs) {
                iprint("Libs with metalStack were found\n");
            }
            if ($hasLibsNoms) {
                iprint("Libs without metalStack were found\n");
            }
            ## Logs
    
            iprint("Checking timing logs for existence and creation time\n");
            my $logError = 0;
            if (!($sisSingleLog || $someSisPvtLogs || $someNtEtmLogs || $someNtIntLogs)) {
                ## No logs found at all.
                eprint("No timing logs at all found\n");
                $logError = 1;
            }
            elsif (($sisSingleLog || $someSisPvtLogs) && $someNtEtmLogs) {
                ## Some SiS logs and some NT logs found.  Like totally weird.
                eprint("Both SiS and NT logs found:\n");
                iprint("\tSiS:\n");
                if ($sisSingleLog) {iprint("\t\t$sisSingleLog->{NAME}\n")}
                dumpListFilerec(\@okSisLogs, "\t\t");
                dumpListFilerec(\@staleSisLogs, "\t\t");
                iprint("\tNT:\n");
                dumpListFilerec(\@okNtEtmLogs, "\t\t");
                dumpListFilerec(\@staleNtLogs, "\t\t");
                dumpListFilerec(\@staleNtLogs, "\t\t");
                $logError = 1;
            }
            elsif ($sisSingleLog && $someSisPvtLogs) {
                ##  Both single SiS and pvt-specifics found
                eprint("Both SiS single and pvt-specific logs found:\n");
                dumpListFilerec(\@okSisLogs, "\t\t");
                dumpListFilerec(\@staleSisLogs, "\t\t");
                $logError = 1;
            }
            elsif ($sisSingleLog && !$someSisPvtLogs) {
                ##  Single log.  OK
            }
            elsif (!$sisSingleLog && $someSisPvtLogs) {
                ##  pvt-specific logs.
                if (!$allSisPvtLogs) {
                    ##  Missing logs
                    eprint("Missing SiS logs:\n");
                    dumpList(\@missingSisLogs, "\t");
                    $logError = 1;
                }
            } else {
                ## Must be NT
                if ($someNtEtmLogs && !$allNtEtmLogs) {
                    ##  Some missing etm logs
                    eprint("Missing NT ETM logs:\n");
                    dumpList(\@missingNtEtmLogs, "\t");
                    $logError = 1;
                }
            }
    
            ##  Overall check for stale logs
            if ((@staleSisLogs > 0) || (@staleNtLogs > 0)) {
                eprint("Stale logs found:\n");
                dumpListFilerec(\@staleSisLogs, "\t\t");
                dumpListFilerec(\@staleNtLogs, "\t\t");
                $logError = 1;
            }
    
            my @singleSisLogList;
            if ($sisSingleLog) {push @singleSisLogList, $sisSingleLog};
            my $nNtLog = (@okNtEtmLogs+@staleNtLogs+@okNtIntLogs);
            my $nSisLog = (@singleSisLogList+@okSisLogs+@staleSisLogs);
            if (($nNtLog>0)||($nSisLog>0)) {
                iprint("Checking timing logs for errors\n");
                ##  Check log files for errors. Do so for all logs found
                if ($nNtLog>0) {
                    if (checkNtLogs(\@okNtEtmLogs, \@staleNtLogs, \@okNtIntLogs)) {iprint("Status:  NT logs CLEAN\n\n")} else {eprint("Status:  NT logs DIRTY\n\n")}
                }
                if ($nSisLog>0) {
                    if (checkSisLogs(\@singleSisLogList, \@okSisLogs, \@staleSisLogs)) {iprint("Status:  SiS logs CLEAN\n\n")} else {eprint("Status:  SiS logs DIRTY\n\n")}
                }
            }
    
            ## Lib checks
            my $qualCheckRoot = undef;
            my $timingType;
            iprint("Checking libs for existence and creation date\n");
            my $isSisMacro = 0;
            my $isNtMacro = 0;
            my $isLibgenMacro = 0;
            my $libError = 0;
            my $busesExist;
            #my $timingExist;
            #my $hasTiming;
            my $hasSetupHold;
            if ($someSisLibs && !$someNtLibs && !$someLibgenLibs) {
                ##  Presumed to be an SiS macro
                $isSisMacro = 1;
                iprint("Only SiS libs found; All other NT-related checks will be skipped\n");
                if (!$allSisLibs) {
                    $libError = 1;
                    eprint("Missing libs:\n");
                    foreach my $lib (@missingSisLibs) {iprint("\t$lib\n")}
                }
                $qualCheckRoot =  "$sis/$macroName/quality_checks";

                ($busesExist, $hasTiming, $hasSetupHold) = checkBusAndTimingExistence(\@okSisLibs);
            }
            elsif (!$someSisLibs && $someNtLibs && !$someLibgenLibs) {
                ##  Presumed to be an NT macro
                iprint("Only NT libs found\n");
                $isNtMacro = 1;
                if (!$allNtLibs) {
                    $libError = 1;
                    eprint("Missing libs:\n");
                    foreach my $lib (@missingNtLibs) {iprint("\t$lib\n")}
                }
                $qualCheckRoot =  "$nt/$macroName/quality_checks";
                #            ?$hasTiming?  should this be $timingExist ?? 
                ($busesExist, $hasTiming, $hasSetupHold) = checkBusAndTimingExistence(\@okNtLibs);
            }
            elsif (!$someSisLibs && !$someNtLibs && $someLibgenLibs) {
                ##  Presumed to be a libgen macro
                iprint("Only libgen libs found\n");
                $isLibgenMacro = 1;
                if (!$allLibgenLibs) {
                    $libError = 1;
                    eprint("Missing libs:\n");
                    foreach my $lib (@missingLibgenLibs) {iprint("\t$lib\n")}
                }
                $qualCheckRoot =  "libgen/$macroName/quality_checks";
                ($busesExist,$hasTiming,$hasSetupHold) = checkBusAndTimingExistence(\@okLibgenLibs);
            }
            elsif (!$someSisLibs && !$someNtLibs && !$someLibgenLibs) {
                ## No libs found at all.
                $libError = 1;
                eprint("No libs found at all; All other NT-related checks will be skipped\n");
            } else {
                ##  Libs found in more than one
                eprint("Libs found in more than one place ($someNtLibs,$someSisLibs,$someLibgenLibs\n");
                $libError = 1;
                $isSisMacro = 0;
                $isNtMacro = 0;
                $isLibgenMacro = 0;
            ## BOZO:  Combined list of libs?
            }
    
            ##  Overall check for stale libs
            if (@staleLibs > 0) {
                $libError = 1;
                eprint("Stale libs found:\n");
                dumpListFilerec(\@staleLibs, "\t\t");
            }
    
            my $libTag = ($libError) ? "DIRTY" : "CLEAN";
            iprint("Status:  Lib existence and creation time check  $libTag\n\n");

            ## Updation
            if ($isNtMacro) {
                checkexistence("$nt/$macroName/sourcefiles/constraints.tcl");
                checkexistence("$nt/$macroName/sourcefiles/$macroName.equiv");
                checkexistence("$nt/$macroName/sourcefiles/$macroName.mungeCfg");
                checkexistence("$nt/$macroName/sourcefiles/$macroName.pininfoNT");
                checkexistence("$nt/$macroName/sourcefiles/exceptions.tcl");
                checkexistence("$nt/$macroName/sourcefiles/precheck.tcl");
                checkexistence("$nt/$macroName/sourcefiles/prechecktopo.tcl");
                checkexistence("$nt/$macroName/sourcefiles/prematchtopo.tcl");
                checkexistence("$nt/$macroName/sourcefiles/user_setting.tcl");
                checkexistence("$nt/$macroName/alphaNT.config");
    
            } else {    
                checkexistence("$sis/$macroName/run_$macroName.tcl");
                checkexistence("$sis/$macroName/$macroName.inst");
                checkexistence("$sis/common_source/commonSetup.tcl");
            }     

            ##  The NT-specific runs.
            if ($isNtMacro) {
                ## Existence of ntManager.log
                my $ntManagerLog_new = "";
                if (defined $lvf) {
                    $ntManagerLog_new = "$nt/$macroName/ntManager_pocvflow.log";
                } else {
                    $ntManagerLog_new = "$nt/$macroName/ntManager.log";
                }
                if (checkFile($ntManagerLog_new, undef, undef, undef)) {
                    checkNTmanagerLog("$timingRootP4/$ntManagerLog_new");
                } else {
                    ## Missing.
                    eprint("$timingRootP4/$ntManagerLog_new is missing\n");
                }
    
                if (!$ntEtmPathsFileExists) {
                    ##  At least one NT ETM .paths file exists.
                    eprint("No .paths file found  in ETM runs\n");
                }
    
                if (!$ntEtmSavedSessionExists) {
                    ##  At least one NT ETM .paths file exists.
                    eprint("No saved session directory found for NT ETM runs\n");
                }
    
    
    
                if (@missingNtReports > 0) {
                    ##  There are some missing NT reports
                    eprint("Missing NT report files:");
                    if (@okNtReports == 0) {
                        iprint("  ALL")
                    } else {
                        nprint(":\n");
                        dumpList(\@missingNtReports, "\t");
                    }
                }
    
    #    if (!$someReportsMacro) {
    #        ## No report files found
    #        eprint("No .rpt files found in any NT internal run\n");
    #    }
    #    else {
    #        if (!$allReportsMacro) {
    #        eprint("Complete set of .rpt files not found for any one NT internal run\n");
    #        }
    #    }
    
            }
    
            ##  Handle internal timing collateral.
            ##  Internal runs are expected if NT libs were found, or if explicitely forced via option or project variable.
            if ($isNtMacro || $hasInternalTiming{$macroName}) {
    
                iprint("Internal timing runs expected\n");
                if (!$someNtIntLogs) {
                    eprint("No internal NT logs found\n");
                }
                elsif ($someNtIntLogs && !$allNtIntLogs) {
                    ##  Some missing etm logs
                    eprint("Missing NT Internal logs:\n");
                    dumpList(\@missingNtIntLogs, "\t");
                    $logError = 1;
                } else {
                    iprint("NT Internal logs present\n");
                }
    
                if (!$someNtVariationParameter) {
                    eprint("POCV variation coefficients files are missing\n");
                }
                elsif ($someNtVariationParameter && !$allNtVariationParameter) {
                    ##  Some missing etm logs
                    eprint("Missing POCV variation coefficients files:\n");
                    dumpList(\@missingSetupLogs_new, "\t");
                    $logError = 1;
                } else {
                    iprint("POCV variation coefficients files are present\n");
                }

                ##  Presence of at least one excluded_Xld_nets.sorted
                if (!$ntIntExcludedNetsExists) {
                    eprint("No $macroName.excluded_Xld_nets.sorted found for any NT internal run\n");
                } else {
                    iprint("$macroName.excluded_Xld_nets.sorted found\n");
                }
    
                ##  Presence of at least one transistors_not_annotated_all
                if (!$ntIntXtorNotAnnotated) {
                    eprint("No transistors_not_annotated_all file found for any NT internal run\n");
                } else {
                    iprint("transistors_not_annotated_all file found\n");
                }
    
                ##  Presence of at least one saved session dir
                if (!$ntIntSavedSessionExists) {
                    eprint("No saved session dir found for any NT internal run\n");
                } else {
                    iprint("Saved session dir found\n");
                }
            }
    
#            my $hasTiming=0;
    
            if ($qualCheckRoot) {
                checking_quality_checks($macroName, $metalStack, 
                    $nocompilecheck, $qualCheckRoot, $hasSetupHold, $nonDI,
                    $hasTiming, $busesExist );
            }
    
            nprint "\n";
            iprint("------------------------------------------------------------------------------------------------------------------\n");
            if ($macroLogs) {
                ##  Figure out where to put the macro log in p4.
                my @timingTypeList = Tokenify($TimingType{$macroName});
                if (@timingTypeList > 1) {
                    wprint("Collateral found in multiple locations: {@timingTypeList}.  Log will be checked in under each.\n");
                }
    
                #  If multiple timingTypes are found, check in log in multiple places.    
                #    if ((($timingType eq "sis") || ($timingType eq "nt") || ($timingType eq "libgen"))) 
                #close LOG;
                foreach my $timingType (@timingTypeList) {
                    if ($p4Logs) {
                        if ( ! defined $logFileName ){
                            eprint("$timingType: \$logFileName is not defined!\n");
                            next;
                        }

                        my $p4Dir = "$timingRootP4/$timingType/$macroName";
                        my $p4Log = "$p4Dir/$logFileName";
                        iprint("Logfile P4 = $p4Log\n");
                        if ( $TESTMODE ){
                            iprint("TESTMODE: p4 sync \$p4Log 2> /dev/null\n");
                        } else {
                            my ($stdout, $status) = run_system_cmd("p4 sync $p4Log 2> /dev/null");
                        }

                        my $x = `p4 where $p4Log`;
                        if ( $x eq "" ){
                            eprint("$timingType: p4 where '$p4Log' failed to find anything!\n");
                            next;
                        }

                        my @o = split(/\s+/, $x);
                        my $clientLog = $o[2];
                        iprint("Logfile client = $clientLog\n");
                        ##  abs_path won't nefcessarly work for this because the dir may not exist.
                        ##  "dirname" just parses the full name.
                        my $clientPath = dirname($clientLog);
                        if (-e $clientLog) {
                        ##  Log file exists.
                        ##  See if file is open anywhere.
                            my $x = `p4 opened -a $clientLog 2> /dev/null`;
                            if ($x ne "") {
                                ##  File is open somewhere.
                                wprint("Cannot write $p4Log; \"$x\n");
                                $clientLog = undef;
                            } else {
                                ## Log exists, and is not opened.  See if it's in p4
                                my $x = `p4 have $clientLog 2> /dev/null`;
                                if ($x eq "") {
                                    ## File exists, but not added.
                                    unlink $clientLog;
                                    run_system_cmd("p4 add -t text $p4Log", $VERBOSITY);
                                } else {
                                    ##  File exists, in p4.  sync and edit
                                    run_system_cmd("p4 sync $clientLog", $VERBOSITY);
                                    run_system_cmd("p4 edit $clientLog", $VERBOSITY);
                                }
                            }
                        } else {
                            ##  Client log does not exist.
                            if (!(-e $clientPath)) {run_system_cmd("mkdir -p $clientPath", $VERBOSITY)}
                            run_system_cmd("p4 add -t text $p4Log", $VERBOSITY);
                        }
                        #close LOG;
                        ## Copy log to client file.
                        if ($clientLog) {
                            copy($logFileName, $clientLog);
                            run_system_cmd("p4 submit -d \"$p4Description\" $clientLog", $VERBOSITY);
                        }
                    }
                }
            }
        }
    
        if($loggingDeferred) {
            write_stdout_log( $LOGFILENAME );
            $STDOUT_LOG   = EMPTY_STR;
        }
    
    } # foreach macroName in macroList
    
    if(defined $logFile) {
        write_stdout_log( $LOGFILENAME ); 
    }
    
    exitApp();
} # end of Main

# New function to check just existence and flashing message 
#
# Globals:
#     $timingRootP4
#
sub checkexistence($){
   print_function_header();

    my $file_name= shift;
    my $timing_root = shift;

    if (checkFile($file_name, undef, undef, undef)){
        iprint("$timingRootP4/$file_name found \n");
    } elsif ($file_name=~m/sis\/common_source\/commonSetup.tcl/){
        iprint("sis not run with Standard characterization Methodology for $file_name \n");
    } else {
        eprint("$timingRootP4/$file_name not found \n");
    }
}

# Globals:
#     $uiArg
#
sub checkPlotArcsCsv {
   print_function_header();
    my $file = shift;
    my $type = shift;  # "gold" or "iterative"

    iprint("Reading $file->{NAME}\n");
#    if ($file->{STATUS} == FILE_STALE) {
#    eprint("$file->{NAME} is stale\n");
#    }
    my $csvData = readPlotArcsCsv($file);
##  Check for presence of mismatched arcs
    if ($csvData->{mismatchedArcs}) {
##  Found the mismatched table
        if (exists($csvData->{mismatchedArcs}->{DATA})) {
            my $data = $csvData->{mismatchedArcs}->{DATA};
            if (@$data > 0) {
                my $n = @$data;
                eprint("$n mismatched arcs exist in $file->{NAME}\n");
            }
        }
    } else {
        eprint("\"Arc Mismatch Report\" missing from $file->{NAME}\n");
    }

##  Check for timing deltas.
    my $deltaThresh;
    if ($type eq "compare_gold") {$deltaThresh = 10}
    elsif ($type eq "compare_iterative") {$deltaThresh = 5}
    else {eprint("Internal error:  Unrecognized csv type \"$type\"\n"); $deltaThresh=0}
    my $deltaThreshFrac = $deltaThresh/100;
    if ($csvData->{mismatchedTiming}) {
##  Found the mismatched table
        my $hdr = $csvData->{mismatchedTiming}->{HDR};
        my $data = $csvData->{mismatchedTiming}->{DATA};
#        my @xxx = keys %$hdr;
        my @mismatcheErrors;
        if (@$data > 0) {
            my $n = @$data;
##  Mismatched timing exists.
            my $uiField = $hdr->{ui};
            my $deltaField = $hdr->{"absolute maximal difference"};
            my $deltaFrac;
            if ((defined $uiField) || (defined $uiArg)) {
                my @mismatchErrors = ();
                foreach my $d (@$data) {
                    my $ui = (defined $uiField) ? $d->[$uiField] : $uiArg;
                    my $delta = $d->[$deltaField];
                    $deltaFrac = sprintf("%.3f", $delta/$ui);

                    if ($deltaFrac > $deltaThreshFrac) {
                        my $x = join(",", @$d);  ##  Remake the line with commas so it resembles the original.
                        my $deltaPct = $deltaFrac*100;
                        $x = "\"$x\"   delta=$deltaPct%";
                        push @mismatchErrors, $x;
                    }
                }
                if (@mismatchErrors > 0) {
                    eprint("Timing mismatches greater that $deltaThresh% ($type) exist:\n");
                    foreach (@mismatchErrors) {iprint("\t$_\n")}
                }
            } else {
                eprint("ui is undefined for $file->{NAME}. Mismatched timing checks will be skipped\n");
            }
        } else {
            iprint("No mismatched timing data exists\n");
        }
    } else {
        wprint("No mismatched timing table exists\n");
    }
}

sub dumpCsvData {
   print_function_header();
    my $csv = shift;

    iprint("DUMPING CSV:\n");
    my @sections = qw(matchedArcs mismatchedArcs mismatchedTiming);
    foreach my $section (@sections) {
        iprint("\t$section:\n");
        my $tbl = $csv->{$section};
        my $hdr = $csv->{$section}->{HDR};
        foreach my $h (keys %$hdr) {
            iprint("$h=$hdr->{$h} ");
        }
        nprint("\n");
        foreach my $dat (@{$csv->{$section}->{DATA}}) {
            iprint("@$dat\n");
        }
    }
}

sub readPlotArcsCsv {
   print_function_header();
    my $csv = shift;

    my $matchedArcsCsvData = {};
    my $arcMismatchReportCsvData = {};
    my $timingDifferenceReportCsvData = {};
    my $currentData;
    my $topCsv = {};
    $topCsv->{matchedArcs} = $matchedArcsCsvData;
    $topCsv->{mismatchedArcs} =  $arcMismatchReportCsvData;
    $topCsv->{mismatchedTiming} = $timingDifferenceReportCsvData;

    my $fileNameP4 = "$timingRootP4/$csv->{NAME}";
    my $fileNameLoc = "$TMP/csv.tmp";
    exportP4File($fileNameP4, $fileNameLoc);
    #open (my $CSV, ,"$fileNameLoc");
    my @csv_contents = read_file( $fileNameLoc );
    my $state = 0;  ##  Searching for a table

    my $line;
#    while ($line = <$CSV>) {
    foreach my $line ( @csv_contents ){
        chomp $line;
        if ($line =~ /^List of matched arcs/i) {
            $currentData = $matchedArcsCsvData;
            $state = 1;
            next;
        }
        elsif ($line =~ /^arc mismatch report/i) {
            $currentData = $arcMismatchReportCsvData;
            $state = 1;
            next;
        }
        elsif ($line =~ /^Timing difference report/i) {
##  This line actually is the header.  
            $currentData = $timingDifferenceReportCsvData;
            $state = 1;
##  No next.  Allow to do the header parse below.
        }

        if ($state == 0) {
##  In state0, just looking for table.  If none of the above matched, continue loop
            next;
        }
        elsif ($state == 1) {
##  Should have a header line
            $line =~ s/\s*,\s*/,/g;  ##  Get rid of extra whitespace around commas
            $line = lc $line;  ##  Headers to lowercase.
            my @toks = split(/,/, $line);
            my $hdrHash = {};
            my $i = 0;
##  Build headerName to field hash
            foreach my $t (@toks) {$hdrHash->{$t} = $i++}
            $currentData->{HDR} = $hdrHash;
            $currentData->{DATA} = [];
            $state = 2;   ##  Read table.
            next;
        }
        elsif ($state == 2) {
            $line =~ s/\s+//g;  ##  Get rid of whitespace
            my $row = [];
            @$row = split(/,/, $line);
            if (@$row > 0) {push @{$currentData->{DATA}}, $row}
        }
    }

#    close $CSV;
    return $topCsv;
}

# Globals:
#   @pvtCorners
#
sub checkPvtQcLog($;$$) {
   print_function_header();
    my $dirP4 = shift;
    my $errorPatt = shift;
    my $passPatt = shift;

    if ((!defined $errorPatt) && (!defined $passPatt)) {
        wprint("Undefined pass and error patterns in checkPvtQcLog of $dirP4\n");
    }
    my %scoreboard;
    my @scoreboardKeys;
    foreach my $PVT (@pvtCorners) {$scoreboard{$PVT} = 0}

    iprint("Checking PVT logs in $timingRootP4/$dirP4\n");
    my $aref_logList = $timingDirs->{$dirP4};
    if ((!defined @$aref_logList) and (scalar(@$aref_logList)  == 0)) {
        eprint("No logs found for $timingRootP4/$dirP4\n");
        return;
    }
    foreach my $log (@$aref_logList) {
        iprint("Checking $timingRootP4/$log->{NAME}\n");
        foreach my $PVT (@pvtCorners) {
            if ($log->{NAME} =~ /_${PVT}/ || $log->{NAME} =~ /_${PVT}_/) {
                $scoreboard{$PVT} = 1; 
                last;
            }
        }
    }

    my $pvtComplete = 1;
    foreach my $PVT (@pvtCorners) {
        if (!$scoreboard{$PVT}) {
            eprint("Log for $PVT missing in $timingRootP4/$dirP4\n");
            $pvtComplete = 0;
        }
    }
    if ($pvtComplete) {
        iprint("Log found for all PVT's\n");
    }
}

sub checkSingleQcLog {
   print_function_header();
    my $logP4 = shift;
    my $errorPatt = shift;
    my $scoreBoardPatt = shift;  ##  patter to match indicating a particular lib was read.
    my $passPatt = shift;
    my $scoreBoardPrePatt = shift;   ##  A single pattern to pick out just the lines 


    iprint("Checking $timingRootP4/$logP4\n");
    my $log = checkFile($logP4);
    my $status = 1;
    if ($log) {
##  Log exists.
        if ($log->{STATUS} == $FILE_STALE) {
            eprint("Stale $logP4\n");
            $status = 0;
        }
        if (!checkGenericLog($log->{NAME}, $errorPatt, $scoreBoardPatt, $passPatt, $scoreBoardPrePatt)) {
            eprint("Errors exist in $timingRootP4/$logP4\n");
            $status = 0;
        }
    } else {
        eprint("Missing $timingRootP4/$logP4\n");
        $status = 0;
    }
    return 0;
}

sub checkGenericLog {
   print_function_header();
##  Check a generic log file for the presence of one or more error patterns
    my $fileNameP4 = shift;
    my $errPatt = shift;
    my $scoreBoardPatt = shift;  ##  patter to match indicating a particular lib was read.
    my $passPatt = shift;
    my $scoreBoardPrePatt = shift;   ##  A single pattern to pick out just the lines 

    my %scoreboard;
    my @scoreboardKeys;
    my $scoreboarding = 0;
    my $GLOG;
    if (defined $scoreBoardPatt) {
        foreach my $PVT (@pvtCorners) {
            my $p = $scoreBoardPatt;
            $p =~ s/{PVT}/$PVT/g;
            $scoreboard{$p} = 0;
        }
        my $scoreboarding = 1;
        @scoreboardKeys = keys %scoreboard;
    }

    $fileNameP4 = "$timingRootP4/$fileNameP4";  #  Add the p4 root
    my $fileNameLoc = "$TMP/log.tmp";
    unlink $fileNameLoc;
    exportP4File($fileNameP4, $fileNameLoc);
    my @glog_contents;
    my $rstatus = read_file_aref( $fileNameLoc, \@glog_contents );
    if (! $rstatus ){
        eprint("Export of $timingRootP4/$fileNameP4 failed\n");
        return 0;
    }
    my @errPattList;
    if (defined $errPatt) {
        my $errPattRef = ref $errPatt;
        if ($errPattRef eq "") {push @errPattList, $errPatt}  # scalar
        elsif ($errPattRef eq "ARRAY") {push @errPattList, @$errPatt}
        else {eprint("Unhandled type \"$errPattRef\" for errPatt in checkGenericLog\n"); return 0}
    }
    if ((@errPattList == 0) && !(defined $passPatt)) {wprint("Undefined error and pass patterns in checkGenericLog of $fileNameP4\n")}
    my $OK = 1;
    my $passing = (defined $passPatt) ? 0 : 1;
#    while (<$GLOG>) {
    foreach my $line ( @glog_contents ){
        foreach my $p (@errPattList) {
            if ($line =~ m/$p/) {$OK = 0}
        } 
        if (defined $passPatt) {
            if ($line =~ m/$passPatt/) {$passing = 1}
        }
        if (defined $scoreBoardPrePatt) {
            if (! ($line =~ m/$scoreBoardPrePatt/)) {next}
        }
        foreach my $k (@scoreboardKeys) {
            if ($line =~ m/$k/) {
                $scoreboard{$k} = 1;
            }
        }
    }
##  Made it through the log without matching an error pattern.  All good.

    foreach my $k (@scoreboardKeys) {
        if (!$scoreboard{$k}) {
##  Some entry was missing.
            eprint("Reference \"$k\" was missing from $fileNameP4\n");
            $OK = 0;
        }
    }
#    close $GLOG;
    unlink $fileNameLoc;
    return ($passing && $OK);
}

sub CheckRequiredArg
{
   print_function_header();
    my $argName = shift;
    my $argValue = shift;

    if (defined $argValue) {return 1}
    eprint("Required argument \"$argName\" not provided\n");
    return 0;
}

sub CheckRequiredFile
{
   print_function_header();
    my $fileName = shift;

    if (defined $fileName) {
        if (-r $fileName) {
            return 1;
        } else {
            eprint("Required file \"$fileName\" is not readable\n");
            return 0;
        }
    } else {
        eprint("Required file variable is undefined\n");
        return 0;
    }

}

sub Tokenify
{
## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = shift;
    $line =~ s/^\s*(.*)\s+$/$1/;
    return split(/\s+/, $line);
}

sub checkFile {
##  Check for the existence of a P4 file and check date against reference datetime
   print_function_header();
    my $fileName    = shift;
    my $okList      = shift;
    my $missingList = shift;
    my $staleList   = shift;

    my $rec;
    if ( exists $globalTimingFiles->{"$fileName"}) {
##  File exists.
        $rec = {};
        $rec->{NAME} = $fileName;
        my $fileRec = $globalTimingFiles->{"$fileName"};
        $rec->{DATA} = $fileRec;
        my ($date,$status) = run_system_cmd("date '+%d.%m.%Y %T' -d '-30 Days'", $VERBOSITY);
        my ($mday,$mon,$year,$hour,$min,$sec) = split(/[\s.:]+/, $date);
        my $timeEpoch = timelocal($sec,$min,$hour,$mday,$mon-1,$year);

        if ($fileRec->{CMPDATETIME} > $timeEpoch) {
            $rec->{STATUS} = $FILE_OK;
            if ($okList) {
                push( @$okList, $fileRec);
            }
        } else {
            $rec->{STATUS} = $FILE_STALE;
            if ($staleList) {
                push @$staleList, $rec; 
            } else {
                eprint("$fileName is stale\n");
            }
        }
    } else {
        $rec = undef;
        if ($missingList) {
            push @$missingList, $fileName;
        }
    }

    print_function_footer();
    return $rec;
}

sub dumpList {
   print_function_header();
    my $list = shift;
    my $prefix = shift;
    foreach my $x (@$list) {iprint("$prefix$x\n")}
}

sub dumpListFilerec {
   print_function_header();
    my $list = shift;
    my $prefix = shift;
    foreach my $x (@$list) {iprint("$prefix$x->{NAME}\n")}
}

sub checkNtLogs {
##  Checks NT logs for errors
   print_function_header();

    my $errFree = 1;
    foreach my $list (@_) {
        foreach my $file (@$list) {
            my $name = $file->{NAME};
            my $fileNameP4 = "$timingRootP4/$name";
            my $fileNameLoc = "$TMP/log.tmp";  ##  BOZO  set up a tmp area to use for temp files like this.
            unlink $fileNameLoc;
            exportP4File($fileNameP4, $fileNameLoc);
            my $foundDiag = 0;
            if (-r $fileNameLoc) {
                my @nlog_contents = read_file( $fileNameLoc );
                iprint("Checking $fileNameP4\n");
                foreach (@nlog_contents){
                    if (/Diagnostic summary:/) {
                        $foundDiag = 1;
                        if (/(\d+)\s+errors/) {
##  Summary appears to flag errors.
                            eprint("Errors found in $fileNameP4\n");
                            $errFree = 0;
                        } else {
##  Appears to be error free.
                        }
                        last;
                    }
                }
                if (!$foundDiag) {
##  Failed to find the diagnostics.  Fail.
                }
            } else {
                eprint("Export of $fileNameP4 apears to have failed\n");
                eprint("Could not find diagnostic summary in $fileNameP4\n");
                $errFree = 0;
            }
        }
    }

    return $errFree;
}

sub checkSisLogs {
##  Checks SiS logs for errors
   print_function_header();

    my $errFree = 1;
    foreach my $list (@_) {
        foreach my $file (@$list) {
            my $name = $file->{NAME};
            my $fileNameP4 = "$timingRootP4/$name";
            my $fileNameLoc = "$TMP/log.tmp";  ##  BOZO  set up a tmp area to use for temp files like this.
            unlink $fileNameLoc;
            exportP4File($fileNameP4, $fileNameLoc);
            my $foundDiag = 0;
            if (-r $fileNameLoc) {
                iprint("Checking $fileNameP4\n");
                my @slog_contents = read_file( $fileNameLoc );
#                open (my $SLOG, ,"$fileNameLoc");
#                while (<$SLOG>) {
                foreach ( @slog_contents ){
                    if (/^Error:/) {
##  Found an error.
                        eprint("Errors found in $fileNameP4\n");
                        $errFree = 0;
                        last;
                    }
                }
#                close $SLOG;
                unlink $fileNameLoc;
            } else {
                eprint("Export of $fileNameP4 apears to have failed\n");
                eprint("Could not find diagnostic summary in $fileNameP4\n");
                $errFree = 0;
            }
        }
    }

    return $errFree;
}

sub exportP4File {
   print_function_header();
##  Exports a P4 file
    my ($p4File, $localFile) = @_;

    my @o = `p4 print -o $localFile $p4File`;

}

sub exitApp {
   print_function_header();
    my $end = shift;
##  clean up tmp area.
    if (-e $TMP) {
        run_system_cmd("rm -rf $TMP", $VERBOSITY);
    }
#    close LOG;
    if($end) {
        exit 1;
    } else {
        exit;
    }
}

sub checkBusAndTimingExistence {
    print_function_header();

    my $libList      = shift;

    my $hasBus       = 0;
    my $hasTiming    = 0;
    my $hasSetupHold = 0;

    foreach my $lib (@$libList) {
        my $fileNameP4 = "$timingRootP4/$lib->{NAME}";
        my $fileNameLoc = "$TMP/lib.tmp";
        exportP4File($fileNameP4, $fileNameLoc);
        my @lines = read_file( $fileNameLoc );

##  Search each lib for the presence of a bus group.
        foreach my $line ( @lines ){
            if( $line =~ m/^\s*bus\W/    ){ $hasBus = 1;    }
            if( $line =~ m/^\s*timing\W/ ){ $hasTiming = 1; }
            if( $line =~ m/^\s*timing_type\s+:\s+(setup|hold)/ ){ $hasSetupHold = 1; } 
            if ($hasBus && $hasTiming && $hasSetupHold) {
## Found all. Bail.
                return (1,1,1);
            }
        }
    }
    print_function_footer();
    return ($hasBus,$hasTiming,$hasSetupHold);
}

# sub dirname {
#     my $file = shift;
#     my @x = split(/\//, $file);
#     pop @x;
#     my $path = join"/", @x;
#     return $path;
# }

sub checkNTmanagerLog {
   print_function_header();
    my $ntManagerLog = shift;

    my @pattList = (
        ["OK REDUCTION is YES", 0],
        ["OK EXTRACTION is RC", 0],
        ["OK INSTANCE_PORT is SUPERCONDUCTIVE", 0],
        ["OK POWER_EXTRACT is DEVICE_LAYERS", 0]
    );

    my $p4LogName = $ntManagerLog;
    my $ntManager =(split "/",$ntManagerLog)[-1];
    my $p4LogNameLoc = "$TMP/$ntManager";
    my $line;
    unlink($p4LogNameLoc);
    exportP4File($p4LogName, $p4LogNameLoc);
    my $filesize = -s $p4LogNameLoc;
    if ($filesize == 0) {
        fatal_error(" $p4LogNameLoc empty\n", 1);
    }    
    if (-e $p4LogNameLoc) {
        my @lines = read_file( $p4LogNameLoc );
        foreach my $line ( @lines ){
            #print( $line);
            foreach my $patt (@pattList) {
                if ($line =~ m/$patt->[0]/){
                    $patt->[1] = 1;
                }
            }
        }
    } else {
        fatal_error("Failed to export $p4LogName to $p4LogNameLoc\n", 1);
    }

    my @errs;
    foreach my $rec (@pattList) {
        if (!$rec->[1]) {push @errs, $rec->[0]}
    }
    if (@errs > 0) {
        eprint("The following missing from $ntManagerLog:\n");
        foreach my $err (@errs) {nprint("\t$err\n")}
    } else {
        iprint("$ntManagerLog CLEAN\n");
    }
    unlink($p4LogNameLoc);
}

sub process_log_file($$$$){
    print_function_header();
    my $p4Description = shift;
    my $timingRootP4  = shift;
    my $timingType    = shift;
    my $macroName     = shift;
    
    my $runstat;
    my $stdout;

    my $logFileName = "alphaVerifyTimingCollateral_${macroName}.log";
    my $p4Dir = "$timingRootP4/$timingType/$macroName";
    my $p4Log = "$p4Dir/$logFileName";

    ($stdout, $runstat) = run_system_cmd("p4 sync $p4Log 2> /dev/null") ;
    ($stdout, $runstat) = run_system_cmd("p4 where $p4Log");
    my $x = $stdout;
    unless( $x ) {
        eprint("process_log_file: 'p4 where' returned '$x'\n");
        return;
    }

    my @o = split(/\s+/, $x);
    my $clientLog = $o[2];
    iprint("Logfile client = $clientLog\n");
    ##  abs_path won't nefcessarly work for this because the dir may not exist.
    ##  "dirname" just parses the full name.
    my $clientPath = dirname($clientLog);
    if (-e $clientLog) {
        ##  Log file exists.
        ##  See if file is open anywhere.
        # nolint backticks
        ($x, $runstat) = run_system_cmd( "p4 opened -a $clientLog 2> /dev/null" );
        if ($x ne "") {
            ##  File is open somewhere.
            wprint("Cannot write $p4Log; \"$x\n");
            $clientLog = undef;
        } else {
            ## Log exists, and is not opened.  See if it's in p4
            ($x, $runstat) = run_system_cmd(  "p4 have $clientLog 2> /dev/null" );
            if ($x eq "") {
                ## File exists, but not added.
                unlink $clientLog;
                ($stdout, $runstat) = run_command("p4 add -t text $p4Log");
            } else {
                ##  File exists, in p4.  sync and edit
                ($stdout, $runstat) = run_command("p4 sync $clientLog");
                ($stdout, $runstat) = run_command("p4 edit $clientLog");
            }
        }
    } else {
        ##  Client log does not exist.
        my $number_of_dirs = make_path( $clientPath, { error => \my $err} ); # like mkdir -p
        if ( ! -e $clientPath ){
            eprint("process_log_file: Tried but unable to create the dirpath '$clientPath'\n");
            if ( $err && @$err ){
                for my $diag (@$err){
                    my ($file, $message) = %$diag;
                    if ( $file eq '') {
                        eprint("process_log_file:make_path: general error: $message\n");
                    } else {
                        eprint("process_log_file:make_path: problem $file: $message\n");
                    }
                }
            }
            return;
        }
        ($stdout, $runstat) = run_command("p4 add -t text $p4Log" );
    }

    ## Copy log to client file.
    if ($clientLog) {
        # copy sourceFile to destinationfile
        if ( -e $logFileName ) {
            copy($logFileName, $clientLog);
            ($stdout, $runstat) = run_command("p4 submit -d \"$p4Description\" $clientLog" );
        } else {
            eprint("Log file does not exist '$logFileName'\n");
        }
    }

    return;
}

# This run_command() subroutine is a shell around the call to run_system_cmd.
# It's used to check if -dryrun is being used or not. If -dryrun was
# specified, then just print out what it would have done but don't really
# do it.
#
sub run_command($){
    my $cmd = shift;
    if ( $main::TESTMODE ){
        sprint("TESTMODE: $cmd\n");
        return ("",0);
    }

    my ($stdout, $status) = run_system_cmd( $cmd );
    return ($stdout, $status);
}

sub process_pvt_corners(){
    print_function_header();

    # readonly arguments passed in
    my $aref_pvtCorners = shift;
    my $macroName       = shift;
    my $metalStack      = shift;
    my $sis             = shift;
    my $nt              = shift;

    # modifiable arguments passed in 
    my $aref_staleLibs      = shift;
    my $aref_staleMisc      = shift;
    my $sref_hasLibsNoms    = shift;
    my $sref_hasLibsMs      = shift;
    my $aref_staleRpts      = shift;
    my $sref_ntIntExcludedNetsExists  = shift;
    my $sref_ntEtmSavedSessionExists  = shift;
    my $sref_ntEtmPathsFileExists     = shift;
    my $sref_someNtVariationParameter = shift;
    my $sref_allNtVariationParameter  = shift;
    my $sref_ntIntXtorNotAnnotated    = shift;
    my $sref_ntIntSavedSessionExists  = shift;

    my $sref_allSisLibs     = shift;
    my $sref_someSisLibs    = shift;
    my $aref_okSisLibs      = shift;
    my $aref_missingSisLibs = shift;

    my $sref_allSisLibsNoms     = shift;
    my $sref_someSisLibsNoms    = shift;
    my $aref_okSisLibsNoms      = shift;
    my $aref_missingSisLibsNoms = shift;

    my $sref_allSisPvtLogs  = shift;
    my $sref_someSisPvtLogs = shift;
    my $aref_okSisLogs      = shift;
    my $aref_missingSisLogs = shift;
    my $aref_staleSisLogs   = shift;

    my $sref_allNtLibs     = shift;
    my $sref_someNtLibs    = shift;
    my $aref_okNtLibs      = shift;
    my $aref_missingNtLibs = shift;
    my $aref_staleNtLogs   = shift;

    my $sref_allNtLibsNoms     = shift;
    my $sref_someNtLibsNoms    = shift;
    my $aref_okNtLibsNoms      = shift;
    my $aref_missingNtLibsNoms = shift;

    my $sref_allNtEtmLogs     = shift;
    my $sref_someNtEtmLogs    = shift;
    my $aref_okNtEtmLogs      = shift;
    my $aref_missingNtEtmLogs = shift;

    my $sref_allNtIntLogs     = shift;
    my $sref_someNtIntLogs    = shift;
    my $aref_okNtIntLogs      = shift;
    my $aref_missingNtIntLogs = shift;

    my $aref_okNtReports      = shift;
    my $aref_missingNtReports = shift;
   
    my $sref_allLibgenLibs     = shift;
    my $sref_someLibgenLibs    = shift;
    my $aref_okLibgenLibs      = shift;
    my $aref_missingLibgenLibs = shift;

    my $sref_allLibgenLibsNoms     = shift;
    my $sref_someLibgenLibsNoms    = shift;
    my $aref_okLibgenLibsNoms      = shift;
    my $aref_missingLibgenLibsNoms = shift;

    my $aref_okSetupLogs_new   = shift;
    my $aref_missingSetupLogs_new = shift;
    my $aref_staleMisc_new = shift;
    
    my $sref_someReportsMacro  = shift;
    my $sref_allReportsMacro   = shift;

    foreach my $pvt (@$aref_pvtCorners) {
        ##  Logs
        #    if ($sisLog =   checkFile("sis/$macroName/run_char_${pvt}.log", $aref_okSisLogs, $aref_missingSisLogs, $aref_staleSisLogs)) {$someSisPvtLogs = 1} else {$allSisPvtLogs = 0}
        my ($ntEtmLog, $sisLog, $sisLib, $sisLibPG, $ntLib, $ntLibPG, $libgenLib, $libgenLibPG, $ntIntLog);
        ## This will show whether the variation.rpt file is present or not, JIRA number P10020416-35101
        my ($ntVariationrptlog_int, $ntVariationrptlog_etm);
    
        my ($sisLVFcsv, $ntLVFcsv, $sisLVFsummarycsv, $ntLVFsummarycsv, $sisLVFreport, $ntLVFreport);
    
        if ($sisLog   = checkFile("$sis/$macroName/char_${pvt}/siliconsmart.log", $aref_okSisLogs, $aref_missingSisLogs, $aref_staleSisLogs) ) {
            $$sref_someSisPvtLogs = 1; } else{ $$sref_allSisPvtLogs = 0; }

        if ($ntEtmLog              = checkFile("$nt/$macroName/timing/Run_${pvt}_etm/timing.log",                 $aref_okNtEtmLogs, $aref_missingNtEtmLogs, $aref_staleNtLogs)) {
            $$sref_someNtEtmLogs = 1} else {$$sref_allNtEtmLogs = 0}
        if ($ntIntLog              = checkFile("$nt/$macroName/timing/Run_${pvt}_internal/timing.log",            $aref_okNtIntLogs, $aref_missingNtIntLogs, $aref_staleNtLogs)) {
            $$sref_someNtIntLogs = 1} else {$$sref_allNtIntLogs = 0}
        if ($ntVariationrptlog_int = checkFile("$nt/$macroName/timing/Run_${pvt}_internal/variation.rpt",         $aref_okNtIntLogs, $aref_missingNtIntLogs, $aref_staleNtLogs)) {
            $$sref_someNtIntLogs = 1} else {$$sref_allNtIntLogs = 0}
        if ($ntVariationrptlog_etm = checkFile("$nt/$macroName/timing/Run_${pvt}_etm/variation.rpt",              $aref_okNtIntLogs, $aref_missingNtIntLogs, $aref_staleNtLogs)) {
            $$sref_someNtIntLogs = 1} else {$$sref_allNtIntLogs = 0}

        dprint(HIGH, "***ATTENTION*** okSisLibs: about to call checkFile , this sets someSisLibs and I assume populates okSisLibs!\n");
        if ($sisLib = checkFile("$sis/$macroName/lib/${macroName}_${metalStack}_${pvt}.lib", $aref_okSisLibs, $aref_missingSisLibs, $aref_staleLibs)) {
            dprint(HIGH, "***  \$sisLib=True and the array okSisLibs,missingSisLibs or staleLibs  may have been updated by checkFile() call ***\n");
            $$sref_someSisLibs = 1; 
            dprint(HIGH, "\$\$sref_someSisLibs=1 checkFile:\n\t'$sis/$macroName/lib/${macroName}_${metalStack}_${pvt}.lib' \n"); 
            my $n_on_okSisLibs = @$aref_okSisLibs;
            dprint(HIGH, "****** HOW????   ***** nothing added to aref_okSisLibs!\n") if ( 0 == $n_on_okSisLibs );
            dprint(HIGH, "n_on_okSisLibs='$n_on_okSisLibs'\n");
        } else {
            $$sref_allSisLibs = 0;
        }

        if ($sisLibPG              = checkFile("$sis/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}_pg.lib", $aref_okSisLibs, $aref_missingSisLibs, $aref_staleLibs)) {
            $$sref_someSisLibs = 1} else {$$sref_allSisLibs = 0}

        if ($sisLVFcsv = checkFile("$sis/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}_lvf.csv", $aref_okSisLibs, $aref_missingSisLibs, $aref_staleLibs)) {$$sref_someSisLibs = 1} else {$$sref_allSisLibs = 0}
        if ($ntLVFcsv  = checkFile("$nt/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}_lvf.csv", $aref_okNtLibs, $aref_missingNtLibs, $aref_staleLibs)) {$$sref_someNtLibs = 1} else {$$sref_allNtLibs = 0}

        if ($sisLVFsummarycsv = checkFile("$sis/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}_summary.csv", $aref_okSisLibs, $aref_missingSisLibs, $aref_staleLibs)) {
            $$sref_someSisLibs = 1} else {$$sref_allSisLibs = 0}
        if ($ntLVFsummarycsv  = checkFile("$nt/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}_summary.csv",  $aref_okNtLibs,  $aref_missingNtLibs,  $aref_staleLibs)) {
            $$sref_someNtLibs = 1}  else {$$sref_allNtLibs = 0}


        if ($sisLVFreport = checkFile("$sis/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}.report", $aref_okSisLibs, $aref_missingSisLibs, $aref_staleLibs)) {
            $$sref_someSisLibs = 1} else {$$sref_allSisLibs = 0}
        if ($ntLVFreport  = checkFile("$nt/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}.report",  $aref_okNtLibs,  $aref_missingNtLibs,  $aref_staleLibs)) {
            $$sref_someNtLibs = 1}  else {$$sref_allNtLibs = 0}

        ##  Libs with metalstacks
        if ($ntLib       = checkFile("$nt/$macroName/lib/${macroName}_${metalStack}_${pvt}.lib",          $aref_okNtLibs,     $aref_missingNtLibs,     $aref_staleLibs)){
            $$sref_someNtLibs = 1}     else {$$sref_allNtLibs = 0}
        if ($ntLibPG     = checkFile("$nt/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}_pg.lib",    $aref_okNtLibs,     $aref_missingNtLibs,     $aref_staleLibs)){
            $$sref_someNtLibs = 1}     else {$$sref_allNtLibs = 0}
        if ($libgenLib   = checkFile("libgen/$macroName/lib/${macroName}_${metalStack}_${pvt}.lib",       $aref_okLibgenLibs, $aref_missingLibgenLibs, $aref_staleLibs)){
            $$sref_someLibgenLibs = 1} else {$$sref_allLibgenLibs = 0}
        if ($libgenLibPG = checkFile("libgen/$macroName/lib_pg/${macroName}_${metalStack}_${pvt}_pg.lib", $aref_okLibgenLibs, $aref_missingLibgenLibs, $aref_staleLibs)){
            $$sref_someLibgenLibs = 1} else {$$sref_allLibgenLibs = 0}

        ##  Libs without metalstacks
        if ($sisLib      = checkFile("$sis/$macroName/lib/${macroName}_${pvt}.lib",         $aref_okSisLibsNoms,    $aref_missingSisLibsNoms,    $aref_staleLibs) ) {
            $$sref_someSisLibsNoms = 1}    else {$$sref_allSisLibsNoms = 0}
        if ($sisLibPG    = checkFile("$sis/$macroName/lib_pg/${macroName}_${pvt}.lib",      $aref_okSisLibsNoms,    $aref_missingSisLibsNoms,    $aref_staleLibs) ) {
            $$sref_someSisLibsNoms = 1}    else {$$sref_allSisLibsNoms = 0}
        if ($ntLib       = checkFile("$nt/$macroName/lib/${macroName}_${pvt}.lib",          $aref_okNtLibsNoms,     $aref_missingNtLibsNoms,     $aref_staleLibs) ) {
            $$sref_someNtLibsNoms = 1}     else {$$sref_allNtLibsNoms = 0}
        if ($ntLibPG     = checkFile("$nt/$macroName/lib_pg/${macroName}_${pvt}_pg.lib",    $aref_okNtLibsNoms,     $aref_missingNtLibsNoms,     $aref_staleLibs) ) {
            $$sref_someNtLibsNoms = 1}     else {$$sref_allNtLibsNoms = 0}
        if ($libgenLib   = checkFile("libgen/$macroName/lib/${macroName}_${pvt}.lib",       $aref_okLibgenLibsNoms, $aref_missingLibgenLibsNoms, $aref_staleLibs) ) {
            $$sref_someLibgenLibsNoms = 1} else {$$sref_allLibgenLibsNoms = 0}
        if ($libgenLibPG = checkFile("libgen/$macroName/lib_pg/${macroName}_${pvt}_pg.lib", $aref_okLibgenLibsNoms, $aref_missingLibgenLibsNoms, $aref_staleLibs) ) {
            $$sref_someLibgenLibsNoms = 1} else {$$sref_allLibgenLibsNoms = 0}

        ## Existence of set_variation_parameters.tcl file under variation directory. Added with lvf related updates.
        if (checkFile("$nt/variation/timing/Run_${pvt}_etm/xtor_variations/set_variation_parameters.tcl",  
                $aref_okSetupLogs_new, $aref_missingSetupLogs_new, $aref_staleMisc_new)) {
            $$sref_someNtVariationParameter = 1;
        } else {
            $$sref_allNtVariationParameter = 0;
        }

        $$sref_hasLibsMs      = ($$sref_hasLibsMs          || $$sref_someNtLibs     || $$sref_someSisLibs     || $$sref_someLibgenLibs);
        $$sref_hasLibsNoms    = ($$sref_hasLibsNoms        || $$sref_someNtLibsNoms || $$sref_someSisLibsNoms || $$sref_someLibgenLibsNoms);
        $$sref_someNtLibs     = ($$sref_someNtLibsNoms     || $$sref_someNtLibs);
        $$sref_someSisLibs    = ($$sref_someSisLibsNoms    || $$sref_someSisLibs);
        $$sref_someLibgenLibs = ($$sref_someLibgenLibsNoms || $$sref_someLibgenLibs);

        ## Existence of at least one .paths file for etm
        if (checkFile("$nt/$macroName/timing/Run_${pvt}_etm/${macroName}_${metalStack}_${pvt}.paths", undef, undef, $aref_staleMisc)) {
            $$sref_ntEtmPathsFileExists = 1}

        ## Existence of at least one saved session in etm
        if ($timingDirs->{"$nt/$macroName/timing/Run_${pvt}_etm/${macroName}_${pvt}"}) {
            $$sref_ntEtmSavedSessionExists = 1}

        ##  Existence of at least one Run_<pvt>_internal/ <macro>.excluded_Xld_nets.sorted
        if (checkFile("$nt/$macroName/timing/Run_${pvt}_internal/${macroName}.edgerates.excluded_Xld_nets.sorted", undef, undef, $aref_staleMisc)) {
            $$sref_ntIntExcludedNetsExists = 1}

        ##  Existence of at least one Run_<pvt>_internal/transistors_not_annotated_all
        if (checkFile("$nt/$macroName/timing/Run_${pvt}_internal/transistors_not_annotated_all", undef, undef, $aref_staleMisc)) {
            $$sref_ntIntXtorNotAnnotated = 1}

        ## Existence of at least one saved session for internal
        if ($timingDirs->{"$nt/$macroName/timing/Run_${pvt}_internal/${macroName}_${pvt}"}) {
            $$sref_ntIntSavedSessionExists = 1}

        ##  Need exploded list of *.rpt for internal runs.
        my $someReports = 0;
        my $allReports  = 1;

        foreach my $rpt (@InternalReportFiles) {
            if (checkFile("$nt/$macroName/timing/Run_${pvt}_internal/$rpt", $aref_okNtReports, $aref_missingNtReports, $aref_staleRpts) ){
                $someReports = 1; }else{ $allReports = 0; }
        }
        if ($someReports) {$$sref_someReportsMacro = 1}
        if ($allReports ) {$$sref_allReportsMacro  = 1}
    } # foreach pvt in pvtCorners

    return;
} # process pvtCorners

sub process_arch($$$$) {
   print_function_header();
    my $arch      = shift;
    my $macroName = shift;
    my $aref_etm  = shift;
    my $aref_internal = shift;
    
    if ( $arch eq "PHY2.0_reverse_wrap" ) {
        if ( $macroName =~ m/lcdl/ ) {
            @$aref_etm=("etm/ddrphy_lcdl_0UI_hold_a0", "etm/ddrphy_lcdl_0UI_hold_a1", "etm/ddrphy_lcdl_0UI_setup" , "etm/ddrphy_lcdl_cal_0UI_hold_a0" , "etm/ddrphy_lcdl_cal_0UI_setup" , "etm/ddrphy_lcdl_clk2q" , "etm/ddrphy_lcdl_comb" , "etm/ddrphy_lcdl_glitch_hold","etm/ddrphy_lcdl_glitch_setup");
            @$aref_internal=("internal_timing/ddrphy_lcdl_calSR", "internal_timing/ddrphy_lcdl_deglitch");
        }
        if ( $macroName =~ m/bdl/ ) {
            @$aref_etm=();
            @$aref_internal=();
        }
    }
    if ( $arch eq "DDR54" ) {
        if ( $macroName =~ m/lcdl/ ) {
            @$aref_etm = ("etm/ddrphy_lcdl_byp_in_mpw_post", "etm/ddrphy_lcdl_byp_in_post", "etm/ddrphy_lcdl_cal_clk_en_post", "etm/ddrphy_lcdl_cal_clk_mpw_post" , "etm/ddrphy_lcdl_cal_en_post" , "etm/ddrphy_lcdl_cal_mode_post","etm/ddrphy_lcdl_cal_reset_post", "etm/ddrphy_lcdl_dly_in_en_post" , "etm/ddrphy_lcdl_dly_in_mpw_post" , "etm/ddrphy_lcdl_dly_in_post" , "etm/ddrphy_lcdl_dly_update_post");
            @$aref_internal = ("internal_timing/ddrphy_lcdl_calSR", "internal_timing/ddrphy_lcdl_deglitch_atpg");
        }
        if ( $macroName =~ m/bdl/ ) {
            @$aref_etm=();
            @$aref_internal=();
        }
    }
    if ( $arch eq "LPDDR54" ) {
        @$aref_etm = ( "etm/atpg_post","etm/byp_in_post", "etm/bypass_post" , "etm/bypin_mpw_post" , "etm/cal_post" , "etm/calclk_mpw_post" , "etm/dlyin_byp_post" , "etm/dlyin_mpw_post", "etm/etm_merge", "etm/mission_post" , "etm/wckin_byp_post" , "etm/wckin_mpw_post" );
        @$aref_internal =("internal_timing/atpg_mode", "internal_timing/cal_mode" );
    }
    if ( $arch eq "FullyNtPHY2.0" ) { 
        if ( $macroName =~ m/lcdl/ ) { 
            @$aref_etm = ("etm/ddrphy_lcdl_byp_mode", "etm/ddrphy_lcdl_cal_mode" , "etm/ddrphy_lcdl_clk2q_cal_en_out" , "etm/ddrphy_lcdl_clk2q_cal_out" , "etm/ddrphy_lcdl_etm_merge" , "etm/ddrphy_lcdl_mission_mode" , "etm/ddrphy_lcdl_test_mode" );
            @$aref_internal = ("internal_timing/ddrphy_lcdl_calibration" , "internal_timing/ddrphy_lcdl_deglitch" );
        } 
        if ( $macroName =~ m/bdl/ ) { 
            @$aref_etm = ("etm/ddrphy_bdl_byp_mode" , "etm/ddrphy_bdl_mission_mode" , "etm/ddrphy_bdl_etm_merge" );
            @$aref_internal = ();
        }
    }
    if ( $arch eq "PartialNtPHY2.0" && $macroName =~ m/lcdl/ ) {
        #print "*********** PartialNtPHY2.0 LCDL(NT for internal timing & libgen for etm generation) ***************\n";
        @$aref_etm = ("etm/synopsys/libgen/$macroName" );
        @$aref_internal = ("internal_timing/ddrphy_lcdl_calibration" , "internal_timing/ddrphy_lcdl_deglitch" );
    }
    if ( $arch eq "PartialNtPHY2.0" && $macroName =~ m/bdl/ ) {
        @$aref_etm = ("etm/synopsys/libgen/$macroName" );
        @$aref_internal = ();
    }

    return;
}

sub checking_quality_checks($$$$$$$$){
   print_function_header();
    my $macroName      = shift;
    my $metalStack     = shift;
    my $nocompilecheck = shift;
    my $qualCheckRoot  = shift;
    my $hasSetupHold   = shift;
    my $nonDI          = shift;
    my $hasTiming      = shift;
    my $busesExist     = shift;
    
    iprint("Checking quality checks\n");
    ##  Look for the quality checks

    ##  Check logs depending on which libs were found, with and/or without metalStack
    my $libPatt1 = "(${macroName}_${metalStack}_{PVT}.lib|${macroName}_{PVT}.lib)";
    my $libPatt  = "(${macroName}_${metalStack}_{PVT}_pg.lib|${macroName}_{PVT}_pg.lib)";

    if (!$nocompilecheck ){
        checkSingleQcLog("$qualCheckRoot/alphaCompileLibs/compile.log", "^Error:", $libPatt1, undef, "^Reading");
        checkSingleQcLog("$qualCheckRoot/alphaCompileLibs/compile_pg.log", "^Error:", $libPatt, undef, "^Reading");
    }

    if ($hasSetupHold ){
        &checkPvtQcLog("$qualCheckRoot/alphaLibCheckMonotonicSetupHold/MONOTONICLOGS", "^Non monotonic");
    } else {
        iprint("No setup/hold arcs; Skipping CheckMonotonicSetupHold\n");
    }
    checkSingleQcLog("$qualCheckRoot/alphaPinCheck/${macroName}_pincheck.log", "DIRTY", $libPatt) unless (defined $nonDI);

    ##  Check existence of .csv
    foreach my $pt ("compare_gold", "compare_iterative") {
        my $singleCsv = checkFile("$qualCheckRoot/alphaPlotArcs/$pt/${macroName}_report.csv");
        my (@okCsv, @missingCsv, @staleCsv);
        my $somePvtCsv = 0;
        my $allPvtCsv  = 1;
        foreach my $pvt (@pvtCorners) {
            if (checkFile("$qualCheckRoot/alphaPlotArcs/$pt/${macroName}_report_${pvt}.csv", \@okCsv, \@missingCsv, \@staleCsv) ){
                $somePvtCsv = 1;
            } else {
                $allPvtCsv = 0;
            }
        }

        ##  Report csv presence:
        if (!$singleCsv && !$somePvtCsv) {
            ##  no csv's found at all
            eprint("No csv found, $qualCheckRoot/alphaPlotArcs/$pt/${macroName}_report.csv or $qualCheckRoot/alphaPlotArcs/$pt/${macroName}_report_{PVT}.csv\n");
        } elsif ($somePvtCsv && !$allPvtCsv) {
            eprint("Missing csv's:\n");
            dumpList(\@missingCsv, "\t");
        }
        if ($singleCsv ){
            push @okCsv, $singleCsv;
        }
        foreach my $csv (@okCsv){
            checkPlotArcsCsv($csv, $pt);
        }
        @okCsv=();
    } # foreach pt

    ##  Liberty checks
    ##  Single logs:
    if ($hasTiming) {
        checkSingleQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkArc/checkArc.log", undef, undef, "Arc consistency passed");
    } else {
        wprint("Macro has no timing, skipping checkArc. macroName='${macroName}'\n");
    }
    if ($busesExist ){
        &checkPvtQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkBusOrder", "^Error:");
    } else {
        iprint( "No buses found in libs; Skipping checkBusOrder requirement\n");
    }

    checkSingleQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkDerate/checkDerate.log", 
        undef, undef, "Liberty Derate Attributes Verified");

    ##  Separate pvt logs
    &checkPvtQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkDuplicateAttributes", "^Error:");
    &checkPvtQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkMaxCap", "^Error:");
    &checkPvtQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkOperatingConditions", "^Error:");
    checkSingleQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkPt/checkPt.log", "^Error:");
    &checkPvtQcLog("$qualCheckRoot/msip_hipreLibertyCheck/used_files_checkTiming", "^Error:");

    ##  Gonzo
    #    &checkPvtQcLog("$qualCheckRoot/alphaLibertyCheck/listArc");
    #    &checkPvtQcLog("$qualCheckRoot/alphaLibertyCheck/listDerate"); 

    return;
} # checking_quality_checks

#------------------------------------------------------------------------------
# 
#------------------------------------------------------------------------------
sub process_cmd_line_args() {
   print_function_header();
    ## get specified args
    my( $opt_projSPEC, $timingRel, $macrosArg, $internalTimingMacrosArg, $metalStack, 
        $pvtCornersArg, $uiArg, $logFile, $nolog, $p4Description, $p4Logs, $opt_help, $arch, $nocompilecheck, 
        $nonDI, $lvf, $opt_verbosity, $opt_debug, $opt_nousage, $opt_dryrun);

    my $success = GetOptions(
    "project=s"                 => \$opt_projSPEC,
    "timingRel=s"               => \$timingRel,
    "macros=s"                  => \$macrosArg,
    "internalTimingMacros=s"    => \$internalTimingMacrosArg,
    "metalStack=s"              => \$metalStack,
    "pvtCorners=s"              => \$pvtCornersArg,
    "ui=s"                      => \$uiArg,
    "log=s"                     => \$logFile,
    "nolog"                     => \$nolog,
    "p4Description=s"           => \$p4Description,
    "p4Logs!"                   => \$p4Logs,
    "h"                         => \$opt_help,
    "help"                      => \$opt_help,
    "arch=s"                    => \$arch,
    "nocompilecheck"            => \$nocompilecheck,
    "nonDI"                     => \$nonDI,
    "lvf"                       => \$lvf,
    "verbosity=i"               => \$opt_verbosity,
    "debug=i"                   => \$opt_debug,
    "dryrun"                    => \$opt_dryrun,
    "nousage"                   => \$opt_nousage
    );

    ## Default values
    $p4Description = "alphaVerifyTimingCollateral" unless( defined $p4Description);
    $timingRel = "latest" unless( defined $timingRel);
    $nolog = 0 unless( defined $nolog);
    $p4Logs = 1 unless( defined $p4Logs);

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun  );

    ## quit with usage message, if usage not satisfied
    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    &usage(1) unless( defined $opt_projSPEC );

    return( $opt_projSPEC, $timingRel, $macrosArg, $internalTimingMacrosArg, $metalStack, 
            $pvtCornersArg, $uiArg, $logFile, $nolog, $p4Description, $p4Logs, $arch, $nocompilecheck, 
            $nonDI, $lvf, $opt_nousage);
}

#------------------------------------------------------------------------------
#  script usage message
#------------------------------------------------------------------------------
sub usage($) {
    my $exit_status = shift;

    iprint("Current script path:  $ScriptPath\n");
    pod2usage({
            -pathlist => "$RealBin",
            -exitval  => $exit_status,
            -verbose  => 1 });
}

__END__


=pod

=head1 SYNOPSIS

 ScriptPath/alphaVerifyTimingCollateral.pl \
        -project <project-id> \
        [-timingRel <timing-rel> \]
        [-macros <macro list> \]
        [-metalStack <metalStack spec \]
        [-pvtCorners <pvt corner list> \]
        [-ui <unit-interval \]
        [-log <logFile> \]
        [-nolog \]
        [-[no]p4Logs \]
        [-h, -help]


  This script is designed check the timing verification collateral for one or
  more macros.  In general, the necessary files are checked for 1) existence,
  2) freshness (compared to a defined reference date/time) and 3) cleanliness.
  See alphaVerifyTimingCollateral.txt in the same directory as this script for
  details on what is checked.  

  Information is provided both on the command-line as well as the project
  legalMacros.txt and legalRelease.txt (assumed to be in the project pcs/design
  dir).

  Written by John Clouser, john.clouser@synopsys.com.  Comments and suggestions
  are welcome.

=over 2

=item B<-h> B<-help>

 Prints this help

=item B<-project>

 The name of the project, specified as productName/projectName/projectRel.
 Example:  "ddr43/d523-ddr43-ss10lpp18/rel1.00".  Required.

=item B<-timingRel>

  Specifies the path from the project directory to pick up the collateral.  The
  path used is
  //wwcad/msip/projects/$productName/$projectName/$timingRel/design/timing/...

  By default, "timingRel" is "latest".  Optional

=item B<-macros>

 Specifies the list of macros to run the check on.  If more than one, a quoted,
 space-separated list should be used.  If not provided, the list from the
 project legalMacros.txt file is used. Optional.

=item B<-metalStack>

 The metal stack specification to be expected in the Liberty.  If not
 defined, uses the "metal_stack" variable from the project
 legalRelease.txt file. Must be defined one way or the other.

=item B<-pvtCorners>

 The list of pvt's to be used.  If not defined, uses the value from the
 "pvtCorners" variable in the project legalRelease.txt file.  If that's not
 defined, uses the value from the project Nanotime config 
 file ($MSIP_PROJ_ROOT/$project/design/timing/nt/ntFiles/alphaNT.config).  
 Must be defined in one of these.

=item B<-ui>

 Defines the unit interval, in ps, for the design.  This used to check for
 arc-timing-deltas in the alphaPlotArcs checks.  Note that there is an open
 request at present to get the ui number included in the csv files. If not
 defined one way or the other, an error results.

=item B<-log>

 The name of the log file for the run.  By default, a separate log is written
 for each macro, of the name alphaVerifyTimingCollateral_${macroName}.log.
 Specifying a log here will create just one.

=item B<-nolog> 

 Supresses creation of a log altogether.

=item B<-[no]p4Logs>

 [dis]enables checkin of logs to p4. By default, logs are checked into
 //wwcad/msip/projects/$productName/$projectName/$timingRel/design/timing/$timingType/$macroName,
 where "timingType" is one of nt, sis or libgen.

=cut
