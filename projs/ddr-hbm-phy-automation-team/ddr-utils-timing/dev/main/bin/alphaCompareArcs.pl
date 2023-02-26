#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;
use File::Copy;
use File::Find;
use Getopt::Long;
use Data::Dumper ;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Cwd;
#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = FALSE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version() || '2022.11'; # Syntax: YYYYww##[.#] optional day 1-7
                                # The work week number can be found in
                                # your outlook calendar. The days are 1=sunday
                                # 2=monday ... 7=saturday
#--------------------------------------------------------------------#
##------------------------------------------------------------------
##  Gather run statistics for the script
##     First argument is name of the script.
##     Second argument is the script version. (ie. 2022ww10)
##     Third argument (optional) is an aref, used
##          to capture the cmd line arguments and log them.
##------------------------------------------------------------------
our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
BEGIN { our $AUTHOR='Multiple Authors'; header(); } 
&Main();
END {
   write_stdout_log("${LOGFILENAME}.log");
   footer(); 
   utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);
}

##Variables - start of list
my $opt_help = FALSE;
my $debug;
my @orig_argv   = @ARGV;
my $comparison_dir1 ;
my $comparison_dir2 ;
my $include_pass ;
my $output_dir ;
my $values = 0 ;
my $def_values = 0;
my $dir_1;
my $pwd;
my $block;
my $blk_prefix = "dwc_ddrphy";
my $blk_suffix = "_top";
my $build;
my $version;
my $tileType;
#  0    1    2     3     4    5     6     7     8
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =  localtime(time);
my $NoGolden = 0;
my $corner;
my @cornerList;
my $goldenLib;
my $goldenArcFile;
my $pin_name;
my $bus_name;
my $bit_count;
my @my_bits ;
my $related_pin;
my $timing_type;
my $IsMissing;
my @MissingCorners;
my %Extra;
my $cmd;
my @LibFiles;
my @LibFilesComparison;
my $libFile;
my @ArcFiles;
my @ArcFilesComparison;
my $arcFile;
my %TempHash;
my %TempHashComparison;
my %PinHashComparison;
my %PinHash;
my %BusHash;
my %seen;
my $this_count;
my $my_field;
my @ListOfTimingFields = ("RiseCnstr","FallCnstr","CellRise","CellFall","RiseTran","FallTran","RestOfLine");
my @TimingValues;
my $value_value;
my $value_count;
my $value_sum;
my $value_average;
my $value_max;
my $value_min;
my $value_sqtotal;
my $value_stddev;
my $counter;
my $file;
my @my_valuesA ;
my @my_valuesB ;
my $my_valueA ;
my $my_valueB ;
my $diff_abs_valueAB;
my $diff_pct_valueAB;
# Allowable absolute difference in cap value before providing a warning (pF)
my $threshold_cap_diff_absolute = 0.005;
# Allowable percent difference in cap value before providing a warning (0.05 is 5%)
my $threshold_cap_diff_percent  = 0.05; 
# Allowable absolute difference in timing value before providing a warning (nS)
my $threshold_timing_diff_absolute = 0.010;
# Allowable percent difference in timing value before providing a warning (0.05 is 5%)
my $threshold_timing_diff_percent  = 0.05; 

sub my_print;
sub readArcs;
my $opt_nousage = FALSE;

#utils__script_usage_statistics( $RealScript, "2020ww11");
# Get options
#if (!GetOptions("help|h"          => \$opt_help,
#                "debug=n"         => \$debug,
#		"golden=s"        => \$goldenLib,
#		"dat_dir=s"       => \$comparison_dir1,
#		"cmp_dir=s"       => \$comparison_dir2,
#		"include_pass"    => \$include_pass,
#		"output_dir=s"    => \$output_dir,
#		"values"          => \$values,
#                )) {
#    print STDERR &usage;
#    exit -1;
#}

# If asking for help, print help message.
#if ($opt_help) { &usage };


