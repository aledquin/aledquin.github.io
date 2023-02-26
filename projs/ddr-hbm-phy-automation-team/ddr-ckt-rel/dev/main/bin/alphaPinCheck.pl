#!/depot/perl-5.14.2/bin/perl
#
# History:
#   001 ljames 6/30/2022
#   Removed the unit_test() code. Not needed. Was added by ljames before he
#   understood how to do unit tests for stand-alone perl scripts.
#   002 wadhawan 2022-08-10 14:34:27
#   Removing unnecessary, commented code and replacing printMsg($item)
#   with dprint(CRAZY, $item)
use strict;
use warnings;
use Cwd;
use FindBin qw($RealBin $RealScript);
##  The current PERL5LIB causes issues.
#----------------------------------#
our $DEBUG     = 0;
our $VERBOSITY = 0;
our $TESTMODE  = 0;

#----------------------------------#
# RECOMMENDATIONS
#----------------------------------#
# 1.    If new print statements are being added to the code for the purposes of 
#       debugging then use dprint/vprint functions instead of commenting out 
#       code with print statements. This keeps the codebase clean and readable.
# 2.    Use dprint functions with CRAZY inside loops for debugging. 
# 3.    Use dprint functions with MEDIUM outside for loops for debugging. 
# 4.    Do not write 'return undef;' Simply return nothing. (Ex. return; )
#       An empty return is evaluated the same as False in all contexts (list 
#       and scalar )
#----------------------------------#

BEGIN {
    ##  There is a conflicting Verilog parser package buried inside a dir in PERL5LIB.  Need to remove these.
    ##  Deleting the PERL5LIB envvar here doesn't appear to work.
    ##  Got to be a better way.

    ##  Loop through PERL5LIB elements, and remove these from @INC
    if ( exists $ENV{'PERL5LIB'} ){
        my @pl = split(/:/, $ENV{'PERL5LIB'});
        my %h;
        my @newInc;
        foreach my $i (@INC) {
        if (!(grep {$i eq $_} @pl)) {
            push @newInc, $i;
        }
        }
        @INC = @newInc;
    }

#    foreach (@INC) {print "\t$_\n"}
    ##@INC = qw(/depot/perl-5.14.2/lib/site_perl/5.14.2/x86_64-linux /depot/perl-5.14.2/lib/site_perl/5.14.2 /depot/perl-5.14.2/lib/5.14.2/x86_64-linux /depot/perl-5.14.2/lib/5.14.2);
}

use Getopt::Long;
use File::Basename;
use File::Spec;
use File::Copy;
use Cwd;
use Cwd 'abs_path';
use Pod::Usage;

use Verilog::Netlist;
use Verilog::Getopt;
use Verilog::Language;
use Verilog::Parser;
use Verilog::Preproc;
use Liberty::Parser;
use Date::Parse; 
use Data::Dumper;
use File::Path qw(make_path remove_tree rmtree);
use Try::Tiny;
use Tk;

use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use lib "$RealBin/../lib/perl/";
use alphaHLDepotRelease;
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::P4;

#---- GLOBAL VARs------------------#
#our $STDOUT_LOG  =undef;   # Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Log msg to var => ON
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version();
our $USERNAME     = ""; # gets filled in later in Main()
our $LOGFILE      = undef;
our $TEMPDIR      = "/tmp";

#----------------------------------#

header;
END {
    local $?;   # to prevent the exit() status from getting modified
    footer;
    write_stdout_log( $LOGFILENAME ); 
}

