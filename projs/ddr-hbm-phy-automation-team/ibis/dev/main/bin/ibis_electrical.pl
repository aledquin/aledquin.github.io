#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : ibis_electrical.pl
# Author  : Harsimrat Singh Wadhawan
# Date    : 12 Jan, 2022
# Purpose : Check IBIS model files' electrical values.
#
# Modification History
#     XXX Harsimrat Singh Wadhawan, 2022-07-13 11:35:19
#         Adding Perl Standard Template header. 
#     
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
use Cwd     qw( abs_path getcwd );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Scalar::Util qw (looks_like_number );

# --INCLUDES ----------------------#
use lib "$FindBin::Bin/../lib/perl";

use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DS;
# use utilities;
use ibis;
use QA;
#----------------------------------#

#---- GLOBAL VARs------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $PROGRAM_NAME = $RealScript;
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $THRESHOLD = 10;
our $RTT = 50;
our $VERSION = get_release_version();

our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";

#----------------------------------#

# Set project parameters
my ( $family, $project, $macro, $release, $customDepotPath, $depotPath );
my ( $success, $help, $nocosim, $macro_arg, $debug, $project_string, $cornerTol, $minTolerance, $maxTolerance );

# Variables for parsing and storing data from IBIS files.
# TODO: Remove global variables and move them to Main
my ( @file_name_non_clipped, @file_name_clipped, @file_arr);
my ( @current_model_data, %all_clipped_pulldown_data, %all_non_clipped_pulldown_data, %all_non_clipped_pullup_data, %voltage_range_non_clipped, %voltage_range_pullup_non_clipped);
my ( %clipped_files, %non_clipped_files );
my ( %pulldown_impedances, %pullup_impedances );
my ( %all_vfixture_data, %all_rising_VDD_half_data, %all_rising_VDD_2_data, %all_rising_0_2_data, %all_falling_VDD_half_data, %all_falling_VDD_2_data);
my ( %all_non_clipped_PowerClamp_data, %all_non_clipped_GNDClamp_data );
my ( %PowerClamp_impedances, %GNDClamp_impedances );
my ( $found_odtmodel );

# =============================
# MAIN
# =============================

sub Main {

	my ($severities, $minTolerance, $maxTolerance, $cornerTol) = initialise_script();

	# ===================================================================================================================== #
	# PARSE SEVERITIES FILE
	# ===================================================================================================================== #

	parse_severities($severities);

	# ===================================================================================================================== #
	# LOAD DATA
	# ===================================================================================================================== #

	# Load waveform data
	load_ibis_models();
	
	# ===================================================================================================================== #
	# DO THE CHECKS
	# ===================================================================================================================== #

	hprint ("Checking Pull Down Values.\n");
	check_pulldown_driving_impedance($minTolerance, $maxTolerance, $cornerTol);	

	hprint ("Checking Pull Up Values.\n");
	check_pullup_driving_impedance($minTolerance, $maxTolerance, $cornerTol);	
	
	get_rising_falling_wavefroms();
	hprint ("Doing Voh Checks.\n");
	voh_check();

	hprint ("Doing Vol Checks.\n");
	vol_check();
	
	hprint ("Checking Power Clamp ODT Values.\n");
	ODT_check_PowerClamp_waveform($minTolerance, $maxTolerance, $cornerTol);

	hprint ("Checking Ground Clamp ODT Values.\n");
	ODT_check_GNDClamp_waveform($minTolerance, $maxTolerance, $cornerTol);	
	
}

# =============================
# UTILITIES
# =============================

# Get options and initalise neessary variables for locating files.
sub initialise_script {

	my $severities = NULL_VAL;

	## get specified args
	$success = GetOptions(
		"help!"   => \$help,
		"macro=s" => \$macro_arg,		
		"proj=s"  => \$project_string,		
		"d=s" => \$DEBUG,
		"depotPath=s" => \$customDepotPath,
		"slow=i" => \$minTolerance,
		"fast=i" => \$maxTolerance,
		"tol=i" => \$cornerTol,
		"typ=i" => \$THRESHOLD,
		"severity=s" => \$severities
	);

	&usage if ( ! $macro_arg);
	&usage if ( ! $project_string);
	&usage if $help;

	if (defined $minTolerance && defined $maxTolerance && !defined $cornerTol){
		fatal_error("When using -min and -max, -tol must also be defined");
	} elsif ((defined $minTolerance && !defined $maxTolerance) || (!defined $minTolerance && defined $maxTolerance)) {
		fatal_error("Both -max and -min must be defined. If using one, set the other to 0");
	}

	#extract project type, path and release
	if ( $project_string =~ /^([^\/]+)\/([^\/]+)\/([^\/]+)$/ ) {
		$family = $1;
		$project = $2;
		$release = $3;
		$macro = $macro_arg;
	}

	if ($family eq 'lpddr5x') {
		$family = "lpddr5x_ddr5_phy/lp5x";
	} elsif ($family eq 'ddr5'){
       $family = "lpddr5x_ddr5_phy/$family";
    }

	#Set the depot path for the ibis folder
	$depotPath = "//depot/products/$family/project/$project/ckt/rel/$macro/$release/macro/ibis";

	if ($customDepotPath) {
		$depotPath = "$customDepotPath/ckt/rel/$macro/$release/macro/ibis";	
	}

	dprint LOW, "Debugger setting: $DEBUG\n";
	dprint LOW, "The depot path is: $depotPath.\n";
	dprint MEDIUM, "$family $project $release $macro\n";

	return $severities, $minTolerance, $maxTolerance, $cornerTol;
}

# Remove extra bits at the end
sub remove_trails {

	my $file_arr = $_[0];
	my $array_to_push = $_[1];
	my $type = $_[2];

	my $clip = "$type/";
	foreach (@$file_arr){
		my $p = index($_,$clip) + length $clip;
		my $p2 = index($_, "#");
		my $s = substr($_,$p);
		$s = substr($s,0,$p2-$p);

		#now all clipped files are in this array	
		push(@$array_to_push,$s);		
	}
	return @file_arr;	

}

# Get impedance from model name
sub get_impedance_from_model_name {

	my $model_name = shift;
	my $minTolerance = shift;
	my $maxTolerance = shift;
	my @last_value;	

	# remove the _tcl suffix if it exists
	$model_name =~ s/_tcl//ig;

	#split the model name by'_''
	my @model_split = split /_/, $model_name;

	# get the last part of the name since it usually contains a number
	my $last_value = $model_split[@model_split-1];		

	# odtoff means that the On Die Termination is essentially an open circuit. (very large impedance)
	if($last_value =~ /odtoff/){
	
	    my $last_value_off = odtoffConstant;
		if (defined $minTolerance && defined $maxTolerance) {
			push(@last_value, odtoffConstant);
			push(@last_value, odtoffConstant);
			push(@last_value, odtoffConstant);
			return @last_value;
		}

	    return $last_value_off;
	    
	}
		
	elsif($last_value =~ /odt/){
	
	    $last_value =~ s/[^0-9]//g;	
	    if (looks_like_number $last_value ){
		  	if (defined $minTolerance && defined $maxTolerance) {
				my $minExpected = ($last_value+($last_value*($minTolerance/100)));
				my $maxExpected = ($last_value-($last_value*($maxTolerance/100)));
				push(@last_value, $last_value);
				push(@last_value, $minExpected);
				push(@last_value, $maxExpected);
				return @last_value;
			}
		  return $last_value;

	    }
	
	}
	
	#Usually the last part of the model name is a number. example: tx_outdrv_d5b_'60'
	elsif (looks_like_number $last_value ){
		if (defined $minTolerance && defined $maxTolerance){
			my $minExpected = ($last_value+($last_value*($minTolerance/100)));
			my $maxExpected = ($last_value-($last_value*($maxTolerance/100)));
			push(@last_value, $last_value);
			push(@last_value, $minExpected);
			push(@last_value, $maxExpected);
			return @last_value;
		}

		return $last_value;

	}

	# if all else fails loop through all the parts of the name and find a number
	else {

		my $candidate = NULL_VAL;

		foreach my $key (@model_split) {

			if ( looks_like_number $key ) {
				if (defined $minTolerance && defined $maxTolerance){
					my $minExpected = ($key+($key*($minTolerance/100)));
					my $maxExpected = ($key-($key*($maxTolerance/100)));
					push($key, @last_value);
					push($minExpected, @last_value);
					push($maxExpected, @last_value);
					return @last_value;
				}
				$candidate = $key
			}

		}

		# Search unsuccessful
		if ($candidate eq NULL_VAL) {
			return -1 * odtoffConstant;
		}

		else {
			return $candidate;
		}

	}
	

}

