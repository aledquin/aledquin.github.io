#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     qw( abs_path getcwd );
use Carp    qw( cluck confess croak );
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
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version(); # Syntax: YYYYww##[.#] optional day 1-7
                                # The work week number can be found in
                                # your outlook calendar. The days are 1=sunday
                                # 2=monday ... 7=saturday
#--------------------------------------------------------------------#

use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);


our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
BEGIN { our $AUTHOR='Multiple Authors'; header(); } 
END {
   write_stdout_log("${LOGFILENAME}");
   footer(); 
   utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);
}



use Getopt::Long;
#use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage;
use Data::Dumper;
#use File::Slurp;
our $LOG_INFO = 0;
our $LOG_WARNING = 1;
our $LOG_ERROR = 2;
our $LOG_FATAL = 3;
our $LOG_RAW = 4;
our $VARTYPE_NUMERIC = 0;
our $VARTYPE_STRING = 1;

my ($DomainVoltage, @Grounds, @Powers, $PowerVoltage, $strict_leading_dot, $strict_wildcard_slash, @toks, $dataCommands, @DeferredCommands, $domainV, $ignoreAggressor, $minDomainName, $minMosgroupFanoutDomain, @mosDevices, $nodeClasses, %nodeData, $noiseVars, %pininfo, @resDevices, $result, $RPT, $TheDefaultClass, $TheStaticClass,@mosGroups, $deviceTables, $fid, $fileDone, $gunzFile, $i, $line, $linebuf, $LOG, $mosdata, $nNum,  $t1, $t2, %uncharDeviceWarning, $value);

#my $x = calcNoise(1, 2000, 1e-14, 2e-15, 1e-12);
#print "$x\n";
#exit;

&Main();

sub Main {

my $ScriptPath = "";
foreach (@toks) {$ScriptPath .= "$_/"}
$ScriptPath = abs_path($ScriptPath);

if (!@ARGV) {
    print_usage($ScriptPath);
    exit;
}

$strict_leading_dot = 0;
$strict_wildcard_slash = 0;

##  Master list of power/ground nodes.  Preloaded with defaults.  These are interpreted as regular expressions.
@Powers = qw( VDD );
$DomainVoltage = {
    "VDD" => 1.0
};
@Grounds = qw( VSS 0 );
$PowerVoltage = {
    'VDD' => 1
    };



##  noiseVars can be changed using the "set" command.
$noiseVars = {
    'defaultGup' => {
	'TYPE' => $VARTYPE_NUMERIC,
	'VALUE' => 0,
    },
    'defaultGdown' => {
	'TYPE' => $VARTYPE_NUMERIC,
	'VALUE' => 0,
    },
    'defaultAggTrise' => {
	'TYPE' => $VARTYPE_NUMERIC,
	'VALUE' => 5e-12,
    },
    'defaultAggTfall' => {
	'TYPE' => $VARTYPE_NUMERIC,
	'VALUE' => 5e-12,
    },
    'capIgnoreThresh' => {
	'TYPE' => $VARTYPE_NUMERIC,
	'VALUE' => 1e-20,
    },
    'infiniteR' => {
	'TYPE' => $VARTYPE_NUMERIC,
	'VALUE' => 1e6,
    },
    'defaultDomain' => {
	'TYPE' => $VARTYPE_STRING,
	'VALUE' => "VDD",
    },
    'macro' => {
	'TYPE' => $VARTYPE_STRING,
	'VALUE' => undef,
    },
};


##  Class names should be lowercase.
my $nodeClasses;

my $dataFile;
my $logFile = "./alphaNoise.log";
my $help;
$result = GetOptions(
    "config=s" => \$dataFile,
    "help" => \$help,
    "logFile=s" => \$logFile
    );

if ($help) {
    print_usage($ScriptPath);
    exit;
}    

# open(my $LOG, ">", "$logFile") || die "Error: Cannot open log file $logFile\n";

my $ArgOK = 1;
#$ArgOK &= CheckRequiredArg($spf_file, "spf_file");
#$ArgOK &= CheckRequiredArg($techFile, "techFile");
if (!$ArgOK) {
	fatal_error ("Aborting on missing required arg(s)\n");
    # logMsg(LOG_FATAL, "Aborting on missing required arg(s)\n");
    # exitApp();
}

my $fileOK = 1;
#$fileOK &= CheckFileRead($spf_file);
#$fileOK &= CheckFileRead($techFile);
if (!$fileOK) {
	fatal_error ("Aborting on missing required file(s)\n");
    # logMsg(LOG_FATAL, "Aborting on missing required file(s)\n");
    # exitApp();
}

$ignoreAggressor = {};

#require $techFile;

my %Supplies;

@mosDevices = ();
@resDevices = ();
@DeferredCommands = ();
@mosGroups = ();

$dataCommands = {
    'print' => {
	'FUNCTION' => \&print_func,
	'LEVEL' => 0,
    },
    'source' => {
	'FUNCTION' => \&source_func,
	'LEVEL' => 0,
    },
    'read_tech' => {
	'FUNCTION' => \&read_tech_func,
	'LEVEL' => 0,
    },
    'read_pininfo' => {
	'FUNCTION' => \&read_pininfo_func,
	'LEVEL' => 0,
    },
    'ignore_aggressor' => {
	'FUNCTION' => \&ignore_aggressor_func,
	'LIST' => [],
	'LEVEL' => 0,
    },
    'set' => {
	'FUNCTION' => \&set_func,
	'LEVEL' => 0,
    },
    'set_powers' => {
	'FUNCTION' => \&set_powers_func,
	'LEVEL' => 0,
    },
    'set_grounds' => {
	'FUNCTION' => \&set_grounds_func,
	'LEVEL' => 0,
    },
    'set_node' => {
	'FUNCTION' => \&set_node_func,
	'LEVEL' => 2,
    },
    'set_fanout' => {
	'FUNCTION' => \&set_fanout_func,
	'LEVEL' => 2,
    },
    'set_domain_voltage' => {
	'FUNCTION' => \&set_domain_voltage_func,
	'LEVEL' => 0,
    },
    'define_class' => {
	'FUNCTION' => \&define_class_func,
	'LEVEL' => 0,
    },
    'define_limit' => {
	'FUNCTION' => \&define_limit_func,
	'LEVEL' => 0,
    },
    'dump_class' => {
	'FUNCTION' => \&dump_class_func,
	'LEVEL' => 0,
    },
    'exit' => {
	'FUNCTION' => \&exit_func,
	'LEVEL' => 0,
    },
    'list' => {
	'FUNCTION' => \&list_func,
	'LEVEL' => 3,
    },
    'gen_noise_model' => {
	'FUNCTION' => \&gen_noise_model_func,
	'LEVEL' => 3,
    },
    'report_coupling' => {
	'FUNCTION' => \&report_coupling_func,
	'LEVEL' => 3,
    },
    'set_virtualPower' => {
	'FUNCTION' => \&set_virtualPower_func,
	'LEVEL' => 1,
    },
    'set_virtualGround' => {
	'FUNCTION' => \&set_virtualGround_func,
	'LEVEL' => 1,
    },
    'read_netlist' => {
	'FUNCTION' => \&read_netlist_func,
	'LEVEL' => 0,
    }
};

#print "Powers = {@Powers}\n";
#print "Grounds = {@Grounds}\n";

if (defined $dataFile) {processDataFile($dataFile)}
#logMsg(LOG_INFO, "Reading $spf_file\n");
##  Process the dataFile
##ProcessFile($spf_file);   Now done as part of level 0 commands
##  Merge parallel devices
processDeferredCommands(1);
mergeMos();
##  Build mosgroups:  Sets of channel-connected devices. Also detects static cmos structures.
buildMosgroups();
##  Clean up any nodes not connected to a device.
cleanupDangles();
##  Determine the voltage domains of all nodes with paths to power/ground
traceDomains();
#dumpNodes();
##  Process commands deferred until the setlist read, and ancillary processing.
processDeferredCommands(2);
##  Take a pass through all the nodes and clean up classifications.
finalNodeClass();
#dumpNodes();
##  Generate all the fanouts
genFanouts();
##  Determine highest domain for each node, used for aggressor swing.
setAggVoltage();
##  Generate the complete ignore-aggressor hash
genAggressorIgnoreHash();
##  Goes through the ccouple list for all nodes, compresses duplicates and sorts according to cap
fixupCaps();
##  Check nodes for presence of all params necessary for coupling analysis.
checkNodeCompleteness();
##  Calculate actual noise for all nodes
calcNoise();

##  Process commands deferred until the setlist read, and ancillary processing.
processDeferredCommands(3);;

##  Dump the final results.  (temporary. Replace with command-driven reports).
#DumpNodes();

iprint ("Run complete. See $logFile for details\n");

}
sub cleanupDangles {
    foreach my $nodeName (keys %nodeData) {

	my $n = $nodeData{$nodeName};
	if (!$n->{DEVCONNECT}) {
	    ##  Remove any nodes that don't connect to any active devices.
	    delete $nodeData{$nodeName};
	    next;
	}
	my $g = $n->{GATEFANOUT};
	my $m = $n->{MOSGROUP};
	my $p = $n->{ISPIN};
#	print "!!!  $nodeName:  \"$g\" \"$m\" \"$p\"\n";
	if (!$n->{MOSGROUP} && !$n->{ISPIN} && !$n->{VIRTUALPOWER}  && !$n->{VIRTUALGROUND} ) {
	    ##  Scrub dangling gate nodes. 
	    ##  These are typically pode gates that will usually appear in the netlist as tied to a rail through a large resistor (ignored)
	    ##  This is for improved simulation performance, but can be ignored here
	    iprint ("Apparent dangling node $n->{NAME}\n");
		# logMsg(LOG_INFO, "Apparent dangling node $n->{NAME}\n");
	    delete $nodeData{$nodeName};
	}
    }
}

sub validateDomain {
    my $domain = shift;
    return (defined $DomainVoltage->{$domain})
}

sub print_func {
    my $toks = shift;

    print "@$toks\n";
}    

sub source_func {
    my $toks = shift;

    if (@$toks > 0) {
	foreach my $df (@$toks) {
	    processDataFile($df)
	}
    }
    else {
	wprint ("No files specified in \"source\" command\n");
	# logMsg(LOG_WARNING, "No files specified in \"source\" command\n");
    }
}    

sub define_class_func {
    my $toks = shift;

    @ARGV = @$toks;
    my $static;
    my $default;  ##  Default class for mosgroups not determined to be fully static
    $result = GetOptions(
	"static!" => \$static,
	"default" => \$default
	);
    
    foreach my $className (@ARGV) {
	$nodeClasses->{$className} = {};
	$nodeClasses->{$className}->{DEFAULT} = $default;
	$nodeClasses->{$className}->{STATIC} = $static;
	$nodeClasses->{$className}->{LIMITS} = {};
	if ($default) {
	    if ($static) {
		##  Calling out default static class
		if (defined $TheStaticClass) {
			eprint ("More than one class defined as default \"static\"\n");
		# logMsg(LOG_ERROR, "More than one class defined as default \"static\"\n");
		} else {
		    $TheStaticClass = $className;
		}
	    }
	    else {
		##  Calling out default non-static class
		if (defined $TheDefaultClass) {
			eprint ("More than one class defined as default \"non-static\"\n");
		# logMsg(LOG_ERROR, "More than one class defined as default \"non-static\"\n");
		} else {
		    $TheDefaultClass = $className;
		}
	    }
	}
    }  ## class loop
}
	 
sub dump_class_func {
    print Dumper($nodeClasses);
}

sub report_coupling_func {
    my $toks = shift;

    @ARGV = @$toks;
    my $brief = 1;   ##  brief/detailed flag
    my $internal = 0;  ## Include internal class nodes.
    my $out;
    $result = GetOptions(
	"brief!" => \$brief,
	"internal!" => \$internal,
	"out=s" => \$out
	);
    
    if (!$out) {
	my $macro = $noiseVars->{macro}->{VALUE};
	if (!$macro) {$out = "coupling.report"}
	else {$out = "${macro}_coupling.report"}
    }

    # if (!open(my $RPT, ">","$out")) {
	# logMsg(LOG_ERROR, "Cannot open $out for write\n");
	# return;
    # }
    
    my @failNodeList;
    foreach my $nodeName (keys %nodeData) {
	my $rec = $nodeData{$nodeName};
	if ($rec->{SKIPCOUPLING}) {next}
	if ($rec->{SLACK} < 0) {push @failNodeList, $rec}
    }

	my @RPT;
	push @RPT, "Coupling report:\n";
    # print $RPT "Coupling report:\n";
    my @failNodeListSorted = sort {$a->{SLACK} <=> $b->{SLACK}} @failNodeList;
	if (!$brief) {push @RPT, "------------------------------------------------------------------------------------------------------------------------------------\n"}
    # if (!$brief) {print $RPT "------------------------------------------------------------------------------------------------------------------------------------\n"}
    foreach my $n (@failNodeListSorted) {
	if (!$internal && ($n->{CLASS} eq "internal")) {next}
	my $classDomain = "$n->{CLASS}(@{$n->{DOMAIN}})";
	my $fanoutClassDomain = "$n->{FANOUT}->{CLASS}($n->{FANOUT}->{DOMAIN})";
	my $noiseLHpct = ($n->{VICVOLTAGE} != 0) ? 100*$n->{NOISELH}/$n->{VICVOLTAGE} : 0;
	my $noiseHLpct = ($n->{VICVOLTAGE} != 0) ? 100*$n->{NOISEHL}/$n->{VICVOLTAGE} : 0;
	##  The one-liner
	my $clkTag = ($n->{ISCLK}) ? "(clk)" : "(sig)";
	printf $RPT "%-50s $clkTag %20s->%-20s %.1f%%/%.1f%%  limit=%.0f%\n",$n->{NAME}, $classDomain, $fanoutClassDomain, $noiseLHpct, $noiseHLpct, $n->{FANOUT}->{LIMITPCT};
	if (!$brief) {
	    dumpNodeCouplingDetails($n, *$RPT);
	    push @RPT, "------------------------------------------------------------------------------------------------------------------------------------\n";
		# print $RPT "------------------------------------------------------------------------------------------------------------------------------------\n";
	}	    
    }
	write_file (\@RPT, $out);
    # close $RPT;
}