sub Main {

($debug,$goldenLib,$comparison_dir1,$comparison_dir2,$include_pass,$output_dir,$values,$opt_help)
            = process_cmd_line_args();
#sub usage;
##Variables - end of list
    unless( defined $values) {
        $values = $def_values;
    }

    if ( $opt_help ) {
        usage();
    }



$mon++; $year +=1900; 
$mon = sprintf "%02d",$mon;
$mday = sprintf "%02d",$mday;

if (-e $comparison_dir1) {
    find sub {if ($File::Find::name =~ m/.*\.lib.*/) { push(@LibFiles,$File::Find::name) } }, $comparison_dir1;
} else {
     eprint("No dat_dir specified\n");
}

if (-e $comparison_dir2) {
    find sub {if ($File::Find::name =~ m/.*\.lib.*/) { push(@LibFilesComparison,$File::Find::name) } }, $comparison_dir2;
} else {
    eprint("No cmp_dir specified\n");
}

foreach my $libFile (@LibFiles) {
    if ($libFile =~ /.*_(\w+)_pg.lib/ ) {
	$corner = $1;
    } elsif ($libFile =~ /.*_(\w+).lib/ ) {
	$corner = $1; 
    } else {
	$corner = "temp";
	wprint ("Can't find corner, using temp as corner name\n");
    }
    $arcFile = $comparison_dir1."/".$corner.".ETMwValues.csv";
    $cmd = "$RealBin/NicksLibertyParser.pl -values -liberty ".$libFile." > ".$arcFile ;
    run_system_cmd("$cmd",$VERBOSITY) ;
    push (@ArcFiles,$arcFile);
}
foreach my $libFile (@LibFilesComparison) {
    if ($libFile =~ /.*_(\w+)_pg.lib/ ) {
	$corner = $1;
    } elsif ($libFile =~ /.*_(\w+).lib/ ) {
	$corner = $1; 
    } else {
	$corner = "temp";
	wprint ("Can't find corner, using temp as corner name\n");
    }
    $arcFile = $comparison_dir2."/".$corner.".ETMwValues.csv";
    $cmd = "$RealBin/NicksLibertyParser.pl -values -liberty ".$libFile." > ".$arcFile ;
    run_system_cmd("$cmd",$VERBOSITY) ;
    push (@ArcFilesComparison,$arcFile);
}


if (-e $goldenLib) {
    $cmd = "$RealBin/NicksLibertyParser.pl -liberty ".$goldenLib." > ".$comparison_dir1."/GOLDEN.ETM.csv";
    run_system_cmd("$cmd",$VERBOSITY) ;
    $goldenArcFile  = "$comparison_dir1/GOLDEN.ETM.csv";
}



if (-e $goldenArcFile) {
    my_print "\n%% Creating PinHash Golden arc section.\n";
    my_print "\tInfo - Golden arc file is $goldenArcFile.\n";
    $corner = "Golden";
    %TempHash =%{ &readArcs($goldenArcFile)} ;
    foreach my $pin_name (keys %TempHash) {
	foreach my $related_pin (keys %{$TempHash{$pin_name}}) {
	    foreach my $timing_type (keys %{$TempHash{$pin_name}{$related_pin}}) {
		$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Dir} = $TempHash{$pin_name}{$related_pin}{$timing_type}{Dir};
		$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap} = $TempHash{$pin_name}{$related_pin}{$timing_type}{Cap};
		$this_count = $TempHash{$pin_name}{$related_pin}{$timing_type}{Count};
		$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Count} = $this_count ;
		foreach my $my_field (@ListOfTimingFields) {
		    $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{"Timing"}{$my_field}  = $TempHash{$pin_name}{$related_pin}{$timing_type}{$my_field};
		}
		for (my $i=1; $i <= $this_count; $i++) {
		    my $this_pass = "Pass".$i;
		    #$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{"Timing"}{"RestOfLine"}{$this_pass} = $TempHash{$pin_name}{$related_pin}{$timing_type}{RestOfLine}{$this_pass};
		}
	    }
	}
    }
} else {
    my_print "\t Warning - No golden arc file at ${goldenArcFile}.  Will not compare to golden\n";
    $NoGolden = 1;
}

#print Dumper(%PinHash);

