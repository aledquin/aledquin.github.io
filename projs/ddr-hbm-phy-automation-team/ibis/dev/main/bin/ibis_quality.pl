#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : ibis_quality.pl
# Author  : Harsimrat Singh Wadhawan
# Date    : 8 Dec, 2021
# Purpose : Check IBIS model files' quality.
#
# Modification History
#     XXX Harsimrat Singh Wadhawan, 2022-07-13 11:36:39
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
use Util::P4;
# use utilities;
use ibis;
use parsers;
use QA;
#----------------------------------#

#---- GLOBAL VARs------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $PROGRAM_NAME = $RealScript;
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $VERSION = get_release_version();
our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
#----------------------------------#

# =============================
# MAIN
# =============================

sub Main {

	# Pre-processing
	my ($depotPath, $severities) = initialise_script();
	
	# ===================================================================================================================== #
	# GATHER DATA
	# ===================================================================================================================== #

	my ($clipped_files_ref, $non_clipped_files_ref);

	# Get the names of all clipped and nonclippe files
	my ($names_clipped_ref, $names_non_clipped_ref) = extract_file_names($depotPath);		

	# Get the summary file
	my $ibis_summary_ref = get_summary_file($depotPath);
	
	# Obtain the file contents and store them for processing later on
	if ($names_clipped_ref eq NULL_VAL) {
		fatal_error("Could not get ibis model files. Exiting.\n");
	}
	else {		
		($clipped_files_ref, $non_clipped_files_ref) = get_file_contents($depotPath, $names_clipped_ref, $names_non_clipped_ref);
	}

	# Clipped and non_clipped files are stored in the following hashtables
	my %clipped_files     = %{$clipped_files_ref};
	my %non_clipped_files = %{$non_clipped_files_ref};

	# Extract models and their descriptions from all the IBIS model files.
	my (	
		$modelCountNonClipped_ref, 
		$modelCountClipped_ref, 
		$modelListNonClipped_ref, 
		$modelListClipped_ref, 
		$non_clipped_descriptions_ref, 
		$clipped_descriptions_ref
	)
	
	= extract_model_lists_and_descriptions(
		$names_clipped_ref, 
		$names_non_clipped_ref, 
		$clipped_files_ref, 
		$non_clipped_files_ref
	);

	# Pack the model data into a hashtable
	my %model_data = (
		'modelCountNonClipped_ref' => $modelCountNonClipped_ref,
		'modelCountClipped_ref'    => $modelCountClipped_ref,
		'modelListNonClipped_ref'  => $modelListNonClipped_ref,
		'modelListClipped_ref'     => $modelListClipped_ref
	);

	# Pack the file name data into a hashtable
	my %file_data = (
		'names_non_clipped_ref'     => $names_non_clipped_ref,
		'names_clipped_ref'         => $names_clipped_ref,
		'clipped_files_ref'         => $clipped_files_ref,
		'non_clipped_files_ref'     => $non_clipped_files_ref
	);

	# ===================================================================================================================== #
	# PARSE SEVERITIES FILE
	# ===================================================================================================================== #

	parse_severities($severities);

	# ===================================================================================================================== #
	# DO THE CHECKS
	# ===================================================================================================================== #

	my $number_clipped     = @{$names_clipped_ref};
	my $number_non_clipped = @{$names_non_clipped_ref};

	# CHECK: Start the checks by ensuring that the same number of clipped and non_clipped files are present
	check_number_files($number_non_clipped, $number_clipped);
	
	# CHECK: Check clipped and non_clipped files with the IBISCHK tool
	check_ibis_with_ibischk(\%clipped_files, \%non_clipped_files);
	
	# CHECK: Ensure that the non clipped files are larger than the clipped files
	check_file_sizes(\%file_data, $depotPath);

	# CHECK: Check the number of models in clipped and non_clipped files and ensure that they are equal
	check_model_numbers(\%model_data, \%file_data);

	# CHECK: Check that the number of data points in clipped and non clipped files, ensure that clipped < non clipped
	check_waveform_lengths(\%model_data, \%file_data);
	
	# CHECK: Check the summary for slew rates and calcodes
	check_ibis_summary_file($ibis_summary_ref);

	# CHECK: Check that the model descriptions match the product names
	check_model_descriptions($non_clipped_descriptions_ref, $clipped_descriptions_ref, $ibis_summary_ref);

	# CHECK: Ensure that C_comp values have not been written in the wrong order (typ > min, but typ < max)
	check_c_comp_values(\%model_data, \%file_data);

	# CHECK: Ensure that the correct VDDQ value is added into each of the models.
	check_vddq_correctness(\%model_data, \%file_data, $ibis_summary_ref);
	
	return 0;

}

# =============================
# DATA COLLECTION FUNCTIONS
# =============================

# get all file contents at once
sub get_file_contents($$$) {

  my $depotPath                   = shift;
  my $m_file_name_clipped_ref     = shift;
  my $m_file_name_non_clipped_ref = shift;
  my @m_file_name_clipped         = @{$m_file_name_clipped_ref};
  my @m_file_name_non_clipped     = @{$m_file_name_non_clipped_ref};
  my %m_clipped_files;
  my %m_non_clipped_files;

  for (my $i = 0 ; $i < @m_file_name_clipped; $i++){
  
	my $path = "$depotPath/clipped/$m_file_name_clipped[$i]";    
	my $answer = da_p4_print_file($path);
	my @result = split(/\n/, $answer);	

	if ($answer eq NULL_VAL){
		wprint("Could not get files for $path.\n");
		$m_clipped_files{"$m_file_name_clipped[$i]"} = NULL_VAL;
	}
	else {
		$m_clipped_files{"$m_file_name_clipped[$i]"} = \@result;
	}    
  
  }
  
  for (my $i = 0 ; $i < @m_file_name_non_clipped; $i++){
      
    my $path = "$depotPath/non_clipped/$m_file_name_non_clipped[$i]";
	my $answer = da_p4_print_file($path);
	my @result = split(/\n/, $answer);

	if ($answer eq NULL_VAL){
		wprint("Could not get files for $path.\n");
		$m_non_clipped_files{"$m_file_name_non_clipped[$i]"} = NULL_VAL;
	}
	else {
		$m_non_clipped_files{"$m_file_name_non_clipped[$i]"} = \@result;
	}    
         
  }      

  return (\%m_clipped_files, \%m_non_clipped_files) ;
  
}

# get the IBIS summary file
sub get_summary_file($) {

	my $depotPath    = shift;
	my @ibis_summary = ();	

	my @files = da_p4_files("$depotPath/*summary*");
	dprint (HIGH, Dumper(\@files)."\n");

	if ($files[0] eq NULL_VAL){
		eprint("IBIS Summary file not found")
	}
	
	if (@files > 1) {
		wprint("Multiple summary files found. Picking $files[0]. \n");		
	}

	my $answer = da_p4_print_file($files[0]);
	@ibis_summary = split(/\n/, $answer);		

	return \@ibis_summary;

}