# Neatly dump the data into the log file
sub dump_models {

	my $model_list_reference = shift;
	my %model_list = %{$model_list_reference};

	my $voltage_list_reference = shift;
	my %voltage_list = %{$voltage_list_reference};

	my $minTolerance 		 = shift;
	my $maxTolerance 		 = shift;

	my $string;

	foreach my $file (sort keys %model_list) {					
			
		my $first=TRUE;

		logger "$file\n";
		foreach my $model ( @{$model_list{"$file"}} ) {

			my %model_info = %{$model};
			my $model_name = $model_info{"model"};

			if ($first) {
				my %current_voltage_range_hash = %{$voltage_list{"$file"}};
				my @voltage_array = @{$current_voltage_range_hash{"$model_name"}};
				$string = sprintf "%-20s %-10s %-10s, %-10s, %-10s\n", "Voltage Range (V)", "Expected", $voltage_array[0], $voltage_array[1], $voltage_array[2];
				logger($string);
				$first=FALSE;
			}
			if (defined $minTolerance && defined $maxTolerance) {
				my @expected_resistance = get_impedance_from_model_name ($model_name, $minTolerance, $maxTolerance);
				$string = sprintf "%-20s %-10s %-10.2f, %-10.2f, %-10.2f\n", $model_name, "(@expected_resistance)", $model_info{"resistance_typical"}, $model_info{"resistance_min"}, $model_info{"resistance_max"};
			} else {
				my $expected_resistance = get_impedance_from_model_name $model_name;
				$string = sprintf "%-20s %-10s %-10.2f, %-10.2f, %-10.2f\n", $model_name, "($expected_resistance)", $model_info{"resistance_typical"}, $model_info{"resistance_min"}, $model_info{"resistance_max"};
			}
			logger($string);
		}

	}


}

# Filter out which models are failing their impedance measurements
sub filter_models {

	my $hash_ref 	 = shift;
	my $minTolerance = shift;
	my $maxTolerance = shift;
	my $cornerTol 	 = shift;

	my ($model_impedance, @model_impedance, $answer_typical, $answer_min, $answer_max);

	my %hash =  %{$hash_ref};

	my %failing_models;	
	my %passing_models;
	
	foreach my $file ( keys %hash ) {
		
		foreach my $model ( keys %{$hash{"$file"}} ) {			
			
			if (defined $minTolerance && defined $maxTolerance) {
				@model_impedance = get_impedance_from_model_name ($model, $minTolerance, $maxTolerance);
			} else {
				$model_impedance = get_impedance_from_model_name ($model);	
			}
			
			my %combined_hash = %{${$hash{"$file"}}{"$model"}};
			my @resistance_array = @{$combined_hash{"resistances"}};
			my @current_array = @{$combined_hash{"currents"}};
			my @voltage_array = @{$combined_hash{"voltages"}};

			my $resistance_typical = $resistance_array[0];
			my $resistance_min = $resistance_array[1];
			my $resistance_max = $resistance_array[2];

			my $c_t = $current_array[0];
			my $c_min = $current_array[1];
			my $c_max = $current_array[2];

			my $v_t = $voltage_array[0];
			my $v_min = $voltage_array[1];
			my $v_max = $voltage_array[2];

			if (defined $minTolerance && defined $maxTolerance) {
				$answer_typical = verify $THRESHOLD, $model_impedance[0], $resistance_typical;			
				$answer_min = verify $cornerTol, $model_impedance[1], $resistance_min;			
				$answer_max = verify $cornerTol, $model_impedance[2], $resistance_max;			
			} else {
				$answer_typical = verify $THRESHOLD, $model_impedance, $resistance_typical;			
				$answer_min = verify $THRESHOLD, $model_impedance, $resistance_min;			
				$answer_max = verify $THRESHOLD, $model_impedance, $resistance_max;
			}
			
			my %model_data = (
				'model' => $model, 
				'resistance_typical' => $resistance_typical, 
				'resistance_min' => $resistance_min, 
				'resistance_max' => $resistance_max,
				'current_max' => $c_max,
				'current_typical' => $c_t,
				'current_min' => $c_min,
				'voltage_typical' => $v_t,
				'voltage_min' => $v_min,
				'voltage_max' => $v_max,
			);

			if (! $answer_typical || ! $answer_max || ! $answer_min) {
				insert_at_key(\%failing_models, $file, \%model_data); 
			}

			else {
				insert_at_key(\%passing_models, $file, \%model_data); 
			}

		}

	}	

	return (\%passing_models, \%failing_models);

}

# Obtain time from a given number
# TODO: replace with Util::get_number
sub get_time {

	my $input = shift;
	my $answer = $input;

	$answer =~ s/[^0-9.-]//g;

	if($input =~ /ps/) {
		return $answer / 1000;
	}

	return $answer;
}

# Obtain voltage value from a given number
# TODO: replace with Util::get_number
sub get_vfixture {

	my $input = shift;
	my $answer = $input;
	my @check = split('=', $input);

	$answer =~ s/[^0-9.-]//g;

	if($check[1] =~ /m/) {
		return $answer / 1000;
	}

	return $answer;
}

# Obtain type information from a voltage value
sub get_type {

	my $input = shift;
	my $curr_type;

	if($input == 0) {
		$curr_type = "Typ";
	} elsif ($input == 1) {
		$curr_type = "Min";
	} else {
		$curr_type = "Max";
	}

	return $curr_type;
}

# =============================
# DATA COLLECTION FUNCTIONS
# =============================

# Get all file contents at once
sub get_file_contents {

  for (my $i = 0 ; $i < @file_name_clipped; $i++){
  
    my ($file, $stderr, $return) = run_system_cmd("p4 print -q $depotPath/clipped/$file_name_clipped[$i]", NONE);
    my @result = split ('\n', $file);
    $clipped_files{"$file_name_clipped[$i]"} = \@result;    
  }
  
  for (my $i = 0 ; $i < @file_name_clipped; $i++){
  
    my ($file, $stderr, $return) = run_system_cmd("p4 print -q $depotPath/non_clipped/$file_name_non_clipped[$i]", NONE);
    my @result = split ('\n', $file);  
    $non_clipped_files{"$file_name_non_clipped[$i]"} = \@result;    
  
  }       
  
}

# Get a list of IBIS model files.
sub load_ibis_models {
	
	#get the names of all the files in the ibis clipped folder	
	my ($files, $stderr, $return) = run_system_cmd("p4 files -e $depotPath/clipped/*", NONE);	
	@file_arr = split ('\n', $files);
	if (!scalar(@file_arr))	{
		alert 0, "Could not find files. Exiting.";
		exit;
	}
	@file_arr = remove_trails \@file_arr, \@file_name_clipped, "clipped";	

	#get all the names of files in the non clipped folder
	($files, $stderr, $return) = run_system_cmd("p4 files -e $depotPath/non_clipped/*", NONE);
	@file_arr = split ('\n', $files);
	if (!scalar(@file_arr))	{
		alert 0, "Could not find files. Exiting.";
		exit;
	}	
	@file_arr = remove_trails \@file_arr, \@file_name_non_clipped, "non_clipped";

	my $clipped_count = @file_name_clipped;
	my $non_clipped_count = @file_name_non_clipped;

	#log results
	logger ("Found $clipped_count ibis files in clipped folder\n\n");
	logger ("Found $non_clipped_count ibis files in non_clipped folder\n\n");

	#if the number of clipped and non clipped files must match, otherwise the QA will not run
	if($clipped_count != $non_clipped_count){
		alert 0 , "Number of files in clipped and non_clipped folders is not equal. Exiting." ;
		exit;
	}
	else {			
		get_file_contents();
	}

}

# =============================
# DATA PARSING FUNCTIONS
# =============================