sub gen_noise_model_func {
    my $toks = shift;

    @ARGV = @$toks;
    my $out;
    $result = GetOptions(
	"out=s" => \$out
	);

    if (!$noiseVars->{macro}->{VALUE}) {
	##  Noise model requires name of macro to be defined.
	eprint ("Macro name undefined in gen_noise_model\n");
	# logMsg(LOG_ERROR, "Macro name undefined in gen_noise_model\n");
	return;
    }
    my $macro = $noiseVars->{macro}->{VALUE};

    if (!$out) {
	if (!$macro) {$out = "noiseModel.tcl"}
	else {$out = "${macro}_noiseModel.tcl"}
    }
	iprint ("Creating $out\n");
    # logMsg(LOG_INFO, "Creating $out\n");
    my @NOISE;
	# open (my $NOISE, ">","$out");
	push @NOISE, "##  Coupling model information for macro $macro\n";
    # print $NOISE "##  Coupling model information for macro $macro\n";
    foreach my $nodeName (keys %nodeData) {
	my $n = $nodeData{$nodeName};
	if ($n->{ISPIN} && !($n->{ISPOWER} || $n->{ISGROUND})) {
	    if (($n->{DIR} eq "input") || ($n->{DIR} eq "io"))
	    {
		##  input or io; generated an input noise limit
		push @NOISE, "\n## $nodeName $n->{DIR}, ($n->{CLASS}/@{$n->{DOMAIN}} --> $n->{FANOUT}->{CLASS}/$n->{FANOUT}->{DOMAIN}), $n->{FANOUT}->{DOMAIN}, $n->{FANOUT}->{LIMITPCT}%\n";
		# print $NOISE "\n## $nodeName $n->{DIR}, ($n->{CLASS}/@{$n->{DOMAIN}} --> $n->{FANOUT}->{CLASS}/$n->{FANOUT}->{DOMAIN}), $n->{FANOUT}->{DOMAIN}, $n->{FANOUT}->{LIMITPCT}%\n";
		push @NOISE, "set_max_noise -cell $macro -pin $nodeName $n->{FANOUT}->{LIMITPCT}\n";
		# print $NOISE "set_max_noise -cell $macro -pin $nodeName $n->{FANOUT}->{LIMITPCT}\n";
	    }
	    if (($n->{DIR} eq "output") || ($n->{DIR} eq "io"))
	    {
		##  output or io; generated an output resistance.
		my $r_high = ($n->{GdownCoup}) ? 1e-3/$n->{GdownCoup} : $noiseVars->{infiniteR}->{VALUE};
		my $r_low = ($n->{GupCoup}) ? 1e-3/$n->{GupCoup} : $noiseVars->{infiniteR}->{VALUE};
		my $class = $n->{CLASS};
		my $fanoutClass = $n->{FANOUT}->{CLASS};
		push @NOISE, "\n## $nodeName $n->{DIR}, $n->{CLASS}, r_high=${r_high}K, r_low=${r_low}K\n";
		push @NOISE, "set_steady_state_resistance -above -low $r_low $nodeName\n";
		push @NOISE, "set_steady_state_resistance -above -high $r_high $nodeName\n";
		push @NOISE, "set_steady_state_resistance -below -low $r_low $nodeName\n";
		push @NOISE, "set_steady_state_resistance -below -high $r_high $nodeName\n";
		# print $NOISE "\n## $nodeName $n->{DIR}, $n->{CLASS}, r_high=${r_high}K, r_low=${r_low}K\n";
		# print $NOISE "set_steady_state_resistance -above -low $r_low $nodeName\n";
		# print $NOISE "set_steady_state_resistance -above -high $r_high $nodeName\n";
		# print $NOISE "set_steady_state_resistance -below -low $r_low $nodeName\n";
		# print $NOISE "set_steady_state_resistance -below -high $r_high $nodeName\n";
	    }
	}
    }
	write_file(\@NOISE, $out);
	iprint ("$out created\n");
    # logMsg(LOG_INFO, "$out created\n");
}

sub list_func {
    ##  Common launch function for the "list" command.  keyword is determined and dispatched to the appropriate function.
    my $toks = shift;

    my $showHash = {
	'mosgroups' => {
	    'FUNCTION' => \&list_mosgroups_func
	},
	'nodes' => {
	    'FUNCTION' => \&list_nodes_func
	}
    };
#    $result = GetOptions(
#	"domain=s" => \$domain
#	);
    if (@$toks == 0) {
	eprint ("Missing keywork in list command\n");
	# logMsg(LOG_ERROR, "Missing keywork in list command\n");
	return
    }
    my $keyword = shift @$toks;
    my @keyList = keys %$showHash;
    my $keywordFull = bestMatch($keyword,\@keyList);
    if (!(defined $keywordFull)) {
		eprint ("Unrecognized keyword\"$keyword\" in list command\n");
	# logMsg(LOG_ERROR, "Unrecognized keyword\"$keyword\" in list command\n");
	return;
    }
    my $funcPtr = $showHash->{$keywordFull}->{FUNCTION};
    $funcPtr->($toks);
}

sub list_mosgroups_func {
    my $toks = shift;
	nprint ("Mosgroup Listing:\n");
    # logMsg(LOG_RAW, "Mosgroup Listing:\n");
    ##  Go through all mosgroups.
    my $i = 0;
    foreach my $m (@mosGroups) {
	if ($m->{DEFUNCT}) {next}
	nprint ("Mosgroup $i\n");
	# logMsg(LOG_RAW, "Mosgroup $i\n");
	nprint ("\tOutputs:\n");
	# logMsg(LOG_RAW, "\tOutputs:\n");
	foreach my $n (@{$m->{OUTPUTS}}) {
	    my @domains = @{$n->{DOMAIN}};
		nprint ("\t\t$n->{NAME}, class=$n->{CLASS}, domain={@domains}\n");
	    # logMsg(LOG_RAW, "\t\t$n->{NAME}, class=$n->{CLASS}, domain={@domains}\n")}
	nprint ("\tInputs:\n");
	# logMsg(LOG_RAW, "\tInputs:\n");
	foreach my $n (@{$m->{INPUTS}}) {nprint ("\t\t$n->{NAME}\n")};
	# foreach my $n (@{$m->{INPUTS}}) {logMsg(LOG_RAW,"\t\t$n->{NAME}\n")};
	nprint ("\tDevices:\n");
	# logMsg(LOG_RAW, "\tDevices:\n");
	foreach my $d (@{$m->{DEVS}}) {nprint ("\t\t$d->{INST}\n")};
	# foreach my $d (@{$m->{DEVS}}) {logMsg(LOG_RAW,"\t\t$d->{INST}\n")}
	$i++;
    }
}
}

sub list_nodes_func {
    my $toks = shift;

    @ARGV = @$toks;
    my $undefined;
    my $internal = 0;
    my $details = 0;
    $result = GetOptions(
	"undefined=s" => \$undefined,
	"details!" => \$details,
	"internal!" => \$internal
	);
    

    my @undefinedKeys = qw(class domain fanout);
    my $undefinedFull;
    if (defined $undefined) {
	$undefinedFull = bestMatch($undefined, \@undefinedKeys);
	if (!(defined $undefinedFull)) { 
		eprint ("Unrecognized keyword \"$undefined\" in list command\n");
	    # logMsg(LOG_ERROR, "Unrecognized keyword \"$undefined\" in list command\n");
	    return ;
	}
    }

    my @nodeList =  sort {$a cmp $b} keys %nodeData;
    nprint ("Node Listing, @$toks:\n");
	# logMsg(LOG_RAW, "Node Listing, @$toks:\n");
    foreach my $nodeName (@nodeList) {
	my $rec = $nodeData{$nodeName};
	if ($undefined) {
	    if (($undefinedFull eq "class") && ($rec->{CLASS})) {next}
	    if (($undefinedFull eq "domain") && (@{$rec->{DOMAIN}} > 0)) {next}
	    if (($undefinedFull eq "fanout") && ($rec->{FANOUT}->{CLASS}) && ($rec->{FANOUT}->{DOMAIN})) {next}
	    if (!$internal && ($rec->{CLASS} eq "internal")) {next}
	}
	my $detailString = "";
	my (@domain, $class, $fanoutClass, $fanoutDomain);
	if ($details) {
	    if ($rec->{ISPOWER} || $rec->{ISGROUND}) {
		if ($rec->{ISPOWER}) {
		    my $v = $DomainVoltage->{$nodeName};
		    $detailString = " POWER, Voltage=$v";
		}
		else {
		    $detailString = " GROUND";
		}
	    }
	    else {
		@domain = @{$rec->{DOMAIN}};
		if (@domain == 0) {push @domain, "Undefined"}
		$class = tagString($rec->{CLASS});
		$fanoutClass = tagString($rec->{FANOUT}->{CLASS});
		$fanoutDomain = tagString($rec->{FANOUT}->{DOMAIN});
		my $vp = ($rec->{VIRTUALPOWER}) ? ", VIRTUALPOWER" : "";
		my $vg = ($rec->{VIRTUALGROUND}) ? ", VIRTUALGROUND" : "";
		$detailString = "Class=$class, Domain=@domain, Fanout=$fanoutClass/$fanoutDomain$vp$vg"
	    }
	}
	my $pin = ($rec->{ISPIN}) ? "(PIN)" : "";
	nprint("\t$nodeName$pin:  $detailString\n");
	# logMsg(LOG_RAW, "\t$nodeName$pin:  $detailString\n");
    }
}

sub tagString {
    my $tag = shift;
    if (defined $tag) {return $tag} else {return "Undefined"}
}

sub nodeListSortedByName {


}

sub define_limit_func {
    ##  Define coupling limits for a given class/fanout
    ##  These should only be defined after all classes are defined.

    my $toks = shift;

    @ARGV = @$toks;
    my $fanoutClass;
    my $clkLimit;
    my $sigLimit;
    my $warn;   ##  Warn when this class/fanout combo occurs
    $result = GetOptions(
	"fanoutClass=s" => \$fanoutClass,
	"clkLimit=i" => \$clkLimit,
	"sigLimit=i" => \$sigLimit,
	"warn" => \$warn
	);
    
    my @fanoutList;
    if (defined $fanoutClass) {
	if (validateNodeClass($fanoutClass)) {push @fanoutList, $fanoutClass} else {@fanoutList = keys %{$nodeClasses}}
	foreach my $nodeClass (@ARGV) {
	    foreach my $fc (@fanoutList) {
		if (defined $clkLimit) {$nodeClasses->{$nodeClass}->{LIMITS}->{$fc}->{CLKLIMIT} = $clkLimit}
		if (defined $sigLimit) {$nodeClasses->{$nodeClass}->{LIMITS}->{$fc}->{SIGLIMIT} = $sigLimit}
		$nodeClasses->{$nodeClass}->{LIMITS}->{$fc}->{WARN} = $warn;
	    }
	}
    }
}	     
	 
sub exit_func {
    ## Immediate exit
    exitApp();
}

sub genFanouts {
    ##  Loop through all mosgroups.  Determine mosgroup class based on the class of each output.
    ##  Use this class to set the fanout on the mosgroup inputs.
    ##  Once done, loop through all mosgroups again, and reflect the output fanouts back to all mosgroup internals.

    foreach my $m (@mosGroups) {
	if ($m->{DEFUNCT}) {next}
	my %outClasses;
	##  Generate the mosgroup class
	$m->{HASOUTPUTS} = 0;
	foreach my $outputNode (@{$m->{OUTPUTS}}) {
	    $m->{HASOUTPUTS} = 1;
	    my $outputNodeName = $outputNode->{NAME};
	    my @outputNodeDomainList = @{$outputNode->{DOMAIN}};
	    my $outputNodeClass = $outputNode->{CLASS};
	    if (!(defined $outputNodeClass)) {
		##  Set default class for any nodes that slipped through.
		$outputNode->{CLASS} = $TheDefaultClass;
		$outputNodeClass = $outputNode->{CLASS};
	    }
#	    print "!!!  fanout for $outputNodeName, class=$outputNode->{CLASS}\n";
	    $outClasses{$outputNodeClass} = 1;
	    foreach my $outputNodeDomain (@outputNodeDomainList) {
#		print "\t$outputNodeDomain\n";
		my $outputNodeDomainVoltage = $DomainVoltage->{$outputNodeDomain};
		foreach my $inputNode (@{$m->{INPUTS}}) {
		    my $inputNodeClass = $inputNode->{CLASS};
		    my $inputNodeName = $inputNode->{NAME};
#		    print ">>> $inputNodeName from $outputNodeName($outputNodeDomain):  ";
		    my $limitPct = ($inputNode->{ISCLK}) ? 
			$nodeClasses->{$inputNodeClass}->{LIMITS}->{$outputNodeClass}->{CLKLIMIT} : 
			$nodeClasses->{$inputNodeClass}->{LIMITS}->{$outputNodeClass}->{SIGLIMIT};
		    my $limit = $limitPct * ($outputNodeDomainVoltage/100);  ##  Convert limit to fraction of output node domain.
#		    print "!!  $inputNodeClass --> $outputNodeClass = $limitPct  clk=$inputNode->{ISCLK}\n";
		    ## Track smallest limit/domain/class.
		    if (defined $inputNode->{FANOUT}->{LIMIT}) {
			if ($limit < $inputNode->{FANOUT}->{LIMIT}) {
			    $inputNode->{FANOUT}->{LIMIT} = $limit;
			    $inputNode->{FANOUT}->{LIMITPCT} = $limitPct;
			    $inputNode->{FANOUT}->{DOMAIN} = $outputNodeDomain;
			    $inputNode->{FANOUT}->{CLASS} = $outputNodeClass;
#			    print "!!!  Setting fanout of $inputNode->{NAME}: limit=$limitPct\n";
			    ##  $inputNode->{FANOUT}->{NODE} = $outputNodeName;   ## Not right.  Can fan out to multiple things.
			}
		    } else {
			$inputNode->{FANOUT}->{LIMIT} = $limit;
			$inputNode->{FANOUT}->{LIMITPCT} = $limitPct;
			$inputNode->{FANOUT}->{DOMAIN} = $outputNodeDomain;
			$inputNode->{FANOUT}->{CLASS} = $outputNodeClass;
#			print "!!!  Setting fanout of $inputNode->{NAME}: limit=$limitPct\n";
			##  $inputNode->{FANOUT}->{NODE} = $outputNode;
		    }
#		    print "$inputNode->{FANOUT}->{LIMIT}\n";
		}
	    }
	}
	##  Save aggregate list of output fanouts
	$m->{OUTCLASSES} = ();
	@{$m->{OUTCLASSES}} = keys %outClasses;
    }

    foreach my $m (@mosGroups) {
	if ($m->{DEFUNCT}) {next}
	my $minMosgroupLimit = 999;
	my $minMosgroupFanoutClass;
	my $minMosgroupLimitPct;
	my $minMosgroupLimitFanoutDomain;
	my $minMosgroupLimitFanoutClass;
	##  Determine lowest limit across all outputs.
	foreach my $outputNode (@{$m->{OUTPUTS}}) {
	    my $outputNodeClass = $outputNode->{CLASS};
	    my $limit = $outputNode->{FANOUT}->{LIMIT};
	    my $limitPct = $outputNode->{FANOUT}->{LIMITPCT};
	    my $domain = $outputNode->{FANOUT}->{DOMAIN};
	    if (!(defined $limit)) {
			wprint ("Using default fanout ($TheDefaultClass) for node $outputNode->{NAME}\n");
		# logMsg(LOG_WARNING, "Using default fanout ($TheDefaultClass) for node $outputNode->{NAME}\n");
		##  Fanout is undefined.  Define it as default.
		$limitPct = ($outputNode->{ISCLK}) ? 
		    $nodeClasses->{$outputNodeClass}->{LIMITS}->{$TheDefaultClass}->{CLKLIMIT} : 
		    $nodeClasses->{$outputNodeClass}->{LIMITS}->{$TheDefaultClass}->{SIGLIMIT};
		my @dh = @{$outputNode->{DOMAIN}};
		$minDomainName = minDomain(\@dh);  #Default to lowest domain.
		$domainV = $DomainVoltage->{$minDomainName};
		my $nnn = $outputNode->{NAME};
		$limit = $limitPct * ($domainV/100);  ##  Convert limit to fraction of output node domain.
#		print "\t!!!  $nnn  limit=$limit limitPct=$limitPct  {$minDomainName}  {$domainV}\n";
		$outputNode->{FANOUT}->{LIMIT} = $limit;
		$outputNode->{FANOUT}->{LIMITPCT} = $limitPct;
		$outputNode->{FANOUT}->{DOMAIN} = $minDomainName;  ##  In the absence of a defined fanout, defaults to domain of the output
		$outputNode->{FANOUT}->{CLASS} = $TheDefaultClass;
	    }
	    if ($outputNode->{FANOUT}->{LIMIT} < $minMosgroupLimit) {
		$minMosgroupLimit = $outputNode->{FANOUT}->{LIMIT};
		$minMosgroupFanoutClass = $outputNode->{FANOUT}->{CLASS};
		$minMosgroupLimitPct = $outputNode->{FANOUT}->{LIMITPCT};
		$minMosgroupFanoutDomain = $outputNode->{FANOUT}->{DOMAIN};
	    }
	}
	##  Apply min mosgroup output limit to mosgroup internals
	foreach my $n (@{$m->{NODES}}) {
	    if ($n->{CLASS} ne "internal") {next}
	    $n->{FANOUT}->{LIMIT} = $minMosgroupLimit;
	    $n->{FANOUT}->{LIMITPCT} = $minMosgroupLimitPct;
	    $n->{FANOUT}->{DOMAIN} = $minMosgroupFanoutDomain;
	    $n->{FANOUT}->{CLASS} = $minMosgroupFanoutClass;
	}
    }
}

