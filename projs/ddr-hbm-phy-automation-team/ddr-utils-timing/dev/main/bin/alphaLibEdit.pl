#!/depot/perl-5.14.2/bin/perl
#01-11-21(dikshant@synopsys.com) Added new renameBus function to rename bus and its Pins.
#12-24-21(dikshant@synopsys.com) Updated Copy and map bus function.
#02-17-21(dikshant@synopsys.com) Updated copy_lut function and added copy_ccsn function that copies ccsn from same lib
use strict;
use warnings;
our $ScriptPath;



BEGIN {
    ## This bit is needed to be able to pick up the alphaLibParser package.
    ##  It is assumed to reside in the same directory as this script.
    my @toks = split(/\//, $0);
    pop (@toks);
    $ScriptPath = join("/", @toks);
    #$ScriptPath = abs_path($ScriptPath);
    push @INC, $ScriptPath;  ##  Need this to pick up the alphaLibParser
}

use Getopt::Long;
use File::Basename;
use Cwd;
use Cwd 'abs_path';
use Pod::Usage;
use Data::Dumper;
use Number::Format qw(:subs);
use Cwd;

#Usage Tracking Utilities.
use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../lib/perl/";
use alphaLibParser;
#use utilities;
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
our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
our $VERSION      = get_release_version() || 2022.11;

##  Constants
our $LOG_INFO = 0;
our $LOG_WARNING = 1;
our $LOG_ERROR = 2;
our $LOG_FATAL = 3;
our $LOG_RAW = 4;
#--------------------------------------------------------------------#

#unless(@ARGV) {ShowUsage() }
my $debug;
my $opt_help;
my @libertyArg;
my $outdir;
my $help;
our $RefLib;
my $configFile;
my $convertbrackets;
my $convert_Pin_name_to_lowercase;
our @libArray;
my $Commands = "";
my $libFile = "";

BEGIN { our $AUTHOR='Multiple Authors'; header(); } 
&Main();
END {
   write_stdout_log("$LOGFILENAME");
   footer(); 
}
sub Main {

#my $result = GetOptions(
#    "outdir=s"       => \$outdir,
#    "Config=s"       => \$configFile,
#    "RefLib=s"       => \$RefLib,
#    "sb"             => \$convertbrackets,
#    "lc"             => \$convert_Pin_name_to_lowercase,	  		
#    "help"           => \$help
#    );
#	    print %{$args->{OPTIONS}},"\n";
our $Commands = {
    'sort_pins' => {
	'FUNCTION' => \&sort_pins_func,
	'LEVEL' => 0,
    },
    'sort_arcs' => {
	'FUNCTION' => \&sort_arcs_func,
	'LEVEL' => 0,
    },
    'port_pvt' => {
	'FUNCTION' => \&port_pvt_seperate,
	'LEVEL' => 0,
    },
    'sortPins' => {
	'FUNCTION' => \&sort_pins_func,
	'LEVEL' => 0,
    },
    'sortArcs' => {
	'FUNCTION' => \&sort_arcs_func,
	'LEVEL' => 0,
    },
    'deletePin' => {
	'FUNCTION' => \&deletePin_func,
	'LEVEL' => 0,
    },
    'setPinAttr' => {
	'FUNCTION' => \&setPinAttr_func,
	'LEVEL' => 0,
    },
    'delPinAttr' => {
	'FUNCTION' => \&delPinAttr_func,
	'LEVEL' => 0,
    },
    'createBus' => {
	'FUNCTION' => \&createBus_func,
	'LEVEL' => 0,
    },
    'deleteArc' => {
	'FUNCTION' => \&deleteArc_func,
	'LEVEL' => 0,
    },
    ## MungeNanotime equiv
    'd' => {
	'FUNCTION' => \&deletePin_func,
	'LEVEL' => 0,
    },
    'r' => {
	'FUNCTION' => \&deleteArc_related_pin_func,
	'LEVEL' => 0,
    },
    'removeArc' => {
	'FUNCTION' => \&deleteArc_related_pin_func,
	'LEVEL' => 0,
    },
    'm' => {
	'FUNCTION' => \&renameArc_related_pin_func,
	'LEVEL' => 0,
    },
    'renameRelatedPin' => {
	'FUNCTION' => \&renameArc_related_pin_func,
	'LEVEL' => 0,
    },
    's' => {
	'FUNCTION' => \&RenamePin_func,
	'LEVEL' => 0,
    },
    'renamePin' => {
	'FUNCTION' => \&RenamePin_func,
	'LEVEL' => 0,
    },
    'u' => {
	'FUNCTION' => \&combineArc_related_pin_func,
	'LEVEL' => 0,
    },	
     'combineArc' => {
	'FUNCTION' => \&combineArc_related_pin_attrib_func,
	'LEVEL' => 0,
    },
   'copy_pin' => {
	'FUNCTION' => \&CopyPin_func,
	'LEVEL' => 0,
    },
   'copy_bus' => {
	'FUNCTION' => \&CopyBus_func,
	'LEVEL' => 0,
    },
   'map_bus' => {
	'FUNCTION' => \&MapBus_func,
	'LEVEL' => 0,
    },
   'delete_bus' => {
	'FUNCTION' => \&deleteBus_func,
	'LEVEL' => 0,
    },
   'delete_busInfo' => {
	'FUNCTION' => \&deleteBus_info_func,
	'LEVEL' => 0,
    },
   'delete_mainbusInfo' => {
	'FUNCTION' => \&deleteBus_maininfo_func,
	'LEVEL' => 0,
    },
    'delete_min_delay' => {
	'FUNCTION' => \&delete_min_delay,
	'LEVEL' => 0,
    },
    'add_pin' => {
	'FUNCTION' => \&AddPin_func,
	'LEVEL' => 0,
    },
    'add_pin_with_attrib' => {
	'FUNCTION' => \&AddPin_attrib_func,
	'LEVEL' => 0,
    },
    'set_pin_attr' => {
	'FUNCTION' => \&setPinAttrib_func,
	'LEVEL' => 0,
    },
    'del_pin_attr' => {
	'FUNCTION' => \&delPinAttrib_func,
	'LEVEL' => 0,
    },
    'change_dir' => {
	'FUNCTION' => \&setPinDirection_func,
	'LEVEL' => 0,
    },
    'change_bus_dir' => {
	'FUNCTION' => \&setBusDirection_func,
	'LEVEL' => 0,
    },
    'mark_clock' => {
	'FUNCTION' => \&setPinClock_func,
	'LEVEL' => 0,
    },
    'cell_area' => {
	'FUNCTION' => \&setCellArea_func,
	'LEVEL' => 0,
    },
    'cell_attrib' => {
	'FUNCTION' => \&setCellAttr_func,
	'LEVEL' => 0,
    },
    'add_bus' => {
	'FUNCTION' => \&AddBus_func,
	'LEVEL' => 0,
    },
    'add_pin_info' => {
	'FUNCTION' => \&AddRelatedPin_func,
	'LEVEL' => 0,
    },
    'add_pg_pin' => {
	'FUNCTION' => \&AddPgPin_func,
	'LEVEL' => 0,
    },
    'del_pg_pin' => {
	'FUNCTION' => \&DelPgPin_func,
	'LEVEL' => 0,
    },
     'del_arc_attr_except' => {
	'FUNCTION' => \&deleteArcWhenExcept_func,
	'LEVEL' => 0,
    },
     'del_arc_attr' => {
	'FUNCTION' => \&deleteArcWhen_func,
	'LEVEL' => 0,
    },
    'copy_timing' => {
	'FUNCTION' => \&CopyTiming_func,
	'LEVEL' => 0,
    },
    'copy_timing_Arc' => {
	'FUNCTION' => \&CopyTiming_flex_func,
	'LEVEL' => 0,
    },
    'pg_pin' => {
	'FUNCTION' => \&AddPgPin_func,
	'LEVEL' => 0,
    },
    'split_arc' => {
	'FUNCTION' => \&splitArc_related_pin_func,
	'LEVEL' => 0,
    },
    'copy_lut' => {
	'FUNCTION' => \&copyLut_func,
	'LEVEL' => 0,
    },
    'mod_timing_type_sense' => {
	'FUNCTION' => \&mod_timing_type_sense_func,
	'LEVEL' => 0,
    },
    'add_vmap' => {
	'FUNCTION' => \&AddVmap_func,
	'LEVEL' => 0,
    },
    'del_vmap' => {
	'FUNCTION' => \&DelVmap_func,
	'LEVEL' => 0,
    }, 
       'add_busInfo' => {
	'FUNCTION' => \&AddBusInfo_func,
	'LEVEL' => 0,
    },
       'add_mainbusInfo' => {
	'FUNCTION' => \&AddBusmainInfo_func,
	'LEVEL' => 0,
    },
       'editLibraryValue' => {
	'FUNCTION' => \&Edit_Lib_value,
	'LEVEL' => 0,
    },
       'deleteLibraryValue' => {
	'FUNCTION' => \&Delete_Lib_value,
	'LEVEL' => 0,
    },
       'del_timing_attr' => {
	'FUNCTION' => \&del_timing_attr_func,
	'LEVEL' => 0,
    },
        'correct_bit_from_to' => {
	'FUNCTION' => \&CorrectBit_from_to_func,
	'LEVEL' => 0,
    },
    'add_bus_info' => {
	'FUNCTION' => \&AddRelatedBus_func,
	'LEVEL' => 0,
#    },
#    'del_arc_attrib' => {
#	'FUNCTION' => \&deleteArcWhen_func,
#	'LEVEL' => 0,
#    },
#    'del_arc_attrib_except' => {
#	'FUNCTION' => \&deleteArcWhenExcept_func,
#	'LEVEL' => 0,
    },
     
    'copy_pin_fromRefLib' => {
	'FUNCTION' => \&CopyPin_1lib2other_func,
	'LEVEL' => 0,
    },
   'copy_bus_fromRefLib' => {
	'FUNCTION' => \&CopyBus_1lib2other_func,
	'LEVEL' => 0,
    },
   'map_bus_fromRefLib' => {
	'FUNCTION' => \&MapBus_1lib2other_func,
	'LEVEL' => 0,
    },
    'copy_timing_Arc_fromRefLib' => {
	'FUNCTION' => \&CopyTiming_1lib2other_func,
	'LEVEL' => 0,
    },
    'copy_CCSN_fromRefLib' => {
	'FUNCTION' => \&CopyCCSN_1lib2other_func,
	'LEVEL' => 0,
    },
    'copy_CCSN' => {
	'FUNCTION' => \&CopyCCSN_func,
	'LEVEL' => 0,
    },

    'deleteCCSN' => {
	'FUNCTION' => \&DeleteCCSN_func,
	'LEVEL' => 0,
    },
    'fix0cap' => {
    	'FUNCTION' => \&replace_zero_cap,
	'LEVEL' => 0,
    },
    'fixRefClkCap' => {
	'FUNCTION' => \&replace_Ref_Clk_Cap,
	'LEVEL' => 0,
    },
    'b' => {
	'FUNCTION' => \&RenameBus_func,
	'LEVEL' => 0,
    },
    'renameBus' => {
	'FUNCTION' => \&RenameBus_func,
	'LEVEL' => 0,
		
	}

};

#our @DeferredCommands;
our @commandList;
($debug,$outdir,$configFile,$RefLib,$convertbrackets,$convert_Pin_name_to_lowercase,$opt_help)
            = process_cmd_line_args();
utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);


#if ($help) {ShowUsage() }


my @libertyFiles;

foreach my $l (@ARGV) {push @libertyFiles, glob($l)}

my $err = 0;
if (@libertyFiles == 0) {
    eprint ("Error:  No Liberty files specified\n");
    $err = 1;
}

if (defined $configFile) {
    if (!(-r $configFile)) {
	logMsg($LOG_FATAL, "Cannot open $configFile for read\n");
	$err = 1;
    }
}
else {
    logMsg($LOG_FATAL, "Config file not specified\n");
    $err = 1;
}

if ($err) {exit}



foreach my $lib (@libertyFiles) {
    my $libFile = alphaLibParser::readLib($lib);
    if (defined $libFile) {
	alphaLibParser::setFilePath($libFile, $outdir);
	push @libArray, $libFile;
    };
    
    #	alphaLibParser::sortArcs($libFile);
    #	writeLib($libFile);
}
if(defined $RefLib) {
    $RefLib = alphaLibParser::readLib($RefLib);
}    
my $CFG;
#my @CFG = read_file("$configFile");
#DikshantRohatgi : adding nolint for this open as it is causing issue while reading config. Tried replacing it with other functionality
open($CFG, $configFile) || die("$configFile file doesn't exist\n"); #nolint open<
my $line;

while($line = readConfigLine($CFG)) {
    #print "** $line\n";
	#shift(\@CFG);
	my @toks = split(/\s+/, $line);
    my $cmd = shift @toks;
    if (!(defined $Commands->{$cmd})) {
	$cmd = uniqueCommand($cmd);
	if (!(defined $Commands->{$cmd})) {
	    logMsg($LOG_WARNING,  "Unrecognized command  \"$cmd\"\n");
	    next;
	}
    }
    my $funcptr = $Commands->{$cmd}->{FUNCTION};
    my $level = $Commands->{$cmd}->{LEVEL};
    ##  LEVEL 0 commands are executed immediately, anything else is saved and run at the appropriate time.
    ##  Run the command
    my $rec = [];
    push @$rec, $funcptr;
    push @$rec, @toks;
    push @commandList, $rec;  ##  Save command.
}

#print Dumper(\@commandList);
#close $CFG;
##  Execute the commands for each libfile.
foreach my $libFile (@libArray) {
    foreach my $cmdRec (@commandList) {
	my @toks = @$cmdRec;
	my $funcptr = $toks[0];
	##  Replace toks[0] (initially function pointer) with libFile to work on.
	$toks[0] = $libFile;
	$funcptr->(\@toks);
	
    }
}


foreach my $libFile (@libArray) {alphaLibParser::writeLib($libFile)}
######option -sb & -lc ###################
foreach my $libFile (@libArray) {
	my $lib_File= alphaLibParser::getName($libFile);
	if ($convertbrackets){
		my $lib = read_file_lib($lib_File);
		$lib=~ s/(\S+)\<(\d+)\>/$1\[$2\]/g;
		write_file_lib($lib_File, $lib);
		#$convertbrackets = 0;					
	}

	if($convert_Pin_name_to_lowercase){
		my $lib = read_file_lib($lib_File);
		$lib =~ s/(pin\s*)\((.*)\)/$1\(\L$2\)/g;
		write_file_lib($lib_File, $lib);
		#$convert_Pin_name_to_lowercase =0;
	}
	
}
}

