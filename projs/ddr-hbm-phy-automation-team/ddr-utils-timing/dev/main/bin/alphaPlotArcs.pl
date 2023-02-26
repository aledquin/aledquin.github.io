#!/depot/perl-5.14.2/bin/perl
#!/depot/perl-5.8.0/bin/perl
###############################################################################
#
# Name    : alphaPlotArcs
# Author  : N/A
# Date    : N/A
# Purpose : N/A
#
# Modification History
# 			2022-05-26 12:38:49 => Adding Perl template. HSW.
###############################################################################
# use warnings; #Remove this because of too much refactoring
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path getcwd );
use Carp qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Cwd;
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR;              # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version();
our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
#--------------------------------------------------------------------#

BEGIN { our $AUTHOR = 'Multiple Authors'; header(); }

END {
    write_stdout_log("$LOGFILENAME");
    footer();
    utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);
}

#####################################################################################################################################################################
#################################################################################################################################################################
#                                                                                                							            #
# Description: Compares/plots timing arcs of given lib files                                     							            #
#                                                                                                						            	    #
# Developer: Vache Galstyan (Synopsys Armenia, SG) 	                                         							    	    #
# Email:     vache@synopsys.com                                                                  							    	    #
#                                                                                                							    	    #
# Based on Nick Howorth's alphaComparaArcs.pl script						 							    	    #
# Rev History   :                                                                                  							            #
#  Version |     Date    |    Who   |            What                                            							            #
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------  #
#   3.0    | 07 Sep 2016 |   vache  |       - Generating arc comparison log in PDF report to show arc mismatches.                                                   #
#					    - Perform plotting on identical arcs. For any extra arc generate warnings instead of crashing out.		            #
#					    - Adding dedicated plots of slew/load for each timing arc.							            #
#					    - Updated the script to print max difference and difference percentage compared to golden reference. 	            #
#					    - Added GMT time to report PDF. 										            #
# 					    - Added pin direction comparison functionality. 								            #
#					    - Added pin capacitance comparison functionality. 								            #
#					    - Added timing_sense and min_delay_flag attributed for each timing arc. 					            #
#					    - Generating summary report on absolute and persentage differences for each timing arc.			            #
#   3.0_patch1 | 19 Sep 2016 |   vache  |   - Fixed arc comparison section to take into consideration pin/pin_name mismatch.                                        #
#   3.0_patch2 | 11 Oct 2016 |   vache  |   - Added -csv option to create output csv report for port mismatch and timing difference                                 #
#					    - Script generates additional pin csv file which contain all related information for all existing pins	            #
#					    - The last function will later be used for solving cap/pin direction comparison issue as well as for additional checks  #
#   4.0    | 31 Oct 2016 |   vache  |       - Added merge option to turn on/off min_delay and timing_sense in csv report                                            #
#					    - Added sdf option to specify sdf condition list to be plotted: used for bdl/lcdl comparison                            #
#					    - Updated pin attribute comparison to apply to all existing pins (pin_cap only and with timing arcs)	            #
#					    - Added function for max_capacitance and max_transition pin attribute comparison.				            #
#					    - Added Comparison Summary to the PDF report.								            #
#					    - Removed arc mismatch, pin attribute comparison sections from PDF report ( available only in the summary section )     #
#					    - Added detailed overview of all mismatched to CSV report. 							            #
#					    - Renamed lib1 and lib2 options to ref (reference) and cur (current).					            #
#   4.0_patch1 | 31 Oct 2016 |   vache  |   - Added disk cleanup function for /tmp directory during runtime                                                         #
#				            - Added disk cleanup of plot files during runtime  								            #
#   4.0_patch2 | 16 Feb 2017 |   vache  |   - Corrected related_power/related_ground comparison typo for pg lib files                                               #
#					    - Resolved segmentation_fault issue caught durng LCDL comparison.    					            #
#					    - Resolved incorrect CSV reporting for mismatched arcs.							            #
#   4.0_patch3 | 24 Mar 2017 |   vache  |   - Corrected arc comparison bug.                                         					            #
#					    - Added information about value increase/decrease compared to reference.   					            #
#					    - Enhanced CSV arc mismatch reporting for better understanding of mismatch lib.                                         #
#					    - Added UI information in CSV file ( Mantis bug : 19407 )                                                               #
#   4.0_patch4 | 31 Oct 2017 | davidgh  |   - Changed logging order in CSV to have arc and pin mismatch information before PDF generation                           #
#   5.0        | 28 Nov 2017 | davidgh  |   - Updated function for calculating percentage difference, ( Mantis bug : #8813 )                                        #
#					    - Added warning information about percentage difference value.       					            #
#   5.0_patch1 | 21 Dec 2017 | davidgh  |   - Corrected UI information logging in CSV file ( Mantis bug : 25488#c225002)                                            #
#   5.0_patch2 | 19 Jan 2018 | davidgh  |   - Added all timing arcs into CSV file ( Mantis bug : 25488#c227719)                                                     #
#   5.0_patch3 | 05 Feb 2018 | davidgh  |   - Fixed incorect comparision for related_power_pin/related_ground_pin attributes ( Mantis bug : 25488#c229749)          #
#   5.0_patch4 | 14 May 2018 | davidgh  |   - Corrected /tmp issue                                                                                                  #
#   5.0_patch5 | 06 Sep 2018 | davidgh  |   - Corrected message when timing tables are equal ( Mantis bug : 25488#c262036 )                                         #
#   6.0        | 17 Dec 2018 | davidgh  |   - added -pdf option: When 1.) -pdf then generate with pdf 2.) by default it generates without pdf TODO::need validation #
#   6.0_patch1 | 01 Apr 2019 | davidgh  |   - added -opportunity to run script parallel                                                                             #
#####################################################################################################################################################################
#####################################################################################################################################################################

##  The current PERL5LIB causes issues.
BEGIN { delete $ENV{PERL5LIB} }

use strict;
use lib '/depot';
use English;
use Getopt::Long;
use Cwd;
use Pod::Usage;
use Time::localtime;
use Data::Dumper;
use Liberty::Parser;
use Parse::Liberty;
use File::Temp qw/ tempfile tempdir /;
use File::Copy;
use File::Find;
use Getopt::Long;
use PDF::Create;
use lib "$RealBin/../lib/perl/Chart";
use Chart::Gnuplot;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);


my $progName = "alphaCompareLibs";    # Name of the script

# Allowable absolute difference in cap value before providing a warning (pF)
my $threshold_cap_diff_absolute = 0.005;

# Allowable percent difference in cap value before providing a warning (0.05 is 5%)
my $threshold_cap_diff_percent = 0.05;
&Main();
#---------------------------------------------------------------------
sub Main {
    print_function_header();
    my $opt_help;
    my $lib1;
    my $lib2;
    my $cellName;
    my $output_dir;
    my $libFile1;
    my $libFile2;
    my $libPath1;
    my $libPath2;
    my $csvFile1;
    my $csvFile2;
    my $csv_pin_file1;
    my $csv_pin_file2;
    my $csv_output;
    my %pinInfo1;
    my %pinInfo2;
    my $merge_results;
    my $sdfCompare;
    my $ui;
    my $pdf;

    # Get options
    if (
        !GetOptions(
            "help|h"      => \$opt_help,
            "ref=s"       => \$lib1,
            "cur=s"       => \$lib2,
            "cell=s"      => \$cellName,
            "sdf=s"       => \$sdfCompare,
            "ui=s"        => \$ui,
            "csv+"        => \$csv_output,
            "merge+"      => \$merge_results,
            "cap_limit=s" => \$threshold_cap_diff_absolute,
            "pdf"         => \$pdf
        )
      )
    {
        print STDERR &usage;
        exit -1;
    }

    if ( !$threshold_cap_diff_absolute ) {
        $threshold_cap_diff_absolute = 0.005;
    }

    # If asking for help, print help message.
    if ($opt_help) { &usage }

    if ( ( -e $lib1 ) and ( -e $lib2 ) ) {
        if ( $lib1 =~ /(.*)(\w+\.lib)/ ) {
            $libFile1 = $1;
            $libPath1 = $2;
        }
        else {
            die "Wrong lib file specified \n";
        }
        if ( $lib2 =~ /(.*)(\w+\.lib)/ ) {
            $libFile2 = $1;
            $libPath2 = $2;
        }
        else {
            die "Wrong lib file specified \n";
        }
    }
    else {
        die "$lib1 or $lib2 doesn't exist, please check ... \n";
    }

    if ( !$cellName ) {
        print "\nCell name is not specified...\nPlease see the usage:\n";
        &usage;
        die;
    }

    $csvFile1 = $lib1;
    $csvFile2 = $lib2;
    $csvFile1 =~ s/\.lib/.csv/;
    $csvFile2 =~ s/\.lib/.csv/;
    $csv_pin_file1 = $csvFile1;
    $csv_pin_file2 = $csvFile2;
    $csv_pin_file1 =~ s/\.csv/_pin.csv/;
    $csv_pin_file2 =~ s/\.csv/_pin.csv/;

    my @lib_array = ($lib1);

    &ReadLiberty( $lib1, $csvFile1, $csv_pin_file1, \%pinInfo1, $sdfCompare );
    &ReadLiberty( $lib2, $csvFile2, $csv_pin_file2, \%pinInfo2, $sdfCompare );
    &GeneratePDF( $csvFile1, $csvFile2, $cellName, $csv_output, \%pinInfo1, \%pinInfo2, $merge_results, $sdfCompare, $ui, $pdf );

}  # END MAIN

#--------------------------------------------------------------------
sub GetValueFromPair {
    my $Pair = shift;
    if   ( $Pair =~ m/(\S+)\s*:\s*(\S+)/ ) { return $2 }
    else                                   { return }
}

#--------------------------------------------------------------------
sub StdDir {
    my $dir = shift;
    if ( !( defined $dir ) ) { return $dir }
    $dir = lc $dir;

    if    ( $dir eq "in" )    { return "input" }
    elsif ( $dir eq "i" )     { return "input" }
    elsif ( $dir eq "o" )     { return "output" }
    elsif ( $dir eq "b" )     { return "io" }
    elsif ( $dir eq "out" )   { return "output" }
    elsif ( $dir eq "ioput" ) { return "io" }
    elsif ( $dir eq "inout" ) { return "io" }
    else                      { return $dir }
}

#--------------------------------------------------------------------
sub defineWithDefault {
    my $default = shift;
    my $value   = shift;

    if   ( defined $value ) { return $value }
    else                    { return $default }
}

#--------------------------------------------------------------------
sub createString {

    my @arr_ref = @_;

    #print "-----------------\n";

    my $string = "{";

    foreach my $arrref (@arr_ref) {

        #print "bbb $arrref\n";
        if ( $arrref eq "N/A" ) {
            return "N/A";
        }
        $string = $string . "(";
        foreach my $number (@$arrref) {
            $string = $string . "$number,";
        }
        $string = $string . ")";
    }
    $string = $string . "}";
    return $string;
}

