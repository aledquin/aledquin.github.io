#!/depot/perl-5.14.2/bin/perl

##  The current PERL5LIB causes issues.
use strict;
use warnings;
use lib '/depot';
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib/perl";
use lib "$RealBin/../lib/perl/Chart";
use lib "$RealBin/../lib/perl/PDF";
use English;
use Cwd;
use Pod::Usage;
use Time::localtime;
use Data::Dumper ;
use Liberty::Parser; 
use Parse::Liberty;
use File::Temp qw/ tempfile tempdir /;
use File::Find;
use Getopt::Long;
use PDF::Create;
use Chart::Gnuplot;
use List::MoreUtils qw(:all);
use List::MoreUtils qw{ uniq };
use Sort::Fields;
use File::Copy qw{ move };
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version();
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
my @diff_s = ();
#--------------------------------------------------------------------#


BEGIN {
	#delete $ENV{PERL5LIB}
    our $AUTHOR='Sneha Raghunath';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
	utils__script_usage_statistics( $PROGRAM_NAME, $VERSION);
    header();
}
&Main();
END {
   footer();
   write_stdout_log( $LOGFILENAME );
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
}

 # Get options

sub Main {
	my $help;
	my $lib1;
	my $metalstack;
	my $cellName;
	my $corner;
	my $macro;
	my $lib_path;
	my $output_dir;
	my $localpath;
	my $lib2;
	
	($help, $lib1, $metalstack,
	$cellName, $corner, $macro, $lib_path,
	$output_dir, $localpath) = process_cmd_line_args();


	if(-d $output_dir) {
		rmdir "$output_dir/*";
	} else {
		mkdir "$output_dir";
	}

	if(!$lib1) {
		if(defined $macro) {
			iprint("macro $output_dir\n");
			my @macrolist = split /\s+/, $macro;
			chomp @macrolist;
			my @pvtcorner = split /\s+/, $corner;
			chomp @pvtcorner;
			foreach my $macroname (@macrolist) {
				foreach my $cornername (@pvtcorner) {
					$lib1 = "$localpath/lib_pg/${macroname}_${metalstack}_${cornername}_pg.lib";
					$lib2 = "$localpath/lib/${macroname}_${metalstack}_${cornername}.lib";
					if(CheckRequiredFile($lib1)) {
						iprint "$lib1\n";
						my $exitStatus = &Wrapper($lib1, $output_dir);
						if($exitStatus ne 0) {
							exit -1;
						}
					}
	#				if(CheckRequiredFile($lib2)) {
	#					print "$lib2\n";
	#					&Wrapper($lib2, $output_dir);
	#				}
				}
			}
		}
	}

	if (defined $lib1) {
		iprint "$lib1\n";
		my $exitStatus = &Wrapper( $lib1 , $output_dir);
		if($exitStatus ne 0) {
			exit -1;
		}
	} 

	if (defined $lib_path) {
		my @liblist = glob("$lib_path/\*.lib");
		foreach my $lib1 (@liblist) {
			iprint "$lib1\n";
			my $exitStatus = &Wrapper($lib1, $output_dir);
			if($exitStatus ne 0) {
				exit -1;
			}
		}
	}
}
sub Wrapper {
	my $opt_help; 
    my $lib1 = shift;
#   my $cellName = shift;
    my $output_dir = shift;
    my $libFile1;
    my $libPath1;
    my $csvFile1;
    my $csv_pin_file1;
    my $csv_output = shift;
    my %pinInfo1;
#    my $merge_results = shift;
    my $ui;
    my $pdf;
     
    # If asking for help, print help message.
    if ($opt_help) { &usage };     
    if ( ( -e $lib1 )) { 
     	if ($lib1 =~ /(.*)(\w+\.lib)/) { 
			$libFile1 = $1;
		} else { 
			eprint "Wrong lib file spcified \n";
			return -1;
		}
     	
    } else { 
     	eprint "$lib1  doesn't exist, please check ... \n";
		 return -1;
    }

	
	#open(my $readlib1,"<",$lib1) or die "Can't open $lib1 file for write\n";
	if( ! (-w $lib1)) {
		eprint("Can't open $lib1 file for write.Exiting");
		exit(-1);
	}
	my @lib_csv = split /\//, $lib1;
	$lib_csv[-1] =~ s/\.lib/.csv/;
	run_system_cmd("touch $output_dir/$lib_csv[-1]", $VERBOSITY);
    $csvFile1 = "$output_dir/$lib_csv[-1]";
    $csv_pin_file1 = $csvFile1;
    $csv_pin_file1 =~ s/\.csv/_pin.csv/;
    my @lib_array = ($lib1);
    &ReadLiberty ( $lib1 , $csvFile1, $csv_pin_file1, \%pinInfo1);
	return 0;
	
}