##  Get path to script.
my @toks = split(/\//, $0);
pop (@toks);
my $ScriptPath = "";
foreach (@toks) {$ScriptPath .= "$_/"}
$ScriptPath = abs_path($ScriptPath);
$ScriptPath = "\$MSIP_SHELL_LEF_UTILS/utils/";

my $MAXLIBDELAY = 2e-9;  ##  Delays greater than this get flagged.
my $MINLIBDELAY = 0;     ##  Delays less than this get flagged.
my $MAXLIBTRAN  = 1e-9;  ##  Delays greater than this get flagged.
my $MINLIBTRAN  = 0;     ##  Delays less than this get flagged.
my $MINSnH      = -1e-9; ##  Setup/hold less than this get flagged.
my $MAXSnH      = 1e-9;  ##  Setup/hold greater than this get flagged.

##  Globals
our @g_ContextStack;
our @g_CurrentStack;
our $g_Current = undef;
our $g_CurrentPin = undef;
our @g_BoundaryLayerList; 
our $g_verilogmodule  = undef;
our $g_LefMacro;
our $g_LefCurrentLayer = undef;
our $g_EnableTableChecks = 0;
our $g_BoundaryLayer  = "62:21 108:0";
our $g_OptVflag       = 0;
our $g_LefVsGdsMap    = undef;
our $g_VerilogDefines = undef;
our $g_VerilogInclude = undef;
our $g_VerilogIncludeFiles = undef;
our $g_opt_macros     = undef;
our $g_TypeDefined    = undef;
our $g_StateObs       = undef;
our $g_StatePin       = undef;
our $g_Context        = undef;
our $g_LefMacroFound  = undef;
our %g_PinHashMerged;
our %g_LefData;
our %g_LvGlayerMap;         ##  Maps gds layers to names
our %g_LvGlayerMapReverse;  ##  Maps names back to layer numbers.
our @ignoreDatatypeList ;
our %g_PinHash;
our %g_InterfaceHash;         ##  Stores pins for Interface files (.v)
our $g_InterfacePinCount = 0;
our %g_streamLayerMap;
our @g_ViewList;
our $g_ViewIdx = 0;
our $LefArea;
our $LefBbox;
our $LefAreaNR = 0;
our %TypeCount;
our %textOfMetal;
our @g_LefVsGdsMapPairs;
our $g_LefLayersHash;
our $g_LefObsLayersHash;
our @g_LefGeomList;  ##  Global list to store LEF pin geometries
## 6/1/2022 ljames -- comment out this global; it's never used! subroutine ReadGds() 
##          mentions GdsGeomList but uses the 'my' keyword which creates a local
##          variable of the same name. But is a ref to an array and not as mentioned
##          here, an array.
## our @GdsGeomList;  ##  Global list to store GDS pin geometries
##  These globals are used to track the type of brackets in use for a given view.
##  This enables a view-wide bracket check, rather than failing name-by-name
our $g_SquareBracket;
our $g_PointyBracket;
our %g_isPgPin;
our $g_FileName; # to store filename when creating a pin where the filename can not be gotten
my %LefCallbacks = (
 "BUSBITCHARS"         => \&BUSBITCHARS_callback,
 "CLASS"               => \&CLASS_callback,
 "DIRECTION"           => \&DIRECTION_callback,
 "DIVIDERCHAR"         => \&DIVIDERCHAR_callback,
 "END"                 => \&END_callback,
 "FOREIGN"             => \&FOREIGN_callback,
 "LAYER"               => \&LAYER_callback,
 "MACRO"               => \&MACRO_callback,
 "OBS"                 => \&OBS_callback,
 "ORIGIN"              => \&ORIGIN_callback,
 "PIN"                 => \&PIN_callback,
 "PORT"                => \&PORT_callback,
 "PROPERTYDEFINITIONS" => \&PROPERTYDEFINITIONS_callback,
 "RECT"                => \&RECT_callback,
 "POLYGON"             => \&POLY_callback,
 "SITE"                => \&SITE_callback,
 "SIZE"                => \&SIZE_callback,
 "SYMMETRY"            => \&SYMMETRY_callback,
 "USE"                 => \&USE_callback,
 "SHAPE"               => \&SHAPE_callback,
 "PROPERTY"            => \&PROPERTY_callback,
 "VERSION"             => \&VERSION_callback,
 );

# In order to perform unit testing on the subroutines in this script we must
# have this 'unlesss caller()' here as you see. Please don't remove it.

&Main() unless caller() ;

#------------------------------------------------------------------------------
# Start Main 
#------------------------------------------------------------------------------
sub Main(){
    my %IsLegalObsLayer;
    my %IsLegalPinLayer;
    my (@verilogNopg, @verilog);
    my (@libertyNopg, @liberty);
    my (@lef, @cdl, @gds, @oas);
    my @pinCSV;
    my $dumppins = 0;
    my $legalLayers  = undef;
    my $lefPinLayers = undef;
    my $lefObsLayers = undef;
    my $checkTiming  = 0; ## Enable lib timing checks.
    my $ignoreDatatype = "";  ## Datatypes to ignore when reading gds pins. 
                              ## Currently have a problem with 
                              ## msip_hipreGDSIICellPinInfo interpreting voltage 
                              ## markers as pin labels.
    my ($PGlayers, $streamLayermap, $since );
    my $auto=0;
    my $p4Auto  = undef;
    my $dateRef = "CDATE";  ##  Use CDATE (creation date) field for -since comparison
    my $pcsTech   = undef;
    my $physCheck = 0;
    my $logFile   = undef;
    my $pgPinsArg = undef;
    my @gcsv;
    my ($opt_nousage, $opt_help, $opt_debug, $opt_verbosity );
    my ($opt_tech, $opt_docx, $opt_p4ws, $opt_unit_test, $opt_pcs, $opt_ctl );
    my ($bracketArg, $opt_nolog );
    my $opt_append_to_log = 0;

    $USERNAME = get_username(); 

    ShowUsage(1) unless(@ARGV);

    my @orig_argv = @ARGV;   # keep this here cause GetOpts modifies ARGV
    my $success = GetOptions(
        "p4ws=s"                 => \$opt_p4ws,
        "macros=s"               => \$g_opt_macros,
        "verilog=s@"             => \@verilog,
        "verilogNopg=s@"         => \@verilogNopg,
        "vmodule=s"              => \$g_verilogmodule,
        "verilogInclude=s"       => \$g_VerilogInclude,
        "verilogIncludeFiles=s"  => \$g_VerilogIncludeFiles,
        "verilogDefines=s"       => \$g_VerilogDefines,
        "pgPins=s"               => \$pgPinsArg,
        "liberty=s@"             => \@liberty,
        "libertyNopg=s@"         => \@libertyNopg,
        "cdl=s@"                 => \@cdl,
        "lef=s@"                 => \@lef,
        "gds=s@"                 => \@gds,
        "oas=s@"                 => \@oas,
        "pinCSV=s@"              => \@pinCSV,
        "dump!"                  => \$dumppins,
        "help"                   => \$opt_help,
        "layers=s"               => \$legalLayers,
        "lefPinLayers=s"         => \$lefPinLayers,
        "lefObsLayers=s"         => \$lefObsLayers,
        "boundaryLayer=s"        => \$g_BoundaryLayer,
        "checkTiming!"           => \$checkTiming,
        "ignoreDatatype=s"       => \$ignoreDatatype,
        "PGlayers=s"             => \$PGlayers,
        "streamLayermap=s"       => \$streamLayermap,
        "vflag"                  => \$g_OptVflag,
        "since=s"                => \$since,
        "auto!"                  => \$auto,
        "p4Auto=s"               => \$p4Auto,
        "dateRef=s"              => \$dateRef,
        "tech=s"                 => \$opt_tech,
        "lefVsGdsMap=s"          => \$g_LefVsGdsMap,
        "physCheck!"             => \$physCheck,
        "bracket=s"              => \$bracketArg,
        "log=s"                  => \$logFile,
        "appendlog"              => \$opt_append_to_log,
        "nolog"                  => \$opt_nolog,
        "pcs=s"                  => \$opt_pcs,
        "debug=i"                => \$opt_debug,
        "verbosity=i"            => \$opt_verbosity,
        "testmode"               => \$TESTMODE,
        "nousage"                => \$opt_nousage,
        "unitTest"               => \$opt_unit_test,
        "docx=s"                 => \$opt_docx,
        "ctl=s"                  => \$opt_ctl,
    );
    
    #dprint(NONE, "" .scalar(Dumper ). "\n" );
    #dprint(NONE, "lefPinLayers = $lefPinLayers \n" );
    #dprint(NONE, "lefObsLayers = $lefObsLayers \n" );
    #dprint(NONE, "lefVsGdsMap  = $g_LefVsGdsMap  \n" );
    #dprint(NONE, "tech         = $opt_tech         \n" );

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    #dprint(HIGH, "opt_debug     => DEBUG     -> '$opt_debug => $main::DEBUG    ' \n");
    #dprint(HIGH, "opt_verbosity => VERBOSITY -> '$opt_verbosity => $main::VERBOSITY' \n");

    ## quit with usage message, if usage not satisfied
    ShowUsage(0) if $opt_help;
    ShowUsage(1) unless( $success );

    if( defined $opt_unit_test && $opt_unit_test ){
        $g_opt_macros = "unit_test"      unless( defined $g_opt_macros );
        $logFile      = "${TEMPDIR}/$USERNAME" unless( defined $logFile      );
        $opt_nousage  = 1;
    }

    #    ShowUsage(1) if (!(defined $g_opt_macros));
    unless( $opt_nousage || $main::DEBUG ){
        utils__script_usage_statistics( $PROGRAM_NAME, $main::VERSION, \@orig_argv );
    }
    #dprint(MEDIUM, "cmd line options are ". join('\n',@orig_argv) . "\n");
    dprint_dumper(MEDIUM, "Passed cmd line options:\n", \@orig_argv);

    $g_verilogmodule = $g_opt_macros unless( defined $g_verilogmodule );
    
    #  ctl file processing
    if ( defined $opt_ctl ) {
        eprint("-ctl option has not yet been implemented\n\t-ctl '$opt_ctl'");
    }

    #  Compare circuit SPECs vs pininfo file(s); 
    my $pinCheckExe = "$RealBin/pin_check__ckt_specs.py";
    if( defined $opt_docx && @pinCSV ){
        my $any_errors = check_ckt_SPEC_vs_pininfo( $opt_docx, $pinCheckExe, \@pinCSV );
        fatal_error( "Errors detected while comparing SPEC vs pininfo...aborting.\n" ) if( $any_errors );
    }

    #------------------------------------------------------
    my $logging = 1;
    if( defined $logFile ){
        ##  Trim leading/trailing whitespace
        $logFile =~ s/^\s+//;
        $logFile =~ s/\s+$//;
        if (-e $logFile) {
            if (-d $logFile) {
                ##  An existing directory.
                $logFile = "$logFile/${g_opt_macros}_pincheck.log";
            }
            else {
                ##  Existing file. deleting existing file to make room for new file
                ##  but if the -appendlog option is used, then do not delete it.
   
                unlink $logFile unless( $opt_append_to_log );
            }
        }
        else {
            ##  A non-existent path.
            my ($filename, $dir, $suffix) = fileparse($logFile);

        #    print "  \"$filename\"  \"$dir\"\n";
            make_path($dir);
            $logFile = ($filename eq "") ? "$dir${g_opt_macros}_pincheck.log" : "$dir$filename";
        }
    }
    else {
        $logFile = "${g_opt_macros}_pincheck.log";
        if (-e $logFile) {
            ##deleting existing file to make room for new file 
            unlink $logFile unless( $opt_append_to_log ); 
        }
    }
    iprint "Logging to $logFile\n";

    $LOGFILE = $logFile;
    $logging = 0 if( $opt_nolog );
    #------------------------------------------------------
    
    iprint "Current cell macro: $g_opt_macros\n";
    $g_BoundaryLayer =~ s/[.:]/_/g;  ###  Convert x.y or x:y to x_y to

    @ignoreDatatypeList = Tokenify($ignoreDatatype);

    if( defined $bracketArg ){
        $bracketArg = lc $bracketArg;
        if (($bracketArg ne "square") && ($bracketArg ne "pointy")&& ($bracketArg ne "any")) {
            die "Error:  Value for -bracket must be either \"square\" or \"pointy\" or \"any\"\n";
        }
    }

    my $now = localtime();
    iprint("Running $RealBin/$RealScript\n");
    iprint("Arguments:\n");
    foreach my $argvalue ( @orig_argv){
        nprint("\n\t") if ( $argvalue =~ m/^-/ );
        nprint( $argvalue . " ");
    }
    nprint("\n");
    iprint("Current time is $now\n");

    $dateRef = uc $dateRef;
    if (($dateRef ne "CDATE") && ($dateRef ne "FMDATE")) {
        eprint("dateRef should be either CDATE or FMDATE. Assuming CDATE\n");
        $dateRef = "CDATE";
    }

    my $haveLayermap = 0;
    if( defined $streamLayermap ){
        viprint(MEDIUM, "Using GDS Stream Layer Map file: '$streamLayermap'\n" );
        if (-r $streamLayermap) {
            my $rstatus = readStreamLayerMap( $streamLayermap, 
                \%g_streamLayerMap );
            if ($rstatus == 0 ){
                $haveLayermap = 1;
            }else{
                wprint("Problem trying to read '$streamLayermap'\n");
            }
        }else{
            wprint("Cannot open $streamLayermap for read\n");
        }

        if (!$haveLayermap) {
            wprint("No layer mappings read.  Check the format of $streamLayermap\n");
        }
    }

    if( not defined $g_LefVsGdsMap ){
        #-------------------------------------------------------
        #  Determine the TECHNOLOGY, find LefVsGdsMap file name
        if( defined $opt_pcs ){
            my $projRoot = "/remote/cad-rep/projects";
            $pcsTech = get_cad_variables( "$projRoot/$opt_pcs/cad/project.env" );
        }
        $opt_tech = $pcsTech unless( defined $opt_tech );

        my $lefVsGdsTechRoot = "/remote/cad-rep/msip/ude_conf/lef_vs_gds";
        my $lefVsGdsTechGlob = "$lefVsGdsTechRoot/*/msip_lefVsGds.map";
        $g_LefVsGdsMap = get_lef_vs_gds_map_filename( $opt_tech, $lefVsGdsTechRoot,$lefVsGdsTechGlob );
    }

    my @lefVsGdsLayers;
    if ( defined $g_LefVsGdsMap ) {
        if( -e $g_LefVsGdsMap ){
            ##  The lefVsGdsMap file has useful information like what geom and text
            #   layers will create a pin, and what the prBoundary layer is.
            @lefVsGdsLayers = read_file_LefVsGdsMap( $g_LefVsGdsMap, "Couldn't read LefVsGdsMap file!\n" );
        }else{
            wprint( "LefVsGdsMap file doesn't exist: '$g_LefVsGdsMap'\n" );
            $g_LefVsGdsMap = undef;
        }
    }

    #-------------------------------------------------------

    #-------------------------------------------------------
    # process the legal layers (lef pin, gds, obs)
    #-------------------------------------------------------
    if( defined $legalLayers ){
        wprint("Using obsolete option \"-layers\".  Use \"-lefPinLayers\" instead\n");
        if (defined $lefPinLayers) {
            wprint("Both -layers and -lefPinLayers used. Ignoring -layers\n");
        }
        else{
            $lefPinLayers = $legalLayers
        }
    }
    
    #-------------------------------------------------------
    # Determine the list of PG pins that should be used
    #     as a reference for cross-checking all other views.
    #     First source for reference list of PG pins is from 
    #       the command line (i.e. -pgPins)
    #     -pinCSV
    #     If not present at command line, then we will search
    #       the pininfo CSV, and use those PG pins as the ref.
    #     -liberty
    #     If pininfo is not provided as input at cmd line, then
    #       we build a list of PG pins, which is the UNION of
    #       of all lists of PG pins derived from each and every
    #       *_pg.lib file provided at cmd line.
    #-------------------------------------------------------
    %g_isPgPin = get_reference_list_for_pg_pins( $pgPinsArg, \@pinCSV, \@liberty );
    dprint(LOW, 'Global Reference list of Power Grid Pins (%g_isPgPin) = ' . pretty_print_href( \%g_isPgPin) . "\n" );
    
    my @ll;
    if (defined $lefPinLayers) {
        @ll = Tokenify($lefPinLayers);
    }
    elsif (@lefVsGdsLayers > 0) {
        iprint("No legal LEF pin layers specified. Using layers in '$g_LefVsGdsMap'\n");
        @ll = @lefVsGdsLayers;
    }
    
    my $runLegalLayers;

    if (@ll > 0) {
        foreach my $layer (@ll) {$IsLegalPinLayer{$layer} = 1}
        $runLegalLayers = 1;
        iprint("Legal LEF pin layers:  {@ll}\n");
    }
    else {
        iprint("No legal LEF pin layers specified.  Skipping check\n");
        $runLegalLayers = 0;
    }
    
    my @oll;
    if (defined $lefObsLayers) {
        @oll = Tokenify($lefObsLayers);
    }
    elsif (@lefVsGdsLayers > 0) {
        iprint("No legal LEF OBS layers specified. Using layers in '$g_LefVsGdsMap'\n");
        @oll = @lefVsGdsLayers;
    }
    
    my $runLegalObsLayers;
    if (@oll > 0) {
        foreach my $layer (@oll) {$IsLegalObsLayer{$layer} = 1}
        $IsLegalObsLayer{'OVERLAP'} = 1;
        $runLegalObsLayers = 1;
        @oll = sort keys %IsLegalObsLayer;
        iprint("Legal LEF obs layers:  {@oll}\n");
    }
    else {
        iprint("No legal LEF obs layers specified.  Skipping check\n");
        $runLegalObsLayers = 0;
    }
    #-------------------------------------------------------

    our $client = undef;
    my $autoLoc = ".";
    ##  This bit will delete the client on a ctrl-c
    $SIG{'INT'} = sub {
        if ($client) {da_p4_delete_client($client)}
        exit(1);
    };
    try {
        if (defined $p4Auto) {
            ##  P4 auto mode.
            my $pid = getppid();
            my $clientName = "pincheck_${USERNAME}_$pid";
            my $clientRoot = "${TEMPDIR}/$clientName";
            my $aref_viewList = [];
            $p4Auto =~ s/\/?$//;  ## Strip trailing "/" if there is one
            push @$aref_viewList, "$p4Auto/...  //$clientName/...";
            $client = da_p4_create_client($clientName, $clientRoot, $aref_viewList);
            my $fileCount = da_p4_sync_root($client);

            if ($fileCount == 0) {
                eprint("Error:  No files sync'ed from $p4Auto\n");
                exit(1);
            }
            $autoLoc = $clientRoot;
            $auto = 1;
        }
            
        my @autoFileList;
        if ($auto) {
            searchAuto($autoLoc, \@autoFileList);
            # Note: the @verilog files are under the /macro/interface/ folder
            #       but there are also verilog files under other dirs like
            #       behavior/
            processAuto(\@autoFileList, \@verilog, "\/$g_opt_macros\[^/\]*\\.v\$");

            my @libertyAll = ();
            my @libertyPG = ();
            processAuto(\@autoFileList, \@libertyAll, "\/$g_opt_macros\[^/\]+\\.lib\$");
            processAuto(\@autoFileList, \@libertyPG, "\/$g_opt_macros\[^/]+_pg\\.lib\$");
            my $aref_temp; (undef, $aref_temp) = compare_lists(\@libertyAll, \@libertyPG);
            @libertyNopg = @$aref_temp;
            @liberty = @libertyPG;
            processAuto(\@autoFileList, \@lef, "\/$g_opt_macros(_merged)?\\.lef\$");
            processAuto(\@autoFileList, \@cdl, "\/$g_opt_macros\\.cdl\$");
            processAuto(\@autoFileList, \@oas, "\/$g_opt_macros\\.oas\$");
            processAuto(\@autoFileList, \@gds, "\/$g_opt_macros\\.gds\$");
            processAuto(\@autoFileList, \@gds, "\/$g_opt_macros\\.gds\\.gz\$");
            processAuto(\@autoFileList, \@pinCSV, "pininfo/.*$g_opt_macros\\.csv\$");
        }
            
        printFileList(\@verilog, "Verilog Files", $client);
        printFileList(\@verilogNopg, "Verilog Nopg Files", $client);
        printFileList(\@liberty, "Liberty Files", $client);
        printFileList(\@libertyNopg, "Liberty Nopg Files", $client);
        printFileList(\@lef,         "Lef Files", $client);
        printFileList(\@cdl,         "CDL Files", $client);
        printFileList(\@gds,         "GDS Files", $client);
        printFileList(\@oas,         "Oasis Files", $client);
        printFileList(\@pinCSV,      "Pininfo CSV files", $client);
        
        @g_BoundaryLayerList = Tokenify($g_BoundaryLayer);

        #---------------------------------------------------------------------------------
        # PARSE all the macro's data views ... if files were specified at the cmd line
        #---------------------------------------------------------------------------------

        ReadVerilog(\@verilog, 0);
        ReadVerilog(\@verilogNopg, 1);
        ReadLiberty(\@liberty, 0);
        ReadLiberty(\@libertyNopg, 1);
        ReadLef(\@lef);
        ReadCdl(\@cdl);
        ReadGds(\@gds);
        ReadOas(\@oas);
        ReadCSV(\@pinCSV);
       
        my @row_vals;
        my @column_headers = sort keys %{ $g_ViewList[0] };
        #-------------------------------------------
        #  column_headers = keys for each view in array g_ViewList[$i]
        #  = [ AREA, BRACKET, CDATE, ... ,
        #      NOPG, ... , FILENAME, TYPE ]
        #-------------------------------------------
        #hprint( pretty_print_aref( \@column_headers) . "\n" );

        for( my $i=0; $i <= $#g_ViewList ; $i++ ){
            # check if the view is not from a '_pg.lib' file.
            my @col_vals;
            my $j=0;
            foreach my $col ( sort keys %{ $g_ViewList[$i] } ){
                $col_vals[$j] = $g_ViewList[$i]->{$col};
                $j++;
            }
            $row_vals[$i] = \@col_vals ;
        }
        #hprint( scalar(Dumper \@row_vals) . "\n" );
        #hprint( pretty_print_aref_of_arefs(\@row_vals) . "\n" );
        
        if( $DEBUG >= HIGH ){
            my $string = pretty_print_aref(\@column_headers) . "\n" 
                       . pretty_print_aref_of_arefs(\@row_vals) . "\n";
            hprint("PININFO \n$string \n" );
            pbc(NONE);
            write_file( $string, "$PROGRAM_NAME.debug.aref.g_ViewList" );
            my $data_structure =  "g_ViewList\n".scalar(Dumper @g_ViewList)."\n";
            write_file( $data_structure, "$PROGRAM_NAME.debug.g_ViewList" );
            $data_structure =  "g_PinHash\n".scalar(Dumper \%g_PinHash)."\n";
            write_file( $data_structure, "$PROGRAM_NAME.debug.g_PinHash" );
            $data_structure =  "g_InterfaceHash\n".scalar(Dumper \%g_InterfaceHash)."\n";
            write_file( $data_structure, "$PROGRAM_NAME.debug.g_InterfaceHash" );
            $data_structure =  "g_isPgPin\n".scalar(Dumper \%g_isPgPin)."\n";
            write_file( $data_structure, "$PROGRAM_NAME.debug.g_isPgPin" );
            pbc(NONE);
        }

        ##  The Checks
        if( $g_ViewIdx >= 2 ){
            #----------------------------------------------
            #  Check other pin attributes across all views.
            #----------------------------------------------
            my @subroutines_to_run = (
                \&CheckMissingPins     , \&CheckPinDirection,
                \&CheckPinType      , \&CheckPinRelatedPower, \&CheckPinRelatedGround, 
            );
            my @check_messages = (
                "Checking across all views for pin existence ...\n", 
                "Checking across all views for pin direction consistency...\n",
                "Checking across all views for type consistency...\n",
                "Checking across all views for related_power consistency...\n",
                "Checking across all views for related_ground consistency...\n",
            );

            my $is_cover_cell = 0;
            if($g_opt_macros =~ m/cover/ && @verilog ne "") {
                $is_cover_cell=1;
            }
            iprint( "Checking across all views for PG pin existence ...\n" );
            my $err = CheckMissingPgPins();
            if   ( !$err ) { iprint("CLEAN!\n") }
            else           { eprint("DIRTY!\n") }

            $err = 0;
            for(my $i=0; $i < @subroutines_to_run; $i++){
                nprint "\n\n";
                $err = 0;
                iprint( $check_messages[$i] );
                foreach my $pin (sort keys(%g_PinHash) ){
                    my $sref_CHECK = $subroutines_to_run[$i];
                    my $msg        = $check_messages[$i];
                    $err |= &$sref_CHECK( $pin, $is_cover_cell );
                }  # END foreach pin
                if   ( !$err ) { iprint("CLEAN!\n") }
                else           { eprint("DIRTY!\n") }
            }  # END foreach SUB checker
            pbc(MEDIUM);
            #----------------------------------------------
                                    
            # Larissa Nitchougovskaia: For voltage markers check
            if($g_OptVflag) { CheckPinRelatedPowerVoltageCdlVsPinInfo(); }
            
            #----------------------------------------------
            # run thru bracket checks ...
            #----------------------------------------------
            nprint "\n\n";
            iprint("Checking bracket consistency across all views;  ");
            $err = 0;
            my @o;
            if (defined $bracketArg) {
                nprint("All views must have \"$bracketArg\" brackets\n");
            }
            else {
                nprint("All views must have consistent brackets\n");
            }
            my $refBracket = $bracketArg;
            foreach my $view (@g_ViewList) {
                if (!(defined $view->{'BRACKET'})) {next}   ## Skip views with undefined brackets.
                my $bkt = $view->{'BRACKET'};
                push @o, "\t$view->{'FILENAME'}: $bkt\n";
                if (!(defined $bkt)) {}
                elsif ($bkt eq "mixed") {$err=1}
                elsif (!(defined $refBracket)) {$refBracket = $bkt}
                elsif ($bkt ne $refBracket) {$err=1}
            }
            
            if   ( $err && ( $bracketArg ne "any" ) ) { eprint("@{o}DIRTY!\n") }
            else                                      { iprint("CLEAN!\n") }
            #----------------------------------------------
            
            ## Check areas
            
            my $TheArea;
            my $AreaMismatch = 0;
            my @AreaOutput;
            my $AreaViews = 0;
            push(@AreaOutput, "Macro area disagreement:\n");
            foreach my $view (@g_ViewList) {
                dprint(HIGH, "foreach view='$view->{'TYPE'}'\n");
                if ( ( $view->{'TYPE'} eq "liberty" ) || ( $view->{'TYPE'} eq "lef" ) || ( $view->{'TYPE'} eq "pininfo" ) || ( $view->{'TYPE'} eq "gds" ) || ( $view->{'TYPE'} eq "oas" ) ) {
                    ## One of the views expected to have an area
                    $AreaViews++;
                    if (!defined $view->{'AREA'}) {

                        nprint "\n";
                        eprint("Error: Undefined area in $view->{'FILENAME'}\n");
                        $AreaMismatch = 1;
                        push(@AreaOutput, "\t$view->{'FILENAME'}: Undefined\n");
                        next;
                    }
                    push(@AreaOutput, "\t$view->{'FILENAME'}: $view->{'AREA'}\n");
                    dprint( HIGH, "push \@AreaOutput,\"\\t$view->{'FILENAME'}: $view->{'AREA'}\n") ;
                    if (!defined $TheArea){
                        dprint(HIGH, "TheArea is NOT defined yet. Setting '$view->{'TYPE'}' AREA to '$view->{'AREA'}'\n");
                        $TheArea = $view->{'AREA'};
                    }
                    else {
                        $AreaMismatch |= ($TheArea ne $view->{'AREA'});
                        if ( $AreaMismatch && $DEBUG ) {
                            dprint(HIGH, "MISMATCH!! TheArea:'$TheArea'  view:'$view->{'TYPE'}' viewArea:'$view->{'AREA'}'\n");
                        }
                    }
                }
            }
            
            if ( $AreaViews < 2 ) {
                nprint "\n\n";
                iprint("Less than two area views present; skipping area check\n");
            }
            else {
                nprint "\n\n";
                iprint("Checking for macro area consistency\n");

                #    if (defined $LefAreaNR) {wprint("LEF is apparently non-rectangular; area check robustness questionable.\n")}
                if ($AreaMismatch) {
                    dprint(HIGH, "Reporting DIRTY because of AreaMismatch = $AreaMismatch\n");
                foreach (@AreaOutput) { iprint("$_") }
                eprint("DIRTY!\n");
                } 
                else {iprint("CLEAN!\n")}
            }
        }
        else {
            nprint "\n";
            wprint("Warning:  Need to have at least 2 views read for pin check.  Skipping\n");
        }  ## END if( $g_ViewIdx >= 2 )
        
        if (defined $since) {
            nprint "\n\n";
            iprint("Checking view file mod dates vs. $since\n");
            
            my $sinceTime = str2time($since);
            if ($sinceTime) {
                foreach my $view (@g_ViewList) {
                    if ( ! exists( $view->{'TYPE'} ) ){
                        my $nkeys = keys %{$view};
                        if ( $nkeys == 0 ){
                            dprint(LOW, "\$view hash ref is empty");
                        }else{
                            dprint_dumper(LOW, "Missing TYPE field for view : ", $view);
                        }
                        if ( $nkeys == 0) {next;}
                    }else{
                        dprint_dumper(LOW, "Processing '$view' =", $view);
                    }

                    print "view: $view->{'TYPE'}\n";
                    if ($view->{'TYPE'} eq "pininfo"){
                        next;
                    }  ##  Skip timestamp check on pininfo files. They generally predate everything else.
                    if ($view->{'TYPE'} eq "liberty" || $view->{'TYPE'} eq "libertyNopg") {
                        my $err = 0;
                        if ($view->{$dateRef}) {
                            if ($view->{$dateRef} < $sinceTime) {
                                my $t = localtime($view->{$dateRef});
                                eprint("\tTiming File $view->{'FILENAME'} ($t) is stale\n");
                                $err = 1;
                            }
                        }else{
                            iprint("Undefined $dateRef for $view->{'FILENAME'}. Skipping date check.\n");
                        }
                        if ( !$err ){ 
                            iprint("CLEAN!\n"); 
                        }else{ 
                            wprint("DIRTY!\n"); 
                        }
                    }else{    ###########check staleness for other views
                        my $err = 0;
                        if ($view->{$dateRef}) {
                            if ($view->{$dateRef} < $sinceTime) {
                                   my $t = localtime($view->{$dateRef});
                                eprint("\tNon-timing File $view->{'FILENAME'} ($t) is stale\n");
                                $err = 1;
                            }
                        }else{
                            iprint("Undefined $dateRef for $view->{'FILENAME'}. Skipping date check.\n");
                        }                    
                        if ( !$err ) { iprint("CLEAN!\n") } else { wprint("DIRTY!\n") }
                    } # end of else for check staleness
                } # foreach view
            } # if since time
            else{
                eprint("Bad time spec \"$since\"\n");
            }
        } # defined $since
                    
        ##  Check LEF layers
        if( exists( $TypeCount{'lef'} ) && ( $TypeCount{'lef'} > 0 ) &&
            ( $runLegalLayers || $runLegalObsLayers ) ){
            my $dumpbanner = 0;
            my $AllClean = 1;

            nprint "\n";        
            iprint("Checking LEF pin layers:\n");
            foreach my $view (@g_ViewList) {
                my $ViewClean = 1;
                if ( ( $view->{'TYPE'} eq "lef" ) ) {
                    my @LayerOutput;
                    if ($runLegalLayers) {
                        my $LayerList = $view->{'LAYERS'};
                        push(@LayerOutput, "\t$view->{'FILENAME'} pins:\n");

                        nprint "\n";
                        iprint("Checking LEF pin layers for $view->{'FILENAME'}:  {@$LayerList}\n");
                        foreach my $layer (@$LayerList) {
                            if ( !$IsLegalPinLayer{$layer} ) { push( @LayerOutput, "\t\tLayer \"$layer\" illegal for pins\n" ); $ViewClean = 0 }
                        }
                    }
                    
                    if ( !$ViewClean ) { iprint("@LayerOutput"); eprint("DIRTY!\n") }
                    else               { iprint("CLEAN!\n") }
                    $ViewClean = 1;
                    @LayerOutput = ();
                    
                    if ($runLegalObsLayers) {
                        my $LayerList = $view->{'OBSLAYERS'};
                        push(@LayerOutput, "\t$view->{'FILENAME'} OBS:\n");
    
                        nprint "\n";
                        iprint("Checking LEF OBS layers for $view->{'FILENAME'}: {@$LayerList}\n");
                        foreach my $layer (@$LayerList) {
                            if ( !$IsLegalObsLayer{$layer} ) { push( @LayerOutput, "\t\tLayer \"$layer\" illegal for OBS\n" ); $ViewClean = 0 }
                        }
                    }
                    if ( !$ViewClean ) { iprint("@LayerOutput"); eprint("DIRTY!\n") }
                    else               { iprint("CLEAN!\n") }
                        
                    nprint "\n";
                    iprint("Checking LEF syntax for $view->{'FILENAME'}\n");
                    ## Checking for LEF syntax errors
                    my $fname_icwb = "icwb_config";
                    my @bashContent;
                    push( @bashContent, "#!/bin/bash\n");
                    push( @bashContent,  ". /global/etc/modules/3.1.6/init/sh\n");
                    push( @bashContent,  "module purge\n");
                    push( @bashContent,  "module load icwbev_plus\n");
                    push( @bashContent,  "icwbev -run $fname_icwb -nodisplay -exitOnError\n");
                    dprint(MEDIUM, "Attempting to write shell script: '$ENV{PWD}/bash_config.sh'\n");
                    my $wstatus = write_file( \@bashContent, 'bash_config.sh' );
    
                    my @icwbContent;
                    push( @icwbContent, "layout open $view->{'FILENAME'} \n"); #nolint
                    push( @icwbContent, "exit\n");
                    $wstatus = write_file( \@icwbContent, $fname_icwb );
                       
                    my $mode = oct(777);
                    chmod $mode, "./bash_config.sh";
                    my ($stdout_err, $status) = run_system_cmd( "./bash_config.sh", $VERBOSITY);
                    my @ICWBoutput = split( /\n/, $stdout_err);
                    #my @ICWBoutput = `./bash_config.sh`;
                    unlink "bash_config.sh";
                    unlink "$fname_icwb";
                    if( grep{ /Error/ } @ICWBoutput ){ 
                        eprint("\tSyntax error found in LEF file while running ICWBEV\n"); 
                        eprint("DIRTY!\n");
                    }
                    else { iprint("CLEAN!\n") }
                }
                $AllClean &= $ViewClean;
            }   ## END foreach my $view 
        }   ## END if( $TypeCount ...
        
        ##  Check pin layers on LEF/GDS power/ground pins
        if (defined $PGlayers) {
            my @pgLayers = Tokenify($PGlayers);
            my %pgLayerHash;
            foreach (@pgLayers) {$pgLayerHash{$_} = 1}
            for ( my $iview = 0 ; ( $iview < $g_ViewIdx ) ; $iview++ ) {
                my $clean = 1;
                my $view = $g_ViewList[$iview];
                if (($view->{'TYPE'} ne "lef") && ($view->{'TYPE'} ne "gds") && ($view->{'TYPE'} ne "oas")) {next}
                if (($view->{'TYPE'} eq "gds") || ($view->{'TYPE'} eq "oas")) {
                    
                    if (!%g_streamLayerMap && !$g_LefVsGdsMap) {
                        wprint("Cannot check power/ground pin layers for layout view $view->{'VIEWNAME'}; layermap not included\n");
                        next;
                    }
                    if (!$g_TypeDefined) {
                        wprint("Cannot check power/ground pin layers for layout view $view->{'VIEWNAME'}; no view defining pin types has been read\n");
                        next;
                    }
                }

                nprint "\n\n";
                iprint("Checking for $view->{'TYPE'} power/ground for $view->{'FILENAME'}\n");
                foreach my $pin (sort keys(%g_PinHash)) {

                    #        printMsg("$pin\n");
                    my $rec = $g_PinHash{$pin}->[$iview];
                    if (defined $rec) {
                        my $pintype='';
                        ##  For a lef view, get the type from the lef view; For gds, get from the merged attributes.
                        if ($view->{'TYPE'} eq "lef") {
                            $pintype = $rec->{'TYPE'} || '';
                        }else{
                            $pintype = $g_PinHashMerged{$pin}->{'TYPE'} || '';
                        }
                        foreach my $layer (keys %{$rec->{'LAYER'}}) {
                            #hprint(">>>line 899: Checking layer '$layer' for pin '$pin' and type is '$type'\n"); 
                            if ((($pintype eq "power") || ($pintype eq "ground")) && (!$pgLayerHash{$layer})) {
                                my $pghashlayer = "";
                                $pghashlayer = $pgLayerHash{"$layer"} if ( exists( $pgLayerHash{"$layer"} ));
                                iprint("\t$pintype pin $pin on unexpected layer $layer  $pghashlayer\n");
                                $clean = 0;
                            }
                        }
                    }
                }
            if   ($clean) { iprint("CLEAN!\n") }
            else          { eprint("DIRTY!\n") }
            }
        }
        
        if ($checkTiming) {
            for ( my $iview = 0 ; ( $iview < $g_ViewIdx ) ; $iview++ ) {
                my $view = $g_ViewList[$iview];
                if ($view->{'TYPE'} ne "liberty") {next}
                my $filename = $g_ViewList[$iview]->{'FILENAME'};

                nprint "\n\n";
                iprint("Timing checks for $filename:\n");
                
                my $err = 0;
                nprint "\n";
                iprint("\tChecking for missing pincaps:\n");
                foreach my $pin (sort keys(%g_PinHash)) {$err |= CheckLibertyPincap($pin, $iview)}
            if   ( !$err ) { iprint("\tCLEAN!\n") }
            else           { eprint("DIRTY!\n") }
                
                $err = 0;
                nprint "\n";
                iprint("\tChecking for timing arcs:\n");
                foreach my $pin (sort keys(%g_PinHash)) {$err |= CheckLibertyTiming($pin, $iview)}
            if   ( !$err ) { iprint("\tCLEAN!\n") }
            else           { eprint("DIRTY!\n") }
                
                #  Checked under arc presence check
                #    $err = 0;
                #    printMsg("\n\tChecking for max_transition/max_capacitance coverage:\n");
                #    foreach $pin (sort keys(%g_PinHash)) {$err |= CheckLibertyMaxes($pin, $i)}
                #    if (!$err) {printMsg("\tCLEAN!\n")}
                
                $err = 0;
                nprint "\n";
                iprint("\tChecking for arc presence:\n");
                foreach my $pin (sort keys(%g_PinHash)) {$err |= CheckLibertyArcs($pin, $iview)}
            if   ( !$err ) { printMsg("\tCLEAN!\n") }
            else           { eprint("DIRTY!\n") }
                
                ## Misc Liberty checks
                ##  Check for existence of leakage_power_unit
                nprint "\n";
                iprint("\tChecking misc timing issues:\n");
                if (!(defined $view->{'LEAKAGE_POWER_UNIT'})) {eprint("\t \"leakage_power_unit\" undefined \n")}
                if (!(defined $view->{'CELL_LEAKAGE_POWER'})) {eprint("\t \"cell_leakage_power\" undefined \n")}
                if (!($view->{'OPCOND_DEFINED'})) {eprint("\t \"operating_conditions\" undefined \n")}
                if (!($view->{'TREE_TYPE_DEFINED'})) {eprint("\t \"operating_conditions-->tree_type\" undefined \n")}
                if (!(defined $view->{'DEFAULT_MAX_CAPACITANCE'})) {eprint("\t \"default_max_capacitance\" undefined \n")}
                if (!(defined $view->{'DEFAULT_MAX_TRANSITION'})) {eprint("\t \"default_max_transition\" undefined \n")}
                
            }  #  END foreach
        }  #  END if( $checkTiming )
        
        if ($physCheck) {CheckPhysPins_1()}
        
        if ($dumppins) {
            iprint("Dumping Pins\n");
            my $i=0;
            foreach my $view (@g_ViewList) {
                iprint("View $i:\n");
                if ( $view ) {
                    iprint("\tFile = $view->{'FILENAME'}\n");
                    iprint("\tType = $view->{'TYPE'}\n");
                    iprint("\tArea $view->{'AREA'}\n");
                }
                $i++;
            }
            foreach my $pin (sort keys(%g_PinHash)) {DumpPin($pin)}
        }
    }  ##  END try{
    
    catch {
        iprint("$_\n");
        if ($client) {da_p4_delete_client($client)}
        exit(1);
    };

    if( $client ){
        if( $logging ){
            my $mw = new MainWindow;
            $mw->iconify();
            my $response = $mw->messageBox(-icon => 'question', -message => 'Check $logFile into P4?', -title => 'My title', -type => 'YesNo', -default => 'No');
            if ($response eq "Yes") {
                my $p4LogFile = "$client->{'ROOT'}/$logFile";
                if (da_p4_add_edit($client, $p4LogFile)) {
                    copy($logFile, $p4LogFile);
                    da_p4_submit($client, $p4LogFile, "alphaPinCheck auto P4");
                }
            }
        }
        da_p4_delete_client($client);
    }

    #-------------------------------------------------
    ## Need to append the log file when there are multiple submacros
    ## e.g. utility_blocks, instead of overwriting.
    my @new_lines = split(/\n/, $main::STDOUT_LOG);
    push(@new_lines, "\n");
    write_file(\@new_lines, $LOGFILE, ">");

    exit(0);
} # end Main

#-------------------------------------------------------
#  Determine the golden reference list of PG pins
#      used to cross-check EVERY view that has power
#      pins:  docx, pininfo, pg-liberty
#-------------------------------------------------------
sub get_reference_list_for_pg_pins($$$){
    print_function_header();
    my $opt_pgPins    = shift;
    my @pininfo_files = @{ +shift };
    my @liberty_files = @{ +shift };

    my $msg = "Reference for PG Pins derived from";
    my @pgPins;
    if( defined $opt_pgPins ){
        hprint( "$msg cmdline ...\n" );
        @pgPins = Tokenify($opt_pgPins);
    }elsif( @pininfo_files ){
        hprint( "$msg PIN INFO file(s) ...\n" );
        @pgPins = get_pgpins_from_pininfo_csv_files( \@pininfo_files );
    }elsif( defined \@liberty_files ){
        hprint( "$msg PG Liberty file(s) ...\n" );
        @pgPins = get_pgpins_from_pglib_files( \@liberty_files, 0 );
    }
    my %pgpins_reference;
    foreach my $pn ( @pgPins ){$pgpins_reference{$pn} = 1} 
    vhprint(LOW, "Found PG pins: ". join(",",(sort keys %pgpins_reference)) ."\n");

    print_function_footer();
    return( %pgpins_reference );
}

#-------------------------------------------------------
#  Handle pcs arg ... 
#  Get the $cadtech from the project.env 
#-------------------------------------------------------
sub get_cad_variables($){
   print_function_header();
   my $projEnvFile = shift;

   my ( $cadproj, $cadrel, $cadhome, $cadtech ) = getCadHome( $projEnvFile );
   if( $cadtech ){
       iprint("Inferred technology '$cadtech' from projSPEC \"$cadproj\"\n");
   }else{
       eprint("Ignoring projSPEC option '-pcs' ... cannot find project.env file:\n\t '$projEnvFile' \n");
   }

   print_function_footer();
   return( $cadtech );
}

#--------------------------------------------------------------------------
#  this subroutine will use the tech value to go find the 
#  legal technologies, and then determine filepath & filename for
#  the lef vs gds map file.
#--------------------------------------------------------------------------
sub get_lef_vs_gds_map_filename($$$){
    print_function_header();
    my $opt_tech         = shift;
    my $lefVsGdsTechRoot = shift;
    my $lefVsGdsTechGlob = shift;

    my @legalTech;
    my $fname_LefVsGdsMap;

    #--------------------------
    # find all the legal technologies 
    foreach my $dir (glob "$lefVsGdsTechGlob") {
        my @t = split(/\//, $dir);
        my $bitBucket = pop @t;   ##  Filename
        my $techDir = pop @t;
        push @legalTech, $techDir;
    }    

    if( defined $opt_tech ){
        my ($theTech, @partialMatches);
        ##--------------------
        ##  Check the opt_tech is legal/valid
        foreach my $lTech (@legalTech) {
            if ($opt_tech eq $lTech) {
                ##  Exact match.
                $theTech = $opt_tech;
                last;
            }
            else {
                ##  Check for parial matches
                #        printMsg("partial check $opt_tech $lTech\n");
                if ($lTech =~ /$opt_tech/) {push @partialMatches, $lTech}
            }
        }
        ##--------------------
   
        if (!(defined $theTech)) {
            ##  No exact match.
            if (@partialMatches == 1) {
                ##  A single partial match
                $theTech = $partialMatches[0];
                iprint("Assuming technology is \"$theTech\"\n");
            }
        }
  
        if (!(defined $theTech)) {
            eprint("Unrecognized tech $opt_tech\n");
            if (@partialMatches > 1) {iprint("\tPartial matches:  {@partialMatches}\n")}
            else {iprint("\tLegal techs: {@legalTech}\n")}
            exit;
        }
        ##  Only update the g_LefVsGdsMap if not explicitely defined.
        if( !defined $fname_LefVsGdsMap ){
            $fname_LefVsGdsMap = $lefVsGdsTechGlob;
            ##  Now that have the tech, replace the glob (*)
            $fname_LefVsGdsMap =~ s|\*|$theTech|;
        }
    }
    print_function_footer();
    return( $fname_LefVsGdsMap );
}

#--------------------------------------------------------------------------
#  this subroutine will compare the circuit team's architectural SPECs
#     with the pininfo file, and report any mismatches of the pin attributes
#     that were detected. The bulk of the work is performed by an external
#     script, which is an arg to this sub.
#--------------------------------------------------------------------------
sub check_ckt_SPEC_vs_pininfo($$$){
    print_function_header();
    my $opt_docx     = shift;
    my $check_script = shift;
    my @pininfo_csv  = @{+shift};

    viprint(LOW, "$RealScript is using option '-docx' and will try and run $check_script");

    ##  No pinfo arg specified ... and is necessary to fuel the comparison
    if( @pininfo_csv == 0 ){
        fatal_error("The required argument -pinCSV was not specified.\n");
    } 

    dprint(HIGH, "\$opt_docx is '$opt_docx'\n");

    my @pininfo_file_list;
    foreach my $file ( @pininfo_csv ){
        push(@pininfo_file_list, glob($file));
    }

    dprint_dumper(HIGH, "Foreach pininfo_csv: ", \@pininfo_csv);
    dprint_dumper(HIGH, "creates pininfo_file_list: ", \@pininfo_file_list);

    if( @pininfo_file_list == 0 ){ 
        nprint "\n"; 
        fatal_error("No PININFO files found:'". join(",",@pininfo_csv) ."'\n", 1 ); 
    }

    my $any_errors=0;
    foreach my $csv_file ( @pininfo_file_list ){
        my $cmd = "$check_script $opt_docx $csv_file";
        my ($stdout_err, $status) = run_system_cmd( $cmd, $main::VERBOSITY);
        if ( $status != 0 ){
            eprint("Error detected while running '$check_script' with '$opt_docx'. Log = $stdout_err\n");
            $any_errors ++;
        }
    }

    print_function_footer();
    return( $any_errors );
}

#--------------------------------------------------------------------------
#  Global VARs
#        my %textofMetal;
#        my %g_LvGlayerMap;
#        my %g_LvGlayerMapReverse;
#--------------------------------------------------------------------------
sub read_file_LefVsGdsMap($$){
    print_function_header();
    my $filename = shift;
    my $err_msg  = shift;

    my @lefVsGdsLayers;   ##  List of the layers defined in the lefVsGds map file
    foreach my $line ( read_file($filename, $err_msg) ){
        next if( $line =~ m/^\s*$/ ); # skip empty lines
        my @t = Tokenify($line);
        if( ($t[0] eq "prBOUNDARY") || ($t[0] eq "PRBND")) {
            $g_BoundaryLayer = $t[1];
        }
        elsif ($t[0] eq "textOfMetal") {
            ##  Map of metal/text layers
            $textOfMetal{$t[1]} = $t[2];
            push @lefVsGdsLayers, $t[1];

        #        if ($buildLegalLayers) {$IsLegalPinLayer{$t[1]} = 1}
        }
        else {
            my $layerName   = $t[0];
            my $layerNumber = $t[1];
            if (!$g_LvGlayerMap{$layerNumber}) {$g_LvGlayerMap{$layerNumber} = ()}
            if (!$g_LvGlayerMapReverse{$layerName}) {$g_LvGlayerMapReverse{$layerName} = ()}
            push(@{$g_LvGlayerMap{$layerNumber}}      , $layerName   );
            push(@{$g_LvGlayerMapReverse{$layerName}}, $layerNumber );
        }
    } # END for
    print_function_footer();
    return( @lefVsGdsLayers );
}

#------------------------------------------------------------------------------
sub printFile {
    ## Writes contents of a file using printMsg
    my $file = shift;

    my $bfr;
    
    if (-e $file) {
        my @fstat = stat $file; 
        open( my $HDL, $file ); # nolint open<
           read $HDL, $bfr, $fstat[7];
        close $HDL;
        iprint($bfr);
    }
}    

#------------------------------------------------------------------------------
sub printFileList {
    my $fileList = shift;
    my $header   = shift;
    my $client   = shift;

    my $n = @$fileList;
    iprint("$header\n");
    if ($n == 0) {
        iprint("\t<None>\n");
    }
    foreach my $file (@$fileList) {
        if ($client) {
            iprint("\t$client->{'CLIENT2DEPOT'}->{$file}\n");
        }
        else {
            iprint("\t$file\n");
        }
    }
}

#------------------------------------------------------------------------------
sub DumpPin {
    print_function_header();
    my $pinname = shift;

    iprint("$pinname:\n");
    for ( my $iview = 0 ; ( $iview < $g_ViewIdx ) ; $iview++ ) {
        if ( defined $g_PinHash{$pinname}->[$iview] ) {
            my $dir            = $g_PinHash{$pinname}->[$iview]->{'DIR'};
            my $type           = $g_PinHash{$pinname}->[$iview]->{'TYPE'};
            my $related_power  = $g_PinHash{$pinname}->[$iview]->{'RELATED_POWER'};
            my $related_ground = $g_PinHash{$pinname}->[$iview]->{'RELATED_GROUND'};
            my $pinarc         = $g_PinHash{$pinname}->[$iview]->{'PINARC'};
            my $relarc         = $g_PinHash{$pinname}->[$iview]->{'RELARC'};
            my $async          = $g_PinHash{$pinname}->[$iview]->{'ASYNC'};

            # Larissa Nitchougovskaia: For voltage markers check
            my $power_value = $g_PinHash{$pinname}->[$iview]->{'POWER_VALUE'};
            iprint("\tView $iview:  Dir=$dir, Type=$type, RelatedPower=$related_power, RelatedGround=$related_ground, PINARC=$pinarc, RELARC=$relarc, async=$async, power_value=$power_value\n");
        }
        else{
            iprint("\tView $iview:  Not present\n");
        }
    }
}

#------------------------------------------------------------------------------
#  Check for existence of a given pin across all the views
#
#  g_PinHash: contains all pins combined from all but the interface view
#  g_InterfaceHash: contains all pins in the interface (.v) files
#
#  The Interface Hash is a superset of pin names. It may contain more than
#  are in the g_PinHash itself.
#
#  We don't check if the Interface Pins are missing from the g_PinHash, but
#  we do want to complain if there is a g_PinHash pin missing from the 
#  Interface hash.
#  
#------------------------------------------------------------------------------
sub CheckMissingPins($$){
    my $name        = shift;  # NOTE: this comes from g_PinHash
    my $is_cover_cell    = shift;

    my $printedName = 0;
    my $pin_attr    = $g_PinHash{$name};
    my $err         = 0;
    if( $name =~ m/^VDD$/  ||  $name =~ m/^vdd$/ ){
        if ( $main::DEBUG >= SUPER ){
            dprint(SUPER, "Arg '\$name'     = '$name' \n");
            dprint(SUPER, "Arg '\$is_cover_cell' = '$is_cover_cell' \n");
            dprint(SUPER, "'\$pin_attr'     = '".scalar(Dumper $pin_attr)."' \n");
            my $data_structure =  "g_PinHash\n".scalar(Dumper \%g_PinHash)."\n";
            write_file( $data_structure, "mydatastruct.href" );
            pbc(SUPER);
        }
    }
    if( $DEBUG >= INSANE ){
        my $pin_name = "ZCalCompVOHDAC[0]";
        my $data_structure =  "g_PinHash $pin_name\n" .scalar(Dumper \@{$g_PinHash{$pin_name}}). "\n" ;
        write_file( $data_structure, "mydatastruct.href" );
    }
    pbc(SUPER);

    # for this pin name, iterate over each view and check attributes
    for ( my $iview = 0 ; ( $iview < $g_ViewIdx ) ; $iview++ ) {
        
        # check if the view is not from a '_pg.lib' file.
        my $nopg = $g_ViewList[$iview]->{'NOPG'}; # boolean
        if( $name =~ m/^VDD$/ || $name =~ m/^vdd$/ ){
            if ( $main::DEBUG >= SUPER) {
                dprint(SUPER, "'\$g_ViewList[$iview]-> \n". scalar(Dumper $g_ViewList[$iview]) ."\n" );
                dprint(SUPER, "if '\$pin_attr->[$iview]'     = \n'". scalar(Dumper \%{$pin_attr->[$iview]}) ."' \n");
                dprint(SUPER, "if '\$nopg'     = '$nopg' \n");
                dprint(SUPER, "if '\$g_isPgPin{$name}'     = '". $g_isPgPin{$name} ."' \n") 
                    if ( exists $g_isPgPin{$name} );
            }
            pbc(SUPER);
        }
        if (!(defined $pin_attr->[$iview]) && !($nopg && $g_isPgPin{$name}) ) {
            dprint(SUPER, "if( COND ) = true branch \n" );
            pbc(SUPER);
            my $viewname = $g_ViewList[$iview]->{'FILENAME'};
            # for cover cells, skip pininfo view ... 
            if($is_cover_cell) {
                if( ($viewname !~ /pininfo/) || ($viewname !~ /cdl/) || ($viewname !~ /lef/)){
                    # If the view is an interface (ie. verilog) then see if the
                    # pin name is in g_InterfaceHash

                    my $good = 0;
                    if ( $viewname =~ m/interface/ ) {
                        $good=1 if ( exists $g_InterfaceHash{"$name"} ) ;
                    }
                    if ( ! $good ) {
                        if( !$printedName ){
                            iprint( "Pin $name\n" );
                        }
                        iprint("\t missing in $viewname\n");
                        $printedName = 1;
                        $err = 1;
                    }
                }
            }else{
                if ( $viewname =~ /interface.*\.v/ ){
                    # This is an interface view. The pins for those are 
                    # stored in g_InterfaceHash table.
                    # So, if the pinname isn't present in that hash table,
                    # then it means it's missing and we should complain.
                    if ( ! $g_InterfaceHash{"$name"} ){
                        if( !$printedName ){
                            iprint( "Pin $name\n" );
                        }
                        iprint("\t missing in $viewname\n");
                    }

                }else{
                
                    if( !$printedName ){
                        iprint( "Pin $name\n" );
                    }
                    iprint("\t missing in $viewname\n");
                    if ( $VERBOSITY >= LOW ) {
                        # Maybe the name was lowercase but should have been uppercase
                        if ( $name eq lc($name) ){
                            viprint(MEDIUM, "\t name eq lc($name): so the pin name is all lowercase\n");
                            # So the pin name is all lowercase here; maybe that isn't
                            # correct. Is there a similiar name to this that could be
                            # mixed case?
                            foreach my $pg_pin (sort keys(%g_isPgPin) ){
                                if ( lc($pg_pin) eq lc($name) ){
                                    my $nviews = @$pin_attr;
                                    for ( my $iv=0; $iv < $nviews; $iv++){
                                        my $pin_viewname =  $pin_attr->[$iv]->{'FILENAME'} || $pin_attr->[$iv]->{'VIEW_NAME'} || $pin_attr->[$iv]->{'VIEW_INDEX'};
                                        if ( $pin_viewname ) {
                                            viprint(LOW, "\t Maybe the text case is incorrect. I see that '$name' from file '$pin_viewname' matches PG pin lowercase('$pg_pin')\n");
                                            last ;
                                        }
                                    }
                                    last;
                                }
                            }
                        }
                    } # if DEBUG >= LOW

                    $printedName = 1;
                    $err = 1;
                }
            }
        }else{
            dprint(SUPER, "if( COND ) = false branch \n" );
            pbc(SUPER);
        }
    }
    print_function_footer();
    return $err;
}

#------------------------------------------------------------------------------
#  Check for power related pins specified in the cmd line args
#      Examples:  VDD, VSS, VAA, VDDQ, etc
#
#  Assumptions : only power related pin names are passed into this subroutine
#  PG pins are expected to be missing in /lib_lvf/ folders.
#  The ViewList array captures attributes of each view, and is used to evaluate
#         decide how to process the pin's attributes for a given view.
#  The g_PinHash includes an array of href that capture the pin attributes
#         from the view.  
#  The relationship between the view array and the pin array is by the
#         index.  So, the same index in the view (e.g. 3 ) refers to the
#         liberty file (capturing it's attributes) and that same index for
#         the pin hash refers to the exact same liberty file (capturing the
#         pin's attributes in that same file).
#------------------------------------------------------------------------------
sub CheckMissingPgPins(){
    print_function_header();
    my $isDirty = 0;

    # for each known global pin name, iterate over each view and check that that pin exists 
    # The g_isPgPin list is built either by the -pgpins option, the .csv file or the liberty files
    # that do contain power pins.
    my @reference_pgpins = sort keys %g_isPgPin;
PG_PIN_LOOP:
    foreach my $pg_pin_name ( @reference_pgpins ){
        #viprint(LOW, "Process pg_pin_name '$pg_pin_name'\n");
        VIEW_LOOP:
        for ( my $iview = 0 ; ( $iview < $g_ViewIdx ) ; $iview++ ) {
            my $view_fname = $g_ViewList[$iview]->{'FILENAME'};
            #-------------
            # if not a pg file, skip cross-check against reference list of PG pins
            #-------------
            my $nopg = $g_ViewList[$iview]->{'NOPG'}; # boolean
            next VIEW_LOOP if( $nopg );

            #-------------
            # View should have pwr pins, check agains ref list
            # (Note: they might not be marked as power pins, but if they exist
            #  we are ok otherwise it's an error)
            #-------------
            if (! exists $g_PinHash{$pg_pin_name} ){
                # No pin_attr object stored in here for any views
                fprint( "Power Grid (PG) pin '$pg_pin_name' is not found in any views!! \n" );
                $isDirty = 1;
                next PG_PIN_LOOP;
            }

            my $err = 0;
            my $view_type  = $g_ViewList[$iview]->{'TYPE'};

            my $pin_attr = $g_PinHash{$pg_pin_name};  # pin attributes for this pin
            my $pin_vrec = @$pin_attr[$iview];
            if ( ! defined $pin_vrec ){
                # This means, we could not find the pg_pin_name in the 
                # specified view.

                # If we have read an interface file, then we want to make sure
                # that the global pin is present there. It should be.

                if ( $g_InterfacePinCount ) {
                    $err += pg_pin_missing_from_interface( $pg_pin_name, \%g_InterfaceHash, $iview, "", $view_fname );
                    $isDirty = 1;
                }

                # We know that the global pin is missing from the present view.
                # This probably should be an error because the global pins
                # should be present in every view.
                #

                iprint("PG pin '$pg_pin_name'\n");
                iprint("\t missing in '$view_fname' type='$view_type'\n");
                $isDirty = 1;

                next VIEW_LOOP;
            }

            #---------------------------------------------------------
            # The pin attribute 'TYPE' will not be defined for a PG pin name 
            # if it's declared in a *_pg.lib liberty file as a 'pin' rather
            # than as a 'pg_pin'. Check for this scenario.
            
            my $pin_type  = $pin_vrec->{TYPE}     ;
            my $viewname  = $pin_vrec->{FILENAME} ; #|| $view_fname

            if( defined $pin_type ){
                unless( $pin_type =~ m/power|ground/i ){
                    my $extra = "in pin view '$viewname'";
                    $extra = "in viewList view '$view_fname'" if ( ! $viewname);
                    vwprint(LOW, "PG pin '$pg_pin_name' attribute TYPE has unexpected value while looking at iview #$iview. Expected one of "
                          . " {power, ground}: Found pin_type='$pin_type' in view $extra\n" );
                    $err++;
                }
            }else{
                # We don't know what the pin_type is at this point. We can't assume the pins are not power pins or should not
                # be treated like power pins.
                vwprint(LOW, "PG pin '$pg_pin_name' in view '$viewname' does not have a type.\n\tSo we can not determine if it's a power/ground pin\n");
                if ( $viewname =~ m/_pg\.lib/ ){
                    $err++;
                }
            }

            # Check if this power pin is in the Interface list.  If it isn't then it's a problem. That is
            # if we read in the interface file.
            if ( $g_InterfacePinCount > 0){
                # Having a count greater than zero means we have an interface
                # file and have read in all the pins. 
                #
                # NOTE: It does not account for having an empty interface file.
                #
                $err += pg_pin_missing_from_interface( $pg_pin_name, \%g_InterfaceHash, $iview, $viewname, $view_fname );
            }

            my ($common, $firstOnly, $secondOnly, $bool__lists_equiv) = compare_lists( [ $pg_pin_name ], \@reference_pgpins );
            if( $err ){
                $isDirty = 1;
                iprint("PG pin '$pg_pin_name'\n" );
                iprint("\t missing in '$viewname'\n" );
            }
        } # foreach View
    } # foreach PG pin
    print_function_footer();
    return $isDirty;
} # end of CheckMissingPgPins


#------------------------------------------------------------------------------
sub Reconcile($$) {
    ##  function to reconcile two attributes to form a merged attribute across all views.
    my $merged  = shift;
    my $current = shift;

    if (!(defined $merged)) {return $current}
    if ((defined $merged) && ( $merged eq NULL_VAL)) {
        return $current;
    }

    if ($merged eq "conflict") {return "conflict"}
    if   ( $merged eq $current )   { return $merged }
    else                           { return "conflict" }
}

#------------------------------------------------------------------------------
sub CheckPinDirection {
    print_function_header();
    my $name = shift;
    
    my $PrintedName = 0;
    my $pinList = $g_PinHash{$name};
    my @output;
    push (@output,"Pin $name:\n");
    my $direction;
    my $err = 0;
    for (my $iview=0; ($iview<$g_ViewIdx); $iview++) {
        my $dir;
        if( defined ($dir = $pinList->[$iview]->{'DIR'}) ){
            $g_PinHashMerged{$name}->{'DIR'} = Reconcile($g_PinHashMerged{$name}->{'DIR'}, $dir);
            my $viewname = $g_ViewList[$iview]->{'FILENAME'};
            push (@output,"\t$viewname: $dir\n");
            if (!(defined $direction)){
                $direction = $dir;
            }
            else {
                $err |= ( $dir ne $direction );
            }
        }
    }
    #if ($err) {wprint("@output")}
    if ($err) {iprint("@output")}
    return $err;
}

# Larissa Nitchougovskaia: For voltage markers check
#------------------------------------------------------------------------------
sub CheckPinRelatedPowerVoltageCdlVsPinInfo {
    print_function_header();

    my @output;
    my $view;
    my $err;
    my $csv_power_value;
    my $cdl_voltage_marker;
    my $pinList;
    my $isGround;
    my @validViewNumbers;
    my $dirty = 0;
    my $count = 0;
    my $Message;
      
    for ( my $iview = 0 ; ( $iview < $g_ViewIdx ) ; $iview++ ) {
       if(($g_ViewList[$iview]->{'TYPE'}  eq "cdl") or 
          ($g_ViewList[$iview]->{'TYPE'}  eq "pininfo")) {
           push(@validViewNumbers, $iview);
         }
    }
    unless( $#validViewNumbers==1 ){
        nprint "\n";
        iprint("No cdl+pinInfo views provided, skipping vflag check\n");
        return
    } # skip
  
    nprint "\n\n";
    iprint("Checking for related power value consistency (vflags) between cdl and pinInfo\n");
    foreach my $pin (sort keys(%g_PinHash)) {
        $csv_power_value = "undef";
        $cdl_voltage_marker = "undef";
        $err = 0;
        my $warn = 0;
        $pinList = $g_PinHash{$pin};
    
        foreach my $iview (@validViewNumbers) {
            if ($g_ViewList[$iview]->{'TYPE'}  eq "cdl") {  
               $cdl_voltage_marker = $pinList->[$iview]->{'POWER_VALUE'}; # value or undef 
            } # pininfo, skip pin if ground
            elsif ($g_ViewList[$iview]->{'TYPE'}  eq "pininfo") {
                $isGround = ($pinList->[$iview]->{'TYPE'} eq 'ground');
                $csv_power_value = $pinList->[$iview]->{'POWER_VALUE'};    # value or undef 
            } 
        }

        if ($isGround) { next }
        push (@output,"Pin $pin: ");
        unless(defined $cdl_voltage_marker ) {
            if($csv_power_value eq 'core') {
                $Message = "Warning";
                $warn = 1; 
            }
            else {
                $Message = "Error";
                $err=1; 
            }
            push(@output, "\t$Message: No voltage marker in cdl (related power is $csv_power_value)\n");
        } 
        unless(defined $csv_power_value ) {
            push( @output, "\tError: No related power value from pinInfo \n" );
            $err = 1;
        } 
    
        if(defined $cdl_voltage_marker && defined $csv_power_value) {
            if( $cdl_voltage_marker ne $csv_power_value ){
                push(@output, "\tError: cdl=>$cdl_voltage_marker, pinInfo=>$csv_power_value\n");
                $err=1;
            }
        }
        if ($err or $warn) {iprint("@output")}
        $dirty |= $err; 
        $err    = 0;
        $warn   = 0;
        @output = ();
      } # foreach pin
   
      unless ($dirty) { iprint("CLEAN!\n"); }
      else            { eprint("DIRTY!\n") }
}

#------------------------------------------------------------------------------
#  Issue error if INPUT|IO pins don't have a cap value.
#  Issue warn  if OUTPUT   pins       have a cap value.
#------------------------------------------------------------------------------
sub CheckLibertyPincap {
    print_function_header();
    my $name  = shift;
    my $iview = shift;  ## view index
    
    my $pinList = $g_PinHash{$name};
    my $PrintedName = 0;
    my $err = 0;
    my $dir;
    my @output;
    push (@output,"Pin $name:\n");
    my $view_filename = $g_ViewList[$iview]->{'FILENAME'};
    if( defined( $dir = $pinList->[$iview]->{'DIR'} ) ){
        my $cap = $pinList->[$iview]->{'PINCAP'};
        if( ($dir eq "input") || ($dir eq "io") ){
            ##  Capacitance is expected.
            if (!defined $cap) {push(@output, "\tError: Undefined cap for $dir pin\n"); $err=1}
            elsif ($cap == 0) {push(@output, "\tError: Zero cap for $view_filename\n"); $err=1}
        }
        elsif ( $dir eq "output" ) {
            ##  Capacitance is not expected.
            if( defined $cap ){
                push(@output, "\tWarning:  Defined cap \"$cap\" on output\n");
                $err=1
            }
        }
    }
    if ($err) {iprint("@output")}
    return $err;
}

#------------------------------------------------------------------------------
sub PinIsAsync {
    print_function_header();
    ##  Looks for a pininfo view, to determine if a pin is tagged as async or not.
    my $pinname = shift;

    my $i = 0;
    foreach my $v (@g_ViewList) {
        if ( exists( $v->{'TYPE'} ) && ( $v->{'TYPE'} eq "pininfo" ) ) {
            my $async = $g_PinHash{$pinname}->[$i]->{'ASYNC'};
            return pininfoBool($async);
        }
        $i++;
    }
    return 0;  ## Default if no pininfo view is loaded.
}

#------------------------------------------------------------------------------
sub pininfoBool {
    print_function_header();
    my $x = shift;

    if ( defined $x ) {
        $x = lc($x);
        if    ($x eq "no"   ){ return 0 }
        elsif ($x eq "false"){ return 0 }
        elsif ($x eq "n"    ){ return 0 }
        elsif ($x eq "yes"  ){ return 1 }  
        elsif ($x eq "true" ){ return 1 }
        elsif ($x eq "y"    ){ return 1 }
        elsif ($x == 0      ){ return 0 }
        elsif ($x != 0      ){ return 1 }
        else {return 0}
    }
    else {return 0}

}

#------------------------------------------------------------------------------
#   Check for max_transition coverage on Inputs/IO's
#   Check for max_capacitance coverage on Outputs/IO's
#------------------------------------------------------------------------------
sub CheckLibertyMaxes {
    print_function_header();
    my $name = shift;
    my $i    = shift;  ## view index
    
    my $pinList = $g_PinHash{$name};
    my $PrintedName = 0;
    my $err = 0;
    my $dir;
    my @output;
    my $filename = $g_ViewList[$i]->{'FILENAME'};
    if( ( defined($dir = $pinList->[$i]->{'DIR'})     ) && 
               ( $pinList->[$i]->{'TYPE'} ne "power"  ) &&
               ( $pinList->[$i]->{'TYPE'} ne "ground" ) ){
        if( ( $dir eq "input" ) || ( $dir eq "io" ) ){
            ## Expect max_transition
            if ( !( defined $pinList->[$i]->{'MAX_TRANSITION'} ) ) { eprint("\t $dir pin $name not covered by max_transition\n"); $err = 1 }
        }
        if ( ( $dir eq "output" ) || ( $dir eq "io" ) ) {
            ## Expect max_cap
            if ( !( defined $pinList->[$i]->{'MAX_CAPACITANCE'} ) ) { eprint("\t $dir pin $name not covered by max_capacitance\n"); $err = 1 }
        }
    }
    if ($err) {iprint("@output")}
    return $err;
}

#------------------------------------------------------------------------------
sub CheckLibertyArcs {
    print_function_header();
    my $name = shift;
    my $i = shift;  ## view index
    
    my $pinList = $g_PinHash{$name};
    my $PrintedName = 0;
    my $err = 0;
    my $dir;
    my @output;
    my $filename = $g_ViewList[$i]->{'FILENAME'};
    if ( ( defined( $dir = $pinList->[$i]->{'DIR'} ) ) && ( $pinList->[$i]->{'TYPE'} ne "power" ) && ( $pinList->[$i]->{'TYPE'} ne "ground" ) ) {
    my $pinarc = (defined $pinList->[$i]->{'PINARC'});
    my $relarc = (defined $pinList->[$i]->{'RELARC'});
        if ( ( $dir eq "input" ) || ( $dir eq "io" ) ) {
        ## Expect pin or related pin arc.
            if ( !$pinarc && !$relarc ) {
        my $isAsync = PinIsAsync($name);
        if (!$isAsync) {eprint("\t $dir pin $name does not have arc\n")}
                if ( !( defined $pinList->[$i]->{'MAX_TRANSITION'} ) ) { eprint("\t $dir pin $name not covered by max_transition\n"); $err = 1 }
        $err=1;
    }
        }
        if ( ( $dir eq "output" ) || ( $dir eq "io" ) ) {
        ## Expect pin arc
            if ( !$pinarc ) {
        my $isAsync = PinIsAsync($name);
        if (!$isAsync) {eprint("\t $dir pin $name does not have a pin arc\n")}
                if ( !( defined $pinList->[$i]->{'MAX_CAPACITANCE'} ) ) { eprint("\t $dir pin $name not covered by max_capacitance\n"); $err = 1 }
        $err=1;
            }
    }

    }
    if ($err) {iprint("@output")}
    return $err;
}

#------------------------------------------------------------------------------
sub CheckPinType {
    print_function_header();
    my $name = shift;
    
    my $PrintedName = 0;
    my $pinList = $g_PinHash{$name};
    my @output;
    push (@output,"Pin $name:\n");
    my $TheType;
    my $err = 0;
    for ( my $iview = 0 ; ( $iview < $g_ViewIdx ) ; $iview++ ) {
        my $type;
        if ( ( defined( $type = $pinList->[$iview]->{'TYPE'} ) ) ) {
            $g_TypeDefined = 1;  ##  A view is being read that includes a defined type
            $g_PinHashMerged{$name}->{'TYPE'} = Reconcile($g_PinHashMerged{$name}->{'TYPE'}, $type);
            my $viewname = $g_ViewList[$iview]->{'FILENAME'};
            push (@output,"\t$viewname: $type\n");
            if (!(defined $TheType)) {$TheType = $type} 
            else { $err ||= ($TheType ne $type)}
        }
    }
    if ($err) {iprint("@output")}
    return $err;
}

#------------------------------------------------------------------------------
sub CheckPinRelatedPower {
    print_function_header();
    my $name = shift;
    
    my $PrintedName = 0;
    my $pinList = $g_PinHash{$name};
    my @output;
    push (@output,"Pin $name:\n");
    my $TheRP;
    my $err = 0;
    for ( my $iview = 0 ; ( $iview < $g_ViewIdx ) ; $iview++ ) {
        my $rp;
        if ( ( defined( $rp = $pinList->[$iview]->{'RELATED_POWER'} ) ) ) {
            my $viewname = $g_ViewList[$iview]->{'FILENAME'};
            push (@output,"\t$viewname: $rp\n");
            if (!(defined $TheRP)) {$TheRP = $rp} 
            else { $err |= ($TheRP ne $rp)}
        }
    }
    if ($err) {iprint("@output")}
    return $err;
}

#------------------------------------------------------------------------------
sub CheckPinRelatedGround {
    print_function_header();
    my $name = shift;
    
    my $PrintedName = 0;
    my $pinList = $g_PinHash{$name};
    my @output;
    push (@output,"Pin $name:\n");
    my $TheRG;
    my $err = 0;
    for ( my $iview = 0 ; ( $iview < $g_ViewIdx ) ; $iview++ ) {
        my $rg;
        if ( ( defined( $rg = $pinList->[$iview]->{'RELATED_GROUND'} ) ) ) {
        my $viewname = $g_ViewList[$iview]->{'FILENAME'};
        push (@output,"\t$viewname: \"$rg\"\n");
        if (!(defined $TheRG)) {$TheRG = $rg} 
        else { $err |= ($TheRG ne $rg)}
    }
    }
    if ($err) {iprint("@output")}
    return $err;
}

#------------------------------------------------------------------------------
sub get_pgpins_from_pininfo_csv_files($) {
    print_function_header();
    my $aref_csv = shift;
    my $tmpFile;

    my @csv_pgPins; # capture all pgPins in this list
    
    if (@$aref_csv == 0) {return}   ##  No args specified.
    my @filelist;
    foreach my $file (@$aref_csv) {push(@filelist, glob($file))}

    if (@filelist == 0) { nprint "\n"; wprint("No files found for PIN INFO view: \n\t '@$aref_csv'\n" ); return}
    foreach my $csv_file ( @filelist ){
        unless( -r $csv_file ){
            nprint "\n";
            wprint("Read permissions don't allow parsing PIN INFO CSV file: '$csv_file'\n");
            next;
        }
        iprint("Reading PIN INFO CSV file: '$csv_file'\n");
        my @lines = read_file( $csv_file );
        my $line  = shift( @lines );
        chomp $line;
        $line =~ s/\s+//g;
        my %hdr;
        my @headers = split(/,/, $line);
        my $i = 0;
        foreach (@headers) {$hdr{$_} = $i++}  ## Build a hash to look up column numbers

        foreach my $line ( @lines ){
            chomp $line;
            $line =~ s/\s+//g;
            my @t = split(/,/, $line);
            my $pinname = GetCsvValue(\@t, $hdr{'name'});
            if (!$line) {next}
            #  TYPE = [ primary_ground, primary_power, general_signal ]
            my $pintype = GetCsvValue(\@t, $hdr{'pin_type'});
            if( $pintype =~ m/^(primary_ground|primary_power|general_signal)$/i ){
                if( $pintype =~ m/^primary/i ){
                    push(@csv_pgPins, $pinname);
                }
            }else{
                eprint( "PIN INFO CSV file has invalid TYPE for pin '$pinname': '$pintype'\n" 
                      . "Allowed TYPE values: primary_ground, primary_power, general_signal\n" );
            }
        } # END foreach line of CSV file
    } # END foreach CSV file
    return( @csv_pgPins );
}

#------------------------------------------------------------------------------
sub ReadCSV {
    print_function_header();
    my $csv = shift;
    my $tmpFile;
    
    if (@$csv == 0) {return}   ##  No args specified.
    my @filelist;
    foreach my $file (@$csv) {push(@filelist, glob($file))}

    if (@filelist == 0) { nprint "\n"; wprint("No files found \"@$csv\"\n"); return}
    foreach my $csv_file (@filelist) {
        if (!(-r $csv_file)) { nprint "\n"; wprint("CSV file \"$csv_file\" cannot be read\n"); next}
        iprint("Reading \"$csv_file\"\n");
        
        my @lines = read_file( $csv_file );
        my $line = shift( @lines );
        chomp $line;
        $line =~ s/\s+//g;
        my %hdr;
        my @headers = split(/,/, $line);
        my $i = 0;
        foreach (@headers) {$hdr{$_} = $i++}  ## Build a hash to look up column numbers

        my $area;
        foreach my $line ( @lines ){
            chomp $line;
            $line =~ s/\s+//g;
            my @t = split(/,/, $line);
            my $name = GetCsvValue(\@t, $hdr{'name'});
            if (!$line) {next}
            my $width = GetCsvValue(\@t, $hdr{'cell_x_dim_um'});
            my $height = GetCsvValue(\@t, $hdr{'cell_y_dim_um'});

            if ((defined $height) && (defined $width)) {$area = sprintf("%.6f", $width*$height)}
            my $dir = &StdDir(GetCsvValue(\@t, $hdr{'direction'}));
            my $pintype = GetCsvValue(\@t, $hdr{'pin_type'});
            my $related_power = GetCsvValue(\@t, $hdr{'related_power_pin'});
            if (!(defined $related_power)) {$related_power = GetCsvValue(\@t, $hdr{'related_power'})}
            my $related_ground = GetCsvValue(\@t, $hdr{'related_ground_pin'});
            if (!(defined $related_ground)) {$related_ground = GetCsvValue(\@t, $hdr{'related_ground'})}
            my $async = GetCsvValue(\@t, $hdr{'async_pin'});
            my $power_value = GetCsvValue(\@t, $hdr{'power_value'}) ;
            #               direction, pintype   relpwr          relgnd           pincap timings layer  filename
            StorePin($name, $dir,      $pintype, $related_power, $related_ground, undef, undef,  undef, $csv_file);
            addPinAttr($name, $g_ViewIdx, "ASYNC", $async);

            # Larissa Nitchougovskaia: For voltage markers check
            if($g_OptVflag) {
                addPinAttr($name, $g_ViewIdx, "POWER_VALUE", $power_value);
            }
        }

        # Larissa Nitchougovskaia: For voltage markers check
        if($g_OptVflag) { AssignPowerValues();}
        my $viewrec = {};
        $viewrec->{'FILENAME'} = $csv_file;
        $viewrec->{'AREA'} = $area;
        if ( defined($area) ) {
            dprint(HIGH, "AREA for pininfo type being set to '$area'\n");
        }
        $viewrec->{'TYPE'} = "pininfo";
        $viewrec->{'BRACKET'} = undef;
        $viewrec->{'NOPG'} = 0;
        $g_ViewList[$g_ViewIdx++] = $viewrec;

        $TypeCount{'pininfo'}++;
    }
}  ## END ReadCSV

# Larissa Nitchougovskaia: For voltage markers check
#------------------------------------------------------------------------------
sub AssignPowerValues {
    print_function_header();

   # global %g_PinHash and $g_ViewIdx
   my $rel_power_name;
   foreach my $pinname (keys %g_PinHash) {
       if( defined $g_PinHash{$pinname}->[$g_ViewIdx]) {

           if(exists $g_PinHash{$pinname}->[$g_ViewIdx]->{'POWER_VALUE'} && defined $g_PinHash{$pinname}->[$g_ViewIdx]->{'POWER_VALUE'} ) {
               next;
           }
           if ((exists $g_PinHash{$pinname}->[$g_ViewIdx]->{'RELATED_POWER'}) && (defined $g_PinHash{$pinname}->[$g_ViewIdx]->{'RELATED_POWER'} )) {

               $rel_power_name = $g_PinHash{$pinname}->[$g_ViewIdx]->{'RELATED_POWER'};
               if(exists $g_PinHash{$rel_power_name} && defined $g_PinHash{$rel_power_name}->[$g_ViewIdx] && exists $g_PinHash{$rel_power_name}->[$g_ViewIdx]->{'POWER_VALUE'} ) {
                   addPinAttr($pinname, $g_ViewIdx, "POWER_VALUE", $g_PinHash{$rel_power_name}->[$g_ViewIdx]->{'POWER_VALUE'});
               }
               else {
                   #printMsg("Read CSV Info: power pin $rel_power_name does not have 'power_value' attribute (for voltage markers check PinInfo-CDL)\n");
               }  
           }
       }
   }
}

#------------------------------------------------------------------------------
sub GetCsvValue {
    print_function_header();
    my $toks = shift;
    my $idx = shift;
    my $val;
    if ( !( defined $idx ) ) { 
        my $return_val = undef;
        return $return_val;
    }
    $val = $toks->[$idx];
    if (defined $val && $val eq "-") { $val = undef }
    if (defined $val && $val eq "") { $val = undef }
    return $val;
}

#------------------------------------------------------------------------------
sub getMdate {
    print_function_header();
    my $fileName = shift;

    if ( !( -e $fileName ) ) { 
        my $return_val = undef;
        return $return_val 
    }
    
    my @fstat = stat $fileName;
    return $fstat[9];
}

#------------------------------------------------------------------------------
sub findIncludeFile {
    print_function_header();
    my $incFile = shift;   ##  Name of the verilog file in question
    my $viewDir = shift;   ##  Dir in which the verilog view file lives
    my $incDirs = shift;   ##  Extra include dirs to search

    if (File::Spec->file_name_is_absolute($incFile)) {
        ##  File name is absolute.
        if (-r $incFile) {
            return $incFile;
        }
        else {
            eprint("Include file \"$incFile\" not found\n");
            my $return_val = undef;
            return $return_val;
        }
        }
    else {
        ## An absolute file.  Search for it.
        foreach my $incDir ($viewDir,@$incDirs) {
            my $incFileFull = "$incDir/$incFile";
            $incFileFull =~ s|/+|/|g;  ##  Get rid of redundant /'s.  Cosmetic
            if (-r $incFileFull) {return $incFileFull}
        }
        eprint("Could not find $incFile in any of $viewDir,@$incDirs\n");
        return;
    }
}

#------------------------------------------------------------------------------
sub ReadVerilog {
    print_function_header();
    my $verilog = shift;
    my $noPg    = shift;

    if (@$verilog == 0) {return}   ##  No args specified.

    my @filelist;
    foreach my $file (@$verilog) {push(@filelist, glob($file))}
    if (@filelist == 0) {wprint("No files found \"@$verilog\"\n"); return}

    ##  Deal with g_VerilogInclude

    my @opts;
    my @verilogIncludeDirs;
    if (defined $g_VerilogInclude) {
        $g_VerilogInclude =~ s/\s+//g;
        my @toks = split(/,/, $g_VerilogInclude);
        foreach my $tok (@toks) {
            $tok =~ s|/$||g;  ##  Get rid of redundant /'s.  Cosmetic
            push @opts, "+incdir+$tok";
            push @verilogIncludeDirs, $tok;
        }
    }
    if (defined $g_VerilogDefines) {
        $g_VerilogDefines =~ s/\s+//g;
        my @toks = split(/,/, $g_VerilogDefines);
        foreach my $tok (@toks) {
            $tok =~ s/=/,/;   ##  Convert "=" to ",". A value is optional.
            push @opts, "+define+$tok";
        }
    }

    my @includeFiles = ();
    if (defined $g_VerilogIncludeFiles) {
        $g_VerilogIncludeFiles =~ s/\s+//g;
        @includeFiles = split(/,/, $g_VerilogIncludeFiles);
    }

    foreach my $verilog_file (@filelist) {
        if (!(-r $verilog_file)) {eprint("Verilog file \"$verilog_file\" cannot be read\n"); return}

        my($verilogFileRoot, $verilogFileDir, $verilogFileSuffix) = fileparse(abs_path($verilog_file));
        $verilogFileDir =~ s|/$||g;  ##  Get rid of redundant /'s.  Cosmetic
        my $opt = new Verilog::Getopt;
        $opt->parameter( @opts );

        my $isInterface = ($verilogFileDir =~ m/interface/ );
        if ( $isInterface ){
            dprint(LOW, "isInterface='$isInterface' for file '$verilog_file'\n");
        }
        my $nl = new Verilog::Netlist (options => $opt,);
        foreach my $incFile (@includeFiles) {
            my $incFileFull = findIncludeFile($incFile, $verilogFileDir, \@verilogIncludeDirs);
            if (defined $incFileFull) {
                iprint("Reading $incFileFull\n");
                $nl->read_file (filename=>$incFileFull);
            }
        }
        iprint("Reading Verilog File '$verilog_file'\n");
        $nl->read_file (filename=>$verilog_file);

        #        print($nl->verilog_text);

        my $topmod = $nl->find_module($g_verilogmodule);
        if (!defined $topmod) {eprint("Module \"$g_verilogmodule\" not found in $verilog_file\n"); return}

        dprint(LOW, "sigs on ports_sorted\n");
        foreach my $sig ($topmod->ports_sorted) {
            ##  Have to get the associated net to see if it's a bus or not.
            my $name = $sig->name;
            dprint(LOW, "\tsig->name: '$name'\n");
            my $direction = &StdDir($sig->direction);
            my $pinnet = $topmod->find_net($name);
            my $lsb="?";
            my $msb;
            if ( defined $pinnet ) {
                $lsb = eval {$pinnet->lsb} if ( defined $pinnet->lsb );
                $msb = eval {$pinnet->msb} if ( defined $pinnet->msb );
            }else{
                wprint("alphaPinCheck.pl:ReadVerilog: Unable to find '$name' net in verilog file '$verilog'!\n");
            }

            if (defined $msb) { 
                if ( $isInterface ){
                    dprint(LOW, "\tmsb: StoreInterfacePin '$name'\n"); 
                    #                                                   pintype relpwr relgnd pincap timings layer  filename
                    StoreInterfacePin("$name\[$msb:$lsb\]", $direction, undef,  undef, undef, undef, undef,  undef, $verilog_file);
                }else{
                    dprint(LOW, "\tmsb: StorePin '$name'\n"); 
                    StorePin("$name\[$msb:$lsb\]",          $direction, undef,  undef, undef, undef, undef,  undef, $verilog_file);
                }
            }else{
                if ( $isInterface ){
                    dprint(LOW, "\t!msb: StoreInterfacePin '$name'\n"); 
                    #                                    pintype relpwr relgnd pincap timings layer  filename
                    StoreInterfacePin($name, $direction, undef,  undef, undef, undef, undef,  undef, $verilog_file);
                }else{
                    dprint(LOW, "\t!msb: StorePin '$name'\n"); 
                    StorePin($name,          $direction, undef,  undef, undef, undef, undef,  undef, $verilog_file);
                }
            }
        } # for sig on ports_sorted topmod
   
        dprint(LOW, "\tEnd sig Loop");

        # P10020416-40518
        # Some behavior verilog files have ifdef statements in them. Within
        # these ifdef statements there could be some ports that need to be
        # added to the pin list. This function will end up calling StorePin()
        my $status=0;
        my ($npins, $aref_pins) = find_pins_contained_within_ifdef_statements( 
                $verilog_file, \$status );
        foreach my $aref_pinobj ( @$aref_pins){
            my $name = @$aref_pinobj[0]; 
            my $dir  = @$aref_pinobj[1];
            if ( $isInterface ){
                #                        direction, pintype relpwr relgnd pincap timings layer  filename
                StoreInterfacePin($name, $dir,      undef,  undef, undef, undef, undef,  undef, $verilog_file);
                dprint(LOW, "\tifdef pins: StoreInterfacePin '$name'\n"); 
            }else{
                #                direction, pintype relpwr relgnd pincap timings layer  filename
                StorePin( $name, $dir,      undef,  undef, undef, undef, undef,  undef, $verilog_file);
                dprint(LOW, "\tifdef pins: StorePin '$name'\n"); 
            }
        }

        my $viewrec = {};
        $viewrec->{'FILENAME'} = $verilog_file;
        $viewrec->{'AREA'}    = undef;
        $viewrec->{'NOPG'}    = $noPg;
        $viewrec->{'TYPE'}    = "verilog";
        $viewrec->{'FMDATE'}  = getMdate($verilog_file);
        $viewrec->{'CDATE'}   = undef;  ##  There's nothing in a verilog to indicate creation date.
        $viewrec->{'BRACKET'} = undef;  ## No real bracket type in verilog
        $g_ViewList[$g_ViewIdx++] = $viewrec;

        $TypeCount{'verilog'}++;
    }
}  ## END ReadVerilog

sub pbc($){
    # enable this when you need to debug this script and you want to add
    # some prompting to continue in it.
    #
    #  prompt_before_continue( shift );
}

#------------------------------------------------------------------------------
# find_pins_contained_within_ifdef_statements
#
# Givin a filename path (to a verilog file). This will find all the 
# input|inout|output PINNAME within an ifdef.*_PG_PINS section.
# It will return the list as a reference to an array of array references.
# In each of this child array_refs contains  PINNAME, PINDIRECTION
#
# Example Verilog code snippit:
#
# `ifdef DWC_LPDDR5XPHY_PG_PINS
#   input VDD;    <-- semicolons are allowed
#   input VSS;
#   input VDD,    <-- commas are allowed
#   input VSS,
# `else
#    ...
# `endif
#
# Example:
#
# my $fname = <file name>;
# my ($status, $aref_pins) = find_pins_contained_within_ifdef_statements($fname);
# foreach my $pin_obj ( @$aref_pins) {
#   my $name = @$pin_obj[0];
#   my $direction = @$pin_obj[1];
#   print ("$direction $name\n");
# }
#
sub find_pins_contained_within_ifdef_statements($;$){
    my $verilog_file = shift;
    my $ref_status   = shift;

    my $FID;

    my $start_re = '`ifdef\s+.*_PG_PINS';
    my $end_re   = '`endif';
    my @pinlist;

    $$ref_status = 0  if ( $ref_status );

    if ( ! open($FID, "<", $verilog_file)){  #nolint open<
        wprint("Unable to open file '$verilog_file' reason: $!\n");
        if ( $ref_status ) {
            $$ref_status = -1;
        }

        return (0, \@pinlist);
    }

    my $curpos = 0;
    while ( $curpos != -1 ){
        my $aref_verilog_code;
        ($curpos, $aref_verilog_code) = ExtractTextBlock($FID, $curpos, $start_re, $end_re);
        if ( $curpos==0 || $curpos == -1 ){ #end of file
            viprint(LOW, "hit end of file\n");
            $curpos = -1;
        }else{
            foreach my $line ( @$aref_verilog_code) {
                my $name      = "";
                my $direction = "";

                if ( $line =~ m/^\s*(input|inout)\s+([^;]*);/ ){
                    $name      = $2;
                    $direction = 'input';
                } elsif ( $line =~ m/^\s*output\s+([^;]*);/ ){
                    $name      = $1;
                    $direction = 'output';
                } elsif ( $line =~ m/^\s*(input|inout)\s+([^,]*),/ ){
                    $name      = $2;
                    $direction = 'input';
                } elsif ( $line =~ m/^\s*output\s+([^,]*),/ ){
                    $name      = $1;
                    $direction = 'output';
                }


                if ( $name ne ""){
                    my @pinobj = ($name, $direction);
                    push(@pinlist, \@pinobj);
                }
            } # loop thru the lines of code
        } # else we found a match
    } # while we have not reached the end of the file
    close($FID);

    my $n = @pinlist;
    return ($n, \@pinlist);
}

#------------------------------------------------------------------------------
#  @pgPins = get_pgpins_from_pglib_files( \@liberty );
#  Gather PG pins from every PG liberty file (*_pg.lib). Build a list that
#      is the superset (union) of all PG pins in all files, and return it.
#------------------------------------------------------------------------------
sub get_pgpins_from_pglib_files($){
    print_function_header();
    pbc( CRAZY );
    my $liberty = shift;

    if (@$liberty == 0) {return}   ##  No args specified.

    my @filelist;
    # if $file uses a wildcard, collect all the valid targets
    foreach my $file ( @$liberty ){
        push(@filelist, glob($file));
    }

    my $Nfiles = @filelist;
    if ($Nfiles == 0) {wprint("No Liberty files found \"@$liberty\"\n"); return}

    my @obj_pg_pins;
    my @pg_pins;
    foreach my $liberty_file ( @filelist ){
        dprint(MEDIUM, "Reading liberty file: '$liberty_file'\n" );
        $g_SquareBracket = 0;
        $g_PointyBracket = 0;
        unless( -r $liberty_file ){ 
           wprint("Liberty file cannot be read: \n\t '$liberty_file' \n" );
           next;
        }
        iprint( "Reading liberty file: '$liberty_file'\n" );
        my $parser        = new Liberty::Parser; 
        my $library_group = $parser->read_file($liberty_file);
        my $lib_name      = $parser->get_group_name($library_group);
        # Example -> library(dwc_ddrphy_cmpana_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675vn40c) \openbrace 
        #         -> lib_name = dwc_ddrphy_cmpana_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675vn40c 
        dprint(MEDIUM, "Lib Name=> '$lib_name' \n" );
        checkLibname($lib_name, $liberty_file);
        pbc( MEDIUM );

        #--------------------------------------------
        #  Get group 'cell'  ...  Extract CELL name from LIB file
        #--------------------------------------------
        #   This parser is very touchy about finding groups.  Tends locate_cell
        #        tends to segfault when looking for a cell that's not there.
        #   This way seems resilient, and handles the case where there are
        #        multiple cells in a library.
        #--------------------------------------------
        my @allCells = $parser->get_groups_by_type($library_group, "cell");
        my $cell_group = undef;
        foreach my $cg (@allCells) {
            my $cell_group_name = $parser->get_group_name($cg); 
            dprint(SUPER, "LIBERTY:get_groups_by_type(cell)=> '$cell_group_name' \n" );
            pbc( SUPER );
            # Look for the MACRO named provided by user at cmd line with
            #    a valid CELL name in the LIB file. If found, then
            #    store the object reference in $cell_group.
            if ($parser->get_group_name($cg) eq $g_opt_macros) {
                $cell_group = $cg;
                my $cn = $parser->get_group_name($cg);
                last;
            }
        }

        unless( defined $cell_group ){
            eprint("Skipping cell '$g_opt_macros' because NOT found in LIB file: \n\t'$liberty_file'\n");
            next;
        }
        #--------------------------------------------
    
        #--------------------------------------------
        #  Valid Cell Attrs : area dont_touch
        #        dont_use interface_timing ff
        #        pg_pin pin bus
        #--------------------------------------------
        #  Get all the PINs, get attributes for each.
        #  Example from LIB file
        #      pin(PwrOkVDD) \openbrace
        #          direction : input ; 
        #          capacitance : 22.3 ; 
        #          input_voltage : default ; 
        #          max_transition : 100.0 ; 
        #      \closebrace
        #      pin(Cmpana_Out) \openbrace
        #          direction : output ; 
        #          max_capacitance : 10 ; 
        #          max_transition : 100 ; 
        #          min_capacitance : 0 ; 
        #          output_voltage : default_cmpana ; 
        #          related_ground_pin : VSS ; 
        #          related_power_pin : VDD ; 
        #          timing() \openbrace  
        #          related_pin : "Cmpdig_CmpanaClk" ; 
        #          timing_type : rising_edge ; 
        #          
        #          cell_fall(tmg_ntin_oload_5x7) \openbrace
        #             ...
        #--------------------------------------------
        #  Get all the PG PINs, get attributes for each.
        #        StorePin($name, $dir, $type, $r_pwr, $r_gnd, $cap, $timings, $layer, $file );
        #--------------------------------------------
        @obj_pg_pins = $parser->get_groups_by_type($cell_group, "pg_pin"); 
        foreach my $pg_pin (@obj_pg_pins) {
            my $pin_name = $parser->get_group_name($pg_pin);
            my $pg_type  = $parser->get_simple_attr_value($pg_pin, "pg_type");
            my $pg_dir   = &StdDir($parser->get_simple_attr_value($pg_pin, "direction"));
            dprint(MEDIUM, "LIB File Name  ='$liberty_file'\n");
            dprint(MEDIUM, "LIB Pin Name   ='$pin_name'\n");
            dprint(MEDIUM, "LIB Pin Type   ='$pg_type'\n");
            pbc(MEDIUM);
            push(@pg_pins, $pin_name);  
        }
    }  ## END  foreach my $liberty_file 
    return( @pg_pins );
}  ## END sub get_pgpins_from_pglib_files

#------------------------------------------------------------------------------
sub ReadLiberty {
    print_function_header();
    pbc( CRAZY );
    my $liberty = shift;
    my $noPg    = shift;

    if (@$liberty == 0) {return}   ##  No args specified.

    my @filelist;
    # if $file uses a wildcard, collect all the valid targets
    foreach my $file ( @$liberty ){
        push(@filelist, glob($file));
    }

    my $pintype = undef; # see StdType()

    my $Nfiles = @filelist;
    if ($Nfiles == 0) {wprint("No Liberty files found \"@$liberty\"\n"); return}

    foreach my $liberty_file ( @filelist ){
        dprint(SUPER, "Reading liberty file: '$liberty_file'\n" );
        $g_SquareBracket = 0;
        $g_PointyBracket = 0;
        unless( -r $liberty_file ){ 
           wprint("Liberty file \"$liberty_file\" cannot be read\n");
           next;
        }
        iprint("Reading $liberty_file\n");
        my $parser        = new Liberty::Parser; 
        my $library_group = $parser->read_file($liberty_file);
        if ($main::DEBUG >= SUPER ){
            dprint(SUPER, "LIBERTY:get_group_name=>". $parser->get_group_name($library_group) ."\n" );
        }
        #---------------------------------
        # PRINT the attr for the '$library_group'
        #---------------------------------
        #$parser->print_groups($library_group);
        #---------------------------------
        
        
        #---------------------------------
        # Example of Valid Groups -> results from '$parser->print_groups($library_group)'
        #---------------------------------
        # operating_conditions: fsg0p675vn40c 
        # input_voltage: default 
        # input_voltage: default_VDDQ 
        # input_voltage: default_cmpana 
        # output_voltage: default 
        # output_voltage: default_VDDQ 
        # output_voltage: default_cmpana 
        # type: default_1_0 
        # type: default_7_0 
        # lu_table_template: tmg_ntin_oload_5x7 
        # cell: dwc_ddrphy_cmpana 
        #---------------------------------
        pbc( SUPER );

        my $lib_name = $parser->get_group_name($library_group);
        # Example -> library(dwc_ddrphy_cmpana_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675vn40c)  
        #         -> lib_name = dwc_ddrphy_cmpana_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675vn40c 
        dprint(SUPER, "Lib Name=> '$lib_name' \n" );
        checkLibname($lib_name, $liberty_file);
        pbc( SUPER );

        my $leakage_power_unit = $parser->get_simple_attr_value ($library_group, "leakage_power_unit");
        my @opconds            = $parser->get_groups_by_type    ($library_group, "operating_conditions"); 
        my $Ncond              = @opconds;
        my $opcond_defined     = ($Ncond > 0);   ## At least one operating condition.
        my $tree_type_defined  = $opcond_defined;
        foreach my $opcond (@opconds) {
            if( !( defined $parser->get_simple_attr_value( $opcond, "tree_type" ) ) ) { $tree_type_defined = 0 }
        }

        #  Attributes that need 'GetValueFromPair'
        #  library_features
        #  capacitive_load_unit
        #  input_threshold_pct_fall
        #  input_threshold_pct_rise
        #  output_threshold_pct_fall
        #  output_threshold_pct_rise
        #  slew_derate_from_library
        #  slew_lower_threshold_pct_fall
        #  slew_lower_threshold_pct_rise
        #  slew_upper_threshold_pct_fall
        #  slew_upper_threshold_pct_rise
        #  nom_process
        #  nom_temperature
        #  nom_voltage
        #  default_cell_leakage_power
        #  default_fanout_load
        #  default_inout_pin_cap
        #  default_input_pin_cap
        #  default_leakage_power_density
        #  default_output_pin_cap
        #  default_max_capacitance
        #  default_max_transition
if( $DEBUG > CRAZY ){
        my @group_attrs = qw(
            delay_model date library_features time_unit voltage_unit current_unit
            capacitive_load_unit pulling_resistance_unit leakage_power_unit
            input_threshold_pct_fall
            input_threshold_pct_rise
            output_threshold_pct_fall
            output_threshold_pct_rise
            slew_derate_from_library
            slew_lower_threshold_pct_fall
            slew_lower_threshold_pct_rise
            slew_upper_threshold_pct_fall
            slew_upper_threshold_pct_rise
            nom_process
            nom_temperature
            nom_voltage
            default_cell_leakage_power
            default_fanout_load
            default_inout_pin_cap
            default_input_pin_cap
            default_leakage_power_density
            default_output_pin_cap
        );
        foreach my $attr ( @group_attrs ){
            my $value = $parser->get_simple_attr_value($library_group, $attr);
            if( defined $value ){
                dprint(CRAZY, "LIB Group Attr : $attr => $value \n" );
            }else{
                $value = GetValueFromPair( $parser->get_attr_with_value($library_group, $attr) );
                dprint(CRAZY, "LIB Group Attr : $attr => $value \n" );
            }
            pbc( CRAZY );
        }
}
        my $default_max_capacitance = GetValueFromPair($parser->get_attr_with_value($library_group, "default_max_capacitance"));
        my $default_max_transition  = GetValueFromPair($parser->get_attr_with_value($library_group, "default_max_transition"));

        my $creationDate = $parser->get_simple_attr_value($library_group, "date");
        my $cdate = undef;
        if ($creationDate) {
            $cdate = str2time($creationDate);
            iprint("Creation date '$creationDate' in LIB file:\n\t'$liberty_file'\n");
        }
        else {
            wprint("Creation date undefined in LIB file:\n\t'$liberty_file'\n");
        }
    
        #--------------------------------------------
        #  Get group 'lu_table_template'  ... 
        #--------------------------------------------
        my $tableHash = {};
        my @tables = $parser->get_groups_by_type($library_group, "lu_table_template"); 
        my $Ntable = @tables;
        foreach my $table (@tables) {
            my $table_name = $parser->get_group_name($table);
            dprint(SUPER, "LIBERTY:get_group_name=> 'lu_table_template' = '$table_name' \n" );
            pbc( SUPER );
        }
        #--------------------------------------------
    
        #--------------------------------------------
        # Extract time units from top level
        #--------------------------------------------
        # =====> time_unit : 1ps ; 
        my $time_unit = $parser->get_simple_attr_value($library_group, "time_unit");
            dprint(SUPER, "LIBERTY:get_simple_attr_value=> 'time_unit' = '$time_unit' \n" );
            pbc( SUPER );
        $time_unit =~ m/^(\d+)([a-zA-Z]+)/;  # e.g. $time_unit='1ps'
        if ($2 eq "ns") {$time_unit = "${1}e-9"}
        elsif ($2 eq "ps") {$time_unit = "${1}e-12"}
        else {eprint("Unrecognized time unit \"$time_unit\"\n")}
        #--------------------------------------------

        #--------------------------------------------
        #  Get group 'cell'  ...  Extract CELL name from LIB file
        #--------------------------------------------
        #   This parser is very touchy about finding groups.  Tends locate_cell
        #        tends to segfault when looking for a cell that's not there.
        #   This way seems resilient, and handles the case where there are
        #        multiple cells in a library.
        #--------------------------------------------
        my @allCells = $parser->get_groups_by_type($library_group, "cell");
        my $cell_group = undef;
        foreach my $cg (@allCells) {
            my $cell_group_name = $parser->get_group_name($cg); 
            dprint(SUPER, "LIBERTY:get_groups_by_type(cell)=> '$cell_group_name' \n" );
            pbc( SUPER );
            # Look for the MACRO named provided by user at cmd line with
            #    a valid CELL name in the LIB file. If found, then
            #    store the object reference in $cell_group.
            if ($parser->get_group_name($cg) eq $g_opt_macros) {
                $cell_group = $cg;
                my $cn = $parser->get_group_name($cg);
                last;
            }
        }

        unless( defined $cell_group ){
            eprint("Skipping cell '$g_opt_macros' because NOT found in LIB file: \n\t'$liberty_file'\n");
            next;
        }
        #--------------------------------------------
    
        #--------------------------------------------
        #  Valid Cell Attrs
        #
        #  area dont_touch dont_use interface_timing ff
        #  pg_pin pin bus
        #--------------------------------------------
        my $cell_leakage_power = GetValueFromPair($parser->get_attr_with_value($cell_group, "cell_leakage_power"));

        #--------------------------------------------
        #  Get AREA from LIB file
        my $areaval = $parser->get_attr_with_value($cell_group, "area");
        my $area = GetValueFromPair($areaval);
        $area = sprintf("%.6f", $area);
        #--------------------------------------------
        #  Get all the PINs, get attributes for each.
        #  Example from LIB file
        #      pin(PwrOkVDD) { 
        #          direction : input ; 
        #          capacitance : 22.3 ; 
        #          input_voltage : default ; 
        #          max_transition : 100.0 ; 
        #      }
        #      pin(Cmpana_Out) { 
        #          direction : output ; 
        #          max_capacitance : 10 ; 
        #          max_transition : 100 ; 
        #          min_capacitance : 0 ; 
        #          output_voltage : default_cmpana ; 
        #          related_ground_pin : VSS ; 
        #          related_power_pin : VDD ; 
        #          timing() { 
        #          related_pin : "Cmpdig_CmpanaClk" ; 
        #          timing_type : rising_edge ; 
        #          
        #          cell_fall(tmg_ntin_oload_5x7) {
        #             ...
        #--------------------------------------------
        #  Get all the PINs, get attributes for each.
        #--------------------------------------------
        my @pins = $parser->get_groups_by_type($cell_group, "pin"); 
        foreach my $pin (@pins) {
            my $pin_name       = $parser->get_group_name($pin);

            my $pincap         = GetValueFromPair( $parser->get_attr_with_value($pin, "capacitance") );
            my $direction      = StdDir          ( $parser->get_simple_attr_value($pin, "direction") );
            my $related_ground = $parser->get_simple_attr_value($pin, "related_ground_pin");
            my $related_power  = $parser->get_simple_attr_value($pin, "related_power_pin");
            ## "capacitance" is one of the attributes that won't read using get_simple_attr_val; read the pair and extract the value.
            my $max_capacitance = defineWithDefault($default_max_capacitance,
                                          GetValueFromPair($parser->get_attr_with_value($pin, "max_capacitance")));
            my $max_transition  = defineWithDefault($default_max_transition,
                                          GetValueFromPair($parser->get_attr_with_value($pin, "max_transition")));
            my $pintimings = GetTiming($parser, $pin);
            if( !defined $direction ){
               wprint( "'$pin_name' pin direction not found in LIB file: '$liberty_file'. \n" );
            }
            if( defined $direction && $direction ne "internal" ){
                StorePin($pin_name, $direction, $pintype, $related_power, $related_ground, $pincap, $pintimings, undef, $liberty_file );   ##  Simple pins have undefined type.
                addPinAttr($pin_name, $g_ViewIdx, "MAX_CAPACITANCE", $max_capacitance);
                addPinAttr($pin_name, $g_ViewIdx, "MAX_TRANSITION", $max_transition);
            }
        }
        #--------------------------------------------
        
        #--------------------------------------------
        #  Get all the PG PINs, get attributes for each.
        #        StorePin($name, $dir, $type, $r_pwr, $r_gnd, $cap, $timings, $layer, $file );
        #--------------------------------------------
        my @pg_pins = $parser->get_groups_by_type($cell_group, "pg_pin"); 
        foreach my $pg_pin (@pg_pins) {
            my $pin_name = $parser->get_group_name($pg_pin);
            my $pg_type  = $parser->get_simple_attr_value($pg_pin, "pg_type");
            my $pg_dir   = &StdDir($parser->get_simple_attr_value($pg_pin, "direction"));
            #                                               relpwr relgnd pincap timings layer  filename
            StorePin($pin_name, $pg_dir, StdType($pg_type), undef, undef, undef, undef,  undef, $liberty_file );
        }
        #--------------------------------------------
        #  Get all the BUS attributes
        #      bus(ZCalCompVOHDAC) { 
        #         bus_type : sis_ZCalCompVOHDAC_7 ; 
        #         capacitance : 1.454 ; 
        #         direction : input ; 
        #         max_transition : 100 ; 
        #
        #         pin(ZCalCompVOHDAC[0]) { 
        #            capacitance : 1.43 ; 
        #            direction : input ; 
        #            input_voltage : default ; 
        #            max_transition : 100 ; 
        #         }
        #      }
        #     ... cont'd
        #      bus(Cmpdig_CalDac) { 
        #         bus_type : default_7_0 ; 
        #         capacitance : 7.379 ; 
        #         direction : input ; 
        #         related_power_pin : VDD ; 
        #         related_ground_pin : VSS ; 
        #   
        #         pin(Cmpdig_CalDac[0]) { 
        #            capacitance : 8.316 ; 
        #            direction : input ; 
        #            input_voltage : default ; 
        #            max_transition : 100 ; 
        #         }
        #         pin(Cmpdig_CalDac[1]) { 
        #            capacitance : 8.215 ; 
        #            direction : input ; 
        #            input_voltage : default ; 
        #            max_transition : 100 ; 
        #         }
        #     ... cont'd
        #         pin(Cmpdig_CalDac[7]) { 
        #            capacitance : 6.728 ; 
        #            direction : input ; 
        #            input_voltage : default ; 
        #            max_transition : 100 ; 
        #         }  # END pin
        #      }  # END bus
        #--------------------------------------------
        my @buses = $parser->get_groups_by_type($cell_group, "bus");
        foreach my $bus ( @buses ){
            my $bus_name       = $parser->get_group_name($bus);
            my $direction      = StdDir($parser->get_simple_attr_value($bus, "direction"));
            my $related_power  = $parser->get_simple_attr_value($bus, "related_power_pin");
            my $related_ground = $parser->get_simple_attr_value($bus, "related_ground_pin");
            my $bus_type       = $parser->get_simple_attr_value($bus, "bus_type");
            my $buscap         = GetValueFromPair(
                   $parser->get_attr_with_value($bus, "capacitance"));  ## Not sure this is ever used.

            my $bus_max_capacitance = defineWithDefault($default_max_capacitance,
                    GetValueFromPair($parser->get_attr_with_value($bus, "max_capacitance")));
            my $bus_max_transition = defineWithDefault($default_max_transition,
                    GetValueFromPair($parser->get_attr_with_value($bus, "max_transition")));
        
            #--------------------------------------------------------------------------
            my $g         = $parser->locate_group($library_group, $bus_type);   
            my $bit_width = $parser->get_attr_with_value($g, "bit_width");
            my $bit_from  = $parser->get_attr_with_value($g, "bit_from");
            my $bit_to    = $parser->get_attr_with_value($g, "bit_to");
            $bit_width    = GetValueFromPair($bit_width);
            $bit_from     = GetValueFromPair($bit_from);
            $bit_to       = GetValueFromPair($bit_to);
            my $bustimings= GetTiming($parser, $bus);
            my $busOK     = 1;
            #--------------------------------------------------------------------------
            # Next line prints group attribtues
            # $parser->print_groups($library_group);
            #--------------------------------------------------------------------------
            dprint(INSANE, "#". '-'x30 ."\n");
            dprint(INSANE, "bit_width = $bit_width' \n" );
            dprint(INSANE, "bit_from  = $bit_from'  \n" );
            dprint(INSANE, "bit_to    = $bit_to'    \n" );
            dprint(INSANE, "#". '-'x30 ."\n");
            pbc(INSANE);

            my @constructed_bus_pin_names;
            if (($bit_from ne "") && ($bit_to ne "")) {
                #---------------------------------------
                # Construct expected bus pin names
                #---------------------------------------
                @constructed_bus_pin_names = bitBlast( "$bus_name\[$bit_from:$bit_to\]" );
                if ( $main::DEBUG >= HIGH) {
                    dprint(LOW, "Add pin to expected pins list:\n". scalar(Dumper \@constructed_bus_pin_names) ."\n" );
                    pbc(HIGH);
                }
                #---------------------------------------
                # Don't Store because they were seen explicitly.
                #---------------------------------------
                if( 0 ){
#                                                                        pintype 
                    StorePin("$bus_name\[$bit_from:$bit_to\]", $direction, undef,
                              $related_power, $related_ground, $buscap, $bustimings, $liberty_file);
                }
            }
            else {
                wprint("Bus \"$bus_name\" does not include msb/lsb info); Skipping\n");
                $busOK = 0;
            }
            my @buspins  = $parser->get_groups_by_type($bus, "pin");
            my @found_bus_pins;
            my $Nbuspins = @buspins;
            #-----------------------------------------------------------------------
            #  process each pin of the bus
            #-----------------------------------------------------------------------
            foreach my $pin ( @buspins ){
                my $pin_name = $parser->get_group_name($pin);
                push(@found_bus_pins, $pin_name);
                if ( $pin_name =~ m/^$bus_name[\[<]([0-9:]+)[\]>]/ ) {
                    my $idx = $1;   ##  Bus index.
                    ##  Process any bus-nested pin statements.
                    my $direction_p      = StdDir($parser->get_simple_attr_value($pin, "direction"));
                    my $related_power_p  =        $parser->get_simple_attr_value($pin, "related_power_pin");
                    my $related_ground_p =        $parser->get_simple_attr_value($pin, "related_ground_pin");
                    my $pincap_p         = GetValueFromPair($parser->get_attr_with_value($pin, "capacitance"));
                    ## If any of these are undefined, use the bus values
                    if( !defined $direction_p     ){ $direction_p      = $direction      }
                    if( !defined $pincap_p        ){ $pincap_p         = $buscap         }
                    if( !defined $related_power_p ){ $related_power_p  = $related_power  }
                    if( !defined $related_ground_p){ $related_ground_p = $related_ground }
                    my $pintimings = GetTiming($parser, $pin);

                    #                                pintype
                    StorePin($pin_name, $direction_p, undef, $related_power_p, $related_ground_p, $pincap_p, $pintimings, $liberty_file);
        
                    if( $direction ne "internal"){
                        CheckBusPin($pin_name, $direction, "signal", 
                                    $related_power, $related_ground,
                                    $pincap_p, $pintimings)
                    }
                    my $max_capacitance = defineWithDefault( $bus_max_capacitance,
                                GetValueFromPair($parser->get_attr_with_value($pin, "max_capacitance")));
                    my $max_transition = defineWithDefault( $bus_max_transition,
                                GetValueFromPair($parser->get_attr_with_value($pin, "max_transition")));
                    addPinAttr($pin_name, $g_ViewIdx, "MAX_CAPACITANCE", $max_capacitance);
                    addPinAttr($pin_name, $g_ViewIdx, "MAX_TRANSITION", $max_transition);
                }else{
                    eprint("Pin $pin_name of bus $bus_name has name mismatch\n");
                }
               # if( exists( $bus_pins_expected{ $pin } ) ){
               #     foreach my $pin ( keys %bus_pins_expected ){
               #         eprint("BUS definition includes $pin, but not bus pin not seend LIB file: \n\t '$liberty_file' \n" )
               #         $bus_pins_expected{ $pin }--;
               #     }
               # }
           } # END foreach my $pin ( @buspins )
             my($common, $firstOnly, $secondOnly, $bool__lists_equiv) = 
                    compare_lists( \@constructed_bus_pin_names, \@found_bus_pins );
             unless( $bool__lists_equiv ){
                 wprint( "In liberty file, bus '$bus_name' has width '". $#{constructed_bus_pin_names}
                       . "', but only found '". $#{found_bus_pins} ."' bus pins!\n"
                       . "\t Inspect liberty file: $liberty_file ...\n" );
                 if ( $main::DEBUG >= MEDIUM){
                     dprint(SUPER, "Const bus pins\n". scalar(Dumper \@constructed_bus_pin_names) ."\n" );
                     dprint(SUPER, "Found bus pins\n". scalar(Dumper \@found_bus_pins) ."\n" );
                     dprint(SUPER, "Common bus pins\n". scalar(Dumper $common) ."\n" );
                     dprint(HIGH, "Constr bus pins ONLY\n". scalar(Dumper $firstOnly) ."\n" );
                     dprint(HIGH, "Foud   bus pins ONLY\n". scalar(Dumper $secondOnly) ."\n" );
                     pbc(MEDIUM);
                 }
             }
        }  # END foreach my $bus (@buses) 
        #-----------------------------------------------------------------------
        my $viewrec                      = {};
        $viewrec->{'FILENAME'}           = $liberty_file;
        $viewrec->{'AREA'}               = $area;
        dprint(HIGH, "AREA for liberty type being set to '$area'\n");
        $viewrec->{'TYPE'}               = "liberty";
        $viewrec->{'NOPG'}               = $noPg;
        $viewrec->{'FMDATE'}             = getMdate($liberty_file);
        $viewrec->{'CDATE'}              = $cdate;
        $viewrec->{'PARSER'}             = $parser;
        $viewrec->{'TIME_UNIT'}          = $time_unit;
        $viewrec->{'LEAKAGE_POWER_UNIT'} = $leakage_power_unit;
        $viewrec->{'CELL_LEAKAGE_POWER'} = $cell_leakage_power;
        $viewrec->{'OPCOND_DEFINED'}     = $opcond_defined;
        $viewrec->{'TREE_TYPE_DEFINED'}  = $tree_type_defined;
        $viewrec->{'TABLES'}             = $tableHash;
        $viewrec->{'DEFAULT_MAX_CAPACITANCE'} = $default_max_capacitance;
        $viewrec->{'DEFAULT_MAX_TRANSITION'}  = $default_max_transition;
        setBracket($viewrec);
    
        $g_ViewList[$g_ViewIdx++] = $viewrec;

        $TypeCount{'liberty'}++;
    }  ## END  foreach my $liberty_file 
}  ## END sub ReadLiberty 

#------------------------------------------------------------------------------
#  Record the type of bracket used
#------------------------------------------------------------------------------
sub setBracket {
    my $rec = shift;

    ## Sets the  state of the BRACKET field of the pin record according to global flags.
    $rec->{'BRACKET'} = undef;
    if    ( $g_SquareBracket && !$g_PointyBracket ){ $rec->{'BRACKET'} = "square" }
    elsif (!$g_SquareBracket &&  $g_PointyBracket ){ $rec->{'BRACKET'} = "pointy" }
    elsif ( $g_SquareBracket &&  $g_PointyBracket ){ $rec->{'BRACKET'} = "mixed"  }
    
}

#------------------------------------------------------------------------------
sub defineWithDefault {
    my $default = shift;
    my $value = shift;

    if   ( defined $value ) { return $value }
    else                    { return $default }
}

#------------------------------------------------------------------------------
##  Checks that the library name matches the file name
#------------------------------------------------------------------------------
sub checkLibname {
    print_function_header();
    my $libname  = shift;
    my $filename = shift;

    my @filetoks  = split(/\//, $filename);
    my $rightname = pop(@filetoks);
    $rightname =~ s/(_pg)?\.lib(\.gz)?$//;  #  Strip ".lib" and optionally _pg.
    if($libname ne $rightname ){
        wprint("Library name \"$libname\" not correct in $filename\n");
        iprint("\tExpecting \"$rightname\"\n");
    }else{
        dprint(SUPER, "Library name \"$libname\" is correct in '$filename'.\n");
    }
}

#------------------------------------------------------------------------------
sub bitBlast {
#    print_function_header();
    ##  bit-blasts a pin name
    my $pinname = shift;

    my @pinlist;
    if( $pinname =~ m/(\w+)\[([0-9:]+)\]/ ){
        my $name = $1;
        my $idx = $2;

        if ( $idx =~ m/(\d+):(\d+)/ ) {
        ##  Bus index is a range
        my $from=$1;
        my $to=$2;
        if ($from>$to) {$from=$2; $to=$1}
        for (my $i=$from; ($i<=$to); $i++) {push @pinlist, "$name\[$i\]"}
    }
    else {push @pinlist, $pinname}  ## Single bit
    }
    else {push @pinlist, $pinname}  ##  Not a bus or bus bit

    return @pinlist;
}

#------------------------------------------------------------------------------
#  Once the pin information has been extracted, record it in hash
#------------------------------------------------------------------------------
sub StorePin {
    my $pinname        = shift;
    my $direction      = shift;
    my $pintype        = shift;
    my $related_power  = shift;
    my $related_ground = shift;
    my $pincap         = shift;
    my $pintimings     = shift;
    my $layer          = shift;
    my $filename       = shift || NULL_VAL ; # optional

    _StorePin(\%g_PinHash, $pinname, $direction, $pintype, $related_power,
        $related_ground, $pincap, $pintimings, $layer, $filename);

}

sub StoreInterfacePin {
    my $pinname        = shift;
    my $direction      = shift;
    my $pintype        = shift;
    my $related_power  = shift;
    my $related_ground = shift;
    my $pincap         = shift;
    my $pintimings     = shift;
    my $layer          = shift;
    my $filename       = shift || NULL_VAL ; # optional

    $g_InterfacePinCount++;

    _StorePin(\%g_InterfaceHash, $pinname, $direction, $pintype, $related_power,
        $related_ground, $pincap, $pintimings, $layer, $filename);

}


sub _StorePin {
    print_function_header();
    my $href_pinhash   = shift;
    my $pinname        = shift;
    my $direction      = shift;
    my $pintype        = shift;
    my $related_power  = shift;
    my $related_ground = shift;
    my $pincap         = shift;
    my $pintimings     = shift;
    my $layer          = shift;
    my $filename       = shift || NULL_VAL ; # optional

    if( $pinname =~ s/([[<])(.*)([\]>])/[$2]/ ){
        ## A bus
        if (!$1 && !$3) {}   ##  No brackets
        elsif( ($1 eq "[") && ($3 eq "]") ){ $g_SquareBracket = 1}
        elsif( ($1 eq "<") && ($3 eq ">") ){ $g_PointyBracket = 1 }
        else {
            wprint("Unexpected mixed brackets exist : $1  $3\n");
            $g_SquareBracket = 1;
            $g_PointyBracket = 1;
        }
    }

#    $pinname =~ tr/<>/[]/;   ##  Convert <> to []
    foreach my $pin ( bitBlast($pinname) ) {
        my $pinrec = $href_pinhash->{"$pin"}->[$g_ViewIdx];
        if (!(defined $pinrec)) {
            $pinrec = {};
            $href_pinhash->{"$pin"}->[$g_ViewIdx] = $pinrec;
        }
        $pinrec->{'VIEW_INDEX'}      = $g_ViewIdx;
        $pinrec->{'DIR'}             = Reconcile($pinrec->{'DIR'}, $direction);
        $pinrec->{'TYPE'}            = Reconcile($pinrec->{'TYPE'}, StdType($pintype));
        $pinrec->{'RELATED_POWER'}   = Reconcile($pinrec->{'RELATED_POWER'}, $related_power);
        $pinrec->{'RELATED_GROUND'}  = Reconcile($pinrec->{'RELATED_GROUND'}, $related_ground);
        $pinrec->{'PINCAP'}          = Reconcile($pinrec->{'PINCAP'}, $pincap);
        $pinrec->{'TIMINGS'}         = $pintimings;
        $pinrec->{'VIEW_NAME'}       = get_call_stack();
        $pinrec->{'FILENAME'}        = Reconcile($pinrec->{'FILENAME'}, $filename);  ## Note, sometimes this can end up as NULL_VAL
        if ( defined( $layer ) ){
            $pinrec->{'LAYER'}->{"$layer"} = 1;  ##  Stored as a hash.
        }
        #dprint(HIGH, "StorePin pin=$pin ViewIdx=$g_ViewIdx rec=$pinrec\n") ;

    } # foreach pin
    if( $DEBUG >= INSANE ){
        my $data_structure =  "\n".'-'x80 ."\n". "Global Pin Hash updated =>\n\t".scalar(Dumper $href_pinhash). "\n". '-'x80 ."\n" ;
        write_file( $data_structure, "mydatastruct.href" );
    }
    pbc(CRAZY);

} # end _StorePin

#------------------------------------------------------------------------------
#    Add an arbitrary attribute to a pin
#------------------------------------------------------------------------------
sub addPinAttr {
    my $pinname  = shift;
    my $iview    = shift;
    my $attrname = shift;
    my $attrval  = shift;
    
    $pinname =~ tr/<>/[]/;   ##  Convert <> to []
    foreach my $pin (bitBlast($pinname)) {
        $g_PinHash{$pin}->[$iview]->{$attrname} = $attrval;
    }
}

#------------------------------------------------------------------------------
# Process the bus-nested pin statements.  In this case, the pin should
#    already be stored, so just need to check direction and related-pin
#    consistency.
#------------------------------------------------------------------------------
sub CheckBusPin {
    print_function_header();
    my $pinname        = shift;
    my $direction      = shift;
    my $pintype        = shift;
    my $related_power  = shift;
    my $related_ground = shift;
    my $pincap         = shift;
    my $pintimings     = shift;

    dprint( CRAZY, "Info:  CheckBusPin $pinname\n" );
    foreach my $pin ( bitBlast($pinname) ) {
        ## Assign pin cap. A bit of a hack
        dprint( CRAZY, "\tInfo:  CheckBusPin $pin\n" );
 
        my $pinrec;
        if ( exists $g_PinHash{$pin} && defined $g_PinHash{$pin}->[$g_ViewIdx] ){
            $pinrec = $g_PinHash{$pin}->[$g_ViewIdx] ; 
        }else{
            $pinrec = {};
            $g_PinHash{$pin}->[$g_ViewIdx] = $pinrec;
        }
        $pinrec->{'VIEW_INDEX'} = $g_ViewIdx;
        $pinrec->{'PINCAP'}  = $pincap;
        $pinrec->{'TIMINGS'} = $pintimings;
        $pinrec->{'DIR'}     = $direction;
        $pinrec->{'TYPE'}    = StdType($pintype);
        $pinrec->{'RELATED_POWER'}  = $related_power;
        $pinrec->{'RELATED_GROUND'} = $related_ground;
    
        ReconcileBusPinAttr($pin, "DIR", $direction);
        ReconcileBusPinAttr($pin, "RELATED_POWER", $related_power);
        ReconcileBusPinAttr($pin, "RELATED_GROUND", $related_ground);
    }
}

#------------------------------------------------------------------------------
sub ReconcileBusPinAttr {
    print_function_header();
    ## Checks and applies pin overrides for bus pin attributes.
    my $pinname      = shift;
    my $attrName     = shift;
    my $pinAttrValue = shift;

    if( ! defined $pinAttrValue ){
        ##  No attribute set for pin.  No action
        return();
    }
    elsif( ! defined $g_PinHash{$pinname}->[$g_ViewIdx]->{$attrName} ){
        ##  Bus attribute not set.  Use pin attribute
        $g_PinHash{$pinname}->[$g_ViewIdx]->{$attrName} = $pinAttrValue;
    }
    else {
        ## Both bus and pin attribute set.  Make sure they match
        if( $g_PinHash{$pinname}->[$g_ViewIdx]->{$attrName} ne $pinAttrValue ){
            wprint("Bus/pin attribute \"$attrName\" mismatch for $pinname\n");
        }
    }
}

#------------------------------------------------------------------------------
# Globals that I see in this subroutine:
#   $g_Context 
#   %g_LefData -- I declared near the top of the code; it was never defined before
#------------------------------------------------------------------------------
sub ReadLef {
    print_function_header();
    my $lef = shift;

    if (@$lef == 0) {return}   ##  No args specified.

    my @filelist;
    $g_LefLayersHash    = {};
    $g_LefObsLayersHash = {};
    foreach my $file (@$lef) {push(@filelist, glob($file))}

    if (@filelist == 0) {wprint("No files found \"@$lef\"\n"); return}

    $g_FileName = undef;

    foreach my $lef_file (@filelist) {
        $g_SquareBracket = 0;
        $g_PointyBracket = 0;
        if (!(-r $lef_file) ){
            eprint("LEF file \"$lef_file\" cannot be read\n");
            return;
        }
        @g_LefGeomList   = ();  ##  Global list used to save the pin geometries for physical pin check.
        $g_Context       = \%g_LefData; 
        $g_LefMacroFound = 0;
        $LefAreaNR       = undef; 
        $g_FileName      = $lef_file;
        my $lNum         = 0;
        my $cdate;

        iprint("Reading $lef_file\n");
        my @lef_lines = read_file( $lef_file );
        foreach my $line ( @lef_lines ){
            $lNum++;
            if (($lNum < 5) && !$cdate) {
                ##  Expecting a "Creation Date" comment within the first few lines.
                if ($line =~ /#\s*Creation Date : (.*)/) {
                    $cdate = str2time($1);
                }
            }
            my @tokens = Tokenify($line);
            chomp $line;
            dprint(CRAZY, "Lef->$line\n" ) if ( $main::DEBUG >= CRAZY );
            LefProcessID(\@tokens);  # possible side-effect to update $LefAreaNR, write all pins to global hash upon END in file
            if ( $main::DEBUG >= CRAZY ) {
                dprint(CRAZY, "g_Context->".scalar(Dumper $g_Context)."\n" );
                dprint(CRAZY, "\%g_LefData->".scalar(Dumper \%g_LefData)."\n" );
            }
            pbc(MEDIUM);
        } # END foreach @lef_lines

        if( $g_LefMacroFound ){
            my $viewrec        = {};
            my $LayerList      = ();
            my $obsLayerList   = ();
            @$LayerList        = sort keys(%$g_LefLayersHash);
            @$obsLayerList     = sort keys(%$g_LefObsLayersHash);
   #gprint( "FILENAME = '$lef_file' \n" );
            $viewrec->{'FILENAME'} = $lef_file;
            $viewrec->{'AREA'}     = $LefArea;
            $viewrec->{'NOPG'}     = 0;
            $viewrec->{'FMDATE'}   = getMdate($lef_file);
            $viewrec->{'CDATE'}    = $cdate;
            dprint(HIGH, "ReadLef: LefArea is currently $LefArea\n");

            if (defined $LefAreaNR) {
                dprint(HIGH, "ReadLef: LefAreaNR is '$LefAreaNR'\n");
                $viewrec->{'AREA'} = sprintf("%.6f", $LefAreaNR);
                dprint(HIGH, "ReadLef: viewrec->{'AREA'} for 'lef' is now $viewrec->{'AREA'}\n");
            }  ##  Macro is non-rectangular.  Using the area defined by the OBS-->LAYER OVERLAP polygon.
            $viewrec->{'TYPE'}      = "lef";
            $viewrec->{'LAYERS'}    = $LayerList;
            $viewrec->{'OBSLAYERS'} = $obsLayerList;
            $viewrec->{'BBOX'}      = $LefBbox;
            if (@g_LefGeomList == 0) {
                $viewrec->{'GEOMLIST'} = undef;
            }
            else {
                $viewrec->{'GEOMLIST'} = [];
                my $ll = @g_LefGeomList;
                @{$viewrec->{'GEOMLIST'}} = @g_LefGeomList;
            }
            setBracket($viewrec);
            $g_ViewList[$g_ViewIdx++] = $viewrec;

            $TypeCount{'lef'}++;

    #        dprint(HIGH, "!!!  LEF area = $rec->{'AREA'}\n");
        }
        else {
            eprint("Macro '$g_opt_macros' not found in '$lef_file'\n");
        }
    }
    $g_FileName = undef;
    if ( $main::DEBUG >= HIGH ) {
        dprint(HIGH, '$g_Context => '.scalar(Dumper $g_Context)."\n" );
    }
    pbc( CRAZY );
    print_function_footer(); 
}

#------------------------------------------------------------------------------
# Used to parse the object from Liberty::Parser
#
#  Example lines from liberty file that require this subroutine
#
#  library_features(report_delay_calculation);
#  capacitive_load_unit(1, ff);
# 
#------------------------------------------------------------------------------
sub GetValueFromPair {
    print_function_header();
    my $pair = shift;

    chomp $pair;
    dprint(SUPER, "pair => '$pair'\n" );
       #-----------------------
       #  $pair can return multi-line value like ex below
       #-----------------------
       # capacitive_load_unit ( Boolean
       # ,\
       #       "ff");'
       #-----------------------
    if( $pair =~ m/(\S+)\s*:\s*(\S+)/ ){
       return $2;
    }elsif( $pair =~ m/(\S+)\s*\(\s*\"*([^\)]*)\"*\s*\)/ ){
       my $value = $2;
       $value =~ s/[\s"\\]*//g;
       return $value;
    }else{
       return;
    }
}

#------------------------------------------------------------------------------
#  Standardize by renaming the pin direction attributes
#------------------------------------------------------------------------------
sub StdDir {
    my $dir = shift;
    if( !defined $dir ){ return $dir }
    $dir = lc $dir;

    if   ( $dir eq "in"    ){ return "input"  }
    elsif( $dir eq "i"     ){ return "input"  }
    elsif( $dir eq "o"     ){ return "output" }
    elsif( $dir eq "b"     ){ return "io"     }
    elsif( $dir eq "out"   ){ return "output" }
    elsif( $dir eq "ioput" ){ return "io"     }
    elsif( $dir eq "inout" ){ return "io"     }
    else                    { return $dir     }
}

#------------------------------------------------------------------------------
# Standardize the pin TYPE field
#------------------------------------------------------------------------------
sub StdType {
    my $type = shift;
    if (!defined $type) {return $type}

    $type = lc $type;

    if    ($type eq "primary_ground") { return "ground" }
    elsif ($type eq "primary_power")  { return "power" }
    elsif ($type eq "general_signal") { return "signal" }
    elsif ($type eq "analog")         { return "signal" }
    elsif ($type eq "clock")          { return "signal" }
    else                              {return $type}
}


#------------------------------------------------------------------------------
#  This sub uses the '$id' to decide which callback to invoke, and it's
#      based on the string in each line of the LEF.
#
#  Callback Subroutine names ... STRING_callback where STRING is the 
#      string found in the LEF file.
#------------------------------------------------------------------------------
sub LefProcessID {
    my $aref_tokens = shift;   # a tokens from a line of text from the .lef file
    my $id = shift(@$aref_tokens);

    if( $id ){
        viprint(HIGH, "LefProcessID id='$id'\n");
        my $funcptr = $LefCallbacks{$id};
        if( defined $funcptr ){
            $LefCallbacks{$id}->($id, $aref_tokens);
        }
        else {
            # Don't ned to process this line in the LEF file.
            #wprint("Warning:  Unrecognized identifier  $id\n");
        }
    }
}

#------------------------------------------------------------------------------
sub Tokenify {
    ## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = trim(shift);
    return split(/\s+/, $line);
}

#------------------------------------------------------------------------------
sub BUSBITCHARS_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    my $busbitchars = shift(@$toks);
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    $g_Context->{'BUSBITCHARS'} = $busbitchars;
}

#------------------------------------------------------------------------------
sub CLASS_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    my $class = shift(@$toks);
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    $g_Context->{'CLASS'} = $class;
}

#------------------------------------------------------------------------------
sub DIRECTION_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    my $direction = shift(@$toks);
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    $g_Context->{'DIRECTION'} = $direction;
}

#------------------------------------------------------------------------------
sub DIVIDERCHAR_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    my $dividerchar = shift(@$toks);
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    $g_Context->{'DIVIDERCHAR'} = $dividerchar;
}

#------------------------------------------------------------------------------
sub END_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    my $filename = $g_FileName;

    my $pin = $toks->[0];
    if ( ! defined $pin ) {  # can be END of a PORT declaration
        #dprint(FUNCTIONS, "id=$id, tok=[".join(",",@$toks)."]\n" );
    }

    if ( defined($pin) && $g_StatePin && ( $pin eq $g_CurrentPin ) && ( $g_LefMacro eq $g_opt_macros ) ) {
        my $direction = StdDir($g_Context->{'DIRECTION'});
        my $type      = StdType($g_Context->{'USE'});
        my $layer     = $g_LefCurrentLayer;
        # Always store it in the normal pin list
        #                          type   relpwr relgnd pincap timings layer   filename
        StorePin($pin, $direction, $type, undef, undef, undef, undef,  $layer, $filename); #P10020416-39222

    #    printMsg("END PIN $pin $direction $type $layer\n");
    #    $g_StatePin = 0;
    }
    
#    $g_StatePin = 0;
#    $g_StateObs = 0;
    $g_Context = pop(@g_ContextStack);
    $g_Current = pop(@g_CurrentStack);
}