# Get the names of the clipped and non-clipped .ibs files
sub extract_file_names($) {
	
	my $m_depotPath = shift;

	my (@file_name_clipped, @file_name_non_clipped);

	my @file_name_clipped_locations     = da_p4_files("$m_depotPath/clipped/*");	
	my @file_name_non_clipped_locations = da_p4_files("$m_depotPath/non_clipped/*");

	if ($file_name_clipped_locations[0] eq NULL_VAL or $file_name_non_clipped_locations[0] eq NULL_VAL){
		fatal_error("Could not find clipped or non clipped files.\n");
		return NULL_VAL;
	}

	@file_name_clipped     = remove_trails(\@file_name_clipped_locations, "$m_depotPath/clipped/");
	@file_name_non_clipped = remove_trails(\@file_name_non_clipped_locations, "$m_depotPath/non_clipped/");

	dprint MEDIUM, Dumper(@file_name_clipped)."\n";
	dprint MEDIUM, Dumper(@file_name_non_clipped)."\n";

	my $clipped_count 		= @file_name_clipped;
	my $non_clipped_count 	= @file_name_non_clipped;

	dprint MEDIUM, "Found $clipped_count ibis files in clipped folder\n";
	dprint MEDIUM, "Found $non_clipped_count ibis files in non_clipped folder\n\n";

	#log results
	logger "Found $clipped_count ibis files in clipped folder\n";
	logger "Found $non_clipped_count ibis files in non_clipped folder\n\n";
	
	return (\@file_name_clipped, \@file_name_non_clipped);


}

# Extract the model names and their descriptions from each of the IBIS model files
sub extract_model_lists_and_descriptions($$$$) {	
	
	my $file_name_clipped_ref     = shift;
	my $file_name_non_clipped_ref = shift;
	my $clipped_files_ref         = shift;
	my $non_clipped_files_ref     = shift; 

	my @file_name_non_clipped     = @{$file_name_non_clipped_ref};
	my @file_name_clipped         = @{$file_name_clipped_ref};
	my %clipped_files             = %{$clipped_files_ref};
	my %non_clipped_files         = %{$non_clipped_files_ref};
 
	my %non_clipped_descriptions;
	my %clipped_descriptions;

    my @modelCountNonClipped;
	my @modelCountClipped;
	my @modelListNonClipped;
	my @modelListClipped;

	# These variables, if set to a value greater than 0, indicate that errors were detected
	my $error_non_clipped = 0;
	my $error_clipped     = 0;

	#Assume that the clipped and non_clipped counts are the same.
	for(my $i = 0; $i < @file_name_non_clipped; $i++) {
			
		my @array = @{$non_clipped_files{"$file_name_non_clipped[$i]"}};		
		my $models = 0;
		
		# This loop will read the number of models in each of the non-clipped files
		# and then enter them into an array.
		foreach my $line (@array){
			$_ = $line;		
			if($models == 0){
				if(index($_,"[Model Selector]") != -1){
					$models = 1;
					next;
				}
			}
			elsif($models == 1){
				if ($_ =~ /.*\|.*-----------------------*./){
					last;
				}
				elsif ($_ =~ /\[.*\]/){
					last;
				}
				elsif (!length trim $_ ){ 
					last ;
				}
				else{
					my @arr                          = split / /, $_;
					my $name                         = $arr[0];					
					$non_clipped_descriptions{$name} = $_;
					push(@{$modelListNonClipped[$i]}, $name);					
					$modelCountNonClipped[$i]++;
				}
			}
		}
			
		if ($models and scalar @modelCountNonClipped) { 
			logger "$modelCountNonClipped[$i] models found in $file_name_non_clipped[$i]\n";
		}
		
		else { 		
		
		  $error_non_clipped = 1;
		  push( @{ $modelListNonClipped[$i] }, () );
		  $modelCountNonClipped[$i] = 0;		  
		  logger "[Model Selector] not found in $file_name_non_clipped[$i].\n"; 
		  eprint ("Models not found in $file_name_non_clipped[$i] since [Model selector] was not found.\n");

		}
								
		@array = @{$clipped_files{"$file_name_clipped[$i]"}};
		$models = 0;
		
		# This loop will read the number of models in each of the clipped files
		# and then enter them into an array.
		foreach my $line (@array){
			
			$_ = $line;
			
			if($models == 0){
				
				if(index($_,"[Model Selector]") != -1){
					$models = 1;
					next;
				}

			}
			
			elsif($models == 1){
			
				if ($_ =~ /.*\|.*-----------------------*./){
					last;
				}
				elsif ($_ =~ /\[.*\]/){
					last;
				}
				elsif (!length trim $_ ){ 
					last;
				}			
				else{
					my @arr                      = split / /, $_;
					my $name                     = $arr[0];										
					$clipped_descriptions{$name} = $_;
					$modelCountClipped[$i]++;
					push(@{$modelListClipped[$i]},$name);
				}

			}

		}
		
		if ($models and scalar @modelCountClipped) { 
			
			logger "$modelCountClipped[$i] models found in $file_name_clipped[$i]\n";

		}

		else { 		
		
		  $error_clipped = 1;	
		  push(@{$modelListClipped[$i]}, () );	 
		  $modelCountClipped[$i] = 0; 
		  logger "[Model Selector] not found in $file_name_clipped[$i].\n"; 		  
		  eprint ("Models not found in $file_name_clipped[$i] since [Model selector] was not found.\n");

		}

	}

	return (\@modelCountNonClipped, \@modelCountClipped, \@modelListNonClipped, \@modelListClipped, \%non_clipped_descriptions, \%clipped_descriptions);

}

# =============================
# UTILITIES
# =============================

# Get options and initalise neessary variables for locating files.
sub initialise_script {

	#Set project parameters
	my ( $family, $project, $macro, $release, $customDepotPath, $depotPath );
	my ( $success, $help, $macro_arg, $debug, $project_string );

	# Set severity configuration
	my $severities = NULL_VAL;

	## get specified args
	$success = GetOptions(
		"help!"   => \$help,
		"macro=s" => \$macro_arg,		
		"proj=s"  => \$project_string,		
		"d=s"     => \$DEBUG,
		"depotPath=s" => \$customDepotPath,
		"severity=s"  => \$severities
	);

	&usage if ( !defined $macro_arg);
	&usage if ( !defined $project_string);
	&usage if defined $help;

	#extract project type, path and release
	($family, $project, $release) = parse_project_spec($project_string, \&usage);

	if ($family eq NULL_VAL){		
		fatal_error("Project string not parsable.\n");		
	}

	if ($family eq 'lpddr5x') {
		$family = "lpddr5x_ddr5_phy/lp5x";
	} elsif ($family eq 'ddr5'){
       $family = "lpddr5x_ddr5_phy/$family";
    }

	#set the macro
	$macro = $macro_arg;

	#Set the depot path for the ibis folder
	$depotPath = "//depot/products/$family/project/$project/ckt/rel/$macro/$release/macro/ibis";

	if (defined $customDepotPath) {
		$depotPath = "$customDepotPath/ckt/rel/$macro/$release/macro/ibis";	
	}
	
	dprint LOW, "Debugger setting: $DEBUG\n";
	dprint LOW, "The depot path is: $depotPath.\n";
	dprint MEDIUM, "$family $project $release $macro\n";

	return ($depotPath, $severities);

}

