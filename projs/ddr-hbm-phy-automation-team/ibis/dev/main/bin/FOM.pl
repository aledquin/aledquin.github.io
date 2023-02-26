#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : std_template.pl
# Author  : Helen Cui
# Date    : December 17, 2021 
# Purpose : Check FOM (Figure of Merit) values inside FOM files.
#
# Modification History
#     000 Helen Cui December 17, 2021 
#         Created this script
#     001 Harsimrat Singh Wadhawan, 18 March 2022
#         Adding Perl Standard Template. 
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

# --INCLUDES ----------------------#

use lib "$RealBin/../lib/perl";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
# use utilities;
#----------------------------------#

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $VERSION      = '2022ww20';
our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log"; 
#--------------------------------------------------------------------#

BEGIN {
    our $AUTHOR='Helen Cui';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
	Main();
END {
   	footer();
	write_stdout_log( $LOGFILENAME );
}

sub Main {

	my ( $config,  $optHelp, $optNousage );
    my @args = @ARGV; # copy @ARGV because 'process_cmd_line_args' modifies @ARGV
    
    GetOptions(
        "filename=s"  => \$config,             # config files for check                
        "help"        => \$optHelp,            # Prints help
		"d=i"		  => \$DEBUG,
		"v=i"		  => \$VERBOSITY,
        "nousage"     => \$optNousage,
     );

	if ($optHelp){
		 pod2usage(   -verbose => 2,
                      -exitval => 0,
             		  -noperldoc => 1  );
		 exit(0);
	}

	unless ( $DEBUG || $optNousage){
        utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@args);
    }
    
	if (!$config ) {
		fatal_error("Please enter the file name through the -filename option.\n");
	}

	my $verbosity=NONE;
	my $converted_file = time()."-$config-converted.txt";

	my ($answer, $retval) = run_system_cmd("pdftotext -layout $config $converted_file", $verbosity);	
	dprint(HIGH, "PDF2TEXT: $answer : $retval");

	if ($retval) {
		fatal_error "Failed to execute pdf2text. $retval\n"
	}

	my @file_array = read_file("$converted_file");		
	my @file_noblanks = remove_blanks(\@file_array);
	dprint(SUPER, Dumper(\@file_noblanks)."\n");

	my @count;
	my $idx = 0;
	my $idx_next = 0;

	# Pre-initialise the count arrays
	$count[0] = 0;
	
	#get model_name and value and store in a hash table 
	for (my $i = 0; $i < @file_noblanks; $i = $i + 1){
		if($file_noblanks[$i] =~ /FOM Table/i){
			my $start_index = $i;	

			#increment line by line until end of file 
			for (my $j = 0; $j < (@file_noblanks - $i); $j = $j + 1){
				my $next_line = $file_noblanks[$start_index + $j];
						
				#check if the first few character is model name 
				if($next_line =~ m/^tx/i){		
				
					#split with _ 
					my @model_name = split/_/, $next_line;
					dprint(HIGH, $model_name[0]);

					#check if nextline is the model name starts with tx		
					if($model_name[0] =~ /tx/){
					
						my $temp = $file_noblanks[$start_index + $j + 1];
						
						#the end of the FOM table   
						my $next_next_line = $file_noblanks[$start_index + $j + 2];
						if($next_next_line !~ m/^tx/i and $next_next_line !~ m/\s*([\d]+\.[\d]+)\s*([\d]+\.[\d]+)\s*([\d]+\.[\d]+)\s*$/){  
							$j = @file_noblanks-$i;			  
						}
					
						my @row_next = split('\s+', $temp);
						
						#put the last three elements in another array
						my $max_index = $#row_next;
						my @FOM_values = ($row_next[$max_index-2], $row_next[$max_index-1], $row_next[$max_index]);
						
						#store the model name as hash key
						my %hash_FOMTable = ($next_line => [$FOM_values[0], $FOM_values[1], $FOM_values[2]]);
						viprint (HIGH, Dumper(%hash_FOMTable)."\n");

						#check if all FOM value > 90%
						$idx = $idx + 1;
						if(($hash_FOMTable{$next_line}->[0]) > 90 and ($hash_FOMTable{$next_line}->[1]) > 90 and ($hash_FOMTable{$next_line}->[2]) > 90){
							$count[$idx] = 1;
						}else{
							if(($hash_FOMTable{$next_line}->[0]) < 90){
								iprint "MAX FOM value for model $next_line is < 90%.\n";
								$count[$idx] = 0;
							}
							if(($hash_FOMTable{$next_line}->[1]) < 90){
								iprint "TYP FOM value for model $next_line is < 90%.\n";
								$count[$idx] = 0;
							}
							if(($hash_FOMTable{$next_line}->[2]) < 90){
								iprint "MIN FOM value for model $next_line is < 90%.\n";
								$count[$idx] = 0;
							}
						}
						
						#check the next line
						if($next_next_line =~ m/\s*([\d]+\.[\d]+)\s*([\d]+\.[\d]+)\s*([\d]+\.[\d]+)\s*$/){
						
							my @row_next_next = split('\s+', $next_next_line);
							my $max_index_next = $#row_next_next;
							my @FOM_values_next = ($row_next_next[$max_index_next-2], $row_next_next[$max_index_next-1], $row_next_next[$max_index_next]);
							my %hash_FOMTable_next = ($next_next_line => [$FOM_values_next[0], $FOM_values_next[1], $FOM_values_next[2]]);
							viprint (HIGH, Dumper(%hash_FOMTable_next)."\n");

							#check all FOM value for next_next_line > 90%
							if(($hash_FOMTable_next{$next_next_line}->[0]) > 90 and ($hash_FOMTable_next{$next_next_line}->[1]) > 90 and ($hash_FOMTable_next{$next_next_line}->[2]) > 90){
								push(@count, 1);
							}else{
								if(($hash_FOMTable_next{$next_next_line}->[0]) < 90){
									wprint "MAX FOM value for model $next_line is < 90%.\n";
									push(@count, 0);
								}
								if(($hash_FOMTable_next{$next_next_line}->[1]) < 90){
									wprint "TYP FOM value for model $next_line is < 90%.\n";
									push(@count, 0);
								}
								if(($hash_FOMTable_next{$next_next_line}->[2]) < 90){
									wprint "MIN FOM value for model $next_line is < 90%.\n";
									push(@count, 0);
								}
							}
						}
					}
				}		
			}  
		}
	}
	dprint(HIGH, Dumper(@count)."\n");

	if ( @count == 1 ) {

		eprint("No models found inside this PDF file: $config.\n");
		
	}

	else {

		my $count_0 = 0;
		my $count_1 = 0;
		my $size_of_count = @count;
		for (my $z = 0; $z < ($size_of_count + $idx_next); $z = $z + 1){
			if($count[$z] == 0){
			$count_0 = $count_0 + 1;
			}elsif($count[$z] == 1){
			$count_1 = $count_1 + 1;
			}
		}

		if($count_1 == ($size_of_count - 1)){
			hprint("PASS: All models have FOM values greater than 90% for $config.\n");
		}
		if($count_0 > 1 ){
			eprint("FAIL: Some models do not have FOM values greater than 90% for $config.\n");
		}
		
	}	

	unlink($converted_file);

}

__END__

=head1 NAME

FOM.pl

=head1 DESCRIPTION

Check FOM (Figure of Merit) values inside FOM files.

=head2 ARGS

=over 8

=item B<-filename> IBIS FOM file.

=item B<-help> Show this message and exit.

=item B<-v #> Set verbosity [integer > 0]

=item B<-d #> Set debugging [integer > 0]

=back