#------------------------------------------------------------------------------
sub FOREIGN_callback {
    ##  Not sure what this is yet..

}

#------------------------------------------------------------------------------
sub LAYER_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    my $layer = shift(@$toks);

    if (($g_LefMacro eq $g_opt_macros) && $g_StatePin) {
    $g_LefLayersHash->{$layer} = 1;
    $g_LefCurrentLayer = $layer;
    }
    if (($g_LefMacro eq $g_opt_macros) && $g_StateObs) {
    $g_LefObsLayersHash->{$layer} = 1;
    $g_LefCurrentLayer = $layer;
    }
    $g_Context->{'LAYER'} = $layer;
}

#------------------------------------------------------------------------------
# Globals:
#   $g_LefMacroFound
#
#------------------------------------------------------------------------------
sub MACRO_callback {
    print_function_header();
    my $id        = shift;
    my $toks      = shift;
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    my $macroName = shift(@$toks);

    $g_Context->{'MACRO'}->{$g_opt_macros} = {};

    if (defined($g_Current) && ($g_Current eq "TOP")) {
        ##  MACRO appears in multiple places.  Push context if at top level.
        push (@g_CurrentStack, $g_Current);
        $g_Current = $id;
        push (@g_ContextStack, $g_Context);
        $g_Context = $g_Context->{'MACRO'}->{$macroName};
    }

    $g_LefMacro = $macroName;
    if ($g_LefMacro eq $g_opt_macros){
        $g_LefMacroFound = 1;
    }
}