sub finalNodeClass {
    ##  Take a pass through all the nodes and clean up classifications.
    
    my $nodeName;
    foreach my $nodeName (keys %nodeData) {

	##  Assign pin directions.
	my $n = $nodeData{$nodeName};
	##  Use pininfo data, if available.  Otherwise, infer direction from device connections.
	if ($n->{ISPIN}) {
	    my $pi;
	    if ($pi = $pininfo{$nodeName}) {
#		print "Info:  Pininfo found for $nodeName \\$pi->{DIR}\\, \\$pi->{RELATED_POWER}\\\n";
		$n->{DIR} = $pi->{DIR};
		$n->{DOMAIN} = ();
		$n->{DOMAIN}->[0] = $pi->{RELATED_POWER};
		$n->{AGGVOLTAGE} = $DomainVoltage->{$pi->{RELATED_POWER}};
	    } else {
		if (defined ($n->{MOSGROUP})) {
		    if ($n->{GATEFANOUT}) { $n->{DIR} = "io" }  ##  Has paths to power/ground, but also gates.  Not clear, but assume IO
		    else { $n->{DIR} = "output" } ##  Has paths to power/ground, but not gates.  Output
		}
		else {
		    ## No paths to power/ground.
		    if ($n->{GATEFANOUT}) { $n->{DIR} = "input" }   ##  Connects to gate(s).  Input
		    else { $n->{DIR} = "Unknown" }  ## No device connections at all.  
		}
	    }
	}
	
	##  Check for static class on nodes.  (Node may become static if assigned a pullup and pulldown R
	if (($n->{GupCoup}>0) && ($n->{GdownCoup}>0)) {
	    $n->{CLASS} = $TheStaticClass;
	}

	##  Last resort:  Undefined class/domain for node,  use default
	if (!(defined $n->{CLASS}) && !$n->{ISPOWER} && !$n->{ISGROUND}) {
	    $n->{CLASS} = $TheDefaultClass;
		wprint ("Using default class \"$TheDefaultClass\" for node $n->{NAME}\n");
	    # logMsg(LOG_WARNING, "Using default class \"$TheDefaultClass\" for node $n->{NAME}\n");
	}

	my @dl = @{$n->{DOMAIN}};
	if ((@dl == 0) && !$n->{ISPOWER} && !$n->{ISGROUND}) {
	    push @{$n->{DOMAIN}}, $noiseVars->{defaultDomain}->{VALUE};
		wprint ("Using default domain \"$noiseVars->{defaultDomain}->{VALUE}\" for node $n->{NAME}\n");
	    # logMsg(LOG_WARNING, "Using default domain \"$noiseVars->{defaultDomain}->{VALUE}\" for node $n->{NAME}\n");
	}

    }

}

sub buildMosgroups {

	iprint ("Extracting Mosgroups\n");
    # logMsg(LOG_INFO, "Extracting Mosgroups\n");
    my ($t1, $t2, $tg);
    my $ng;
    my $i=0;
    my @mosGroupsTemp = ();
    foreach my $dev (@mosDevices,@resDevices) {
#	print "Working on $dev->{INST}\n";

	if ($dev->{TYPE} eq "MOS") {
	    $t1=0; $t2=2;
	    $dev->{NODES}->[1]->{GATEFANOUT} = 1;   ##  Mark node as fanning out to gate.
	    $ng = $dev->{NODES}->[1];   ##  Gate connect
	    ##  Filter devices based on "DC" states of input.
	    if (defined $ng->{DC}) {
		if (($ng->{DC} == 0) && $dev->{MOSTYPE} eq "N") {next}  ##  Skip unconditionally off nfets
		if (($ng->{DC} == 1) && $dev->{MOSTYPE} eq "P") {next}  ##  Skip unconditionally off pfets
	    }
	}
	elsif ($dev->{TYPE} eq "RES") {
	    $t1=0; $t2=1; $ng=undef;
	}
	
	my $n1 = $dev->{NODES}->[$t1];
	my $n2 = $dev->{NODES}->[$t2];
#	print "###  $n1->{NAME}($n1->{VIRTUALPOWER}) : $n2->{NAME}($n2->{VIRTUALPOWER})\n";
#	if ($n1->{VIRTUALPOWER}) {print "!!! $n1->{NAME}\n"}
#	if ($n2->{VIRTUALPOWER}) {print "!!! $n2->{NAME}\n"}
	my $n1Rail = ($n1->{ISPOWER} || $n1->{ISGROUND} || $n1->{VIRTUALPOWER} || $n1->{VIRTUALGROUND});
	my $n2Rail = ($n2->{ISPOWER} || $n2->{ISGROUND} || $n2->{VIRTUALPOWER} || $n2->{VIRTUALGROUND});
	##  Ignore any no-op devices witih both S and D connected to rails.  Caps for these have already been counted, but just skip these in mosgroup analysis.
	if ($n1Rail && $n2Rail) {next}
	my $m1 = $n1->{MOSGROUP};
	my $m2 = $n2->{MOSGROUP};
	##  Check for mosgroups already associated with each S/D node of device.
	if ($m1 && !$m2) {
	    ##  n1 is in a mosgroup, n2 not.  Assign to n1
#	    print "m1 & !m2\n";
	    if (!$n2Rail) {
		$n2->{MOSGROUP} = $m1;
		push @{$m1->{NODES}}, $n2;
	    }
	    $dev->{MOSGROUP} = $m1;
	    if ($ng) {push @{$m1->{INPUTS}}, $ng}
	    push @{$m1->{DEVS}}, $dev;
	}
	elsif ($m2 && !$m1) {
	    ##  n2 is in a mosgroup, n1 not.  Assign to n2
#	    print "m2 & !m1\n";
	    if (!$n1Rail) {
		$n1->{MOSGROUP} = $m2;
		push @{$m2->{NODES}}, $n1;
	    }
	    $dev->{MOSGROUP} = $m2;
	    if ($ng) {push @{$m2->{INPUTS}}, $ng}
	    push @{$m2->{DEVS}}, $dev;
	}
	elsif (!$m2 && !$m1) {
	    ##  Neither is in a mosgroup.  Create new one.
	    ##  New mosgroup.
#	    print "!m1 & !m2\n";
	    my $m = {};
	    $m->{DEVS} = ();
	    $m->{NODES} = ();
	    $m->{INPUTS} = ();
	    if (!$n1Rail) {
		push @{$m->{NODES}}, $n1;
		$n1->{MOSGROUP} = $m;
	    }
	    if (!$n2Rail) {
		push @{$m->{NODES}}, $n2;
		$n2->{MOSGROUP} = $m;
	    }
	    push @{$m->{DEVS}}, $dev;
	    $dev->{MOSGROUP} = $m;
	    $m->{N} = $i++;
	    if ($ng) {push @{$m->{INPUTS}}, $ng}
	    push @mosGroupsTemp, $m;
	}
	else {
	    ##  Both mosgroups defined.  Merge under m1
#	    print "m1 & m2\n";
	    push @{$m1->{DEVS}}, $dev;
	    $dev->{MOSGROUP} = $m1;
	    if ($m1 == $m2) {
		##  Same mosgroup.  No need to do anything with nodes.
		next;
	    }
#	    print "Merging $m1->{N} and $m2->{N}, \"$m1->{DEFUNCT}\"\n";
	    foreach my $md (@{$m2->{DEVS}})  {push @{$m1->{DEVS}},$md; $md->{MOSGROUP}=$m1}
	    foreach my $mn (@{$m2->{NODES}}) {push @{$m1->{NODES}},$mn; $mn->{MOSGROUP}=$m1}
	    foreach my $mi (@{$m2->{INPUTS}}) {push @{$m1->{INPUTS}},$mi}
	    $m2->{DEVS} = ();
	    $m2->{NODES} = ();
#	    print "DEFUNCTing $m2->{N}\n";
	    $m2->{DEFUNCT} = 1;
	    $n2->{MOSGROUP} = $m1;
	    if ($ng) {push @{$m1->{INPUTS}}, $ng}
	    push @{$m1->{NODES}}, $n2;
	}
    }

    ##  Clean up any redundancies
    my $mNum = 0;
    foreach my $m (@mosGroupsTemp) {
	if ($m->{DEFUNCT}) {next}
	##  Note that {NODES}(?) and {INPUTS} may have redundant entries.  Use temp hashes to clean up.
	my %nodeHash;
	my %gateHash;
	my $cleanNodes = ();
	my $cleanGates = ();
	my $outputs = ();
	foreach my $n (@{$m->{NODES}}) {$nodeHash{$n->{NAME}} = 1}
	foreach my $nn (keys %nodeHash) {
	    push @$cleanNodes, $nodeData{$nn};
	    ##  If node connects to a gate or a pin, considered an output.
	    if ($nodeData{$nn}->{GATEFANOUT} || $nodeData{$nn}->{ISPIN}) {push @$outputs, $nodeData{$nn}}
	}
        $m->{NODES} = $cleanNodes;
        $m->{OUTPUTS} = $outputs;
	foreach my $n (@{$m->{INPUTS}}) {$gateHash{$n->{NAME}} = 1}
	foreach my $nn (keys %gateHash) {push @$cleanGates, $nodeData{$nn}}
        $m->{INPUTS} = $cleanGates;
	$m->{ID} = $nNum++;
	push @mosGroups, $m;
    }
    
#    DumpMosgroups();
    processMosgroups();
}


sub processMosgroups {
    my $i = 0;

    my @danglingMosgroups;
    foreach my $m (@mosGroups) {
	my @inputs;
	my @outputs;
	my @devs;
	my %inpNum;
	my $mosGroupClass = undef;
	if ($m->{DEFUNCT}) {next}

#	print "\tDevices:\n";
#	foreach my $dev (@{$m->{DEVS}}) {print "\t\t$dev->{INST}\n"}
	my $nInputs = @{$m->{INPUTS}};
	my $nOutputs = @{$m->{OUTPUTS}};
	if (($nOutputs==0)) {
#	    logMsg(LOG_INFO, "Found dangling mosgroup\n");
	    foreach my $n (@{$m->{NODES}}) {
		my $nn = $n->{NAME};
#		logMsg(LOG_INFO, "\tRemoving node $nn\n");
		delete $nodeData{$nn};
		$m->{DEFUNCT} = 1;
		next;
	    }
	}
#	print "Mosgroup $m->{ID}:  $nInputs inputs, $nOutputs outputs\n";
#	print "\tInputs ($nInputs):\n";
	my $iNum=0;
	foreach my $n (@{$m->{INPUTS}}) {
	    my $iName = $n->{NAME};
#	    print "\t\t$iName = input$iNum\n";
	    $inpNum{$iName} = $iNum++;   ## Hash to get quick input number lookup
	}
#	foreach $x (keys(%inpNum)) {print "### $x -->  $inpNum{$x}\n"}
#	print "\tOutputs ($nOutputs):\n";
#	foreach $n (@{$m->{OUTPUTS}}) {print "\t\t$n->{NAME}\n"};
#	print "\tDevices:\n";
#	foreach my $d (@{$m->{DEVS}}) {print "\t\t$d->{INST}\n"}

	##  In this next part, process the mosgroup to determine if it's a static, digital gate or similar.
	##  Loop through all possible inputs combos, determining if the output is always driven and what the effective R is.
	foreach my $n (@{$m->{NODES}}) {
	    ##  Init the datafields to be used in G reduction.  These to persist across all input states
	    $n->{Fight} = 0;           ##  Set if some case causes a fight condition
	    $n->{HiZ} = 0;             ##  Set if some case causes a hi-z condition
#	    $n->{GupMin} = undef;      ##  Minimum G to supply.  Might be 0
	    $n->{GupMinNZ} = undef;    ##  Minimum non-zero G to supply
	    $n->{GmaxUp} = undef;      ##  Max G to supply.
#	    $n->{GdownMin} = undef;    ##  Same as above for G's to ground
	    $n->{GdownMinNZ} = undef;
	    $n->{GdownMax} = undef;
	}
	if ($nInputs <= 11) {
	    ##  Setting arbitrary limit on the number of inputs that can be handled to analyze a mosgroup
	    my $max = 2**$nInputs;
	    my $i;
	    for ($i=0; ($i<$max); $i++) {
#		print "\t Input = $i\n";
		##  @is contains the bit map of input state.
		my (@is, $b);
		for ($b=0; ($b<$nInputs); $b++) {
		    $is[$b] = ($i >> $b) & 1;
		}
		##  Build lists of pullup devices (nmos+res) and pulldown devices (pmos+res)
		my @devListUp;
		my @devListDown;
		foreach my $dev (@{$m->{DEVS}}) {
		    if ($dev->{ISMOS}) {
			my $k = keys(%inpNum);
			my $iNum = $inpNum{$dev->{NODES}->[1]->{NAME}};
			if (($dev->{MOSTYPE} eq "N") && $is[$iNum]) { 
			    addG($dev, \@devListDown, "M") ;
			}
			if (($dev->{MOSTYPE} eq "P") && !$is[$iNum]) {
			    addG($dev, \@devListUp, "M");
			}
		    }
		    elsif ($dev->{ISRES}) {
			addG($dev, \@devListUp, "R");
			addG($dev, \@devListDown, "R");
		    }
		}

		foreach my $n (@{$m->{NODES}}) {
		    ##  Init the datafields to be used in G reduction.  These are specific to an input state.
		    $n->{GupInt} = 0;    ##  Calculated conductance to supply
		    $n->{GdownInt} = 0;  ##  Calculated conductance to ground
		}

		##  Now have lists of pullup and pulldown devices.
#		print "\t\tPullup devices\n";
#		dumpGs(\@devListUp);
#		print "\t\tPulldown devices\n";
#		dumpGs(\@devListDown);

		reduceGs(\@devListUp, 1);
		reduceGs(\@devListDown, 0);

		## Incremental G handling.
		foreach my $n (@{$m->{NODES}}) {
#		    $n->{GupMin} =     myMin($n->{GupMin}, $n->{GupInt});
		    $n->{GupMinNZ} =   myMinNZ($n->{GupMinNZ}, $n->{GupInt});
#		    $n->{GdownMin} =   myMin($n->{GdownMin}, $n->{GdownInt});
		    $n->{GdownMinNZ} = myMinNZ($n->{GdownMinNZ}, $n->{GdownInt});
		    $n->{GmaxUp} =     myMax($n->{GmaxUp}, $n->{GupInt});
		    $n->{GdownMax} =   myMax($n->{GdownMax}, $n->{GdownInt});
		    if (($n->{GupInt} > 0) && ($n->{GdownInt} > 0)) {$n->{Fight} = 1}  ##  Fight case detected
		    if (!$n->{GupInt} && !$n->{GdownInt}) {$n->{HiZ} = 1}    ##  Hi-Z
#		    print "+++ $n->{NAME}:  GupInt=$n->{GupInt}, $n->{GupMin}, GdownInt=$n->{GdownInt}, $n->{GdownMin}  \"$n->{HiZ}\"\n";
		}
	    }
	}  ##  End detailed mosgroup analysis
	else {
	    my @nl;
	    foreach my $on (@{$m->{OUTPUTS}}) {push(@nl, $on->{NAME})}
		wprint ("Mosgroup with outputs {@nl} has more than 11 inputs; cannot determine holding impedances\n");
	    # logMsg(LOG_WARNING, "Mosgroup with outputs {@nl} has more than 11 inputs; cannot determine holding impedances\n");
	}

	####  Final Node classification and final conductance assignment
	foreach my $n (@{$m->{NODES}}) {
	    if (!(defined $n->{GupMinNZ})) {$n->{GupMinNZ} = 0; $n->{GmaxUp} = 0; $n->{HiZ} = 1}
	    if (!(defined $n->{GdownMinNZ})) {$n->{GdownMinNZ} = 0; $n->{GdownMax} = 0; $n->{HiZ} = 1}

#	    print "Final classification of $n->{NAME}\n";
#	    print "\tGupMinNZ=$n->{GupMinNZ}), GmaxUp=$n->{GmaxUp}, GdownMinNZ$n->{GdownMinNZ}, GdownMax=$n->{GdownMax} Fight=$n->{Fight}, hiZ=$n->{HiZ}\n";

	    if (!$n->{HiZ} && !$n->{Fight}) {
		##  Node appears to be always driven.  Regardless of connectivity, classify as Static
		$n->{CLASS} = $TheStaticClass;
		##  Coupling G's default to min values.
		$n->{GupCoup} = $n->{GupMinNZ};
		$n->{GdownCoup} = $n->{GdownMinNZ};
#		print "\t$n->{NAME} Static, $n->{GupCoup}, $n->{GdownCoup}\n";
	    }
	    else {
		##  Not a static node, perhaps.
		if  ($n->{GATEFANOUT} || $n->{ISPIN}) {
		    ## This is a "real" output of some type.  Mark as dynamic/analog
		    $n->{CLASS} = $TheDefaultClass;
		    ##  Coupling G's default to 0 for dynamic
		    $n->{GupCoup} = 0;
		    $n->{GdownCoup} = 0;
#		    print "\tDynamic\n";
		}
		else {
		    ##  Not connected to a gate or pin, mark as mosgroup Internal.
		    ##  Consider option to ignore this type in coupling analysis.
		    $n->{CLASS} = "internal";
		    ## $mosGroupClass :  Mosgroup class not affected by classification of internal nodes.
		    ##  Coupling G's default to 0 for mosgroup internal.
		    $n->{GupCoup} = 0;
		    $n->{GdownCoup} = 0;
#		    print "\tInternal\n"
		}
	    }
	}
	
	if ($nOutputs == 0) {$m->{CLASS} = $TheStaticClass}   ##  Special case for mosgroups with no outputs.  Usually dummy devices.
	##  Mark all input fanouts according to the mosgroup class.
	##  Can't set fanouts yet; node class may be changed by command.
	$i++;
    }  ##  End mosgroup loop
}