#&Main();
exit;




sub read_file_lib{
	my($lib_File)= @_;
	#open my $in,"<$lib_File" or die "Could not open '$lib_File' for reading $!";
	my @in = read_file($lib_File);
	local $/ = undef;
	#my $all = <$in>;
	my $all = join("\n", @in);
	#close $in;
	return $all;
}

sub write_file_lib{

	my ($lib_File, $content) = @_ ;
	#open my $out, ">$lib_File" or die "Could not open '$lib_File' for writing $!";
	#print $out $content;
	#close $out;
	my $status = write_file($content, "$lib_File");
	return;
}


sub replace_zero_cap {
	my $toks =shift;
	my @command1 =@$toks;

	foreach my $libFile (@libArray) {
		my @pinlist = alphaLibParser::getPinList($libFile);
	   	my $spec_value = format_number($command1[1],6,6);
	   	foreach my $pin(@pinlist){
			my $pin_name = alphaLibParser::getName($pin);
			my $cap = alphaLibParser::getSimpleAttrValue($pin,"capacitance");
			if($cap =~m/0.000000/){
				my @command = ($libFile,$pin_name,"-attr","capacitance=$spec_value","-attr","rise_capacitance_range=$spec_value,$spec_value","-attr","fall_capacitance_range=$spec_value,$spec_value");
				setPinAttr_func(\@command);				
			}	
		}


	}
}

sub replace_Ref_Clk_Cap {
	my $toks =shift;
	my @command1 =@$toks;
	foreach my $libFile (@libArray) {
		my @pinlist = alphaLibParser::getPinList($libFile);
	   	my $spec_value = format_number($command1[1],6,6);
	   	foreach my $pin(@pinlist){
			my $pin_name = alphaLibParser::getName($pin);
			my $cap = alphaLibParser::getSimpleAttrValue($pin,"capacitance");
			if(($pin_name =~ m/ref_alt_clk_m|ref_alt_clk_p|ref_pad_clk_m|ref_pad_clk_p/)&&($cap > $spec_value)){
				my @command = ($libFile,$pin_name,"-attr","capacitance=$spec_value","-attr","rise_capacitance_range=$spec_value,$spec_value","-attr","fall_capacitance_range=$spec_value,$spec_value");
				setPinAttr_func(\@command);				
			}	
		}

	}
}


sub logMsg {
    my $severity = shift;
    my $msg = shift;
    my $forceStdout = shift;
    
    my $printStdout = 0;
    if ($severity == $LOG_INFO) {
	$printStdout = 0;
	$msg = "Info: $msg";
    }
    elsif ($severity == $LOG_WARNING) {
	$printStdout = 0;
	$msg = "Warning: $msg";
    }
    elsif ($severity == $LOG_ERROR) {
	$printStdout = 1;
	$msg = "Error: $msg";
    }
    elsif ($severity == $LOG_FATAL) {
	$printStdout = 1;
	$msg = "Fatal: $msg";
    }
    elsif ($severity == $LOG_RAW) {
	##  For untagged outputs.
	$printStdout = 0;
    }

#    if ($printStdout || $forceStdout) {print $msg}
    iprint ("$msg");
    
}

sub uniqueCommand {
    ##  Look for a unique match
    my $cmd = shift;
#    print "Looking for unique command for $cmd\n";
    
    my $i = 0;
    my $uCmd;
    foreach my $fullCmd (keys %$Commands) {
	if ($fullCmd =~ /^$cmd(.*)/) {
	    $i++;
	    $uCmd = $fullCmd;
#	    print "Found unique command $cmd --> $fullCmd\n";
	}
    }

    if ($i == 1) {return $uCmd} else {return $cmd};
}

sub sort_pins_func {
    my $toks = shift;

    my $libFile = shift @$toks;

    if (@$toks > 0) {
	logMsg($LOG_WARNING, "Extraneous args in sort_pins\n");
    }
    my $fileName = alphaLibParser::getName($libFile);
    logMsg($LOG_INFO, "Sorting pins of $fileName\n");
    alphaLibParser::sortPins($libFile);
}

sub globToRegexList {
    ##  Builds a regex pattern list from a glob list
    my $globList = shift;
    my @pattList;
    foreach my $glob (@$globList) {push @pattList, glob_to_regex_string($glob)}
    return @pattList;
}

sub deletePin_func {

    ##  Synopsis:
    ##    deletePin pin1 [pin2] [pin3] ...
    my $toks = shift;
    my $libFile = shift @$toks;
    
    if (@$toks == 0) {
	logMsg($LOG_WARNING, "No pins specified in deletePin\n");
	return;
    }
    my @pinNamePatts = globToRegexList($toks);
    
    my @cellList = alphaLibParser::getCellList($libFile);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 0);
	my @pinList = filterPinlist(\@rawPinList, $toks, 0);
	foreach my $pin (@rawPinList) {
	    my $pinName = alphaLibParser::getName($pin);
}
	foreach my $pin (@pinList) {
	    my $pinName = alphaLibParser::getName($pin);
	    if (alphaLibParser::deleteGroup($cell, "pin", $pinName)) {
		logMsg($LOG_INFO, "Deleted pin $pinName from cell $cellName\n");
		if($pinName =~ /(.*)</) {   alphaLibParser::updateBusDef($libFile,$1);}
	    }
	    else {
		logMsg($LOG_INFO, "Could not find  pin $pinName in cell $cellName\n");
	    }
	    my @removeRelPins = ($libFile,$pinName,"*");
	    deleteArc_related_pin_func(\@removeRelPins);
	}
    }
}
sub AddPin_attrib_func {

    my $toks = shift;
    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    my $PinName = shift @ARGV;
    my $cellName;
    my @attrList;
     my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	);

    my @cellList = alphaLibParser::getCellList($libFile);
my @pin = ($PinName);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 1);
	my @pinList = filterPinlist(\@rawPinList, \@pin, 0);
	if($#pinList>=0) {logMsg($LOG_WARNING, "pin $PinName already exist, not processing for AddPin\n"); return;}
	alphaLibParser::addPin($cell,$PinName);
	setPinAttr_func($toks);

}
}


sub AddPin_func {

    my $toks = shift;
    nprint ("$toks\n");
    my @command = @$toks;
    my @command1 = ($command[0],$command[1],"-attr","direction=$command[2]","-attr","capacitance=$command[3]","-attr","max_capacitance=$command[4]","-attr","min_capacitance=$command[5]","-attr","max_transition=$command[6]","-attr","min_transition=$command[7]","-attr","rise_capacitance_range=$command[8]","-attr","fall_capacitance_range=$command[9]");
    #print "@command\n";
    AddPin_attrib_func(\@command1); 
}

sub AddPgPin_attribute_func {
    my $toks = shift;
    my $libFile = shift @$toks;
    my @cellList = getCellList($libFile);
    my $libList = findAllGroups($libFile, "pg_pin");
    nprint ("@$libList");
}
sub AddPgPin_func {
    my $toks = shift;
    my @command = @$toks;
    my $pin = $command[1];
    my $libFile = shift @$toks;
    alphaLibParser::AddPgpin($libFile,$toks);
    $toks = \@command;
    $libFile = shift @$toks;
    alphaLibParser::AddVmapPin($libFile,$toks);
    @command = ($libFile, $pin);
    deletePin_func(\@command);
}
sub DelPgPin_func {
    my $toks = shift;
    my @command = @$toks;
    my $libFile = shift @$toks;
    alphaLibParser::DelPgpin($libFile,$toks);
}
sub AddVmap_func {

    my $toks = shift;
    my $libFile = shift @$toks;
    alphaLibParser::AddVmapPin($libFile,$toks);
}
sub port_pvt_seperate {

 my $toks = shift;
    my $libFile = shift @$toks;
    $libFile = alphaLibParser::copyObject($libFile);
    my @cellList = getCellList($libFile);
    my $libList = findAllGroups($libFile, "library");
    @ARGV = @$toks;
    my @attrList;
    my $result = GetOptions(
	"attrList=s@" => \@attrList,
	);
    
my $process = "none"; my $voltage = "none"; my $temp = "none"; my $corner_type = "none";
   foreach my $lib (@ARGV) { if($lib =~ /(.*)_(.*).*0p(.*)v(.*)c/) {$corner_type=$2; $voltage=$3;$temp=$4;}
    my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);
    foreach(@attrListParsed) {
    	if(@$_[0] eq "process"){$process = @$_[1];}
    	if(@$_[0] eq "voltage"){$voltage = @$_[1];}
    	if(@$_[0] eq "temperature"){$temp = @$_[1];}
    }
	my $lib_name = $lib;
	$lib_name =~ s/_PG.*//gi;
	my $temperature = $temp;
	$temperature =~ s/n/-/g;
    alphaLibParser::update_operating_cond(@$libList[0],$process,$corner_type,$voltage,$temp);
    if ($voltage ne "none") {alphaLibParser::AddLibrary_attrib(@$libList[0],"nom_voltage : ".sprintf("%f","0.$voltage"));}
    if ($temperature ne "none") {alphaLibParser::AddLibrary_attrib(@$libList[0],"nom_temperature : ".sprintf("%f",$temperature));}
    if ($process ne "none") {alphaLibParser::AddLibrary_attrib(@$libList[0],"nom_process : ".sprintf("%f",$process));}
	alphaLibParser::AddLibrary_attrib(@$libList[0],"library ($lib_name) {");
	alphaLibParser::AddLibrary_attrib(@$libList[0],"default_operating_conditions : "."$corner_type"."0p$voltage"."v$temp"."c");

       alphaLibParser::writeLib($libFile);
}
}