# parse the rising and failling waveforms
sub get_rising_falling_wavefroms {

	for (my $i = 0; $i < @file_name_non_clipped; $i++) {

		my @array = @{$non_clipped_files{"$file_name_non_clipped[$i]"}};
		
		my %current_vfixture_data;
		my %current_rising_VDD_half_data;
		my %current_rising_VDD_2_data;
		my %current_rising_0_2_data;
		my %current_falling_VDD_half_data;
		my %current_falling_VDD_2_data;
		my $current_model;	   
		my $model_found = 0;

		my $start_parsing_rising = 0;  
		my $start_parsing_falling = 0;
		my $curr_vfixture = -1;
		my $start_parsing_rising_VDD = 0;
		my $start_parsing_rising_0 = 0;

		for (my $j = 0 ; $j < @array; $j++) {
	
			my $line = $array[$j]; 

			if ($model_found == 0 and $line =~ /\[model\]/i) {	

				$current_model = (split /\s+/, $line)[1];
				if (!scalar $current_model) {
					alert 0, "Model name not found. Line $j.\n";
				}
				else {
					$model_found = 1;
				}
		  	}	

			elsif ($model_found == 1 and $line =~ /\[Rising waveform\]/i) {
			 	$start_parsing_rising = 1; 	  
		  	}

			elsif ($start_parsing_rising == 1 and $line =~ /V_fixture=/i) {
				($curr_vfixture) = ($line =~ /(\d+)/);

				if ($curr_vfixture != 0) {
					(my $typ) = get_vfixture $line;
					(my $min) = get_vfixture $array[$j + 1];
					(my $max) = get_vfixture $array[$j + 2]; 

					$current_vfixture_data{"$current_model"} = [$typ, $min, $max];
					$start_parsing_rising_VDD = 1;
				} else {
					$start_parsing_rising_0 = 1;
				}

			} 
			
			elsif ($start_parsing_rising_VDD == 1 and ($line =~ /ps/ or $line =~ /ns/)) {

				my @numbers = split /\s+/, trim $line;
				my $prev = get_time $numbers[0];
				my $parsing_half = 1;
				my $parsing_2 = 0;

				for (my $k = $j + 1; $k < @array; $k++) {
					my $curr_line = $array[$k];
					my @curr_numbers = split /\s+/, trim $curr_line; 

					if (@curr_numbers != 4){
						# Skip any line less than 4 items
						next;
					}

					my $curr_time = get_time $curr_numbers[0];		

					if($parsing_half == 1) {
						if(abs($curr_time - 0.5) < abs($prev - 0.5)){
							$prev = $curr_time;
							@numbers = @curr_numbers;
						} else {
							my $typ = get_number $numbers[1];
							my $min = get_number $numbers[2];
							my $max = get_number $numbers[3];

							$current_rising_VDD_half_data{"$current_model"} = [$typ, $min, $max];
							$parsing_half = 0;
							$parsing_2 = 1;
						}
					} elsif($parsing_2 == 1) {
				
							if(abs($curr_time - 2) < abs($prev - 2)) {
							$prev = $curr_time;
							@numbers = @curr_numbers;			
						} else {
							my $typ = get_number $numbers[1];
							my $min = get_number $numbers[2];
							my $max = get_number $numbers[3];

							$current_rising_VDD_2_data{"$current_model"} = [$typ, $min, $max];
							$start_parsing_rising_VDD = 0;
							$j = $k + 1;
							last;
						}
					}
				}

			}

			elsif ($start_parsing_rising_0 == 1 and ($line =~ /ps/ or $line =~ /ns/)) {

				my @numbers = split /\s+/, trim $line;
				my $prev = get_time $numbers[0];

				for (my $k = $j + 1; $k < @array; $k++) {
					my $curr_line = $array[$k];
					my @curr_numbers = split /\s+/, trim $curr_line; 
					my $curr_time = get_time $curr_numbers[0];		

					if (@curr_numbers != 4){
						# Skip any line less than 4 items
						next;
					}

					if(abs($curr_time - 2) < abs($prev - 2)){
						$prev = $curr_time;
						@numbers = @curr_numbers;
					} else {
						my $typ = get_number $numbers[1];
						my $min = get_number $numbers[2];
						my $max = get_number $numbers[3];

						$current_rising_0_2_data{"$current_model"} = [$typ, $min, $max];
						$start_parsing_rising_0 = 0;
						$curr_vfixture = -1;
						$start_parsing_rising = 0;
						last; 		
					}
				}	
			}

			elsif ($model_found == 1 and $line =~ /\[Falling waveform\]/i) {
			 	$start_parsing_falling = 1; 	  
		  	}

			elsif ($start_parsing_falling == 1 and $line =~ /V_fixture=1/i) {
				($curr_vfixture) = ($line =~ /(\d+)/);
			} 

			elsif ($start_parsing_falling == 1 and $curr_vfixture != 0 and ($line =~ /ps/ or $line =~ /ns/)) {

				my @numbers = split /\s+/, trim $line;
				my $prev = get_time $numbers[0];
				my $parsing_half = 1;
				my $parsing_2 = 0;

				for (my $k = $j + 1; $k < @array; $k++) {
					my $curr_line = $array[$k];
					my @curr_numbers = split /\s+/, trim $curr_line; 
					my $curr_time = get_time $curr_numbers[0];		

					if (@curr_numbers != 4){
						# Skip any line less than 4 items
						next;
					}

					if($parsing_half == 1) {
						if(abs($curr_time - 0.5) < abs($prev - 0.5)){
							$prev = $curr_time;
							@numbers = @curr_numbers;
						} else {
							my $typ = get_number $numbers[1];
							my $min = get_number $numbers[2];
							my $max = get_number $numbers[3];

							$current_falling_VDD_half_data{"$current_model"} = [$typ, $min, $max];
							$parsing_half = 0;
							$parsing_2 = 1;
						}
					} elsif($parsing_2 == 1) {
				
							if(abs($curr_time - 2) < abs($prev - 2)) {
							$prev = $curr_time;
							@numbers = @curr_numbers;			
						} else {
							my $typ = get_number $numbers[1];
							my $min = get_number $numbers[2];
							my $max = get_number $numbers[3];

							$current_falling_VDD_2_data{"$current_model"} = [$typ, $min, $max];
							$start_parsing_falling = 0;
							$curr_vfixture = -1;
							$model_found = 0;
							$j = $k + 1;
							last;
						}
					}
				}
			}
		}

		$all_rising_VDD_2_data{"$file_name_non_clipped[$i]"} = \%current_rising_VDD_2_data;	
		$all_rising_VDD_half_data{"$file_name_non_clipped[$i]"} = \%current_rising_VDD_half_data;	
		$all_rising_0_2_data{"$file_name_non_clipped[$i]"} = \%current_rising_0_2_data;	
		$all_falling_VDD_2_data{"$file_name_non_clipped[$i]"} = \%current_falling_VDD_2_data;	
		$all_falling_VDD_half_data{"$file_name_non_clipped[$i]"} = \%current_falling_VDD_half_data;	
		$all_vfixture_data{"$file_name_non_clipped[$i]"} = \%current_vfixture_data;	
	}

}

# parse pull down waveform data
sub get_non_clipped_pulldown_waveform {
  
    for (my $i = 0; $i < @file_name_non_clipped; $i++) {
	
		my %all_pulldown_data;
		my %current_voltage_range;
		my $current_model;	
		my @array = @{$non_clipped_files{"$file_name_non_clipped[$i]"}};  
		my $model_found = 0;
		my $start_parsing_pulldown = 0;
		
		for (my $j = 0 ; $j < @array; $j++) {
		
			my $line = $array[$j];      
			
			if ( $model_found == 0 and $line =~ /\[model\]/i) {	  	  
				$current_model = (split /\s+/, $line)[1];
				if (!scalar $current_model){
					alert 0, "Model name not found. Line $j.\n";
				}
				else {
					$model_found = 1;
				}
			}			 
			
			elsif ($model_found and $line =~ /\[pulldown\]/i) {
				$start_parsing_pulldown = 1; 	  
			}		 		  
			
			elsif ($model_found and $line =~ /\[voltage range\]/i) {			

				my @array_vr = split /\s+/, $line;
				
				if (@array_vr != 5) {
					eprint "Error VR measurement.\n";
				}
				
				else {
					my $vtyp = $array_vr[2];
					my $vmin = $array_vr[3];
					my $vmax = $array_vr[4];
					$current_voltage_range{"$current_model"} = [$vtyp, $vmin, $vmax];
				}

			}
			
			elsif ($model_found and $line =~ /.*\|.*-+.*/i and not scalar @current_model_data) {			    
					#alert 2, "Pull down values for $current_model not found.";
					$model_found = 0;
					$start_parsing_pulldown = 0; 	  
					$all_pulldown_data{"$current_model"} = [@current_model_data];				
					@current_model_data = ();			
			}

			elsif ($start_parsing_pulldown){
				if ($line =~ /.*\|.*/i) {				
					$model_found = 0;
					$start_parsing_pulldown = 0; 	  
					$all_pulldown_data{"$current_model"} = [@current_model_data];				
					@current_model_data = ();
				}			
				else {
					my @numbers = split /\s+/, trim $line;
					if (scalar @numbers != 4) {
						alert 2, "Extra content found.\n";
					}	
					else {
						my $voltage = get_number $numbers[0];
						my $current1 = get_number $numbers[1];
						my $current2 = get_number $numbers[2];
						my $current3 = get_number $numbers[3];
						push @current_model_data, [$voltage, $current1, $current2, $current3];
					}		
				}
			}

		}
			
		$all_non_clipped_pulldown_data{"$file_name_non_clipped[$i]"} = \%all_pulldown_data;	  
		$voltage_range_non_clipped{"$file_name_non_clipped[$i]"} = \%current_voltage_range;
		
		if (scalar keys %all_pulldown_data != scalar keys %current_voltage_range)   {
		
			wprint "Different key counts.";	  	  
		
		}
	  
    }  
      
}