sub myMin {
    ##  Slightly smarter min function.  If old is undefined, unconditionally returns new, else returns min of old vs. new
    my $old = shift;
    my $new = shift;

    if (defined $old) {return (($new<$old) ? $new : $old) } else {return $new}

}

sub myMinNZ {
    ##  Slightly smarter min function.  If old is undefined, unconditionally returns new, else returns min of old vs. new
    ##  This one is a little different in that it won't return new if it's zero. 
    ##  Intended to track the minimum non-zero G's
    my $old = shift;
    my $new = shift;

    if ($new == 0) {return $old}
    if (defined $old) { return (($new<$old) ? $new : $old) } else {return $new}

}

sub myMax {
    ##  Slightly smarter max function.  If old is undefined, unconditionally returns new, else returns max of old vs. new
    my $old = shift;
    my $new = shift;

    if (defined $old) { return (($new>$old) ? $new : $old) } else {return $new}

}

sub reduceGs {
    ##  Iterate through a pullup or pulldown network, returning
    my $gList = shift;
    my $dir = shift;   ## 1=up, 0=down

    my $update;
    my @gListTmp = @$gList;
    my @next;
    ## The following loop propagates resistance from the rails.  BOZO: This is not perfect; Some topologies will break it.  
    do {
	$update = 0;
	@next = ();
	foreach my $g (@gListTmp) {
	    if ($dir == 0) {
		if ($g->[0]->{ISGROUND} || $g->[0]->{VIRTUALGROUND}) {
		    $update = addNodeG($g->[1], $g->[2], 0, 0);   ## Add a parallel G to node
		}
		elsif ($g->[1]->{ISGROUND} || $g->[1]->{VIRTUALGROUND}) {
		    $update = addNodeG($g->[0], $g->[2], 0, 0);   ## Add a parallel G to node
		}
		elsif ($g->[0]->{GdownInt}) {
		    $update = addNodeG($g->[1], $g->[2], 0, $g->[0]->{GdownInt});   ## Add a incremental G
		}
		elsif ($g->[1]->{GdownInt}) {
		    $update = addNodeG($g->[0], $g->[2], 0, $g->[1]->{GdownInt});   ## Add a incremental G
		} 
		else {
		    ## Nothing doing.
		    push @next, $g;
		}
	    }
	    elsif ($dir == 1) {
		if ($g->[0]->{ISPOWER} || $g->[0]->{VIRTUALPOWER}) {
		    $update = addNodeG($g->[1], $g->[2], 1, 0);   ## Add a parallel G to node
		}
		elsif ($g->[1]->{ISPOWER} || $g->[1]->{VIRTUALPOWER}) {
		    $update = addNodeG($g->[0], $g->[2], 1, 0);   ## Add a parallel G to node
		}
		elsif ($g->[0]->{GupInt}) {
		    $update = addNodeG($g->[1], $g->[2], 1, $g->[0]->{GupInt});   ## Add a incremental G
		}
		elsif ($g->[1]->{GupInt}) {
		    $update = addNodeG($g->[0], $g->[2], 1, $g->[1]->{GupInt});   ## Add a incremental G
		}
		else {
		    ## Nothing doing.
		    push @next, $g;
		}
	    }
	}
	@gListTmp = @next;
    } while ($update);   ##  Loop until nothing left to do.
}


sub addNodeG {
    ##  Adds a G in parallel with any G already defined for this node.
    ##  refG will be 0 if device is connected to a rail, non-zero otherwise. 
    my $node = shift;
    my $G = shift;
    my $dir = shift;
    my $refG = shift;

#    print "addNodeG:  $node->{NAME}, G=$G, dir=$dir, refG=$refG\n";
    if ($G == 0) {return 1}
    my $incrG = $G;
    if ($refG != 0) {$incrG = 1/((1/$G)+(1/$incrG))}  ##  Add series R, then reconvert to G.

    if ($dir == 0) {$node->{GdownInt} += $incrG}
    elsif ($dir == 1) {$node->{GupInt} += $incrG}

    return 1;
}

sub dumpGs {
    my $devList = shift;

    foreach my $g (@$devList) {
#	print "\t\t\t- $g->[0]->{NAME}, $g->[1]->{NAME}, $g->[2], {@{$g->[3]}}\n";
	nprint ("\t\t\t- $g->[0]->{NAME}, $g->[1]->{NAME}, $g->[2]\n");
	# logMsg(LOG_RAW, "\t\t\t- $g->[0]->{NAME}, $g->[1]->{NAME}, $g->[2]\n");
    }
}

sub addG {
    ##  Add a conductance to the supplied list.
    ##  A conductance record consists of a list, thus:
    ##     [1:0]:  Nodes  (mos S/D or resistor term), node structs, not names.  Simpler to compare.
    ##     [2]:  G
    ##     [3]:  list of parallel devices; Temp for debug.

    my $dev = shift;
    my $devList = shift;
    my $type = shift;   ##  "M" for mos, "R" for res.


#    print "+++ $dev->{INST} {@$devList} $type\n";
    my $gRec = ();
    my ($n1, $n2);
    $n1 = $dev->{NODES}->[0];
    if ($type eq "R") {$n2 = $dev->{NODES}->[1]} elsif ($type eq "M") {$n2 = $dev->{NODES}->[2]} else {print "Oops\n"; return}
    ##  Look for parallel G's
    foreach my $gDev (@$devList) {
	if (($n1 == $gDev->[0]) && ($n2 == $gDev->[1]) || ($n1 == $gDev->[1]) && ($n2 == $gDev->[0])) {
	    ##  Existing G in parallel
	    $gDev->[2] += $dev->{G};
	    push @{$gDev->[3]}, $dev;
#	    print ">> Adding parallel $dev->{INST}\n";
	    return;
	}
    }
    ##  Fell throughl no parallel device
    $gRec->[0] = $n1;
    $gRec->[1] = $n2;
    if (defined $dev->{G}) {
        $gRec->[2] = $dev->{G};
    } else {
		eprint ("Undefined conductance for device\n");
        # logMsg(LOG_ERROR, "Undefined conductance for device\n");
        $gRec->[2] = 1;
    }
    $gRec->[3] = ();
    push @{$gRec->[3]}, $dev;
    push @$devList, $gRec;
    my $n = @$devList;
#    print ">> Adding new $dev->{INST}, $n";
#    dumpGs($devList);
    return;
}

sub DumpMosgroups {
	iprint ("Dumping Mosgroups:\n");
    # logMsg(LOG_INFO, "Dumping Mosgroups:\n");
    foreach my $m (@mosGroups) {
	if ($m->{DEFUNCT}) {next}
	nprint ("Mosgroup $m->{ID}:\n");
	# logMsg(LOG_RAW, "Mosgroup $m->{ID}:\n");
	nprint ("\tDevices:\n");
	# logMsg(LOG_RAW, "\tDevices:\n");
	foreach my $d (@{$m->{DEVS}}) {nprint ("\t\t$d->{INST}\n")}
	# foreach my $d (@{$m->{DEVS}}) {logMsg(LOG_RAW, "\t\t$d->{INST}\n")}
	nprint ("\tNodes:\n");
	# logMsg(LOG_RAW, "\tNodes:\n");
	foreach my $n (@{$m->{NODES}}) {
	    my $pinTag = ($n->{ISPIN}) ? " PIN ": "";
	    my $gateTag = ($n->{GATEFANOUT}) ? " Output ": "";
	    nprint ("\t\t$n->{NAME} $pinTag $gateTag\n");
		# logMsg(LOG_RAW, "\t\t$n->{NAME} $pinTag $gateTag\n");
	}
	nprint ("\tInputs:\n");
	# logMsg(LOG_RAW, "\tInputs:\n");
	foreach my $n (@{$m->{INPUTS}}) {
		nprint ("\t\t$n->{NAME}\n");
	    # logMsg(LOG_RAW, "\t\t$n->{NAME}\n");
	}
    }
}

sub setAggVoltage {
    ##  For each node, determines the highest voltage domain.  Used for aggressor voltage swing.
    foreach my $nodeName (sort(keys %nodeData)) {
	my $rec = $nodeData{$nodeName};
	if (${nodeData{$nodeName}->{DOMAIN}} == 0) {
	    $nodeData{$nodeName}->{AGGVOLTAGE} = 1;
	    $nodeData{$nodeName}->{VICVOLTAGE} = 1;
		wprint ("Undefined domain for $nodeName; assuming 1v\n");
	    # logMsg(LOG_WARNING, "Undefined domain for $nodeName; assuming 1v\n");
	    next;
	}
	my @domains = @{$nodeData{$nodeName}->{DOMAIN}};
	if (@domains == 1) {
	    ##  Single domain, should be vast majority of cases.
	    $nodeData{$nodeName}->{AGGVOLTAGE} = $DomainVoltage->{$domains[0]};
	    $nodeData{$nodeName}->{VICVOLTAGE} = $DomainVoltage->{$domains[0]};
	    next;
	}
	my $high = 0;
	my $low = 999;
	##  Multiple domains should be pretty rare.
	foreach my $d (@domains) {
	    $high =  ($DomainVoltage->{$d} > $high) ? $DomainVoltage->{$d} : $high;
	    $low =  ($DomainVoltage->{$d} < $low) ? $DomainVoltage->{$d} : $low;
	}
	$nodeData{$nodeName}->{AGGVOLTAGE} = $high;
	$nodeData{$nodeName}->{VICVOLTAGE} = $low
    }
}

sub processDeferredCommands {
    my $defer = shift;
	iprint ("Processing level $defer deferred commands\n");
    # logMsg(LOG_INFO, "Processing level $defer deferred commands\n");
    foreach my $cmd (@{$DeferredCommands[$defer]}) {
	my $funcptr = $cmd->{FUNC};
	$funcptr->($cmd->{ARGS});
    }
}

sub getDeviceParam {
    ##  Gets a device param
    my $dev = shift;
    my $pName = lc shift;

    return $dev->{PARAMS}->{$pName};
}

sub addtoDeviceParam {
    ##  Adds $val to the param for a device.
    my $dev = shift;
    my $pName = lc shift;
    my $val = shift;
    
    $dev->{PARAMS}->{$pName} += $val;
}


sub transferDomain {
    ##  Passes along domain info from source to drain, or vice-versa
    my $n1 = shift;
    my $n2 = shift;
    my $mos = shift;

    if ($n2->{ISPOWER} || $n2->{ISGROUND}) { return }
#    print "Transfer domain from $n1->{NAME} to $n2->{NAME} via $mos->{INST}  ";
    if ($n1->{DOMAINDEF}) {
	foreach my $domain (keys %{$n1->{DOMAINHASH}}) {
	    $n2->{DOMAINHASH}->{$domain} = 1;
	    $n2->{DOMAINDEF} = 1;
#	    print " $domain";
	}
    }
#    print "\n";
}

sub traceDomains {
    ##  Attempts to define a power domain to all nodes.
	iprint ("Tracing power domains\n");
    # logMsg(LOG_INFO,"Info:  Tracing power domains\n");
    ##  Trace through MOS (S-->D, D-->S) or RES.
    my @next_md = (@mosDevices,@resDevices);
    my $pass = 1;
    my $update = 0;
    do {
	$update = 0;
	my @md = @next_md;
	@next_md = ();
	foreach my $dev (@md) {
	    if ($dev->{TYPE} eq "MOS") {
		##  Propagate domains from S to D or vise-versa
		$t1 = 0;
		$t2 = 2;
	    }
	    elsif ($dev->{TYPE} eq "RES") {
		$t1 = 0;
		$t2 = 1;
	    }
	    if ($dev->{NODES}->[$t1]->{ISGROUND}) {next}   #  Device connected to ground; 
	    if ($dev->{NODES}->[$t2]->{ISGROUND}) {next}   #  Device connected to ground; 
	    
	    ##  Devices connected direcly to a rail.  Domain is unambiguous.
	    if ($dev->{NODES}->[$t1]->{ISPOWER}) {
		$dev->{NODES}->[$t1]->{DOMAINHASH}->{$dev->{NODES}->[$t1]->{NAME}} = 1; $dev->{NODES}->[$t1]->{DOMAINDEF} = 1;
		$dev->{NODES}->[$t2]->{DOMAINHASH}->{$dev->{NODES}->[$t1]->{NAME}} = 1; $dev->{NODES}->[$t2]->{DOMAINDEF} = 1;
		$update = 1;
		next;
	    }
	    
	    if ($dev->{NODES}->[$t2]->{ISPOWER}) {
		$dev->{NODES}->[$t2]->{DOMAINHASH}->{$dev->{NODES}->[$t2]->{NAME}} = 1; $dev->{NODES}->[$t2]->{DOMAINDEF} = 1;
		$dev->{NODES}->[$t1]->{DOMAINHASH}->{$dev->{NODES}->[$t2]->{NAME}} = 1; $dev->{NODES}->[$t1]->{DOMAINDEF} = 1;
		$update = 1;
		my $n = $dev->{NODES}->[$t1];
		my @d = keys %{$n->{DOMAINHASH}};
		next;
	    }
	    
	    if ($dev->{NODES}->[$t1]->{DOMAINDEF}) {
		transferDomain($dev->{NODES}->[$t1], $dev->{NODES}->[$t2], $dev);
		$update = 1;
		next;
	    }
	    
	    if ($dev->{NODES}->[$t2]->{DOMAINDEF}) {
		transferDomain($dev->{NODES}->[$t2], $dev->{NODES}->[$t1], $dev);
		$update = 1;
		next;
	    }
	    ## Nothing useful happened.
	    push @next_md, $dev;
	}
	$pass++;
    } while ($update);

    ##  Convert to simple list for all future references.
    foreach my $nodeName (keys %nodeData) {
	@{$nodeData{$nodeName}->{DOMAIN}} = keys(%{$nodeData{$nodeName}->{DOMAINHASH}});
#	delete $nodeData{$nodeName}->{DOMAINHASH}
    }
}

sub dumpNodes {
	iprint ("Node Dump:\n");
    # logMsg(LOG_INFO, "Node Dump:\n");
    foreach my $nodeName (sort keys %nodeData) {
	my $n = $nodeData{$nodeName};
	my @d = @{$n->{DOMAIN}};
	nprint("$nodeName:  domain={@d}\n");
	# logMsg(LOG_RAW, "$nodeName:  domain={@d}\n");
    }
}