my_print "\n%% Creating PinHash for each corner.\n";
foreach my $arcFile (@ArcFiles) {

    if ( $arcFile =~ /.*\/(\w+)\.ETM/ ) {
	$corner = $1;
    } else {
	$corner = "unknown";
    }
    #my_print "\t Info - Corner is $corner\n";
    push (@cornerList, $corner);
    %TempHash =%{ &readArcs($arcFile)} ;
    foreach my $pin_name (keys %TempHash) {
	foreach my $related_pin (keys %{$TempHash{$pin_name}}) {
	    foreach my $timing_type (keys %{$TempHash{$pin_name}{$related_pin}}) {
		$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Dir} = $TempHash{$pin_name}{$related_pin}{$timing_type}{Dir};
		$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap} = $TempHash{$pin_name}{$related_pin}{$timing_type}{Cap};
		$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Count} = $TempHash{$pin_name}{$related_pin}{$timing_type}{Count};
		foreach my $my_field (@ListOfTimingFields) {
		    $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{"Timing"}{$my_field}  = $TempHash{$pin_name}{$related_pin}{$timing_type}{$my_field};
		}
		my $total_count = $TempHash{$pin_name}{$related_pin}{$timing_type}{Count};
		for (my $i=1; $i <= $total_count; $i++) {
		    my $this_pass = "Pass".$i;
		    $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{"Timing"}{"RestOfLine"}{$this_pass} = $TempHash{$pin_name}{$related_pin}{$timing_type}{RestOfLine}{$this_pass};
		}
	    }
	}
    }
}

#print Dumper(%PinHash);
#print Dumper(%PinHashComparison);

# We have to do compares now.
# For each pin, 
# Check that TimingType, RelatedPin and Dir match Golden.
# If it does not, flag an error!  
# Error Missing - in Golden, not in corner(s)
# Error Extra   - not in Golden, but in corner(s)
my_print "\n%% Comparing Golden file to corner tables.\n";
foreach my $pin_name (sort keys %PinHash) {
    #Check for arcs missing in corners
    foreach my $related_pin (keys %{$PinHash{$pin_name}{Golden}}) {
	foreach my $timing_type (keys %{$PinHash{$pin_name}{Golden}{$related_pin}}) {
	    $IsMissing = 0;
	    @MissingCorners = "";
	    foreach my $corner (@cornerList) {
		if (!$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}) {
		    $IsMissing = 1 ;
		    push (@MissingCorners, $corner);
		}
	    }
	    if ($IsMissing) {
		my_print "    Warning: $pin_name has MISSING $timing_type arcs wrt $related_pin in corners: @MissingCorners\n";
	    } elsif ($include_pass) {
		my_print "       PASS: $pin_name $related_pin $timing_type hass all corners. @cornerList\n";
	    }
	}
    }
}
foreach my $pin_name (sort keys %PinHash) {
    #Check for extra arcs in corners
    foreach my $corner (@cornerList) {
	foreach my $related_pin (keys %{$PinHash{$pin_name}{$corner}}) {
	    foreach my $timing_type (keys %{$PinHash{$pin_name}{$corner}{$related_pin}}) {
		if (!$PinHash{$pin_name}{Golden}{$related_pin}{$timing_type}) {
		    $Extra{$pin_name}{$related_pin}{$timing_type} = $Extra{$pin_name}{$related_pin}{$timing_type}." ".$corner;
		}
	    }
	}
    }
    if ($Extra{$pin_name}) {
	foreach my $related_pin (keys %{$Extra{$pin_name}}) {
	    foreach my $timing_type (keys %{$Extra{$pin_name}{$related_pin}}) {
		my_print "    Warning: $pin_name has  EXTRA  $timing_type arcs wrt $related_pin in corners: $Extra{$pin_name}{$related_pin}{$timing_type}\n";
	    }
	}
    } elsif ($include_pass) {
	my_print "       PASS: $pin_name has no extra arcs in corners @cornerList\n";
    }
}