#------------------------------------------------------------------------------
sub OBS_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    $g_StateObs = 1;
    $g_StatePin = 0;
}

#------------------------------------------------------------------------------
sub ORIGIN_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    my $x = shift(@$toks);
    my $y = shift(@$toks);
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    $g_Context->{'ORIGIN'}->{'X'} = $x;
    $g_Context->{'ORIGIN'}->{'Y'} = $y;
}

#------------------------------------------------------------------------------
sub PIN_callback {
    print_function_header();
    my $id = shift;
    my $aref_toks = shift;
    dprint(SUPER, "id=$id, tok=[".join(",",@$aref_toks)."]\n" ) if ( $main::DEBUG >= SUPER);
    my $pin = shift(@$aref_toks);    

    $g_StatePin = 1;
    $g_StateObs = 0;
    $g_Context->{'PIN'}->{$pin} = {};
    if( $pin =~ m/\{\d+\]|\[\d+\}|\{\d+\}/ ){
       print_warning_if_bad_bitbuschar( $pin );
    }
    push (@g_CurrentStack, $g_Current);
    $g_Current = $id;
    push (@g_ContextStack, $g_Context);
    $g_Context = $g_Context->{'PIN'}->{$pin};
    $g_CurrentPin = $pin;

}

#---------------------------------------------------------------
#  Look for bad BUS BIT CHARs (brackets,braces,etc). Place mark
#     at the character position where the bad characters are found.
#     Print a 3 line warning if found.
#                                                                             v
#  -W- In LEF-> PIN Name contains invalid BUSBITCHARs: 'csrZCalCompGainCurrAdj{1}'
#                                                                               ^
#---------------------------------------------------------------
sub print_warning_if_bad_bitbuschar($){
    my $pin = shift;

    my $msg  = "In LEF-> PIN Name contains invalid BUSBITCHARs: ";
    my $num_chars = length( $msg );
       $msg .= "'$pin'\n";
    my $left_msg  = create_str_ptr_pos( $num_chars, $pin, '{', "^" );
    my $right_msg = create_str_ptr_pos( $num_chars, $pin, '}', 'v' );
    wprint( $right_msg ) unless( $right_msg eq EMPTY_STR );
    wprint( $msg  );
    wprint( $left_msg  ) unless( $left_msg  eq EMPTY_STR );
}
sub create_str_ptr_pos($$$$){
    my $num_chars    = shift;
    my $pin_name     = shift;
    my $search_char  = shift;
    my $pointer_char = shift;

    my $msg;
    my $pos_brace = index( $pin_name, $search_char );
    if( $pos_brace == -1){
        $msg = EMPTY_STR;
    }else{
        for(my $i=0; $i <= $num_chars + $pos_brace; $i++){
               $msg .= ' ';
        }
        $msg .= "$pointer_char\n";
    }

    return( $msg );
}