# parse pull up waveform data
sub get_non_clipped_pullup_waveform {
  
    for (my $i = 0; $i < @file_name_non_clipped; $i++) {
	
		my %all_pulldown_data;
		my %current_voltage_range;
		my $current_model;	
		my @array = @{$non_clipped_files{"$file_name_non_clipped[$i]"}};  
		my $model_found = 0;
		my $start_parsing_pulldown = 0;
		
		for (my $j = 0 ; $j < @array; $j++) {
		
			my $line = $array[$j];      
			
			if ( $model_found == 0 and $line =~ /\[model\]/i) {	  	  
				$current_model = (split /\s+/, $line)[1];
				if (!scalar $current_model){
					alert 0, "Model name not found. Line $j.\n";
				}
				else {
					$model_found = 1;
				}
			}			 
			
			elsif ($model_found and $line =~ /\[pullup\]/i) {
				$start_parsing_pulldown = 1; 	  
			}		 		  
			
			elsif ($model_found and $line =~ /\[voltage range\]/i) {			

				my @array_vr = split /\s+/, $line;
				
				if (@array_vr != 5) {
					eprint "Error VR measurement.\n";
				}
				
				else {
					my $vtyp = $array_vr[2];
					my $vmin = $array_vr[3];
					my $vmax = $array_vr[4];
					$current_voltage_range{"$current_model"} = [$vtyp, $vmin, $vmax];
				}

			}
			
			elsif ($model_found and $line =~ /.*\|.*-+.*/i and not scalar @current_model_data) {			    
					#alert 2, "Pull down values for $current_model not found.";
					$model_found = 0;
					$start_parsing_pulldown = 0; 	  
					$all_pulldown_data{"$current_model"} = [@current_model_data];				
					@current_model_data = ();			
			}

			elsif ($start_parsing_pulldown){			
				if ($line =~ /.*\|.*/i) {				
					$model_found = 0;
					$start_parsing_pulldown = 0; 	  
					$all_pulldown_data{"$current_model"} = [@current_model_data];				
					@current_model_data = ();
				}			
				else {
					my @numbers = split /\s+/, trim $line;
					if (scalar @numbers != 4) {
						wprint "Extra content found.\n";
					}	
					else {
						my $voltage = get_number $numbers[0];
						my $current1 = get_number $numbers[1];
						my $current2 = get_number $numbers[2];
						my $current3 = get_number $numbers[3];
						push @current_model_data, [$voltage, $current1, $current2, $current3];
					}		
				}
			}

		}
			
		$all_non_clipped_pullup_data{"$file_name_non_clipped[$i]"} = \%all_pulldown_data;	  		
		$voltage_range_pullup_non_clipped{"$file_name_non_clipped[$i]"} = \%current_voltage_range;		

		if (scalar keys %all_pulldown_data != scalar keys %current_voltage_range)   {		
			wprint "Different key counts.";	  	  		
		}
	  
    }  
      
}

# parse PowerClamp waveform data
sub get_non_clipped_PowerClamp_waveform {
  
    for (my $i = 0; $i < @file_name_non_clipped; $i++) {
	
		my %all_PowerClamp_data;
		my %current_voltage_range;
		my $current_model;	
		my @array = @{$non_clipped_files{"$file_name_non_clipped[$i]"}};  
		my $model_found = 0;
		my $start_parsing_PowerClamp = 0;
		
		for (my $j = 0 ; $j < @array; $j++) {
		
			my $line = $array[$j];      
			
			if ( $model_found == 0 and $line =~ /\[model\]/i) {	  	  
				$current_model = (split /\s+/, $line)[1];
				if (!scalar $current_model){
					alert 0, "Model name not found. Line $j.\n";
				}
				else {
					$model_found = 1;
				}
			}			 
			
			elsif ($model_found and $line =~ /\[Power Clamp\]/i) { 
				$start_parsing_PowerClamp = 1; 	  
			}		 		  
			
			elsif ($model_found and $line =~ /\[voltage range\]/i) {			

				my @array_vr = split /\s+/, $line;
				
				if (@array_vr != 5) {
					eprint "Error VR measurement.\n";
				}
				
				else {
					my $vtyp = $array_vr[2];
					my $vmin = $array_vr[3];
					my $vmax = $array_vr[4];
					$current_voltage_range{"$current_model"} = [$vtyp, $vmin, $vmax];
				}

			}
			
			elsif ($model_found and $line =~ /.*\|.*-+.*/i and not scalar @current_model_data) {			    
					#alert 2, "Pull down values for $current_model not found.";
					$model_found = 0;
					$start_parsing_PowerClamp = 0; 	  
					$all_PowerClamp_data{"$current_model"} = [@current_model_data];				
					@current_model_data = ();			
			}

			elsif ($start_parsing_PowerClamp){			
				if ($line =~ /.*\|.*/i) {				
					$model_found = 0;
					$start_parsing_PowerClamp = 0; 	  
					$all_PowerClamp_data{"$current_model"} = [@current_model_data];				
					@current_model_data = ();
				}			
				else {
					my @numbers = split /\s+/, trim $line;
					if (scalar @numbers != 4) {
						alert 2, "Extra content found.\n";
					}	
					else {
						my $voltage = get_number $numbers[0];
						my $current1 = get_number $numbers[1];
						my $current2 = get_number $numbers[2];
						my $current3 = get_number  $numbers[3];
						push @current_model_data, [$voltage, $current1, $current2, $current3];
					}		
				}
			}

		}
			
		$all_non_clipped_PowerClamp_data{"$file_name_non_clipped[$i]"} = \%all_PowerClamp_data;	  
		$voltage_range_non_clipped{"$file_name_non_clipped[$i]"} = \%current_voltage_range;
		
		if (scalar keys %all_PowerClamp_data != scalar keys %current_voltage_range)   {
		
			wprint "Different key counts.";	  	  
		
		}
	  
    }  
      
}

# parse pull down waveform data
sub get_non_clipped_GNDClamp_waveform {
  
    for (my $i = 0; $i < @file_name_non_clipped; $i++) {
	
		my %all_GNDClamp_data;
		my %current_voltage_range;
		my $current_model;	
		my @array = @{$non_clipped_files{"$file_name_non_clipped[$i]"}};  
		my $model_found = 0;
		my $start_parsing_GNDClamp = 0;
		
		for (my $j = 0 ; $j < @array; $j++) {
		
			my $line = $array[$j];      
			
			if ( $model_found == 0 and $line =~ /\[model\]/i) {	  	  
				$current_model = (split /\s+/, $line)[1];
				if (!scalar $current_model){
					alert 0, "Model name not found. Line $j.\n";
				}
				else {
					$model_found = 1;
				}
			}			 
			
			elsif ($model_found and $line =~ /\[GND Clamp\]/i) {
				$start_parsing_GNDClamp = 1; 	  
			}		 		  
			
			elsif ($model_found and $line =~ /\[voltage range\]/i) {			

				my @array_vr = split /\s+/, $line;
				
				if (@array_vr != 5) {
					eprint "Error VR measurement.\n";
				}
				
				else {
					my $vtyp = $array_vr[2];
					my $vmin = $array_vr[3];
					my $vmax = $array_vr[4];
					$current_voltage_range{"$current_model"} = [$vtyp, $vmin, $vmax];
				}

			}
			
			elsif ($model_found and $line =~ /.*\|.*-+.*/i and not scalar @current_model_data) {			    
					#alert 2, "Pull down values for $current_model not found.";
					$model_found = 0;
					$start_parsing_GNDClamp = 0; 	  
					$all_GNDClamp_data{"$current_model"} = [@current_model_data];				
					@current_model_data = ();			
			}

			elsif ($start_parsing_GNDClamp){			
				if ($line =~ /.*\|.*/i) {				
					$model_found = 0;
					$start_parsing_GNDClamp = 0; 	  
					$all_GNDClamp_data{"$current_model"} = [@current_model_data];				
					@current_model_data = ();
				}			
				else {
					my @numbers = split /\s+/, trim $line;
					if (scalar @numbers != 4) {
						alert 2, "Extra content found.\n";
					}	
					else {
						my $voltage = get_number  $numbers[0];
						my $current1 = get_number  $numbers[1];
						my $current2 = get_number  $numbers[2];
						my $current3 = get_number  $numbers[3];
						push @current_model_data, [$voltage, $current1, $current2, $current3];
					}		
				}
			}

		}
			
		$all_non_clipped_GNDClamp_data{"$file_name_non_clipped[$i]"} = \%all_GNDClamp_data;	  
		$voltage_range_non_clipped{"$file_name_non_clipped[$i]"} = \%current_voltage_range;
		
		if (scalar keys %all_GNDClamp_data != scalar keys %current_voltage_range)   {
		
			wprint "Different key counts.";	  	  
		
		}
	  
    }  
      
}

# =============================
# QUALITY ASSURANCE FUNCTIONS
# =============================