sub DelVmap_func {

    my $toks = shift;
    my @command = @$toks;
    my $libFile = shift @$toks;
    alphaLibParser::DelVmapPin($libFile,$toks);
}
sub Edit_Lib_value {

 my $toks = shift;
    my $libFile = shift @$toks;
    my @cellList = getCellList($libFile);
    my $libList = findAllGroups($libFile, "library");
    
    alphaLibParser::AddLibrary_attrib(@$libList[0],@$toks[0]);
}
sub Delete_Lib_value {

 my $toks = shift;
    my $libFile = shift @$toks;
    my @cellList = getCellList($libFile);
    my $libList = findAllGroups($libFile, "library");
    
    alphaLibParser::DelLibrary_attrib(@$libList[0],$toks);
}

sub createBus_func {
    my $toks =  shift ;
    $libFile = shift @$toks;
    
    my $pin = shift @$toks;
    @ARGV = @$toks;
    my $cellName;
    my @attrList;
    my $msb;
    my $lsb;
    my $copyAttr = 1;  ## Copy common attributes from pins to bus
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"lsb=s" => \$lsb,
	"msb=s" => \$msb
	);
	
    my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);
    my @cellList = alphaLibParser::getCellList($libFile);
    alphaLibParser::Addbus($libFile,"$pin",$msb,$lsb,\@attrListParsed);

}

sub AddBus_func {

    my $toks = shift;
    my @command = @$toks;
    my @command1 = ($command[0],$command[1],"-msb","$command[2]","-lsb","$command[3]","-attr","direction=$command[4]","-attr","capacitance=$command[5]","-attr","max_capacitance=$command[6]","-attr","min_capacitance=$command[7]","-attr","max_transition=$command[8]","-attr","min_transition=$command[9]","-attr","rise_capacitance_range=$command[10]","-attr","fall_capacitance_range=$command[11]");
    createBus_func(\@command1);
}


sub CorrectBit_from_to_func {

    my $toks = shift;

    @ARGV = @$toks;
    my $libFile = shift @ARGV;

    alphaLibParser::updateBusInfo($libFile);

}

sub CopyBus_func {

    my $toks = shift;

    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
    my $src_pin = $ARGV[0];
    my $dst_pin = $ARGV[1];
    
    my @pin;
    my $msb;
    my $lsb;
    my $cellName;
    my @attrList;
    my $copyAttr = 1;  ## Copy common attributes from pins to bus
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"msb=s" => \$msb,
	"lsb=s" => \$lsb
	);

    my $delete = pop @$toks;
my $parent = alphaLibParser::copyBusattrib($libFile, $src_pin, $dst_pin,$msb,$lsb);

for (my $i=$lsb; $i<=$msb; $i++) {
	$pin[0]="$src_pin<$i>";
	
    if($delete !~ /copy_timing/) {logMsg($LOG_ERROR, "problem in passing arguments with copy_bus, use either copy_timing/dont_copy_timing\n");	return;}
    if (@$toks == 0) {
	logMsg($LOG_WARNING, "No pins specified in copy_bus\n");
	return;
    }

    my @cellList = alphaLibParser::getCellList($libFile);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 0);

	my @pinList = filterPinlist(\@rawPinList, \@pin, 0);
	if($#pinList<0) {logMsg($LOG_WARNING, "pin $pin[0] not found in cell $cellName\n");}
	foreach my $pin (@pinList) {
	    my $pinName = alphaLibParser::getName($pin);
	    	    my $newmember = alphaLibParser::copyObject($pin);
		     alphaLibParser::AddMember($parent,$newmember);
	    	     alphaLibParser::renameClsGRP_name($newmember, $pinName, "$dst_pin<$i>");
		if($delete =~ /dont_copy_timing/) {
		    my @pinList = alphaLibParser::getPinList($libFile);
			my $pin = findPinInList("$dst_pin<$i>", \@pinList);
			if (defined $pin) {alphaLibParser::deleteGroup($pin, "timing", undef);}
					}
	}
    }
}
	
#	print "$lsb to $msb\n";
alphaLibParser::updateBusDef($libFile,"$src_pin");


}
sub CopyBus_1lib2other_func {

    my $toks = shift;
    unless(defined $RefLib) {shift(@$toks);logMsg($LOG_ERROR, "Mandatory Argument -RefLib not defined. It is mandatory to use \"-RefLib\" with copy_bus_fromRefLib @$toks\n");return;}

    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
    my $src_pin = $ARGV[0];
    my $dst_pin = $ARGV[1];
    my @pin;
    my $msb;
    my $lsb;
    my $cellName;
    my @attrList;
    my $copyAttr = 1;  ## Copy common attributes from pins to bus
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"msb=s" => \$msb,
	"lsb=s" => \$lsb
	);
    my $delete = pop @$toks;
my $parent = alphaLibParser::copyBusattrib($libFile, $src_pin, $dst_pin,$msb,$lsb);
for (my $i=$lsb; $i<=$msb; $i++) {
	$pin[0]="$src_pin<$i>";
    if($delete !~ /copy_timing/) {logMsg($LOG_ERROR, "problem in passing arguments with copy_bus, use either copy_timing/dont_copy_timing\n");	return;}
    if (@$toks == 0) {
	logMsg($LOG_WARNING, "No pins specified in copy_bus\n");
	return;
    }
	#print Dumper("AA",$libFile);
    my @cellList = alphaLibParser::getCellList($RefLib);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 0);
	my @pinList = filterPinlist(\@rawPinList, \@pin, 0);
	if($#pinList<0) {logMsg($LOG_WARNING, "pin $pin[0] not found in cell $cellName\n");}
	foreach my $pin (@pinList) {
	    my $pinName = alphaLibParser::getName($pin);
	    	    my $newmember = alphaLibParser::copyObject($pin);
		     alphaLibParser::AddMember($parent,$newmember);
	    	     alphaLibParser::renameClsGRP_name($newmember, $pinName, "$dst_pin<$i>");
		if($delete =~ /dont_copy_timing/) {
		    my @pinList = alphaLibParser::getPinList($libFile);
			my $pin = findPinInList("$dst_pin<$i>", \@pinList);
			if (defined $pin) {alphaLibParser::deleteGroup($pin, "timing", undef);}
					}
	}
    }
}
	
#	print "$lsb to $msb\n";
alphaLibParser::updateBusDef($libFile,"$src_pin");


}
sub MapBus_1lib2other_func {

    my $toks = shift;
    unless(defined $RefLib) {shift(@$toks);logMsg($LOG_ERROR, "Mandatory Argument -RefLib not defined. It is mandatory to use \"-RefLib\" with map_bus_fromRefLib @$toks\n");return;}

    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
    my @pin;
    my $src_pin;
    $pin[0]=$ARGV[0];
    if($pin[0] =~ /(.*)(<|\])/) {$src_pin=$1;} else {logMsg($LOG_ERROR, "problem in passing arguments with map_bus,provide bit number, instead of $ARGV[0] use $ARGV[0]<0>\n");	return; }
    my $dst_pin = $ARGV[1];
    
    my $msb;
    my $lsb;
    my $cellName;
    my @attrList;
    my $copyAttr = 1;  ## Copy common attributes from pins to bus
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"msb=s" => \$msb,
	"lsb=s" => \$lsb
	);

    my $delete = pop @$toks;
my $parent = alphaLibParser::copyBusattrib($libFile, $src_pin, $dst_pin,$msb,$lsb);

for (my $i=$lsb; $i<=$msb; $i++) {
	
    if($delete !~ /copy_timing/) {logMsg($LOG_ERROR, "problem in passing arguments with map_bus, use either copy_timing/dont_copy_timing\n");	return;}
    if (@$toks == 0) {
	logMsg($LOG_WARNING, "No pins specified in copy_bus\n");
	return;
    }

    my @cellList = alphaLibParser::getCellList($RefLib);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 0);

	my @pinList = filterPinlist(\@rawPinList, \@pin, 0);
	if($#pinList<0) {logMsg($LOG_WARNING, "pin $pin[0] not found in cell $cellName\n");}
	foreach my $pin (@pinList) {
	    my $pinName = alphaLibParser::getName($pin);
	    	    my $newmember = alphaLibParser::copyObject($pin);
		     alphaLibParser::AddMember($parent,$newmember);
	    	     alphaLibParser::renameClsGRP_name($newmember, $pinName, "$dst_pin<$i>");
		if($delete =~ /dont_copy_timing/) {
		    my @pinList = alphaLibParser::getPinList($libFile);
			my $pin = findPinInList("$dst_pin<$i>", \@pinList);
			if (defined $pin) {alphaLibParser::deleteGroup($pin, "timing", undef);}
					}
	}
    }
}
	
#	print "$lsb to $msb\n";
alphaLibParser::updateBusDef($libFile,"$src_pin");


}
sub MapBus_func {

    my $toks = shift;

    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
    my @pin;
    my $src_pin;
    $pin[0]=$ARGV[0];
    if($pin[0] =~ /(.*)(<|\])/) {$src_pin=$1;} else {logMsg($LOG_ERROR, "problem in passing arguments with map_bus,provide bit number, instead of $ARGV[0] use $ARGV[0]<0>\n");	return; }
    my $dst_pin = $ARGV[1];
    
    my $msb;
    my $lsb;
    my $cellName;
    my @attrList;
    my $copyAttr = 1;  ## Copy common attributes from pins to bus
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"msb=s" => \$msb,
	"lsb=s" => \$lsb
	);

    my $delete = pop @$toks;
my $parent = alphaLibParser::copyBusattrib($libFile, $src_pin, $dst_pin,$msb,$lsb);

for (my $i=$lsb; $i<=$msb; $i++) {
	
    if($delete !~ /copy_timing/) {logMsg($LOG_ERROR, "problem in passing arguments with map_bus, use either copy_timing/dont_copy_timing\n");	return;}
    if (@$toks == 0) {
	logMsg($LOG_WARNING, "No pins specified in copy_bus\n");
	return;
    }

    my @cellList = alphaLibParser::getCellList($libFile);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 0);

	my @pinList = filterPinlist(\@rawPinList, \@pin, 0);
	if($#pinList<0) {logMsg($LOG_WARNING, "pin $pin[0] not found in cell $cellName\n");}
	foreach my $pin (@pinList) {
	    my $pinName = alphaLibParser::getName($pin);
	    	    my $newmember = alphaLibParser::copyObject($pin);
		     alphaLibParser::AddMember($parent,$newmember);
	    	     alphaLibParser::renameClsGRP_name($newmember, $pinName, "$dst_pin<$i>");
		if($delete =~ /dont_copy_timing/) {
		    my @pinList = alphaLibParser::getPinList($libFile);
			my $pin = findPinInList("$dst_pin<$i>", \@pinList);
			if (defined $pin) {alphaLibParser::deleteGroup($pin, "timing", undef);}
					}
	}
    }
}
	