sub GetValueFromPair {
    my $Pair = shift;
    if ($Pair =~ m/(\S+)\s*:\s*(\S+)/) {return $2} else { return(undef) }
}

sub StdDir {
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

sub defineWithDefault {
    my $default = shift;
    my $value = shift;
    if (defined $value) {return $value} else {return $default}
}

sub createString { 
    my @arr_ref = @_;
    my $string = "{";
    foreach my $arrref ( @arr_ref ) {
		if ( $arrref eq "N/A" ) { 
	    	return "N/A";
		}
		$string = $string."(";
		foreach my $number  ( @$arrref ) {
			push @diff_s,$number;
	    	$string = $string."$number,";
		}
		$string = $string.")";
    }
    $string = $string."}";
    return $string;
}

sub find_centre_value {
    my @arr_ref = @_;
	my $count = 0;
    my $string = "";
    foreach my $arrref ( @arr_ref ) {
		if ( $arrref eq "N/A" ) { 
	    	return "N/A";
		}
		foreach my $number  ( @$arrref ) {
			$count = $count + 1;
			push @diff_s,$number;
			if ($count == 13) {
	    		$string = "$number";
			}
		}
    }
    return $string;
}

sub CheckRequiredFile
{
    my $fileName = shift;

    if (defined $fileName) {
	if (-r $fileName) {
	    return 1;
	}
	else {
	    eprint "Error: Required file \"$fileName\" is not readable\n";
	    return 0;
	}
    } else {
	eprint "Error: Required file variable is undefined\n";
	return 0;
    }

}
sub ReadLiberty {
    #variables
    my $result;
    my @liberty;
    my $liberty;
    my $file;
    my $max_var_1;
    my $max_var_2;
    my $min_var_1;
    my $min_var_2;
    my $pg_pin;
    my $bus;
    my $ViewIdx;
    my @ViewList;
    my %TypeCount;
    my $pin;
    my $timingdata ={};
	my $timingscalar ={};
	my %snehar;
    my $this_table = "";
    my $liberty_file = shift;
    my $csvFile = shift;
    my $csv_pin_file = shift;
    my $pinInfo = shift;
	my $voltage;
	my $temperature;
	my $input_transition;
    # Removing existing cvs file if present 
    if (-e $csvFile ) { 
    	unlink ( $csvFile );
    	print "Removing existing CSV file: $csvFile ... \n";	
    } else { 
    	print "CSV file $csvFile doesn't exist, proceed ... \n";
    }
    #open (CSVFILE,">$csvFile") or die "Can't open $csvFile file for write\n";
	my @CSVFILE;
#open (CSVPINFILE,">$csv_pin_file") or die "Can't open $csv_pin_file file for write\n";    
    if (!(-r $liberty_file)) {wprint "Warning:  Liberty file \"$liberty_file\" cannot be read\n"; next}    	        
    my $parser = new Liberty::Parser; 
    my $library_group  = $parser->read_file($liberty_file);
    my $lib_name = $parser->get_group_name($library_group);
    my $leakage_power_unit = $parser->get_simple_attr_value($library_group, "leakage_power_unit");
	my @nom_voltage = $parser->get_simple_attr_value($library_group, "nom_voltage");
	if(scalar(@nom_voltage) > 1) {
	    iprint "@nom_voltage\n";
	}
    my @opconds = $parser->get_groups_by_type($library_group, "operating_conditions"); 
	foreach my $opcond (@opconds) {
#		my $table_name_op = $parser->get_group_name($opcond);
    	my $nom_voltage = $parser->get_attr_with_value($opcond, "voltage");
		if ($nom_voltage =~ /voltage\s*\:\s*(\S+)/) {
		$voltage = $1;
		}
		my $nom_temperature = $parser->get_attr_with_value($opcond, "temperature");
		if ($nom_temperature =~ /temperature\s*\:\s*(\S+)/) {
		$temperature = $1;
		}

	}
    my $Ncond = @opconds;
	iprint "$Ncond @opconds SNeha\n";
    my $opcond_defined = ($Ncond > 0);   ## At least one operating condition.
    my $tree_type_defined = $opcond_defined;
    foreach my $opcond (@opconds) {if (!(defined $parser->get_simple_attr_value($opcond, "tree_type"))) {$tree_type_defined = 0}}
    my $default_max_capacitance = GetValueFromPair($parser->get_attr_with_value($library_group, "default_max_capacitance"));
    my $default_max_transition = GetValueFromPair($parser->get_attr_with_value($library_group, "default_max_transition"));
    ##  Get all the lookup table templates
    my $tableHash = {};
    my @tables = $parser->get_groups_by_type($library_group, "lu_table_template"); 
    my $Ntable = @tables;
    foreach my $table (@tables) {
    	my $table_name = $parser->get_group_name($table);
    	#print CSVFILE "Looking up table $table_name\n";
    	my $variable_2 = $parser->get_simple_attr_value($table, "variable_2");
    	my $variable_1 = $parser->get_simple_attr_value($table, "variable_1");
    	$tableHash->{$table_name} = {};
    	$tableHash->{$table_name}->{VAR_1}->{ID} = $variable_1;
    	$tableHash->{$table_name}->{VAR_1}->{MAX} = $max_var_1;
    	$tableHash->{$table_name}->{VAR_1}->{MIN} = $min_var_1;
    	$tableHash->{$table_name}->{VAR_2}->{ID} = $variable_2;
    	$tableHash->{$table_name}->{VAR_2}->{MAX} = $max_var_2;
    	$tableHash->{$table_name}->{VAR_2}->{MIN} = $min_var_2;
    }
    my $time_unit = $parser->get_simple_attr_value($library_group, "time_unit");
#	my $nom_voltage = $parser->get_simple_attr_value($library_group, "nom_voltage");
	my $default_operating_conditions = $parser->get_simple_attr_value($library_group, "default_operating_conditions");
	iprint "$default_operating_conditions $voltage $temperature\n";
    $time_unit =~ m/^(\d+)([a-zA-Z]+)/;
    if ($2 eq "ns") {$time_unit = "${1}e-9"}
    elsif ($2 eq "ps") {$time_unit = "${1}e-12"}
    else {eprint "Error:  Unrecognized time unit \"$time_unit\"\n"}
    my $cell_group = $parser->locate_group_by_type($library_group, "cell");
    my $cell_name = $parser->get_group_name($cell_group);
    my $cell_leakage_power = GetValueFromPair($parser->get_attr_with_value($cell_group, "cell_leakage_power"));
    my $areaval = $parser->get_attr_with_value($cell_group, "area");
    my $area = GetValueFromPair($areaval);
    $area = sprintf("%.6f", $area);
    my @pins = $parser->get_groups_by_type($cell_group, "pin"); 
    #make sure the first four exist, if not then give the value none
	push @CSVFILE,"pin_name,related_pin,timing_type,timing_sense,min_delay_flag,direction,cell_rise,cell_fall,rise_constraint,fall_constraint,rise_transition,fall_transition,index1,index2,output_load(fF),input_transition(ps),corner,voltage,temperature\n";
    foreach my $pin (sort @pins) {				
		my $timing_count = 0;
		my $pin_name = $parser->get_group_name($pin);
		my $direction = StdDir($parser->get_simple_attr_value($pin, "direction"));
		my $pincap = GetValueFromPair($parser->get_attr_with_value($pin, "capacitance"));
		my $related_power = $parser->get_simple_attr_value($pin, "related_power_pin");
		my $related_ground = $parser->get_simple_attr_value($pin, "related_ground_pin");
		my $max_capacitance = defineWithDefault($default_max_capacitance, GetValueFromPair($parser->get_attr_with_value($pin, "max_capacitance")));
		my $max_transition = defineWithDefault($default_max_transition, GetValueFromPair($parser->get_attr_with_value($pin, "max_transition")));
		$pinInfo->{$pin_name}{direction}=$direction;
		$pinInfo->{$pin_name}{pincap}=$pincap;
		$pinInfo->{$pin_name}{related_power}=$related_power;	
		$pinInfo->{$pin_name}{related_ground}=$related_ground;
		$pinInfo->{$pin_name}{max_capacitance}=$max_capacitance;
		$pinInfo->{$pin_name}{max_transition}=$max_transition;			
		my @timings = $parser->get_groups_by_type($pin, "timing");
		foreach my $timing (sort @timings) {
    		my $related_pin   = $parser->get_simple_attr_value($timing, "related_pin");
    		my $timing_type   = $parser->get_simple_attr_value($timing, "timing_type");
    		my $timing_sense   = $parser->get_simple_attr_value($timing, "timing_sense");	    
			$timing_sense = "N/A" if (! $timing_sense );
    		my $min_delay_flag   = $parser->get_attr_with_value($timing, "min_delay_flag");	    	    
			if ($min_delay_flag =~ /true/ ) { 
				$min_delay_flag = "True";
			} else { 
				$min_delay_flag = "False";	    
			}   	    	
    		my $group_extract = $parser->extract_group($timing,$timing_type);
    		my $index2 = ${timing_type}."index_2";
    		my $index3 = ${timing_type}."index_3";
    		if ($group_extract =~ /${index3}/ ) {
   			} elsif ($group_extract =~ /${index2}/) {
				my @arc_types = ( "rise_constraint" , "fall_constraint" , "cell_rise" , "cell_fall" , "rise_transition" , "fall_transition" );
				my $cur_arc;
				foreach my $arc_type ( @arc_types ) { 
	    			$cur_arc = $parser->locate_group_by_type($timing, $arc_type);
	    			last if ($cur_arc != 0);
				}			    
				my @arr_index1 = $parser->get_lookup_table_index_1($cur_arc);
				my @arr_index2 = $parser->get_lookup_table_index_2($cur_arc);			
				my $string_index1 = join ("," , @arr_index1 );
				my $string_index2 = join ("," , @arr_index2 );  		
				$string_index1 = "{${string_index1}}";
				$string_index2 = "{${string_index2}}";  			
				$timingdata->{"index1"} = $string_index1;
				$timingdata->{"index2"} = $string_index2;
				$timingscalar->{"index1"} = $string_index1;
				$timingscalar->{"index2"} = $string_index2;
				$timingdata->{"rise_constraint"} = createString($parser->get_lookup_table_array($timing, "rise_constraint"));
				$timingdata->{"rise_constraint"} = $parser->get_lookup_table_array($timing, "rise_constraint");
				$timingdata->{"fall_constraint"} = createString($parser->get_lookup_table_array($timing, "fall_constraint"));
				$timingdata->{"cell_rise"}	 = createString($parser->get_lookup_table_array($timing, "cell_rise"));
				$timingdata->{"cell_fall"}	 = createString($parser->get_lookup_table_array($timing, "cell_fall"));
				$timingdata->{"rise_transition"} = createString($parser->get_lookup_table_array($timing, "rise_transition"));
				$timingdata->{"fall_transition"} = createString($parser->get_lookup_table_array($timing, "fall_transition"));
				$timingscalar->{"rise_constraint"} = find_centre_value($parser->get_lookup_table_array($timing, "rise_constraint"));
				$timingscalar->{"rise_transition"} = find_centre_value($parser->get_lookup_table_array($timing, "rise_transition"));
				$timingscalar->{"cell_rise"} = 		 find_centre_value($parser->get_lookup_table_array($timing, "cell_rise"));
				$timingscalar->{"fall_constraint"}	 = find_centre_value($parser->get_lookup_table_array($timing, "fall_constraint"));
				$timingscalar->{"fall_transition"} = find_centre_value($parser->get_lookup_table_array($timing, "fall_transition"));
				$timingscalar->{"cell_fall"}	 = find_centre_value($parser->get_lookup_table_array($timing, "cell_fall"));
				my $rise_constraint = $timingscalar->{"rise_constraint"};
				my $fall_constraint = $timingscalar->{"fall_constraint"};
				my $cell_rise = $timingscalar->{"cell_rise"};
				my $cell_fall = $timingscalar->{"cell_fall"};
				my $rise_transition = $timingscalar->{"rise_transition"};
				my $fall_transition = $timingscalar->{"fall_transition"};
				chomp $rise_constraint;
				chomp $fall_constraint;
				if($direction eq "output") {
					$arr_index2[2] = $arr_index2[2] - $pincap;
#					print "$pincap $arr_index2[2]\n";
				}
				if($timing_type =~ /hold/ || $timing_type =~ /setup/) {
					$input_transition = $arr_index2[2];
				} else {
					$input_transition = $arr_index1[2];
				}
#				print CSVPINFILE "$timing_type,$cell_rise,$cell_fall,$rise_constraint,$fall_constraint\n";
				push @CSVFILE ,"$pin_name,$related_pin,$timing_type,$timing_sense,$min_delay_flag,$direction,$cell_rise,$cell_fall,$rise_constraint,$fall_constraint,$rise_transition,$fall_transition,$arr_index1[2],$arr_index2[2],$pincap,$input_transition,$default_operating_conditions,$voltage,$temperature\n";
            	} else {
            		$timingdata->{"index1"} = "N/A";
            		$timingdata->{"index2"} = "N/A";		
            		$timingdata->{"rise_constraint"} = "N/A";
            		$timingdata->{"fall_constraint"} = "N/A";
            		$timingdata->{"cell_rise"}	 = "N/A";
            		$timingdata->{"cell_fall"}	 = "N/A";
            		$timingdata->{"rise_transition"} = "N/A";
            		$timingdata->{"fall_transition"} = "N/A";
#					print CSVFILE "$pin_name $related_pin $timing_type $timing_sense $min_delay_flag $cell_rise $cell_fall $rise_constraint $fall_constraint $arr_index1[2] $arr_index2[2]\n";
            		my @extract_fields = split ("$timing_type",$group_extract);
            		$this_table = "";
            		my $this_table_type = "";
            		my $thevalues = "";
            		foreach my $this_field (@extract_fields) {
            			if ($this_field =~ /^\s*(\w+)\s+\((scalar)\)\s+\{\s*$/) {
            				$this_table = $1;
            				$this_table_type = $2;
            			} elsif ($this_field =~ /^\s*(\w+)\s+\(([fr]_itrans)\)\s+\{\s*$/) {
            				$this_table = $1;
            				$this_table_type = $2;
            			} elsif ($this_field =~/^\s*values\s*\(\s*\"(.*)\"\s*\)\s*\;\s*$/) {
            				$thevalues = $1 ;
            			}
            		}		    
            		my @thevalues	= split (",",$thevalues);
					my $arraySize	= @thevalues;
            		my $arrayMiddle = int(($arraySize/2)+($arraySize%2)-1);				            		
            		$timingdata->{$this_table} = $thevalues[$arrayMiddle];
#					print CSVFILE "$pin_name $related_pin $timing_type $timing_sense $min_delay_flag $cell_rise $cell_fall $rise_constraint $fall_constraint $arr_index1[2] $arr_index2[2]\n";
            		$timingdata->{"OTHER_THING"} = $thevalues[$arrayMiddle];
				}
#				make sure the first four exist, if not then give the value none
        		if ($pin_name eq "")    { $pin_name    = "none"; }
        		if ($direction eq "")   { $direction   = "none"; }
        		if ($pincap eq "")      { $pincap	   = "none"; }
        		if ($related_pin eq "") { $related_pin = "none"; } 
				if ($timing_type eq "") { $timing_type = "none"; }
        		$timing_count++;
			}
			if ($timing_count == 0) {
				##nh##print "\t\t$pin_name,$direction,$pincap,NoTiming,,,,,,,\n";
			}
		}
		my @pg_pins = $parser->get_groups_by_type($cell_group, "pg_pin");
    	foreach my $pg_pin (@pg_pins) {
			my $pin_name = $parser->get_group_name($pg_pin);
        	my $pg_type = $parser->get_simple_attr_value($pg_pin, "pg_type");
        	my $pg_dir = StdDir($parser->get_simple_attr_value($pg_pin, "direction"));
    	}
		my @buses = $parser->get_groups_by_type($cell_group, "bus");
		foreach my $bus (sort @buses) {
			my $bus_name = $parser->get_group_name($bus);
			my $direction = StdDir($parser->get_simple_attr_value($bus, "direction"));
			my $related_power = $parser->get_simple_attr_value($bus, "related_power_pin");
			my $related_ground = $parser->get_simple_attr_value($bus, "related_ground_pin");
			my $bus_type = $parser->get_simple_attr_value($bus, "bus_type");
			my $buscap = GetValueFromPair($parser->get_attr_with_value($bus, "capacitance"));  ## Not sure this is ever used.
			my $bus_max_capacitance = defineWithDefault($default_max_capacitance, GetValueFromPair($parser->get_attr_with_value($bus, "max_capacitance")));
			my $bus_max_transition = defineWithDefault($default_max_transition, GetValueFromPair($parser->get_attr_with_value($bus, "max_transition")));
			my $g = $parser->locate_group($library_group, $bus_type);
			my $bit_width = $parser->get_attr_with_value($g, "bit_width");
			my $bit_from = $parser->get_attr_with_value($g, "bit_from");
			my $bit_to = $parser->get_attr_with_value($g, "bit_to");
			$bit_width = GetValueFromPair($bit_width);
			$bit_from = GetValueFromPair($bit_from);
			$bit_to = GetValueFromPair($bit_to);
			my @buspins = $parser->get_groups_by_type($bus, "pin");
			my $bustimings = $parser->get_groups_by_type($bus, "timing");
			my $pin_name = $parser->get_group_name($bus);
			my @timings = $parser->get_groups_by_type($bus, "timing");
			my $theBusName = "$bus_name\[$bit_from:$bit_to\]";
			my $Nbuspins = @buspins;
			foreach my $pin (sort @buspins) {
		 	   my $timing_count = 0;
		 	   my $pin_name = $parser->get_group_name($pin);
		    	if ($pin_name =~ m/^$bus_name[\[<]/) {
					##  Process any bus-nested pin statements.
					my $direction = StdDir($parser->get_simple_attr_value($pin, "direction"));
					my $related_power = $parser->get_simple_attr_value($pin, "related_power_pin");
					my $related_ground = $parser->get_simple_attr_value($pin, "related_ground_pin");
					my $pincap = GetValueFromPair($parser->get_attr_with_value($pin, "capacitance"));
					#my $pintimings = GetTiming($parser, $pin);
					my $pin_name = $parser->get_group_name($pin);
					my @timings = $parser->get_groups_by_type($pin, "timing");
					my $max_capacitance = defineWithDefault($bus_max_capacitance, GetValueFromPair($parser->get_attr_with_value($pin, "max_capacitance")));
					my $max_transition = defineWithDefault($bus_max_transition, GetValueFromPair($parser->get_attr_with_value($pin, "max_transition")));	        
					$pinInfo->{$pin_name}{direction}=$direction;
					$pinInfo->{$pin_name}{pincap}=$pincap;
					$pinInfo->{$pin_name}{related_power}=$related_power;	
					$pinInfo->{$pin_name}{related_ground}=$related_ground;
					$pinInfo->{$pin_name}{max_capacitance}=$max_capacitance;
					$pinInfo->{$pin_name}{max_transition}=$max_transition;	
					foreach my $timing (@timings) {
					    my $related_pin = $parser->get_simple_attr_value($timing, "related_pin");
					    my $timing_type = $parser->get_simple_attr_value($timing, "timing_type");
						
						my $timing_sense   = $parser->get_simple_attr_value($timing, "timing_sense");	    
						$timing_sense = "N/A" if (! $timing_sense );		    
					    my $min_delay_flag   = $parser->get_attr_with_value($timing, "min_delay_flag");	    	    
					    if ($min_delay_flag =~ /true/ ) { 
					        $min_delay_flag = "True";
					    } else { 
					        $min_delay_flag = "False";	    
					    }        		    
					    if ($timing_type eq "min_pulse_width" || 
							$timing_type eq "minimum_period"  || 
							$timing_type eq "max_clock_tree_path" ||
							$timing_type eq "min_clock_tree_path" ) {
							next ;
					    }            		    
					    my @arc_types = ( "rise_constraint" , "fall_constraint" , "cell_rise" , "cell_fall" , "rise_transition" , "fall_transition" );
					    my $cur_arc;
					    foreach my $arc_type ( @arc_types ) { 
						    $cur_arc = $parser->locate_group_by_type($timing, $arc_type);
						    last if ($cur_arc != 0);
					    }				    
#						print "$timing_type\n";
					    my @arr_index1 = $parser->get_lookup_table_index_1($cur_arc);
					    my @arr_index2 = $parser->get_lookup_table_index_2($cur_arc);		
					    my $string_index1 = join ("," , @arr_index1 );
					    my $string_index2 = join ("," , @arr_index2 );		
					    $string_index1 = "{${string_index1}}";
					    $string_index2 = "{${string_index2}}";		            		
					    $timingdata->{"index1"} = $string_index1;
					    $timingdata->{"index2"} = $string_index2;		    
					    $timingdata->{"rise_constraint"} = createString($parser->get_lookup_table_array($timing, "rise_constraint"));
					    $timingdata->{"fall_constraint"} = createString($parser->get_lookup_table_array($timing, "fall_constraint"));
					    $timingdata->{"cell_rise"}       = createString($parser->get_lookup_table_array($timing, "cell_rise"));
					    $timingdata->{"cell_fall"}       = createString($parser->get_lookup_table_array($timing, "cell_fall"));
					    $timingdata->{"rise_transition"} = createString($parser->get_lookup_table_array($timing, "rise_transition"));
					    $timingdata->{"fall_transition"} = createString($parser->get_lookup_table_array($timing, "fall_transition"));
					    #make sure the first four exist, if not then give the value none
					    if ($pin_name eq "")    { $pin_name    = "none"; }
					    if ($direction eq "")   { $direction   = "none"; }
					    if ($pincap eq "")      { $pincap	   = "none"; }
					    if ($related_pin eq "") { $related_pin = "none"; } 
					    if ($timing_type eq "") { $timing_type = "none"; }
						$timingscalar->{"rise_constraint"} = find_centre_value($parser->get_lookup_table_array($timing, "rise_constraint"));
						$timingscalar->{"rise_transition"} = find_centre_value($parser->get_lookup_table_array($timing, "rise_transition"));
						$timingscalar->{"cell_rise"} = 		 find_centre_value($parser->get_lookup_table_array($timing, "cell_rise"));
						$timingscalar->{"fall_constraint"}	 = find_centre_value($parser->get_lookup_table_array($timing, "fall_constraint"));
						$timingscalar->{"fall_transition"} = find_centre_value($parser->get_lookup_table_array($timing, "fall_transition"));
						$timingscalar->{"cell_fall"}	 = find_centre_value($parser->get_lookup_table_array($timing, "cell_fall"));
						my $rise_constraint = $timingscalar->{"rise_constraint"};
						my $fall_constraint = $timingscalar->{"fall_constraint"};
						my $cell_rise = $timingscalar->{"cell_rise"};
						my $cell_fall = $timingscalar->{"cell_fall"};
						my $rise_transition = $timingscalar->{"rise_transition"};
						my $fall_transition = $timingscalar->{"fall_transition"};
						if($direction eq "output") {
						$arr_index2[2] = $arr_index2[2] - $pincap;
	#					print "$pincap $arr_index2[2]\n";
						}
						if($timing_type =~ /hold/ || $timing_type =~ /setup/) {
						$input_transition = $arr_index2[2];
						} else {
						$input_transition = $arr_index1[2];
						}
#						print CSVPINFILE "$timing_type sneha $cell_rise $cell_fall $rise_constraint $fall_constraint\n";
						push @CSVFILE, "$pin_name,$related_pin,$timing_type,$timing_sense,$min_delay_flag,$direction,$cell_rise,$cell_fall,$rise_constraint,$fall_constraint,$rise_transition,$fall_transition,$arr_index1[2],$arr_index2[2],$pincap,$input_transition,$default_operating_conditions,$voltage,$temperature\n";
		            	$timing_count++;
		            }		    
		            if ($timing_count == 0) {
		            	##nh##print "\t\t$pin_name,$direction,$pincap,NoTiming,,,,,,,\n";
		            }
				} else {
					eprint "ERROR: Pin $pin_name of bus $bus_name has name mismatch\n";
				}
			}
		}
		push  @CSVFILE, "\nNotes:-\n";
		push  @CSVFILE, "For setup/hold arcs, index1 and index2 are transition of constrained pin and related pin respectively\n";
		push  @CSVFILE, "For all other arcs, index1 is related pin transition and index2 is output load\n";
		push  @CSVFILE, "Input transition is 20% to 80%\n";
		push  @CSVFILE, "Extraction conditions for timing -\n";
		push  @CSVFILE, "1) REDUCTION: YES\n";
		push  @CSVFILE, "2) TEMP_SENSITIVITY: NO\n";
		push  @CSVFILE, "3) RCC Typical DEVICE LAYERS NON DEVICE LAYERS CONLY\n";
        my $write_status = write_file(\@CSVFILE,$csvFile);		
#    	close (CSVPINFILE);    
	}

sub usage() {
    my $code = shift||0;
    my $USAGE = <<EOusage;

    Script to compare timing arc of specified lib files.
    ref: reference lib file to be compared with. 
    cur: lib file of current release. 
    cell: the cell name which is compared.
    csv : flag to generate output csv report.
    merge : flag to turn on/turn off min_delay and timing sense.
	arc : filters only necessary arcs
    
	  CSV report as well as arc comparison will contain full list of possible arcs, no matter the specified sdf condition list.
	  

    Usage: timing_status.pl [-h|-help]

    -h or -help  this help message
    -ref 
    -cur
    -cell
    -csv
    -ui
    -merge
    -arc
    example of usage:
    Run Example:/remote/us01home57/snehar/timing/libedit/delay_based_merge.pl -lib <path>/mindelaylibdir1/<macro>_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_<corner>_pg.lib -cur <path>/mindelaylibdir2/<macro>_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_<corner>_pg.lib -arc /remote/us01home57/snehar/timing/libedit/arctest.txt -csv -merge -cell <macro>
EOusage

    print $USAGE;
    exit 0;
    
}

sub process_cmd_line_args() {
	my ( $opt_help, $opt_lib1, $opt_metalstack,
	     $opt_cellName, $opt_corner, $opt_macro, $opt_lib_path,
		 $opt_output_dir, $opt_localpath,$opt_debug,  $opt_verbosity ) = "";
	my $success = GetOptions( 
		        "help|h"          => \$opt_help,
     		    "lib=s"           => \$opt_lib1,
				"metalstack=s"    => \$opt_metalstack,
     		    "cell=s"	      => \$opt_cellName,
				"corner=s"        => \$opt_corner,
				"macro=s"         => \$opt_macro,
				"libpath=s"       => \$opt_lib_path,
				"outDir=s"        => \$opt_output_dir,
				"localpath=s"     => \$opt_localpath,
				"verbosity=i"     => \$opt_verbosity,
				"debug=i"         => \$opt_debug

                );
	$main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
 	if(!$opt_output_dir) {
		$opt_output_dir = "csvfiles";
    }
	&usage(0) if $opt_help;
	&usage(1) unless($success);
	return($opt_help, $opt_lib1, $opt_metalstack,
	     $opt_cellName, $opt_corner, $opt_macro, $opt_lib_path,
		 $opt_output_dir, $opt_localpath);
    

}