iprint ("\n%% Building bus data\n\n");
foreach my $pin_name (sort keys %PinHash) {
    if ($pin_name =~ /(.*)\[(\d+)\]/) {
	$bus_name =$1 ;
	$bit_count = $2 ;
	$BusHash{$bus_name}{"IsBus"} = 1 ;
	$BusHash{$bus_name}{"BitCount"}++ ;
	$BusHash{$bus_name}{"MissingBits"} = 0 ;
	unless ($seen{$bus_name}) {
	    $BusHash{$bus_name}{"Bits"}   = $bit_count ;
	    $BusHash{$bus_name}{"MinBit"} = $bit_count;
	    $seen{$bus_name} = 1 ;
	} else {
	    $BusHash{$bus_name}{"Bits"} = $BusHash{$bus_name}{Bits}.",".$bit_count ;
	}
	if ($BusHash{$bus_name}{MinBit} > $bit_count) {$BusHash{$bus_name}{"MinBit"} = $bit_count;}
	if ($BusHash{$bus_name}{MaxBit} < $bit_count) {$BusHash{$bus_name}{"MaxBit"} = $bit_count;}
	if ($BusHash{$bus_name}{MaxBit} - $BusHash{$bus_name}{MinBit}  != $BusHash{$bus_name}{"BitCount"}-1) {
	    $BusHash{$bus_name}{"MissingBits"} = 1 ;
	}
    } else {
	$bus_name =$pin_name ;
	$bit_count = 0 ;
	$BusHash{$bus_name}{"IsBus"} = 0 ;
	$BusHash{$bus_name}{"Bits"} = "0";
	$BusHash{$bus_name}{"BitCount"} = "1";
	$BusHash{$bus_name}{"MaxBit"} = "0";
	$BusHash{$bus_name}{"MinBit"} = "0";
	$BusHash{$bus_name}{"MissingBits"} = 0 ;
	if ($BusHash{$bus_name}{MaxBit} - $BusHash{$bus_name}{MinBit}  != $BusHash{$bus_name}{"BitCount"}-1) {
	    $BusHash{$bus_name}{"MissingBits"} = 1 ;
	}
    }
    foreach my $corner (sort keys %{$PinHash{$pin_name}}) {
	foreach my $related_pin (sort keys %{$PinHash{$pin_name}{$corner}}) {
	    foreach my $timing_type (sort keys %{$PinHash{$pin_name}{$corner}{$related_pin}}) {
		unless ($seen{$bus_name.".Dir"}) {
		    $BusHash{$bus_name}{"Dir"}    = $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Dir};
		    $seen{$bus_name.".Dir"} = 1 ;
		} else {
		    if ($BusHash{$bus_name}{"Dir"} != $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Dir}) { wprint ("Warning: Bus $bus_name has direction issues\n"); }
		}
		unless ($seen{$pin_name.".".$corner.".Cap"}) {
		    $BusHash{$bus_name}{"Cap"}{$corner}{$bit_count}=$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap};
		    $seen{$pin_name.".".$corner.".Cap"} = 1 ;
		} else {
		    if ($BusHash{$bus_name}{"Cap"}{$corner}{$bit_count} !=$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap} ) {
			$BusHash{$bus_name}{"Cap"}{$corner}{$bit_count}=$BusHash{$bus_name}{"Cap"}{$corner}{$bit_count}.",".$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap};
		    }
		}
		if ($PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap} == 0 && $corner != "Golden") {
		    #print "Cap value is $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap} for $pin_name in corner $corner ($related_pin and $timing_type).\n";	      
		}		    
		
		# Add in the values
		foreach my $my_field (@ListOfTimingFields) {
		    my $this_value = $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{"Timing"}{$my_field} ;
		    $this_value =~ s/N\/A,//g ;
		    $this_value =~ s/,N\/A//g ;
		    $this_value =~ s/N\/A// ;
		    if ($this_value =~ /^$/) {
			#print "$this_value\n";
			next ;
		    } else {
			#print "\t 3 |$bus_name|$related_pin|$timing_type|$my_field|$corner|$this_value|\n" ;
			$BusHash{"Timing"}{$bus_name}{$related_pin}{$timing_type}{$my_field}{$corner}{$bit_count} = $this_value;
			if ($my_field ne "RestOfLine") {
			    unless ($seen{$bus_name.".".$corner.".".$related_pin.".".$timing_type.".".$my_field.".TimingValues"}) {
				$BusHash{"Timing"}{"Values"}{$bus_name}{$related_pin}{$timing_type}{$my_field}{$corner} = $this_value;
				$seen{$bus_name.".".$corner.".".$related_pin.".".$timing_type.".".$my_field.".TimingValues"}= 1 ;
			    } else {
				$BusHash{"Timing"}{"Values"}{$bus_name}{$related_pin}{$timing_type}{$my_field}{$corner} = $BusHash{"Timing"}{"Values"}{$bus_name}{$related_pin}{$timing_type}{$my_field}{$corner}.",".$this_value;
			    }
			}
		    } 
		}
	    }	    
	}
    }
}
#print "\n%% Generate Average, BitCount, DataCount, Max, Min Range and StdDev for bus data\n\n";
foreach my $bus_name (sort keys %{$BusHash{Timing}{Values}}) {
    foreach my $related_pin (sort keys %{$BusHash{Timing}{Values}{$bus_name}}) {
	foreach my $timing_type (sort keys %{$BusHash{Timing}{Values}{$bus_name}{$related_pin}}) {
	    foreach my $my_field (@ListOfTimingFields) {
		foreach my $corner (sort keys %{$BusHash{Timing}{Values}{$bus_name}{$related_pin}{$timing_type}{$my_field}}) {
		    my $ListOfValues = $BusHash{Timing}{Values}{$bus_name}{$related_pin}{$timing_type}{$my_field}{$corner} ;
		    @TimingValues = split /,/,$ListOfValues ;
		    #print "$ListOfValues, @TimingValues\n";
		    $value_count = 0; $value_sum = 0 ; $value_max = $TimingValues[0] ; $value_min = $TimingValues[0]; $value_sqtotal = 0;
		    foreach my $value_value (@TimingValues) {
			$value_count++;
			$value_sum=$value_sum+$value_value;
			if ($value_value > $value_max) { $value_max = $value_value; }
			if ($value_value < $value_min) { $value_min = $value_value; }
		    }
		    
		    if ($value_count == 0 ) { $value_average  = ($value_sum); } else { $value_average  = ($value_sum)/($value_count); }
		    $BusHash{"Timing"}{"Results"}{$my_field}{$timing_type}{$related_pin}{$bus_name}{$corner}{"ListOfValues"} = $ListOfValues;
		    $BusHash{"Timing"}{"Results"}{$my_field}{$timing_type}{$related_pin}{$bus_name}{$corner}{"Average"} = $value_average;
		    $BusHash{"Timing"}{"Results"}{$my_field}{$timing_type}{$related_pin}{$bus_name}{$corner}{"BitCount"} = $BusHash{$bus_name}{BitCount} ;
		    $BusHash{"Timing"}{"Results"}{$my_field}{$timing_type}{$related_pin}{$bus_name}{$corner}{"DataCount"} = $value_count ;
		    $BusHash{"Timing"}{"Results"}{$my_field}{$timing_type}{$related_pin}{$bus_name}{$corner}{"Max"} = $value_max ;
		    $BusHash{"Timing"}{"Results"}{$my_field}{$timing_type}{$related_pin}{$bus_name}{$corner}{"Min"} = $value_min ;
		    $BusHash{"Timing"}{"Results"}{$my_field}{$timing_type}{$related_pin}{$bus_name}{$corner}{"Range"} = $value_max - $value_min;
		    
		    #print "Bus $bus_name Pin $pin_name Related $related_pin Corner $corner field $my_field Max $value_max Min $value_min Average $value_average\n"; 	
		    foreach my $value_value (@TimingValues) {
			$value_sqtotal +=($value_average-$value_value)**2;
			
		    }
		    if ($value_count <= 1 ) { 
			$value_stddev = 0;
		    } else {
			$value_stddev = ($value_sqtotal/($value_count-1))**0.5;
		    }
		    $BusHash{"Timing"}{"Results"}{$my_field}{$timing_type}{$related_pin}{$bus_name}{$corner}{"StdDev"} = $value_stddev;
		}
	    }
	}
    }
}