#--------------------------------------------------------------------
sub ReadLiberty {
    print_function_header();
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
    my $timingdata = {};
    my $this_table = "";

    my $liberty_file = shift;
    my $csvFile      = shift;
    my $csv_pin_file = shift;
    my $pinInfo      = shift;
    my $sdfCompare   = shift;

    # Removing existing cvs file if present
    if ( -e $csvFile ) {
        unlink($csvFile);
        print "Removing existing CSV file: $csvFile ... \n";
    }
    else {
        print "CSV file $csvFile doesn't exist, proceed ... \n";
    }

    if ( !( -r $liberty_file ) ) { print "Warning:  Liberty file \"$liberty_file\" cannot be read\n"; next }

    my ( @CSVPINFILE, @CSVFILE );
    if ($sdfCompare) {

        # ----------------------------------------------------------------- getting sdf conditions --------------------------------------------------------- #

        my $parser                  = new Liberty::Parser;
        my $library_group           = $parser->read_file($liberty_file);
        my $lib_name                = $parser->get_group_name($library_group);
        my $cell_group              = $parser->locate_group_by_type( $library_group, "cell" );
        my $cell_name               = $parser->get_group_name($cell_group);
        my @pins                    = $parser->get_groups_by_type( $cell_group, "pin" );
        my $default_max_capacitance = GetValueFromPair( $parser->get_attr_with_value( $library_group, "default_max_capacitance" ) );
        my $default_max_transition  = GetValueFromPair( $parser->get_attr_with_value( $library_group, "default_max_transition" ) );

        push(@CSVFILE, sprintf(
            "%-30s\t%10s\t%30s\t%50s\t%100s\t%100s\t%20s\t%30s\t%30s\t%30s\t%10s\t%10s\t%10s\t%10s\t%10s\n",
            "pin_name", "direction", "pincap", "related_pin", "sdf_condition", "timing_sense",
            "min_delay_flag", "index1", "index2", "{rise_cnstr}", "{fall_cnstr}", "{cell_rise}",
            "{cell_fall}", "{rise_tran}", "{fall_tran}")
        );
        push(@CSVPINFILE, sprintf( "%-30s\t%20s\t%20s\t%20s\t%20s\t%20s\t%20s\n",
                          "pin_name", "direction", "pincap", "related_power",
                          "related_ground", "max_capacitance", "max_transition")
        );

        foreach my $pin ( sort @pins ) {
            my $pin_name        = $parser->get_group_name($pin);
            my $direction       = StdDir( $parser->get_simple_attr_value( $pin, "direction" ) );
            my $pincap          = GetValueFromPair( $parser->get_attr_with_value( $pin, "capacitance" ) );
            my $related_power   = $parser->get_simple_attr_value( $pin, "related_power_pin" );
            my $related_ground  = $parser->get_simple_attr_value( $pin, "related_ground_pin" );
            my $max_capacitance = defineWithDefault( $default_max_capacitance, GetValueFromPair( $parser->get_attr_with_value( $pin, "max_capacitance" ) ) );
            my $max_transition  = defineWithDefault( $default_max_transition, GetValueFromPair( $parser->get_attr_with_value( $pin, "max_transition" ) ) );

            $pincap    = "N/A" if ( !$pincap );
            $direction = "N/A" if ( !$direction );

            $pinInfo->{$pin_name}{direction}       = $direction;
            $pinInfo->{$pin_name}{pincap}          = $pincap;
            $pinInfo->{$pin_name}{related_power}   = $related_power;
            $pinInfo->{$pin_name}{related_ground}  = $related_ground;
            $pinInfo->{$pin_name}{max_capacitance} = $max_capacitance;
            $pinInfo->{$pin_name}{max_transition}  = $max_transition;

            my @timings = $parser->get_groups_by_type( $pin, "timing" );
            push(@CSVPINFILE, sprintf( "%-30s\t%20s\t%20s\t%20s\t%20s\t%20s\t%20s\n",
                              $pin_name, $direction, $pincap, $related_power,
                              $related_ground, $max_capacitance, $max_transition
                              )
            );

            foreach my $timing ( sort @timings ) {
                my $related_pin  = $parser->get_simple_attr_value( $timing, "related_pin" );
                my $timing_type  = $parser->get_simple_attr_value( $timing, "timing_type" );
                my $timing_sense = $parser->get_simple_attr_value( $timing, "timing_sense" );
                my $min_delay_flag = $parser->get_attr_with_value( $timing, "min_delay_flag" );
                my $sdf_condition  = $parser->get_attr_with_value( $timing, "sdf_cond" );

                $related_pin =~ s/\s+/&/g;
                chomp($sdf_condition);
                $sdf_condition =~ s/sdf_cond ://;
                $sdf_condition =~ s/[ ;\"]//g;

                if ( $sdf_condition =~ /\s*sdf_cond\s*/ ) {
                    $sdf_condition = "N/A";
                }

                $timing_type   = "N/A" if ( !$timing_type );
                $timing_sense  = "N/A" if ( !$timing_sense );
                $sdf_condition = "N/A" if ( !$sdf_condition );

                if ( $min_delay_flag =~ /true/ ) {
                    $min_delay_flag = "True";
                }
                else {
                    $min_delay_flag = "False";
                }

                my @arc_types = ( "rise_constraint", "fall_constraint", "cell_rise", "cell_fall", "rise_transition", "fall_transition" );
                my $cur_arc;

                foreach my $arc_type (@arc_types) {
                    $cur_arc = $parser->locate_group_by_type( $timing, $arc_type );
                    last if ( $cur_arc != 0 );
                }

                my @arr_index1 = $parser->get_lookup_table_index_1($cur_arc);
                next if ( $#arr_index1 == 0 );

                my @arr_index2    = $parser->get_lookup_table_index_2($cur_arc);
                my $string_index1 = join( ",", @arr_index1 );
                my $string_index2 = join( ",", @arr_index2 );
                $string_index1 = "{${string_index1}}";
                $string_index2 = "{${string_index2}}";

                $timingdata->{"index1"}          = $string_index1;
                $timingdata->{"index2"}          = $string_index2;
                $timingdata->{"rise_constraint"} = createString( $parser->get_lookup_table_array( $timing, "rise_constraint" ) );
                $timingdata->{"fall_constraint"} = createString( $parser->get_lookup_table_array( $timing, "fall_constraint" ) );
                $timingdata->{"cell_rise"}       = createString( $parser->get_lookup_table_array( $timing, "cell_rise" ) );
                $timingdata->{"cell_fall"}       = createString( $parser->get_lookup_table_array( $timing, "cell_fall" ) );
                $timingdata->{"rise_transition"} = createString( $parser->get_lookup_table_array( $timing, "rise_transition" ) );
                $timingdata->{"fall_transition"} = createString( $parser->get_lookup_table_array( $timing, "fall_transition" ) );

                $timingdata->{"index1"}          = "N/A" if ( !$timingdata->{"index1"} );
                $timingdata->{"index2"}          = "N/A" if ( !$timingdata->{"index2"} );
                $timingdata->{"rise_constraint"} = "N/A" if ( !$timingdata->{"rise_constraint"} );
                $timingdata->{"fall_constraint"} = "N/A" if ( !$timingdata->{"fall_constraint"} );
                $timingdata->{"cell_rise"}       = "N/A" if ( !$timingdata->{"cell_rise"} );
                $timingdata->{"cell_fall"}       = "N/A" if ( !$timingdata->{"cell_fall"} );
                $timingdata->{"rise_transition"} = "N/A" if ( !$timingdata->{"rise_transition"} );
                $timingdata->{"fall_transition"} = "N/A" if ( !$timingdata->{"fall_transition"} );

                push(@CSVFILE, sprintf(
                    "%-30s\t%10s\t%30s\t%50s\t%100s\t%100s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\n",
                    $pin_name,                      $direction,               $pincap,                  $related_pin,                   $sdf_condition,
                    $timing_sense,                  $min_delay_flag,          $timingdata->{index1},    $timingdata->{index2},          $timingdata->{rise_constraint},
                    $timingdata->{fall_constraint}, $timingdata->{cell_rise}, $timingdata->{cell_fall}, $timingdata->{rise_transition}, $timingdata->{fall_transition}
                ));
            }
        }

    }
    else {
        my $parser = new Liberty::Parser;

        #my $parser = new Parse::Liberty (verbose=>0,indent=>4,file=>$liberty_file);
        #my $new_parser = Parse::Liberty->library($liberty_file);
        my $library_group = $parser->read_file($liberty_file);

        my $lib_name = $parser->get_group_name($library_group);

        #checkLibname($lib_name, $liberty_file);

        my $leakage_power_unit = $parser->get_simple_attr_value( $library_group, "leakage_power_unit" );
        my @opconds           = $parser->get_groups_by_type( $library_group, "operating_conditions" );
        my $Ncond             = @opconds;
        my $opcond_defined    = ( $Ncond > 0 );                                                          ## At least one operating condition.
        my $tree_type_defined = $opcond_defined;
        foreach my $opcond (@opconds) {
            if ( !( defined $parser->get_simple_attr_value( $opcond, "tree_type" ) ) ) { $tree_type_defined = 0 }
        }

        my $default_max_capacitance = GetValueFromPair( $parser->get_attr_with_value( $library_group, "default_max_capacitance" ) );
        my $default_max_transition  = GetValueFromPair( $parser->get_attr_with_value( $library_group, "default_max_transition" ) );

        ##  Get all the lookup table templates
        my $tableHash = {};
        my @tables    = $parser->get_groups_by_type( $library_group, "lu_table_template" );
        my $Ntable    = @tables;
        foreach my $table (@tables) {
            my $table_name = $parser->get_group_name($table);

            #print CSVFILE "Looking up table $table_name\n";
            my $variable_2 = $parser->get_simple_attr_value( $table, "variable_2" );
            my $variable_1 = $parser->get_simple_attr_value( $table, "variable_1" );
            $tableHash->{$table_name}                 = {};
            $tableHash->{$table_name}->{VAR_1}->{ID}  = $variable_1;
            $tableHash->{$table_name}->{VAR_1}->{MAX} = $max_var_1;
            $tableHash->{$table_name}->{VAR_1}->{MIN} = $min_var_1;
            $tableHash->{$table_name}->{VAR_2}->{ID}  = $variable_2;
            $tableHash->{$table_name}->{VAR_2}->{MAX} = $max_var_2;
            $tableHash->{$table_name}->{VAR_2}->{MIN} = $min_var_2;
        }

        my $time_unit = $parser->get_simple_attr_value( $library_group, "time_unit" );
        $time_unit =~ m/^(\d+)([a-zA-Z]+)/;
        if    ( $2 eq "ns" ) { $time_unit = "${1}e-9" }
        elsif ( $2 eq "ps" ) { $time_unit = "${1}e-12" }
        else                 { print "Error:  Unrecognized time unit \"$time_unit\"\n" }

        #my $cell_group = $parser->locate_cell($library_group, $macro);
        ## Maddeningly difficult to determine if the cell name provided is actually found; locate_cell returns a defined cell_group even if it's not there
        ##   and can't figure out a way to determine it's validity without triggering an exception.
        ##   This seems to work.
        my $cell_group = $parser->locate_group_by_type( $library_group, "cell" );
        my $cell_name = $parser->get_group_name($cell_group);

        #if ($cell_name ne $macro) {print "Error:  Cell \"$macro\" not found in $liberty_file\n"; next}

        my $cell_leakage_power = GetValueFromPair( $parser->get_attr_with_value( $cell_group, "cell_leakage_power" ) );
        my $areaval = $parser->get_attr_with_value( $cell_group, "area" );

        my $area = GetValueFromPair($areaval);
        $area = sprintf( "%.6f", $area );

        my @pins = $parser->get_groups_by_type( $cell_group, "pin" );

        #make sure the first four exist, if not then give the value none
        push(@CSVFILE, sprintf(
            "%-30s\t%10s\t%10s\t%15s\t%20s\t%20s\t%20s\t%30s\t%30s\t%30s\t%10s\t%10s\t%10s\t%10s\t%10s\n",
            "pin_name", "direction", "pincap", "related_pin", "timing_type", "timing_sense",
            "min_delay_flag", "index1", "index2", "{rise_cnstr}", "{fall_cnstr}",
            "{cell_rise}", "{cell_fall}", "{rise_tran}", "{fall_tran}")
        );
        push(@CSVPINFILE, sprintf( "%-30s\t%20s\t%20s\t%20s\t%20s\t%20s\t%20s\n",
                "pin_name", "direction", "pincap", "related_power",
                "related_ground", "max_capacitance", "max_transition")
        );

        foreach my $pin ( sort @pins ) {
            my $timing_count    = 0;
            my $pin_name        = $parser->get_group_name($pin);
            my $direction       = StdDir( $parser->get_simple_attr_value( $pin, "direction" ) );
            my $pincap          = GetValueFromPair( $parser->get_attr_with_value( $pin, "capacitance" ) );
            my $related_power   = $parser->get_simple_attr_value( $pin, "related_power_pin" );
            my $related_ground  = $parser->get_simple_attr_value( $pin, "related_ground_pin" );
            my $max_capacitance = defineWithDefault( $default_max_capacitance, GetValueFromPair( $parser->get_attr_with_value( $pin, "max_capacitance" ) ) ) || 0.00;
            my $max_transition  = defineWithDefault( $default_max_transition, GetValueFromPair( $parser->get_attr_with_value( $pin, "max_transition" ) ) ) || 0.00;

            push(@CSVPINFILE, sprintf("%-30s\t%20s\t%20s\t%20s\t%20s\t%20s\t%20s\n",
                              $pin_name, $direction, $pincap, $related_power,
                              $related_ground, $max_capacitance, $max_transition )
            );
            $pinInfo->{$pin_name}{direction}       = $direction;
            $pinInfo->{$pin_name}{pincap}          = $pincap;
            $pinInfo->{$pin_name}{related_power}   = $related_power;
            $pinInfo->{$pin_name}{related_ground}  = $related_ground;
            $pinInfo->{$pin_name}{max_capacitance} = $max_capacitance;
            $pinInfo->{$pin_name}{max_transition}  = $max_transition;

            my @timings = $parser->get_groups_by_type( $pin, "timing" );

            #$parser->print_timing_arc($pin);
            foreach my $timing ( sort @timings ) {
                my $related_pin  = $parser->get_simple_attr_value( $timing, "related_pin" );
                my $timing_type  = $parser->get_simple_attr_value( $timing, "timing_type" );
                my $timing_sense = $parser->get_simple_attr_value( $timing, "timing_sense" );
                $timing_sense = "N/A" if ( !$timing_sense );
                my $min_delay_flag = $parser->get_attr_with_value( $timing, "min_delay_flag" );
                if ( $min_delay_flag =~ /true/ ) {
                    $min_delay_flag = "True";
                }
                else {
                    $min_delay_flag = "False";
                }

                #$min_delay_flag = "false" unless ( $min_delay_flag =);

                my $group_extract = $parser->extract_group( $timing, $timing_type );
                my $index2        = ${timing_type} . "index_2";
                my $index3        = ${timing_type} . "index_3";
                if ( $group_extract =~ /${index3}/ ) {
                }
                elsif ( $group_extract =~ /${index2}/ ) {

                    #my @arr = $parser->get_lookup_table_array($timing, "cell_fall");
                    #print @arr;
                    #print "\n";

                    my @arc_types = ( "rise_constraint", "fall_constraint", "cell_rise", "cell_fall", "rise_transition", "fall_transition" );
                    my $cur_arc;
                    foreach my $arc_type (@arc_types) {
                        $cur_arc = $parser->locate_group_by_type( $timing, $arc_type );
                        last if ( $cur_arc != 0 );
                    }
                    my @arr_index1    = $parser->get_lookup_table_index_1($cur_arc);
                    my @arr_index2    = $parser->get_lookup_table_index_2($cur_arc);
                    my $string_index1 = join( ",", @arr_index1 );
                    my $string_index2 = join( ",", @arr_index2 );
                    $string_index1 = "{${string_index1}}";
                    $string_index2 = "{${string_index2}}";

                    $timingdata->{"index1"}          = $string_index1;
                    $timingdata->{"index2"}          = $string_index2;
                    $timingdata->{"rise_constraint"} = createString( $parser->get_lookup_table_array( $timing, "rise_constraint" ) );
                    $timingdata->{"fall_constraint"} = createString( $parser->get_lookup_table_array( $timing, "fall_constraint" ) );
                    $timingdata->{"cell_rise"}       = createString( $parser->get_lookup_table_array( $timing, "cell_rise" ) );
                    $timingdata->{"cell_fall"}       = createString( $parser->get_lookup_table_array( $timing, "cell_fall" ) );
                    $timingdata->{"rise_transition"} = createString( $parser->get_lookup_table_array( $timing, "rise_transition" ) );
                    $timingdata->{"fall_transition"} = createString( $parser->get_lookup_table_array( $timing, "fall_transition" ) );

                }
                else {
                    #print "\t\t $pin_name $timing_type DOES NOT HAVE index 2\n";
                    $timingdata->{"index1"}          = "N/A";
                    $timingdata->{"index2"}          = "N/A";
                    $timingdata->{"rise_constraint"} = "N/A";
                    $timingdata->{"fall_constraint"} = "N/A";
                    $timingdata->{"cell_rise"}       = "N/A";
                    $timingdata->{"cell_fall"}       = "N/A";
                    $timingdata->{"rise_transition"} = "N/A";
                    $timingdata->{"fall_transition"} = "N/A";

                    #print "#"x80; print "\n$group_extract";print "#"x80; print "\n";
                    my @extract_fields = split( "$timing_type", $group_extract );
                    $this_table = "";
                    my $this_table_type = "";
                    my $thevalues       = "";
                    foreach my $this_field (@extract_fields) {

                        #print "$this_field";
                        if ( $this_field =~ /^\s*(\w+)\s+\((scalar)\)\s+\{\s*$/ ) {
                            $this_table      = $1;
                            $this_table_type = $2;
                        }
                        elsif ( $this_field =~ /^\s*(\w+)\s+\(([fr]_itrans)\)\s+\{\s*$/ ) {
                            $this_table      = $1;
                            $this_table_type = $2;
                        }
                        elsif ( $this_field =~ /^\s*values\s*\(\s*\"(.*)\"\s*\)\s*\;\s*$/ ) {
                            $thevalues = $1;
                        }
                    }
                    my @thevalues   = split( ",", $thevalues );
                    my $arraySize   = @thevalues;
                    my $arrayMiddle = int( ( $arraySize / 2 ) + ( $arraySize % 2 ) - 1 );

                    $timingdata->{$this_table} = $thevalues[$arrayMiddle];
                    $timingdata->{"OTHER_THING"} = $thevalues[$arrayMiddle];
                }

                #make sure the first four exist, if not then give the value none
                if ( $pin_name eq "" )    { $pin_name    = "none"; }
                if ( $direction eq "" )   { $direction   = "none"; }
                if ( $pincap eq "" )      { $pincap      = "none"; }
                if ( $related_pin eq "" ) { $related_pin = "none"; }
                if ( $timing_type eq "" ) { $timing_type = "none"; }

                push(@CSVFILE, sprintf(
                    "%-30s\t%10s\t%10s\t%15s\t%20s\t%20s\t%20s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\n",
                    $pin_name,                      $direction,               $pincap,                  $related_pin,                   $timing_type,
                    $timing_sense,                  $min_delay_flag,          $timingdata->{index1},    $timingdata->{index2},          $timingdata->{rise_constraint},
                    $timingdata->{fall_constraint}, $timingdata->{cell_rise}, $timingdata->{cell_fall}, $timingdata->{rise_transition}, $timingdata->{fall_transition}
                ));
                $timing_count++;
            }

            if ( $timing_count == 0 ) {
                ##nh##print "\t\t$pin_name,$direction,$pincap,NoTiming,,,,,,,\n";
            }
        }

        my @pg_pins = $parser->get_groups_by_type( $cell_group, "pg_pin" );
        foreach my $pg_pin (@pg_pins) {
            my $pin_name = $parser->get_group_name($pg_pin);
            my $pg_type  = $parser->get_simple_attr_value( $pg_pin, "pg_type" );
            my $pg_dir   = StdDir( $parser->get_simple_attr_value( $pg_pin, "direction" ) );

            #StorePin($pin_name, $pg_dir, StdType($pg_type), undef, undef );
        }
        my @buses = $parser->get_groups_by_type( $cell_group, "bus" );
        foreach my $bus ( sort @buses ) {
            my $bus_name       = $parser->get_group_name($bus);
            my $direction      = StdDir( $parser->get_simple_attr_value( $bus, "direction" ) );
            my $related_power  = $parser->get_simple_attr_value( $bus, "related_power_pin" );
            my $related_ground = $parser->get_simple_attr_value( $bus, "related_ground_pin" );
            my $bus_type       = $parser->get_simple_attr_value( $bus, "bus_type" );
            my $buscap         = GetValueFromPair( $parser->get_attr_with_value( $bus, "capacitance" ) );    ## Not sure this is ever used.

            my $bus_max_capacitance = defineWithDefault( $default_max_capacitance, GetValueFromPair( $parser->get_attr_with_value( $bus, "max_capacitance" ) ) );
            my $bus_max_transition  = defineWithDefault( $default_max_transition,  GetValueFromPair( $parser->get_attr_with_value( $bus, "max_transition" ) ) );

            my $g = $parser->locate_group( $library_group, $bus_type );
            my $bit_width = $parser->get_attr_with_value( $g, "bit_width" );
            my $bit_from  = $parser->get_attr_with_value( $g, "bit_from" );
            my $bit_to    = $parser->get_attr_with_value( $g, "bit_to" );
            $bit_width = GetValueFromPair($bit_width);
            $bit_from  = GetValueFromPair($bit_from);
            $bit_to    = GetValueFromPair($bit_to);
            my @buspins    = $parser->get_groups_by_type( $bus, "pin" );
            my $bustimings = $parser->get_groups_by_type( $bus, "timing" );
            my $pin_name   = $parser->get_group_name($bus);
            my @timings    = $parser->get_groups_by_type( $bus, "timing" );

            #StorePin("$bus_name\[$bit_from:$bit_to\]", $direction, "signal", $related_power, $related_ground, $buscap, $bustimings);
            my $theBusName = "$bus_name\[$bit_from:$bit_to\]";

            my $Nbuspins = @buspins;
            foreach my $pin ( sort @buspins ) {
                my $timing_count = 0;
                my $pin_name     = $parser->get_group_name($pin);
                if ( $pin_name =~ m/^$bus_name[\[<]/ ) {
                    ##  Process any bus-nested pin statements.
                    my $direction = StdDir( $parser->get_simple_attr_value( $pin, "direction" ) );
                    my $related_power  = $parser->get_simple_attr_value( $pin, "related_power_pin" );
                    my $related_ground = $parser->get_simple_attr_value( $pin, "related_ground_pin" );
                    my $pincap = GetValueFromPair( $parser->get_attr_with_value( $pin, "capacitance" ) );

                    #my $pintimings = GetTiming($parser, $pin);
                    my $pin_name        = $parser->get_group_name($pin);
                    my @timings         = $parser->get_groups_by_type( $pin, "timing" );
                    my $max_capacitance = defineWithDefault( $bus_max_capacitance, GetValueFromPair( $parser->get_attr_with_value( $pin, "max_capacitance" ) ) ) || 0.00;
                    my $max_transition  = defineWithDefault( $bus_max_transition, GetValueFromPair( $parser->get_attr_with_value( $pin, "max_transition" ) ) );

                    push(@CSVPINFILE, sprintf("%-30s\t%20s\t%20s\t%20s\t%20s\t%20s\t%20s\n",
                                 $pin_name, $direction, $pincap, $related_power,
                                 $related_ground, $max_capacitance, $max_transition )
                    );
                    $pinInfo->{$pin_name}{direction}       = $direction;
                    $pinInfo->{$pin_name}{pincap}          = $pincap;
                    $pinInfo->{$pin_name}{related_power}   = $related_power;
                    $pinInfo->{$pin_name}{related_ground}  = $related_ground;
                    $pinInfo->{$pin_name}{max_capacitance} = $max_capacitance;
                    $pinInfo->{$pin_name}{max_transition}  = $max_transition;

                    #addPinAttr($pin_name, "MAX_CAPACITANCE", $max_capacitance);
                    #addPinAttr($pin_name, "MAX_TRANSITION", $max_transition);

                    foreach my $timing (@timings) {
                        my $related_pin  = $parser->get_simple_attr_value( $timing, "related_pin" );
                        my $timing_type  = $parser->get_simple_attr_value( $timing, "timing_type" );
                        my $timing_sense = $parser->get_simple_attr_value( $timing, "timing_sense" );
                        $timing_sense = "N/A" if ( !$timing_sense );
                        my $min_delay_flag = $parser->get_attr_with_value( $timing, "min_delay_flag" );
                        if ( $min_delay_flag =~ /true/ ) {
                            $min_delay_flag = "True";
                        }
                        else {
                            $min_delay_flag = "False";
                        }

                        if (   $timing_type eq "min_pulse_width"
                            || $timing_type eq "minimum_period"
                            || $timing_type eq "max_clock_tree_path"
                            || $timing_type eq "min_clock_tree_path" )
                        {
                            next;
                        }

                        my @arc_types = ( "rise_constraint", "fall_constraint", "cell_rise", "cell_fall", "rise_transition", "fall_transition" );
                        my $cur_arc;
                        foreach my $arc_type (@arc_types) {
                            $cur_arc = $parser->locate_group_by_type( $timing, $arc_type );
                            last if ( $cur_arc != 0 );
                        }
                        my @arr_index1    = $parser->get_lookup_table_index_1($cur_arc);
                        my @arr_index2    = $parser->get_lookup_table_index_2($cur_arc);
                        my $string_index1 = join( ",", @arr_index1 );
                        my $string_index2 = join( ",", @arr_index2 );
                        $string_index1 = "{${string_index1}}";
                        $string_index2 = "{${string_index2}}";

                        $timingdata->{"index1"}          = $string_index1;
                        $timingdata->{"index2"}          = $string_index2;
                        $timingdata->{"rise_constraint"} = createString( $parser->get_lookup_table_array( $timing, "rise_constraint" ) );
                        $timingdata->{"fall_constraint"} = createString( $parser->get_lookup_table_array( $timing, "fall_constraint" ) );
                        $timingdata->{"cell_rise"}       = createString( $parser->get_lookup_table_array( $timing, "cell_rise" ) );
                        $timingdata->{"cell_fall"}       = createString( $parser->get_lookup_table_array( $timing, "cell_fall" ) );
                        $timingdata->{"rise_transition"} = createString( $parser->get_lookup_table_array( $timing, "rise_transition" ) );
                        $timingdata->{"fall_transition"} = createString( $parser->get_lookup_table_array( $timing, "fall_transition" ) );

                        #make sure the first four exist, if not then give the value none
                        if ( $pin_name eq "" )    { $pin_name    = "none"; }
                        if ( $direction eq "" )   { $direction   = "none"; }
                        if ( $pincap eq "" )      { $pincap      = "none"; }
                        if ( $related_pin eq "" ) { $related_pin = "none"; }
                        if ( $timing_type eq "" ) { $timing_type = "none"; }

                        push(@CSVFILE, sprintf(
                            "%-30s\t%10s\t%10s\t%15s\t%20s\t%20s\t%20s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\n",
                            $pin_name,    $direction,    $pincap,         $related_pin,
                            $timing_type, $timing_sense, $min_delay_flag, $timingdata->{index1},
                            $timingdata->{index2},          $timingdata->{rise_constraint},
                            $timingdata->{fall_constraint}, $timingdata->{cell_rise},
                            $timingdata->{cell_fall},       $timingdata->{rise_transition},
                            $timingdata->{fall_transition} )
                        );
                        $timing_count++;
                    }
                    if ( $timing_count == 0 ) {
                        ##nh##print "\t\t$pin_name,$direction,$pincap,NoTiming,,,,,,,\n";
                    }
                }
                else {
                    print "ERROR: Pin $pin_name of bus $bus_name has name mismatch\n";
                }
            }
        }
    }
    write_file(\@CSVFILE, $csvFile );
    write_file(\@CSVPINFILE, $csv_pin_file );
}  # END ReadLiberty

#---------------------------------------------------------------------
sub GeneratePDF {
    print_function_header();
    ##Variables - start of list
    my $opt_help;
    my $comparison_dir1;
    my $comparison_dir2;
    my $include_pass;
    my $values = 0;
    my $pwd    = getcwd;
    my $build;
    my $lt_array_ref = localtime(time);
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = @$lt_array_ref;
    my $corner;
    my @cornerList;
    my $golden_dir;
    my $pin_name;
    my $bus_name;
    my $bit_count;
    my $related_pin;
    my $timing_type;
    my $IsMissing;
    my %Extra;
    my %Missing;
    my %NA_arcs;
    my $cmd;
    my $libFile;
    my $arcFile;
    my $arcFileGolden;
    my %TempHash;
    my %PinHash;
    my %PinHashGolden;
    my $this_count;
    my $my_field;
    my @ListOfTimingFields = ( "RiseCnstr", "FallCnstr", "CellRise", "CellFall", "RiseTran", "FallTran" );
    my @my_valuesA;
    my @my_valuesB;
    my $my_valueA;
    my $my_valueB;
    my @arc_compare_messages_pass;
    my @arc_compare_messages_mismatch;
    my @csv_compare_messages_pass;
    my @csv_compare_messages_mismatch;
    my $diff_abs_valueAB;
    my $diff_pct_valueAB;
    my $timing_sense;
    my $min_delay_flag;
    my $username = $ENV{USER};
    #sub readArcs;
    #sub usage;
    ##Variables - end of list

    $mon++;
    $year += 1900;
    $mon  = sprintf "%02d", $mon;
    $mday = sprintf "%02d", $mday;

    my $csvFile1      = shift;
    my $csvFile2      = shift;
    my $cellName      = shift;
    my $csv_output    = shift;
    my $pinInfo1      = shift;
    my $pinInfo2      = shift;
    my $merge_results = shift;
    my $sdf_compare   = shift;
    my $ui            = shift;
    my $pdf_required  = shift;

    if ($ui) {
        $ui = $ui . ',';
    }

    my %PinHash1;
    my %PinHash2;
    my $corner1 = "ver1";
    my $corner2 = "ver2";

    my $libFile1 = $csvFile1;
    my $libFile2 = $csvFile2;
    $libFile1 =~ s/\.csv/\.lib/;
    $libFile2 =~ s/\.csv/\.lib/;

    my $csv_report_file = $csvFile1;
    $csv_report_file =~ s/\/.*$//;

    $csv_report_file = $pwd . "/${cellName}_report.csv";

    if ( -e $csv_report_file ) {
        print "Removing $csv_report_file file...\n";
        unlink $csv_report_file;
    }

    my %sdf_conditions;

    if ($sdf_compare) {
        if ( !-f $sdf_compare ) {
            die "SDF condition file doesn't exist, exiting ...\n";
        }
        else {
            chomp $sdf_compare;
            print "Reading sdf conditions .... ";

            foreach my $line ( read_file($sdf_compare) ){
                $line =~ s/sdf_cond ://;
                $line =~ s/[ ;\"]//g;
                $sdf_conditions{$line} = 1;
            }
        }
    }

    # ------------------------------------------- CVS file parsing ------------------------------------------- #
    hprint( "\n%% Creating PinHash1 from $csvFile1.\n" );
    %TempHash = %{ &readArcs($csvFile1) };
	print Dumper(\%TempHash); print "\n\n";
    foreach my $pin_name ( keys %TempHash ) {
        foreach my $related_pin ( keys %{ $TempHash{$pin_name} } ) {
            foreach my $timing_type ( keys %{ $TempHash{$pin_name}{$related_pin} } ) {
                $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{Dir}   = $TempHash{$pin_name}{$related_pin}{$timing_type}{Dir};
                $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{Cap}   = $TempHash{$pin_name}{$related_pin}{$timing_type}{Cap};
                $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{Count} = $TempHash{$pin_name}{$related_pin}{$timing_type}{Count};
                foreach my $timing_sense ( keys %{ $TempHash{$pin_name}{$related_pin}{$timing_type}{"timing_sense"} } ) {
                    foreach my $min_delay_flag ( keys %{ $TempHash{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"} } ) {
                        $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index1} =
                          $TempHash{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index1};
                        $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index2} =
                          $TempHash{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index2};
                        foreach my $my_field (@ListOfTimingFields) {
                            $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} =
                              $TempHash{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field};
                        }
                    }
                }
                my $total_count = $TempHash{$pin_name}{$related_pin}{$timing_type}{Count};
                for ( my $i = 1 ; $i <= $total_count ; $i++ ) {
                    my $this_pass = "Pass" . $i;
                    $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"Timing"}{"RestOfLine"}{$this_pass} = $TempHash{$pin_name}{$related_pin}{$timing_type}{RestOfLine}{$this_pass};
                }
            }
        }
    }

    hprint( "\n%% Creating PinHash2 for $csvFile2.\n" );

    %TempHash = %{ &readArcs($csvFile2) };
    foreach my $pin_name ( keys %TempHash ) {
        foreach my $related_pin ( keys %{ $TempHash{$pin_name} } ) {
            foreach my $timing_type ( keys %{ $TempHash{$pin_name}{$related_pin} } ) {
                $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{Dir}   = $TempHash{$pin_name}{$related_pin}{$timing_type}{Dir};
                $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{Cap}   = $TempHash{$pin_name}{$related_pin}{$timing_type}{Cap};
                $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{Count} = $TempHash{$pin_name}{$related_pin}{$timing_type}{Count};

                foreach my $timing_sense ( keys %{ $TempHash{$pin_name}{$related_pin}{$timing_type}{"timing_sense"} } ) {
                    foreach my $min_delay_flag ( keys %{ $TempHash{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"} } ) {
                        $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index1} =
                          $TempHash{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index1};
                        $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index2} =
                          $TempHash{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index2};

                        foreach my $my_field (@ListOfTimingFields) {
                            $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} =
                              $TempHash{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field};
                        }
                    }
                }
                my $total_count = $TempHash{$pin_name}{$related_pin}{$timing_type}{Count};
                for ( my $i = 1 ; $i <= $total_count ; $i++ ) {
                    my $this_pass = "Pass" . $i;
                    $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"Timing"}{"RestOfLine"}{$this_pass} = $TempHash{$pin_name}{$related_pin}{$timing_type}{RestOfLine}{$this_pass};
                }
            }
        }
    }

    # ------------------------------------------- End of CVS file parsing ------------------------------------------- #

    # ------------------------------------------- Arc Comparison Section ------------------------------------------- #
    foreach my $pin_name ( sort keys %PinHash ) {

        #Check for arcs missing in corners
        foreach my $related_pin ( keys %{ $PinHash{$pin_name}{$corner1} } ) {
            foreach my $timing_type ( keys %{ $PinHash{$pin_name}{$corner1}{$related_pin} } ) {
                foreach my $timing_sense ( keys %{ $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"} } ) {
                    foreach my $min_delay_flag ( keys %{ $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"} } ) {
                        foreach my $my_field (@ListOfTimingFields) {
                            if (   ( !exists $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} )
                                or ( $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} eq "N/A" ) )
                            {
                                $NA_arcs{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field} = 1;
                                next;
                            }

                            if ( !exists $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} ) {
                                $Missing{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field} = 1;
                                push @arc_compare_messages_mismatch,
"    MISSING $my_field timing arc: $pin_name -> $timing_type arc with related pin $related_pin, timing sense : $timing_sense , min_delay_flag : $min_delay_flag in lib2 file: $csvFile2\n";
                                push @csv_compare_messages_mismatch, "$pin_name, $related_pin, $timing_type, $my_field, $timing_sense, $min_delay_flag, 'missing in',$csvFile2\n";
                            }
                            elsif ( ( $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} eq "N/A" )
                                and ( $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} ne "N/A" ) )
                            {
                                $Missing{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field} = 1;
                                push @arc_compare_messages_mismatch,
"    MISSING $my_field timing arc: $pin_name -> $timing_type arc with related pin $related_pin, timing sense : $timing_sense , min_delay_flag : $min_delay_flag in lib2 file: $csvFile2\n";
                                push @csv_compare_messages_mismatch, "$pin_name, $related_pin, $timing_type, $my_field, $timing_sense, $min_delay_flag, 'missing in',$csvFile2\n";
                            }
                            elsif ( ( $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} ne "N/A" )
                                and ( $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} ne "N/A" ) )
                            {
                                push @arc_compare_messages_pass,
"    PASS $my_field timing arc: $pin_name -> $timing_type arc with related pin $related_pin, timing sense : $timing_sense , min_delay_flag : $min_delay_flag exists in both lib files\n";
                                push @csv_compare_messages_pass, "$pin_name, $related_pin, $timing_type, $my_field, $timing_sense, $min_delay_flag\n";
                            }
                        }
                    }
                }
            }
        }
    }

    foreach my $pin_name ( sort keys %PinHash ) {

        #Check for arcs missing in corners
        foreach my $related_pin ( keys %{ $PinHash{$pin_name}{$corner2} } ) {
            foreach my $timing_type ( keys %{ $PinHash{$pin_name}{$corner2}{$related_pin} } ) {
                foreach my $timing_sense ( keys %{ $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"} } ) {
                    foreach my $min_delay_flag ( keys %{ $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"} } ) {
                        foreach my $my_field (@ListOfTimingFields) {
                            if (   ( !exists $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} )
                                or ( $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} eq "N/A" ) )
                            {
                                $NA_arcs{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field} = 1;
                                next;
                            }

                            if ( exists $Missing{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field} ) {
                                next;
                            }
                            else {
                                if ( !exists $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} ) {
                                    $Missing{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field} = 1;
                                    push @arc_compare_messages_mismatch,
"    MISSING $my_field timing arc: $pin_name -> $timing_type arc with related pin $related_pin, timing sense : $timing_sense , min_delay_flag : $min_delay_flag in lib2 file: $csvFile2\n";
                                    push @csv_compare_messages_mismatch, "$pin_name, $related_pin, $timing_type, $my_field, $timing_sense, $min_delay_flag, 'missing in', $csvFile1\n";
                                }
                                elsif ( ( $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} ne "N/A" )
                                    and ( $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"Timing"}{$my_field} eq "N/A" ) )
                                {
                                    $Missing{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field} = 1;
                                    push @arc_compare_messages_mismatch,
"    MISSING $my_field timing arc: $pin_name -> $timing_type arc with related pin $related_pin, timing sense : $timing_sense , min_delay_flag : $min_delay_flag in lib1 file: $csvFile1\n";
                                    push @csv_compare_messages_mismatch, "$pin_name, $related_pin, $timing_type, $my_field, $timing_sense, $min_delay_flag, 'missing in', $csvFile1\n";
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    # ----------------------------------------- End Of Arc Comparison Section ----------------------------------------- #

    # ----------------------------------------- Mismatched/Passed Arc List Compress Section --------------------------- #
    if ($merge_results) {
        print "Merging passed arc list ....\n";
        foreach my $message (@csv_compare_messages_pass) {
            $message =~ s/^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/$1 $2 $3 $4/;
        }
        @csv_compare_messages_pass = keys { map { $_ => 1 } @csv_compare_messages_pass };

        foreach my $message (@csv_compare_messages_mismatch) {
            $message =~ s/^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/$1 $2 $3 $4 $7/;
        }
        @csv_compare_messages_mismatch = keys { map { $_ => 1 } @csv_compare_messages_mismatch };
        print "Merging mismatched arc list ....\n";
    }

    # ----------------------------------------- Pin attribute comparison section ------------------------------------------ #

    my @pin_mismatch;
    my @pin_direction_mismatch;
    my @pin_cap_mismatch;
    my @pin_related_power_mismatch;
    my @pin_related_ground_mismatch;
    my @pin_max_capacitance_mismatch;
    my @pin_max_transition_mismatch;

    my $is_pg = 0;
    $is_pg = 1 if ( ( $libFile1 =~ /pg/ ) and ( $libFile2 =~ /pg/ ) );

    foreach my $pin_name ( keys %{$pinInfo1} ) {
        if ( exists $pinInfo2->{$pin_name} ) {
            foreach my $key ( keys %{ $pinInfo1->{$pin_name} } ) {
                if ( $key eq "direction" ) {
                    if ( $pinInfo1->{$pin_name}{"direction"} ne $pinInfo2->{$pin_name}{"direction"} ) {
                        push( @pin_direction_mismatch, "$pin_name, reference value:  $pinInfo1->{$pin_name}{'direction'},  current value: $pinInfo2->{$pin_name}{'direction'}\n" );
                    }
                }
                elsif ( $key eq "related_power" ) {
                    if ($is_pg) {
                        if ( !defined $pinInfo1->{$pin_name}{"related_power"} ) {
                            if ( !defined $pinInfo2->{$pin_name}{"related_power"} ) {
                                next;
                            }
                            else {
                                push( @pin_related_power_mismatch, "Missing related_power attribute for pin $pin_name in reference\n" );
                            }
                        }
                        elsif ( !defined $pinInfo2->{$pin_name}{"related_power"} ) {
                            push( @pin_related_power_mismatch, "Missing related_power attribute for pin $pin_name in current\n" );
                        }
                        elsif ( $pinInfo1->{$pin_name}{"related_power"} ne $pinInfo2->{$pin_name}{"related_power"} ) {

                            # davidgh [id=25488#c229749]
                            push( @pin_related_power_mismatch, "Mismatch related_power attribute for pin $pin_name\n" );
                        }
                    }
                }
                elsif ( $key eq "related_ground" ) {
                    if ($is_pg) {
                        if ( !defined $pinInfo1->{$pin_name}{"related_ground"} ) {
                            if ( !defined $pinInfo2->{$pin_name}{"related_ground"} ) {
                                next;
                            }
                            else {
                                push( @pin_related_power_mismatch, "Missing related_ground attribute for pin $pin_name in reference\n" );
                            }
                        }
                        elsif ( !defined $pinInfo2->{$pin_name}{"related_ground"} ) {
                            push( @pin_related_power_mismatch, "Missing related_ground attribute for pin $pin_name in current\n" );
                        }
                        elsif ( $pinInfo1->{$pin_name}{"related_ground"} ne $pinInfo2->{$pin_name}{"related_ground"} ) {

                            # davidgh [id=25488#c229749]
                            push( @pin_related_power_mismatch, "Mismatch related_ground attribute for pin $pin_name\n" );
                        }
                    }
                }
                elsif (( $key eq "max_capacitance" ) and (defined $pinInfo1->{$pin_name}{'max_capacitance'}) and ($pinInfo2->{$pin_name}{'max_capacitance'})) {
                    if ( $pinInfo1->{$pin_name}{"max_capacitance"} != $pinInfo2->{$pin_name}{"max_capacitance"} ) {
                        push( @pin_max_capacitance_mismatch, "$pin_name, reference value: $pinInfo1->{$pin_name}{'max_capacitance'}, current value: $pinInfo2->{$pin_name}{'max_capacitance'}\n" );
                    }
                }
                elsif (( $key eq "max_transition" ) and (defined $pinInfo1->{$pin_name}{'max_transition'}) and ($pinInfo2->{$pin_name}{'max_transition'})) {
                    if ( $pinInfo1->{$pin_name}{"max_transition"} != $pinInfo2->{$pin_name}{"max_transition"} ) {
                        push( @pin_max_transition_mismatch, "$pin_name, reference value:  $pinInfo1->{$pin_name}{'max_transition'},  current value: $pinInfo2->{$pin_name}{'max_transition'}\n" );
                    }
                }
                elsif ( $key eq "pincap" ) {
                    $my_valueA        = $pinInfo1->{$pin_name}{"pincap"};
                    $my_valueB        = $pinInfo2->{$pin_name}{"pincap"};
                    $diff_abs_valueAB = abs( $my_valueA - $my_valueB );

                    if ( $my_valueA != 0 ) {
                        $diff_pct_valueAB = $diff_abs_valueAB / abs($my_valueA);
                    }
                    else {
                        $diff_pct_valueAB = 100;
                    }

                    if ( $diff_abs_valueAB > $threshold_cap_diff_absolute && $diff_pct_valueAB > $threshold_cap_diff_percent ) {
                        push( @pin_cap_mismatch, "Pin $pin_name , reference value: $pinInfo1->{$pin_name}{'pincap'}, current value: $pinInfo2->{$pin_name}{'pincap'}\n" );
                    }
                }
            }

            delete( $pinInfo1->{$pin_name} );
            delete( $pinInfo2->{$pin_name} );
        }
        else {
            push( @pin_mismatch, "$pin_name, from current\n" );
            delete( $pinInfo1->{$pin_name} );
        }
    }

    foreach my $pin_name ( keys %{$pinInfo2} ) {
        push( @pin_mismatch, "$pin_name, from reference\n" );
        delete( $pinInfo2->{$pin_name} );
    }

    # ----------------------------------------- Fill CSV with arc mismatch report ----------------------------------------- #
    my @csv_lines;
    if ($csv_output) {

        push(@csv_lines, "Reference lib file: , $libFile1\n" );
        push(@csv_lines, "Current lib file: , $libFile2\n" );
        push(@csv_lines, "\n\n" );

        # ----------------------------------------- Fill CSV with arc mismatch report --------------------------------------- #
        if ($merge_results) {
            if ($sdf_compare) {
                push(@csv_lines, "List of matched arcs , pin_name, related_pin, sdf_condition, my_field\n" );
            }
            else {
                push(@csv_lines, "List of matched arcs , pin_name, related_pin, timing_type, my_field\n" );
            }
        }
        else {
            if ($sdf_compare) {
                push(@csv_lines, "List of matched arcs , pin_name, related_pin, sdf_condition, my_field, timing_sense, min_delay_flag\n" );
            }
            else {
                push(@csv_lines, "List of matched arcs , pin_name, related_pin, timing_type, my_field, timing_sense, min_delay_flag\n" );
            }
        }
        my @csv_compare_messages_pass = keys { map { $_ => 1 } @csv_compare_messages_pass };
        foreach my $match ( sort { $a cmp $b } @csv_compare_messages_pass ) {
            push(@csv_lines, "Matched arc, " . $match );
        }
        push(@csv_lines, "\n\n" );

        if ($merge_results) {
            if ($sdf_compare) {
                push(@csv_lines, "List of mismatched arcs , pin_name, related_pin, sdf_condition, my_field, lib file\n" );
            }
            else {
                push(@csv_lines, "List of mismatched arcs , pin_name, related_pin, timing_type, my_field, lib file\n" );
            }
        }
        else {
            if ($sdf_compare) {
                push(@csv_lines, "List of mismatched arcs , pin_name, related_pin, sdf_condition, my_field, timing_sense, min_delay_flag, lib file\n" );
            }
            else {
                push(@csv_lines, "List of mismatched arcs , pin_name, related_pin, timing_type, my_field, timing_sense, min_delay_flag, lib file\n" );
            }
        }

        my @csv_compare_messages_mismatch = keys { map { $_ => 1 } @csv_compare_messages_mismatch };
        foreach my $mismatch ( sort { $a cmp $b } @csv_compare_messages_mismatch ) {
            push(@csv_lines, "Mismatched arc, " . $mismatch );
        }
        push(@csv_lines, "\n\n" );

        #push(@csv_lines, "timing difference report\n" );
        #        if ( $sdf_compare ) {
        #	     	push(@csv_lines, "Timing difference report, UI Absolute maximal difference,  difference in percentage, pin, related_pin, sdf_condition, timing_sense, min_delay_flag\n" );
        #	} else {
        #	     	push(@csv_lines, "Timing difference report, UI Absolute maximal difference,  difference in percentage, pin, related_pin, timing_type, timing_sense, min_delay_flag\n" );
        #	}
        #     	foreach my $key ( sort {$b<=>$a} keys %diff_csv) {
        #  		push(@csv_lines, "Timing difference, ".$diff_csv{$key} );
        #     	}

        push(@csv_lines, "\n\n" );
        push(@csv_lines, "Pin comparison report\n" );
        if ( scalar(@pin_mismatch) > 0 ) {
            foreach my $message (@pin_mismatch) {
                push(@csv_lines, "Missing pin, " . "$message" );
            }
        }
        else {
            push(@csv_lines, "No pin mismatch\n" );
        }

        push(@csv_lines, "\n\n" );
        push(@csv_lines, "Pin direction comparison report\n" );
        if ( scalar(@pin_direction_mismatch) > 0 ) {
            foreach my $message (@pin_direction_mismatch) {
                push(@csv_lines, "Pin direction mismatch, " . "$message" );
            }
        }
        else {
            push(@csv_lines, "No pin direction mismatch\n" );
        }

        push(@csv_lines, "\n\n" );
        push(@csv_lines, "Pin capacitance comparison report, absolute threshold used: $threshold_cap_diff_absolute\n" );
        if ( scalar(@pin_cap_mismatch) > 0 ) {
            foreach my $message (@pin_cap_mismatch) {
                push(@csv_lines, "Pin capacitance mismatch, " . "$message" );
            }
        }
        else {
            push(@csv_lines, "No pin capacitance mismatch\n" );
        }

        push(@csv_lines, "\n\n" );
        push(@csv_lines, "Max capacitance comparison report\n" );
        if ( scalar(@pin_max_capacitance_mismatch) > 0 ) {
            foreach my $message (@pin_max_capacitance_mismatch) {
                push(@csv_lines, "Max cap mismatch, " . "$message" );
            }
        }
        else {
            push(@csv_lines, "No max capacitance mismatch\n" );
        }

        push(@csv_lines, "\n\n" );
        push(@csv_lines, "Max transition comparison report\n" );
        if ( scalar(@pin_max_transition_mismatch) > 0 ) {
            foreach my $message (@pin_max_transition_mismatch) {
                push(@csv_lines, "Max tran mismatch, " . "$message" );
            }
        }
        else {
            push(@csv_lines, "No max transition mismatch\n" );
        }

        push(@csv_lines, "\n\n" );
        push(@csv_lines, "Related power comparison report\n" );
        if ($is_pg) {
            if ( scalar(@pin_related_power_mismatch) > 0 ) {
                foreach my $message (@pin_related_power_mismatch) {
                    push(@csv_lines, "Related power mismatch, " . "$message" );
                }
            }
            else {
                push(@csv_lines, "No related power mismatch\n" );
            }
        }
        else {
            push(@csv_lines, "Lib files are not pg type\n" );
        }

        push(@csv_lines, "\n\n" );
        push(@csv_lines, "Related ground comparison report\n" );
        if ($is_pg) {
            if ( scalar(@pin_related_ground_mismatch) > 0 ) {
                foreach my $message (@pin_related_ground_mismatch) {
                    push(@csv_lines, "Related ground mismatch, " . "$message\n" );
                }
            }
            else {
                push(@csv_lines, "No related ground mismatch\n\n" );
            }
        }
        else {
            push(@csv_lines, "Lib files are not pg type\n" );
        }
    }

#### MOVED BY DAVIDGH
    my %diff_csv;
    if ($pdf_required) {
        %diff_csv = %{
            &addPDFData(
                $cellName,                       $libFile1,                    $libFile2,                     $is_pg,                         $csv_report_file,
                \@csv_compare_messages_mismatch, \@pin_mismatch,               \@pin_direction_mismatch,      \@pin_max_capacitance_mismatch, \@pin_max_transition_mismatch,
                \@pin_related_power_mismatch,    \@pin_related_power_mismatch, \@pin_related_ground_mismatch, \@pin_cap_mismatch,             \%PinHash,
                $corner1,                        $corner2,                     $sdf_compare,                  \%sdf_conditions,               $timing_sense,
                \@ListOfTimingFields,            \%Missing,                    $ui,                           $username,                      \%NA_arcs
            )
        };
    }
    else {
        %diff_csv = %{
            &addCSVData(
                $cellName,                       $libFile1,                    $libFile2,                     $is_pg,                         $csv_report_file,
                \@csv_compare_messages_mismatch, \@pin_mismatch,               \@pin_direction_mismatch,      \@pin_max_capacitance_mismatch, \@pin_max_transition_mismatch,
                \@pin_related_power_mismatch,    \@pin_related_power_mismatch, \@pin_related_ground_mismatch, \@pin_cap_mismatch,             \%PinHash,
                $corner1,                        $corner2,                     $sdf_compare,                  \%sdf_conditions,               $timing_sense,
                \@ListOfTimingFields,            \%Missing,                    $ui,                           $username,                      \%NA_arcs
            )
        };
    }
    #print CSV "timing difference report\n";

    if ($sdf_compare) {
        if ($ui) {
            push(@csv_lines, "Timing difference report, UI, Absolute maximal difference,  difference in percentage, pin, related_pin, sdf_condition, timing_sense, min_delay_flag\n" );
        }
        else {
            push(@csv_lines, "Timing difference report, Absolute maximal difference,  difference in percentage, pin, related_pin, sdf_condition, timing_sense, min_delay_flag\n" );
        }
    }
    else {
        if ($ui) {
            push(@csv_lines, "Timing difference report, UI, Absolute maximal difference,  difference in percentage, pin, related_pin, timing_type, timing_sense, min_delay_flag\n" );
        }
        else {
            push(@csv_lines, "Timing difference report, Absolute maximal difference,  difference in percentage, pin, related_pin, timing_type, timing_sense, min_delay_flag\n" );
        }
    }
    foreach my $key ( sort { $b <=> $a } keys %diff_csv ) {
        push(@csv_lines, "Timing difference, " . $diff_csv{$key} );
    }

    write_file(\@csv_lines, $csv_report_file );
    #	print Dumper \%diff_csv;
}

#---------------------------------------------------------------------
sub delete_tmp_files() {
    print_function_header();
    my $username      = shift;
    my @psaux         = `ps aux | grep "perl-5.14.2.*alphaPlotArcs.*-ref="`;
    my @tmp_to_remove = `find /tmp -user $username 2>&1 |  grep -v 'Permission denied'`;

    if ( $#psaux < 3 ) {
        foreach my $remove_dir (@tmp_to_remove) {
            chomp($remove_dir);
            if ( -d $remove_dir ) {

                #`rm -rf $remove_dir`;
                rmdir $remove_dir;
            }
        }
    }
}

#---------------------------------------------------------------------
sub print_mismatch_to_csv {
    print_function_header();
    my $filehandle           = shift;
    my $error_array          = shift;
    my $section_text         = shift;
    my $section_correct_text = shift;

    print $filehandle "\n\n";
    print $filehandle "$section_text\n";
    if ( scalar( @{$error_array} ) > 0 ) {
        foreach my $message ( @{$error_array} ) {
            print $filehandle "$message";
        }
    }
    else {
        print $filehandle "$section_correct_text\n";
    }
}

#---------------------------------------------------------------------
sub insertImage {
    print_function_header();
    my $pdf            = shift;
    my $page           = shift;
    my $stage          = shift;
    my $image_path     = shift;
    my $image_path2    = shift;
    my $text1          = shift;
    my $text2          = shift;
    my $style          = shift;
    my $message_string = shift;
    my $sdf_compare    = shift;

    my $start_pos;
    if ( $stage == 1 ) {
        $start_pos = 780;
    }
    elsif ( $stage == 2 ) {
        $start_pos = 530;
    }
    elsif ( $stage == 3 ) {
        $start_pos = 280;
    }

    my $sec_coord   = $start_pos - 17;
    my $image_coord = $sec_coord - 155;

    if ($sdf_compare) {
        $$page->stringc( $style, 8, 196, $start_pos, $text1 );
        $$page->stringc( $style, 6, 296, $sec_coord, $text2 );
    }
    else {
        $$page->stringc( $style, 10, 166, $start_pos, $text1 );
        $$page->stringc( $style, 8,  276, $sec_coord, $text2 );
    }

    my $jpg = $$pdf->image($image_path);

    $$page->image(
        'image' => $jpg,
        xscale  => '0.3',
        yscale  => '0.3',
        'xpos'  => 70,
        'ypos'  => $image_coord
    );

    my $jpg2 = $$pdf->image($image_path2);

    $$page->image(
        'image' => $jpg2,
        xscale  => '0.3',
        yscale  => '0.3',
        'xpos'  => 330,
        'ypos'  => $image_coord
    );

    my $mes_coord = $image_coord - 17;

    # davidgh
    my $percentage = substr( ( split( ": ", ( split( ", ", $message_string ) )[1] ) )[1], 0, -2 );

    $$page->stringc( $style, 8, 276, $mes_coord, $message_string );

    if ( $percentage >= 1000 ) {
        $$page->setrgbcolor( 255, 0, 0 );
        $$page->stringc( $style, 8, 276, $mes_coord - 10, "NOTE : difference in percentage is greater than 1000" );
        $$page->setrgbcolor( 0, 0, 0 );
    }
    elsif ( $percentage >= 100 ) {
        $$page->setrgbcolor( 128, 0, 255 );
        $$page->stringc( $style, 8, 276, $mes_coord - 10, "NOTE : difference in percentage is greater than 100" );
        $$page->setrgbcolor( 0, 0, 0 );
    }

    # end davidgh
}

#---------------------------------------------------------------------
sub readArcs {
    my $this_file = shift;

    my ($tileType,   $block,    $build, $version );
    my ($this_pin,   $this_dir, $this_cap );
    my ($this_count, $this_pass  );
    my ($rise_cnstr, $fall_cnstr );
    my ($cell_rise,  $cell_fall  );
    my ($rise_tran,  $fall_tran  );
    my ($index1,     $index2     );
    my $related_pin;
    my $timing_type;
    my $restOfLine;
    my $timing_sense;
    my $min_delay_flag;
    my %seen;
    my %Hash;

    my $start = 0;
    foreach my $line ( read_file($this_file) ){
        if( $line =~ m/\s*pin_name/xm ){
            $start = 1;
            next;
        }
        if ($start) {
            if ( $line =~ m/^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)(.*)$/ ) {
				$this_pin       = $1;
                $this_dir       = $2;
                $this_cap       = $3;
                $related_pin    = $4;
                $timing_type    = $5;
                $timing_sense   = $6;
                $min_delay_flag = $7;
                $index1         = $8;
                $index2         = $9;
                $rise_cnstr     = $10;
                $fall_cnstr     = $11;
                $cell_rise      = $12;
                $cell_fall      = $13;
                $rise_tran      = $14;
                $fall_tran      = $15;
                $restOfLine     = $16;

            }
            elsif ( $line == "" ) {
                next;
            }
            else {
                hprint( "$_ is not the correct format\n" );
            }

            if ( $this_pin eq "pin_name" ) {

                #this is a header
                next;
            }
            else {
                #dprint(HIGH, "$this_pin - $this_dir - $related_pin - $timing_type - $restOfLine\n" );
                $Hash{$this_pin}{$related_pin}{$timing_type}{"Dir"} = $this_dir;
                $Hash{$this_pin}{$related_pin}{$timing_type}{"Cap"} = $this_cap;
                $Hash{$this_pin}{$related_pin}{$timing_type}{"Count"}++;
                unless ( $seen{ ${this_pin} . "." . ${related_pin} . "." . ${timing_type} . "." . ${timing_sense} . "." . ${min_delay_flag} } ) {
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"index1"}    = $index1;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"index2"}    = $index2;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"RiseCnstr"} = $rise_cnstr;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"FallCnstr"} = $fall_cnstr;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"CellRise"}  = $cell_rise;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"CellFall"}  = $cell_fall;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"RiseTran"}  = $rise_tran;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"FallTran"}  = $fall_tran;
                    $seen{ ${this_pin} . "." . ${related_pin} . "." . ${timing_type} . "." . ${timing_sense} . "." . ${min_delay_flag} }        = 1;
                }
                else {
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"index1"} = $index1;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"index2"} = $index2;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"RiseCnstr"} =
                      $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"RiseCnstr"} . " " . $rise_cnstr;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"FallCnstr"} =
                      $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"FallCnstr"} . " " . $fall_cnstr;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"CellRise"} =
                      $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"CellRise"} . " " . $cell_rise;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"CellFall"} =
                      $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"CellFall"} . " " . $cell_fall;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"RiseTran"} =
                      $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"RiseTran"} . " " . $rise_tran;
                    $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"FallTran"} =
                      $Hash{$this_pin}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{"FallTran"} . " " . $fall_tran;
                }
                $this_count                                                            = $Hash{$this_pin}{$related_pin}{$timing_type}{"Count"};
                $this_pass                                                             = "Pass" . $this_count;
                $Hash{$this_pin}{$related_pin}{$timing_type}{"RestOfLine"}{$this_pass} = $restOfLine;
            }
        }
    } # END foreach $line

    #print Dumper(%Hash);
    return \%Hash;
}