# remove extra bits at the end
sub remove_trails($$) {

	my $file_arr_ref  = shift;
	my $substring     = shift;	
	my @file_array    = @{$file_arr_ref};
	my @new_array     = ();

	for (my $i = 0; $i < @file_array; $i++){

		my $new_name = $file_array[$i];
		$new_name    =~ s/\Q$substring//ig;
		push (\@new_array, $new_name);

	}

	return @new_array;

}

sub find_next_occurrence($$$){

	my $array_ref = shift;
	my $pattern   = shift;
	my $offset    = shift;

	my @array = @ {$array_ref};

	for (my $i = $offset; $i < @array; $i++) {

		if ($array[$i] =~ $pattern) {
			return $i;
		}

	}

	return NULL_VAL;

}

# Get the number of points per rising/falling/composite/etc. section in a model
sub get_model_locations($$){

	# Contains the model count and the model data
	my $model_data_ref    = shift;			
	# File contents to search inside for models
	my $array_data_ref    = shift;

	# Hashtable to store the different number of models inside a file
	my %models;	
	# Dereference hashtable pointer ;)
	my %model_data = %{$model_data_ref};
	
	my @modelCountClipped = @{$model_data{'modelCount_ref'}};  	
	my @modelListClipped  = @{$model_data{'modelList_ref'}}; 
	my @array             = @{$array_data_ref};

	# Search for all lines starting with [Model] and then after that search for the next occurrence of '|'
	for (my $i = 0; $i < @array; $i++) {

		if ($array[$i] =~ /^\[model\].*/ig){

			my $model_name = $array[$i];
			$model_name    =~ s/^\[model\]//ig;
			$model_name    = trim($model_name);

			my $occurrence = $i;
			my $end        = find_next_occurrence($array_data_ref, qr/\|\s-+/, $i);
			
			if ($end eq NULL_VAL) {

				$models{$model_name} = { 
					
					'first' => $occurrence,
					'last'  => NULL_VAL

				};

			}

			else {
				
				$models{$model_name} = {
					
					'first' => $occurrence,
					'last'  => $end

				};

				$i = $end;

			}

		}

	}
	
	if (! keys(%models) ) {
		return NULL_VAL;
	}

	return \%models;

}

# Find the number of lines in a certain section
sub count_number_lines_in_section ($$$$) {
	
	# The section to search for in an IBIS model file: [Rising Waveform], [Falling Waveform], [Coposite Current]
	my $section_to_search = shift;
	# File contents to search inside for models
	my $array_data_ref    = shift;
	# Offset to start searching from	
	my $offset            = shift;
	# End search here
	my $end 	          = shift;

	my @array             = @{$array_data_ref};

	for (my $i = $offset; $i < $end; $i++){

		if ( $array[$i] =~ $section_to_search ) { # Perl quotemeta for literal search

			my $first_occurrence = $i + 1; 
			my $index = $first_occurrence;

			while ( TRUE ){

				if ($array[$index] =~ /\|/ig) {					
					return ($index - $first_occurrence);					
				}

				elsif ($index > $end) {
					return NULL_VAL;
				}

				$index++;				

			}			

		}

	}

	return NULL_VAL;

}

# Apply the get_number function to each element of the array
sub apply_get_number ($) {

	my $array_ref = shift;
	my @array = @{$array_ref};
	my @array_processed;

	foreach my $value (@array) {
		my $number = get_number($value);
		push (@array_processed, $number);
	}

	return @array_processed;

}

# Process the C_comps and make sure that they are the same
sub process_c_comps ($) {

	my $c_comp_ref = shift;
	my %c_comps    = %{$c_comp_ref};
	my $problems   = 0;

	logger "Processing C_comps.\n";
	foreach my $file (keys(%c_comps)){

		my %models = %{$c_comps{"$file"}};
		foreach my $model (keys(%models)){

			logger "\t$file <=> $model\n";
			my @array = @{$models{$model}};
			
			# C_comp, C_comp_pullup, C_comp_pulldown, C_comp_power_clamp
			my $C_comp             = 0;
			my $C_comp_pullup      = 0;
			my $C_comp_pulldown    = 0;
			my $C_comp_power_clamp = 0;

			my %verdict = ();
			my $index   = 0;

			foreach my $line (@array) {

				if (   $line =~ /^C_comp\s/ )            { insert_at_key(\%verdict, "C_comp", $index);          }
				elsif ($line =~ /^C_comp_pullup\s/)      { insert_at_key(\%verdict, "C_comp_pullup", $index);   }
				elsif ($line =~ /^C_comp_pulldown\s/)    { insert_at_key(\%verdict, "C_comp_pulldown", $index); }
				$index++;

			}

			if (exists($verdict{"C_comp"}) && @{$verdict{"C_comp"}} > 1) {

				# Ensure that the 2 C_comp strings are the same						
				if (@{$verdict{"C_comp"}}[0] ne @{$verdict{"C_comp"}}[1]){
										
					my $line  = $array[${$verdict{"C_comp"}}[0]];
					my $line2 = $array[${$verdict{"C_comp"}}[1]];
					
					my @values_0 = split (/\s+/, $line);
					my @values_1 = split (/\s+/, $line2);

					if (@values_0 != 4 || @values_1 != 4) {
						wprint("Could not parse C_Comp line for $file:$model.\n");
					}

					else {
						
						logger "\t\tC_comp count greater than 1.\n\t\t$line\n\t\t$line2\n";	

						# Get the numerical value of each datum
						@values_0 = apply_get_number (\@values_0);
						@values_1 = apply_get_number (\@values_1);

						# Check to make sure the values are equal for the 2 occurrences 
						if ( ($values_0[1] == $values_1[1]) && ($values_0[2] == $values_1[2]) && ($values_0[3] == $values_1[3]) ) {

							# NOP
							logger "\t\tC_Comp values are equal for both occurences typ/min/max.\n";

						}

						else {

							logger "\t\tC_Comp values are not equal for both occurences typ/min/max.\n";

							if ( ($values_0[1] > $values_0[2]) && ( $values_0[1] < $values_0[3]) ) {}
							else {
								$problems++;
								logger "\t\tC_Comp values not in ascending order for typ/min/max.\n";
							}

							if ( ($values_1[1] > $values_1[2]) && ( $values_1[1] < $values_1[3]) ) {}
							else {
								$problems++;
								logger "\t\tC_Comp values not in ascending order for typ/min/max.\n";
							}

						}
						
						dprint ( INSANE, "$values_0[1] $values_0[2] $values_0[3]\n" );						

					}
					
				}

			}
	
			if (exists($verdict{"C_comp_pullup"}) && @{$verdict{"C_comp_pullup"}} > 1) {
											
				if (@{$verdict{"C_comp_pullup"}}[0] ne @{$verdict{"C_comp_pullup"}}[1]){
										
					my $line  = $array[${$verdict{"C_comp_pullup"}}[0]];
					my $line2 = $array[${$verdict{"C_comp_pullup"}}[1]];
					
					my @values_0 = split (/\s+/, $line);
					my @values_1 = split (/\s+/, $line2);

					if (@values_0 != 4 || @values_1 != 4) {
						wprint("Could not parse C_comp_pullup line for $file:$model.\n");
					}

					else {
						
						logger "\t\tC_comp_pullup count greater than 1.\n\t\t$line\n\t\t$line2\n";	

						# Get the numerical value of each datum
						@values_0 = apply_get_number (\@values_0);
						@values_1 = apply_get_number (\@values_1);

						# Check to make sure the values are equal for the 2 occurrences 
						if ( ($values_0[1] == $values_1[1]) && ($values_0[2] == $values_1[2]) && ($values_0[3] == $values_1[3]) ) {

							# NOP
							logger "\t\tC_Comp values are equal for both occurences typ/min/max.\n";

						}

						else {

							logger "\t\tC_Comp values are not equal for both occurences typ/min/max.\n";

							if ( ($values_0[1] > $values_0[2]) && ( $values_0[1] < $values_0[3]) ) {}
							else {
								$problems++;
								logger "\t\tC_Comp values not in ascending order for typ/min/max.\n";
							}

							if ( ($values_1[1] > $values_1[2]) && ( $values_1[1] < $values_1[3]) ) {}
							else {
								$problems++;
								logger "\t\tC_Comp values not in ascending order for typ/min/max.\n";
							}

						}

						dprint ( INSANE, "$values_0[1] $values_0[2] $values_0[3]\n" );						

					}
					
				}

			}

			if (exists($verdict{"C_comp_pulldown"}) && @{$verdict{"C_comp_pulldown"}} > 1) {
											
				if (@{$verdict{"C_comp_pulldown"}}[0] ne @{$verdict{"C_comp_pulldown"}}[1]){
										
					my $line  = $array[${$verdict{"C_comp_pulldown"}}[0]];
					my $line2 = $array[${$verdict{"C_comp_pulldown"}}[1]];
					
					my @values_0 = split (/\s+/, $line);
					my @values_1 = split (/\s+/, $line2);

					if (@values_0 != 4 || @values_1 != 4) {
						wprint("Could not parse C_comp_pulldown line for $file:$model.\n");
					}

					else {
						
						logger "\t\tC_comp_pulldown count greater than 1.\n\t\t$line\n\t\t$line2\n";	

						# Get the numerical value of each datum
						@values_0 = apply_get_number (\@values_0);
						@values_1 = apply_get_number (\@values_1);

						# Check to make sure the values are equal for the 2 occurrences 
						if ( ($values_0[1] == $values_1[1]) && ($values_0[2] == $values_1[2]) && ($values_0[3] == $values_1[3]) ) {

							# NOP
							logger "\t\tC_Comp values are equal for both occurences typ/min/max.\n";

						}

						else {

							logger "\t\tC_Comp values are not equal for both occurences typ/min/max.\n";

							if ( ($values_0[1] > $values_0[2]) && ( $values_0[1] < $values_0[3]) ) {}
							else {
								$problems++;
								logger "\t\tC_Comp values not in ascending order for typ/min/max.\n";
							}

							if ( ($values_1[1] > $values_1[2]) && ( $values_1[1] < $values_1[3]) ) {}
							else {
								$problems++;
								logger "\t\tC_Comp values not in ascending order for typ/min/max.\n";
							}

						}

						dprint ( INSANE, "$values_0[1] $values_0[2] $values_0[3]\n" );
						
					}
					
				}

			}

		}

	}

	return $problems;

}