sub mergeMos {
    ##  Merges MOS devices.
	iprint ("Merging MOS devices\n");
    # logMsg(LOG_INFO, "Merging MOS devices\n");
    my @merged;
    foreach my $mos (@mosDevices) {
#	print Dumper($mos);
	##  Look for devices with identical G/D/S connections.
	my $mDev = undef;
	my $g = $mos->{G};
	foreach my $mergedMos (@merged) {
#	    print "\t$mos->{INST} $mos->{TYPE} $mos->{NODES}->[0] $mos->{NODES}->[1] $mos->{NODES}->[2] $mos->{NODES}->[3]\n";
	    if ($mos->{NODES}->[1] != $mergedMos->{NODES}->[1]) {next}   #  Check gate
	    if ($mos->{NODES}->[3] != $mergedMos->{NODES}->[3]) {next};  ##  Check bulk
	    if ($mos->{MOSTYPE} ne $mergedMos->{MOSTYPE}) {next};  ##  Check type
	    if (($mos->{NODES}->[0] == $mergedMos->{NODES}->[0]) && ($mos->{NODES}->[2] == $mergedMos->{NODES}->[2])) {$mDev = $mergedMos; last;}
	    if (($mos->{NODES}->[0] == $mergedMos->{NODES}->[2]) && ($mos->{NODES}->[2] == $mergedMos->{NODES}->[0])) {$mDev = $mergedMos; last;}
	}
	
	if (defined $mDev) {
#	    print "Merging $mos->{INST} and $mDev->{INST}\n";
	    my $w = getDeviceParam($mos, $mos->{WVAR});
	    my $l = getDeviceParam($mos, $mos->{LVAR});
	    ##  BOZO:  Check for length consistency.
	    addtoDeviceParam($mDev, $mos->{WVAR}, $w);   ##  Add the device width to merged device.
	    $mDev->{G} += $g;  ##  Add conductances
	} else {
	    ##  No match.
	    push @merged, $mos;
	}
    }
    @mosDevices = @merged;
    
}

sub genAggressorIgnoreHash {
    ##  Takes list from ignore_aggressor list and expands into a full 2d hash.
    
#    if (!(defined @allNodes)) {@allNodes = keys %nodeData}   ## Build a single list of all nodes for cases where there's no spec'ed victim.
    foreach my $rec (@{$dataCommands->{ignoreAggressor}->{LIST}}) {
	my $aggressor = $rec->[0];
	my $victim = $rec->[1];
	my $expandedVictimList; 
	my $expandedAggressorList;
	foreach my $aggNode (expandNodeList($aggressor)) {
	    if ($victim eq "") {
		$ignoreAggressor->{$aggNode} = \%nodeData;  ##  A bit of a hack. Use the already existing nodeData hash to double as the victim hash when all victims are specified.
	    } else {
		foreach my $vicNode (expandNodeList($victim)) {$ignoreAggressor->{$aggNode}->{$vicNode} = 1}
	    }
	}
    }

#    foreach $aggNode (keys %$ignoreAggressor) {
#	foreach $vicNode (keys %{$ignoreAggressor->{$aggNode}}) {
#	}
#    }

}


sub checkRequiredNodeParam {
    my $param = shift;
    my $id = shift;
    my $nodeName = shift;
    
    if (defined $param) {return 1}
    else {
		wprint ("\"$id\" is undefined for node $nodeName\n");
	# logMsg(LOG_WARNING, "\"$id\" is undefined for node $nodeName\n");
	return 0;
    }
}


sub checkNodeCompleteness {
    ##  Makes sure that all the necessary node params are in place to run coupling successfully.
	iprint ("Checking nodes for completeness\n");
    # logMsg(LOG_INFO, "Checking nodes for completeness\n");
    my $allOK = 1;
    foreach my $nodeName (keys %nodeData) {
	my $rec = $nodeData{$nodeName};
	if ($rec->{ISPOWER} || $rec->{ISGROUND}) {next}
	my $OK = 1;
	$OK &&= checkRequiredNodeParam($rec->{CLASS}, "Node class", $nodeName);
	$OK &&= checkRequiredNodeParam($rec->{FANOUT}->{CLASS}, "Fanout class", $nodeName);
	$OK &&= checkRequiredNodeParam($rec->{FANOUT}->{DOMAIN}, "Fanout domain", $nodeName);
	$allOK &&= $OK;
	if (!$OK) {
	    $rec->{SKIPCOUPLING} = 1;
		wprint ("Coupling analysis for victim node $nodeName will be skipped\n");
	    # logMsg(LOG_WARNING, "Coupling analysis for victim node $nodeName will be skipped\n");
	}
    }
	if ($allOK) {iprint ( "All nodes complete for coupling analysis\n")}
    # if ($allOK) {logMsg(LOG_INFO, "All nodes complete for coupling analysis\n")}
}


sub calcNoise {
    foreach my $nodeName (sort(keys %nodeData)) {
	my $rec = $nodeData{$nodeName};
	if ($rec->{SKIPCOUPLING}) {next};
	my $fanoutDomain = $rec->{FANOUT}->{DOMAIN};
	my $fanoutDomainVoltage = $DomainVoltage->{$fanoutDomain};
	my $fanoutLimit = $rec->{FANOUT}->{LIMIT};
	my $fanoutLimitPct = $rec->{FANOUT}->{LIMITPCT};
#	if (!(defined $fanoutLimit)) {print "Warning:  Undefined fanout for $nodeName\n"; return}
	if ($rec->{ISPOWER} || $rec->{ISGROUND}) {next}
	my $noiseLH = 0;
	my $noiseHL = 0;
	my $gup =   (defined $rec->{GupCoup}) ? $rec->{GupCoup} : $noiseVars->{defaultGup}->{VALUE};
	my $gdown = (defined $rec->{GdownCoup}) ? $rec->{GdownCoup} : $noiseVars->{defaultGdown}->{VALUE};
	foreach my $agg (@{$rec->{CCOUPLE}}) {
	    my $aggName = $agg->[0];
	    my $aggCap = $agg->[1];
	    if ($aggCap == 0) {next}
	    my $aggRec = $nodeData{$aggName};
	    my $aggVoltage = $aggRec->{AGGVOLTAGE};
	    my $aggTrise =  (defined $aggRec->{TRISE}) ? $aggRec->{TRISE} : $noiseVars->{defaultAggTrise}->{VALUE};
	    my $aggTfall = (defined $aggRec->{TFALL}) ? $aggRec->{TFALL} : $noiseVars->{defaultAggTfall}->{VALUE};
	    $noiseLH += calcNoiseCase($aggVoltage, $gdown, $rec->{CTOTAL0}, $aggCap, $aggTrise);
	    $noiseHL += calcNoiseCase($aggVoltage, $gup, $rec->{CTOTAL1}, $aggCap, $aggTfall);
	}
	$rec->{NOISELH} = $noiseLH;
	$rec->{NOISEHL} = $noiseHL;

	my $maxNoise = ($noiseLH > $noiseHL) ? $noiseLH : $noiseHL;
#	print "!!! $nodeName  $rec->{FANOUT}->{DOMAIN}\n";
	if ($fanoutDomainVoltage == 0) {
		eprint ("Fanout domain voltage is zero for $nodeName, domain=\"$fanoutDomain\"\n");
	    # logMsg(LOG_ERROR, "Fanout domain voltage is zero for $nodeName, domain=\"$fanoutDomain\"\n");
	    next;
	}
	my $maxSlack = ($fanoutLimit-$maxNoise)/$fanoutDomainVoltage;
	$rec->{SLACK} = $maxSlack;
#	print "calcNoise:  victim=$nodeName  slack=$rec->{SLACK}  maxNoise=$maxNoise fanoutLimit=$fanoutLimit \n"
	## Check noise against the limits.  Slacks are normalized to supply voltage, so sort better.
#	my $slackLH = ($noiseLH - $fanoutLimit)/$fanoutDomainVoltage;
#	my $slackHL = ($noiseHL - $fanoutLimit)/$fanoutDomainVoltage;
	
#	print "calcNoise:  victim=$nodeName, gup=$gup, gdown=$gdown, cCouple=$rec->{CTOTALCOUPLE}, cTotal0=$rec->{CTOTAL0}, cTotal1=$rec->{CTOTAL1}, noiseLH=$noiseHL, noiseLH=$noiseLH, class=$rec->{CLASS}, fanoutDomain=$fanoutDomain,  limit=$fanoutLimit ($fanoutLimitPct%)\n";
    }
}

sub calcNoiseCase {
    my $aggV = shift;
    my $g = shift;  ## Conductance, not resistance.
    my $cTotal = shift;
    my $cCouple = shift;
    my $aggEdge = shift;

    my $nStep = 100;   ##  Number of steps used for the aggressor edge.

    ##  Calculates actual noise for the case of a victim held by a resistance.

    ##  Method:   Approximates the aggressor edge as a staircase waveform.
    ##            During the rise edge of the stairstep, deltaV on the victim will be governed solely by the coupling ratio, cCouple/cTotal.
    ##            During the flat of the step, the voltage will droop based on r*cTotal
    ##            Noise peak will be at the end of the aggressor edge.

    my $tStep = $aggEdge/$nStep;  ##  Delta T per step.
    my $vStep = $aggV/$nStep;      ##  Delta V (aggressor) per step
    my $droopFactor = exp((-1*$tStep*$g)/$cTotal);  ##  Factor used for RC decay during "tread" part of stairstep aggressor waveform
    my $victimStepUp = $vStep * ($cCouple/$cTotal);  ##  The step up (away from rail) in response to the aggressor edge
    
    my $v = 0;
    my $i;
    for ($i=0; ($i<$nStep); $i++) {
	$v += $victimStepUp;
	$v *= $droopFactor;
    }
    
    if (0) {
	##  Debug
	print "calcNoiseCase: aggV=$aggV, g=$g, cTotal=$cTotal, cCouple=$cCouple, aggEdge=$aggEdge, noise=$v\n";
    }

    return $v;
}


sub expandNodeList {
    my $nodePatt = shift;
    my $origPatt = shift;
    my @l = ();

    if (!(defined $nodePatt)) {return @l}
    if ($nodePatt eq "") {return @l}
    foreach my $nodeName (sort(keys %nodeData)) {
	if ($nodeName =~ /$nodePatt/i) {push @l, $nodeName}
    }
    if (@l == 0) {
	## Nothing found
	if (defined $origPatt) {$nodePatt = $origPatt}
	wprint ("No nodes matched \"$nodePatt\"\n");
	# logMsg(LOG_WARNING, "No nodes matched \"$nodePatt\"\n");
    }
    return @l;
}

sub processDataFile {
    my $dataFile = shift;

    my $datFH;
    
	iprint ("Reading $dataFile\n");
    # logMsg(LOG_INFO,  "Reading $dataFile\n");
    my @data = read_file($dataFile);
	# open($datFH, $dataFile);
    # my $line;
    my $lineNum = 0;
	foreach my $line (@data){
    # while ($line = <$datFH>) {
	$line =~ s/\#.*//;   ##  Uncomment
	$lineNum++;
	my @toks = Tokenify($line);
	if (@toks == 0) {next};
	my $cmd = shift @toks;
	if (!(defined $dataCommands->{$cmd})) {
	    $cmd = uniqueCommand($cmd);
	    if (!(defined $dataCommands->{$cmd})) {
			wprint ("Unrecognized command  \"$cmd\" at line $lineNum of $dataFile \n");
		# logMsg(LOG_WARNING,  "Unrecognized command  \"$cmd\" at line $lineNum of $dataFile \n");
		next;
	    }
	}

	my $funcptr = $dataCommands->{$cmd}->{FUNCTION};
	if (!defined $funcptr) {
		eprint ("Unrecognized command  \"$cmd\" at line $lineNum of $dataFile \n");
	    # logMsg(LOG_ERROR,  "Unrecognized command  \"$cmd\" at line $lineNum of $dataFile \n");
	} else {
	    my $level = $dataCommands->{$cmd}->{LEVEL};
	    ##  LEVEL 0 commands are executed immediately, anything else is saved and run at the appropriate time.
	    if 	($level > 0) {
		#		print "Info:  Deferring $cmd\n";
		##  A command that wants to be executed after the netlist is loaded.
		my $rec = {};
		$rec->{FUNC} = $funcptr;
		$rec->{CMD} = $cmd;
		$rec->{ARGS} = \@toks;
		push @{$DeferredCommands[$level]}, $rec;
	    } else {
		$funcptr->(\@toks);
	    }
	}
    }
    # close $datFH;
}

sub uniqueCommand {
    ##  Look for a unique match
    my $cmd = shift;
#    print "Looking for unique command for $cmd\n";
    
    my $i = 0;
    my $uCmd;
    foreach my $fullCmd (keys %$dataCommands) {
	if ($fullCmd =~ /^$cmd(.*)/) {
	    $i++;
	    $uCmd = $fullCmd;
#	    print "Found unique command $cmd --> $fullCmd\n";
	}
    }

    if ($i == 1) {return $uCmd} else {return $cmd};
}


sub read_tech_func {
    my $toks = shift;

    foreach my $techFile (@$toks) {
	if (-r $techFile) {
		iprint ("Reading $techFile\n");
	    # logMsg(LOG_INFO, "Reading $techFile\n");
	    do $techFile;
#	    print Dumper($deviceTables);
	}  else {
		eprint ("Cannot open $techFile for read\n");
	    # logMsg(LOG_ERROR, "Cannot open $techFile for read\n");
	}
    }
}

sub set_domain_voltage_func {
    my $toks = shift;

    foreach my $t (@$toks) {
	if ($t =~ /^(\S+)=(\S+)$/) {
		iprint ("Setting $1 domain voltage to $2\n");
	    # logMsg(my $log_INFO, "Setting $1 domain voltage to $2\n");
	    $DomainVoltage->{$1} = $2;
	} else {
		eprint ("Malformed arg in set_domain_voltage \"$t\"\n");
	    # logMsg(LOG_ERROR, "Malformed arg in set_domain_voltage \"$t\"\n");
	}
    }
}

sub setDriverDevice {
    my $deviceName = shift;
    my $deviceWidth = shift;
    my $deviceLength = shift;
    my $domain = shift;
    my $argList = shift;
    my $type = shift;
    
    if (!(defined $deviceName) && !(defined $deviceWidth) && !(defined $deviceLength)) {return}  ##  Not defining any.  That's OK
    my $argOK = 1;
	if (!(defined $deviceName)) {eprint ("Undefined device_name in set_eff_driver\n"); $argOK=0}
    if (!(defined $deviceWidth)) {eprint ("Undefined device_width in set_eff_driver\n"); $argOK=0}
    if (!(defined $deviceLength)) {eprint ("Undefined device_length in set_eff_driver\n"); $argOK=0}
    # if (!(defined $deviceName)) {logMsg(LOG_ERROR, "Undefined device_name in set_eff_driver\n"); $argOK=0}
    # if (!(defined $deviceWidth)) {logMsg(LOG_ERROR, "Undefined device_width in set_eff_driver\n"); $argOK=0}
    # if (!(defined $deviceLength)) {logMsg(LOG_ERROR,"Undefined device_length in set_eff_driver\n"); $argOK=0}
    if (!$argOK) {return}
    
    ##  Fully defined.  Carry on.
    if (defined ($deviceTables->{$deviceName})) {
	my $wvar = lc $deviceTables->{$deviceName}->{WVAR};
	my $lvar = lc $deviceTables->{$deviceName}->{LVAR};
#	$deviceWidth = SpiceNumToReal($deviceWidth);
#	$deviceLength = SpiceNumToReal($deviceLength);
	##  Build a device record to look up the resistance.  NAME and PARAMS should be all that are required.
	my $devRec = {};
	my $params = {};
	$devRec->{NAME} = $deviceName;
	$params->{$wvar} = $deviceWidth;
	$params->{$lvar} = $deviceLength;
	$devRec->{PARAMS} = $params;
	my $g = genDeviceResSingle("Gsd", $devRec, $deviceName);
	foreach my $nodeGlob (@$argList) {
	    my $nodePatt = glob_to_regex_string($nodeGlob);
	    foreach my $nodeName (expandNodeList($nodePatt, $nodeGlob)) {
		$nodeData{$nodeName}->{"${type}Coup"} = $g;
		$nodeData{$nodeName}->{"${type}MinNZ"} = $g;
		if (defined $domain) {
		    @{$nodeData{$nodeName}->{DOMAIN}} = ($domain);
		}
	    }
	}
    } else {eprint ("Unrecognized device_name \"$deviceName\" in set_eff_width\n"); return}
	# else {logMsg(LOG_ERROR, "Unrecognized device_name \"$deviceName\" in set_eff_width\n"); return}
}
     