#print Dumper($BusHash{Timing}{Results});

iprint ("\n%% Outputing Result CSV File.\n");
my @OUT;
foreach my $my_field (@ListOfTimingFields) {
    foreach my $timing_type (sort keys %{$BusHash{Timing}{Results}{$my_field}}) {
	$counter = 1 ;
	$file = "/remote/us01home45/nhoworth/temp.".$block.".".$my_field.".".$timing_type.".csv";
	if(-e $file)  { unlink $file ; }
	foreach my $related_pin (sort keys %{$BusHash{Timing}{Results}{$my_field}{$timing_type}}) {
	    #$counter = 1 ;
	    #$file = "/remote/us01home45/nhoworth/temp.".$my_field.".".$timing_type.".".$related_pin.".csv";
	    #if(-e $file)  { unlink $file ; }
	    #open(OUT, ">$file");
	    foreach my $bus_name (sort keys %{$BusHash{Timing}{Results}{$my_field}{$timing_type}{$related_pin}}) {
		foreach my $corner (sort keys %{$BusHash{Timing}{Results}{$my_field}{$timing_type}{$related_pin}{$bus_name}}) {
		    my $ListOfValues = $BusHash{Timing}{Results}{$my_field}{$timing_type}{$related_pin}{$bus_name}{$corner}{ListOfValues} ;
		    @TimingValues = split /,/,$ListOfValues ;
		    foreach my $value_value (@TimingValues) {
			#print OUT "$my_field.$timing_type.$bus_name.$related_pin.$corner,$counter,$value_value\n";
			push @OUT, "$my_field.$timing_type.$bus_name.$related_pin.$corner,$counter,$value_value\n";
		        my $status = write_file(\@OUT, $file);
		    }			    
		    $counter++;
		}
	    }
	}
    }
}