#	print "$lsb to $msb\n";
alphaLibParser::updateBusDef($libFile,"$src_pin");


}
sub CopyPin_func {
    ##  Synopsis:
    ##    deletePin pin1 [pin2] [pin3] ...

    my $toks = shift;
    my @toks_bck = @$toks;
    my $libFile = shift @$toks;
    my $delete = pop @$toks;
    if($delete !~ /copy_timing/) {logMsg($LOG_ERROR, "problem in passing arguments with copy_pin, use either copy_timing/dont_copy_timing\n");	return;}
    if (@$toks == 0) {
	logMsg($LOG_WARNING, "No pins specified in copy_pin\n");
	return;
    }
    my @pin;
    my @command = @$toks;
    $pin[0] = shift @$toks;
    my @cellList = alphaLibParser::getCellList($libFile);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 1);
	my @pinList = filterPinlist(\@rawPinList, \@pin, 0);
	if($#pinList<0) {logMsg($LOG_WARNING, "pin $pin[0] not found in cell $cellName\n");}
	foreach my $pin (@pinList) {
	    my $pinName = alphaLibParser::getName($pin);
	    my $parent = alphaLibParser::getParent($pin);
	    	    my $newmember = alphaLibParser::copyObject($pin);
		     alphaLibParser::AddMember($parent,$newmember);
	    	     alphaLibParser::renameClsGRP_name($newmember, $pinName, $command[1]);
		if($delete =~ /dont_copy_timing/) {
		    my @pinList = alphaLibParser::getPinList($libFile);
			my $pin = findPinInList($command[1], \@pinList);
			if (defined $pin) {alphaLibParser::deleteGroup($pin, "timing", undef);}
					}
	}
    }
}
sub CopyPin_1lib2other_func {
    ##  Synopsis:
    ##    deletePin pin1 [pin2] [pin3] ...

    my $toks = shift;
    unless(defined $RefLib) {shift(@$toks);logMsg($LOG_ERROR, "Mandatory Argument -RefLib not defined. It is mandatory to use \"-RefLib\" with copy_pin_fromRefLib @$toks\n");return;}
    my @toks_bck = @$toks;
    my $libFile = shift @$toks;
    my $delete = pop @$toks;
    if($delete !~ /copy_timing/) {logMsg($LOG_ERROR, "problem in passing arguments with copy_pin, use either copy_timing/dont_copy_timing\n");	return;}
    if (@$toks == 0) {
	logMsg($LOG_WARNING, "No pins specified in copy_pin\n");
	return;
    }
    my @pin;
    my @command = @$toks;
    $pin[0] = shift @$toks;
    
    my $parent = alphaLibParser::getParent((alphaLibParser::getPinList($libFile))[0]);    
    my @cellList = alphaLibParser::getCellList($RefLib);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 1);
	my @pinList = filterPinlist(\@rawPinList, \@pin, 0);
	if($#pinList<0) {logMsg($LOG_WARNING, "pin $pin[0] not found in cell $cellName\n");}
	foreach my $pin (@pinList) {
	    my $pinName = alphaLibParser::getName($pin);
	    	    my $newmember = alphaLibParser::copyObject($pin);
		     alphaLibParser::AddMember($parent,$newmember);
	    	     alphaLibParser::renameClsGRP_name($newmember, $pinName, $command[1]);
		if($delete =~ /dont_copy_timing/) {
		    my @pinList = alphaLibParser::getPinList($libFile);
			my $pin = findPinInList($command[1], \@pinList);
			if (defined $pin) {alphaLibParser::deleteGroup($pin, "timing", undef);}
					}
	}
    }
}

sub RenamePin_func {
    ##  Synopsis:
    ##    deletePin pin1 [pin2] [pin3] ...

    my $toks = shift;
    my $toks_ori = $toks;
push(@$toks,"*");
renameArc_related_pin_func($toks);
    my $libFile = shift @$toks;
    
    if (@$toks == 0) {
	logMsg($LOG_WARNING, "No pins specified in deletePin\n");
	return;
    }
    my @pin;
    my @command = @$toks;
    $pin[0] = shift @$toks;
    my @cellList = alphaLibParser::getCellList($libFile);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 1);
	my @pinList = filterPinlist(\@rawPinList, \@pin, 0);
	if($#pinList<0) {logMsg($LOG_WARNING, "Renaming not find  pin $pin[0] in cell $cellName\n");}
	foreach my $pin (@pinList) {
	    my $pinName = alphaLibParser::getName($pin);
	    	    if (alphaLibParser::renameGroup($cell, "pin", $pinName, $command[1],0)) {
		logMsg($LOG_INFO, "Renaming pin $pinName from cell $cellName to $command[1] from cell $cellName \n");
	    }
	    else {
		logMsg($LOG_WARNING, "Renaming not find  pin $pinName in cell $cellName\n");
	    }
    
	}
    }

}


sub sort_arcs_func {
    my $toks = shift;

    my $libFile = shift @$toks;

    if (@$toks > 0) {
	logMsg($LOG_WARNING, "Extraneous args in sort_arcs\n");
    }
    my $fileName = alphaLibParser::getName($libFile);
    logMsg($LOG_INFO, "Sorting arcs of $fileName\n");
    alphaLibParser::sortArcs($libFile);
}

#sub ShowUsage {
#    print "Current script path:  $ScriptPath\n";
#    pod2usage(0);
#}

sub process_cmd_line_args(){
    my ($outdir,$configFile,$RefLib,$convertbrackets,$convert_Pin_name_to_lowercase,$opt_help,$opt_dryrun,$opt_debug,$opt_verbosity);
    my $success = GetOptions(
                "help|h"         => \$opt_help,
		        "outdir=s"       => \$outdir,
                "dryrun!"        => \$opt_dryrun,
                "debug=i"        => \$opt_debug,
                "verbosity=i"    => \$opt_verbosity,
                "Config=s"       => \$configFile,
                "RefLib=s"       => \$RefLib,
                "sb"	     => \$convertbrackets,
                "lc"	     => \$convert_Pin_name_to_lowercase		       
	); 

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );
	$outdir          = "libEdit"               if (not defined $outdir);

    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    return ($opt_debug,$outdir,$configFile,$RefLib,$convertbrackets,$convert_Pin_name_to_lowercase,$opt_help);  
#($debug,$outdir,$configFile,$RefLib,$convertbrackets,$convert_Pin_name_to_lowercase,$opt_help)
}    

sub usage($) {
    my $exit_status = shift || '0';
	pod2usage($exit_status);
   
}    
    
sub Tokenify {
    ## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = shift;
    $line =~ s/^\s+?(.*)\s+$/$1/;
    $line =~ s/\s*=\s*/=/g;   ## Strip any whitespace around "=" signs.  Makes later parsing easier.
    return split(/\s+/, $line);
}

sub parseAttrSpecList {
    ##  Takes a list of attr specs (name=val), and returns a parsed list
    my ($attrList, $minArg, $maxArg) = @_;
    
    
    my @attrListParsed;
    foreach my $attrSpec (@$attrList) {
	my $rec = [];
	@$rec = parseAttrSpec($attrSpec, $minArg, $maxArg);
	if (defined $rec->[0]) {push @attrListParsed, $rec}
    }
    return @attrListParsed;
}


sub AddRelatedPin_func {
    my $toks = shift;
    my @command = @$toks;
    splice(@command,2,2,"-attr","related_power_pin=$command[2]","-attr","related_ground_pin=$command[3]");
 #    my @command = @command;
   setPinAttr_func(\@command); 
if($command[1] =~ /\[/) {
$command[1]=~ s/\[.*\]//g;
    AddBusmainInfo_func(\@command); 
}
}
sub AddBusInfo_func {
    my $toks = shift;
    my @command = @$toks;
	foreach($command[3]..$command[2]) {push( @command,"$command[1]<$_>");}
    splice(@command,1,3);
    setPinAttr_func(\@command); 
}
sub AddBusmainInfo_func {
    my $toks = shift;
    my @command = @$toks;
    setmainBusAttr_func(\@command); 
}


sub deleteBus_info_func {
    my $toks = shift;
    my @command = @$toks;
    my $pin = $command[1];
    my $lsb=$command[3];
    my $msb=$command[2];
	splice(@command,2,2);
	foreach($lsb..$msb) {
    
    $command[1]="$pin<$_>";
    
    delPinAttr_func(\@command); 
}
}
sub deleteBus_maininfo_func {
    my $toks = shift;
    my @command = @$toks;
    
    delmainBusAttr_func(\@command); 
}
sub AddRelatedBus_func {
    my $toks = shift;
    my @command = @$toks;
    my @command1 = ($command[0],"-attr","direction=$command[4]","-attr","related_power_pin=$command[5]","-attr","related_ground_pin=$command[6]");
	foreach($command[3]..$command[2]) {push( @command1,"$command[1]<$_>");}
    setPinAttr_func(\@command1); 
}
sub setPinAttrib_func {
    my $toks = shift;
    my @command = @$toks;
    splice(@command,2,2,"-attr","$command[2]=$command[3]");
    setPinAttr_func(\@command); 
}
sub setPinDirection_func {
    my $toks = shift;
    my @command = @$toks;
    #checking if bus
    if($command[1] =~ /\<|\>|\[|\]/ && $command[1] =~ /\*/) {
        my @busCommand;
        push (@busCommand,$command[0]);
	my ($busname) = ($command[1] =~ /([a-z0-9_\-]+)/);
	push(@busCommand,$busname);
	push(@busCommand,"-attr","direction=$command[2]");
	setmainBusAttr_func(\@busCommand);
    }
    splice(@command,2,2,"-attr","direction=$command[2]");
    setPinAttr_func(\@command);
}
sub setBusDirection_func {
	my $toks = shift;
	my @command = @$toks;
	my $allPins = "${command[1]}[*]";
	splice(@command,2,2,"-attr","direction=$command[2]");
	setmainBusAttr_func(\@command);
	#changing pin directions inside the bus
	splice(@command,1,1,$allPins);print "com @command\n";
	setPinAttr_func(\@command);
}
sub setPinClock_func {
    my $toks = shift;
    my @command = @$toks;
    splice(@command,2,2,"-attr","clock=true");
    setPinAttr_func(\@command); 
}
sub setCellArea_func {
    my $toks = shift;
    my @command = @$toks;
    splice(@command,1,1,"-attr","area=$command[1]");
    setCellAttr_func(\@command); 
}
sub setCellAttr_func {
    my $toks = shift;
   
    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
   
    
    my $cellName;
    my @attrList;
    my $copyAttr = 1;  ## Copy common attributes from pins to bus
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList
	);

    my @cellList = alphaLibParser::getCellList($libFile);
	
    foreach my $cell (@cellList) {
	##  Process each cell
    
    my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);
	  	foreach my $attrRec (@attrListParsed) {
	next if($attrRec->[1] eq "none" || $attrRec->[1] eq "NONE") ;
	if($attrRec->[1] =~ /,/) {
	$attrRec->[1] =~  s/,/, /g;
	$attrRec->[1] =~  s/\"|  //g;
	    alphaLibParser::setComplexAttr($cell, $attrRec->[0], $attrRec->[1]);
	    } else {
	    alphaLibParser::setSimpleAttr($cell, $attrRec->[0], $attrRec->[1]);
		}
		}
		}
}
sub delPinAttrib_func {
    my $toks = shift;
    my @command = @$toks;
    splice(@command,2,1,"-attr","$command[2]");
    delPinAttr_func(\@command); 
}