#------------------------------------------------------------------------------
sub PORT_callback {
    print_function_header();
    my $id = shift;
    dprint(SUPER, "id=$id, tok=[]\n" );

    $g_Context->{'PORT'} = {};
    push (@g_CurrentStack, $g_Current);
    $g_Current = $id;
    push (@g_ContextStack, $g_Context);
    $g_Context = $g_Context->{'PORT'};
}

#------------------------------------------------------------------------------
#
# Globals Referenced:
#   $LefAreaNR  - gets modified 
#
#------------------------------------------------------------------------------
sub RECT_callback {
    #print_function_header();
    my $id = shift;
    my $toks = shift;
    #dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" );
    
    if ($g_StatePin) {
    pop @$toks;  ##  Get rid of trailing ";"
    my $mask = undef;
    if ($toks->[0] eq "MASK") {
        ##  This is apparently a colored lef
        shift @$toks;
        $mask = shift @$toks;
    }
    saveRect($g_CurrentPin, $g_LefCurrentLayer, $toks, \@g_LefGeomList);
    }

    if ( $g_StateObs && ( $g_Context->{'LAYER'} eq "OVERLAP" ) && ( $g_LefMacro eq $g_opt_macros ) ) {
        $LefAreaNR += rectArea($toks);
        dprint(HIGH, "RECT_callback: updating \$LefAreaNR = '$LefAreaNR'\n") if ( $main::DEBUG >= HIGH);
    }
}

#------------------------------------------------------------------------------
#
# Globals Referenced:
#   $LefAreaNR - gets modified
#
#------------------------------------------------------------------------------
sub POLY_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    if (($g_StatePin) && ($g_LefMacro eq $g_opt_macros)) {
        ##  Duplicate first coords at end of list, as gds does.  Comes in handy later.
        pop @$toks;  ##  Get rid of trailing ";"
        push @$toks, $toks->[0];
        push @$toks, $toks->[1];
        my $mask = undef;
        if ($toks->[0] eq "MASK") {
            ##  This is apparently a colored lef
            shift @$toks;
            $mask = shift @$toks;
        }
        savePoly($g_CurrentPin, $g_LefCurrentLayer, $toks, \@g_LefGeomList);
    }

    dprint( CRAZY, "Polygon:  g_StateObs = $g_StateObs, Layer=$g_Context->{'LAYER'}\n" );
    if ($g_StateObs && ($g_Context->{'LAYER'} eq "OVERLAP") && ($g_LefMacro eq $g_opt_macros)){

    #    printMsg("\nWarning:  LEF is apparently non-rectangular); uncertain of area check robustness\n";
        $LefAreaNR += polygonArea($toks);
        dprint(HIGH, "POLY_callback: updating \$LefAreaNR = '$LefAreaNR'\n");
        checkOrigin($toks, "LEF");
    }
}

#------------------------------------------------------------------------------
##  Geometry data struct:
##
##  $geom->{'NAME'}:  Pin name
##  $geom->{'LAYER'}:  The simple layer name of the layer.
##  $geom->{'ISRECT'}:  True if it's a simple rectangle.
##  $geom->{'BBOX'}:  4-coord list of rectangular bounding box.
##  $geom->{'COORDS'}:  List of the coordinates.
#------------------------------------------------------------------------------
sub saveRect {
#    print_function_header();
    my ($pinName, $layer, $coords, $rectList) = @_;

    ## Should be just 4 coordinates.  Not sure if they're ordered, but we'll order them.
    if (@$coords == 4) {
    my $geom = {};
    $pinName =~ tr/<>/[]/;
    $geom->{'NAME'} = $pinName;
    $geom->{'LAYER'} = $layer;
    $geom->{'BBOX'} = ();  ##  4 coord list of the rectangular bounding box
    $geom->{'COORDS'} = [];
    $geom->{'ISRECT'} = 1;  ##  Mark it as simple rectangle.

    if ($coords->[0] > $coords->[2]) {
        $geom->{'BBOX'}->[0] = $coords->[2];
        $geom->{'BBOX'}->[2] = $coords->[0];
    }
    else {
        $geom->{'BBOX'}->[0] = $coords->[0];
        $geom->{'BBOX'}->[2] = $coords->[2];
    }

    if ($coords->[1] > $coords->[3]) {
        $geom->{'BBOX'}->[1] = $coords->[3];
        $geom->{'BBOX'}->[3] = $coords->[1];
    }
    else {
        $geom->{'BBOX'}->[1] = $coords->[1];
        $geom->{'BBOX'}->[3] = $coords->[3];
    }
    $geom->{'BBOX'}->[0] = coordFmt($geom->{'BBOX'}->[0]);
    $geom->{'BBOX'}->[1] = coordFmt($geom->{'BBOX'}->[1]);
    $geom->{'BBOX'}->[2] = coordFmt($geom->{'BBOX'}->[2]);
    $geom->{'BBOX'}->[3] = coordFmt($geom->{'BBOX'}->[3]);
        @{ $geom->{'COORDS'} } = (
            $geom->{'BBOX'}->[0], $geom->{'BBOX'}->[1], $geom->{'BBOX'}->[2], $geom->{'BBOX'}->[1], $geom->{'BBOX'}->[2],
            $geom->{'BBOX'}->[3], $geom->{'BBOX'}->[0], $geom->{'BBOX'}->[3], $geom->{'BBOX'}->[0], $geom->{'BBOX'}->[1]
        );
    push @$rectList,$geom;
    }
    else {
    eprint("Rectangle with more than 4 coords!!\n");
    iprint("\t$pinName $layer {@$coords}\n");
    }
}

#------------------------------------------------------------------------------
sub coordFmt {
    my $val = shift;
    my $valFmt = sprintf("%.6f", $val);
    return $valFmt;
}

#------------------------------------------------------------------------------
sub savePoly {
    print_function_header();
    my ($pinName, $layer, $coords, $geomList) = @_;

    my $geom = {};
    $pinName =~ tr/<>/[]/;
    $geom->{'NAME'} = $pinName;
    $geom->{'LAYER'} = $layer;
    $geom->{'BBOX'} = ();  ##  4 coord list of the rectangular bounding box
    $geom->{'COORDS'} = ();
    my ($isRect,$minX,$minY,$maxX,$maxY) = analyzePoly($coords);

    $geom->{'ISRECT'} = $isRect;  ##  Mark it as simple rectangle.
    $geom->{'BBOX'}->[0] = coordFmt($minX);
    $geom->{'BBOX'}->[1] = coordFmt($minY);
    $geom->{'BBOX'}->[2] = coordFmt($maxX);
    $geom->{'BBOX'}->[3] = coordFmt($maxY);
    ##  Format the coord's properly
    $geom->{'COORDS'} = [];
    foreach (@$coords) {push @{$geom->{'COORDS'}}, coordFmt($_)}
    dprint( CRAZY, "savePoly: @{$geom->{'BBOX'}}\n" ) if ( $main::DEBUG >= CRAZY);
    push @$geomList, $geom;
    my $ll = @$geomList;
}

#------------------------------------------------------------------------------
sub analyzePoly {
    print_function_header();
    my $coords = shift;

    ## Analyzes polygon, checking to see if it's a simple rectangle and returning the bbox
    ##  This assumes the first/last coords are the same.
    my ($minX,$minY,$maxX,$maxY, $xl, $yl, $x,$y);
    my $nCoord = @$coords;
    $minX = $coords->[0];
    $maxX = $coords->[0];
    $minY = $coords->[1];
    $maxY = $coords->[1];

    my $i;
    my $orthog = 1;
    for (my $i=2; ($i<$nCoord); $i+=2) {
    $x = $coords->[$i];
    $y = $coords->[$i+1];
    $xl = $coords->[$i-2];
    $yl = $coords->[$i-1];
    $minX = get_min_val($minX, $x);
    $minY = get_min_val($minY, $y);
    $maxX = get_max_val($maxX, $x);
    $maxY = get_max_val($maxY, $y);
    if (($x != $xl) && ($y != $yl)) {$orthog = 0}  ## Make sure only X or Y changes between pairs.
    }
    my $isRect = (($nCoord == 10) && $orthog);
    return($isRect,$minX,$minY,$maxX,$maxY);
}

#------------------------------------------------------------------------------
sub polygonArea {
    print_function_header();
    ## Calculates the area of a polygon
    ##  Algorithm for getting area measurement from http://www.mathopenref.com/coordpolygonarea.html
    my $coords = shift;   ##  List of coords, x1,y2,x2,y2,x3,y3
    if ( defined $DEBUG && $DEBUG > CRAZY) {
        my $coords_pretty = pretty_print_aref( $coords );
        dprint(HIGH, "\t\$coords = ' $coords_pretty '\n");
    }

    my $Ntoks = (@$coords);  ##  Total number of coords.  2x the number of vertices.
    if ($coords->[$Ntoks-1] eq ";"){
        pop @$coords; ## Get rid of trailing semicolon
        $Ntoks = $Ntoks - 1;
    }
    push(@$coords, $coords->[0]); 
    push(@$coords, $coords->[1]);   ##  Duplicate first set of coords
    $Ntoks = $Ntoks + 2;
    
    my $area = 0;
    for (my $i=0; ($i<($Ntoks-2)); $i+=2){
        my $x1 = $coords->[$i];
        my $y1 = $coords->[$i+1];
        my $x2 = $coords->[$i+2];
        my $y2 = $coords->[$i+3];
        my $component = ($x1*$y2) - ($y1*$x2);
        dprint(HIGH, "x1*y2 - y1*x2 area is $component\n");
        $area += $component; # ($x1*$y2) - ($y1*$x2);
        dprint(HIGH, "Area iter: \$i=$i  ($x1,$y1 ; $x2,$y2) area=$area\n");
    }
    $area = abs($area/2.0);
    $area = sprintf("%.6f", $area);
    dprint( CRAZY, "area: $area\n" );
    print_function_footer();
    return $area;
}

#------------------------------------------------------------------------------
sub rectArea {
    ## Calculates the area of a rectangle
    my $coords = shift;   ##  List of coords, x1,y2,x2,y2
    my $area;
    
    my $x1 = $coords->[0];
    my $y1 = $coords->[1];
    my $x2 = $coords->[2];
    my $y2 = $coords->[3];
    $area = abs(($x1-$x2)*($y1-$y2));
    $area = sprintf("%.6f", $area);
    return $area;
}

#------------------------------------------------------------------------------
sub SITE_callback {
    print_function_header();
##  Ignoring for now
}

#------------------------------------------------------------------------------
sub SIZE_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    my $width = shift(@$toks);
    my $by = shift(@$toks);
    my $height = shift(@$toks);
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    if ($g_LefMacro eq $g_opt_macros) {
    ##  Only process SIZE statements associated with the specified macro
        if ( $by eq "BY" ) {
            $g_Context->{'SIZE'}->{'WIDTH'} = $width;
            $g_Context->{'SIZE'}->{'HEIGHT'} = $height;
            $LefArea = sprintf("%.6f", $width*$height);
            ##  Need to adjust according to origin?
            my $x0 = coordFmt(0);
            my $y0 = coordFmt(0);
            my $x1 = coordFmt($width);
            my $y1 = coordFmt($height);
            @$LefBbox = ($x0,$y0,$x1,$y1);
        }
            else {
            wprint("\"SIZE\" not in expected format\n");
        }
    }
}

#------------------------------------------------------------------------------
sub SYMMETRY_callback {
    print_function_header();
##  Ignoring for now

}

sub USE_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    my $usage = shift(@$toks);

    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."],usage=$usage\n" ) if ( $main::DEBUG >= SUPER);
    $g_Context->{'USE'} = $usage;
}

#------------------------------------------------------------------------------
sub SHAPE_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    my $shape = shift(@$toks);
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."],shape=$shape\n" ) if ( $main::DEBUG >= SUPER);

    $g_Context->{'SHAPE'} = $shape;
}

#------------------------------------------------------------------------------
sub VERSION_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    my $version = shift(@$toks);
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."], version=$version\n" ) if ( $main::DEBUG >= SUPER);

    $g_Context->{'VERSION'} = $version;
}

#------------------------------------------------------------------------------
sub PROPERTYDEFINITIONS_callback {
    print_function_header();
    my $id = shift;
    my $toks = shift;
    dprint(SUPER, "id=$id, tok=[".join(",",@$toks)."]\n" ) if ( $main::DEBUG >= SUPER);

    $g_Context->{'PROPERTYDEFINITIONS'} = {};

    push (@g_CurrentStack, $g_Current);
    $g_Current = $id;
    push (@g_ContextStack, $g_Context);
    $g_Context = $g_Context->{'PROPERTYDEFINITIONS'};
}

#------------------------------------------------------------------------------
sub PROPERTY_callback {
    print_function_header();
##  Ignoring
}