# Make sure that voltage rangelines contain approporiate values corresponding to the model.
sub process_vddq_voltages(%) {

	my $voltage_range_ref = shift;
	my %voltage_ranges    = %{$voltage_range_ref};
	my $problems   = 0;

	logger "Processing VDDQ Voltage Ranges.\n";
	foreach my $file (keys(%voltage_ranges)){
		
		my %models = %{$voltage_ranges{"$file"}};
		foreach my $model (keys(%models)){

			my $line   = $models{$model};
			if ($line eq NULL_VAL){
				logger "\t$file : $model => $line.\n";
				$problems++;
				next;
			}

			my @values = split(/\s+/, $line);
			@values = apply_get_number (\@values);

			my $voltage = map_voltage($model);

			dprint(SUPER, "$model => $voltage.\n");
			if (@values == 5 && ( $values[2] == $voltage || $values[3] == $voltage || $values[4] == $voltage) ){
				# NOP
			}
			else {
				logger "\t$file : $model => $line.\n";
				logger "\t\tExpected typical voltage = $voltage.\n";
				$problems++;
			}

		}
			
	}
	logger "Done processing.\n";

	return $problems;

}

# =============================
# QUALITY ASSURANCE FUNCTIONS
# =============================

sub check_number_files($$) {

	my $non_clipped_count = shift;
	my $clipped_count     = shift;

	#if the number of clipped and non clipped files must match, otherwise the QA will not run
	if($clipped_count != $non_clipped_count){
		fatal_error ("Number of files in clipped and non_clipped folders is not equal. Exiting.");	
		return NULL_VAL;	
	}
	else {	
		alert (1, "Number of files in clipped and non_clipped folders is equal.\n", map_check_severity());		
	}

}

sub check_ibis_with_ibischk ($$) {

	my $clipped_files_ref         = shift;
	my $non_clipped_files_ref     = shift;
	
	my %clipped_files      = %{$clipped_files_ref};
	my %non_clipped_files  = %{$non_clipped_files_ref};			
	my %ibis_files = (%clipped_files, %non_clipped_files);
	
	my $log_file_passed = "";
	my $log_file_failed = "";
	
	my @names_of_skipped;
	
	logger "\nChecking IBIS files with IBISCHK tool...\n";
	
	for my $ibs_name (keys %ibis_files) {
	
		write_file($ibis_files{"$ibs_name"}, "$ibs_name");
		
		my @log_of_cmd = run_system_cmd("$RealBin/../lib/ibischk7 $ibs_name");
		
		if ( $log_of_cmd[0] =~ m/File Failed/ ) {
			$log_file_failed = $log_file_failed . $log_of_cmd[0];
		} elsif ( $log_of_cmd[0] =~ m/File Passed/ ) {
			$log_file_passed = $log_file_passed . $log_of_cmd[0];
		} else {
			push(@names_of_skipped, $ibs_name)
		}
		
		run_system_cmd("rm -f $ibs_name");
		
	}
	
	if ( $log_file_failed eq "" ) {
		alert(1, "The IBISCHK hasn't found any errors.\n", map_check_severity());
		logger $log_file_passed;
	} else {
		alert(0, "The IBISCHK has found errors in some files.\n", map_check_severity());
		logger $log_file_failed;
		logger $log_file_passed;
	}
	
	for ( @names_of_skipped ) {
		wprint( "Skipping checks for $_\n" );
	}

}