sub setPinAttr_func {
    ##  Sets an arbitrary attribute for a pin group.
    ##  Changes value if exists, creates new if it does not.
    ##  Form:
    ##     setPinAttr pin1 [pin2] [pin3] ... -attrName1 attrVal1 [-attrName2 attrVal2] ...
    ##
    #  Doesn't use getopt to parse the command args because the attrName args could be anything.
    my $toks = shift;
    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
    
    my $cellName;
    my @attrList;
    my $copyAttr = 1;  ## Copy common attributes from pins to bus
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList
	);
    
    
    ##  $toks just has list of pin globs
    my @rawPinList = alphaLibParser::getPinList($libFile);
    my @pinList = filterPinlist(\@rawPinList, \@ARGV, 0);
    
    ##  Pre-parse the attr specs so errors are flagged only once.
    my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);
    
    foreach my $pin (@pinList) {
	foreach my $attrRec (@attrListParsed) {
	next if($attrRec->[1] eq "none" || $attrRec->[1] eq "NONE") ;
	if($attrRec->[1] =~ /,/) {
	$attrRec->[1] =~  s/,/, /g;
	$attrRec->[1] =~  s/\"|  //g;
	    alphaLibParser::setComplexAttr($pin, $attrRec->[0], $attrRec->[1]);
	    } else {
	    alphaLibParser::setSimpleAttr($pin, $attrRec->[0], $attrRec->[1]);
		}

	}
    }
}
sub delmainBusAttr_func {
    ##  Deletes an attribute for a pin group.
    
    my $toks = shift;
    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
    my $cellName;
    my @attrList;
     my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList
	);


    my $args = parseArgsSimple(0, $toks);   ##  Parse args, but no value expected for options.
    
    my @rawPinList = alphaLibParser::getPinList($libFile);
    my @pinList = filterPinlist(\@rawPinList, \@ARGV, 1);
    foreach my $pin (@pinList) {
    	    my $parent = alphaLibParser::getParent($pin);
	    foreach my $attrName (@attrList) {
		unless(alphaLibParser::delSimpleAttr($parent, $attrName)) {
			unless(alphaLibParser::delComplexAttr($parent, $attrName)) {print "$attrName not deleted from @ARGV\n";}
			}
    		return;
		}
	    
	}
	
    
}

sub setmainBusAttr_func {
    my $toks = shift;
    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
   
    
    
    my $cellName;
    my @attrList;
    my $copyAttr = 1;  ## Copy common attributes from pins to bus
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList
	);
    
    
    ##  $toks just has list of pin globs
    my @rawPinList = alphaLibParser::getPinList($libFile);
    my @pinList = filterPinlist(\@rawPinList, \@ARGV, 1);
    
    ##  Pre-parse the attr specs so errors are flagged only once.
    my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);

    foreach my $pin (@pinList) {
    	    my $parent = alphaLibParser::getParent($pin);
	foreach my $attrRec (@attrListParsed) {
	next if($attrRec->[1] eq "none" || $attrRec->[1] eq "NONE") ;
	if($attrRec->[1] =~ /,/) {
	$attrRec->[1] =~  s/,/, /g;
	$attrRec->[1] =~  s/\"|  //g;
	    alphaLibParser::setComplexAttr($parent, $attrRec->[0], $attrRec->[1]);
	    } else {
	    alphaLibParser::setSimpleAttr($parent, $attrRec->[0], $attrRec->[1]);
		}

	}
    return;
    }
}

sub parseAttrSpec {
    ##  Parses astring of the form "attrName:attrValue"
    my ($spec, $minArg, $maxArg) = @_;
    
    $spec =~ s/^\s+|\s+$//g;   ##  Trim leading/trailing whitespace
    my @t = split(/[=: ]/, $spec);
    if (@t < $minArg) {
	logMsg($LOG_ERROR, "Bad format for attribute spec \"$spec\", expecting at least $minArg fields\n");
	return (undef, undef);
    }
    elsif (@t > $maxArg) {
	logMsg($LOG_ERROR, "Bad format for attribute spec \"$spec\", expecting at most $maxArg fields\n");
	return (undef, undef);
    }
    else {
	return @t;
    }
}


sub setCellAttr_func_1 {
    my $toks = shift;
   
    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
   
    
    my $cellName;
    my @attrList;
    my $copyAttr = 1;  ## Copy common attributes from pins to bus
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList
	);
  



    my $cellPatt; my @cellList; my @cellAttr;
    ##  $toks just has list of pin globs
	my $libList = alphaLibParser::findAllGroups($libFile, "library");
	foreach my $lib (@$libList) {
	    my $libCellList = alphaLibParser::findAllGroups($lib, "cell");
	    push @cellAttr, @$libCellList;
	}

    if (defined $cellName) { $cellPatt = glob_to_regex_string($cellName);}
    foreach my $cell (@cellList) {
	foreach my $attrRec (@cellAttr) {
	my $n = alphaLibParser::getName($attrRec);
	my $v = alphaLibParser::getValue($attrRec);
	   print " alphaLibParser::setSimpleAttr($cell, $n, $v);\n";


	}
    }
}

sub getTimingList {
    ##  Builds a list of timing groups based on:
    my ($parent, $cellName, $pinPattList, $attrList) = @_;
    my $cellPatt;
    my @pin_list = @$pinPattList;
    if (defined $cellName) {$cellPatt = glob_to_regex_string($cellName)}
    my @cellList = alphaLibParser::getCellList($parent, $cellPatt);

    ##  Pre-parse the attr specs so errors are flagged only once.
    my %attrHash = attrList2Hash($attrList);
	foreach (keys %attrHash) {$attrHash{$_} =~ tr/<>/[]/;}

    my @timingList;
    foreach my $cell (@cellList) {
	##  Process each cell
	my $n = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell);
	foreach (@pin_list) {$_ =~ tr/<>/[]/;}
	my @pinList = filterPinlist(\@rawPinList, \@pin_list, 0);
	my $pin;
	foreach my $pin (@pinList) {
	    my $pn = alphaLibParser::getName($pin);
	    my $pinTimingList = alphaLibParser::findAllGroups($pin, "timing");
	    my $tn = @$pinTimingList;
#	    print "!! cell=$n, pin=$pn, $tn timing groups found\n";
	    foreach my $timing (@$pinTimingList) {
		if (timingAttrMatch($timing, \%attrHash)) {push @timingList, $timing}
	    }
	}
    }
    return @timingList;
}
sub getComplexattributeList {
    ##  Builds a list of timing groups based on:
    my ($parent, $cellName, $pinPattList, $attrList, $ComplexAttrib_name) = @_;
    my $cellPatt;
    my @pin_list = @$pinPattList;
    if (defined $cellName) {$cellPatt = glob_to_regex_string($cellName)}
    my @cellList = alphaLibParser::getCellList($parent, $cellPatt);

    ##  Pre-parse the attr specs so errors are flagged only once.
    my %attrHash = attrList2Hash($attrList);
	foreach (keys %attrHash) {$attrHash{$_} =~ tr/<>/[]/;}

    my @timingList;
    foreach my $cell (@cellList) {
	##  Process each cell
	my $n = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell);
	foreach (@pin_list) {$_ =~ tr/<>/[]/;}
	my @pinList = filterPinlist(\@rawPinList, \@pin_list, 0);
	my $pin;
	foreach my $pin (@pinList) {
	    my $pn = alphaLibParser::getName($pin);
	    my $pinTimingList = alphaLibParser::findAllGroups($pin, "$ComplexAttrib_name");
	    my $tn = @$pinTimingList;
#	    print "!! cell=$n, pin=$pn, $tn timing groups found\n";
	    foreach my $timing (@$pinTimingList) {
		if (timingAttrMatch($timing, \%attrHash)) {push @timingList, $timing}
	    }
	}
    }
    return @timingList;
}

sub delete_min_delay {
    my $toks = shift;
    my @command = @$toks;
    if ($command[1] =~ /true/i) {
    splice(@command,1,1,"-attr","min_delay_flag=$command[1]","*");
    my $n = deleteArc_func(\@command); 
    if ($n <= 0) {
	logMsg($LOG_WARNING, "No arcs found for delete_min_delay @$toks\n");
    }
    } elsif($command[1] =~ /false/i){
    splice(@command,1,1,"-attr","min_delay_flag=true","*","-except");
    my $n = deleteArc_func(\@command); 
    if ($n <= 0) {
	logMsg($LOG_WARNING, "No arcs found for delete_min_delay @$toks\n");
    }
    } else {logMsg($LOG_WARNING, "True/false  is expected with delete_min_delay @$toks\n");return;}
}


sub  deleteArcWhen_func{
    my $toks = shift;
    my @command = @$toks;
 if(defined $command[5])  {  @command= ($command[0],"-delete","$command[1]","$command[2]","-attr","related_pin=$command[3]","-attr","timing_type=$command[4]","-attr","timing_sense=$command[5]");}
 else {@command= ($command[0],"-delete","$command[1]","$command[2]","-attr","related_pin=$command[3]","-attr","timing_type=$command[4]");}
    my $n = deleteArc_func(\@command); 
    if ($n <= 0) {
	logMsg($LOG_WARNING, "No arcs found for del_arc_attr @$toks\n");
    }
}
sub  deleteArcWhenExcept_func{
    my $toks = shift;
    my @command = @$toks;
    if(defined $command[5])  {   splice(@command,1,5,"-delete","$command[1]","$command[2]","-attr","related_pin=$command[3]","-attr","timing_type=$command[4]","-attr","timing_sense=$command[5]","-except");}
    else { splice(@command,1,5,"-delete","$command[1]","$command[2]","-attr","related_pin=$command[3]","-attr","timing_type=$command[4]","-except");}
    
    my $n = deleteArc_func(\@command); 
    if ($n <= 0) {
	logMsg($LOG_WARNING, "No arcs found for del_arc_attr_except @$toks\n");
    }
}
sub deleteArc_related_pin_func {
    my $toks = shift;
    my @command = @$toks;
    splice(@command,1,1,"-attr","related_pin=$command[1]");
    my $n = deleteArc_func(\@command); 
    if ($n <= 0) {
	logMsg($LOG_WARNING, "No arcs found for r @$toks\n");
    }
}


sub delete_Complex_func {
    my $toks = shift;
    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
    my $n = alphaLibParser::getName($libFile);
    my $cellName;
    my @attrList;
    my $delete;
    my $except;
    my $ComplexAttrib_name;
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"delete=s" => \$delete,
	"except" => \$except,
	"ComplexAttrib=s" => \$ComplexAttrib_name
	);
	
    unless(defined $delete) {$delete = "*"}
    my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);
    my @timingList = getComplexattributeList($libFile, $cellName, \@ARGV, \@attrListParsed, "$ComplexAttrib_name");
    $n = @timingList;
    if ($n > 0) {
	##  Found some arcs.
	my $i = 0;
	foreach my $timing (@timingList) {
	    my $parent = alphaLibParser::getParent($timing);
	    	if (!defined $except) {
		if($delete eq "*") {
			alphaLibParser::removeMember($parent, $timing);
	   	 } else {
     		        my $type = alphaLibParser::findAllGroups($timing, $delete);
			foreach my $delete (@$type) {alphaLibParser::removeMember($timing,$delete);}
			alphaLibParser::remove_empty_timingMember($parent,$timing);
			
			#$type = alphaLibParser::findAllGroups($timing, "*");
			#my $flag = 0;
			#foreach $delete (@$type) {print $$flag =1; last;}
			#if($flag == 0) {print "$delete:$flag:hello\n";alphaLibParser::removeMember($parent, $timing);} else {print "not delete\n";}
			}
		} else {
		 ###except will delete an attribute which doesn not match the remaining specifications.
     		        my $all = alphaLibParser::findAllGroups($timing);
      		        my $type = alphaLibParser::findAllGroups($timing, $delete);
			my $matched;
			foreach my $delete (@$all) {
				$matched = "";
				foreach my $except (@$type) {$matched = "matched" if($delete eq $except);}
				if($matched ne "matched") {
					if($delete eq "*") {
						alphaLibParser::removeMember($parent, $timing);
	   	 				}
						else {
						alphaLibParser::removeMember($timing,$delete);
						}
				}
				}
		}
			
		}
    }
    return $n;
}