#------------------------------------------------------------------------------
sub ReadCdl {
    print_function_header();
    my $aref_cdl = shift;
    if (@$aref_cdl == 0) {return}   ##  No args specified.

    my @filelist;
    foreach my $file (@$aref_cdl) {push(@filelist, glob($file))}

    if (@filelist == 0) {wprint("No files found \"@$aref_cdl\"\n"); return}

    $g_FileName = undef;

    foreach my $cdl_file (@filelist){
        $g_SquareBracket = 0;
        $g_PointyBracket = 0;
        if (!(-r $cdl_file)) {wprint("CDL file \"$cdl_file\" cannot be read\n"); return}
        iprint("Reading $cdl_file\n");
        my $foundMacroSubckt = 0;
        my $state = 0;
        my @subckt_toks;
        my @pininfo_toks;
        my %h_vflags;
        my $lNum = 0;
        my $cdate = undef;
        $g_FileName = $cdl_file;

        my @cdl_lines = read_file( $cdl_file );
        foreach my $line ( @cdl_lines ){
            $lNum++;
            if (($lNum < 4) && !$cdate) {
            ##  Expecting a comment with creation time information within the first three lines.
            ##  Check comments in the first three lines. and if the string converts to a valid time, we're assuming it's the date
            if (substr($line, 0, 1) eq "*") {
                my $maybeDate = substr($line, 1);
                my $maybeCdate = str2time($maybeDate);
                if ($maybeCdate) {$cdate = $maybeCdate}
            }
            }
            $line =~ s/\s*=\s*/=/g;  ##  Remove whitespace surrounding a "=" sign.
            my @toks = Tokenify($line);
            my $id='';
            if ( @toks ) {
                $id = lc(shift(@toks));
            }
            ##  Process the subcircuit upon encountering the .ends statement
            if ( $id eq ".ends" ) {
                $foundMacroSubckt |= ProcessSubckt(\@subckt_toks, \@pininfo_toks, \%h_vflags, $cdl_file); 
                $state=0;
            }
            if ( $state == 0 ) {
                ##  Not parsing anything.
                if ( lc $id eq ".subckt" ) {
                    @subckt_toks = ();
                    foreach (@toks) {push(@subckt_toks, $_)}
                    $state = 1;
                }
            }
            elsif ( $state == 1 ) {
                ##  Subckt in process.  Looking for conntinuations and pininfo.
                if (substr($id, 0, 1) eq "+"){
                    ## Continuation of subckt
                    substr($id, 0, 1, ""); ##  Remove continuation.
                    if ($id ne "") {push(@subckt_toks, $id)}
                    foreach (@toks) {push(@subckt_toks, $_)}
                }
                elsif ( $id eq "*.pininfo" ) {
                    foreach (@toks) {push(@pininfo_toks, $_)}
                    $state = 2;
                }
                else {
                    $state=2;
                }

            }
            elsif ( $state == 2 ) {
                ##  Processing a subckt, after the header.  Looking for pininfo only
                if ($id eq "*.pininfo") {
                   foreach (@toks ){
                       push(@pininfo_toks, $_);
                   }
                }

                # Larissa Nitchougovskaia: For voltage markers check
                elsif(($id =~ /^x/) && ($toks[1] =~ /^vflag_/) ) {
                   $toks[1] =~ s/vflag_//;
                   $toks[1] =~ s/(\d+)v(\d+)/$1.$2/;
                   $toks[1] =~ s/corev/core/;
                   $h_vflags{$toks[0]} = $toks[1];
                }
                elsif ( ( $id =~ /^x/ ) && ( $toks[1] =~ /^vflaghl$/ ) ) {
                   (grep{/vhigh=/ } @toks)[0] =~ /(\d+\.?\d+?)/;
                   $h_vflags{$toks[0]} = $1;
                }
            }
        }
        if ($foundMacroSubckt) {
            my $viewrec = {};
            $viewrec->{'FILENAME'} = $cdl_file;
            $viewrec->{'AREA'}     = undef;
            $viewrec->{'FMDATE'}   = getMdate($cdl_file);
            $viewrec->{'CDATE'}    = $cdate;
            $viewrec->{'TYPE'}     = "cdl";
            $viewrec->{'NOPG'}     = 0;
            setBracket($viewrec);
            $g_ViewList[$g_ViewIdx++] = $viewrec;

            $TypeCount{'cdl'}++;
        }
        else {
            eprint("Macro '$g_opt_macros' not found in '$cdl_file'\n");
        }
    }

    $g_FileName = undef;
} # ReadCdl

#------------------------------------------------------------------------------
#  store the CDL data
#------------------------------------------------------------------------------
sub ProcessSubckt {
    print_function_header();
    my $subckt_toks  = shift;
    my $pininfo_toks = shift;
    my $rh_vflags    = shift;
    my $cdl_file     = shift;

    my $pintype = undef; # see StdType() for what types we would expect
    my $status = 0;
    my $cellname = shift(@$subckt_toks);
    if ( ( lc $cellname ) eq ( lc $g_opt_macros ) ) {
        $status = 1;
        my $supressMissingPininfo = 0;
        if ( @$pininfo_toks == 0 ) {
            iprint("No pininfo provided for cell $g_opt_macros in $cdl_file; Direction checking disabled for this view\n");
            $supressMissingPininfo = 1;
        }

        my %pinhash;

        foreach my $pin (@$subckt_toks) {
            if (index($pin, "=") == -1) {$pinhash{$pin} = "X"}
        }
        foreach my $pininfo (@$pininfo_toks) {
            $pininfo =~ m/([^:]+):([^:]+)/;
            if( ! defined $pinhash{$1} ){
                eprint("Pininfo found for pin not in subckt: \"$1\"\n");
            }else{
                $pinhash{$1} = StdDir($2);
            }
        }
        foreach my $pin (@$subckt_toks) {
            if ( ( $pinhash{$pin} eq "X" ) && !$supressMissingPininfo ) {
                eprint("Missing pininfo for pin \"$pin\"; Direction checking for this pin is disabled\n");
                $pinhash{$pin} = undef;
            }
            if( $supressMissingPininfo ){
                $pinhash{$pin} = undef;
            }
#                          direction,      pintype    relpwr relgnd pincap timings layer  filename
            StorePin($pin, $pinhash{$pin}, $pintype,  undef, undef, undef, undef,  undef, $cdl_file); # P10020416-39222 

            # Larissa Nitchougovskaia: For voltage markers check
            addPinAttr($pin, $g_ViewIdx, "POWER_VALUE", $rh_vflags->{$pin});
        }
    }
    @$subckt_toks  = ();
    @$pininfo_toks = ();

    return $status;
}

#------------------------------------------------------------------------------
sub ShowUsage($) {
    my $status = shift;

    pod2usage(
        {
            -pathlist => "$RealBin",
            -exitval => $status,
            -verbose  => 1
        }
    );

}

#------------------------------------------------------------------------------
sub CheckLibertyTiming {
    print_function_header();
    ##  Generates a warning for output/io pins missing delay arcs (cell_rise, cell_fall, rise_transition, fall_transition)
    my $pinname = shift;
    my $i = shift;

    my $pinList = $g_PinHash{$pinname};
    my $PrintedName = 0;
    my $err = 0;
    my $missingerr = 0;
    my @output = ();
    my $filename = $g_ViewList[$i]->{'FILENAME'};
    my $time_unit = $g_ViewList[$i]->{'TIME_UNIT'};
    my $parser = $g_ViewList[$i]->{'PARSER'};
    my $dir = $pinList->[$i]->{'DIR'};
    my $timings = $pinList->[$i]->{'TIMINGS'};
    ##  BOZO: Should probably add a check for undefined timing; shouldn't occur, but you never know. Here, pins w/o a timing group return a 0-length list rather than undef.
    if ( $g_ViewList[$i]->{'TYPE'} eq "liberty" ) {
        if ( @$timings == 0 ) {
        ##  Lack of any timing arc is covered under a different check
            dprint( CRAZY, "\tWarning:  No timing at all exists for $dir pin $pinname\n" );
    }
        else {
            foreach my $t (@$timings) {
        my $related_pin = $parser->get_simple_attr_value($t, "related_pin");
        my $timing_type = $parser->get_simple_attr_value($t, "timing_type");
        my $timing_sense = $parser->get_simple_attr_value($t, "timing_sense");
        
        addPinAttr($pinname, $i, "PINARC", 1);   ##  Tag pin as having arc associated with it
        addPinAttr($related_pin, $i, "RELARC", 1);   ##  Tag related pin as having arc associated with it.
                dprint( CRAZY, "Attempting to extract table indexes from timing group\n" );
        
        my @cell_rise_list = $parser->get_groups_by_type($t, "cell_rise");
        my @cell_fall_list = $parser->get_groups_by_type($t, "cell_fall");
        my @rise_transition_list = $parser->get_groups_by_type($t, "rise_transition");
        my @fall_transition_list = $parser->get_groups_by_type($t, "fall_transition");
        my @rise_constraint_list = $parser->get_groups_by_type($t, "rise_constraint");
        my @fall_constraint_list = $parser->get_groups_by_type($t, "fall_constraint");
        my $cell_rise_groups = @cell_rise_list;
        my $cell_fall_groups = @cell_fall_list;
        my $rise_transition_groups = @rise_transition_list;
        my $fall_transition_groups = @fall_transition_list;
        my $missing_arcs;
        my $missingerr = 0;
        my $sep = "";
        if ($cell_rise_groups == 0) {$missing_arcs .= "${sep}cell_rise"; $sep=","; $missingerr=1}
        if ($cell_fall_groups == 0) {$missing_arcs .= "${sep}cell_fall"; $sep=",";$missingerr=1}
        if ($rise_transition_groups == 0) {$missing_arcs .= "${sep}rise_transition"; $sep=",";$missingerr=1}
        if ($fall_transition_groups == 0) {$missing_arcs .= "${sep}fall_transition"; $sep=",";$missingerr=1}
        ## Report partial missing-delay arcs unless it's a setup/hold arc.
                if ( ( !( $timing_type =~ m/(setup|hold)/ ) ) && ($missingerr) ) {
            wprint("\tWarning:  Arcs \"$missing_arcs\" missing for $dir pin $pinname, $timing_type/$timing_sense/$related_pin \n");
            $err=1;
        }
        
                if ($g_EnableTableChecks) {
            $err |= CheckOutliers($parser, $pinname, "cell_rise", \@cell_rise_list, $MINLIBDELAY, $MAXLIBDELAY, $timing_type, $related_pin, $timing_sense, $time_unit);
            $err |= CheckOutliers($parser, $pinname, "cell_fall", \@cell_fall_list, $MINLIBDELAY, $MAXLIBDELAY, $timing_type, $related_pin, $timing_sense, $time_unit);
            $err |= CheckOutliers($parser, $pinname, "rise_transition", \@rise_transition_list, $MINLIBTRAN, $MAXLIBTRAN, $timing_type, $related_pin, $timing_sense, $time_unit);
            $err |= CheckOutliers($parser, $pinname, "fall_transition", \@fall_transition_list, $MINLIBTRAN, $MAXLIBTRAN, $timing_type, $related_pin, $timing_sense, $time_unit);
            $err |= CheckOutliers($parser, $pinname, "rise_constraint", \@rise_constraint_list, $MINSnH, $MAXSnH, $timing_type, $related_pin, $timing_sense, $time_unit);
            $err |= CheckOutliers($parser, $pinname, "fall_constraint", \@fall_constraint_list, $MINSnH, $MAXSnH, $timing_type, $related_pin, $timing_sense, $time_unit);
            
            $err |= CheckMonotonicity($parser, $pinname, "cell_rise", \@cell_rise_list,  $timing_type, $related_pin, $timing_sense, $time_unit);
            $err |= CheckMonotonicity($parser, $pinname, "cell_fall", \@cell_fall_list,  $timing_type, $related_pin, $timing_sense, $time_unit);
            $err |= CheckMonotonicity($parser, $pinname, "rise_transition", \@rise_transition_list, $timing_type, $related_pin, $timing_sense, $time_unit);
            $err |= CheckMonotonicity($parser, $pinname, "fall_transition", \@fall_transition_list, $timing_type, $related_pin, $timing_sense, $time_unit);
            $err |= CheckMonotonicity($parser, $pinname, "rise_constraint", \@rise_constraint_list, $timing_type, $related_pin, $timing_sense, $time_unit);
            $err |= CheckMonotonicity($parser, $pinname, "fall_constraint", \@fall_constraint_list, $timing_type, $related_pin, $timing_sense, $time_unit);
        }
        }
    }
    }
    return $err;
}

#------------------------------------------------------------------------------
sub CheckMonotonicity {
    print_function_header();
    my $parser = shift;
    my $pinname = shift;
    my $id = shift;
    my $tlist = shift;
    my $timing_type = shift;
    my $related_pin = shift;
    my $timing_sense = shift;
    my $time_unit = shift;

    my $err = 0;
    foreach my $t (@$tlist) {
    my @table = $parser->get_lookup_table($t);
    my @tableTran;
    my $Nrows = @table;
    my $Ncols = @{$table[0]};
        dprint( CRAZY, "Check mono $pinname, $id.  rows=$Nrows, cols=$Ncols\n" );
        for ( my $row = 0 ; ( $row < $Nrows ) ; $row++ ) {
            if ( !CheckSingleMono( $table[$row], $time_unit ) ) {
        wprint("\t Non-monotonicity detected in row $row of $pinname, $timing_type/$timing_sense/$id/$related_pin:\n");
        iprint("\t\t@{$table[$row]}\n");
        }
    }

        for ( my $col = 0 ; ( $col < $Ncols ) ; $col++ ) {
        for (my $row=0; ($row<$Nrows); $row++) {$tableTran[$col]->[$row] = $table[$row]->[$col]}
            if ( !CheckSingleMono( $tableTran[$col], $time_unit ) ) {
        wprint("\t Non-monotonicity detected in column $col of $pinname, $timing_type/$timing_sense/$id/$related_pin:\n");
        iprint("\t\t@{$tableTran[$col]}\n");
        }
    }
    }
    return $err;
}

sub CheckSingleMono {
    print_function_header();
    ##  A pretty cimple-minded monotonicity check.
    ##  Needs to handle the nearly-flat case.
    my $array = shift;
    my $time_unit = shift;

    my $ll = @$array;
    my $i;
    my $dir;
    my $delta;
    my $IsMonotonic = 1;
    for ( $i = 1 ; ( $i < $ll ) ; $i++ ) {
    ##  To handle trivial non-mono issues, round to integer ps then consider delta=0 as ok.
    my $a = int(($array->[$i-1]*$time_unit*1e12)+0.5);
    my $b = int(($array->[$i]*$time_unit*1e12)+0.5);
    $delta = $b-$a;
        if ( defined $dir ) {
        $IsMonotonic &&= (($dir>=0)&&($delta>=0)) || (($dir<=0)&&($delta<=0));
    }
    else {$dir = $delta}
    }

    if (!$IsMonotonic) {$IsMonotonic = CheckSingleMonoFlat($array)}  ##  Check for flatness
    return $IsMonotonic;
}

#------------------------------------------------------------------------------
sub CheckSingleMonoFlat {
    print_function_header();
    ##  Checks for flat table row/column as a special case of non-monotonicity
    ##  See if all values are withing 1% of the average.
    my $array = shift;
    
    my $i = 0;
    my $avg = 0;
    foreach my $x (@$array) {$avg += $x; $i++}
    $avg /= $i;

    my $thresh = 0.01;
    foreach my $x (@$array) {
        if ( abs( ( $x - $avg ) / $avg ) > $thresh ) { return 0 }
    }
    return 1;
}

#------------------------------------------------------------------------------
sub CheckOutliers {
    print_function_header();
    my $parser = shift;
    my $pinname = shift;
    my $id = shift;
    my $tlist = shift;
    my $min = shift;
    my $max = shift;
    my $timing_type = shift;
    my $related_pin = shift;
    my $timing_sense = shift;
    my $time_unit = shift;

    my $err = 0;
    my $n = @$tlist;
    iprint("Checking outliers on $id.  max=$max, min=$min  ($n timing groups)\n");
    foreach my $t (@$tlist) {
        dprint( CRAZY, "Looking up timing table ... \n" );
    my @table = $parser->get_lookup_table($t);
        dprint( CRAZY, "Done\n" );
        foreach my $x (@table) {
            foreach my $y (@$x) {
        $y *= $time_unit;
        if ((defined $min) && ($y < $min)) {wprint("Outlier(min) value=$y for $pinname $id/$timing_type/$timing_sense/$related_pin\n"); $err=1}
        if ((defined $max) && ($y > $max)) {wprint("Outlier(max) value=$y for $pinname $id/$timing_type/$timing_sense/$related_pin\n"); $err=1}
        }
    }
    }
    return $err;
}

#------------------------------------------------------------------------------
sub GetTiming {
    print_function_header();
    my $parser = shift;
    my $pin = shift;

    my $pinname = $parser->get_group_name($pin);
    my @timings = $parser->get_groups_by_type($pin, "timing");
    return \@timings;
    
}

#------------------------------------------------------------------------------
sub isListed {
    my $str = shift;
    my $list = shift;

    foreach (@$list) {
        if ( $_ eq $str ) { return 1 }
    }
    return 0;
}

#------------------------------------------------------------------------------
sub sideGunzip {
    print_function_header();
    my $file = shift;

    my $tmpDir = "${TEMPDIR}/${PROGRAM_NAME}_${USERNAME}_gunzip_$$";
    if (!(-e $tmpDir)) {
        mkdir $tmpDir;
        if (!(-e $tmpDir)) {
            eprint("Could not create $tmpDir\n");
            return;
        }
    }
    if (!(-d $tmpDir)) {
        eprint("$tmpDir exists, not a directory\n");
        return;
    }

    my @o = `file $file`; # nolint
    if ( $main::VERBOSITY >= LOW ) {
        sprint("file $file\n@o");
    }

    if ($o[0] =~ /gzip compressed data/) {
        my @t = split /\//, $file;  ##  Get the base name
        my $basename = pop @t;
        my $gunzName = $basename;
        if ($basename =~ /(.*)\.gz/) {
            $gunzName = $1;
        }else{
            $gunzName = "$basename.gunz";
        }
        my $gunzFile = "$tmpDir/$gunzName";
        unlink $gunzFile if ( -e $gunzFile );
    #    `gunzip -c $file > $gunzFile`;
        my ($stdout_err, $status) = run_system_cmd( "gunzip -c $file > $gunzFile", $VERBOSITY);
        if (!(-e $gunzFile)) {
            wprint("gunzip of $file failed.\n$stdout_err\n");
            return;
        }
        dprint( CRAZY, ">>> $file --> $gunzFile\n" );
        return $gunzFile;
    }
    return;
}

#------------------------------------------------------------------------------
# Globals:
#   %g_LvGlayerMapReverse 
#   @g_BoundaryLayerList
#   $g_BoundaryLayer
#------------------------------------------------------------------------------
sub checkGdsPinLayer {
    print_function_header();

    my $textLayer = shift;
    my $geomLayer = shift;

    ## Quick check for boundary layer
    foreach my $l (@g_BoundaryLayerList) {
        if ( $geomLayer eq $l ) { return ( 0, undef ) }
    }
    dprint( CRAZY, "Checking $textLayer, $geomLayer\n" );

    dprint( CRAZY, "checkGdsPinLayer:  $textLayer, $geomLayer\n" );
    if ($g_LefVsGdsMap) {
        ##  Preferred solution.
        my $textLayerNameList = $g_LvGlayerMap{$textLayer};
        my $geomLayerNameList = $g_LvGlayerMap{$geomLayer};
        if (!$textLayerNameList || !$geomLayerNameList) {return(0,undef)}  ##  Either layer not in layermap.  Not a pin
        foreach my $pinLayer (keys %textOfMetal) {
            my $ToM = $textOfMetal{$pinLayer};
            my $ToMtextLayer = $g_LvGlayerMapReverse{$ToM};
            if (listContains($textLayerNameList, $ToM)) {
                ##  Have the right text layer.
                if (listContains($geomLayerNameList, $pinLayer)) {return(1,$pinLayer)}
            }
        }
        return(0,undef);  ##  Fell through with no match.
    }
    elsif (%g_streamLayerMap) {
        ##  A stream layermap was provided.  Does't provided the text/geom 
        ##   association, so just take the layer of the text.
        if (%g_streamLayerMap) {
            my $pinLayer = $g_streamLayerMap{$textLayer};
            if ($pinLayer =~ /(.*)\.(.*)/) {$pinLayer = $1}  ## Strip off the purpose.
            return(1,$pinLayer);
        }
    }
    else {
        ##  Neither layermap was provided.  
        dprint( CRAZY, "no layermap\n" );
        return(1,undef);
    }
}

#------------------------------------------------------------------------------
sub listContains {
    my $searchList = shift;
    my $value = shift;
    foreach (@$searchList) {
        if ( $_ eq $value ) { return 1 }
    }
    return 0;
}

#------------------------------------------------------------------------------
# GLOBALS:
#   @ignoreDatatypeList
#------------------------------------------------------------------------------
sub ReadGds {
    print_function_header();
    my $gds = shift;

    my $alphaGdsPinInfo = "$ScriptPath/msip_hipreGDSIICellPinInfo";
    my $useNewGdsPinInfo = 1;
    my $pintype = undef; # see StdType() for list of types

    if (@$gds == 0) {return}   ##  No args specified.
    my @filelist;
    foreach my $file (@$gds) {push(@filelist, glob($file))}

    if (@filelist == 0) {wprint("No files found \"@$gds\"\n"); return}

    $g_FileName = undef;

    foreach my $gds_file (@filelist) {
        $g_SquareBracket = 0;
        $g_PointyBracket = 0;
        my $cdate = undef;
        my $adate = undef;
        my $origGds = $gds_file;
        ## 6/1/2022 ljames, changed name from GdsGeomList to aref_GdsGeomList so
        ##          that it reflects the actual data-type and won't be confused
        ##          with the Global variable @GdsGeomList. Was this meant to 
        ##          reference the global variable? I don't know for sure. I do not
        ##          see any mention of @GdsGeomList anywhere. And only this subroutine
        ##          uses a variable with GdsGeomList in it.
        my $aref_GdsGeomList = [];
        my $dbu;
        my $prec = 6;  ##  Number of digits of precision, based on DBU of gds file.  Default to 6, if not specified.
        if (!(-r $gds_file)) {wprint("GDS file \"$gds_file\" cannot be read\n"); next}
        iprint("Reading $gds_file\n");
        my $gunzFile = sideGunzip($gds_file);
        if( defined $gunzFile ){
            if( -e $gunzFile ){
                $gds_file = $gunzFile;
            }
            else {
                next;
            }
        }
        else { next }
        ## Get pin and area (as defined by prBoundary)
        $g_FileName = $origGds; # P10020416-39222
        my @lines = ();
        push(@lines, "#!/bin/bash\n" );
        push(@lines, ". /global/etc/modules/3.1.6/init/sh\n" );
        push(@lines, "module purge\n" );
        push(@lines, "module load msip_hipre_gds_utils/2015.09\n" );
        my $forceOld = 0;
        if ($useNewGdsPinInfo && !$forceOld) {
            my $bLayers = $g_BoundaryLayer;
            $bLayers =~ tr/:/_/;
            ##  Going with non-strict, as some tech's have labels and geometries on different labels.
            ##  Basically, a label with *any* enclosing geometry counts as a label.
            push(@lines, "module unload msip_shell_lef_utils\n" );
            push(@lines, "module load msip_shell_lef_utils/2022.03\n" );
            push(@lines, "$alphaGdsPinInfo $gds_file $g_opt_macros          --nopath --format=alpha --prBoundary=\"$bLayers\" 2> GdsPinInfo.err\n" );
        }
        else{
            push(@lines, "msip_hipreGDSIICellPinInfo $gds_file $g_opt_macros 2> GdsPinInfo.err\n" );
        }
        write_file( \@lines, 'getGdsInfo.sh' );

        unlink "GdsPinInfo.err";
        my @output = `chmod +x getGdsInfo.sh; ./getGdsInfo.sh`;
        unlink "getGdsInfo.sh";
        my $GdsError = 0;
        my $fname = "GdsPinInfo.err";
        if ( open( my $ERR, $fname) ){  # nolint open<
            # Read 1st 1024 characters, should be entire file
            #    and return a '0'. If not end of file, $n > 0...
            my $GdsErrInfo;
            my $n = read $ERR, $GdsErrInfo, 1024;
            close $ERR;
            if( $n > 0 ){
                ##  Something in the error
                eprint( "While reading file '$fname', longer than 1024 characters!\n\n$GdsErrInfo\n");
                $GdsError = 1;
                next;
            }
        }
        unlink( $fname );

        my $area;
        my $pinname;
        my ($pr_minx, $pr_miny, $pr_maxx, $pr_maxy);
        my ($bb_minx, $bb_miny, $bb_maxx, $bb_maxy);
        my $areaCount = 0;
        my $areaInconsistent = 0;
        if ($useNewGdsPinInfo && !$forceOld) {
            iprint("Using alpha gds pininfo extractor\n");
            foreach (@output) {
                $_ = uncomment($_);
                my @toks = Tokenify($_);
                if (@toks == 0) {next}
                my $first = shift(@toks);
                if ($first eq "AREA") {
                    $areaCount++;
                    my $newArea = shift(@toks);
                    $newArea = sprintf("%.6f", $newArea);
                    if (defined $area) {
                        if ($area ne $newArea) {
                            wprint("GDS area inconsistency, $area ne $newArea\n");
                            $areaInconsistent = 1;
                        }
                    }
                    else {
                        $area = $newArea;
                    }
                }
                elsif ($first eq "DBU") {

                    #            $dbu = shift @toks;
                    #            my $tmp = sprintf("%.8f", $dbu);
                    #            $tmp =~ s/0+$//;  ##  Strip trailing zeros
                    #            $prec = length($tmp)-2;
                }
                elsif ($first eq "BOUNDARY") {
                    my $prBoundaryLayer = shift(@toks);
                    shift(@toks);
                    ($pr_minx, $pr_miny, $pr_maxx, $pr_maxy) = getBbox(\@toks);
                }
                elsif ($first eq "PIN") {

                    #PIN pinName textLayer textX textY geomLayer PATH|BOUNDARY [width] geomX1 geomY1 geomX2 geomX2 ...
                    $pinname = shift @toks;
                    my $pinTextLayer = shift @toks;
                    my $textX = shift @toks;
                    my $textY = shift @toks;
                    my $pinGeomLayer = shift @toks;
                    my $geomType = shift @toks;
                    ##   @toks now just a coord list.
                    if ($geomType ne "BOUNDARY") {next}   ##  Only gds BOUNDARY obj's (polygons) considered pins.  PATH's ignored.
                    #            my ($layer,$datatype) = split(/\./, $pinTextLayer);
                    #            my $pinLayer = $layer;
                    #             printMsg("$pinname $pinTextLayer $pinGeomLayer  $layer, $datatype\n");

                    #            NOTE: 4/21/2022 ljames -- The call to isListed() will always be FALSE, because $datatype is not declared anywhere
                    #            NOTE: 6/1/2022 ljames -- to get rid of a warning related to datatype not being defined I will set it to undef
                    my $datatype = undef;
                    if (!isListed($datatype, \@ignoreDatatypeList)) {
                        if ($pinname =~ /^[0-9.]/) { next }  ##  A voltage marker, not to be interpreted as a signal name.
                        if ($pinname =~ /^&/) { next }  ##  Ignoring tags as well.
                        my ($isPin, $pinLayer) = checkGdsPinLayer($pinTextLayer, $pinGeomLayer);
                        if ($isPin) {
                            #                  direc
                            #                  tion   type      relpwr relgnd pincap timings layer       filename 
                            StorePin($pinname, undef, $pintype, undef, undef, undef, undef,  $pinLayer, $g_FileName); # P10020416-39222 
                            if (defined $pinLayer) {savePoly($pinname, $pinLayer, \@toks, $aref_GdsGeomList)}  ##  Save the pin geometry
                        }
                    } 
                }
                elsif ($first eq "MDATE") {
                    ##  Going to have to assume that the gds MDATE is the actual creation date
                    $_ =~ /MDATE\s+"(.*)"/;
                    $cdate = str2time($1);
                }
                elsif ($first eq "ADATE") {
                    $_ =~ /ADATE\s+"(.*)"/;
                    $adate = str2time($1);
                }
            }
        }
        else  {
            ##  Using msip gds pin extractor
            my $pinname;
            my $pinTextLayer;
            foreach (@output) {
                $_ =~ s/,/ /g;    ##  Get rid of pesky commas.
                my @toks = Tokenify($_);
                if (@toks == 0) {next}
                my $first = shift(@toks);
                if ( substr( $first, 0, 2 ) eq "--" ) {
                    ##  It's not a pin name

                    if ( $first eq "--BOUNDARY" ) {
                        ##  Working with a boundary object.
                        my $geomLayer = shift(@toks);
                        if ( isListed( $geomLayer, \@g_BoundaryLayerList ) ) {
                            ##  It's a prBoundary shape.  Get the area.
                            pop(@toks);
                            pop(@toks);    ##  Get rid of redundant coords.
                            checkOrigin(\@toks, $gds_file);
                            ($pr_minx, $pr_miny, $pr_maxx, $pr_maxy) = getBbox(\@toks);
                            my $newArea = polygonArea(\@toks);
                            if ( defined $area ) {
                                if ($area ne $newArea) {wprint("GDS area inconsistency for pin $pinname, $area ne $newArea\n")}
                            } 
                            else {
                                $area = $newArea;
                                ($pr_minx, $pr_miny, $pr_maxx, $pr_maxy) = getBbox(\@toks);
                            }
                        }
                        else {
                            ##  Check to see if it's a pin
                            my ($isPin, $pinLayer) = checkGdsPinLayer($pinTextLayer, $geomLayer);
                            if ($isPin) {
                            #                      direc
                            #                      tion   type      relpwr relgnd pincap timings layer       filename 
                                StorePin($pinname, undef, $pintype, undef, undef, undef, undef, $pinLayer, $g_FileName); # P10020416-39222                                 if (defined $pinLayer) {savePoly($pinname, $pinLayer, \@toks, $aref_GdsGeomList)}  ##  Save the pin geometry
                            }
                        }
                    }
                }
                else {
                    ##  A text
                    if ($_ =~ /(\S+)\s+(\(.*\))\s+(\d+_\d+)/) {
                        $pinname = $1;
                        $pinTextLayer = $3;
                    }
                    else {
                        eprint("Could not interpret GDS pininfo line \"$_\"\n");
                    }
                }
            }
        }

        if ($areaCount > 1) {
            wprint("Multiple ($areaCount) prBoundary polygons detected\n");
            if ($areaInconsistent) {$area = undef}
        }
        ## Get bbox info for cell to see if there's geometry outside prBoundary
        if( !$GdsError ){
            my @lines=();
            push(@lines, "#!/bin/bash\n" );
            push(@lines, ". /global/etc/modules/3.1.6/init/sh\n" );
            push(@lines, "module purge\n" );
            push(@lines, "module load icwbev_plus\n" );
            push(@lines, "icwbev -run icwb_config -nodisplay\n" );
            write_file( \@lines, "bash_config.sh" );

            @lines=();
            push(@lines, "layout open $gds_file ??\n" );
            push(@lines, "cell bbox -cell $g_opt_macros\n" );
            push(@lines, "layout uu_per_dbu\n" );
            push(@lines, "exit\n" );
            write_file( \@lines, "icwb_config" );

            my @ICWBoutput = `chmod +x bash_config.sh; ./bash_config.sh`;
            unlink "bash_config.sh";
            unlink "icwb_config";
            ##  Get the layout DBU.  This way we don't rely on the pin extractor to get it
            my $line = pop(@ICWBoutput);
            my @toks = Tokenify($line);
            if (@toks == 2) {
                shift(@toks);  ## Throw away "#->" token
                $dbu = shift(@toks);

                #        print "dbu = $dbu\n";
                $dbu = sprintf("%.8f", $dbu*1e6);  ## Convert to microns and format.
                $dbu =~ s/0+$//;  ##  Strip trailing zeros
                $prec = length($dbu)-2;
            }

            $line = pop(@ICWBoutput);
            @toks = Tokenify($line);
            if ( @toks == 5 ) {
                ##  Line has the expected number of tokens.
                shift(@toks);  ## Throw away "#->" token
                ($bb_minx, $bb_miny, $bb_maxx, $bb_maxy) = getBbox(\@toks);

                #        printMsg("$bb_minx, $bb_miny, $bb_maxx, $bb_maxy\n");
                ## icwbev reports in nm apparently, though I can't find anywhere that says so.  Convert these coords to um.
                $bb_minx /= 1000;
                $bb_miny /= 1000;
                $bb_maxx /= 1000;
                $bb_maxy /= 1000;
            }
        }
        else {
            wprint("Skipping extraction of gds cell Bbox due to previous error\n");
            $bb_minx = 0;
            $bb_miny = 0;
            $bb_maxx = 0;
            $bb_maxy = 0;
        }

        my $viewrec = {};
        if ( fCmp( $pr_minx, $bb_minx, $prec ) || fCmp( $pr_miny, $bb_miny, $prec ) || fCmp( $pr_maxx, $bb_maxx, $prec ) || fCmp( $pr_maxy, $bb_maxy, $prec ) ) {
            my $msg = sprintf "Warning:  GDS prBoundary bbox (%.*f,%.*f:%.*f,%.*f) does not equal cell bbox (%.*f,%.*f:%.*f,%.*f)\n", 
            $prec,$pr_minx,$prec,$pr_miny,$prec,$pr_maxx,$prec,$pr_maxy,$prec,$bb_minx,$prec,$bb_miny,$prec,$bb_maxx,$prec,$bb_maxy;
            iprint($msg);
        }

        $viewrec->{'FILENAME'} = $origGds;
        $viewrec->{'AREA'} = $area;
        $viewrec->{'TYPE'} = "gds";
        $viewrec->{'NOPG'} = 0;
        $viewrec->{'FMDATE'} = getMdate($gds_file);
        $viewrec->{'CDATE'} = $cdate;
        if (@$aref_GdsGeomList == 0) {
            $viewrec->{'GEOMLIST'} = undef;
        }
        else {
            $viewrec->{'GEOMLIST'} = $aref_GdsGeomList;
        }
        $viewrec->{'DBU'} = $dbu;
        $viewrec->{'PREC'} = $prec;
        $pr_minx = coordFmt($pr_minx);
        $pr_miny = coordFmt($pr_miny);
        $pr_maxx = coordFmt($pr_maxx);
        $pr_maxy = coordFmt($pr_maxy);
        @{$viewrec->{'BBOX'}} = ($pr_minx,$pr_miny,$pr_maxx,$pr_maxy);
        setBracket($viewrec);
        $g_ViewList[$g_ViewIdx++] = $viewrec;

        $TypeCount{'gds'}++;
        if (defined $gunzFile) {
            unlink $gunzFile if (-e $gunzFile);
        }
        scrubRedundantGeometries($viewrec);
    }
} # end ReadGds