# Check pull down drivers' impedance value
# For the formula see: P80001562-190376
sub check_pulldown_driving_impedance {  

	my $minTolerance = shift;
	my $maxTolerance = shift;
	my $cornerTol 	 = shift; 
	
  	get_non_clipped_pulldown_waveform();    
    
	# Obtain pulldown drive impedance values.	
	foreach my $file (sort keys %all_non_clipped_pulldown_data){
		
		my %current_hash = %{$all_non_clipped_pulldown_data{"$file"}};
		my %current_voltage_range_hash = %{$voltage_range_non_clipped{"$file"}};    				
		
		my %models;
		foreach my $key_model (sort keys %current_hash) {      	        			
		
			if ($key_model =~ /odt/ig) {next;}

			my $divisor;
			if ($key_model =~ /.*_25_.*/i && $key_model =~ /.*lpd5.*/i) {
				$divisor = 2.5;
			}
			elsif ($key_model =~ /.*_3_.*/i && $key_model =~ /.*lpd5.*/i) {
				$divisor = 3;
			}
			else {$divisor = 2;}

			my @array = @{$current_hash{"$key_model"}};	
			my @voltage_array = @{$current_voltage_range_hash{"$key_model"}};	
				
			if (@voltage_array != 3) {

				eprint "There should be 3 columns in each pulldown table: typical, minimum, maximum. Only @voltage_array found.\n";
				exit;

			}

			my $VDDQ_TYPICAL = get_number $voltage_array[0];
			my $VDDQ_MIN = get_number $voltage_array[1];
			my $VDDQ_MAX = get_number $voltage_array[2];
						  
			my $midpoint_typical = $VDDQ_TYPICAL / $divisor;						
			my $midpoint_minimum = $VDDQ_MIN / $divisor;												
			my $midpoint_maxmimum = $VDDQ_MAX / $divisor;							
			
			my $done = 0;

			# Store the current, voltage and resistance values for reference			
			my $resistance_typical;
			my $resistance_min;
			my $resistance_max;

			my $current_typical;
			my $current_min;
			my $current_max;

			my $voltage_typical;
			my $voltage_min;
			my $voltage_max;

			# TYPICAL CALCULATION
			for (my $i = 0 ; $i < @array and $done == 0; $i++) {

				my @voltage_and_currents = @{$array[$i]};				
				# Pullup voltages are VDDQ referenced, therefore subtract them from the corresponding VDDQ value.
				my $x2 = $voltage_and_currents[0];												

				if ($x2 > $midpoint_typical) {
					
					my $y2 = $voltage_and_currents[1];					

					my @previous_voltage_and_currents = @{$array[$i-1]};
					my $x1 = $previous_voltage_and_currents[0];
					my $y1 = $previous_voltage_and_currents[1];					
					
					my $interpolation = lerp $midpoint_typical, $x1, $y1, $x2, $y2 ;
					$resistance_typical = $midpoint_typical/$interpolation;
					$current_typical = $y2;
					$voltage_typical = $x2;																				
					$done = 1;			    
					
				}
				
			}	

			$done = 0;
			# MIN CALCULATION
			for (my $i = 0 ; $i < @array and $done == 0; $i++) {

				my @voltage_and_currents = @{$array[$i]};				
				# Pullup voltages are VDDQ referenced, therefore subtract them from the corresponding VDDQ value.
				my $x2 = $voltage_and_currents[0];												

				if ($x2 > $midpoint_minimum) {
					
					my $y2 = $voltage_and_currents[2];					

					my @previous_voltage_and_currents = @{$array[$i-1]};
					my $x1 = $previous_voltage_and_currents[0];
					my $y1 = $previous_voltage_and_currents[2];					
					
					my $interpolation = lerp $midpoint_minimum, $x1, $y1, $x2, $y2 ;
					$resistance_min = $midpoint_minimum/$interpolation;	
					$current_min = $y2;
					$voltage_min = $x2;																			
					$done = 1;			    
					
				}
				
			}						

			$done = 0;
			# MAX CALCULATION
			for (my $i = 0 ; $i < @array and $done == 0; $i++) {

				my @voltage_and_currents = @{$array[$i]};				
				# Pullup voltages are VDDQ referenced, therefore subtract them from the corresponding VDDQ value.
				my $x2 = $voltage_and_currents[0];												

				if ($x2 > $midpoint_maxmimum) {
					
					my $y2 = $voltage_and_currents[3];					

					my @previous_voltage_and_currents = @{$array[$i-1]};
					my $x1 = $previous_voltage_and_currents[0];
					my $y1 = $previous_voltage_and_currents[3];					
					
					my $interpolation = lerp $midpoint_maxmimum, $x1, $y1, $x2, $y2 ;
					$resistance_max = $midpoint_maxmimum/$interpolation;
					$current_max = $y2;
					$voltage_max = $x2;																				
					$done = 1;			    
					
				}
				
			}		

			my %combined_hash = (
				'resistances' => [$resistance_typical, $resistance_min, $resistance_max],
				'voltages' => [$voltage_typical, $voltage_min, $voltage_max],
				'currents' => [$current_typical, $current_min, $current_max]
			);

			$models{"$key_model"} = \%combined_hash;
		}

		$pulldown_impedances{"$file"} = \%models;

	}	

	my ($passing_models_ref, $failing_models_ref) = filter_models (\%pulldown_impedances, $minTolerance, $maxTolerance, $cornerTol);	
	my %passing_models = %{$passing_models_ref};
	my %failing_models = %{$failing_models_ref};

	dprint (HIGH, "Passing/Failing PU models.\n");
	dprint (HIGH, Dumper(%passing_models)."\n");
	dprint (HIGH, Dumper(%failing_models)."\n");

	my @list_of_failing_models = keys (%failing_models);
	my @list_of_passing_models = keys (%passing_models);

	if ( @list_of_failing_models ) {
		wprint ("Some models do not match their impedance values.\n");		
		logger ("\nFailing models.\n");	
		dump_models (\%failing_models, \%voltage_range_non_clipped, $minTolerance, $maxTolerance);
	}	

	if (  @list_of_passing_models ) {				
		logger ("\nPassing models.\n");
		dump_models (\%passing_models, \%voltage_range_non_clipped, $minTolerance, $maxTolerance);		
	}

	if (@list_of_passing_models > 0 and @list_of_failing_models == 0) {
		alert (1, "Pulldown driver impedance check passed.\n\n", map_check_severity());
	}
	else {
		alert (0, "Pulldown driver impedance check failed.\n\n", map_check_severity());
	}

}