#LOAD UP Comparison hash
if (-e $comparison_dir2) {
    my_print "\n%% Creating Comparison Hash from Comparison qor dir.\n";
    my_print "\tInfo - Comparison directory is $comparison_dir2.\n";
    #@ArcFilesComparison = glob "$comparison_dir2/*.ETMwValues.csv";
    foreach my $arcFile (@ArcFilesComparison) {
	if ( $arcFile =~ /.*\/(\w+)\.ETM/ ) {    
	    $corner = $1;
	} else {
	    $corner = "unknown";
	}
	#my_print "Corner is $corner\n";
	push (@cornerList, $corner);
	%TempHashComparison =%{ &readArcs($arcFile)} ;
	foreach my $pin_name (keys %TempHashComparison) {
	    foreach my $related_pin (keys %{$TempHashComparison{$pin_name}}) {
		foreach my $timing_type (keys %{$TempHashComparison{$pin_name}{$related_pin}}) {
		    $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Dir} = $TempHashComparison{$pin_name}{$related_pin}{$timing_type}{Dir};
		    $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap} = $TempHashComparison{$pin_name}{$related_pin}{$timing_type}{Cap};
		    $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Count} = $TempHashComparison{$pin_name}{$related_pin}{$timing_type}{Count};
		    foreach my $my_field (@ListOfTimingFields) {
			$PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{"Timing"}{$my_field}  = $TempHashComparison{$pin_name}{$related_pin}{$timing_type}{$my_field};
		    }
		    my $total_count = $TempHashComparison{$pin_name}{$related_pin}{$timing_type}{Count};
		    for (my $i=1; $i <= $total_count; $i++) {
			my $this_pass = "Pass".$i;
			$PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{"Timing"}{"RestOfLine"}{$this_pass} = $TempHashComparison{$pin_name}{$related_pin}{$timing_type}{RestOfLine}{$this_pass};
		    }
		}
	    }
	}
    }
    # End of TempHashComparison generation.
    #print Dumper(%PinHashComparison);
} else {
    eprint ("No cmp_dir specified\n");
    exit ;
}