sub del_timing_attr_func {
 my $toks = shift;
    my $delete = shift;
    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    my $n = alphaLibParser::getName($libFile);
    if (@ARGV == 0) {push @ARGV, "*"}
	
    my $cellName;
    my @attrList;
    my @delete;
    my $parent;
    my $newmember;
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"delete=s@" => \@delete
	);
   my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);
   my @timingList = getTimingList($libFile, $cellName, \@ARGV, \@attrListParsed);

    $n = @timingList;
    my @newmembers;
    if ($n > 0) {
	foreach my $timing (@timingList) {
		foreach my $attrName (@delete) {
		unless(alphaLibParser::delSimpleAttr($timing, $attrName)) {
			unless(alphaLibParser::delComplexAttr($timing, $attrName)) {logMsg($LOG_WARNING, "del_timing_attr:$attrName not present in all respective timing section\n");}
			else {logMsg($LOG_INFO, "del_timing_attr:$attrName deleted\n");}
			} else {logMsg($LOG_INFO, "del_timing_attr:$attrName deleted\n");}
			}
	}
    }
    if ($n < 0) {
	logMsg($LOG_WARNING, "No arcs found for del_timing_attr @$toks\n");
    }
}
sub deleteArc_func {
    my $toks = shift;
    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
    my $n = alphaLibParser::getName($libFile);
    my $cellName;
    my @attrList;
    my $delete;
    my $except;
#    print "###@ARGV\n";
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"delete=s" => \$delete,
	"except" => \$except,
	);
	
    unless(defined $delete) {$delete = "*"}
   my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);
   my @timingList = getTimingList($libFile, $cellName, \@ARGV, \@attrListParsed);
    $n = @timingList;
   if ($n > 0) {
	##  Found some arcs.
	my $i = 0;
	foreach my $timing (@timingList) {
	    my $parent = alphaLibParser::getParent($timing);
	    	if (!defined $except) {
		if($delete eq "*") {
			alphaLibParser::removeMember($parent, $timing);
	   	 } else {
     		    my $type = alphaLibParser::findAllGroups($timing, $delete);
			    foreach my $delete (@$type) {alphaLibParser::removeMember($timing,$delete);}
			         alphaLibParser::remove_empty_timingMember($parent,$timing);
			
			#$type = alphaLibParser::findAllGroups($timing, "*");
			#my $flag = 0;
			#foreach $delete (@$type) {print $$flag =1; last;}
			#if($flag == 0) {print "$delete:$flag:hello\n";alphaLibParser::removeMember($parent, $timing);} else {print "not delete\n";}
			}
		} else {
		 ###except will delete an attribute which doesn not match the remaining specifications.
     		        my $all = alphaLibParser::findAllGroups($timing);
      		        my $type = alphaLibParser::findAllGroups($timing, $delete);
			my $matched;
			foreach my $delete (@$all) {
				$matched = "";
				foreach my $except (@$type) {$matched = "matched" if($delete eq $except);}
				if($matched ne "matched") {
					if($delete eq "*") {
						alphaLibParser::removeMember($parent, $timing);
	   	 				}
						else {
						alphaLibParser::removeMember($timing,$delete);
						}
				}
				}
		}
			
		}
    }
    return $n;
}

sub CopyArc_func {
##Copy the group matching with -attr
 my $toks = shift;
    my $delete = shift;
    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    my $n = alphaLibParser::getName($libFile);
    if (@ARGV == 0) {push @ARGV, "*"}
	
    my $cellName;
    my @attrList;
    my @newList;
    my $parent;
    my $newmember;
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"newList=s@" => \@newList
	);
   my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);
   my @new_attrList   = parseAttrSpecList(\@newList, 2, 2);
   my @timingList = getTimingList($libFile, $cellName, \@ARGV, \@attrListParsed);

    $n = @timingList;
    my @newmembers;
    if ($n > 0) {
	foreach my $timing (@timingList) {
	    $parent = alphaLibParser::getParent($timing);
	    $newmember = alphaLibParser::copyObject($timing);
	    alphaLibParser::AddMember($parent,$newmember);
	    alphaLibParser::UpdateSimpleAttr($newmember,\@new_attrList);
    	    if($delete) {alphaLibParser::removeMember($parent, $timing);}
	push(@newmembers,$newmember);
	}
    }
return($n,$parent,\@newmembers);
}
sub CopyArc_flex_func {
##Copy the group matching with -attr
 my $toks = shift;
    my $delete = shift;
    @ARGV = @$toks;
    my $libFilesrc = shift @ARGV;
    my $libFile = shift @ARGV;
    my $n =0;
    if (@ARGV == 0) {push @ARGV, "*"}
    my @src_pin ;
    $src_pin[0]= $ARGV[0];
    my @dst_pin ;
    $dst_pin[0]= $ARGV[1];
	
    my $cellName;
    my @attrList;
    my @newList;
    my $parent;
    my $newmember;
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"newList=s@" => \@newList
	);
   my @cellList = alphaLibParser::getCellList($libFile);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 0);

	my @pinList = filterPinlist(\@rawPinList, \@dst_pin, 0);
	if($#pinList<0) {logMsg($LOG_WARNING, "pin $dst_pin[0] not found in cell $cellName\n");}
	foreach my $parent (@pinList) {


   my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);
   my @new_attrList   = parseAttrSpecList(\@newList, 2, 2);
   my @timingList = getTimingList($libFilesrc, undef, \@src_pin, \@attrListParsed);
   $n = @timingList;
    my @newmembers;
    if ($n > 0) {
	foreach my $timing (@timingList) {
	    $newmember = alphaLibParser::copyObject($timing);
	    alphaLibParser::AddMember($parent,$newmember);
	    alphaLibParser::UpdateRelatedPin_min_pulse_width($newmember,$dst_pin[0]);
	    alphaLibParser::UpdateSimpleAttr($newmember,\@new_attrList);
    	    if($delete) {alphaLibParser::removeMember($parent, $timing);}
	push(@newmembers,$newmember);
	}
    }
}
}


return($n,$parent);
}


sub renameArc_related_pin_func {
    my $toks = shift;
    my @command = @$toks;
    splice(@command,1,2,"-attr","related_pin=$command[1]","-new","related_pin=$command[2]");
    my ($n,$parent1,$newmember1) = CopyArc_func(\@command, 1); 
    if ($n < 0) {
	logMsg($LOG_WARNING, "No arcs found for r/deleteArc @$toks\n");
    }
}

sub combineArc_related_pin_func {
    my $toks = shift;
    my @command = @$toks;
    if ($command[3] =~ /hold|setup|rising|falling/i && $command[5] =~ /hold|setup|rising|falling/i && ($command[3] ne $command[7]) && ($command[5] ne $command[7])) {
		my $temp1 = $command[3];
		my $temp2 = $command[4];
		$command[3] = $command[5];
		$command[5] = $temp1;
		$command[4] = $command[6];
		$command[6] = $temp2;
    }
    elsif ($command[3] =~ /hold|setup|rising|falling/i && $command[5] =~ /hold|setup|rising|falling/i && ($command[5] eq $command[7])) {
		my $temp1 = $command[3];
		my $temp2 = $command[4];
		$command[3] = $command[5];
		$command[5] = $temp1;
		$command[4] = $command[6];
		$command[6] = $temp2;
    }			
    my @command1 = ($command[0],$command[1],"-attr","related_pin=$command[2]","-attr","timing_type=$command[3]","-attr","timing_sense=$command[4]","-new","timing_type=$command[7]","-new","timing_sense=$command[8]");
    my $timingType1 = $command[3];
    my $newTimingType = $command[7];
    my @findNONE1 = grep{$command1[$_] =~ /NONE/i} 0..$#command1;
    my @indices;  
    foreach my $tc (@findNONE1) { push(@indices,$tc-1,$tc); }
    for (sort{$b <=> $a}@indices) { splice @command1,$_,0; }
    my ($n,$parent1,$newmember1) = CopyArc_func(\@command1,1);
     if ($n <= 0) {
	logMsg($LOG_WARNING, "No arcs found for combineArc @$toks: command[0],$command[1],related_pin=$command[2],timing_type=$command[3]\n");
    }
   
    my @command2 = ($command[0],$command[1],"-attr","related_pin=$command[2]","-attr","timing_type=$command[5]","-attr","timing_sense=$command[6]","-new","timing_type=$command[7]","-new","timing_sense=$command[8]");
    my $timingType2 = $command[5];
    my @findNONE2 = grep{$command2[$_] =~ /NONE/i} 0..$#command2;
    my @indices2;  
    foreach my $tc (@findNONE2) { push(@indices2,$tc-1,$tc); }
    for (sort{$b <=> $a}@indices2) { splice @command2,$_,0; }
    my ($n1,$parent2,$newmember2) = CopyArc_func(\@command2,1); 
    if ($n1 <= 0) {
	logMsg($LOG_WARNING, "No arcs found for r/deleteArc @$toks\n");
    }
    if($newTimingType eq $timingType1 || $newTimingType eq $timingType2 || ($timingType1 =~ /hold|setup|rising|falling/i && $timingType2 =~ /hold|setup|rising|falling/i )) {
	for(my $i = 0; $i<= $#{$newmember1}; $i++) {
		#for(my $j = 0; $j<= $#{$newmember2}; $j++) {
			#alphaLibParser::copyMember(@$newmember1[$i],@$newmember2[$j]); 
			alphaLibParser::removeMember($parent2, @$newmember2[$i]);
			#alphaLibParser::removeMember($parent2, @$newmember2[$i]);
			#}
	}
    }
    else {
	for(my $i = 0; $i<= $#{$newmember1}; $i++) {
		#for(my $j = 0; $j<= $#{$newmember2}; $j++) {
			alphaLibParser::copyMember(@$newmember1[$i],@$newmember2[$i]); 
			alphaLibParser::removeMember($parent2, @$newmember2[$i]);
			#alphaLibParser::removeMember($parent2, @$newmember2[$i]);
			#}
		}
   }
}

sub combineArc_related_pin_attrib_func {
    my $toks = shift;
      my $command = shift @$toks;
       @ARGV = @$toks;
    my $cellName;
    my $PinName;
    my @attr1List;
    my @attr2List;
    my @newList;
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"PinName=s" => \$PinName,
	"attr1List=s@" => \@attr1List,
	"attr2List=s@" => \@attr2List,
	"newList=s@" => \@newList
	);
    my @command1 = ($command, $PinName);
    foreach(@attr1List) {push(@command1,"-attr",$_);}
    foreach(@newList) {push(@command1,"-new",$_);}
    my @findNONE1 = grep{$command1[$_] =~ /NONE/i} 0..$#command1;
    my @indices;  
    foreach my $tc (@findNONE1) { push(@indices,$tc-1,$tc); }
    for (sort{$b <=> $a}@indices) { splice @command1,$_,2; }
    my ($n,$parent1,$newmember1) = CopyArc_func(\@command1,1); 
    if ($n <= 0) {
	logMsg($LOG_WARNING, "No arcs found for combineArc @$toks:@command1\n");
    }
    my @command2 = ($command, $PinName);
    foreach(@attr2List) {push(@command2,"-attr",$_);}
    foreach(@newList) {push(@command2,"-new",$_);}
    my @findNONE2 = grep{$command2[$_] =~ /NONE/i} 0..$#command2;
    my @indices2;  
    foreach my $tc (@findNONE2) { push(@indices2,$tc-1,$tc); }
    for (sort{$b <=> $a}@indices2) { splice @command2,$_,2; }
    my ($n1,$parent2,$newmember2) = CopyArc_func(\@command2,1); 
    if ($n1 <= 0) {
	logMsg($LOG_WARNING, "No arcs found for r/deleteArc @$toks:@command2\n");
    }