# Check pull up drivers' impedance value
# For the formula see: P80001562-190377
sub check_pullup_driving_impedance {  

	my $minTolerance = shift;
	my $maxTolerance = shift;
	my $cornerTol 	 = shift;

  	get_non_clipped_pullup_waveform();    
    
	# Obtain pulldown drive impedance values.	
	foreach my $file (sort keys %all_non_clipped_pullup_data){
		
		my %current_hash = %{$all_non_clipped_pullup_data{"$file"}};
		my %current_voltage_range_hash = %{$voltage_range_pullup_non_clipped{"$file"}};    				
		
		my %models;
		foreach my $key_model (sort keys %current_hash) {      	        			
				
			if ($key_model =~ /odt/ig) {next;}
			
			my $divisor;
			if ($key_model =~ /.*_25_.*/i && $key_model =~ /.*lpd5.*/i) {
				$divisor = 2.5;
			}
			elsif ($key_model =~ /.*_3_.*/i && $key_model =~ /.*lpd5.*/i) {
				$divisor = 3;
			}
			else {$divisor = 2;}

			my @array = @{$current_hash{"$key_model"}};	
			my @voltage_array = @{$current_voltage_range_hash{"$key_model"}};	
				
			if (@voltage_array != 3) {

				eprint "There should be 3 columns in each pulldown table: typical, minimum, maximum. Only @voltage_array found.\n";
				exit;

			}

			my $VDDQ_TYPICAL = get_number $voltage_array[0];
			my $VDDQ_MIN = get_number $voltage_array[1];
			my $VDDQ_MAX = get_number $voltage_array[2];
						  
			my $midpoint_typical = $VDDQ_TYPICAL / $divisor;						
			my $midpoint_minimum = $VDDQ_MIN / $divisor;												
			my $midpoint_maxmimum = $VDDQ_MAX / $divisor;							
			
			my $done = 0;
			
			my $resistance_typical;
			my $resistance_min;
			my $resistance_max;

			my ($voltage_typical, $voltage_min, $voltage_max);
			my ($current_typical, $current_min, $current_max);

			# TYPICAL CALCULATION
			for (my $i = 0 ; $i < @array and $done == 0; $i++) {

				my @voltage_and_currents = @{$array[$i]};				
				# Pullup voltages are VDDQ referenced, therefore subtract them from the corresponding VDDQ value.
				my $x2 = $VDDQ_TYPICAL - $voltage_and_currents[0];												

				if ($x2 < $midpoint_typical) {
					
					my $y2 = $voltage_and_currents[1];					

					my @previous_voltage_and_currents = @{$array[$i-1]};
					my $x1 = $VDDQ_TYPICAL - $previous_voltage_and_currents[0];
					my $y1 = $previous_voltage_and_currents[1];					
					
					my $interpolation = lerp $midpoint_typical, $x1, $y1, $x2, $y2 ;
					$resistance_typical = abs $midpoint_typical/$interpolation;
					$current_typical = $y2;
					$voltage_typical = $x2;																				
					$done = 1;			    
					
				}
				

			}	

			$done = 0;
			# MIN CALCULATION
			for (my $i = 0 ; $i < @array and $done == 0; $i++) {

				my @voltage_and_currents = @{$array[$i]};				
				# Pullup voltages are VDDQ referenced, therefore subtract them from the corresponding VDDQ value.
				my $x2 = $VDDQ_MIN - $voltage_and_currents[0];												

				if ($x2 < $midpoint_minimum) {
					
					my $y2 = $voltage_and_currents[2];					

					my @previous_voltage_and_currents = @{$array[$i-1]};
					my $x1 = $VDDQ_MIN - $previous_voltage_and_currents[0];
					my $y1 = $previous_voltage_and_currents[2];					
					
					my $interpolation = lerp $midpoint_minimum, $x1, $y1, $x2, $y2 ;
					$resistance_min = abs $midpoint_minimum/$interpolation;	
					$current_min = $y2;
					$voltage_min = $x2;																					
					$done = 1;			    
					
				}
				
			}						

			$done = 0;
			# MAX CALCULATION
			for (my $i = 0 ; $i < @array and $done == 0; $i++) {

				my @voltage_and_currents = @{$array[$i]};				
				# Pullup voltages are VDDQ referenced, therefore subtract them from the corresponding VDDQ value.
				my $x2 = $VDDQ_MAX - $voltage_and_currents[0];												

				if ($x2 < $midpoint_maxmimum) {
					
					my $y2 = $voltage_and_currents[3];					

					my @previous_voltage_and_currents = @{$array[$i-1]};
					my $x1 = $VDDQ_MAX - $previous_voltage_and_currents[0];
					my $y1 = $previous_voltage_and_currents[3];					
					
					my $interpolation = lerp $midpoint_maxmimum, $x1, $y1, $x2, $y2 ;
					$resistance_max = abs $midpoint_maxmimum/$interpolation;																				
					$current_max = $y2;
					$voltage_max = $x2;	
					$done = 1;			    
					
				}
				
			}		

			my %combined_hash = (
				'resistances' => [$resistance_typical, $resistance_min, $resistance_max],
				'voltages' => [$voltage_typical, $voltage_min, $voltage_max],
				'currents' => [$current_typical, $current_min, $current_max]
			);

			$models{"$key_model"} = \%combined_hash;

		}

		$pullup_impedances{"$file"} = \%models;

	}
	
	my ($passing_models_ref, $failing_models_ref) = filter_models (\%pullup_impedances, $minTolerance, $maxTolerance, $cornerTol);	
	my %passing_models = %{$passing_models_ref};
	my %failing_models = %{$failing_models_ref};

	dprint (HIGH, "Passing/Failing PU models.\n");
	dprint (HIGH, Dumper(%passing_models)."\n");
	dprint (HIGH, Dumper(%failing_models)."\n");
	
	my @list_of_failing_models = keys (%failing_models);
	my @list_of_passing_models = keys (%passing_models);

	if (@list_of_failing_models) {
		wprint("Some models do not match their impedance values.\n");
		logger("\nFailing models.\n");	
		dump_models(\%failing_models, \%voltage_range_pullup_non_clipped, $minTolerance, $maxTolerance);
	}	

	if (@list_of_passing_models) {				
		logger ("\nPassing models.\n");	
		dump_models (\%passing_models, \%voltage_range_pullup_non_clipped, $minTolerance, $maxTolerance);
	}

	if (@list_of_passing_models > 0 and @list_of_failing_models == 0) {
		alert (1, "Pullup driver impedance check passed.\n\n", map_check_severity());
	}
	else {
		alert (0, "Pullup driver impedance check failed.\n\n", map_check_severity());
	}	

}

# Calculate voltage output high value.
# For the formula see: P80001562-190378
sub voh_check {

	my $minTolerance = shift;
	my $maxTolerance = shift;
	my $cornerTol 	 = shift;

	my $voh_pass_all = 1;
	my %failed_models;

	foreach my $file_name (sort keys %all_rising_VDD_2_data) {

		my %current_failed_model;

		my %current_rising_VDD_2 = %{$all_rising_VDD_2_data{"$file_name"}};
		my %current_falling_VDD_half = %{$all_falling_VDD_half_data{"$file_name"}};
		my %current_vfixture = %{$all_vfixture_data{"$file_name"}};
		my %current_rising_0_2 = %{$all_rising_0_2_data{"$file_name"}};
		
		foreach my $key (sort keys %current_rising_VDD_2) {

			my @rising_2 = @{$current_rising_VDD_2{$key}};
			my @falling_half = @{$current_falling_VDD_half{$key}};
			my @fixture_data = @{$current_vfixture{$key}};
			my @rising_0_2 = @{$current_rising_0_2{$key}};

			if ( ! exists ${$pullup_impedances{"$file_name"}}{"$key"} ) {
				wprint "Skpping $key in file $file_name.\n";
				next;
			}

			my %combined_hash = %{${$pullup_impedances{"$file_name"}}{"$key"}};
			my @Rpu = @{$combined_hash{"resistances"}};
			my $voh_pass = 1;		

			if (!(@rising_2 == @falling_half and @falling_half == @fixture_data and @fixture_data == @rising_0_2)) {
				eprint "Missing model information in $file_name for model $key.\n";
				$voh_pass = 0;
				$voh_pass_all = 0;

			} else {
				foreach (my $k = 0; $k < @rising_2; $k++) {
					my $check1 = verify $THRESHOLD, $rising_2[$k], $falling_half[$k];
					my $check2 = verify $THRESHOLD, $rising_2[$k], $fixture_data[$k];
					my $check3 = verify $THRESHOLD, $falling_half[$k], $fixture_data[$k];

					my $curr_type = get_type $k;

					my $toCheck = $fixture_data[$k] * $RTT / ($Rpu[$k] + $RTT);
					my $answer = verify $THRESHOLD, $rising_0_2[$k], $toCheck;
					my $toPrint = sprintf("%.3f", $toCheck);

					if ($check1 == 0 or $check2 == 0 or $check3 == 0) {
						eprint "voh check failed in $file_name for model $key, $curr_type Rising waveform value does not match Falling Waveform value.\n";
						$voh_pass = 0;
						$voh_pass_all = 0;

						$current_failed_model{"$key"} = [$curr_type, $fixture_data[$k], $rising_2[$k], $falling_half[$k], $rising_0_2[$k], $toPrint];
					}

					if ($answer == 0) {
						my $toPrintRPU = sprintf("%.3f", $Rpu[$k]);

						eprint "voh check failed in $file_name for model $key, $curr_type Rising Waveform value does not match value calcultated with RTT and RPU.\n";
						wprint "The calculated value is around $toPrint, VDD is $fixture_data[$k] and RPU is around $toPrintRPU\n";

						if($voh_pass == 1) {
							$current_failed_model{"$key"} = [$curr_type, $fixture_data[$k], $rising_2[$k], $falling_half[$k], $rising_0_2[$k], $toPrint];
							$voh_pass = 0;
						}
						$voh_pass_all = 0;
					}

					if($voh_pass == 0) {
						last;
					}
				}
			}
		}

		$failed_models{"$file_name"} = \%current_failed_model;
	}

	if($voh_pass_all == 1) {
		alert (1, "All Voh tests passed!\n\n", map_check_severity());
	} else {
		
		alert (0, "Voh tests failed!\n\n", map_check_severity());
		logger "Failed Models:\n";
		
		foreach my $file (sort keys %failed_models) {						
			
			my %curr_failed_list = %{$failed_models{"$file"}};
			if(!keys %curr_failed_list) {
				next;
			}

			my $FIRST = 1;
			logger "$file\n";

			foreach my $model (sort keys %curr_failed_list) { 

				my @curr_model =  @{$curr_failed_list{$model}};

				if($FIRST == 1){
					my $string = sprintf "%-20s %-15s %-10s, %-20s, %-25s, %-15s, %-10s\n", "Model Name", "Min/Max/Typ", 
						"V_Fixture", "Rising V=VDDQ 0ns", "Falling V=VDDQ 0.5ns", "Rising V=0 2ns", "Calculated Value";
					logger($string);
					$FIRST = 0;
				} 
				
				my $string = sprintf "%-20s %-15s %-10s, %-20s, %-25s, %-15s, %-10s\n", $model, $curr_model[0], 
						$curr_model[1], $curr_model[2], $curr_model[3], $curr_model[4], $curr_model[5];

				logger($string);
			}
		}
	}
}