sub check_file_sizes($$) {
	
	my $file_name_data_ref     = shift;
	my $depotPath              = shift;

	my %file_data  = %{$file_name_data_ref};
	my @m_file_name_clipped     = @{$file_data{'names_clipped_ref'}};
	my @m_file_name_non_clipped = @{$file_data{'names_non_clipped_ref'}};
	
	#Make sure the clipped ibis file is always larger than the non clipped.
	for (my $i = 0; $i < @m_file_name_non_clipped; $i++) {
		
		my ($sizeClipped, $stderr, $return) = run_system_cmd("p4 sizes $depotPath/clipped/$m_file_name_clipped[$i]", NONE);
		my$p            = index($sizeClipped," ");
		$sizeClipped    = substr($sizeClipped,$p+1);
		$p              = index($sizeClipped," ");
		$sizeClipped    = substr($sizeClipped,0,$p);

		my ($sizeNonClipped, $err, $ret) = run_system_cmd("p4 sizes $depotPath/non_clipped/$m_file_name_non_clipped[$i]", NONE);
		$p                 = index($sizeNonClipped," ");
		$sizeNonClipped    = substr($sizeNonClipped,$p+1);
		$p                 = index($sizeNonClipped," ");
		$sizeNonClipped    = substr($sizeNonClipped,0,$p);		

		if ($sizeClipped >= $sizeNonClipped) { 			
			alert (0, "$m_file_name_clipped[$i] is larger than it's non_clipped equivalent $m_file_name_non_clipped[$i].\n", map_check_severity());
			logger "$m_file_name_clipped[$i] is larger than it's non_clipped equivalent $m_file_name_non_clipped[$i]\n\n";			
		}
		else{			
			logger "$m_file_name_clipped[$i] is smaller than it's non_clipped equivalent $m_file_name_non_clipped[$i]\n\n";
		}

	}

	alert (1, "Clipped files are smaller than their non_clipped versions.\n", map_check_severity());

}

sub check_model_numbers ($$) {

	my $model_data_ref         = shift;
	my $file_name_data_ref     = shift;
	
	my %model_data = %{$model_data_ref};
	my %file_data  = %{$file_name_data_ref};

	my @modelCountNonClipped  = @{$model_data{'modelCountNonClipped_ref'}};
	my @modelCountClipped     = @{$model_data{'modelCountClipped_ref'}};  
	my @modelListNonClipped   = @{$model_data{'modelListNonClipped_ref'}};
	my @modelListClipped      = @{$model_data{'modelListClipped_ref'}}; 

	my @file_name_clipped     = @{$file_data{'names_clipped_ref'}};
	my @file_name_non_clipped = @{$file_data{'names_non_clipped_ref'}};

	dprint SUPER, "model list clipped/non-clipped\n";
	dprint SUPER, (Dumper @modelListClipped)."\n";
	dprint SUPER, (Dumper @modelListNonClipped)."\n";

	#ensure that the model counts are not 0.
	if (! @modelCountClipped ){
		
		alert (0, "[Model selector] not found in the files. Exiting.\n", map_check_severity());
		
		exit;

	}
	elsif (! @modelCountNonClipped){
		
		alert (0, "[Model selector] not found in the files. Exiting.\n", map_check_severity());
		
		exit;

	}
	else {

		#sort the lists
		foreach (my $i = 0; $i < @file_name_clipped; $i++){ 						
		  
		  if (length $modelListClipped[$i]) {			  			    
		  
		    @{$modelListClipped[$i]}    = sort @{$modelListClipped[$i]};
		    @{$modelListNonClipped[$i]} = sort @{$modelListNonClipped[$i]}			

		  }			

		}

		my $problem = 0;

		#This will check the number of models in the clipped and non clipped versions of each IBIS file
		# and will die if a mismatch is found in the number of models
		foreach (my $i = 0; $i < @file_name_clipped; $i++){

			if (not length $modelCountClipped[$i] or not length $modelCountNonClipped[$i]) {			  
			  next;
			}
		
			if($modelCountClipped[$i] != $modelCountNonClipped[$i]){
			
				my $message = "The number of models in $file_name_clipped[$i] is $modelCountClipped[$i], and the number of models in $file_name_non_clipped[$i] is $modelCountNonClipped[$i].";

				alert (0,   "$message\n", map_check_severity());
				logger "$message\n";			
				$problem = 1;

			}

			elsif($modelCountClipped[$i] == $modelCountNonClipped[$i]){
			
				logger "The number of models in $file_name_clipped[$i] and $file_name_non_clipped[$i] matches and is $modelCountClipped[$i]\n";			
				
				for(my $j = 0; $j< $modelCountClipped[$i]; $j++){
					
					if((@{$modelListClipped[$i]}[$j] eq @{$modelListNonClipped[$i]}[$j]) != 1){
						iprint ("@{$modelListClipped[$i]}[$j] @{$modelListNonClipped[$i]}[$j]\n");
						alert (0, "The names of models in $file_name_non_clipped[$i] and $file_name_clipped[$i] do not match.\n", map_check_severity());
						$problem = 1;
					}

				}			

			}

		} 
	
		if (!$problem ) {
	
		  alert (1, "The numbers and the names of models in clipped and non-clipped files match.\n", map_check_severity());
	
		}
	
		else {
	
		  alert (0, "The numbers and the names of models in clipped and non-clipped files do not match.\n", map_check_severity());
	
		}
	
	}

}