sub set_func {
    ##  "set" command func.  
    my $toks = shift;

    if (@$toks != 2) {
		eprint ("Incorrect number of args in \"set\" command\n");
	# logMsg(LOG_ERROR, "Incorrect number of args in \"set\" command\n");
	nprint ("\t\"set @$toks\"\n");
	# logMsg(LOG_RAW, "\t\"set @$toks\"\n", 1);
	return;
    }

    my $varName = $toks->[0];
    my $varValue = $toks->[1];
    my $type = $noiseVars->{$varName}->{TYPE};
    if (defined $type) {
	if ($type == $VARTYPE_NUMERIC) {$noiseVars->{$varName}->{VALUE} = SpiceNumToReal($varValue)}
	else {$noiseVars->{$varName}->{VALUE} = $varValue}
    }
    else {
		eprint ("Unrecognized variable name \"$varName\" in set command\n");
	# logMsg(LOG_ERROR, "Unrecognized variable name \"$varName\" in set command\n");
    }

}

sub set_powers_func {
    my $toks = shift;
    
    @Powers = ();  ##  Flush the defaults.
    foreach my $supply (@$toks) {push @Powers, $supply}
}

sub set_fanout_func {
    my $toks = shift;

    @ARGV = @$toks;
    my $class;
    my $domain;
    $result = GetOptions(
	"class=s" => \$class,
	"domain=s" => \$domain
	);
    
    foreach my $nodeGlob (@ARGV) {
	my $nodePatt = glob_to_regex_string($nodeGlob);
	foreach my $nodeName (expandNodeList($nodePatt, $nodeGlob)) {

	    ##  Process set_node -class:
	    if (defined $class) {
		if (validateNodeClass($class)) {$nodeData{$nodeName}->{FANOUT}->{CLASS} = $class}
	    }

	    ##  Process set_node -domain:
	    if (defined $class) {
		if (validateDomain($domain)) {$nodeData{$nodeName}->{FANOUT}->{DOMAIN} = $domain}
	    }
	    updateFanoutLimit($nodeData{$nodeName});
	}
    }
}

sub set_virtualPower_func {
    my $toks = shift;

    @ARGV = @$toks;

    foreach my $nodeGlob (@ARGV) {
	my $nodePatt = glob_to_regex_string($nodeGlob);
	foreach my $nodeName (expandNodeList($nodePatt, $nodeGlob)) {
	    $nodeData{$nodeName}->{VIRTUALPOWER} = 1;
	    $nodeData{$nodeName}->{DC} = 1;
	}
    }
}

sub set_virtualGround_func {
    my $toks = shift;

    @ARGV = @$toks;

    foreach my $nodeGlob (@ARGV) {
	my $nodePatt = glob_to_regex_string($nodeGlob);
	foreach my $nodeName (expandNodeList($nodePatt, $nodeGlob)) {
	    $nodeData{$nodeName}->{VIRTUALGROUND} = 1;
	    $nodeData{$nodeName}->{DC} = 0;
	}
    }
}

sub set_node_func {
    my $toks = shift;
    @ARGV = @$toks;
    my $domain;
    my $rup;
    my $rdown;
    my $tedge;
    my $trise;
    my $tfall;
    my $dcLevel;
    my $onlyUndefined = 0;  ##  Apply only to undefined values.
    my $pullup_device;
    my $pullup_width;
    my $pullup_length;
    my $pulldown_device;
    my $pulldown_width;
    my $pulldown_length;
    my $class;
    my $clk = 0;
    $result = GetOptions(
	"domain=s" => \$domain,
	"rup=s" => \$rup,
	"rdown=s" => \$rdown,
	"tedge=s" => \$tedge,
	"trise=s" => \$tedge,
	"tfall=s" => \$tedge,
	"dc=i" => \$dcLevel,
	"pullup_device=s" => \$pullup_device,
	"pullup_width=s" => \$pullup_width,
	"pullup_length=s" => \$pullup_length,
	"pulldown_device=s" => \$pulldown_device,
	"pulldown_width=s" => \$pulldown_width,
	"pulldown_length=s" => \$pulldown_length,
	"class=s" => \$class,
	"clk" => \$clk
	);
    foreach my $nodeGlob (@ARGV) {
	my $nodePatt = glob_to_regex_string($nodeGlob);
	foreach my $nodeName (expandNodeList($nodePatt, $nodeGlob)) {

	    my $n = $nodeData{$nodeName};
	    
	    ##  Process effective driver
	    setDriverDevice($pullup_device, $pullup_width, $pullup_length, $domain, \@ARGV, "Gup");
	    setDriverDevice($pulldown_device, $pulldown_width, $pulldown_length, $domain, \@ARGV, "Gdown");

	    ##  Process -domain
	    if (defined $domain) {
		if (!$onlyUndefined || (@{$n->{DOMAIN}} == 0)) {@{$n->{DOMAIN}} = ($domain)}
	    }

	    ##  Process -rup

	    if (defined $rup) {
		my $g = 1/SpiceNumToReal($rup);
		setNodeParam($nodeName, "GupCoup", $g, $onlyUndefined);
		setNodeParam($nodeName, "GupMinNZ", $g, $onlyUndefined);
	    }

	    ##  Process -rup
	    if (defined $rdown) {
		my $g = 1/SpiceNumToReal($rdown);
		setNodeParam($nodeName, "GdownCoup", $g, $onlyUndefined);
		setNodeParam($nodeName, "GdownMinNZ", $g, $onlyUndefined);
	    }

	    ##  Process -tedge, sets both trise and tfall.

	    if (defined $tedge) {
		setNodeParam($nodeName, "TRISE", SpiceNumToReal($tedge) , $onlyUndefined);
		setNodeParam($nodeName, "TFALL", SpiceNumToReal($tedge) , $onlyUndefined);
	    }

	    if (defined $trise) {
		setNodeParam($nodeName, "TRISE", SpiceNumToReal($trise) , $onlyUndefined);
	    }
		
	    if (defined $tfall) {
		setNodeParam($nodeName, "TFALL", SpiceNumToReal($tfall) , $onlyUndefined);
	    }

	    ##  Indicate that the node is dc; level=0 or 1.
	    if (defined $dcLevel) {
		if ( ($dcLevel==0) || ($dcLevel==1)) {
		    setNodeParam($nodeName, "DC", $dcLevel , $onlyUndefined);
		}
	    }

	    ##  Tag node as a clock
	    if ($clk) {setNodeParam($nodeName, "ISCLK", 1, $onlyUndefined)}

	    ##  Process set_node -class:
	    if (defined $class) {
		if (validateNodeClass($class)) {
		    setNodeParam($nodeName, "CLASS", $class);
		    if ($class eq $TheStaticClass) {
			##  For static class, set effective coupling G's to the min calculated values.
#			print "Setting $nodeName static:  $n->{GdownMinNZ}, $n->{GupMinNZ}\n";
			setNodeParam($nodeName, "GdownCoup", $n->{GdownMinNZ}, $onlyUndefined);
			setNodeParam($nodeName, "GupCoup", $n->{GupMinNZ}, $onlyUndefined);
		    }
		}
	    }

	}
    }
}

sub minDomain {
    ##  Given a list of domains, returns the one with the lowest supply.
    my $domainList = shift;

    
    my $minV = 999;
    my $minD;
    foreach my $d (@$domainList) {
	if ($DomainVoltage->{$d} < $minV) {$minV = $DomainVoltage->{$d}; $minD = $d}
    }
    return $minD;
}

sub updateFanoutLimit {
    ##  Sets the fanout limit based on nodeClass, fanoutClass and fanoutDomain.
    ##  Used when fanout is forced by command.
    my $nodeRec = shift;

    my $domain = $nodeRec->{FANOUT}->{DOMAIN};
    if (!$domain) {
	##  fanout domain is currently undefined.  Assume same domain as current node.
	$domain = $nodeRec->{DOMAIN};
	$nodeRec->{FANOUT}->{DOMAIN} = $domain;
    }

    my $class = $nodeRec->{FANOUT}->{CLASS};
    if (!$class) {
	$class = $TheDefaultClass;
    }

    my $domainVoltage = $DomainVoltage->{$domain};
    my $limitPct = ($nodeRec->{ISCLK}) ? 
	$nodeClasses->{$nodeRec->{CLASS}}->{LIMITS}->{$class}->{CLKLIMIT} : 
	$nodeClasses->{$nodeRec->{CLASS}}->{LIMITS}->{$class}->{SIGLIMIT};
    my $limit = $limitPct * ($domainVoltage/100);  ##  Convert limit to fraction of output node domain.
    $nodeRec->{FANOUT}->{LIMIT} = $limit;
    $nodeRec->{FANOUT}->{LIMITPCT} = $limitPct;
}


sub validateNodeClass {
    my $inClass = lc shift;

    my $outClass;
    if ($nodeClasses->{$inClass}) {return 1}  ##  Exact match

    my @classList = keys %$nodeClasses;
    my $mat = bestMatch($inClass, \@classList);
    if ($mat) {return 1} else {
		eprint ("Unrecognized node class \"$inClass\"\n");
	# logMsg(LOG_ERROR, "Unrecognized node class \"$inClass\"\n");
	return 0;
    }
}

sub bestMatch {
    my $str = shift;
    my $matList = shift;
    
    my $i = 0;
    my $outMatch;
    foreach my $mat (@$matList) {
	if ($mat =~ /^$str(.*)/) {
	    $i++;
	    $outMatch = $mat;
	}
    }

    if ($i == 1) {return $outMatch} else { return };

}

sub setNodeParam {
    my $nodeName = shift;
    my $pName = shift;  ## Node param name
    my $pVal = shift;   #  Node param value
    my $onlyUndefined = shift;  ##  Set only if onlyUndefined.
    
    if (!(defined $pVal)) {return}  ## Ignore if value is undefined.
#    print "!!! setting $pName to $pVal for $nodeName\n";
    if (!$onlyUndefined || !(defined $nodeData{$nodeName}->{$pName})) {$nodeData{$nodeName}->{$pName} = $pVal}
    
}

sub set_grounds_func {
    my $toks = shift;
    
    @Grounds = qw( ^0$ );  ##  Flush the defaults, but always keep the node "0".
    foreach my $ground (@$toks) {push @Grounds, $ground}
}

sub ignore_aggressor_func {
    my $toks = shift;

    my @victims;
    
    @ARGV = @$toks;
    $result = GetOptions(
			 "victim=s" => \@victims
			 );

    if (@victims == 0) {push @victims, ""}  ##  Empty victim will be interpreted dowstream as "all"
    foreach my $aggressor (@ARGV) {
	foreach my $victim (@victims) {
	    my $victim_re = glob_to_regex_string($victim);
	    my $aggressor_re = glob_to_regex_string($aggressor);
	    my $rec = ();
	    $rec->[0] = $aggressor_re;
	    $rec->[1] = $victim_re;
	    push @{$dataCommands->{ignoreAggressor}->{LIST}}, $rec;
	}
    }
}

sub dumpNodeCouplingDetails {
    my $rec = shift;
    my $fh = shift;
    
    my $isPin = ($rec->{ISPIN}) ? "PIN" : "";
    if ($rec->{ISPOWER} || $rec->{ISGROUND}) {next}
#    print "$nodeName  $isPin, Class=$rec->{CLASS}, Fanout=$rec->{FANOUT}\n";
    my @domains = @{$rec->{DOMAIN}};
    my $domainStr = "Unknown";
    if (@domains > 0) {$domainStr = "@domains"}
    print $fh "\tDomain = $domainStr\n";
    my $Rup = "Z";
    my $Rdown = "Z";
    if ($rec->{GupCoup} != 0) {$Rup = sprintf "%.2f", 1/$rec->{GupCoup}}
    if ($rec->{GdownCoup} != 0) {$Rdown = sprintf "%.2f", 1/$rec->{GdownCoup}}
    print $fh "\tRup = $Rup\n";
    print $fh "\tRdown = $Rdown\n";
#    print $fh "\tTedge: Rise $rec->{TRISE}, Fall $rec->{TFALL}\n";
    my $cTotal0 = $rec->{CTOTAL0};
    my $cTotal1 = $rec->{CTOTAL1};
    my $cFixed = $rec->{CTOTALFIXED};
    my $cCouple = $rec->{CTOTALCOUPLE};
    my $cdev0 = $rec->{CDEV0};
    my $cdev1 = $rec->{CDEV1};
    if (!(defined $cdev0)) {$cdev0 = 0}
    if (!(defined $cdev1)) {$cdev0 = 0}
    printf $fh  "\tCtotal:  %.6e/%.6e\n", $cTotal0, $cTotal1;
    
    if ($cTotal0 == 0) {
	print $fh "\tDangle\n";
    } else {
	printf $fh  "\tDevice Cap:  %.6e/%.6e  (%.2f%/%.2f%)\n", $cdev0, $cdev1, 100*$cdev0/$cTotal0, 100*$cdev1/$cTotal1;
	printf $fh  "\tCfixed:  %.6e  (%.2f%%/%.2f%%)\n", $cFixed, 100*$cFixed/$cTotal0,100*$cFixed/$cTotal1;
	printf $fh  "\tCcouple: %.6e  (%.2f%%/%.2f%%)\n", $cCouple, 100*$cCouple/$cTotal0,100*$cCouple/$cTotal1;
	foreach my $aggRec (@{$rec->{CCOUPLE}}) {
	    my $aggName = $aggRec->[0];
	    my $aggCap = $aggRec->[1];
	    my $aggPct0 = ($aggCap/$cTotal0)*100;
	    my $aggPct1 = ($aggCap/$cTotal1)*100;
	    printf $fh  "\t\t$aggName: %.6e, %.2f%%/%.2f%% \n", $aggCap, $aggPct0, $aggPct1;
	}
	my $noiseLHpct = ($rec->{VICVOLTAGE} != 0) ? 100*$rec->{NOISELH}/$rec->{VICVOLTAGE} : 0;
	my $noiseHLpct = ($rec->{VICVOLTAGE} != 0) ? 100*$rec->{NOISEHL}/$rec->{VICVOLTAGE} : 0;
	printf $fh  "\tNoiseLH: %.3fv,  %.2f%%\n", $rec->{NOISELH},  $noiseLHpct;
	printf $fh  "\tNoiseHL: %.3fv,  %.2f%%\n", $rec->{NOISEHL},  $noiseHLpct;
    }
}