#---------------------------------------------------------------------
sub create_dir {
    my @dir_list = split( '/', shift );
    my $new_dir  = shift(@dir_list);      # Dump first empty entry.
    my $output   = \*STDOUT;

    foreach my $dir (@dir_list) {
        if ( not -d "$new_dir/$dir" ) {
            $new_dir = "${new_dir}/${dir}";
            print $output "${new_dir} doesn't exist - creating ...\n";
            mkdir($new_dir) or die "Can't create directory: $new_dir : $!\n";
        }
        else {
            $new_dir = "${new_dir}/${dir}";
        }
    }
}

## davidgh
#---------------------------------------------------------------------
sub createPDF {

    #LOAD UP Comparison hash

    my $cellName                      = shift;
    my $libFile1                      = shift;
    my $libFile2                      = shift;
    my $is_pg                         = shift;
    my $csv_report_file               = shift;
    my @csv_compare_messages_mismatch = @{ $_[0] };
    my @pin_mismatch                  = @{ $_[1] };
    my @pin_direction_mismatch        = @{ $_[2] };
    my @pin_max_capacitance_mismatch  = @{ $_[3] };
    my @pin_max_transition_mismatch   = @{ $_[4] };
    my @pin_related_power_mismatch    = @{ $_[5] };
       @pin_related_power_mismatch    = @{ $_[6] };
    my @pin_related_ground_mismatch   = @{ $_[7] };
    my @pin_cap_mismatch              = @{ $_[8] };

    my $stage = 1;

    my $pdf = PDF::Create->new(
        'filename' => "${cellName}.pdf",
        'Title'    => 'Comparison Report'
    );

    my $a4   = $pdf->new_page( 'MediaBox' => $pdf->get_page_size('A4') );
    my $page = $a4->new_page;
    my $f1   = $pdf->font( 'BaseFont' => 'Helvetica' );
    $page->stringc( $f1, 12, 286, 446, "ETM comparison report for $cellName cell" );
    $page->stringc( $f1, 8,  286, 426, "Comparing: $libFile1 with" );
    $page->stringc( $f1, 8,  286, 412, "$libFile2" );

    my $dateString = gmtime();
    $page->stringc( $f1, 10, 386, 102, "GMT date and time run: $dateString" );

    # ----------------------------------------- Generating Summary Report ----------------------------------------- #

    my $page_comparison = $a4->new_page;
    $page_comparison->stringc( $f1, 16, 280, 746, "Comparison Summary for $cellName" );

    my $y_coord = 700;
    if ( scalar(@csv_compare_messages_mismatch) > 0 ) {
        my $error_count = scalar(@csv_compare_messages_mismatch);
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Arc comparison : FAIL with $error_count mismatched arcs" );
    }
    else {
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Arc comparison : PASS" );
    }
    $y_coord = $y_coord - 14;

    if ( scalar(@pin_mismatch) > 0 ) {
        my $error_count = scalar(@pin_mismatch);
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Pin comparison : FAIL with $error_count mismatched pins" );
    }
    else {
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Pin comparison : PASS" );
    }
    $y_coord = $y_coord - 14;

    if ( scalar(@pin_direction_mismatch) > 0 ) {
        my $error_count = scalar(@pin_direction_mismatch);
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Pin direction comparison : FAIL with $error_count mismatched pin directions" );
    }
    else {
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Pin direction comparison : PASS" );
    }
    $y_coord = $y_coord - 14;

    if ( scalar(@pin_cap_mismatch) > 0 ) {
        my $error_count = scalar(@pin_cap_mismatch);
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Pin capacitance comparison : FAIL with $error_count mismatched pin caps" );
    }
    else {
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Pin capacitance comparison : PASS" );
    }
    $y_coord = $y_coord - 14;

    if ( scalar(@pin_max_capacitance_mismatch) > 0 ) {
        my $error_count = scalar(@pin_max_capacitance_mismatch);
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Pin max capacitance comparison : FAIL with $error_count mismatches" );
    }
    else {
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Pin max capacitance comparison : PASS" );
    }
    $y_coord = $y_coord - 14;

    if ( scalar(@pin_max_transition_mismatch) > 0 ) {
        my $error_count = scalar(@pin_max_transition_mismatch);
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Pin max tranistion comparison : FAIL with $error_count mismatches" );
    }
    else {
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Pin max transition comparison : PASS" );
    }
    $y_coord = $y_coord - 14;

    if ($is_pg) {
        if ( scalar(@pin_related_power_mismatch) > 0 ) {
            my $error_count = scalar(@pin_related_power_mismatch);
            $page_comparison->stringc( $f1, 12, 280, $y_coord, "Related power comparison : FAIL with $error_count mismatches" );
        }
        else {
            $page_comparison->stringc( $f1, 12, 280, $y_coord, "Related power comparison : PASS" );
        }
    }
    else {
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Related power comparison : N/A" );
    }
    $y_coord = $y_coord - 14;

    if ($is_pg) {
        if ( scalar(@pin_related_ground_mismatch) > 0 ) {
            my $error_count = scalar(@pin_related_ground_mismatch);
            $page_comparison->stringc( $f1, 12, 280, $y_coord, "Related ground comparison : FAIL with $error_count mismatches" );
        }
        else {
            $page_comparison->stringc( $f1, 12, 280, $y_coord, "Related ground comparison : PASS" );
        }
    }
    else {
        $page_comparison->stringc( $f1, 12, 280, $y_coord, "Related ground comparison : N/A" );
    }
    $y_coord = $y_coord - 34;

    $page_comparison->stringc( $f1, 10, 280, $y_coord, "Please find the detailed mismatch report at:" );
    $y_coord = $y_coord - 14;
    $page_comparison->stringc( $f1, 6, 280, $y_coord, "$csv_report_file" );

    return ( $a4, $stage, $pdf, $f1 );

    # ----------------------------------------- End of attribute comparison section --------------------------------------- #
}    ## END createPDF()