iprint ("\n%% Comparing PinHash to Comparison PinHash.\n");
foreach my $pin_name (keys %PinHashComparison) {
    foreach my $corner  (keys %{$PinHashComparison{$pin_name}}) {
	if (!$PinHash{$pin_name}{$corner}) {
	    my_print "    Warning: $pin_name has MISSING corner: $corner.\n";
	    next;
	}
	foreach my $related_pin (keys %{$PinHashComparison{$pin_name}{$corner}}) {
	    foreach my $timing_type (keys %{$PinHashComparison{$pin_name}{$corner}{$related_pin}}) {
		if ($PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Dir} ne $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Dir}) { 
		    my_print "    Warning: $pin_name $corner $related_pin $timing_type Dir values don't match \t Comparison value: $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Dir} \tThis value: $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Dir}  \n";
		} elsif ($include_pass) {
		    my_print "       PASS: $pin_name $corner $related_pin $timing_type Dir values match \t Comparison value: $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Dir} \tThis value: $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Dir}  \n";
		}
		if ($values) {
		    $my_valueA = $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap} ;
		    $my_valueB = $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap} ;
		    $diff_abs_valueAB = abs($my_valueA - $my_valueB);
		    if ($my_valueA != 0) {
			$diff_pct_valueAB = $diff_abs_valueAB/abs($my_valueA);
		    } else {
			$diff_pct_valueAB = 100;
		    }
		    #print "$my_valueA $my_valueB $diff_abs_valueAB, $diff_pct_valueAB\n";
		    if ($diff_abs_valueAB > $threshold_cap_diff_absolute && $diff_pct_valueAB > $threshold_cap_diff_percent) {
			my_print "    Warning: $pin_name $corner $related_pin $timing_type Cap values don't match \t Comparison value: $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap} \tThis value: $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap}  \n";
		    } elsif ($include_pass) {
			my_print "       PASS: $pin_name $corner $related_pin $timing_type Cap values match \t Comparison value: $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap} \tThis value: $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Cap}  \n";
		    }
		}
		if ($PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Count} ne $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Count}) { 
		    my_print "    Warning: $pin_name $corner $related_pin $timing_type Count values don't match \t Comparison value: $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Count} \tThis value: $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Count}  \n";
		} elsif ($include_pass) {
		    my_print "       PASS: $pin_name $corner $related_pin $timing_type Count values match \t Comparison value: $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Count} \tThis value: $PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Count}  \n";
		}
		foreach my $my_field (@ListOfTimingFields) {
		    if ($my_field eq "RestOfLine") {
			#Skip for now
			next ;
		    } 
		    if ($values) {
			@my_valuesA =  sort {$a<=>$b} split /,/,$PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Timing}{$my_field} ;
			@my_valuesB =  sort {$a<=>$b} split /,/,$PinHash{$pin_name}{$corner}{$related_pin}{$timing_type}{Timing}{$my_field} ;
			for (my $i=0; $i < $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{Count} ; $i++) {
			    $my_valueA = $my_valuesA[$i];
			    $my_valueB = $my_valuesB[$i];
			    $diff_abs_valueAB = abs($my_valueA - $my_valueB);
			    if ($my_valueA != 0 ) {
				$diff_pct_valueAB = $diff_abs_valueAB/abs($my_valueA);
			    } else {
				$diff_pct_valueAB = 100;
			    }
			    #print "$my_valueA $my_valueB $diff_abs_valueAB, $diff_pct_valueAB\n";
			    if ($diff_abs_valueAB > $threshold_timing_diff_absolute && $diff_pct_valueAB > $threshold_timing_diff_percent) {
				my_print "    Warning: $pin_name $corner $related_pin $timing_type $my_field values don't match \t Comparison value: $my_valueA \t This value: $my_valueB \n";
			    } elsif ($include_pass) {
				my_print "       PASS: $pin_name $corner $related_pin $timing_type $my_field values match \t Comparison value: $my_valueA \t This value: $my_valueB \n";
			    }
			}
		    }
		}
		my $total_count = $PinHashComparison{$pin_name}{$related_pin}{$timing_type}{Count};
		for (my $i=1; $i <= $total_count; $i++) {
		    my $this_pass = "Pass".$i;
		    #    $PinHashComparison{$pin_name}{$corner}{$related_pin}{$timing_type}{"Timing"}{"RestOfLine"}{$this_pass} = $PinHashComparison{$pin_name}{$related_pin}{$timing_type}{RestOfLine}{$this_pass};
		}
	    }
	}
    }
}

}

&Main();
sub my_print {
my @OUT = "";
    #print @_;
    #print OUT @_;
my $status = write_file(\@OUT, @_);
}