# Globals: origGds
#------------------------------------------------------------------------------
sub ReadOas {
    print_function_header();
    my $oas = shift;

    my $pintype = undef; # see StdType() for a list of known types

    if (@$oas == 0) {return}   ##  No args specified.
    my @filelist;
    foreach my $file (@$oas) {
        push( @filelist, glob($file) );
    }

    if (@filelist == 0) {wprint("No files found \"@$oas\"\n"); return}

    if (!defined $g_LefVsGdsMap) {
    wprint("The lefVsGdsMap file must be defined to read oas, either directly with -lefVsGdsMap or indirectly with -tech\n");
    return;
    }

    foreach my $oas_file (@filelist) {
    $g_SquareBracket = 0;
    $g_PointyBracket = 0;
    my $cdate = undef;
    my $adate = undef;
    my $origOas = $oas_file;
    my $OasGeomList = [];
    my $dbu;
    my $prec = 6;  ##  Number of digits of precision, based on DBU of oas file.  Default to 6, if not specified.
    if (!(-r $oas_file)) {wprint("Oasis file \"$oas_file\" cannot be read\n"); next}
    iprint("Reading $oas_file\n");
    my $gunzFile = sideGunzip($oas_file);
    $g_FileName = $oas_file;

    if (defined $gunzFile) {
        if (-e $gunzFile) {
        $oas_file = $gunzFile;
            }
            else { next }
    }
    ## Get pin and area (as defined by prBoundary)

    ##  Oas (and gds) pin extraction utility is $MSIP_SHELL_LEF_UTILS/utils/StreamPinDumper

    ##  BOZO:  Do work in $TEMPDIR (ie. /tmp)
        my @lines = ();
        push(@lines, "#!/bin/bash\n" );
        push(@lines, ". /global/etc/modules/3.1.6/init/sh\n" );
        push(@lines, "module purge\n" );
        push(@lines, "module load msip_shell_lef_utils\n" );
        push(@lines, "\$MSIP_SHELL_LEF_UTILS/utils/StreamPinDumper $oas_file $g_opt_macros $g_LefVsGdsMap 2> oasPinInfo.err\n" );
        write_file( \@lines, 'getOasInfo.sh' );
    
    unlink "$g_opt_macros.oasinfo";
    unlink "$g_opt_macros.ascii";
    my @output = `chmod +x getOasInfo.sh; ./getOasInfo.sh`;
    unlink "getOasInfo.sh";
    my $GdsError = 0;

    if (!(-e "$g_opt_macros.ascii")) {
        eprint("Failed to extract pin info from $oas_file\n");
        printFile("oasPinInfo.err");
        next;
    }
    else {
        my @fstat = stat "$g_opt_macros.ascii";
        if ($fstat[7] == 0) {
            eprint("Failed to extract pin info from $oas_file\n");
            printFile("oasPinInfo.err");
            next;
        }
    }

    my $INFO;
    unless( open( $INFO, "$g_opt_macros.ascii" ) ){   # nolint open<
       eprint("Failed to open pin info from $oas_file\n");
       next;
    }

    unlink "oasPinInfo.err";

    my $area;
    my $pinname;
    my ($pr_minx, $pr_miny, $pr_maxx, $pr_maxy);
    my ($bb_minx, $bb_miny, $bb_maxx, $bb_maxy);
    my $areaCount = 0;
    my $areaInconsistent = 0;
    ##  Using msip gds pin extractor
    my $pinTextLayer;
    my $oasPininfoFile = "$g_opt_macros.ascii";
    my $oasError = 0;

        while (<$INFO>) {
        $bb_minx = 0;
        $bb_miny = 0;
        $bb_maxx = 0;
        $bb_maxy = 0;
        $pr_minx = 0;
        $pr_miny = 0;
        $pr_maxx = 0;
        $pr_maxy = 0;
        $_ =~ s/,/ /g;    ##  Get rid of pesky commas.
        my @toks = Tokenify($_);
        if (@toks == 0) {next}
        my $first = shift(@toks);

            if ( substr( $first, 0, 2 ) eq "--" ) {
        ##  It's not a pin name
        
                if ( $first eq "--BOUNDARY" ) {
            ##  Working with a boundary object.
            my $geomLayer = shift(@toks);
                    if ( isListed( $geomLayer, \@g_BoundaryLayerList ) ) {
            ##  It's a prBoundary shape.  Get the area.
                        pop(@toks);
                        pop(@toks);    ##  Get rid of redundant coords.
            checkOrigin(\@toks, $oas_file);
            ($pr_minx, $pr_miny, $pr_maxx, $pr_maxy) = getBbox(\@toks);
            my $newArea = polygonArea(\@toks);
            if (defined $area) {
                if ($area ne $newArea) {wprint("Oasis area inconsistency for pin $pinname, $area ne $newArea\n")}
                        }
                        else {
                $area = $newArea;
                ($pr_minx, $pr_miny, $pr_maxx, $pr_maxy) = getBbox(\@toks);
            }
                    }
                    else {
            ##  Check to see if it's a pin
            my ($isPin, $pinLayer) = checkGdsPinLayer($pinTextLayer, $geomLayer);
            if ($isPin) {
                #                  direc
                #                  tion   type      relpwr relgnd pincap timings layer       filename 
                StorePin($pinname, undef, $pintype, undef, undef, undef, undef, $pinLayer, $g_FileName); # P10020416-39222 ljames researching, FILENAME ends up as NULL_VAL because it's missing an argument (on purpose? I don't know)
                if (defined $pinLayer) {savePoly($pinname, $pinLayer, \@toks, $OasGeomList)}  ##  Save the pin geometry
            }
            }
        }
        }
            else {
        ##  A text
        if ($_ =~ /(\S+)\s+(\(.*\))\s+(\d+_\d+)/) {
            $pinname = $1;
            $pinTextLayer = $3;
        }
        elsif ($_ =~ /DBU=([0-9.]+)/ ) {
            ##  Can't think of anything useful to do with dbu here.
                    dprint( MEDIUM, "Info:  DBU = $1\n" );
                }
                else {
            eprint("Could not interpret OAS pininfo line \"$_\"\n");
        }
        }
    }
        close $INFO;
    unlink "$g_opt_macros.oasinfo";
    unlink "$g_opt_macros.ascii";
    
    ## Get bbox info for cell to see if there's geometry outside prBoundary
    if (!$oasError) {
            my @lines = ();
            push(@lines, "#!/bin/bash\n" );
            push(@lines, ". /global/etc/modules/3.1.6/init/sh\n" );
            push(@lines, "module purge\n" );
            push(@lines, "module load icwbev_plus\n" );
            push(@lines, "icwbev -run icwb_config -nodisplay\n" );
            write_file( \@lines, "bash_config.sh" );

            @lines = ();
            push(@lines, "layout open $oas_file ??\n" );
            push(@lines, "cell bbox -cell $g_opt_macros\n" );
            push(@lines, "layout uu_per_dbu\n" );
            push(@lines, "exit\n" );
            write_file( \@lines, "icwb_config" );
        
        my @ICWBoutput = `chmod +x bash_config.sh; ./bash_config.sh`;
        unlink "bash_config.sh";
        unlink "icwb_config";
        ##  Get the layout DBU.  This way we don't rely on the pin extractor to get it
        my $line = pop(@ICWBoutput);
        my @toks = Tokenify($line);
        if (@toks == 2) {
            shift(@toks);  ## Throw away "#->" token
            $dbu = shift(@toks);

            #    print "dbu = $dbu\n";
            $dbu = sprintf("%.8f", $dbu*1e6);  ## Convert to microns and format.
            $dbu =~ s/0+$//;  ##  Strip trailing zeros
            $prec = length($dbu)-2;
        }
        
        $line = pop(@ICWBoutput);
        @toks = Tokenify($line);
            if ( @toks == 5 ) {
            ##  Line has the expected number of tokens.
            shift(@toks);  ## Throw away "#->" token
            ($bb_minx, $bb_miny, $bb_maxx, $bb_maxy) = getBbox(\@toks);

            #        printMsg("$bb_minx, $bb_miny, $bb_maxx, $bb_maxy\n");
            ## icwbev reports in nm apparently, though I can't find anywhere that says so.  Convert these coords to um.
            $bb_minx /= 1000;
            $bb_miny /= 1000;
            $bb_maxx /= 1000;
            $bb_maxy /= 1000;
        }
        }
        else {
        wprint("Skipping extraction of oas cell Bbox due to previous error\n");
    }

    my $viewrec = {};
    if ( fCmp( $pr_minx, $bb_minx, $prec ) || fCmp( $pr_miny, $bb_miny, $prec ) || fCmp( $pr_maxx, $bb_maxx, $prec ) || fCmp( $pr_maxy, $bb_maxy, $prec ) ) {
        my $msg = sprintf "Warning:  Oasis prBoundary bbox (%.*f,%.*f:%.*f,%.*f) does not equal cell bbox (%.*f,%.*f:%.*f,%.*f)\n", 
        $prec,$pr_minx,$prec,$pr_miny,$prec,$pr_maxx,$prec,$pr_maxy,$prec,$bb_minx,$prec,$bb_miny,$prec,$bb_maxx,$prec,$bb_maxy;
        iprint($msg);
    }

    $viewrec->{'FILENAME'} = $origOas;
    $viewrec->{'AREA'}     = $area;
    $viewrec->{'TYPE'}     = "oas";
    $viewrec->{'FMDATE'}   = getMdate($oas_file);
    $viewrec->{'CDATE'}    = undef;
    $viewrec->{'NOPG'}     = 0;
    if (@$OasGeomList == 0) {
        $viewrec->{'GEOMLIST'} = undef;
    }
    else {
        $viewrec->{'GEOMLIST'} = $OasGeomList;
    }
    $viewrec->{'DBU'} = $dbu;
    $viewrec->{'PREC'} = $prec;
    $pr_minx = coordFmt($pr_minx);
    $pr_miny = coordFmt($pr_miny);
    $pr_maxx = coordFmt($pr_maxx);
    $pr_maxy = coordFmt($pr_maxy);
    @{$viewrec->{'BBOX'}} = ($pr_minx,$pr_miny,$pr_maxx,$pr_maxy);
    setBracket($viewrec);
    $g_ViewList[$g_ViewIdx++] = $viewrec;

    $TypeCount{'gds'}++;
    if (defined $gunzFile) {unlink $gunzFile}
    scrubRedundantGeometries($viewrec);
    }

    $g_FileName = undef;
} # end ReadOas

#------------------------------------------------------------------------------
sub fCmp {

    ## Compares two floats by doing a string compare to "prec" digits.
    my $a = shift;
    my $b = shift;
    my $prec = shift;
    
    my $fmt = "%.${prec}f";
    my $as = sprintf($fmt, $a);
    my $bs = sprintf($fmt, $b);
    return ($as ne $bs);

}

#------------------------------------------------------------------------------
sub checkOrigin {

    ##  Check that prBoundary lower-left is at 0,0
    my $coords = shift;   ##  List of coords, x1,y2,x2,y2,x3,y3
    my $id = shift;

    my $Ntoks = (@$coords);  ##  Total number of coords.  2x the number of vertices.
    my ($minx, $miny);
    my $i;
    for ( $i = 0 ; ( $i < ($Ntoks) ) ; $i += 2 ) {
    my $x = $coords->[$i];
    my $y = $coords->[$i+1];
        if ( defined $minx ) { $minx = ( $x < $minx ) ? $x : $minx }
        else                 { $minx = $x }
        if ( defined $miny ) { $miny = ( $y < $miny ) ? $y : $miny }
        else                 { $miny = $y }
    }

    if (($minx != 0) || ($miny != 0)) {wprint("Lower-left of cell not at 0,0:  $minx:$miny for $id\n")}
}

#------------------------------------------------------------------------------
sub getBbox {
    print_function_header();
    ##  Get the bounding box of the polygon.
    my $coords = shift;   ##  List of coords, x1,y2,x2,y2,x3,y3
    dprint( MEDIUM, "getBbox:  @$coords:  --> " ) if ( $main::DEBUG >= MEDIUM);

    my $Ntoks = (@$coords);  ##  Total number of coords.  2x the number of vertices.
    my $minx=undef;
    my $miny=undef;
    my $maxx=undef;
    my $maxy=undef;
    for ( my $i = 0 ; ( $i < $Ntoks ) ; $i += 2 ) {
        my $x = $coords->[$i];
        my $y = $coords->[$i+1];
        if ( defined $minx ) { $minx = ( $x < $minx ) ? $x : $minx }
        else                 { $minx = $x }
        if ( defined $miny ) { $miny = ( $y < $miny ) ? $y : $miny }
        else                 { $miny = $y }
        if ( defined $maxx ) { $maxx = ( $x > $maxx ) ? $x : $maxx }
        else                 { $maxx = $x }
        if ( defined $maxy ) { $maxy = ( $y > $maxy ) ? $y : $maxy }
        else                 { $maxy = $y }
    }
    dprint( MEDIUM, "returning $minx, $miny, $maxx, $maxy\n" );
    return ($minx, $miny, $maxx, $maxy);
}

#------------------------------------------------------------------------------
sub uncomment {
    my $x = shift;
    $x =~ s/\#.*//g;    ##  Get rid of pesky commas.
    return $x;
}

#------------------------------------------------------------------------------
sub listMax {

    my $list = shift;
    my $max;
    foreach my $x (@$list) {
        if ( defined $max ) { $max = ( $x > $max ) ? $x : $max }
        else                { $max = $x }
    }
    return $max;
}

#------------------------------------------------------------------------------
sub listMin {

    my $list = shift;

    my $min;
    my $max;
    foreach my $x (@$list) {
        if (defined $min) {
            $max = ( $x < $min ) ? $x : $min;
        }
        else {
            $min = $x;
        }
    }
    return $max;
}

#------------------------------------------------------------------------------
sub processAuto {
    print_function_header();
    my $fileList = shift;
    my $aref_viewList = shift;
    my $patt = shift;

    dprint( MEDIUM, "Pattern = $patt\n" );
    dprint( MEDIUM, "ProcessAuto  $patt\n" );
    foreach my $file (@$fileList) {
        dprint( CRAZY, "$file\n" ) if ( $main::DEBUG >= CRAZY );
        if ($file =~ /$patt/) {
            my $dup = 0;
            foreach my $f (@$aref_viewList) {
                if ($f eq $file) {
                    $dup = 1;
                    last;
                }
            }
            if (!$dup) {push @$aref_viewList, $file}
        }
    }
}

#------------------------------------------------------------------------------
# Recursively find all files under the given directory
#
sub searchAuto {
    my $dir = shift;
    my $fileList = shift;

    foreach my $file (glob "$dir/*") {
        if (-d $file) { 
            searchAuto($file, $fileList);
        }
        else {
            push @$fileList, abs_path($file);
        }
    }
}

#------------------------------------------------------------------------------
sub scrubRedundantGeometries {
    print_function_header();
    my $viewRec = shift;
    my $geomList = $viewRec->{'GEOMLIST'};

    my ($i, $j);
    my $ll;
    if (defined $geomList){
        $ll = @$geomList;
    } else {
        $ll = 0;
    }
    my ($rec0, $rec1);
    for ($i=0; ($i<$ll); $i++) {
    my $rec0 = $geomList->[$i];
    if (!$rec0) {next}
    for ($j=$i+1; ($j<$ll); $j++) {
        my $rec1 = $geomList->[$j];
        if (!$rec1) {next}
        if ($rec0->{'NAME'} ne $rec1->{'NAME'}) {next}
        if ($rec0->{'LAYER'} ne $rec1->{'LAYER'}) {next}
        if ($rec0->{'BBOX'}->[0] ne $rec1->{'BBOX'}->[0]) {next}
        if ($rec0->{'BBOX'}->[1] ne $rec1->{'BBOX'}->[1]) {next}
        if ($rec0->{'BBOX'}->[2] ne $rec1->{'BBOX'}->[2]) {next}
        if ($rec0->{'BBOX'}->[3] ne $rec1->{'BBOX'}->[3]) {next}
        ##  Looks like a redundant geometry
        $geomList->[$j] = undef;
    }
    }

    my $newGeomList = [];
    foreach my $rec (@$geomList) {
        if ($rec) { push @$newGeomList, $rec }
    }
    my $lll = @$newGeomList;
    $viewRec->{'GEOMLIST'} = $newGeomList;
}

##  Notes on phyical pin check:
##    There may be redundant pin, especially in gds views where there are multiple labels.

#------------------------------------------------------------------------------
sub CheckPhysPins {
    print_function_header();
    my @PhysViewList; ##  List of the views that have physical pins (lef,gds)
    foreach my $view (@g_ViewList) {
        if ( $view->{'GEOMLIST'} ) { push @PhysViewList, $view }
    }

    if (@PhysViewList < 2) {
    nprint "\n\n";
    iprint("Less than two views with physical pins present; skipping the physical pin comparison check\n");
    return;
    }

    nprint "\n\n";
    iprint("Physical pin comparision check:\n");
    my $nViews = @PhysViewList;
    my ($i, $j, $n);
    for ($i=0; ($i<$nViews); $i++) {
    for ($j=$i+1; ($j<$nViews); $j++) {
        my $view0 = $PhysViewList[$i];
        my $view1 = $PhysViewList[$j];
        my $geom;
        ##  $geom->{'OVERLAP'} will be a list of the matched (bbox-overlap) pins in the compared view.
        ##  Must be flushed from each view prior to 
        foreach my $geom (@{$view0->{'GEOMLIST'}}) {$geom->{'MATCH'} = []}  
        foreach my $geom (@{$view1->{'GEOMLIST'}}) {$geom->{'MATCH'} = []}
        iprint("\tBegin $view0->{'FILENAME'} vs. $view1->{'FILENAME'}\n");
        if ((($view0->{'TYPE'} eq "gds") || ($view1->{'TYPE'} eq "gds")) && !$g_LefVsGdsMap) {
        wprint("No lefVsGdsMap file provided; Skipped\n");
        next;
        }
        my $status = 1;
        foreach my $geom0 (@{$view0->{'GEOMLIST'}}) {
        $n = 0;
        foreach my $geom1 (@{$view1->{'GEOMLIST'}}) {

            if ($geom0->{'LAYER'} ne $geom1->{'LAYER'}) {next}
            if ($geom0->{'BBOX'}->[0] >= $geom1->{'BBOX'}->[2]) {next}  ##  MinX0 > MaxX1
            if ($geom0->{'BBOX'}->[2] <= $geom1->{'BBOX'}->[0]) {next}  ##  MaxX0 < MaxX1
            if ($geom0->{'BBOX'}->[1] >= $geom1->{'BBOX'}->[3]) {next}  ##  MinY0 > MaxY1
            if ($geom0->{'BBOX'}->[3] <= $geom1->{'BBOX'}->[1]) {next}  ##  MaxY0 < MaxY1
            ##  Here, layer/name match and there's at least some bbox overlap
            my $pinName = $geom0->{'NAME'};
            my $pinLayer = $geom0->{'LAYER'};
            
            ##  An identified pin overlap.  Analyze the match.
            my $matchRec = checkPinOverlap($geom0, $geom1);
            if (!$matchRec->{'OVERLAP'}) {next}    ##  Pins don't actually intersect.  Can happen with odd geometries.
            push @{$geom0->{'MATCH'}}, $matchRec;
            push @{$geom1->{'MATCH'}}, $matchRec;
            if ($matchRec->{'SHORT'}) {
            my $match = ($matchRec->{'EXACT'}) ? "EXACT" : "PARTIAL";
            eprint("\t\tpin short detected:  layer=$geom0->{'LAYER'}, pin0=\"$geom0->{'NAME'}\", pin1=\"$geom1->{'NAME'}\", overlap=$match\n");
            $status = 0;
            }
            if ($matchRec->{'EXACT'}) {
            next;
            }

            elsif ($matchRec->{'SUBSET_0in1'}) {
            ##  geom0 completely contained in geom1
            if (($view0->{'TYPE'} eq "lef") && ($view1->{'TYPE'} eq "gds")) {
                ##  This particular is is pretty common, occurs when a pin shape doesn't cover the entire metal
                iprint("\t\tLEF pin a subgeometry of GDS pin, $geom0->{'NAME'}/$geom0->{'LAYER'}:\n");
                iprint("\t\t\tLEF:  {@{$geom0->{'COORDS'}}}\n");
                iprint("\t\t\tGDS:  {@{$geom1->{'COORDS'}}}\n");
                        }
                        else {
                eprint("\t\tView0 pin a subgeometry of View1 pin, $geom0->{'NAME'}/$geom0->{'LAYER'}:\n");
                iprint("\t\t\tView0 ($view0->{'TYPE'}):  {@{$geom0->{'COORDS'}}}\n");
                iprint("\t\t\tView1 ($view1->{'TYPE'}):  {@{$geom1->{'COORDS'}}}\n");
                $status = 0;
            }
            }

            elsif ($matchRec->{'SUBSET_1in0'}) {
            ##  geom0 completely contained in geom1
            if (($view1->{'TYPE'} eq "lef") && ($view0->{'TYPE'} eq "gds")) {
                ##  This particular is is pretty common, occurs when a pin shape doesn't cover the entire metal
                iprint("\t\tLEF pin a subgeometry of GDS pin, $geom0->{'NAME'}/$geom0->{'LAYER'}:\n");
                iprint("\t\t\tLEF:  {@{$geom1->{'COORDS'}}}\n");
                iprint("\t\t\tGDS:  {@{$geom0->{'COORDS'}}}\n");
                        }
                        else {
                eprint("\t\tView1 pin a subgeometry of View0 pin, $geom0->{'NAME'}/$geom0->{'LAYER'}:\n");
                iprint("\t\t\tView0 ($view0->{'TYPE'}):  {@{$geom0->{'COORDS'}}}\n");
                iprint("\t\t\tView1 ($view1->{'TYPE'}):  {@{$geom1->{'COORDS'}}}\n");
                $status = 0;
            }
            }
            else {
            ##  Some kind of overlap, no subgeometry detected.
            eprint("\t\tOverlapping pins with geometric differences $geom0->{'NAME'}/$geom0->{'LAYER'}:\n");
            iprint("\t\t\tView0 ($view0->{'TYPE'}):  {@{$geom0->{'COORDS'}}}\n");
            iprint("\t\t\tView1 ($view1->{'TYPE'}):  {@{$geom1->{'COORDS'}}}\n");
            $status = 0;
            }
        }
        }

        $status &= checkUnmatchedGeometries($view0, 0);
        $status &= checkUnmatchedGeometries($view1, 1);
        iprint("\tEnd $view0->{'FILENAME'}\nvs.\t    $view1->{'FILENAME'}");
            if   ($status) { iprint("  CLEAN!\n") }
            else           { eprint("   DIRTY!\n") }
    }
    }
}

#------------------------------------------------------------------------------
sub CheckPhysPins_1 {
    print_function_header();
    my @PhysViewList; ##  List of the views that have physical pins (lef,gds)
    foreach my $view (@g_ViewList) {
        if ( $view->{'GEOMLIST'} ) { push @PhysViewList, $view }
    }

    if( @PhysViewList < 2 ){
        nprint "\n\n";
        iprint("Less than two views with physical pins present; skipping the physical pin comparison check\n");
        return;
    }

    nprint "\n\n";
    iprint("Physical pin comparision check:\n");
    my $nViews = @PhysViewList;
    my ($i, $j, $n);
    for ($i=0; ($i<$nViews); $i++) {
    for ($j=$i+1; ($j<$nViews); $j++) {
        my $v0Num = $i;
        my $v1Num = $j;
        my $view0 = $PhysViewList[$i];
        my $view1 = $PhysViewList[$j];
        my $geom;
        ##  Hashes to save the errors in
        my %v0Overlap;
        my %v1Overlap;
        my %v0Short;
        my %v1Short;
        my %v0v1Short;
        my %v0notv1;
        my %v1notv0;
        ##  $geom->{'OVERLAP'} will be a list of the matched (bbox-overlap) pins in the compared view.
        ##  Must be flushed from each view prior to 
        my $geomHash0;
        my $geomHash1;
        ##   Split up into layers
        foreach my $geom (@{$view0->{'GEOMLIST'}}) {
            my $layer= $geom->{'LAYER'};
            if (!$geomHash0->{$layer}) {$geomHash0->{$layer} = []}
            push @{$geomHash0->{$layer}}, $geom;
        }
        foreach my $geom (@{$view1->{'GEOMLIST'}}) {
            my $layer= $geom->{'LAYER'};
            if (!$geomHash1->{$layer}) {$geomHash1->{$layer} = []}
            push @{$geomHash1->{$layer}}, $geom;
        }

        if ((($view0->{'TYPE'} eq "gds") || ($view1->{'TYPE'} eq "gds")) && !$g_LefVsGdsMap) {
            wprint("No lefVsGdsMap file provided; Skipped\n");
            next;
        }

        my %layerHash;
        ##  Get merged list of layers from both views.
        foreach my $geomHash ($geomHash0,$geomHash1) {
        foreach my $l (keys %$geomHash) {$layerHash{$l} = 1}
        }
        my $err = 0;
        my @layerList = sort keys %layerHash;
        foreach my $layer (@layerList) {
            dprint( CRAZY, "Checking layer $layer\n" );
            $v0Overlap{$layer} = [];
            $v1Overlap{$layer} = [];
            $v0Short{$layer} = [];
            $v1Short{$layer} = [];
            $v0v1Short{$layer} = [];
            $v0notv1{$layer} = [];
            $v1notv0{$layer} = [];
            my %xHash, my %yHash;

            foreach my $geomList ($geomHash0->{$layer},$geomHash1->{$layer}) {
                foreach my $geom (@$geomList) {
                    my $ll = @{$geom->{'COORDS'}};
                    for (my $i=0; ($i<$ll); $i+=2) {
                        my $x = $geom->{'COORDS'}->[$i];
                        my $y = $geom->{'COORDS'}->[$i+1];
                        $xHash{$x} = 1;
                        $yHash{$y} = 1;
                    }  # Coord loop
                }  # geom Loop
            }  #  view loop
            my @xl = sort {$a <=> $b} keys %xHash;
            my @yl = sort {$a <=> $b} keys %yHash;
            my $nx = @xl;
            my $ny = @yl;
            ##  @xl and @yl contains a uniqified list of x and y pin coords for both views.
            for (my $ix=0; ($ix<($nx-1)); $ix++) {
                for (my $iy=0; ($iy<($ny-1)); $iy++) {
                    my $matchRec = {};
                    my $rect = [];
                    $rect->[0] = $xl[$ix];
                    $rect->[1] = $yl[$iy];
                    $rect->[2] = $xl[$ix+1];
                    $rect->[3] = $yl[$iy+1];
                    my $matList0 = [];
                    my $matList1 = [];
                    $matchRec->{'RECT'} = $rect;
                    $matchRec->{'geomList0'} = $matList0;
                    $matchRec->{'geomList1'} = $matList1;
                    findMatchingGeoms($rect, $geomHash0->{$layer}, $matList0);
                    findMatchingGeoms($rect, $geomHash1->{$layer}, $matList1);
                    my $n0 = @$matList0;
                    my $n1 = @$matList1;
                    if ( ($n0 == 0) && ($n1 == 0) ) {next}  ##  A null rectangle; no pin geometries.
                    my $nameList0 = [];
                    my $nameList1 = [];
                    @$nameList0 = getGeomNodeList($matList0);
                    @$nameList1 = getGeomNodeList($matList1);
                    dprint( CRAZY, "@$nameList0 @$nameList1\n" ) if ( $main::DEBUG >= CRAZY ) ;

                    #  Numbers of names.
                    my $nn0 = @$nameList0;
                    my $nn1 = @$nameList1;
                    ##  Names, assuming there's just one.
                    my $name0 = $nameList0->[0];
                    my $name1 = $nameList1->[0];
                        dprint( CRAZY, "$name0 $name1\n" );
                    if (($n0 == 1) && ($n1 == 1) && ($nn0 == 1) && ($nn1 == 1) && ($name0 eq $name1)) {next}   ##  A simple 1/1 match
                    ##  Here, something is unusual.  Add the checks here.
                    if( $n0  > 1 ){ push @{$v0Overlap{$layer}}, $rect; $err=1; }   ## Overlapping geoms in view0
                    if( $n1  > 1 ){ push @{$v1Overlap{$layer}}, $rect; $err=1; }   ## Overlapping geoms in view1
                    if( $nn0 > 1 ){ push @{$v0Short{$layer}}  , $rect; $err=1; }   ##  Pin short in view0
                    if( $nn1 > 1 ){ push @{$v1Short{$layer}}  , $rect; $err=1; }   ##  Pin short in view1
                    if( ($n0 > 0) && ($n1 > 0) ){
                        if( my $id = checkInterviewShort($nameList0, $nameList1) ){
                            ##  view0/view1 overlapping pins of different names
                            $rect->[4] = $id;   ##  Save short info
                            push @{$v0v1Short{$layer}}, $rect;
                            $err=1;
                        }
                    }
                    ##  rect in one view, not the other
                    if ($n0 == 0) {push @{$v1notv0{$layer}}, $rect; $err=1; $rect->[4] = "@$nameList1"}
                    if ($n1 == 0) {push @{$v0notv1{$layer}}, $rect; $err=1; $rect->[4] = "@$nameList0"}
                }
            }
        }  #  layer loop
        iprint("\tView$v0Num($view0->{'FILENAME'},$view0->{'TYPE'})]\n\tvs.\tView$v1Num($view1->{'FILENAME'},$view1->{'TYPE'})\n");
        if( $err ){
            eprint("DIRTY!\n");
            my $errLefFile = "view${v0Num}_view${v1Num}_physCheck.lef";

            my @lines = ();
            push(@lines, "# View$v0Num($view0->{'FILENAME'},$view0->{'TYPE'}) vs. View$v1Num($view1->{'FILENAME'},$view1->{'TYPE'})\n" );
            push(@lines, "VERSION 5.7 ;\n" );
            push(@lines, "BUSBITCHARS \"[]\" ;\n" );
            push(@lines, "DIVIDERCHAR \"/\" ;\n" );
            push(@lines, "MACRO view${v0Num}_view${v1Num}\n" );
            push(@lines, "  CLASS BLOCK ;\n" );
            push(@lines, "  ORIGIN 0 0 ;\n" );
            push(@lines, "  FOREIGN view${v0Num}_view${v1Num} 0 0 ;\n" );
            push(@lines, "  SYMMETRY X Y ;\n" );
        ##  Using view0; not sure what to do if sizes differ
            push(@lines, "  SIZE $view0->{'BBOX'}->[2] BY $view0->{'BBOX'}->[3] ;\n" );
            push(@lines, "  PIN allpins\n" );
            push(@lines, "    DIRECTION INPUT ;\n" );
            push(@lines, "    USE SIGNAL ;\n" );
            push(@lines, "    PORT\n" );

            dumpPhysErrors( \%v0Overlap, "Overlapping pin geometries in view$v0Num",                              "v${v0Num}Overlap",          \@lines );
            dumpPhysErrors( \%v1Overlap, "Overlapping pin geometries in view$v1Num",                              "v${v1Num}Overlap",          \@lines );
            dumpPhysErrors( \%v0Short,   "Shorted pin geometries in view$v0Num",                                  "v${v0Num}Short",            \@lines );
            dumpPhysErrors( \%v1Short,   "Shorted pin geometries in view$v1Num",                                  "v${v1Num}Short",            \@lines );
            dumpPhysErrors( \%v0v1Short, "Overlapping view$v0Num/view$v1Num pin geometries with different names", "v${v0Num}v${v1Num}Overlap", \@lines );
            dumpPhysErrors( \%v0notv1,   "Pin geometries in view$v0Num but not view$v1Num",                       "v${v0Num}notv${v1Num}",     \@lines );
            dumpPhysErrors( \%v1notv0,   "Pin geometries in view$v1Num but not view$v0Num",                       "v${v1Num}notv${v0Num}",     \@lines );

            push(@lines, "      END\n" );
            push(@lines, "    END allpins\n" );
            push(@lines, "  END view${v0Num}_view${v1Num}\n" );
            push(@lines, "END LIBRARY\n" );
            write_file( \@lines, "$errLefFile" );
            nprint "\n";
            eprint("\tSee $errLefFile\n");
        }
        else { iprint("  CLEAN!\n") }
    }
    }
}