sub check_waveform_lengths($$) {

	# ALGORITHM:
	# First : Get the number of data points for each of the models in each of the files 
	# Second: Compare the number of data points in each of the clipped and non clipped models and make sure that clipped data are smaller than 	non-clipped data

	my $model_data_ref         = shift;
	my $file_name_data_ref     = shift;
	
	my %model_data = %{$model_data_ref};
	my %file_data  = %{$file_name_data_ref};

	my @modelCountNonClipped  = @{$model_data{'modelCountNonClipped_ref'}};
	my @modelCountClipped     = @{$model_data{'modelCountClipped_ref'}};  
	my @modelListNonClipped   = @{$model_data{'modelListNonClipped_ref'}};
	my @modelListClipped      = @{$model_data{'modelListClipped_ref'}}; 

	my @file_name_clipped     = @{$file_data{'names_clipped_ref'}};
	my @file_name_non_clipped = @{$file_data{'names_non_clipped_ref'}};
	my %clipped_files         = %{$file_data{'clipped_files_ref'}};
	my %non_clipped_files     = %{$file_data{'non_clipped_files_ref'}};

	my ( 
		
		# Hash tables for passing data to the sub called get_number_points_per_section
		%model_clipped_data,
		%model_non_clipped_data,

		# clipped and non_clipped model locations
		%clipped_locations,
		%non_clipped_locations

	);

	$model_clipped_data{'modelCount_ref'} = \@modelCountClipped;
	$model_clipped_data{'modelList_ref'}  = \@modelListClipped;

	$model_non_clipped_data{'modelCount_ref'} = \@modelCountNonClipped;
	$model_non_clipped_data{'modelList_ref'}  = \@modelListNonClipped;
	
	# Get the location of all models in the clipped ibis model files
	for (my $i = 0; $i < @file_name_clipped; $i++) {

		my $filename = $file_name_clipped[$i];
		my @array    = @{$clipped_files{"$filename"}};
				
		# If there are no models for this file then skip.
		if ( ! $modelCountClipped[$i] || ! defined $modelCountClipped[$i] ) {			
			eprint("Could not get model counts for $filename.\n");
			$clipped_locations{"$filename"} = NULL_VAL;	
			next;
		}

		my $answer = get_model_locations( \%model_clipped_data, \@array );
						
		$clipped_locations{"$filename"} = $answer;
		
	}

	# Find the count of rising/falling/composite current waveform data in each of the models in each of the clipped files.
	foreach my $file (keys(%clipped_locations)) {

		dprint (HIGH, "Parsing $file.\n");

		if ( $clipped_locations{"$file"} eq NULL_VAL ){
			next;
		}

		my %file_hash = %{$clipped_locations{"$file"}} ;

		foreach my $model (keys( %file_hash )) {
						
			my $start = ${$file_hash{"$model"}}{"first"};
			my $last  = ${$file_hash{"$model"}}{"last"};
			
			if ($last eq NULL_VAL) {
				eprint ("$file : $model not searchable. Erroneous data.\n");
				next;
			}
		
			my $rising_count     = count_number_lines_in_section (qr/\[Rising\swaveform\]/  , $clipped_files{"$file"}, $start, $last);
			my $falling_count    = count_number_lines_in_section (qr/\[Falling\swaveform\]/ , $clipped_files{"$file"}, $start, $last);
			my $composite_count  = count_number_lines_in_section (qr/\[Composite\scurrent\]/, $clipped_files{"$file"}, $start, $last);

			${$file_hash{"$model"}}{"rising_count"}	   = $rising_count;
			${$file_hash{"$model"}}{"falling_count"}   = $falling_count;
			${$file_hash{"$model"}}{"composite_count"} = $composite_count;

		}

	}

	# Get the location of all models in the non clipped ibis model files		
	for (my $i = 0; $i < @file_name_non_clipped; $i++) {

		my $filename = $file_name_non_clipped[$i];
		my @array    = @{$non_clipped_files{"$filename"}};
				
		# If there are no models for this file then skip.
		if ( ! $modelCountNonClipped[$i] || ! defined $modelCountNonClipped[$i] ) {			
			eprint("Could not get model counts for $filename.\n");
			$non_clipped_locations{"$filename"} = NULL_VAL;	
			next;
		}

		my $answer = get_model_locations( \%model_non_clipped_data, \@array );
						
		$non_clipped_locations{"$filename"} = $answer;
		
	}

	# Find the count of rising/falling/composite current waveform data in each of the models in each of the non clipped files.
	foreach my $file (keys(%non_clipped_locations)) {

		dprint (HIGH, "Parsing $file.\n");

		if ( $non_clipped_locations{"$file"} eq NULL_VAL ){
			next;
		}

		my %file_hash = %{$non_clipped_locations{"$file"}} ;

		foreach my $model (keys( %file_hash )) {
						
			my $start = ${$file_hash{"$model"}}{"first"};
			my $last  = ${$file_hash{"$model"}}{"last"};
			
			if ($last eq NULL_VAL) {
				eprint ("$file : $model not searchable. Erroneous data.\n");
				next;
			}
		
			my $rising_count     = count_number_lines_in_section (qr/\[Rising\swaveform\]/, $non_clipped_files{"$file"}, $start, $last);
			my $falling_count    = count_number_lines_in_section (qr/\[Falling\swaveform\]/, $non_clipped_files{"$file"}, $start, $last);
			my $composite_count  = count_number_lines_in_section (qr/\[Composite\scurrent\]/, $non_clipped_files{"$file"}, $start, $last);

			${$file_hash{"$model"}}{"rising_count"}	   = $rising_count;
			${$file_hash{"$model"}}{"falling_count"}   = $falling_count;
			${$file_hash{"$model"}}{"composite_count"} = $composite_count;

		}

	}

	compare_waveform_lengths(\%non_clipped_locations, \%clipped_locations);

}