for(my $i = 0; $i<= $#{$newmember1}; $i++) {
	#for(my $j = 0; $j<= $#{$newmember2}; $j++) {
		alphaLibParser::copyMember(@$newmember1[$i],@$newmember2[$i]);
		alphaLibParser::removeMember($parent2, @$newmember2[$i]);
	#	}
	}
}
sub splitArc_related_pin_func {
    my $toks = shift;
   
    my @command = @$toks;
    my @command1 = ($command[0],$command[1],"-attr","related_pin=$command[2]","-attr","timing_type=$command[3]","-attr","timing_sense=$command[4]","-new","timing_type=$command[5]","-new","timing_sense=$command[6]");
    my @findNONE1 = grep{$command1[$_] =~ /NONE/i} 0..$#command1;
    my @indices;  
    foreach my $tc (@findNONE1) { push(@indices,$tc-1,$tc); }
    for (sort{$b <=> $a}@indices) { splice @command1,$_,1; }
    my ($n,$parent1,$newmember1) = CopyArc_func(\@command1,0); 
     if ($n <= 0) {
	logMsg($LOG_WARNING, "No arcs found for combineArc @$toks: command[0],$command[1],related_pin=$command[2],timing_type=$command[3]\n");
    }
   
    my @command2 = ($command[0],$command[1],"-attr","related_pin=$command[2]","-attr","timing_type=$command[3]","-attr","timing_sense=$command[4]","-new","timing_type=$command[7]","-new","timing_sense=$command[8]");
    my @findNONE2 = grep{$command2[$_] =~ /NONE/i} 0..$#command2;
    my @indices2;  
    foreach my $tc (@findNONE2) { push(@indices2,$tc-1,$tc); }
    for (sort{$b <=> $a}@indices2) { splice @command2,$_,1; }
    my ($n1,$parent2,$newmember2) = CopyArc_func(\@command2,1); 
    if ($n1 <= 0) {
	logMsg($LOG_WARNING, "No arcs found for r/deleteArc @$toks\n");
    }
for(my $i = 0; $i<= $#{$newmember1}; $i++) {
	alphaLibParser::removechildMember(@$newmember1[$i],"fall"); 
	alphaLibParser::removechildMember(@$newmember2[$i],"rise"); 
	}
}
sub copyLut_func {
    my $toks = shift;
    my @command = @$toks;
    @command = ($command[0],$command[1],"-attr","related_pin=$command[2]","-attr","timing_type=$command[3]","-attr","timing_sense=$command[4]");
    
    my ($n,$parent1,$newmember1) = CopyArc_func(\@command,1); 
     if ($n <= 0) {
	logMsg($LOG_WARNING, "No arcs found for combineArc @$toks: command[0],$command[1],related_pin=$command[2],timing_type=$command[3]\n");
    }
    
    my ($n1,$parent2,$newmember2) = CopyArc_func(\@command,1); 
    if ($n1 <= 0) {
	logMsg($LOG_WARNING, "No arcs found for r/deleteArc @$toks\n");
    }
##rename rise to fall ot fall to rise
for(my $i = 0; $i<= $#{$newmember1}; $i++) {
	unless (alphaLibParser::renameClsGRP(@$newmember2[$i],"fall","rise")) {alphaLibParser::renameClsGRP(@$newmember2[$i],"rise","fall");}
	alphaLibParser::copyMember(@$newmember1[$i],@$newmember2[$i]); 

#Commenetd out by Dikshant as it is removing whole arc from lib
#	alphaLibParser::removeMember($parent2, @$newmember2[$i]);
	}
}

sub mod_timing_type_sense_func {
    my $toks = shift;
   
    my @command = @$toks;
    
   my @command1 = ($command[0],$command[1],"-attr","related_pin=$command[2]");
   unless($command[3]=~/^none$/i){push(@command1,"-attr","timing_type=$command[3]");}
   unless($command[4]=~/^none$/i){push(@command1,"-attr","timing_sense=$command[4]");}
   unless($command[5]=~/^none$/i){push(@command1,"-new","timing_type=$command[5]");}
   unless($command[6]=~/^none$/i){push(@command1,"-new","timing_sense=$command[6]");}
    my ($n,$parent1,$newmember1) = CopyArc_func(\@command1,1); 
     if ($n <= 0) {
	logMsg($LOG_WARNING, "No arcs found for mod_timing_type_sense @command\n");
    }
   
}
sub CopyTiming_func {
    my $toks = shift;
   
    my @command = @$toks;
    $command[2] =~ tr/<>/[]/;
    my @command1 = ($command[0],$command[0]);
    if($command[1]=~ /(.*)=(.*)/) {push(@command1,$2,$1);}
    else {push(@command1,$command[1],$command[1]);}
    
    if($command[2]=~ /(.*)=(.*)/) {push(@command1,"-attr","related_pin=$2","-new","related_pin=$1");}
    else {push(@command1,"-attr","related_pin=$command[2]");}
    unless($command[3]=~ /^none$/i) { unless($command[3]=~ /(.*)=(.*)/) {logMsg($LOG_WARNING, "copy_timing @$toks:Syntax issue with timing_type\n"); return;} push(@command1,"-attr","timing_type=$2","-new","timing_type=$1");}
    unless($command[4]=~ /^none$/i) { unless($command[4]=~ /(.*)=(.*)/) {logMsg($LOG_WARNING, "copy_timing @$toks:Syntax issue with timing_sense\n"); return;} push(@command1,"-attr","timing_sense=$2","-new","timing_sense=$1");}
    my ($n1,$parent) = CopyArc_flex_func(\@command1,0); 
    if ($n1 <= 0) {
	logMsg($LOG_WARNING, "No arcs found for copy_timing @$toks\n");
    }
}
sub CopyTiming_flex_func {
    my $toks = shift;
    unshift(@$toks,@$toks[0]);
    my ($n1,$parent) = CopyArc_flex_func($toks,0); 
    if ($n1 <= 0) {
	logMsg($LOG_WARNING, "No arcs found for copy_timing_Arc @$toks\n");
    } 
}

sub CopyTiming_1lib2other_func {
    my $toks = shift;
#    unshift(@$toks,@$toks[0]);
    unless(defined $RefLib) {shift(@$toks);logMsg($LOG_ERROR, "Mandatory Argument -RefLib not defined. It is mandatory to use \"-RefLib\" with copy_timing_Arc_fromRefLib @$toks\n");return;}
    unshift(@$toks,$RefLib);
    my ($n1,$parent) = CopyArc_flex_func($toks,0); 
    if ($n1 <= 0) {
	logMsg($LOG_WARNING, "No arcs found for copy_timing_Arc @$toks\n");
    }
}
sub  DeleteCCSN_func{
    my $toks = shift;
    my @command = @$toks;
    push (@command ,"-ComplexAttrib", "receiver_capacitance");
    my $n = delete_Complex_func(\@command); 
    $command[-1]= "ccsn_first_stage";
    my $n1 = delete_Complex_func(\@command); 
    $command[-1]= "ccsn_last_stage";
    my $n2 = delete_Complex_func(\@command); 
    if ($n <= 0 && $n1<=0 && $n2 <=0) {
	logMsg($LOG_WARNING, "No arcs found for del_arc_attr @$toks\n");
    }
}

sub CopyCCSN_1lib2other_func {
    my $toks = shift;
#    unshift(@$toks,@$toks[0]);
    unless(defined $RefLib) {shift(@$toks);logMsg($LOG_ERROR, "Mandatory Argument -RefLib not defined. It is mandatory to use \"-RefLib\" with copy_timing_Arc_fromRefLib @$toks\n");return;}
    unshift(@$toks,$RefLib);
    push (@$toks ,"-ComplexAttrib", "receiver_capacitance");
    my ($n1,$parent) = CopyComplex_func($toks,0); 

    pop(@$toks); push (@$toks , "ccsn_first_stage");
     ($n1,$parent) = CopyComplex_func($toks,0,); 

    pop(@$toks); push (@$toks , "ccsn_last_stage");
    ($n1,$parent) = CopyComplex_func($toks,0); 

    pop(@$toks); push (@$toks , "lu_table_template");
    ($n1,$parent) = CopyLibrary_func($toks,0); 
}

#Added by Dikshant To copy CCSN from one Pin to Another Pin in same Liberty File.
sub CopyCCSN_func {
    my $toks = shift;
	my $libFile = @$toks[0];
#    unshift(@$toks,@$toks[0]);
#    unless(defined $RefLib) {shift(@$toks);logMsg($LOG_ERROR, "Mandatory Argument -RefLib not defined. It is mandatory to use \"-RefLib\" with copy_timing_Arc_fromRefLib @$toks\n");return;}
    unshift(@$toks,$libFile);
    push (@$toks ,"-ComplexAttrib", "receiver_capacitance");
    my ($n1,$parent) = CopyComplex_func($toks,0); 

    pop(@$toks); push (@$toks , "ccsn_first_stage");
     ($n1,$parent) = CopyComplex_func($toks,0,); 

    pop(@$toks); push (@$toks , "ccsn_last_stage");
    ($n1,$parent) = CopyComplex_func($toks,0); 

    pop(@$toks); push (@$toks , "lu_table_template");
    ($n1,$parent) = CopyLibrary_func($toks,0); 
}



sub CopyLibrary_func {

 my $toks = shift;
    my $delete = shift;
    @ARGV = @$toks;
    my $libFilesrc = shift @ARGV;
    my $libFile = shift @ARGV;
    my @cellList = alphaLibParser::getCellList($libFile);
    my $libList = alphaLibParser::findAllGroups($libFile, "library");
    my $n = alphaLibParser::getName($libFile);
    my $cellName;
    my @attrList;
    my @newList;
    my $parent;
    my $newmember;
    my $ComplexAttrib_name;
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"newList=s@" => \@newList,
	"ComplexAttrib=s" => \$ComplexAttrib_name
	);
    
    my @src_pin ;
    $src_pin[0]= "ccsn*";
    my @dst_pin ;
   my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);
   my @new_attrList   = parseAttrSpecList(\@newList, 2, 2);
#    alphaLibParser::CopyLu_table($libFilesrc,$libFile,$ComplexAttrib_name, "ccs");
    alphaLibParser::CopyLu_table($libFilesrc,$libFile,$ComplexAttrib_name, "");
	
	
}