## davidgh
#---------------------------------------------------------------------
sub addPDFData {

    my $cellName                      = shift;
    my $libFile1                      = shift;
    my $libFile2                      = shift;
    my $is_pg                         = shift;
    my $csv_report_file               = shift;
    my @csv_compare_messages_mismatch = @{ $_[0] };
    shift;
    my @pin_mismatch = @{ $_[0] };
    shift;
    my @pin_direction_mismatch = @{ $_[0] };
    shift;
    my @pin_max_capacitance_mismatch = @{ $_[0] };
    shift;
    my @pin_max_transition_mismatch = @{ $_[0] };
    shift;
    my @pin_related_power_mismatch = @{ $_[0] };
    shift;
       @pin_related_power_mismatch = @{ $_[0] };
    shift;
    my @pin_related_ground_mismatch = @{ $_[0] };
    shift;
    my @pin_cap_mismatch = @{ $_[0] };
    shift;
    my %PinHash = %{ $_[0] };
    shift;
    my $corner1        = shift;
    my $corner2        = shift;
    my $sdf_compare    = shift;
    my %sdf_conditions = %{ $_[0] };
    shift;
    my $timing_sense       = shift;
    my @ListOfTimingFields = @{ $_[0] };
    shift;
    my %Missing = %{ $_[0] };
    shift;
    my $ui       = shift;
    my $username = shift;
    my %NA_arcs  = %{ $_[0] };
    shift;

    my ( $a4, $stage, $pdf, $f1 ) = createPDF(
        $cellName,                       $libFile1,                    $libFile2,                     $is_pg,                         $csv_report_file,
        \@csv_compare_messages_mismatch, \@pin_mismatch,               \@pin_direction_mismatch,      \@pin_max_capacitance_mismatch, \@pin_max_transition_mismatch,
        \@pin_related_power_mismatch,    \@pin_related_power_mismatch, \@pin_related_ground_mismatch, \@pin_cap_mismatch
    );

    # ----------------------------------------- Generating timing comparison plots ------------------------------------------ #
    my %diff;
    my %diff_csv;
    my $diff_count = 0;               # davidgh
    my $page2      = $a4->new_page;
    foreach my $pin_name ( keys %PinHash ) {
        foreach my $related_pin ( keys %{ $PinHash{$pin_name}{$corner1} } ) {
            foreach my $timing_type ( keys %{ $PinHash{$pin_name}{$corner1}{$related_pin} } ) {
                if ($sdf_compare) {
                    if ( ( !exists $sdf_conditions{$timing_type} ) and ( $timing_type ne "N/A" ) ) {
                        print "Timing arc for $timing_type sdf condition doesn't exist in sdf condition file, skipping ...\n";
                        next;
                    }
                }
                foreach my $timing_sense ( keys %{ $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"} } ) {
                    foreach my $min_delay_flag ( keys %{ $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"} } ) {
                        foreach my $my_field (@ListOfTimingFields) {
                            if (   ( exists $Missing{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field} )
                                or ( exists $NA_arcs{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field} ) )
                            {
                                next;
                            }
                            else {
                                if ( $my_field eq "RestOfLine" ) {

                                    #Skip for now
                                    next;
                                }
                                print "$pin_name $related_pin $timing_type timing_sense:$timing_sense   min_delay_flag:$min_delay_flag $my_field	\n";

                                my $string_values_A = $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{Timing}{$my_field};
                                my $string_values_B = $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{Timing}{$my_field};

                                next if ( ( $string_values_A eq "N/A" ) and ( $string_values_B eq "N/A" ) );

                                my $string_index1_ver1 = $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index1};
                                my $string_index2_ver1 = $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index2};

                                my $string_index1_ver2 = $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index1};
                                my $string_index2_ver2 = $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index2};

                                $string_index1_ver1 =~ s/[\(\{\)\}]//g;
                                $string_index2_ver1 =~ s/[\(\{\)\}]//g;
                                $string_index1_ver2 =~ s/[\(\{\)\}]//g;
                                $string_index2_ver2 =~ s/[\(\{\)\}]//g;

                                my @slew_values_ver1 = split( ",", $string_index1_ver1 );
                                my @load_values_ver1 = split( ",", $string_index2_ver1 );
                                my @slew_values_ver2 = split( ",", $string_index1_ver2 );
                                my @load_values_ver2 = split( ",", $string_index2_ver2 );

                                my @load_values_plot_ver1;
                                my @load_values_plot_ver2;

                                my $ref_value1 = $load_values_ver1[-1];
                                my $ref_value2 = $load_values_ver2[-1];

                                foreach my $index_1 ( 0 .. $#load_values_ver1 ) {
                                    foreach my $index_2 ( 0 .. $#load_values_ver1 ) {
                                        push( @load_values_plot_ver1, $load_values_ver1[$index_2] + $ref_value1 * $index_1 );
                                        push( @load_values_plot_ver2, $load_values_ver2[$index_2] + $ref_value2 * $index_1 );
                                    }
                                }

                                $string_values_A =~ s/[\(\{\)\}]//g;
                                $string_values_B =~ s/[\(\{\)\}]//g;
                                my @values_lib1 = split /,/, $string_values_A;
                                my @values_lib2 = split /,/, $string_values_B;

                                my $max_diff      = 0;
                                my $max_val1      = 0;
                                my $max_val1_real = 0;
                                my $max_val2      = 0;
                                my $max_val2_real = 0;
                                my $diff_percent;

                                for ( my $j = 0 ; $j < $#values_lib1 ; $j++ ) {

                                    if ( abs( abs( $values_lib1[$j] ) - abs( $values_lib2[$j] ) ) > $max_diff ) {
                                        $max_val1      = abs( $values_lib1[$j] );
                                        $max_val2      = abs( $values_lib2[$j] );
                                        $max_val1_real = $values_lib1[$j];
                                        $max_val2_real = $values_lib2[$j];

                                        if ( $max_val1_real =~ m/N\/A\s+(.*)/ ) {
                                            $max_val1_real = $1;
                                            $max_val1      = abs($max_val1_real);
                                        }
                                        if ( $max_val2_real =~ m/N\/A\s+(.*)/ ) {
                                            $max_val2_real = $1;
                                            $max_val2      = abs($max_val2_real);
                                        }

                                        # davidgh
                                        if ( $max_val1_real / $max_val2_real < 0 ) {
                                            $max_diff = abs( $max_val1 + $max_val2 );
                                        }
                                        else {
                                            $max_diff = abs( $max_val1 - $max_val2 );
                                        }

                                        # end davidgh
                                    }
                                }

                                # davidgh
                                if ( ( $max_val1 > $max_val2 ) and ( $max_val2 != 0 ) ) {
                                    $diff_percent = ${max_diff} / ${max_val2} * 100;
                                }
                                elsif ( ( $max_val1 < $max_val2 ) and ( $max_val1 != 0 ) ) {
                                    $diff_percent = ${max_diff} / ${max_val1} * 100;
                                }
                                else {
                                    $diff_percent = "Unknown";
                                }

                                # end davidgh

                                if ( $diff_percent > 100 ) {    # davidgh,  original was -> if  ($diff_percent > 1000)
                                    print $max_val2 , "    ", $max_val1, "     ", $max_diff, "\n";
                                }

                                $max_diff     = sprintf( "%.4f", $max_diff );
                                $diff_percent = sprintf( "%.4f", $diff_percent );

                                my $message_string;

                                if ( $max_val1_real > $max_val2_real ) {
                                    $diff{$diff_percent} =
"Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}% , decreased compared to ref ( pin: $pin_name, related_pin:$related_pin, timing_type: $timing_type, timing_sense : $timing_sense,    min_delay_flag : $min_delay_flag)\n";

#$diff_csv{$diff_percent} = "$ui $max_diff, ${diff_percent}%, $pin_name, $related_pin, $timing_type, $timing_sense, $min_delay_flag, ref value : $max_val1_real, cur value : $max_val2_real, decreased compared to ref, \n";
                                    $diff_csv{ $diff_percent . ':' . $diff_count } =
"$ui $max_diff, ${diff_percent}%, $pin_name, $related_pin, $timing_type, $timing_sense, $min_delay_flag, ref value : $max_val1_real, cur value : $max_val2_real, decreased compared to ref, \n";
                                    $diff_count++;

                                    # davidgh
                                    # $message_string = "Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}%\n";
                                    $message_string =
                                      "Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}%  , ref value : $max_val1_real, cur value : $max_val2_real \n";

                                    # end davidgh
                                }
                                elsif ( $max_val1_real eq $max_val2_real ) {
                                    $diff{$diff_percent} =
"Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}% , Tables are equal ( pin: $pin_name, related_pin:$related_pin, timing_type: $timing_type, timing_sense : $timing_sense,    min_delay_flag : $min_delay_flag)\n";
                                    $diff_csv{ $diff_percent . ':' . $diff_count } =
                                      "$ui $max_diff, ${diff_percent}%, $pin_name, $related_pin, $timing_type, $timing_sense, $min_delay_flag, Tables are equal \n";
                                    $diff_count++;
                                    $message_string = "Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}%  , Tables are equal\n";
                                }
                                else {
                                    $diff{$diff_percent} =
"Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}% , increased compared to ref ( pin: $pin_name, related_pin:$related_pin, timing_type: $timing_type, timing_sense : $timing_sense,    min_delay_flag : $min_delay_flag)\n";
                                    $diff_csv{ $diff_percent . ':' . $diff_count } =
"$ui $max_diff, ${diff_percent}%, $pin_name, $related_pin, $timing_type, $timing_sense, $min_delay_flag, ref value : $max_val1_real, cur value : $max_val2_real, increased compared to ref, \n";
                                    $diff_count++;
                                    $message_string =
                                      "Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}%  , ref value : $max_val1_real, cur value : $max_val2_real \n";
                                }

                                my $len = @values_lib1;

                                my @plot_values_1;
                                my @plot_values_2;

                                for ( my $j = 0 ; $j < $len ; $j++ ) {
                                    push( @plot_values_1, [ $j + 1, $values_lib1[$j] ] );
                                    push( @plot_values_2, [ $j + 1, $values_lib2[$j] ] );
                                }

                                if ( not -d "plots" ) {
                                    mkdir("plots") or die "Can't create directory: plots : $!\n";
                                }

                                my @plot_load_values_1;
                                my @plot_load_values_2;
                                my @plot_slew_values_1;
                                my @plot_slew_values_2;

                                for ( my $j = 0 ; $j <= $#load_values_ver1 ; $j++ ) {
                                    push( @plot_load_values_1, [ 2 * $j, $load_values_ver1[$j] ] );
                                    push( @plot_load_values_2, [ 2 * $j, $load_values_ver2[$j] ] );
                                }

                                for ( my $j = 0 ; $j <= $#slew_values_ver1 ; $j++ ) {
                                    push( @plot_slew_values_1, [ 2 * $j, $slew_values_ver1[$j] ] );
                                    push( @plot_slew_values_2, [ 2 * $j, $slew_values_ver2[$j] ] );
                                }

                                my $chart_dir = "plots/$pin_name/compare/$related_pin/$timing_type/$timing_sense/$min_delay_flag/$my_field";

                                #if ( $sdf_compare )  {
                                $chart_dir =~ s/[\"\(\)=\'\&]//g;

                                #}
                                create_dir($chart_dir);

                                # Chart object
                                my $chart = Chart::Gnuplot->new(
                                    output => "$chart_dir/${my_field}.jpg",
                                    xlabel => {
                                        text => "Load and slew",
                                        font => "Helvetica, 15",
                                    },
                                    ylabel => {
                                        text => "Timing Values",
                                        font => "Helvetica, 15",
                                    },
                                    grid => {
                                        width    => 1,
                                        linetype => "longdash",
                                    }
                                );

                                my $chart2 = Chart::Gnuplot->new(
                                    output => "$chart_dir/${my_field}_2.jpg",
                                    grid   => {
                                        width    => 1,
                                        linetype => "longdash",
                                    }
                                );

                                my @charts = ();

                                $charts[0] = Chart::Gnuplot->new(
                                    xlabel => {
                                        text => "Index",
                                        font => "Helvetica, 15",
                                    },
                                    ylabel => {
                                        text => "Load Values",
                                        font => "Helvetica, 15",
                                    },
                                    grid => {
                                        width    => 0.1,
                                        linetype => "longdash",
                                    },
                                    size   => '0.8 , 0.5',
                                    origin => '0.0 , 0.0'
                                );

                                $charts[1] = Chart::Gnuplot->new(
                                    xlabel => {
                                        text => "Index",
                                        font => "Helvetica, 15",
                                    },
                                    ylabel => {
                                        text => "Slew Values",
                                        font => "Helvetica, 15",
                                    },
                                    grid => {
                                        width    => 0.1,
                                        linetype => "longdash",
                                    },
                                    size   => '0.8 , 0.5',
                                    origin => '0.0 , 0.5'
                                );

                                # Data set object

                                my $dataSet = Chart::Gnuplot::DataSet->new(
                                    points => \@plot_values_1,
                                    style  => "lines",
                                    title  => "reference",
                                    color  => "blue",            # can be color name or RGB value
                                );

                                my $dataSet2 = Chart::Gnuplot::DataSet->new(
                                    points => \@plot_values_2,
                                    style  => "lines",
                                    title  => "current",
                                    color  => "red",             # can be color name or RGB value
                                );

                                my $dataSet_sec1 = Chart::Gnuplot::DataSet->new(
                                    points => \@plot_load_values_1,
                                    style  => "lines",
                                    title  => "reference_load",
                                    color  => "black",                # can be color name or RGB value
                                );

                                my $dataSet_sec2 = Chart::Gnuplot::DataSet->new(
                                    points => \@plot_load_values_2,
                                    style  => "lines",
                                    title  => "current_load",
                                    color  => "green",                # can be color name or RGB value
                                );

                                my $dataSet_sec3 = Chart::Gnuplot::DataSet->new(
                                    points => \@plot_slew_values_1,
                                    style  => "lines",
                                    title  => "reference_slew",
                                    color  => "red",                  # can be color name or RGB value
                                );

                                my $dataSet_sec4 = Chart::Gnuplot::DataSet->new(
                                    points => \@plot_slew_values_2,
                                    style  => "lines",
                                    title  => "current_slew",
                                    color  => "blue",                 # can be color name or RGB value
                                );

                                $chart->plot2d( $dataSet, $dataSet2 );
                                $charts[0]->add2d( $dataSet_sec1, $dataSet_sec2 );
                                $charts[1]->add2d( $dataSet_sec3, $dataSet_sec4 );
                                $chart2->multiplot(@charts);

                                if ( $stage == 4 ) {
                                    $page2 = $a4->new_page;
                                    $stage = 1;
                                }

                                if ( $stage != 4 ) {
                                    my $text1 = "pin : $pin_name,	  related_pin : $related_pin";
                                    my $text2 = "timing type : $timing_type,    arc : $my_field,    timing_sense : $timing_sense,    min_delay_flag : $min_delay_flag";
                                    if ($sdf_compare) {
                                        $text1 = "pin : $pin_name,	  related_pin : $related_pin,        arc : $my_field";
                                        $text2 = "sdf cond : $timing_type";
                                    }
                                    insertImage( \$pdf, \$page2, $stage, "$chart_dir/${my_field}.jpg", "$chart_dir/${my_field}_2.jpg", $text1, $text2, $f1, $message_string, $sdf_compare );
                                    $stage = $stage + 1;
                                    unlink("$chart_dir/${my_field}.jpg");
                                    unlink("$chart_dir/${my_field}_2.jpg");

                                    &delete_tmp_files($username);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    # ----------------------------------------- Logging absolute and percentage difference ------------------------------------------ #
    my $y_coord          = 740;
    my $page_comparison3 = $a4->new_page;
    $page_comparison3->stringc( $f1, 14, 300, $y_coord, "Absolute and percentage difference report" );
    $y_coord = $y_coord - 30;

    foreach my $key ( sort { $b <=> $a } keys %diff ) {
        $diff{$key} =~ /(.*)(\(.*\))/;
        my $sub1 = $1;
        my $sub2 = $2;

        #	            $page_comparison3->stringc($f1, 8, 300, $y_coord, $sub1);

        # davidgh
        my $percentage = substr( ( split( ": ", ( split( ", ", $sub1 ) )[1] ) )[1], 0, -2 );

        if ( $percentage >= 1000 ) {
            $page_comparison3->setrgbcolor( 255, 0, 0 );
            $page_comparison3->stringc( $f1, 8, 300, $y_coord, $sub1 );
            $page_comparison3->setrgbcolor( 0, 0, 0 );
        }
        elsif ( $percentage >= 100 ) {
            $page_comparison3->setrgbcolor( 128, 0, 255 );
            $page_comparison3->stringc( $f1, 8, 300, $y_coord, $sub1 );
            $page_comparison3->setrgbcolor( 0, 0, 0 );
        }
        else {
            $page_comparison3->stringc( $f1, 8, 300, $y_coord, $sub1 );
        }
        $y_coord = $y_coord - 15;

        if ( $y_coord < 70 ) {
            $page_comparison3 = $a4->new_page;
            $y_coord          = 770;
        }

        $page_comparison3->stringc( $f1, 8, 300, $y_coord, $sub2 );
        $y_coord = $y_coord - 30;
    }

    # ----------------------------------------- End of Logging absolute and percentage difference ------------------------------------------ #

    $pdf->closePDF();

    # Removing plots temporary directory
    print "\nRemoving \"plots\" temporary directory ... \n";
    `rm -rf plots`;
    return \%diff_csv;
}    # END addPDFData

## davidgh
#---------------------------------------------------------------------
sub addCSVData {
    my $cellName                      = shift;
    my $libFile1                      = shift;
    my $libFile2                      = shift;
    my $is_pg                         = shift;
    my $csv_report_file               = shift;
    my @csv_compare_messages_mismatch = @{ $_[0] };
    shift;
    my @pin_mismatch = @{ $_[0] };
    shift;
    my @pin_direction_mismatch = @{ $_[0] };
    shift;
    my @pin_max_capacitance_mismatch = @{ $_[0] };
    shift;
    my @pin_max_transition_mismatch = @{ $_[0] };
    shift;
    my @pin_related_power_mismatch = @{ $_[0] };
    shift;
       @pin_related_power_mismatch = @{ $_[0] };
    shift;
    my @pin_related_ground_mismatch = @{ $_[0] };
    shift;
    my @pin_cap_mismatch = @{ $_[0] };
    shift;
    my %PinHash = %{ $_[0] };
    shift;
    my $corner1        = shift;
    my $corner2        = shift;
    my $sdf_compare    = shift;
    my %sdf_conditions = %{ $_[0] };
    shift;
    my $timing_sense       = shift;
    my @ListOfTimingFields = @{ $_[0] };
    shift;
    my %Missing = %{ $_[0] };
    shift;
    my $ui       = shift;
    my $username = shift;
    my %NA_arcs  = %{ $_[0] };
    shift;

    # ----------------------------------------- Generating timing comparison plots ------------------------------------------ #
    my %diff;
    my %diff_csv;
    my $diff_count = 0;    # davidgh
    foreach my $pin_name ( keys %PinHash ) {
        foreach my $related_pin ( keys %{ $PinHash{$pin_name}{$corner1} } ) {
            foreach my $timing_type ( keys %{ $PinHash{$pin_name}{$corner1}{$related_pin} } ) {
                if ($sdf_compare) {
                    if ( ( !exists $sdf_conditions{$timing_type} ) and ( $timing_type ne "N/A" ) ) {
                        print "Timing arc for $timing_type sdf condition doesn't exist in sdf condition file, skipping ...\n";
                        next;
                    }
                }
                foreach my $timing_sense ( keys %{ $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"} } ) {
                    foreach my $min_delay_flag ( keys %{ $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"} } ) {
                        foreach my $my_field (@ListOfTimingFields) {
                            if (   ( exists $Missing{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field} )
                                or ( exists $NA_arcs{$pin_name}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{$my_field} ) )
                            {
                                next;
                            }
                            else {
                                if ( $my_field eq "RestOfLine" ) {

                                    #Skip for now
                                    next;
                                }
                                print "$pin_name $related_pin $timing_type timing_sense:$timing_sense   min_delay_flag:$min_delay_flag $my_field	\n";

                                my $string_values_A = $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{Timing}{$my_field};
                                my $string_values_B = $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{Timing}{$my_field};

                                next if ( ( $string_values_A eq "N/A" ) and ( $string_values_B eq "N/A" ) );

                                my $string_index1_ver1 = $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index1};
                                my $string_index2_ver1 = $PinHash{$pin_name}{$corner1}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index2};

                                my $string_index1_ver2 = $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index1};
                                my $string_index2_ver2 = $PinHash{$pin_name}{$corner2}{$related_pin}{$timing_type}{"timing_sense"}{$timing_sense}{"min_delay_flag"}{$min_delay_flag}{index2};

                                $string_index1_ver1 =~ s/[\(\{\)\}]//g;
                                $string_index2_ver1 =~ s/[\(\{\)\}]//g;
                                $string_index1_ver2 =~ s/[\(\{\)\}]//g;
                                $string_index2_ver2 =~ s/[\(\{\)\}]//g;

                                my @slew_values_ver1 = split( ",", $string_index1_ver1 );
                                my @load_values_ver1 = split( ",", $string_index2_ver1 );
                                my @slew_values_ver2 = split( ",", $string_index1_ver2 );
                                my @load_values_ver2 = split( ",", $string_index2_ver2 );

                                my @load_values_plot_ver1;
                                my @load_values_plot_ver2;

                                my $ref_value1 = $load_values_ver1[-1];
                                my $ref_value2 = $load_values_ver2[-1];

                                foreach my $index_1 ( 0 .. $#load_values_ver1 ) {
                                    foreach my $index_2 ( 0 .. $#load_values_ver1 ) {
                                        push( @load_values_plot_ver1, $load_values_ver1[$index_2] + $ref_value1 * $index_1 );
                                        push( @load_values_plot_ver2, $load_values_ver2[$index_2] + $ref_value2 * $index_1 );
                                    }
                                }

                                $string_values_A =~ s/[\(\{\)\}]//g;
                                $string_values_B =~ s/[\(\{\)\}]//g;
                                my @values_lib1 = split /,/, $string_values_A;
                                my @values_lib2 = split /,/, $string_values_B;

                                my $max_diff      = 0;
                                my $max_val1      = 0;
                                my $max_val1_real = 0;
                                my $max_val2      = 0;
                                my $max_val2_real = 0;
                                my $diff_percent;

                                for ( my $j = 0 ; $j < $#values_lib1 ; $j++ ) {

                                    if ( abs( abs( $values_lib1[$j] ) - abs( $values_lib2[$j] ) ) > $max_diff ) {
                                        $max_val1      = abs( $values_lib1[$j] );
                                        $max_val2      = abs( $values_lib2[$j] );
                                        $max_val1_real = $values_lib1[$j];
                                        $max_val2_real = $values_lib2[$j];

                                        if ( $max_val1_real =~ m/N\/A\s+(.*)/ ) {
                                            $max_val1_real = $1;
                                            $max_val1      = abs($max_val1_real);
                                        }
                                        if ( $max_val2_real =~ m/N\/A\s+(.*)/ ) {
                                            $max_val2_real = $1;
                                            $max_val2      = abs($max_val2_real);
                                        }

                                        # davidgh
                                        if ( $max_val1_real / $max_val2_real < 0 ) {
                                            $max_diff = abs( $max_val1 + $max_val2 );
                                        }
                                        else {
                                            $max_diff = abs( $max_val1 - $max_val2 );
                                        }

                                        # end davidgh
                                    }
                                }

                                # davidgh
                                if ( ( $max_val1 > $max_val2 ) and ( $max_val2 != 0 ) ) {
                                    $diff_percent = ${max_diff} / ${max_val2} * 100;
                                }
                                elsif ( ( $max_val1 < $max_val2 ) and ( $max_val1 != 0 ) ) {
                                    $diff_percent = ${max_diff} / ${max_val1} * 100;
                                }
                                else {
                                    $diff_percent = "Unknown";
                                }

                                # end davidgh

                                if ( $diff_percent > 100 ) {    # davidgh,  original was -> if  ($diff_percent > 1000)
                                    print $max_val2 , "    ", $max_val1, "     ", $max_diff, "\n";
                                }

                                $max_diff     = sprintf( "%.4f", $max_diff );
                                $diff_percent = sprintf( "%.4f", $diff_percent );

                                my $message_string;

                                if ( $max_val1_real > $max_val2_real ) {
                                    $diff{$diff_percent} =
"Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}% , decreased compared to ref ( pin: $pin_name, related_pin:$related_pin, timing_type: $timing_type, timing_sense : $timing_sense,    min_delay_flag : $min_delay_flag)\n";

#$diff_csv{$diff_percent} = "$ui $max_diff, ${diff_percent}%, $pin_name, $related_pin, $timing_type, $timing_sense, $min_delay_flag, ref value : $max_val1_real, cur value : $max_val2_real, decreased compared to ref, \n";
                                    $diff_csv{ $diff_percent . ':' . $diff_count } =
"$ui $max_diff, ${diff_percent}%, $pin_name, $related_pin, $timing_type, $timing_sense, $min_delay_flag, ref value : $max_val1_real, cur value : $max_val2_real, decreased compared to ref, \n";
                                    $diff_count++;

                                    # davidgh
                                    # $message_string = "Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}%\n";
                                    $message_string =
                                      "Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}%  , ref value : $max_val1_real, cur value : $max_val2_real \n";

                                    # end davidgh
                                }
                                elsif ( $max_val1_real eq $max_val2_real ) {
                                    $diff{$diff_percent} =
"Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}% , Tables are equal ( pin: $pin_name, related_pin:$related_pin, timing_type: $timing_type, timing_sense : $timing_sense,    min_delay_flag : $min_delay_flag)\n";
                                    $diff_csv{ $diff_percent . ':' . $diff_count } =
                                      "$ui $max_diff, ${diff_percent}%, $pin_name, $related_pin, $timing_type, $timing_sense, $min_delay_flag, Tables are equal \n";
                                    $diff_count++;
                                    $message_string = "Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}%  , Tables are equal\n";
                                }
                                else {
                                    $diff{$diff_percent} =
"Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}% , increased compared to ref ( pin: $pin_name, related_pin:$related_pin, timing_type: $timing_type, timing_sense : $timing_sense,    min_delay_flag : $min_delay_flag)\n";
                                    $diff_csv{ $diff_percent . ':' . $diff_count } =
"$ui $max_diff, ${diff_percent}%, $pin_name, $related_pin, $timing_type, $timing_sense, $min_delay_flag, ref value : $max_val1_real, cur value : $max_val2_real, increased compared to ref, \n";
                                    $diff_count++;
                                    $message_string =
                                      "Absolute maximal difference is : $max_diff  ,  difference in percentage : ${diff_percent}%  , ref value : $max_val1_real, cur value : $max_val2_real \n";
                                }
                            }
                        }
                    }
                }
            }  ## END foreach my $timing_type 
        }  ## END foreach my $related_pin
    }  ## END foreach my $pin_name

    return \%diff_csv;

}    # END addCSVData

#---------------------------------------------------------------------
sub usage {

    my $USAGE = <<EOusage;

    Script to compare timing arc of specified lib files.
    ref: reference lib file to be compared with. 
    cur: lib file of current release. 
    cell: the cell name which is compared.
    cap_limit: permissible capacitance difference.
    csv : flag to generate output csv report.
    merge : flag to turn on/turn off min_delay and timing sense.
    ui : ui for compared blocks
    sdf : list of sdf conditions to be plotted in PDF report, mainly used for bdl/lcdl .lib comparison. 
    	  if sdf condition file is empty, pdf report will be generated on for timing arcs with no sdf conditions.
	  CSV report as well as arc comparison will contain full list of possible arcs, no matter the specified sdf condition list.
	  

    Usage: timing_status.pl [-h|-help]

    -h or -help  this help message
    -ref 
    -cur
    -cell
    -cap_limit
    -csv
    -ui
    -merge
    -sdf

    example of usage:

    Run Example:
    ./CompareArcs.pl -ref=path/lib_file1.lib -cur=/path/lib_file2.lib -cell=cellName -csv
    ./CompareArcs.pl -ref=path/lib_file1.lib -cur=/path/lib_file2.lib -cell=cellName -csv -merge     
    ./CompareArcs.pl -ref=path/lib_file1.lib -cur=/path/lib_file2.lib -cell=cellName -csv -sdf=sdf_conditions.txt
    
     
    Example of sdf condition file:
    "(byp_mode == 1'b0 && test_mode == 1'b1 && dly_sel[8] == 1'b0 && dly_sel[7] == 1'b0 && dly_sel[6] == 1'b0 && dly_sel[5] == 1'b0 && dly_sel[4] == 1'b0 && dly_sel[3] == 1'b0 && dly_sel[2] == 1'b0 && dly_sel[1] == 1'b0 && dly_sel[0] == 1'b0)"
    "(byp_mode == 1'b0 && test_mode == 1'b1 && dly_sel[8] == 1'b0 && dly_sel[7] == 1'b0 && dly_sel[6] == 1'b0 && dly_sel[5] == 1'b0 && dly_sel[4] == 1'b0 && dly_sel[3] == 1'b0 && dly_sel[2] == 1'b0 && dly_sel[1] == 1'b0 && dly_sel[0] == 1'b1)"
    "(cal_mode == 1'b1 && dly_sel[8] == 1'b1 && dly_sel[7] == 1'b1 && dly_sel[6] == 1'b1 && dly_sel[5] == 1'b1 && dly_sel[4] == 1'b0 && dly_sel[3] == 1'b1 && dly_sel[2] == 1'b1 && dly_sel[1] == 1'b0 && dly_sel[0] == 1'b0)"
    "(cal_mode == 1'b1 && dly_sel[8] == 1'b1 && dly_sel[7] == 1'b1 && dly_sel[6] == 1'b1 && dly_sel[5] == 1'b1 && dly_sel[4] == 1'b0 && dly_sel[3] == 1'b1 && dly_sel[2] == 1'b1 && dly_sel[1] == 1'b0 && dly_sel[0] == 1'b1)"
    "(cal_mode == 1'b1 && dly_sel[8] == 1'b1 && dly_sel[7] == 1'b1 && dly_sel[6] == 1'b1 && dly_sel[5] == 1'b1 && dly_sel[4] == 1'b0 && dly_sel[3] == 1'b1 && dly_sel[2] == 1'b1 && dly_sel[1] == 1'b1 && dly_sel[0] == 1'b0)"
    "(cal_mode == 1'b1 && dly_sel[8] == 1'b1 && dly_sel[7] == 1'b1 && dly_sel[6] == 1'b1 && dly_sel[5] == 1'b1 && dly_sel[4] == 1'b0 && dly_sel[3] == 1'b1 && dly_sel[2] == 1'b1 && dly_sel[1] == 1'b1 && dly_sel[0] == 1'b1)"
    "(cal_mode == 1'b1 && dly_sel[8] == 1'b1 && dly_sel[7] == 1'b1 && dly_sel[6] == 1'b1 && dly_sel[5] == 1'b1 && dly_sel[4] == 1'b1 && dly_sel[3] == 1'b0 && dly_sel[2] == 1'b0 && dly_sel[1] == 1'b0 && dly_sel[0] == 1'b0)"
    "(cal_mode == 1'b1 && dly_sel[8] == 1'b1 && dly_sel[7] == 1'b1 && dly_sel[6] == 1'b1 && dly_sel[5] == 1'b1 && dly_sel[4] == 1'b1 && dly_sel[3] == 1'b0 && dly_sel[2] == 1'b0 && dly_sel[1] == 1'b0 && dly_sel[0] == 1'b1)"
    "(cal_mode == 1'b1 && dly_sel[8] == 1'b1 && dly_sel[7] == 1'b1 && dly_sel[6] == 1'b1 && dly_sel[5] == 1'b1 && dly_sel[4] == 1'b1 && dly_sel[3] == 1'b0 && dly_sel[2] == 1'b0 && dly_sel[1] == 1'b1 && dly_sel[0] == 1'b0)"
    

EOusage

    print $USAGE;
    exit;

}