sub DumpNodes {

    foreach my $nodeName (sort(keys %nodeData)) {
	my $rec = $nodeData{$nodeName};
	my $isPin = ($rec->{ISPIN}) ? "PIN" : "";
	if ($rec->{ISPOWER} || $rec->{ISGROUND}) {next}
	nprint ("$nodeName  $isPin, Class=$rec->{CLASS}, Fanout=$rec->{FANOUT}\n");
	# logMsg(LOG_RAW,  "$nodeName  $isPin, Class=$rec->{CLASS}, Fanout=$rec->{FANOUT}\n");
	my @domains = @{$rec->{DOMAIN}};
	my $domainStr = "Unknown";
	if (@domains > 0) {$domainStr = "@domains"}
	nprint ("\tDomain = $domainStr\n");
	# logMsg(LOG_RAW,  "\tDomain = $domainStr\n");
	my $Rup = "Z";
	my $Rdown = "Z";
	if ($rec->{GupCoup} != 0) {$Rup = sprintf "%.2f", 1/$rec->{GupCoup}}
	if ($rec->{GdownCoup} != 0) {$Rdown = sprintf "%.2f", 1/$rec->{GdownCoup}}
	nprint ("\tRup = $Rup\n");
	# logMsg(LOG_RAW,  "\tRup = $Rup\n");
	nprint ("\tRdown = $Rdown\n");
	# logMsg(LOG_RAW,  "\tRdown = $Rdown\n");
	nprint ("\tTedge: Rise $rec->{TRISE}, Fall $rec->{TFALL}\n");
	# logMsg(LOG_RAW,  "\tTedge: Rise $rec->{TRISE}, Fall $rec->{TFALL}\n");
	my $cTotal0 = $rec->{CTOTAL0};
	my $cTotal1 = $rec->{CTOTAL1};
	my $cFixed = $rec->{CTOTALFIXED};
	my $cCouple = $rec->{CTOTALCOUPLE};
	my $cdev0 = $rec->{CDEV0};
	my $cdev1 = $rec->{CDEV1};
	if (!(defined $cdev0)) {$cdev0 = 0}
	if (!(defined $cdev1)) {$cdev0 = 0}
	
	my $tmp;
	$tmp = sprintf "\tCtotal:  %.6e/%.6e\n", $cTotal0, $cTotal1;
	nprint ("$tmp");
	# logMsg(LOG_RAW, $tmp);
	
	if ($cTotal0 == 0) {
	    print "\tDangle\n";
	} else {
	    $tmp = sprintf "\tDevice Cap 0:  %.6e  (%.2f%%)\n", $cdev0, 100*$cdev0/$cTotal0;
		nprint ("$tmp");
	    # logMsg(LOG_RAW, $tmp);
	    $tmp = sprintf "\tDevice Cap 1:  %.6e  (%.2f%%)\n", $cdev1,  100*$cdev1/$cTotal1;
	    nprint ("$tmp");
		# logMsg(LOG_RAW, $tmp);
	    $tmp = sprintf "\tCfixed:  %.6e  (%.2f%%/%.2f%%)\n", $cFixed, 100*$cFixed/$cTotal0,100*$cFixed/$cTotal1;
	    nprint ("$tmp");
		# logMsg(LOG_RAW, $tmp);
	    $tmp = sprintf "\tCcouple: %.6e  (%.2f%%/%.2f%%)\n", $cCouple, 100*$cCouple/$cTotal0,100*$cCouple/$cTotal1;
	    nprint ("$tmp");
		# logMsg(LOG_RAW, $tmp);
	    foreach my $aggRec (@{$rec->{CCOUPLE}}) {
		my $aggName = $aggRec->[0];
		my $aggCap = $aggRec->[1];
		my $aggPct0 = ($aggCap/$cTotal0)*100;
		my $aggPct1 = ($aggCap/$cTotal1)*100;
		$tmp = sprintf "\t\t$aggName: %.6e, %.2f%%/%.2f%% \n", $aggCap, $aggPct0, $aggPct1;
		nprint ("$tmp");
		# logMsg(LOG_RAW, $tmp);
	    }
	    my $noiseLHpct = ($rec->{VICVOLTAGE} != 0) ? 100*$rec->{NOISELH}/$rec->{VICVOLTAGE} : 0;
	    my $noiseHLpct = ($rec->{VICVOLTAGE} != 0) ? 100*$rec->{NOISEHL}/$rec->{VICVOLTAGE} : 0;
	    $tmp = sprintf "\tNoiseLH: %.3fv,  %.2f%%\n", $rec->{NOISELH},  $noiseLHpct;
	    nprint ("$tmp");
		# logMsg(LOG_RAW, $tmp);
	    $tmp = sprintf "\tNoiseHL: %.3fv,  %.2f%%\n", $rec->{NOISEHL},  $noiseHLpct;
	    nprint ("$tmp");
		# logMsg(LOG_RAW, $tmp);
	}
    }
}

sub fixupCaps {
    ##  Goes through the ccouple list for all nodes, compresses duplicates and sorts according to cap
	iprint ("Sorting and compressing coupling caps\n");
    # logMsg(LOG_INFO, "Sorting and compressing coupling caps\n");
    foreach my $nodeName (keys %nodeData) {
	my %tempHash;
	my @compressedUnsortedList = ();
	my $rec = $nodeData{$nodeName};
	my $cTotal0 = 0;
	my $cTotal1 = 0;
	$cTotal0 += $rec->{CDEV0};
	$cTotal1 += $rec->{CDEV1};
	my $cFixed = 0;
	foreach my $aggRec (@{$rec->{CFIXED}}) {$cFixed += $aggRec->[1]}
	## Build up a hash to get rid of duplicates.
	my $aggRec;
	my $cCouple = 0;
	foreach my $aggRec (@{$rec->{CCOUPLE}}) 
	{
	    my $aggName = $aggRec->[0];
	    my $aggCap = $aggRec->[1];
	    my $aggNode = $nodeData{$aggName};
	    if (($ignoreAggressor->{$aggName}->{$nodeName}) || (defined $aggNode->{DC})) {
		##  An ignore found, or aggressor is DC.  Add to fixed, and set to zero here, leaving the aggressor in the list as an indication of the ignore.
		$cFixed += $aggRec->[1];
		$aggRec->[1] = 0;
	    }
	    $tempHash{$aggRec->[0]} += $aggRec->[1]; $cCouple += $aggRec->[1];
	}
	$cTotal0 += $cFixed;
	$cTotal1 += $cFixed;
	$cTotal0 += $cCouple;
	$cTotal1 += $cCouple;
	my $before = @{$rec->{CCOUPLE}};
	my $after = keys %tempHash;
#	if ($before != $after) {print "!!  $rec->{NAME}, before=$before after=$after\n"}
	foreach my $aggName (keys %tempHash) {
	    my $aggRec = ();
	    $aggRec->[0] = $aggName;
	    $aggRec->[1] = $tempHash{$aggName};
	    push @compressedUnsortedList, $aggRec;
	}
	my $sorted = ();
	@$sorted = sort {$b->[1] <=> $a->[1]} @compressedUnsortedList;
	foreach my $x (@$sorted) {
	}
	$rec->{CCOUPLE} = $sorted;
	$rec->{CTOTAL0} = $cTotal0;
	$rec->{CTOTAL1} = $cTotal1;
	$rec->{CTOTALFIXED} = $cFixed;
	$rec->{CTOTALCOUPLE} = $cCouple;
    }
}

sub getNodeCaps {
    my $device = shift;
    my $node = shift;
    
    my $x = $deviceTables->{$device}->{NODECAPS}->{$node};
    return $x;
}

sub read_netlist_func
{
    my $toks = shift;

    my $infile = shift @$toks;
    if (!(defined $infile)) {
		fatal_error ("File not specified in read_netlist\n");
	# logMsg(LOG_FATAL, "File not specified in read_netlist\n");
	exit;
    }
	iprint ("Reading $infile\n");
    # logMsg(LOG_INFO, "Reading $infile\n");
    $gunzFile = sideGunzip($infile);
    if (defined $gunzFile) {
        if (-e $gunzFile) {
            $infile = $gunzFile;
        } else { next}
    }
    
	my @NET = read_file($infile);
	# open(my $NET, ,"$infile") || die "Error: Cannot open $infile\n";
    foreach my $line (@NET)
	# while ($line = GetLine(*NET))
    {
#	print $line;
	my @tokens = Tokenify($line);
	my $tok1 = $tokens[0];
	my $tok1lc = lc $tok1;
	if ($tok1)
	{
	    my $id = uc(substr($tok1,0,1));
	    if ($id eq "X") {ProcessInstance(\@tokens, $fid)}
	    elsif ($id eq "C") {ProcessCap(\@tokens, $fid)}
	    elsif ($id eq "R") {ProcessRes(\@tokens, $fid)}
	    elsif ($id eq "M") {ProcessMos(\@tokens, $fid)}
	    elsif ($id eq "D") {ProcessDiode(\@tokens, $fid)}
	    elsif ($tok1lc eq ".subckt") {
		my $subckt = shift @tokens;
		my $cellName = shift @tokens;
		foreach my $pinName (@tokens) {
		    $pinName = bracketMap($pinName);
		    my $nodeRec = getNode($pinName);
		    $nodeRec->{ISPIN} = 1;
		}
	    }
	    elsif ($id eq "*") {next}
	    elsif ($id eq ".") {next}
	    elsif ($id eq "\$") {next}
	    else {print "Missed $id\n"}
	}
    }
    # close NET;
    if (defined $gunzFile) {unlink $gunzFile}
}

sub GetLine
{
    my $fh = shift;

    my $line;

    ## $linebuf should hold the pre-fetched next non-continuation line.
    if (!$linebuf) {$linebuf = <$fh>}   ##  Read first line of file.

    while ($line = <$fh>)
    {
	##$linebuf =~ s/^\s*(.*)\s*$/$1/g;
	if (substr($line, 0, 1) eq "+")
	{
	    ## Line is continuation
	    chomp $linebuf;
	    $linebuf .= substr($line, 1);
	}
	else
	{
	    ##  Non-continuation.  Return $linebuf
	    my $rline = $linebuf;
	    $linebuf = $line;
	    return $rline;
	}
    }
    if (!$fileDone) {
	$fileDone=1; 
	return $linebuf;
    } else {
	return 0;
    }
}

sub Tokenify
{
    ## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = shift;
    $line =~ s/^\s+?(.*)\s+$/$1/;
    $line =~ s/\s*=\s*/=/g;   ## Strip any whitespace around "=" signs.  Makes later parsing easier.
    return split(/\s+/, $line);
}

sub parseGenericDevice {
    my $devToks = shift;

    my $nodes = ();
    my $params = ();
    foreach my $t (@$devToks) {
	if (index($t, "=") < 0) {
	    ##  Not found.  A simple token
	    push(@$nodes, $t);
	} else {
	    my @ptoks = split(/=/, $t);
	    my $paramName = lc $ptoks[0];
	    my $paramVal = lc $ptoks[1];
	    $params->{$paramName} = $paramVal;
	}
    }
    my $instName = shift @$nodes;
    my $devName = pop @$nodes;

    ##  Build list of node records.
    my $nodeRec = ();
    foreach my $nodeName (@$nodes) {
	$nodeName = bracketMap($nodeName);
	my $n = getNode($nodeName);
	push @$nodeRec, $n;
	$n->{DEVCONNECT} = 1;   ##  Tag that a given node connects to an active device.  Used later to filter out dangles.
    }

    my $rec = {};

    $rec->{NAME} = $devName;
    $rec->{PARAMS} = $params;
    $rec->{INST} = $instName;
    $rec->{DEVNAME} = $devName;
    $rec->{NODES} = $nodeRec;
    
    $devName = $rec->{NAME};
    my $instNodes = $rec->{NODES};

    my $devNodes = undef;
    if (defined $deviceTables->{$devName}) {
	$devNodes = $deviceTables->{$devName}->{NODES};
	my $type = $deviceTables->{$devName}->{TYPE};
	$rec->{TYPE} = $type;
	if ($type eq "MOS") {
	    $rec->{ISMOS} = 1;
	    $rec->{MOSTYPE} = uc $deviceTables->{$devName}->{MOSTYPE};  ## Generally P or N
	    $rec->{WVAR} = $deviceTables->{$devName}->{WVAR};  ##  The param associated with width, typically W or NFIN
	    $rec->{LVAR} = $deviceTables->{$devName}->{LVAR};  ##  The param associated with length, typically L.
	    $rec->{G} = genDeviceResSingle("Gsd", $rec, $devName);   ## Get the device conductance
	    push @mosDevices, $rec;  ##  Build a list of the MOS devices.
	}
	elsif ($type eq "RES") {
	    $rec->{ISRES} = 1;
	    $rec->{G} = genDeviceResSingle("Gsd", $rec, $devName);   ## Get the device conductance
#	    print "resistor g = $rec->{G}\n";
	    push @resDevices, $rec;
	}
    } else {
	if (defined $uncharDeviceWarning{$devName}) {
	    ##  Warning already issued
	} else {
	    $uncharDeviceWarning{$devName} = 1;
		wprint ("Uncharacterized device $devName\n");
	    # logMsg(LOG_WARNING, "Uncharacterized device $devName\n");
	}
    }

    my $i = 0;
    foreach my $node (@$instNodes) {
	my $devNode = (defined $devNodes) ? $devNodes->[$i] : undef;
	processNodeDeviceCaps($node, $devNode, $rec);
	$i++;
    }

    return $rec;
}

sub getNode {
    my $nodeName = shift;

    if (!(defined $nodeData{$nodeName})) {
	my $rec = {};
	$rec->{NAME} = $nodeName;
	$rec->{AGGRESSORS} = ();  ##  Will contain a list of aggressor nodes and caps.
	if (isPower($nodeName)) {
	    $rec->{ISPOWER} = 1;
	    $rec->{DC} = 1;
	}
	if (isGround($nodeName)) {
	    $rec->{ISGROUND} = 1;
	    $rec->{DC} = 0;
	}
	$rec->{CFIXED} = ();
	$rec->{CCOUPLE} = ();
	$rec->{DOMAIN} = ();
	$rec->{DOMAINHASH} = {};
	$rec->{GupCoup} = 0;   ## Effective high-down holding conductance
	$rec->{GdownCoup} = 0;  ##  Effective low-up holding conductance
	$nodeData{$nodeName} = $rec;
    } 
    return $nodeData{$nodeName};
}

sub processNodeDeviceCaps {
    ## Gets the device caps connected to a node and adds them to the appropriate fields in the node record.

    my $nodeRec = shift;
    my $devNode = shift;
    my $devRec = shift;

    my $isPowerGround = $nodeRec->{ISPOWER} || $nodeRec->{ISGROUND};
    if ((defined $devNode) && !$isPowerGround) {
	## Not a supply, and linked to a characerized device, so process device caps.
	my $devName = $devRec->{NAME};
	my $nodeCaps = $deviceTables->{$devName}->{NODECAPS}->{$devNode};
	my ($cap0, $cap1);
	($cap0,$cap1) = genDeviceCaps($devNode, $nodeCaps, $devRec, $devName);
#	print "Adding $cap0 for CDEV0 $nodeRec->{NAME}\n";
#	print "Adding $cap1 for CDEV1 $nodeRec->{NAME}\n";
	$nodeRec->{CDEV0} += $cap0;
	$nodeRec->{CDEV1} += $cap1;
    }
}

sub genDeviceCaps {
    ##  Generates 
    my $devNode = shift;
    my $capTableList = shift;
    my $devRec = shift; 
    my $devName = shift;

    my $cap0=0;
    my $cap1=0;
    foreach my $capTable (@$capTableList) {
	$cap0 += genDeviceCapSingle("${capTable}0", $devRec, $devName);
	$cap1 += genDeviceCapSingle("${capTable}1", $devRec, $devName);
#	print "Info:  $devNode cap {@$capTableList} = $cap0,$cap1\n";
    }
    return ($cap0,$cap1);
}

sub genDeviceResSingle {
    my $resTable = shift;
    my $devRec = shift;
    my $devName = shift;
    my $res = undef;
    my $table = $deviceTables->{$devName}->{RES}->{$resTable};
    my $tableData = $deviceTables->{$devName}->{RES}->{$resTable}->{DATA};
    my $tableParams = $table->{tableParams};
    my $rowVar = lc $table->{rowVar};
    my $rowVarVal = 1;
    my $tableParamValue;
    my $pn = lc $tableParams->[0];

    if ($rowVar ne "") {
        if (!(defined $devRec->{PARAMS}->{$rowVar})) {
			eprint ("No such param \"$rowVar\" for $devName\n");
            # logMsg(LOG_ERROR, "No such param \"$rowVar\" for $devName\n");
            return ;
        }
	$rowVarVal = SpiceNumToReal($devRec->{PARAMS}->{$rowVar});
    }

    if (@$tableParams == 0) {
	##  No table really.  Just a single value
	##  BOZO:  Add check for a real single-entry table.
	return $tableData->[0]->[0] * $rowVarVal;
    } else {
	##  There are tables params.  Need to do an actual table lookup.
	##  BOZO:  Only handling a single tableParam at present.  Need to do a recursive reduction to do it right.
	##  This assumes the table is sorted, which the current char script does.

	if (@$tableParams > 1) {fatal_error ("More than one tableParam {@$tableParams}.  Aborting.\n");}
	# if (@$tableParams > 1) {logMsg(LOG_FATAL,  "More than one tableParam {@$tableParams}.  Aborting.\n"); exitApp()}
        if (!(defined $devRec->{PARAMS}->{$pn})) {
			eprint ("No such param \"$pn\" for $devName\n");
            # logMsg(LOG_ERROR, "No such param \"$pn\" for $devName\n");
            return 0;
        }
	$tableParamValue = SpiceNumToReal($devRec->{PARAMS}->{$pn});
	my $i = 0;
        my $xx = @$tableData;
	foreach my $t (@$tableData) {
	    if ($t->[0] >= $tableParamValue) {
		if ($i == 0) {
		    ##  Min value.  Better be exact min.
		    $res = $tableData->[0]->[1] * $rowVarVal;
		} else {
		    ##  Interpolate
		    $res = interpolate($tableParamValue, $tableData->[$i-1]->[0], $tableData->[$i-1]->[1], $tableData->[$i]->[0], $tableData->[$i]->[1])  * $rowVarVal;
		}
		last;
	    }
	    $i++;
	}
    }

    if (!(defined $res)) {
		eprint ("Undefined conductance for $devName $pn=$tableParamValue; Check table range\n");
        # logMsg(LOG_ERROR, "Undefined conductance for $devName $pn=$tableParamValue; Check table range\n");
        return 0;
    }
    return $res;

}