sub check_ibis_summary_file {

	my $ibis_summary_ref = shift;
	my @ibis_summary     = @{$ibis_summary_ref};

	my @current_component_names;
	my @components_that_have_slew_codes;
	my @components_that_do_not_have_slew_codes;	

	my $not_found = 0;
	my $name = 0;
	my $componentName;
	my $componentName1;

	#Reading the IBIS summary file to ensure all of the models have slew rate codes
	foreach my $line (@ibis_summary){

		# check to see whether the process parameter exists in the summary file.
		if ($line =~ /.*PROCESS:.*/i ) {
			
			my @array = split (/:/, $line);						

			if (@array ==2 ){
				if (scalar trim $array[1]) {
					alert (0, "PROCESS parameter found in the summary file\n", map_check_severity());
					logger "PROCESS parameter found in the summary file:$array[1]\n\n", map_check_severity();
				}
			}

		}				

		if($name == 0){
			
			if(index($line,"[File name]") != -1){
				
				my @spl = split /\s+/, $line ;
				
				@current_component_names = grep { ! /"\|"/ } @spl [ 2 .. $#spl ];
				
				$name = 1;

			}

		}

		elsif($name == 1){
			
			if(index($line,"# MODEL_NAME")!= -1){
				
				if( index($line,"Slew_Rate_codes")!= -1 || index($line,"csrLsTxSlewLPPU | VIO_csrLsTxSlewDPU | TxModeCtl |csrTxSlewPD") != -1 ){
					
					push @components_that_have_slew_codes, @current_component_names;					

				}
				else{
					
					push @components_that_do_not_have_slew_codes, @current_component_names;					
					$not_found = 1;
				}
			
				$name = 0;
				@current_component_names = ();

			}

		}

	}

	if (@components_that_do_not_have_slew_codes ) {

		logger "Models in the following files do NOT have a slew rate code table\n";

		foreach my $code (@components_that_do_not_have_slew_codes) {
			
			logger "$code\n";

		}

		logger "\n";

	}

	if (@components_that_have_slew_codes ) {

		logger "Models in the following files have a slew rate code table\n";

		foreach my $code (@components_that_have_slew_codes) {
			
			logger "$code\n";

		}
		
		logger "\n";

	}					

	if ($not_found) {
		alert (0, "Slew rate codes do not exist for some models.\n", map_check_severity());
	} 
	else {
		alert (1, "Slew rate codes exist for all models.\n", map_check_severity());
	}
}

sub check_model_descriptions($$$) {

	my $non_clipped_descriptions_ref = shift;
	my $clipped_descriptions_ref     = shift;
	my $ibis_summary_ref			 = shift;	

	my @ibis_summary		     = $ibis_summary_ref;
	my %non_clipped_descriptions = %{$non_clipped_descriptions_ref};
	my %clipped_descriptions	 = %{$clipped_descriptions_ref};

	my $error = 0;
	foreach my $key (keys %non_clipped_descriptions){
		my @array = split /\s+/, $non_clipped_descriptions{$key};
		my $answer = map_name $key, $array[1];
		if (!$answer) {
			logger "Does does not match summary:\t\t$array[1]:$key.\n";	
			$error = 1;			
		}		
		else {
			logger "Matches summary:\t\t$array[1]:$key.\n";	
		}
	}

	foreach my $key (keys %clipped_descriptions){
		my @array = split /\s+/, $non_clipped_descriptions{$key};
		my $answer = map_name $key, $array[1];
		if (!$answer) {
			logger "Does not match summary:\t\t$array[1]:$key.\n";	
			$error = 1;			
		}		
		else {
			logger "Matches summary:\t\t$array[1]:$key.\n";	
		}
	}

	my $model_found = 0;	
	foreach my $line (@ibis_summary){

		if ($line =~ /^#.*model_name.*/i){
			$model_found = 1;						
		}
		elsif ($line =~ /^#-+/) {
			if ($model_found) {$model_found = 0;}
		}
		elsif ($model_found and $line =~ /^tx.*_/) {
			my @array = split /\s+/, $line;
			my $answer = map_name $array[0], $array[1];
			if (!$answer) {
				logger "$array[0] does not match IBIS summary file description: $array[1].\n";	
				$error = 1;			
			}		
			else {
				logger "$array[0] matches IBIS summary file description: $array[1].\n";	
			}
		}

	}	

	if ($error) {
		alert (0, "Model descriptions do not match model names.\n", map_check_severity());
		return;
	}

	alert (1, "Model descriptions match model names.\n", map_check_severity());
	
}

sub check_c_comp_values($$){

	# Ensure that C_COMP* sections have not been defined twice per model
	# As per IBIS ver7.1:
	# 	 - The C_comp, C_comp_pullup, C_comp_pulldown, C_comp_power_clamp, and 
	#	 - C_comp_gnd_clamp (referred to hereinafter as “C_comp_*”) subparameters define die 
	#	 - capacitance.

	my $model_data_ref    = shift;
	my $file_data_ref     = shift;

	my %model_data = %{$model_data_ref};
	my %file_data  = %{$file_data_ref};

	my @modelCountNonClipped  = @{$model_data{'modelCountNonClipped_ref'}};
	my @modelCountClipped     = @{$model_data{'modelCountClipped_ref'}};  
	my @modelListNonClipped   = @{$model_data{'modelListNonClipped_ref'}};
	my @modelListClipped      = @{$model_data{'modelListClipped_ref'}}; 

	my %files_clipped         = %{$file_data{'clipped_files_ref'}};
	my %files_non_clipped     = %{$file_data{'non_clipped_files_ref'}};

	my %model_clipped_data;
	$model_clipped_data{'modelCount_ref'} = \@modelCountClipped;
	$model_clipped_data{'modelList_ref'}  = \@modelListClipped;

	my %model_non_clipped_data;
	$model_non_clipped_data{'modelCount_ref'} = \@modelCountNonClipped;
	$model_non_clipped_data{'modelList_ref'}  = \@modelListNonClipped;

	my %clipped_ccomps     = ();
	my %non_clipped_ccomps = ();
	my %problem_hash       = ();

	# Find all the clipped models' c_comp lists
	foreach my $file (keys(%files_clipped)){

		my @array = @{$files_clipped{$file}};
		my $answer = get_model_locations( \%model_clipped_data , \@array );
		if ($answer eq NULL_VAL) {
			eprint("Could not obtain model locations inside $file for checking C_comp values.\n");
		}
				
		my %model_locations  = %{$answer};

		$clipped_ccomps{"$file"} = {};

		foreach my $model (keys(%model_locations)) {

			# Find all C_comp values inside a model.
			my $start = ${$model_locations{"$model"}}{"first"};
			my $last  = ${$model_locations{"$model"}}{"last"};

			# Store the C_comp* lines in this array
			my @c_comp_locations = ();

			for (my $i = $start; $i < $last; $i++) {

				my $line = $array [$i];
				if ($line =~ /c_comp/ig){
					push(\@c_comp_locations, $line);
				}

			}

			${$clipped_ccomps{"$file"}}{$model} = \@c_comp_locations;

		}
						
	}	

	# Process the c_comp values for clipped files
	my $problems = process_c_comps(\%clipped_ccomps);		
	if ($problems > 0){
		insert_at_key(\%problem_hash, "clipped", $problems);
	}

	# Find all the non-clipped models' c_comp lists
	foreach my $file (keys(%files_non_clipped)){

		my @array = @{$files_non_clipped{$file}};
		my $answer = get_model_locations( \%model_non_clipped_data , \@array );
		if ($answer eq NULL_VAL) {
			eprint("Could not obtain model locations inside $file for checking C_comp values.\n");
		}
				
		my %model_locations  = %{$answer};

		$non_clipped_ccomps{"$file"} = {};

		foreach my $model (keys(%model_locations)) {

			# Find all C_comp values inside a model.
			my $start = ${$model_locations{"$model"}}{"first"};
			my $last  = ${$model_locations{"$model"}}{"last"};

			# Store the C_comp* lines in this array
			my @c_comp_locations = ();

			for (my $i = $start; $i < $last; $i++) {

				my $line = $array [$i];
				if ($line =~ /c_comp/ig){
					push(\@c_comp_locations, $line);
				}

			}

			${$non_clipped_ccomps{"$file"}}{$model} = \@c_comp_locations;

		}
						
	}	

	# Process the c_comp values for clipped files
	$problems = process_c_comps(\%non_clipped_ccomps);		
	if ($problems > 0){
		insert_at_key(\%problem_hash, "non_clipped", $problems);
	}

	if (keys(%problem_hash) > 0) {

		alert(0, "C_comp check found problems in some files.\n", map_check_severity());

	}

	else {

		alert(1, "C_comp check passed without problems.\n", map_check_severity());

	}

	dprint (SUPER, Dumper(\%problem_hash)."\n");

}

sub compare_waveform_lengths($$) {

	my $nc_hash_ref  = shift;
	my $c_hash_ref   = shift;	

	my %nc_hash = %{$nc_hash_ref};
	my %c_hash  = %{$c_hash_ref};
  
	logger "Now checking length of rising and falling waveforms.\n";	

	my $problem = 0;

	dprint (SUPER, "non-clipped\n");
	dprint (SUPER, Dumper(%nc_hash)."\n");	
	dprint (SUPER, "clipped\n");
	dprint (SUPER, Dumper(%c_hash)."\n");
	
	my @keys_clipped     = sort (keys (%c_hash));
	my @keys_non_clipped = sort (keys (%nc_hash));

	if (@keys_clipped != @keys_non_clipped) {

		eprint ("Model file counts not equal in clipped and non-clipped directories. Skipping waveform length check.\n");
		return;

	}

	for (my $i = 0; $i < @keys_clipped; $i++) {

		my $nc_file = $keys_non_clipped[$i];
		my $c_file  = $keys_clipped[$i];

		logger "=========== $c_file <=> $nc_file ========= \n" ;

		if ( exists  $nc_hash{"$nc_file"} && exists  $c_hash{"$c_file"} ) {
			
			if ( $nc_hash{"$nc_file"} eq NULL_VAL || $c_hash{"$c_file"} eq NULL_VAL ){
				$problem++;
				next;
			}

			my %nc_model_hash = %{$nc_hash{"$nc_file"}};
			my %c_model_hash  = %{$c_hash{"$c_file"}};

			my @models_clipped     = keys (%c_model_hash);
			my @models_non_clipped = keys (%nc_model_hash);

			if (@models_clipped != @models_non_clipped) {
				eprint ("Model counts not equal in $nc_file and $c_file. Skipping waveform length check.\n");
				return;
			}

			for (my $j = 0 ; $j < @models_clipped ; $j++ ) {

				my $nc_model = $models_non_clipped[$j];
				my $c_model  = $models_clipped[$j];

				if ( defined($nc_model_hash{"$nc_model"}) && defined($c_model_hash{"$c_model"}) ) {

					my %data_nc = %{$nc_model_hash{"$nc_model"}};
					my %data_c  = %{$c_model_hash{"$c_model"}};

					my $rising_count_clipped    = $data_c{"rising_count"}; 
					my $falling_count_clipped   = $data_c{"falling_count"}; 
					my $composite_count_clipped = $data_c{"composite_count"}; 

					my $rising_count_non_clipped    = $data_nc{"rising_count"}; 
					my $falling_count_non_clipped   = $data_nc{"falling_count"}; 
					my $composite_count_non_clipped = $data_nc{"composite_count"}; 

					dprint (SUPER, "$c_file $nc_file : $c_model $nc_model.\n");
					dprint (SUPER, "$rising_count_clipped <=> $rising_count_non_clipped\n");
					dprint (SUPER, "$falling_count_clipped <=> $falling_count_non_clipped\n");
					dprint (SUPER, "$composite_count_clipped <=> $composite_count_non_clipped\n");

					logger "\t$c_model <=> $nc_model.\n";
					logger "\t\tRISING: $rising_count_clipped <=> $rising_count_non_clipped\n";
					logger "\t\tFALLING: $falling_count_clipped <=> $falling_count_non_clipped\n";
					logger "\t\tCOMPOSITE_CURRENT: $composite_count_clipped <=> $composite_count_non_clipped\n";

					if (
						
						$rising_count_clipped        eq NULL_VAL ||
						$rising_count_non_clipped    eq NULL_VAL ||
						$falling_count_clipped       eq NULL_VAL ||
						$falling_count_non_clipped   eq NULL_VAL ||
						$composite_count_clipped     eq NULL_VAL ||
						$composite_count_non_clipped eq NULL_VAL

					) {

						wprint("Skipping checks for $c_model and $nc_model.\n");
						next;

					}

					if (
						
						$rising_count_clipped    > $rising_count_non_clipped ||
						$falling_count_clipped   > $falling_count_non_clipped ||
						$composite_count_clipped > $composite_count_non_clipped

					) {
						$problem++;
						wprint("Clipped count greater for $c_file: $c_model.\n");
					}

				}

				else {

					eprint ("$nc_model or $c_model not found in $nc_file and $c_file. Skipping\n");
					next;

				}

			}
			
		}

		
		else {

			eprint("$nc_file or $c_file does not exist.\n");

		}
			
	}

	if ($problem > 0){

		alert (0, "Waveform lengths are not smaller for cliped files when compared to non-clipped files. $problem problems.\n", map_check_severity());

	}

	else {
		alert (1, "Waveform lengths are smaller for cliped files when compared to non-clipped files.\n", map_check_severity());
	}

}

sub check_vddq_correctness($$$){

	my $model_data_ref    = shift;
	my $file_data_ref     = shift;
	my $ibis_summary_ref  = shift;

	my %model_data = %{$model_data_ref};
	my %file_data  = %{$file_data_ref};

	my @modelCountNonClipped  = @{$model_data{'modelCountNonClipped_ref'}};
	my @modelCountClipped     = @{$model_data{'modelCountClipped_ref'}};  
	my @modelListNonClipped   = @{$model_data{'modelListNonClipped_ref'}};
	my @modelListClipped      = @{$model_data{'modelListClipped_ref'}}; 

	my %files_clipped         = %{$file_data{'clipped_files_ref'}};
	my %files_non_clipped     = %{$file_data{'non_clipped_files_ref'}};

	my %model_clipped_data;
	$model_clipped_data{'modelCount_ref'} = \@modelCountClipped;
	$model_clipped_data{'modelList_ref'}  = \@modelListClipped;

	my %model_non_clipped_data;
	$model_non_clipped_data{'modelCount_ref'} = \@modelCountNonClipped;
	$model_non_clipped_data{'modelList_ref'}  = \@modelListNonClipped;

	my %clipped_ranges     = ();
	my %non_clipped_ranges = ();
	my %summary_file_ranges= ();
	my %problem_hash       = ();

	# Find all the clipped models' [voltage range] sections
	foreach my $file (keys(%files_clipped)){

		my @array = @{$files_clipped{$file}};
		my $answer = get_model_locations( \%model_clipped_data , \@array );
		if ($answer eq NULL_VAL) {
			eprint("Could not obtain model locations inside $file for checking C_comp values.\n");
		}
				
		my %model_locations  = %{$answer};

		$clipped_ranges{"$file"} = {};

		foreach my $model (keys(%model_locations)) {

			# Find all voltage range lines inside a model.
			my $start = ${$model_locations{"$model"}}{"first"};
			my $last  = ${$model_locations{"$model"}}{"last"};

			for (my $i = $start; $i < $last; $i++) {

				my $line = $array [$i];
				if ($line =~ /\[voltage range\]/ig){
					${$clipped_ranges{"$file"}}{$model} = $line;
				}
												
			}
			
		}				
				
	}

	my $answer = process_vddq_voltages(\%clipped_ranges);

	# Find all the non-clipped models' [voltage range] sections
	my @list = (keys(%files_non_clipped));
	for (my $idx = 0; $idx < scalar(@list); $idx++) {

		my $file = $list[$idx];
		my @array = @{$files_non_clipped{$file}};
		my $answer = get_model_locations(\%model_non_clipped_data, \@array);
		if ($answer eq NULL_VAL) {
			eprint("Could not obtain model locations inside $file for checking C_comp values.\n");
		}

		my %model_locations = %{$answer};

		$non_clipped_ranges{"$file"} = {};

		foreach my $model (keys(%model_locations)) {

			# Find all voltage range lines inside a model.
			my $start = ${$model_locations{"$model"}}{"first"};
			my $last = ${$model_locations{"$model"}}{"last"};

			for (my $i = $start; $i < $last; $i++) {

				my $line = $array[$i];
				if ($line =~ /\[voltage range\]/ig) {
					${$non_clipped_ranges{"$file"}}{$model} = $line;
				}

			}

		}

	}

	$answer += process_vddq_voltages(\%non_clipped_ranges);

	# Find all the ibis summary file's PVT values
	my $summary_codes_ref                = get_ibis_summary_vio_values($ibis_summary_ref);	
	my %summary_codes                    = %{$summary_codes_ref};
	$summary_file_ranges{"summary_file"} = {};

	foreach my $model (keys(%summary_codes)) {

		my @value_array = @{$summary_codes{$model}};

		for (my $i = 0; $i < @value_array; $i++) {

			my $vddq_value = ${$value_array[$i]}[1];
			my $real       = map_voltage($model);
			
			if (! verify(10, $real , $vddq_value ) ) {

				$answer++;
				dprint (SUPER, "$model = $vddq_value. But it should be $real.\n");
				logger "\t\tIBIS Summary: $model => $vddq_value.\n";

			}

		}	

	}
	
	if ($answer) {
		alert(0, "VDDQ voltage ranges are not consistent with model names.\n", map_check_severity());
	}
	else {	
		alert(1, "VDDQ voltage range check passed.\n", map_check_severity());	
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
	if (! $DEBUG) {
		utils__script_usage_statistics("ibis_quality.pl", $VERSION); 	
	}
}

# =============================
# USAGE
# =============================

sub usage($) {
    my $exit_status = shift;
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

	EXAMPLE: $0 -proj ddr43/d528-ddr43-ss11lpp18/1.00a -macro dwc_ddrphy_txrxca_ew -depotPath //depot/products/ddr43_lpddr4_v2/project/d528-ddr43-ss11lpp18

EOP
    exit($exit_status);
}