#------------------------------------------------------------------------------
sub dumpPhysErrors {
    print_function_header();
    my $errHash  = shift;
    my $info     = shift;
    my $layerID  = shift;
    my $aref_lef = shift;
    
    my @errLayers = sort keys %$errHash;
    my $errCount  = 0;

    foreach my $layer (@errLayers) {
        $errCount += @{$errHash->{$layer}};
    }
    if ($errCount == 0) {
        iprint("\t\t$info:  OK\n");
        return;
    }

    iprint("\t\t$info:\n");
    foreach my $layer (@errLayers) {
        if (@{$errHash->{$layer}} > 0) {
            push(@$aref_lef, "      LAYER ${layer}_$layerID ;\n" );
        }
        ###  Trying a rectangle merge here..
        mergeRectList($errHash->{$layer}, 0);
        foreach my $rect (@{$errHash->{$layer}}) {
            my $extraInfo = "";
            if (defined $rect->[4]) {
                $extraInfo = ", $rect->[4]";
            }
            iprint("\t\t\t'$layer':  $rect->[0],$rect->[1] $rect->[2], $rect->[3] $extraInfo\n") if ( $layer);
            push(@$aref_lef, "        RECT $rect->[0] $rect->[1] $rect->[2] $rect->[3] ;\n" );
        }
    }
}

#------------------------------------------------------------------------------
sub checkInterviewShort {
    print_function_header();
    my $nameList0 = shift;
    my $nameList1 = shift;

    ## Quick check for common 1/1 case
    if ((@$nameList0 == 1) && (@$nameList1 == 1)) {
    ## Common case:  One name per view, just check for a match
        if( $nameList0->[0] eq $nameList1->[0] ){
            return;
        }else{
            return "view0:$nameList0->[0]/view1:$nameList1->[0]";
        }
    }

    ##  One or both have more than one name.  Should be pretty rare.
    my %h0;
    my %h1;
    my @only0;
    my @only1;
    
    foreach my $name (@$nameList0) { $h0{$name} = 1 }
    foreach my $name (@$nameList1) { $h1{$name} = 1 }
    foreach my $name (@$nameList0) {
    if (!$h1{$name}) {push @only0, $name}
    }
    foreach my $name (@$nameList1) {
    if (!$h0{$name}) {push @only1, $name}
    }

    ##  If both only's are empty, the names match; call this matching, though the multiple names is really an error.
    if ((@only0 == 0) && (@only1 == 0)) {
        return;
    }
    else {
    return "view0:{@only0}/view1:{@only1}";
    }

}

#------------------------------------------------------------------------------
sub getGeomNodeList {
    print_function_header();
    my $geomList = shift;

    my %nameHash;
    foreach my $geom (@$geomList) {
    $nameHash{$geom->{'NAME'}} = 1;
    }
    return (sort keys %nameHash);
}

#------------------------------------------------------------------------------
sub findMatchingGeoms {
    print_function_header();

    my ($rect, $geomList, $matList) = @_;

    foreach my $geom (@$geomList) {
    if ($geom->{'BBOX'}->[0] >= $rect->[2]) {next}  ##  MinX0 > MaxX1
    if ($geom->{'BBOX'}->[2] <= $rect->[0]) {next}  ##  MaxX0 < MaxX1
    if ($geom->{'BBOX'}->[1] >= $rect->[3]) {next}  ##  MinY0 > MaxY1
    if ($geom->{'BBOX'}->[3] <= $rect->[1]) {next}  ##  MaxY0 < MaxY1
    ##  Here, we know that rect overlaps the geom bbox.  Check for containment
    if (rectContainedInPoly($rect, $geom->{'COORDS'})) {
        push @$matList, $geom;
            dprint( CRAZY, "Matched {@$rect} to pin geom @{$geom->{'COORDS'}} $geom->{'NAME'}\n" ) if ( $main::DEBUG >= CRAZY );
    }
    }
}

#------------------------------------------------------------------------------
sub checkUnmatchedGeometries {
    print_function_header();
    ##  Looks for geometries with no matches
    my $view = shift;
    my $id = shift;

    my @oList;
    foreach my $geom (@{$view->{'GEOMLIST'}}) {
    if (@{$geom->{'MATCH'}} == 0) {
        push @oList, "\t\t\t$geom->{'NAME'}/$geom->{'LAYER'} {@{$geom->{'COORDS'}}}\n";
    }
    }

    if (@oList > 0) {
    eprint( "\t\tError:  Unmatched pin geometries in view$id ($view->{'TYPE'}):\n");
    iprint("@oList");
    return 0;
    }
    return 1;
}

#------------------------------------------------------------------------------
sub checkPinOverlap {
    print_function_header();
    my ($geom0, $geom1) = @_;

    dprint( MEDIUM, "checkPinOverlap\n" );

    my $matchRec = {};   ##  A struct containing details of the match
    $matchRec->{'GEOM0'} = $geom0;
    $matchRec->{'GEOM1'} = $geom1;

    ##  Check 1: Simply rectangluar match. This should (hopefully) cover most pins
    if (   ( $geom0->{'ISRECT'} && $geom1->{'ISRECT'} )
        && ( $geom0->{'BBOX'}->[0] eq $geom1->{'BBOX'}->[0] )
        && ( $geom0->{'BBOX'}->[1] eq $geom1->{'BBOX'}->[1] )
        && ( $geom0->{'BBOX'}->[2] eq $geom1->{'BBOX'}->[2] )
        && ( $geom0->{'BBOX'}->[3] eq $geom1->{'BBOX'}->[3] ) )
    {
    $matchRec->{'EXACT'} = 1;
    $matchRec->{'SUBSET_0in1'} = 1;
    $matchRec->{'SUBSET_1in0'} = 1;
    $matchRec->{'OVERLAP'} = 1;
    $matchRec->{'SHORT'} = ($geom0->{'NAME'} ne $geom1->{'NAME'});
    return $matchRec;
    }
    
    ##  More complex..  Do a thorough compare
    
    my (%xHash, %yHash);

    ##  Create a lists of unique x and y coords, including both polygons.
    ##   Using hashes as convenient way to eliminate duplicates
    foreach my $geom ($geom0,$geom1) {
        dprint( CRAZY, "{ @{$geom->{'COORDS'}} }\n" ) if ( $main::DEBUG >= CRAZY );
    my $ll = @{$geom->{'COORDS'}};
    my ($i, $x, $y);
    for ($i=0; ($i<$ll); $i+=2) {
        $x = $geom->{'COORDS'}->[$i];
        $y = $geom->{'COORDS'}->[$i+1];
        $xHash{$x} = 1;
        $yHash{$y} = 1;
        my @q = keys(%xHash);
        my @qq = keys(%yHash);
            dprint( CRAZY, "\t$x,$y   {@q}  {@qq}\n" ) if ( $main::DEBUG >= CRAZY );
    }
    }
    my @xl = sort {$a <=> $b} keys %xHash;
    my @yl = sort {$a <=> $b} keys %yHash;
    dprint( CRAZY, "xList={@xl}  yList={@yl}\n" ) if ( $main::DEBUG >= CRAZY );
    my ($x0,$x1,$y0,$y1,$ix,$iy,$nx,$ny);
    $nx = @xl;
    $ny = @yl;

    # ljames commented these two variables out rect0not1, rect1not0 because
    # they were not actually used once they were created.
    #my $rect0not1 = [];  ## Rectangles in geom0, not geom1
    #my $rect1not0 = [];  ## Rectangles in geom1, not geom0
    # ljames commented out this variable because it was not used 'rect0and1'
    #my $rect0and1 = [];  ## Rectangles in geom0 and geom1

    my $exactMatch = 1;  # Assuming exact match until proved otherwise.
    my $subset_1in0 = 1;  ##  geom1 is completely contained by geom0
    my $subset_0in1 = 1;  ##  geom0 is completely contained by geom1
    my $overlap = 0;  ## There's some overlap.
    for ($ix=0; ($ix<($nx-1)); $ix++) {
    for ($iy=0; ($iy<($ny-1)); $iy++) {
        my $rect = [];
        $rect->[0] = $xl[$ix];
        $rect->[1] = $yl[$iy];
        $rect->[2] = $xl[$ix+1];
        $rect->[3] = $yl[$iy+1];
        my $inGeom0 = rectContainedInPoly($rect,$geom0->{'COORDS'});
        my $inGeom1 = rectContainedInPoly($rect,$geom1->{'COORDS'});
        if    (!$inGeom0 && !$inGeom1) {next}
        elsif ($inGeom0 && !$inGeom1) {

            #push @$rect0not1; 
            $exactMatch=0; 
            $subset_0in1=0;
        }
        elsif (!$inGeom0 && $inGeom1) {

            #push @$rect1not0; 
            $exactMatch=0; 
            $subset_1in0=0;
        }
        elsif ($inGeom0 && $inGeom1)  {$overlap=1}
        
            dprint( CRAZY, "Rect:  {@{$rect}}   in0=$inGeom0, in1=$inGeom1\n" ) if ( $main::DEBUG >= CRAZY );
    }
    }

    $matchRec->{'EXACT'} = $exactMatch;
    $matchRec->{'SUBSET_0in1'} = $subset_0in1;
    $matchRec->{'SUBSET_1in0'} = $subset_1in0;
    $matchRec->{'OVERLAP'} = $overlap;
    $matchRec->{'SHORT'} = $overlap && ($geom0->{'NAME'} ne $geom1->{'NAME'});
    return $matchRec;
    #dprint( CRAZY, "exact=$exactMatch, overlap=$overlap, subset_0in1=$subset_0in1, subset_1in0=$subset_1in0\n" );
}

#------------------------------------------------------------------------------
sub rectContainedInPoly {
    print_function_header();
    ##  Checks whether a rectangle is within a polgon
    ##  Method:  Using a point at the center of the rectangle, project a line horizontally, and count how many times this crosses a polygon side.
    ##           Should work projecting a line in any direction, actually.
    ##           Since rectangles are derived from the polygon coordinates, the center of the rectangle can never coincide with any rectangle vertex.

    my ($rect,$coords) = @_;
    my ($x0,$y0,$x1,$y1) = @$rect;
    my $x = ($x0+$x1)/2.0;
    my $y = ($y0+$y1)/2.0;
    my $i;
    my $ll = @$coords;
    my $in = 0;
    my $sides = 0;
    for ($i=0; ($i<($ll-2)); $i+=2) {
    $sides++;
    my $xA=$coords->[$i];
    my $yA=$coords->[$i+1];
    my $xB=$coords->[$i+2];
    my $yB=$coords->[$i+3];
    if ($yA == $yB) {next}  ##  Horizontal line
    if (($y > $yA) && ($y > $yB)) {next}
    if (($y < $yA) && ($y < $yB)) {next}
    ##  Vertical segment and bounded in the y direction.
    if ($x < $xA) {$in = !$in}   ##  Imaginary projection passes through polygon segment.
    }
    dprint( MEDIUM, "#  Sides = $sides\n" );
    return $in;
}

#------------------------------------------------------------------------------
sub mergeRectList {
    print_function_header();
    ##  Merges rectangles within a list.
    my $rectList = shift;
    my $noIterate = shift;
    
    my $startCount = @$rectList;
    iprint("Merging, start count=$startCount\n");

    my( $i, $j, $merge, $iteration );
    my $n = @$rectList;
    do {
        $merge = 0;
        $iteration++;
        for( $i=0; $i<$n; $i++ ){
            next if( $rectList->[$i]->[5] );
            for ($j=$i+1; ($j<$n); $j++) {
                next if( $rectList->[$j]->[5] );
                my ($x1a, $y1a, $x2a, $y2a) = @{$rectList->[$i]};
                my ($x1b, $y1b, $x2b, $y2b) = @{$rectList->[$j]};
                dprint( CRAZY, "$i:$j {$x1a,$y1a,$x2a,$y2a}:{$x1b,$y1b,$x2b,$y2b}\n" );
                if ($x2a == $x1b) {
                    ##  Possible merge to right.
                    if ($y1a ne $y1b) {next}   ## Nope
                    if ($y2a ne $y2b) {next}   ## Nope
                    ##  Aligned.
                    $rectList->[$i]->[2] = $x2b;
                    $rectList->[$j]->[5] = 1;
                        dprint CRAZY, "Merged {$x1a,$y1a,$x2a,$y2a} and {$x1b,$y1b,$x2b,$y2b} right\n";
                    $merge++;
                }
                elsif ($x1a == $x2b) {
                    ##  Possible merge to left.
                    if ($y1a ne $y1b) {next}   ## Nope
                    if ($y2a ne $y2b) {next}   ## Nope
                    ##  Aligned.
                    $rectList->[$i]->[0] = $x1b;
                    $rectList->[$j]->[5] = 1;
                    $merge++;
                        dprint CRAZY, "Merged {$x1a,$y1a,$x2a,$y2a} and {$x1b,$y1b,$x2b,$y2b} left\n";
                }
                elsif ($y2a == $y1b) {
                    ##  Possible merge up.
                    if ($x1a ne $x1b) {next}   ## Nope
                    if ($x2a ne $x2b) {next}   ## Nope
                    ##  Aligned.
                    $rectList->[$i]->[3] = $y2b;
                    $rectList->[$j]->[5] = 1;
                    $merge++;
                        dprint CRAZY, "Merged {$x1a,$y1a,$x2a,$y2a} and {$x1b,$y1b,$x2b,$y2b} up\n";
                }
                elsif ($y1a == $y2b) {
                    ##  Possible merge down
                    if ($x1a ne $x1b) {next}   ## Nope
                    if ($x2a ne $x2b) {next}   ## Nope
                    ##  Aligned.
                    $rectList->[$i]->[1] = $y1b;
                    $rectList->[$j]->[5] = 1;
                    $merge++;
                        dprint CRAZY, "Merged {$x1a,$y1a,$x2a,$y2a} and {$x1b,$y1b,$x2b,$y2b} down\n";
                }
            } # END for( $j
        } # END for( $i
    } until (($merge == 0) || ($noIterate));
    ##  Clean up the list to remove the merged rect's
    my @cleanList;
    foreach my $r (@$rectList) {
        if ( !$r->[5] ) { push @cleanList, $r }
    }
    @$rectList = @cleanList;
    my $endCount = @$rectList;
    iprint("End merging, count=$endCount\n");
}

sub pg_pin_missing_from_interface($$$){
    my $pg_pin_name        = shift;
    my $href_InterfaceHash = shift;
    my $iview              = shift;
    my $viewname           = shift;
    my $view_fname         = shift;

    my $isMissing = 0;

    # Check that it isn't mentioned in the g_InterfaceHash table;
    # These would be the verilog views.
    my $ipin_attr = $href_InterfaceHash->{"$pg_pin_name"};
    if ( ! defined $ipin_attr ){
        # This would mean that the PG pin that we are looking for
        # is absent from the Interface file. The Interface file is
        # a superset of all pins, including power pins. So, if this
        # power pin is missing from the interface file, it's a 
        # problem and should be flagged.
        viprint(LOW, "PG pin '$pg_pin_name'\n");
        viprint(LOW, "\t missing in the interface file '$viewname'!\n"); 
        dprint_dumper(MEDIUM, "g_InterfaceHash => ", $href_InterfaceHash);
        $isMissing = 1;
    }else{
        my $ipin_attr = $href_InterfaceHash->{"$pg_pin_name"};
        my $ipin_vrec = @$ipin_attr[$iview]; # if not defined then it's not an interface pin
        if ( ! defined $ipin_vrec ) {
            # There are a number of files that would contain the same pin
            # name and yet they might not actually have the type attribute of
            # 'power' or 'ground' associated with them. These should not be
            # considered an error. But we will print info about this if
            # asked for when -verbosity is 1 or greater.
            my $extra = "in pin view -> \n\t '$viewname'";
            $extra = "in viewList view -> \n\t '$view_fname'" if ( ! $viewname );
            viprint(MEDIUM, "PG pin '$pg_pin_name' has attribute TYPE that's\n"
                        ."\t not defined. Looking at file view number '$iview'!\n"
                        ."\t Types expected for views that mention types would be 'power' or 'ground'.\n"
                        ."\t $extra\n"
                        ."\t The good news is that this function CheckMissingPgPins has found the PG pin we were looking for in this view.\n");
        } # and not in interface hash
    } # else it is found in the InterfaceHash file

    return $isMissing;
}


1;    # required to run unit tests

__END__
=head1 SYNOPSIS

    alphaPinCheck.pl \
    -macro <MACRO> \
    [-lef LEFFILE1 [-lef LEFFILE2 -lef LEFFILE3...]] \
    [-liberty LIBFILE1 [-lib LIBFILE2 -lib LIBFILE3...]] \
    [-libertyNopg LIBFILE1 [-lib LIBFILE2 -lib LIBFILE3...]] \
    [-verilog VERILOGFILE1 [-verilog VERILOGFILE2 -verilog VERILOGFILE3...]] \
    [-verilogNopg VERILOGFILE1 [-verilog VERILOGFILE2 -verilog VERILOGFILE3...]] \
    [-cdl CDLFILE1 [-cdl CDLFILE2 -cdl CDLFILE3...]] \
    [-GDS GDSFILE1 [-gds GDSFILE2 -gds GDSFILE3...]] \
    [-OAS OASFILE1 [-oas OASFILE2 -oas OASFILE3...]] \
    [-pinCSV PINCSVFILE1 [-pinCSV PINCSVFILE2 -pinCSV PINCSVFILE3...]] \
    [-layers <Legal LEF-layer-list>] \
    [-lefPinLayers <Legal LEF-layer-list>] \
    [-lefObsLayers <Legal LEF-layer-list>] \
    [-layers <Legal LEF-layer-list>] \
    [-PGlayers <List of expected PG pin layers for lef/gds> \
    [-boundaryLayer LAYER] [-ignoreDatatype "datatype list"] [-streamLayermap <stream layermap>] \
    [-vflag] \
    [-[no]checkTiming] \
    [-since "timestamp"] \
    [-[no]auto] \
    [-p4Auto <p4-depot-location>] \
    [-dateRef CDATE|MDATE] \
    [-tech techName] \
    [-pcs pcsName] \
    [-lefVsGdsMap mapFile] \
    [-bracket square|pointy] \
    [-[no]physCheck] \
    [-verilogInclude "includeDirs"] \
    [-verilogIncludeFiles "includeFiles"] \
    [-verilogDefines "idefines"] \
    [-pgPins "power-ground-pins-list"] \
    [-log <filename>|<directory>] \
    [-nolog] \
    [-appendlog ] \
    [-debug <level>] \
    [-verbosity <level>] \
    [-testmode] \
    [-nousage]
    

This script is designed to read multiple macro views and compare the pin consistency, (existence and direction) across all views.
In addition, it will compare macro area numbers for views whcih include areas (LEF and Liberty).  Multiple files for a given view can be specified to allow checking 
across different versions of the same file.

Along the way, other checks have been added.  The complete list follows:

=item B<Consistency of pin EXISTENCE across all views>

=item B<Consistency of pin DIRECTION across all views>

=item B<Consistency of of pin TYPE across all views:> Note that not all views contain a type (power, ground, signal).

=item B<Consistency of pin attribute 'related_power'/'related_ground' across all views:> Applies to Liberty and pinCSV views.

=item B<Cell Area:> Applies to LEF, Liberty, GDS and pinCSV views.

=item B<LEF layers:> A simple layer check to make sure that the LEF has only expected layers.

=item B<LEF/GDS power/ground pin layers:> Verifies that power/ground pins are on the expected layers.  Triggered by defining -PGlayers

=item B<Simple GDS boundary check:> Checks of the prBoundary coincides with the cell boundary, possibly identifying geometries outside of prBoundary.

=item B<Voltage markers (-vflag):> Applies to pinCSV and special cdl  

=item B<Timing checks:> A set of checks on the Liberty views:

=item B<Bracket checks:>  Verifies that bus-notation brackets are of a specified type (-bracket arg) or at least consistent across views.

=item B<Physical Pin checks:>  Compares pin geometries across lef/gds views.

=over 2

=item B<Pin caps:>  All inputs/IO's have a defined capacitance

=item B<Misc:>  Presence of leakage_power_unit, cell_leakage_power,operating_conditions-->tree_type, default_max_capacitance and default_max_transition

=item B<Timing Table Checks:>  The type of check that reviews timing tables for outliers, monotonicity and max_tran/max_cap out-of-range have been removed due to issues with the Liberty parser. This sort of check now done with SiliconSmart.

=back

=item B<View file modification dates vs. a user-supplied time.  Verifies that all files were created after a given time.

Written by John Clouser, john.clouser@synopsys.com.  Comments and suggestions are welcome.



=over 2

=item B<-h> B<-help>

Prints this help

=item B<-macro>

The name of the macro in question.  Must be consistent for all views read.  Required.

=item B<View Arguments>

There are four arguments used to specify the view files to be read:  -lef, -liberty, -verilog and -cdl.  Multiple files for each view can be read, by either using wildcards (must be quoted) 
or by invoking the related argument multiple times, as shown in the synopsis above.  

=over 2

=item B<-lef>

Name(s) of LEF files.

=item B<-liberty>

Name(s) of Liberty files.

=item B<-libertyNopg>

Name(s) of Liberty files specifically without power/ground pins.  Used in conjunction with the-pgPins option to suppress errors about missingPG pins in Liberty views that are intended to not include them.

=item B<-verilog>

Name(s) of Verilog files.

=item B<-verilogNopg>

Name(s) of verilog files specifically without power/ground pins.  Used in conjunction with the-pgPins option to suppress errors about missingPG pins in verilog views that are intended to not include them.

=item B<-verilogInclude>

Comma-separated list of directories to search when reading Verilog files.  Applies to all Verilog files read, ; there is no mechanism to specify specific include directories for each file.

=item B<-verilogIncludeFiles>

Comma-separated list of extra Verilog files to be read along with the Verilog view file(s).  
For relative files, directories searched will be, in order, dir of Verilog view file followed by dir(s) spec'ed in -verilogInclude.
Applies to all Verilog files read; there is no mechanism to specify specific include directories for each file.

=item B<-verilogDefines>

Comma-separated list of macro definitions to make.  Each definition is of the form "macroName[=macroValue]"; note that a value is optional.

=item B<-pgPins "power-ground-pin-list">  

Specifies the power and ground pins.  Used in conjunction with the -libertyNopg and -verilogNopg options to suppress errors about missing PG pins in views that are not intended to include them.

=item B<-vmodule verilog-module-name>

Name of module in Verilog view(s) (optional).  (Added at a time when macro names were in flux)

=item B<-cdl>

Name(s) of CDL files.

=item B<-gds>

Name(s) of GDS files.

=item B<-oas>

Name(s) of Oasis files.

=item B<-pinCSV>

Name(s) of pin CSV file.  This view is reminiscent of the old pininfo files, but in CSV (comma-separated-value) form.
Requirements:

=over 2

=item B<Header line>

There must be a single header line which identifies each column in which data is included.

=item B<Pin lines; one line per signal (buses allowed)

Each line after the header defines the characteristics of each pin (or bus).  

The columns this script pays attention to are:

=item B<name>  - The name of the signal or bus

=item B<cell_x_dim_um>  - The width of the macro in um

=item B<cell_y_dim_um>  - The height of the macro in um

=item B<direction>  - The direction of the pin

=item B<pintype>  - Typically primary_power, primary_ground or general_signal.

=item B<related_power>  - The related power of the pin

=item B<related_power>  - The related ground of the pin

=item B<power_value>    - Optional (for voltage marker check): For power pins, voltage (f.ex: 1.8 or 'core' for core power).

Extra info can be included, will be ignored.


=back

=back

=item B<-lefPinLayers "layerlist"> 

Space-separated list of LEF layers legal for pins.  If not supplied, the layers specified in the lefVsGds map file is used, if available. If no layers are provided at all, the check is skipped.

=item B<-lefObsLayers "layerlist"> 

Space-separated list of LEF layers legal for OBS.  If not supplied, the layers specified in the lefVsGds map file is used, if available. If no layers are provided at all, the check is skipped.

=item B<-layers "layerlist"> 

Obsolete, and synonymous with -lefPinLayers.

=item B<-layersFile filename> 

Name of file containing the list of legal layers. Listed as space-separated list and/or one per line.  
Note that this checks only the LEF and is not related to the full alphaCheckLegalLayers script for checking the GDS against a foundry/customer supplied layer list.

=item B<-PGlayers "layerlist"> 

Space-separated list of legal LEF layers for power/ground pins.  Defaults to undefined, skipping check.

=item B<-streamLayermap> 

The layermap file used to translate GDS layer numbers to more intelligible names.  
Typically part of the ccs: /remote/proj/cad/$MSIP_CAD_PROJ_NAME/$MSIP_CAD_REL_NAME/cad/$METAL_STACK/stream/STD/stream.layermap
The preferred solution is to use lefVsGdsMap file is picked up, either by -lefVsGdsMap file arg, or implicitely with -tech arg.

=item B<-boundaryLayer> LAYER  

The GDS layer(s) for prBoundary used for simple boundary checks.  Use a quoted, space-separated list to allow for multiple possible layers.
Defaults to "62.21 108.0" covering gf14 and multiple tsmc projects.  Overidden if a lefVsGdsMap file is picked up, either by -lefVsGdsMap file arg, or implicitely with -tech arg.

=item B<-ignoreDatatype>

List of gds datatypes to ignore when reading pins. The underlying gds parser currently has a problem interpreting voltage markers as pin labels.

=item B<-[no]CheckTiming >

Disables/enables timing checks on the .lib files. (Default=disabled).  Timing checks include checks for the presence of pin caps, warnings for missing arcs on output and io pins and monotonicity checks.

=item B<-vflag> 

Enables voltage markers check

=item B<-since timespec> 

Enables the view file timestamp check against the specified timespec.  Almost any rational timespec accepted.  See http://search.cpan.org/~gbarr/TimeDate-2.30/lib/Date/Parse.pm.

=item B<-dateRef CDATE|FMDATE> 

Specifies what date will be used for the above -since timestamp checking.  "CDATE" uses the apparent file creation date, usually included in the file contents. 
"liberty" and "gds" files have creation date included in their normal data.  'cdl' and 'lef' views generally have it included in comments.  "FMDATE" uses the file modification date for the 
compare.  This timestamp will exist for all files.

=item B<-[no]auto>  

Enables an auto-mode for picking up view files.  Will search down in the directory hierarchy from the invocation directory looking for file named MACRO_*.EXT, where MACRO is the name of the macro specified by -macro switch and EXT is the extension appropriate to each view (.lib, .gds, etc).

=item B<-p4Auto p4-location>

Works a lot like -auto, except takes a p4 depot location, sync's out (temporary client) and runs this checks in auto mode on that area.  When complete, the user is given the option to check
in the log file to that location in p4.  Intended to allow pinCheck to be run directly on p4 contents.

=item B<-tech techName> 

Specifies the technology used in the gds and lef views.  This allows a lef vs. gds layermap to be loaded automatically which defines 1) prBoundary layer, 2) legal LEF layers
(if not specified any other way), 3) geometry/text layer relationships that allow gds pin geometries.  Legal values are the directories in /remote/cad-rep/msip/ude_conf/lef_vs_gds. 
This is preferred to manually specifying the streamLayermap file.

=item B<-pcs pcsName> 

Specifies the pcs to use to infer the process technology.  pcsName is specified as "product/project/rel"; example: "e32/x331-e32-ss4lpe-12-ns/rel1.00". At writing, this is used only to determine the technology, which is inferred from the ccs name in the same way that lefGen does it.  If both -tech and -pcs are used, -tech wins.

=item B<-lefVsGdsMap mapFile> 

Specifies the lefVsGdsMap file, if not available in or different from the version in /remote/cad-rep/msip/ude_conf/lef_vs_gds/TECH.

=item B<-bracket square|pointy>  

Specifies the expected bus-notation bracket type, "square" ([]) or "pointy" (<>) to be used in the bracket type check.  If not specified, the tool
checks for bracket consistency across all views. (Verilog and pininfoCSV are considered bracket-agnostic and are not checked.)

=item B<-[no]physCheck> 

[dis]enables the physical pin check in which the geometries of lef and gds views are compared for consistency.  This check is fairly new, at writing, and is not fully tested.
Defaults to -nophysCheck.

=cut