# Calculate voltage output low value.
# For the formula see: P80001562-190379
sub vol_check {

	my $minTolerance = shift;
	my $maxTolerance = shift;
	my $cornerTol 	 = shift;

	my $vol_pass = 1;
	my %failed_models;

	foreach my $file_name (sort keys %all_rising_VDD_half_data) {

		my %current_failed_model;

		my %current_rising_VDD_half = %{$all_rising_VDD_half_data{"$file_name"}};
		my %current_falling_2 = %{$all_falling_VDD_2_data{"$file_name"}};
		my %current_vfixture = %{$all_vfixture_data{"$file_name"}};

		foreach my $key (sort keys %current_rising_VDD_half) {

			my @rising_half = @{$current_rising_VDD_half{$key}};
			my @falling_2 = @{$current_falling_2{$key}};
			my @fixture_data = @{$current_vfixture{$key}};

			if ( ! exists ${$pulldown_impedances{"$file_name"}}{"$key"} ) {
				wprint "Skpping $key in file $file_name.\n";
				next;
			}

			my %combined_hash = %{${$pulldown_impedances{"$file_name"}}{"$key"}};
			my @Rpd = @{$combined_hash{"resistances"}};			

			if (@rising_half != @falling_2 or @rising_half != @fixture_data or @falling_2 != @fixture_data) {
				eprint "Missing model information in $file_name for model $key.\n";
				$vol_pass = 0;

			} else {
				foreach (my $k = 0; $k < @rising_half; $k++) {

					my $toCheck = $fixture_data[$k] * $Rpd[$k] / ($Rpd[$k] + $RTT);
					my $answer1 = verify $THRESHOLD, $rising_half[$k], $falling_2[$k];
					my $answer2 = verify $THRESHOLD, $rising_half[$k], $toCheck;
					my $answer3 = verify $THRESHOLD, $falling_2[$k], $toCheck;

					if ($answer1 == 0 or $answer2 == 0 or $answer3 == 0) {
						my $curr_type = get_type $k;
						my $toPrint = sprintf("%.3f", $toCheck);
						my $toPrintRPD = sprintf("%.3f", $Rpd[$k]);

						eprint "vol check failed in $file_name for model $key, the three $curr_type values: Rising Waveform, Falling Waveform and value calculated with RTT and RPD are not equal.\n";
						wprint "The calculated value is around $toPrint, VDD is $fixture_data[$k] and RPD is around $toPrintRPD.\n";
						$vol_pass = 0;
						$current_failed_model{"$key"} = [$curr_type, $fixture_data[$k], $rising_half[$k], $falling_2[$k], $toPrint];
						last;
					}
				}
			}
		}
		$failed_models{"$file_name"} = \%current_failed_model;	
	}

	if($vol_pass == 1) {
		alert (1, "All Vol tests passed!\n\n", map_check_severity());
	} else {
		
		alert (0, "Vol tests failed!\n\n", map_check_severity());
		logger "Failed Models:\n";

		foreach my $file (sort keys %failed_models) {						
			
			my %curr_failed_list = %{$failed_models{"$file"}};
			if(!keys %curr_failed_list) {
				next;
			}

			my $FIRST = 1;
			logger "$file\n";

			foreach my $model (sort keys %curr_failed_list) { 

				my @curr_model =  @{$curr_failed_list{$model}};

				if($FIRST == 1){
					my $string = sprintf "%-20s %-15s %-10s, %-20s, %-25s, %-15s\n", "Model Name", "Min/Max/Typ", 
						"V_Fixture", "Rising V=VDDQ 0.5ns", "Falling V=VDDQ 2ns", "Calculated Value";
					logger($string);
					$FIRST = 0;
				} 
				
				my $string = sprintf "%-20s %-15s %-10s, %-20s, %-25s, %-15s\n", $model, $curr_model[0], 
						$curr_model[1], $curr_model[2], $curr_model[3], $curr_model[4];

				logger($string);
			}
		}
	}
}

# Calculate on die termination value for pull up driver
# For the formula see: P80001562-190382
sub ODT_check_PowerClamp_waveform {

	my $minTolerance = shift;
	my $maxTolerance = shift;
	my $cornerTol 	 = shift;

	get_non_clipped_PowerClamp_waveform();

	# Obtain PowerClamp drive impedance values.	
	foreach my $file (sort keys %all_non_clipped_PowerClamp_data){
		
		my %current_hash 			   = %{$all_non_clipped_PowerClamp_data{"$file"}};
		my %current_voltage_range_hash = %{$voltage_range_non_clipped{"$file"}};    				
		
		my %models;
		foreach my $key_model (sort keys %current_hash) {      	        			
		
		    #only check odt models
		    if ( $key_model =~ /odt/ ) 

			{
								
				my $divisor;
				if ($key_model =~ /.*_25_.*/i) {
					$divisor = 2.5;
				}
				elsif ($key_model =~ /.*_3_.*/i) {
					$divisor = 3;
				}
				else {
					$divisor = 2;
				}			

				my @array = @{$current_hash{"$key_model"}}; #all the current values of the model	
				my @voltage_array = @{$current_voltage_range_hash{"$key_model"}}; # the value reference value 	
					
				if (@voltage_array != 3) {

					eprint ("There should be 3 columns in each PowerClamp table: typical, minimum, maximum. Only @voltage_array found.\n");
					exit;

				}

				my $VDDQ_TYPICAL = get_number $voltage_array[0];
				my $VDDQ_MIN 	 = get_number $voltage_array[1];
				my $VDDQ_MAX 	 = get_number $voltage_array[2];
							
				my $midpoint_typical 	= $VDDQ_TYPICAL / $divisor;						
				my $midpoint_minimum 	= $VDDQ_MIN / $divisor;												
				my $midpoint_maxmimum 	= $VDDQ_MAX / $divisor;	

				my $done = 0;

				# Store the current, voltage and resistance values for reference			
				my $resistance_typical;
				my $resistance_min;
				my $resistance_max;			

				my $current_typical;
				my $current_min;
				my $current_max;

				my $voltage_typical;
				my $voltage_min;
				my $voltage_max;

				# TYPICAL CALCULATION
				for (my $i = 0 ; $i < @array and $done == 0; $i++) {
				
					my @voltage_and_currents = @{$array[$i]};
					#voltages are VDDQ referenced, therefore subtract them from the corresponding VDDQ value.
					my $x2 = $VDDQ_TYPICAL - $voltage_and_currents[0]; 

					if ($x2 < $midpoint_typical) {

						my $y2 = $voltage_and_currents[1];
						
						my @previous_voltage_and_currents = @{$array[$i-1]};
						my $x1 = $VDDQ_TYPICAL - $previous_voltage_and_currents[0];
						my $y1 = $previous_voltage_and_currents[1];	
						
						my $interpolation = lerp $midpoint_typical, $x1, $y1, $x2, $y2 ;
						$resistance_typical =abs $midpoint_typical/$interpolation;
						$current_typical = $y2;
						$voltage_typical = $x2;																				
						$done = 1;			    
	
					}
				}	

				$done = 0;
				# MIN CALCULATION
				for (my $i = 0 ; $i < @array and $done == 0; $i++) {

					my @voltage_and_currents = @{$array[$i]};				
					# Pullup voltages are VDDQ referenced, therefore subtract them from the corresponding VDDQ value.
					my $x2 = $VDDQ_MIN - $voltage_and_currents[0];												

					if ($x2 < $midpoint_minimum) {
						
						my $y2 = $voltage_and_currents[2];					

						my @previous_voltage_and_currents = @{$array[$i-1]};
						my $x1 = $VDDQ_MIN - $previous_voltage_and_currents[0];
						my $y1 = $previous_voltage_and_currents[2];					
						
						my $interpolation = lerp $midpoint_minimum, $x1, $y1, $x2, $y2 ;
						$resistance_min = abs $midpoint_minimum/$interpolation;	
						$current_min = $y2;
						$voltage_min = $x2;																			
						$done = 1;			    
						
					}
					
				}						
				
				$done = 0;
				# MAX CALCULATION
				for (my $i = 0 ; $i < @array and $done == 0; $i++) {

					my @voltage_and_currents = @{$array[$i]};				
					# Pullup voltages are VDDQ referenced, therefore subtract them from the corresponding VDDQ value.
					my $x2 = $VDDQ_MAX - $voltage_and_currents[0];												

					if ($x2 < $midpoint_maxmimum) {
						
						my $y2 = $voltage_and_currents[3];					

						my @previous_voltage_and_currents = @{$array[$i-1]};
						my $x1 = $VDDQ_MAX - $previous_voltage_and_currents[0];
						my $y1 = $previous_voltage_and_currents[3];					
						
						my $interpolation = lerp $midpoint_maxmimum, $x1, $y1, $x2, $y2 ;
						$resistance_max = abs $midpoint_maxmimum/$interpolation;
						$current_max = $y2;
						$voltage_max = $x2;																				
						$done = 1;			    
						
					}
					
				}		

				my %combined_hash = (
					'resistances' => [$resistance_typical, $resistance_min, $resistance_max],
					'voltages' 	  => [$voltage_typical, $voltage_min, $voltage_max],
					'currents' 	  => [$current_typical, $current_min, $current_max]
				);

				$models{"$key_model"} = \%combined_hash;
		    }
		}

		if(! keys (%models) ){
	      wprint("No [POWER Clamp] compatible odt models found inside $file.\n");	      
		}	
		else {
			$PowerClamp_impedances{"$file"} = \%models;
		}
	    
	}	

	my ($passing_models_ref, $failing_models_ref) = filter_models (\%PowerClamp_impedances, $minTolerance, $maxTolerance, $cornerTol);

	my %passing_models = %{$passing_models_ref};
	my %failing_models = %{$failing_models_ref};
	
	my @list_of_failing_models = keys (%failing_models);
	my @list_of_passing_models = keys (%passing_models);

	if (@list_of_failing_models) {
		wprint("Some odt models do not match their impedance values.\n");
		logger("\nFailing odt models.\n");	
		dump_models(\%failing_models, \%voltage_range_non_clipped, $minTolerance, $maxTolerance);
	}	

	if (@list_of_passing_models) {				
		logger("\nPassing odt models.\n");	
		dump_models(\%passing_models, \%voltage_range_non_clipped, $minTolerance, $maxTolerance);
	}

	if (@list_of_passing_models > 0 and @list_of_failing_models == 0) {
		alert (1, "ODT PWR. CLAMP check passed.\n\n", map_check_severity());
	}
	else {
		alert (0, "ODT PWR. CLAMP check failed.\n\n", map_check_severity());
	}
			
}