sub readArcs {
    my $this_file = shift;
    my $tileType;
    my $block;
    my $build;
    my $version;
    my $this_pin;
    my $this_dir;
    my $this_cap;
    my $related_pin;
    my $timing_type;
    my $rise_cnstr;
    my $fall_cnstr;
    my $cell_rise;
    my $cell_fall;
    my $rise_tran;
    my $fall_tran;
    my $restOfLine;
    my $this_count;
    my $this_pass;
    my %seen = "";
    my %Hash = "";

    #my_print "This file: $this_file\n";
    my $FILE = "";

    if (! (open ($FILE, $this_file))) { # nolint open<
	my_print ( "Warning - unable to open file $this_file\n" );
    } else {
	my_print "\t Opened file: $this_file\n";
    }

    while (<$FILE>){
	#print "$_";
	if ( $_ =~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)(.*)$/) {
	    $this_pin = $1; $this_dir = $2; $this_cap = $3; $related_pin = $4; $timing_type = $5; 
	    $rise_cnstr = $6; $fall_cnstr = $7; $cell_rise = $8; $cell_fall = $9; 
	    $rise_tran = $10; $fall_tran = $11; $restOfLine = $12;
	} elsif ( $_ =~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)(.*)$/) {
	    $this_pin = $1; $this_dir = $2; $this_cap = "N/A"; $related_pin = $3; $timing_type = $4; 
	    $rise_cnstr = "N/A"; $fall_cnstr = "N/A"; $cell_rise = "N/A"; $cell_fall = "N/A"; 
	    $rise_tran = "N/A"; $fall_tran = "N/A"; $restOfLine = $5;
	} elsif ($_ == "") {
	    next;
	} else {
	    my_print "$_ is not the correct format\n";
	}

	if ($this_pin eq "pin_name") {
	    #this is a header
	    next;
	} else {
	    #my_print "$this_pin - $this_dir - $related_pin - $timing_type - $restOfLine\n";
	    $Hash{$this_pin}{$related_pin}{$timing_type}{"Dir"} = $this_dir;
	    $Hash{$this_pin}{$related_pin}{$timing_type}{"Cap"} = $this_cap;
	    $Hash{$this_pin}{$related_pin}{$timing_type}{"Count"}++;
	    unless ($seen{${this_pin}.".".${related_pin}.".".${timing_type}}) {
		$Hash{$this_pin}{$related_pin}{$timing_type}{"RiseCnstr"} = $rise_cnstr;
		$Hash{$this_pin}{$related_pin}{$timing_type}{"FallCnstr"} = $fall_cnstr;
		$Hash{$this_pin}{$related_pin}{$timing_type}{"CellRise"} = $cell_rise;
		$Hash{$this_pin}{$related_pin}{$timing_type}{"CellFall"} = $cell_fall;
		$Hash{$this_pin}{$related_pin}{$timing_type}{"RiseTran"} = $rise_tran;
		$Hash{$this_pin}{$related_pin}{$timing_type}{"FallTran"} = $fall_tran;
		$seen{${this_pin}.".".${related_pin}.".".${timing_type}} = 1 ;
	    } else {
		$Hash{$this_pin}{$related_pin}{$timing_type}{"RiseCnstr"} = $Hash{$this_pin}{$related_pin}{$timing_type}{"RiseCnstr"}.",".$rise_cnstr;
		$Hash{$this_pin}{$related_pin}{$timing_type}{"FallCnstr"} = $Hash{$this_pin}{$related_pin}{$timing_type}{"FallCnstr"}.",".$fall_cnstr;
		$Hash{$this_pin}{$related_pin}{$timing_type}{"CellRise"} = $Hash{$this_pin}{$related_pin}{$timing_type}{"CellRise"}.",".$cell_rise;
		$Hash{$this_pin}{$related_pin}{$timing_type}{"CellFall"} = $Hash{$this_pin}{$related_pin}{$timing_type}{"CellFall"}.",".$cell_fall;
		$Hash{$this_pin}{$related_pin}{$timing_type}{"RiseTran"} = $Hash{$this_pin}{$related_pin}{$timing_type}{"RiseTran"}.",".$rise_tran;
		$Hash{$this_pin}{$related_pin}{$timing_type}{"FallTran"} = $Hash{$this_pin}{$related_pin}{$timing_type}{"FallTran"}.",".$fall_tran;
	    }
	    $this_count = $Hash{$this_pin}{$related_pin}{$timing_type}{"Count"};
	    $this_pass = "Pass".$this_count;
	    $Hash{$this_pin}{$related_pin}{$timing_type}{"RestOfLine"}{$this_pass} = $restOfLine;
	}
    }

    #print Dumper(%Hash);
    return \%Hash;
}
    
sub process_cmd_line_args(){
    my ( $goldenLib, $dat_dir, $cmp_dir, $include_pass, $output_dir, $values, $opt_help,$opt_dryrun,$opt_debug,$opt_verbosity);
  
    my $success = GetOptions(
               "help|h"          => \$opt_help,
	       "golden=s"	 => \$goldenLib,
               "dryrun!"         => \$opt_dryrun,
               "debug=i"         => \$opt_debug,
               "verbosity=i"     => \$opt_verbosity,
	       "dat_dir=s"	 => \$dat_dir,
	       "cmp_dir=s"	 => \$cmp_dir,
	       "include_pass"	 => \$include_pass,
	       "output_dir=s"	 => \$output_dir,
	       "values" 	 => \$values,
	); 

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    &usage(0) if $opt_help;
    &usage(1) unless( $success );
   
     return ($opt_debug,$goldenLib,$dat_dir,$cmp_dir,$include_pass,$output_dir,$values,$opt_help)

}

sub usage($) {
my $exit_status = shift || '0';
    my $USAGE = <<EOusage;

    Script to compare timing arc files.
    This script must be run in the qor directory
    with rpt results completed.
    Golden file is assumed to be ./con/hook/*.Golden.ETM.csv
    Default search is for all rpt/*.ETM.csv
    Could add *.ETMwValues.csv file searches later.


    Usage: alphaCompareArcs.pl [-h|-help]

    -h or -help  this help message
    -debug	 debug output information (the higher the number the more info).
    -value	 use ETMwValues.csv files (not implemented at this time).
    -bussed	 generate bussed signal statistics

    example of usage:

    Example

    alphaCompareArcs.pl {>>options}

EOusage
nprint ("$USAGE");
exit;
}

__END__