sub CopyComplex_func {
##Copy the group matching with -attr
 my $toks = shift;
    my $delete = shift;
    @ARGV = @$toks;
    my $libFilesrc = shift @ARGV;
    my $libFile = shift @ARGV;
    my $n = alphaLibParser::getName($libFile);
    my $cellName;
    my @attrList;
    my @newList;
    my $parent;
    my $newmember;
    my $ComplexAttrib_name;
    my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList,
	"newList=s@" => \@newList,
	"ComplexAttrib=s" => \$ComplexAttrib_name
	);
    if (@ARGV == 0) {push @ARGV, "*"}
    my @src_pin ;
    $src_pin[0]= $ARGV[0];
    my @dst_pin ;
    
    unless(defined $ARGV[1]) {$ARGV[1]=$src_pin[0];}
   $dst_pin[0]= $ARGV[1];
	
   my @cellList = alphaLibParser::getCellList($libFile);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 0);

	my @pinList = filterPinlist(\@rawPinList, \@dst_pin, 0);
	
	if($#pinList<0) {logMsg($LOG_WARNING, "pin $dst_pin[0] not found in cell $cellName\n");}


foreach my $parent (@pinList) {

if($ARGV[1] eq "*") { $dst_pin[0] = alphaLibParser::getName($parent); }
if($ARGV[0] eq "*") { $src_pin[0] = alphaLibParser::getName($parent); }

   my @attrListParsed = parseAttrSpecList(\@attrList, 2, 2);
   my @new_attrList   = parseAttrSpecList(\@newList, 2, 2);
   my @FuncList = getComplexattributeList($libFilesrc, undef, \@src_pin, \@attrListParsed, "$ComplexAttrib_name");
   $n = @FuncList;
    my @newmembers;
    if ($n > 0) {
	foreach my $arc (@FuncList) {
	    $newmember = alphaLibParser::copyObject($arc);
	    alphaLibParser::AddMember($parent,$newmember);
	    alphaLibParser::UpdateSimpleAttr($newmember,\@new_attrList);
    	    if($delete) {alphaLibParser::removeMember($parent, $arc);}
	push(@newmembers,$newmember);
	}
    }
}
}


return($n,$parent);
}


sub timingAttrMatch {
    ## Checks a timing group simple attributes against a set of defined attributes, passed in hash form.
    ##  Seems klunky.  Wish there was a better way.
    my ($timing, $attrHash) = @_;

    my %scb;  ## Scoreboard hash
    foreach my $an (keys %$attrHash) {$scb{$an} = 0}
    my @timingAttr = alphaLibParser::getSimpleAttrList($timing);
    foreach my $tAttr (@timingAttr) {
	my $n = alphaLibParser::getName($tAttr);
	my $v = alphaLibParser::getValue($tAttr);
	if (defined $attrHash->{$n}) {
	    if ($attrHash->{$n} eq $v) {$scb{$n} = 1}
	}
    }
    my $match = 1;
    foreach my $an (keys %$attrHash) {$match &= $scb{$an}}    ##  Check the scoreboard
    return $match;
}

sub attrList2Hash {
    ##  Takes a attribute list (just simple list of name/value pairs) and returns a hash
    my $attrList = shift;

    my %attrHash;
    foreach my $attr (@$attrList) {$attrHash{$attr->[0]} = $attr->[1]}
    return %attrHash;
}


sub myMin {
    my ($a, $b) = @_;
    if (!(defined $a)) {return $b}
    if (!(defined $b)) {return $a}
    if ($a < $b) {return $a} else {return $b}
}

sub myMax {
    my ($a, $b) = @_;
    if (!(defined $a)) {return $b}
    if (!(defined $b)) {return $a}
    if ($a > $b) {return $a} else {return $b}
}

sub delPinAttr_func {
    ##  Deletes an attribute for a pin group.
    
    my $toks = shift;
    @ARGV = @$toks;
    my $libFile = shift @ARGV;
    if (@ARGV == 0) {push @ARGV, "*"}
    my $cellName;
    my @attrList;
     my $result = GetOptions(
	"cellName=s" => \$cellName,
	"attrList=s@" => \@attrList
	);


    my $args = parseArgsSimple(0, $toks);   ##  Parse args, but no value expected for options.
    
    my @pinList = alphaLibParser::getPinList($libFile);
    foreach my $pinName (@ARGV) {
	my $pin = findPinInList($pinName, \@pinList);
	if (defined $pin) {
	    foreach my $attrName (@attrList) {
		unless(alphaLibParser::delSimpleAttr($pin, $attrName)) {
			unless(alphaLibParser::delComplexAttr($pin, $attrName)) {print "$attrName not deleted\n";}
			}
		}
	    
	}
	else {
	    logMsg($LOG_ERROR, "Cannot find pin \"$pinName\" in delPinAttr\n");
	}
    }
}

#New feature to rename bus and its pin. 
sub RenameBus_func {
    ##  Synopsis:
    ##    deletePin pin1 [pin2] [pin3] ...
    my $toks = shift;
    my $toks_ori = $toks;
push(@$toks,"*");
renameArc_related_pin_func($toks);
    my $libFile = shift @$toks;
    
    if (@$toks == 0) {
	logMsg($LOG_WARNING, "No pins specified in deletePin\n");
	return;
    }
    my @pin;
    my @command = @$toks;
    $pin[0] = shift @$toks;
    my @cellList = alphaLibParser::getCellList($libFile);
    foreach my $cell (@cellList) {
	my $cellName = alphaLibParser::getName($cell);
	my @rawPinList = alphaLibParser::getPinList($cell, 0);
	my @pinList = filterPinlist(\@rawPinList, \@pin, 1);
	if($#pinList<0) {logMsg($LOG_WARNING, "Renaming not find  pin $pin[0] in cell $cellName\n");}
	foreach my $pin (@pinList) {
	    my $pinName = alphaLibParser::getName($pin);
				$pinName =~ m/.+(<.+>)/;
				my $newPin = $command[1].$1;
				if (alphaLibParser::renameGroup($cell, "pin", $pinName, $newPin,1)) {
		logMsg($LOG_INFO, "Renaming pin $pinName from cell $cellName to $newPin from cell $cellName \n");
	    }
	    else {
		logMsg($LOG_WARNING, "Renaming not find  pin $pinName in cell $cellName\n");
	    }
    
	}
    }

}


sub findPinInList {
    my ($pinName, $pinList) = @_;
    my $pin;

    foreach my $pin (@$pinList) {
	my $p = alphaLibParser::getName($pin);
	if ($pinName eq alphaLibParser::getName($pin)) {return $pin}
    }
    return(undef);
}

sub parseArgsSimple {
    ##  Local argument parser.
    my  $hasVal = shift;
    my $toks = shift;
    
    my $argHash = {};
    $argHash->{ARGLIST} = [];   ##  Contains the simple arguments
    $argHash->{OPTIONS} = {};   ##  Contains the command options in hach form.

    my $i;
    my $l = @$toks;
    my $t;
    my $c;
    my $v;
    for ($i=0; ($i<$l); $i++) {
	$t = $toks->[$i];
	$c = substr($t, 0, 1);  ##  First character
	if ($c eq "-") {
	    ##  An option.
	    $t = substr($t, 1);  ## Strip "-"
	    if ($hasVal) {
		$v = $toks->[++$i];   ##  get value
	    }
	    else {
		$v = 1;  ##  No value expected.  
	    }
	    if (defined $v) {
		$argHash->{OPTIONS}->{$t} = $v;
	    }
	    else {
		logMsg($LOG_ERROR, "Missing value for arg \"$t\"\n");
	    }
	}
	else {
	    ##  A simple arg.
	    push @{$argHash->{ARGLIST}}, $t;
	}
    }
    return $argHash;
}


sub readConfigLine($) {
    my $fh = shift;
	#my @fh_array_ref = @$fh;
    
    my $bfr = "";
#    foreach my $line (@$fh) {
    while(my $line = <$fh>) {
	chomp $line; 
	$line =~ s/\#.*//;   ##  Uncomment
	my $last = substr($line, -1, 1);  ##  Last char, before newline. 
	if ($last eq "\\") {
	    ##   Line ends with backslash,  Trim left and append to bfr, and continue
	    substr($line, -1, 1, "");  ## Strip off trailing backslash
	    $bfr .= $line;
	}
	else {
	    ##  No continuation.  Trim both ends
	    $line =~ s/^\s+|\s+$//g;
	    $bfr .= $line;
	    if ($bfr eq "") {next}
		$bfr =~ s/\"//g;
		#print "*** $bfr\n";
		return $bfr;
	}
    }
    return(undef);
}

##  Borrowed this glob_to_regexp stuff from cpan, Text::Glob
sub glob_to_regex {
    my $glob = shift;
    my $regex = glob_to_regex_string($glob);
    return qr/^$regex$/;
}

sub glob_to_regex_string
{
    my $glob = shift;

    ##  
    my $strict_leading_dot = 0;
    my $strict_wildcard_slash = 0;


    if ($glob eq "") {return ""}  ##  Preserve empty string
    my ($regex, $in_curlies, $escaping);
    local $_;
    my $first_byte = 1;
     for ($glob =~ m/(.)/gs) {
        if ($first_byte) {
            if ($strict_leading_dot) {
                $regex .= '(?=[^\.])' unless $_ eq '.';
            }
            $first_byte = 0;
        }
        if ($_ eq '/') {
            $first_byte = 1;
        }
        if ($_ eq '.' || $_ eq '(' || $_ eq ')' || $_ eq '|' ||
            $_ eq '+' || $_ eq '^' || $_ eq '$' || $_ eq '@' || $_ eq '%' ) {
            $regex .= "\\$_";
        }
        elsif ($_ eq '*') {
            $regex .= $escaping ? "\\*" :
		$strict_wildcard_slash ? "[^/]*" : ".*";
        }
        elsif ($_ eq '?') {
            $regex .= $escaping ? "\\?" :
		$strict_wildcard_slash ? "[^/]" : ".";
        }
        elsif ($_ eq '{') {
            $regex .= $escaping ? "\\{" : "(";
            ++$in_curlies unless $escaping;
        }
        elsif ($_ eq '}' && $in_curlies) {
            $regex .= $escaping ? "}" : ")";
            --$in_curlies unless $escaping;
        }
        elsif ($_ eq ',' && $in_curlies) {
            $regex .= $escaping ? "," : "|";
        }
        elsif ($_ eq "\\") {
            if ($escaping) {
                $regex .= "\\\\";
                $escaping = 0;
            }
            else {
                $escaping = 1;
            }
            next;
        }
        else {
            $regex .= $_;
            $escaping = 0;
        }
        $escaping = 0;
    }
#    print "# $glob $regex\n" if debug;

    $regex = "^$regex\$";   ##  Need to match entire string
    return $regex;
}

sub match_glob {
#    print "# ", join(', ', map { "'$_'" } @_), "\n" if debug;
    my $glob = shift;
    my $regex = glob_to_regex $glob;
    local $_;
    grep { $_ =~ $regex } @_;
}

sub filterPinlist {
    ##  Filters a pin list by name, based on 
    my ($pinList, $globList, $useRootname) = @_;

    if (!$globList) {return @$pinList}
    my @pattList;
    foreach my $glob (@$globList) {push @pattList, glob_to_regex_string($glob)}
    my @filteredList;
    foreach my $pin (@$pinList) { 
	my $name = ($useRootname) ? alphaLibParser::getRootname($pin) : alphaLibParser::getName($pin);
	foreach my $patt (@pattList) {
	$patt =~ tr/[]/<>/;
	    if ($name =~ m/$patt/) {
		push @filteredList, $pin;
		last;  ##  Skip the rest of the patterns
	    }
	}
    }
    return @filteredList;
}


__END__

=head1 NAME

 alphalibEdit.pl

  
=head1 SYNOPSIS

 ScriptPath/alphaLibEdit.pl -config <config-file> <library> -outdir <output-dir> [-help]

=item B<This program> is designed to edit/delete/add pins/cells/arcs and more on library

=head1 OPTIONS

over 4

=item B<-Config>  Specifies ths Config file path. It is Mandatory argument.

=item B<-lc>	  Change all Pin names to lowercase.

=item B<-sb> 	  Change all angle brackets <> to square brackets [].

=item B<-h[elp]>  Prints this usage info

=item B<-outdir>  Specifies ths directories to write the reordered libs to. 

=cut