sub genDeviceCapSingle {
    ##  Generates a single device cap number.
    my $capTable = shift;
    my $devRec = shift;
    my $devName = shift;


    my $cap;
    my $table = $deviceTables->{$devName}->{CAPS}->{$capTable};
    my $tableData = $deviceTables->{$devName}->{CAPS}->{$capTable}->{DATA};
    my $tableParams = $table->{tableParams};
    my $rowVar = lc $table->{rowVar};
    my $rowVarVal = 1;
    if ($rowVar ne "") {
	$rowVarVal = $devRec->{PARAMS}->{$rowVar};
        if (defined $rowVarVal) {
            $rowVarVal = SpiceNumToReal($rowVarVal);
        } else {
			wprint ("No such parameter \"$rowVar\" for $devRec->{NAME}\n");
            # logMsg(LOG_WARNING, "No such parameter \"$rowVar\" for $devRec->{NAME}\n");
            return 0;
        }
    }
#    print "-genDeviceCapSingle: $capTable, $devName {@$tableParams}\n";
    
    if (@$tableParams == 0) {
	##  No table really.  Just a single value
	##  BOZO:  Add check for a real single-entry table.
	$cap = $tableData->[0]->[0] * $rowVarVal;
    } else {
	##  There are tables params.  Need to do an actual table lookup.
	##  BOZO:  Only handling a single tableParam at present.  Need to do a recursive reduction to do it right.
	##  This assumes the table is sorted, which the current char script does.

	if (@$tableParams > 1) {fatal_error ("More than one tableParam {@$tableParams}.  Aborting.\n");}
	# if (@$tableParams > 1) {logMsg(LOG_FATAL, "More than one tableParam {@$tableParams}.  Aborting.\n"); exitApp()}
	my $pn = lc $tableParams->[0];
	my $tableParamValue = SpiceNumToReal($devRec->{PARAMS}->{$pn});
	my $i = 0;
	foreach my $t (@$tableData) {
	    if ($t->[0] >= $tableParamValue) {
		if ($i == 0) {
		    ##  Min value.  Better be exact min.
		    $cap = $tableData->[0]->[1] * $rowVarVal;
		} else {
		    ##  Interpolate
		    $cap = interpolate($tableParamValue, $tableData->[$i-1]->[0], $tableData->[$i-1]->[1], $tableData->[$i]->[0], $tableData->[$i]->[1])  * $rowVarVal;
		}
		last;
	    }
	    $i++;
	}
    }
    ##  Ignore caps below a certain threshold.
    $cap = ($cap > $noiseVars->{capIgnoreThresh}->{VALUE}) ? $cap : 0;
#    print "genDeviceCapSingle:  $capTable $devName \"@$tableParams\" \"$rowVar\" $cap\n";
    return $cap;


}

sub isPower {
    my $nodeName = shift;
    foreach my $powerPatt (@Powers) {if ($nodeName =~ /^$powerPatt$/) {return 1}}
    return 0;
}

sub isGround {
    my $nodeName = shift;
    foreach my $groundPatt (@Grounds) {if ($nodeName =~ /^$groundPatt$/) {return 1}}
    return 0;
}


sub ProcessRes
{
    my $tokens = shift;
    my $fid = shift;

}

sub registerCouplingCap {
    my $victim = shift;
    my $aggressor = shift;
    my $cap = shift;

#    print "Registering cap:  victim=$victim->{NAME}, $aggressor->{NAME}\n";
    if ($victim->{ISPOWER} || $victim->{ISGROUND}) {return}  ## Skip if victim is a power/ground.
    my $rec = ();
    $rec->[0] = $aggressor->{NAME};
    $rec->[1] = $cap;
    if ($aggressor->{ISPOWER} || $aggressor->{ISGROUND}) {
	push @{$victim->{CFIXED}}, $rec;
	my $n = @{$victim->{CFIXED}};
#	print "Saving CFIXED for $victim->{NAME}, $cap\n";
    } else {
	push @{$victim->{CCOUPLE}}, $rec;
	my $n = @{$victim->{CCOUPLE}};
#	print "Saving CCOUPLE for $victim->{NAME} $cap\n";
    }

}

sub ProcessCap
{
    my $tokens = shift;
    my $fid = shift;

    my $nodeA = $tokens->[1];
    my $nodeB = $tokens->[2];
    $nodeA = bracketMap($nodeA);
    $nodeB = bracketMap($nodeB);
    my $cap = $tokens->[3];

    my $recA = getNode($nodeA);
    my $recB = getNode($nodeB);

    registerCouplingCap($recA, $recB, $cap);
    registerCouplingCap($recB, $recA, $cap);

}

sub ProcessDiode
{
    my $tokens = shift;
    my $fid = shift;

    my $rec = parseGenericDevice $tokens;

}

sub ProcessMos
{
    my $tokens = shift;
    my $fid = shift;

    my $rec = parseGenericDevice $tokens;

}

sub ProcessInstance
{
    my $tokens = shift;
    my $fid = shift;

    my $rec = parseGenericDevice $tokens;

}



sub dumpGenericDevice {
    my $rec = shift;
    
    my $instName = $rec->{INST};
    my $devName = $rec->{DEVNAME};
    my $nodes = $rec->{NODES};
    my $params = $rec->{PARAMS};

    nprint ("Instance $instName $devName:\n");
	# logMsg(LOG_RAW, "Instance $instName $devName:\n");
    nprint ("\tNodes = {@$nodes}\n");
	# logMsg(LOG_RAW, "\tNodes = {@$nodes}\n");
    nprint ("\tParams:\n");
	# logMsg(LOG_RAW, "\tParams:\n");
    foreach my $pName (keys(%{$rec->{PARAMS}})) {print "\t\t$pName = $rec->{PARAMS}->{$pName}\n"}

}

sub IsMos
{
    my $devname = shift;
#    print "Checking $devname\n";

    $devname = lc($devname);
    if (defined $mosdata->{$devname}) { return 1}
    return 0;

}

sub IsSupply
{
    my $node = shift;

    $node = uc($node);
    if ($node =~ m/^VSS/) { return 1 }
    if ($node =~ m/^VDD/) { return 1 }
    return 0;
    
}

sub CheckRequiredArg
{
    my $arg = shift;
    my $argname = shift;

    
    if (defined $arg) { return 1} else {
		eprint ("Missing required arg $argname\n");
	# logMsg(LOG_ERROR, "Missing required arg $argname\n");
	return 0
    }

}

sub CheckFileRead
{
    my $fileName = shift;
    
    if (-r $fileName) { return 1} else {
	eprint ("File $fileName cannot be opened for read\n");
	# logMsg(LOG_ERROR, "File $fileName cannot be opened for read\n");
	return 0
    }

}

sub SpiceNumToReal
{

    my $InStr = lc(shift);

    if ($InStr =~ m/(([-+])?(\d+)?(\.)?(\d+)([e][-+]?\d+)?)([a-z]+)?/)
    {
	##  $1 is number part
	##  $7 is multiplier
	##  The rest can be ignored I think.
#	print "\t\$1 = $1\n";
#	print "\t\$2 = $2\n";
#	print "\t\$3 = $3\n";
#	print "\t\$4 = $4\n";
#	print "\t\$5 = $5\n";
#	print "\t\$6 = $6\n";
	my $mul = 1.0;
	my $mulstr = lc($7);
	if ($mulstr ne "")
	{
	    my $mulstr1 = substr($mulstr, 0, 1);
	    if ($mulstr1 eq "a") {$mul = 1e-18}
	    elsif ($mulstr1 eq "f") {$mul = 1e-15}
	    elsif ($mulstr1 eq "f") {$mul = 1e-15}
	    elsif ($mulstr1 eq "p") {$mul = 1e-12}
	    elsif ($mulstr1 eq "n") {$mul = 1e-09}
	    elsif ($mulstr1 eq "u") {$mul = 1e-06}
	    elsif ($mulstr1 eq "m") 
	    {
		$mul = 1e-03;
		if (substr($mulstr, 0, 3) eq "meg")
		{
		    $mul = 1e+06;
		}
	    }
	    elsif ($mulstr1 eq "k") {$mul = 1e+03}
	    elsif ($mulstr1 eq "x") {$mul = 1e+06}
	    elsif ($mulstr1 eq "g") {$mul = 1e+09}
	    elsif ($mulstr1 eq "t") {$mul = 1e+12}
	    else {$mul = 1.0}
	}
	$value = $1 * $mul;
#	print "$InStr: $value\n";
	return $value;
    }
    else 
    {
		eprint ("SpiceNumToReal: Could not parse $InStr\n");
	# logMsg(LOG_ERROR, "SpiceNumToReal: Could not parse $InStr\n");
	return ;
    }
}

sub interpolate
{
    my $x = shift;
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;
    
    ##  Add undefined checker 
    my $y = $y1 + ((($x-$x1)/($x2-$x1))*($y2-$y1));
    return $y;
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

sub read_pininfo_func
{
    my $toks = shift;

    if (@$toks < 1) {
		eprint ("File not specified in read_pininfo\n");
	# logMsg(LOG_ERROR, "File not specified in read_pininfo\n");
	return;
    }

    foreach my $csv_file (@$toks) {
		if (!(-r $csv_file)) {wprint ("CSV file \"$csv_file\" cannot be read\n"); next}
	# if (!(-r $csv_file)) {logMsg(LOG_WARNING, "CSV file \"$csv_file\" cannot be read\n"); next}
	iprint ("Reading $csv_file\n");
	# logMsg(LOG_INFO, "Reading $csv_file\n"); 
	
	my @CSV = read_file ($csv_file);
	# open (my $CSV, ,"$csv_file");
	my $line = $CSV[0];  ##  Read header
	chomp $line;
	$line =~ s/\s+//g;
	my %hdr;
	my @headers = split(/,/, $line);
	my $i = 0;
	foreach (@headers) {$hdr{$_} = $i++}  ## Build a hash to look up column numbers
	my $area;
	foreach my $line (@CSV)
	# while ($line = <CSV>)
	{
	    chomp $line;
	    $line =~ s/\s+//g;
	    my @t = split(/,/, $line);
	    my $pintype = GetCsvValue(\@t, $hdr{pin_type});
	    if (($pintype eq "primary_power") || ($pintype eq "primary_ground")) {next}
	    my $name = GetCsvValue(\@t, $hdr{name});
	    my $dir = StdDir(GetCsvValue(\@t, $hdr{direction}));
	    ##  Take either "related_(power|ground)_pin or related_(power|ground)
	    my $related_power = GetCsvValue(\@t, $hdr{related_power_pin});
	    my $related_ground = GetCsvValue(\@t, $hdr{related_ground_pin});
	    if (!(defined $related_power)) {$related_power = GetCsvValue(\@t, $hdr{related_power})}
	    if (!(defined $related_ground)) {$related_ground = GetCsvValue(\@t, $hdr{related_ground})}
	    my $rec = {};
	    $rec->{DIR} = $dir;
	    $rec->{RELATED_POWER} = $related_power;
	    $rec->{RELATED_GROUND} = $related_ground;
	    ##  Add new ones
	    foreach my $pinname (bitBlast($name)) {$pininfo{$pinname} = $rec}
	}
	# close CSV;
    }

#    print "Pininfo:\n";
#    foreach my $nn (keys %pininfo) {
#	my $pi = $pininfo{$nn};
#	print "$nn:  dir=$pi->{DIR}, related_power=$pi->{RELATED_POWER}, related_ground=$pi->{RELATED_GROUND}\n";
#    }

}

sub GetCsvValue
{
    my $toks = shift;
    my $idx = shift;

    
    if (!(defined $idx)) {return }
    my $val = $toks->[$idx];
    if ($val eq "-") { $val = undef }
    if ($val eq "") { $val = undef }
    return $val;
}

sub bitBlast {
    ##  bit-blasts a pin name
    my $pinname = shift;

    my @pinlist;
    if ($pinname =~ m/(\w+)\[([0-9:]+)\]/)
    {
	my $name = $1;
	my $idx = $2;

	if ($idx =~ m/(\d+):(\d+)/)
	{
	    ##  Bus index is a range
	    my $from=$1;
	    my $to=$2;
	    if ($from>$to) {$from=$2; $to=$1}
	    for ($i=$from; ($i<=$to); $i++) {
#		push @pinlist, "$name\[$i\]";
		##   Standardizing on <>.
		push @pinlist, "$name<$i>"
	    }
	}
	else {push @pinlist, $pinname}  ## Single bit
    }
    else {push @pinlist, $pinname}  ##  Not a bus or bus bit

    return @pinlist;
}

sub StdDir
{
    my $dir = shift;
    if (!(defined $dir)) {return $dir}
    $dir = lc $dir;

    if    ($dir eq "in")    { return "input" }
    elsif ($dir eq "i")   { return "input" }
    elsif ($dir eq "o")   { return "output" }
    elsif ($dir eq "b")   { return "io" }
    elsif ($dir eq "out")   { return "output" }
    elsif ($dir eq "ioput") { return "io" }
    elsif ($dir eq "inout") { return "io" }
    else                    {return $dir}
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

    if ($printStdout || $forceStdout) {print $msg}

    # print $LOG $msg
}

sub exitApp {
    # close $LOG;
    exit;
}

sub print_usage {
    my $ScriptPath = shift;
    print "Current script path:  $ScriptPath\n";
    pod2usage(0);
}

sub bracketMap {
    my $src = shift;
    ##  Map <> to []
    $src  =~ tr/\[\]/<>/;
    return $src;
}

sub sideGunzip {
    my $file = shift;
	my ($o, $outerr) = run_system_cmd ("file $file", $VERBOSITY);
	my @o = split("\n", $o);
    # my @o = `file $file`;
    if ($o[0] =~ /gzip compressed data/) {
	my @t = split /\//, $file;  ##  Get the base name
	my $basename = pop @t;
	my $gunzName = $basename;
	if ($basename =~ /(.*)\.gz/) {$gunzName = $1} else {$gunzName = "$basename.gunz"}
	if (defined $ENV{TMP}) {$gunzFile = "$ENV{TMP}/$gunzName"} else {$gunzFile = "/tmp/$gunzName"}
	unlink $gunzFile;
	($o, $outerr) = run_system_cmd ("gunzip -c $file > $gunzFile");
	@o = split("\n", $o);
	# @o = `gunzip -c $file > $gunzFile`;
	if (!(-e $gunzFile)) {
		wprint("gunzip of $file failed.\n@o\n");
	    # printMsg("Warning:  gunzip of $file failed.\n@o\n");
	}
	return $gunzFile;
#	printMsg(">>> $file --> $gunzFile\n");
    }
    return ;
}

sub DBG {
    my $msg = shift;
    print("$msg\n");
}

__END__
=head1 SYNOPSIS

    ScriptPath/alphaNoise.pl \
    -config <config-file> \
    -logFile <log-file> \
    -help
    
=item B<-config>  The name of the config file, which contains all the commands necessary for intelligent noise analysis.  Required.

=item B<-logFile>  The name of the logfile for the run. Defaults to alphaNoise.log

=item B<-help>  Prints this stuff.