# Calculate on die termination value for pull down driver
# For the formula see: P80001562-190382
sub ODT_check_GNDClamp_waveform {

	my $minTolerance = shift;
	my $maxTolerance = shift;
	my $cornerTol 	 = shift;	

	get_non_clipped_GNDClamp_waveform();
	# Obtain GNDClamp drive impedance values.	
	foreach my $file (sort keys %all_non_clipped_GNDClamp_data){
		
		my %current_hash = %{$all_non_clipped_GNDClamp_data{"$file"}};
		my %current_voltage_range_hash = %{$voltage_range_non_clipped{"$file"}};    				

		my %models;
		foreach my $key_model (sort keys %current_hash) {      	        			
		
		    #only check odt models
		    if ($key_model =~ /odt/ ) {
				
				my $divisor;
				if ($key_model =~ /.*_25_.*/i) {
					$divisor = 2.5;
				}
				elsif ($key_model =~ /.*_3_.*/i) {
					$divisor = 3;
				}
				else {$divisor = 2;}

				my @array = @{$current_hash{"$key_model"}};	
				my @voltage_array = @{$current_voltage_range_hash{"$key_model"}};	
					
				if (@voltage_array != 3) {

					eprint "There should be 3 columns in each GNDClamp table: typical, minimum, maximum. Only @voltage_array found.\n";
					exit;

				}

				my $VDDQ_TYPICAL = get_number $voltage_array[0];
				my $VDDQ_MIN = get_number $voltage_array[1];
				my $VDDQ_MAX = get_number $voltage_array[2];
							
				my $midpoint_typical = $VDDQ_TYPICAL / $divisor;						
				my $midpoint_minimum = $VDDQ_MIN / $divisor;												
				my $midpoint_maxmimum = $VDDQ_MAX / $divisor;							
				
				my $done = 0;

				# Store the current, voltage and resistance values for reference			
				my $resistance_typical;
				my $resistance_min;
				my $resistance_max;

				my $current_typical;
				my $current_min;
				my $current_max;

				my $voltage_typical;
				my $voltage_min;
				my $voltage_max;

				# TYPICAL CALCULATION
				for (my $i = 0 ; $i < @array and $done == 0; $i++) {

					my @voltage_and_currents = @{$array[$i]};				
					my $x2 = $voltage_and_currents[0];												

					if ($x2 > $midpoint_typical) {
						
						my $y2 = $voltage_and_currents[1];					

						my @previous_voltage_and_currents = @{$array[$i-1]};
						my $x1 = $previous_voltage_and_currents[0];
						my $y1 = $previous_voltage_and_currents[1];					
						
						my $interpolation = lerp $midpoint_typical, $x1, $y1, $x2, $y2 ;
						$resistance_typical = abs $midpoint_typical/$interpolation;
						$current_typical = $y2;
						$voltage_typical = $x2;																				
						$done = 1;			    
						
					}
					

				}	

				$done = 0;
				# MIN CALCULATION
				for (my $i = 0 ; $i < @array and $done == 0; $i++) {

					my @voltage_and_currents = @{$array[$i]};				
					my $x2 = $voltage_and_currents[0];												

					if ($x2 > $midpoint_minimum) {
						
						my $y2 = $voltage_and_currents[2];					

						my @previous_voltage_and_currents = @{$array[$i-1]};
						my $x1 = $previous_voltage_and_currents[0];
						my $y1 = $previous_voltage_and_currents[2];					
						
						my $interpolation = lerp $midpoint_minimum, $x1, $y1, $x2, $y2 ;
						$resistance_min = abs $midpoint_minimum/$interpolation;	
						$current_min = $y2;
						$voltage_min = $x2;																			
						$done = 1;			    
						
					}
					
				}						

				$done = 0;
				# MAX CALCULATION
				for (my $i = 0 ; $i < @array and $done == 0; $i++) {

					my @voltage_and_currents = @{$array[$i]};				
					my $x2 = $voltage_and_currents[0];												

					if ($x2 > $midpoint_maxmimum) {
						
						my $y2 = $voltage_and_currents[3];					

						my @previous_voltage_and_currents = @{$array[$i-1]};
						my $x1 = $previous_voltage_and_currents[0];
						my $y1 = $previous_voltage_and_currents[3];					
						
						my $interpolation = lerp $midpoint_maxmimum, $x1, $y1, $x2, $y2 ;
						$resistance_max = abs $midpoint_maxmimum/$interpolation;
						$current_max = $y2;
						$voltage_max = $x2;																				
						$done = 1;			    
						
					}
					
				}		

				my %combined_hash = (
					'resistances' => [$resistance_typical, $resistance_min, $resistance_max],
					'voltages' => [$voltage_typical, $voltage_min, $voltage_max],
					'currents' => [$current_typical, $current_min, $current_max]
				);

				$models{"$key_model"} = \%combined_hash;
		    }
		}

		if(! keys (%models) ){
	    	wprint("No [GND Clamp] compatible odt models found inside $file.\n");	      
		}	
		else {
			$GNDClamp_impedances{"$file"} = \%models;
		}	
	    
	}	

	my ($GNDpassing_models_ref, $GNDfailing_models_ref) = filter_models (\%GNDClamp_impedances, $minTolerance, $maxTolerance, $cornerTol);
	
	my %GNDpassing_models = %{$GNDpassing_models_ref};
	my %GNDfailing_models = %{$GNDfailing_models_ref};
	
	my @list_of_failing_models = keys (%GNDfailing_models);
	my @list_of_passing_models = keys (%GNDpassing_models);

	if (@list_of_failing_models) {
		wprint("Some odt models do not match their impedance values.\n");
		logger("\nFailing odt models.\n");	
		dump_models (\%GNDfailing_models, \%voltage_range_non_clipped, $minTolerance, $maxTolerance);
	}	

	if (@list_of_passing_models) {				
		logger("\nPassing odt models.\n");
		dump_models(\%GNDpassing_models, \%voltage_range_non_clipped, $minTolerance, $maxTolerance);
	}

	if (@list_of_passing_models > 0 and @list_of_failing_models == 0) {
		alert (1, "ODT GND. CLAMP check passed.\n\n", map_check_severity());
	}
	else {
		alert (0, "ODT GND. CLAMP check failed.\n\n", map_check_severity());
	}
	
}

# =============================
# TEMPLATE ROUTINES
# =============================

BEGIN {
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
   Main();
END   { 	
	footer();
	write_stdout_log( $LOGFILENAME );
	utils__script_usage_statistics("ibis_electrical.pl", $VERSION);
}

# =============================
# USAGE
# =============================

sub usage {
    print << "EOP" ;

	USAGE : $0 [options]

	-proj	
		project string (required)
	-macro	
		circuit macro to be analysed (required)
	-d	
		set debugging level ( positive integer )
	-help	
		print this screen
	-depotPath	
		specify custom depoth path	
	-severity	
		specify the sverity configuration file	

	EXAMPLE: $0 -proj ddr43/d528-ddr43-ss11lpp18/1.00a -macro dwc_ddrphy_txrxac_ew -depotPath //depot/products/ddr43_lpddr4_v2/project/d528-ddr43-ss11lpp18

EOP
    exit;
}
