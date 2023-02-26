#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;

###############################################################################
# Name    : NicksLibertyParser.pl
# Author  : Multiple
# Date    : n/a
# Purpose : n/a
# History :
#   001 ljames  10/25/2022
#       remove tabs and replace with 4 spaces
#       added Main() subroutine
###############################################################################
use Pod::Usage;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use Cwd     qw( getcwd );
use List::MoreUtils qw(uniq);
use English;
use Time::localtime;

use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../lib/perl/";
use Util::Misc;
use Util::Messaging;
use Util::CommonHeader;
use Util::DS;

use Liberty::Parser; 

#------------------------------CONSTANTS-----------------------------#
use constant FIFTY   => 50;
use constant MILLION => 1000000;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#

BEGIN { 
    our $AUTHOR='wadhawan'; 
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header(); 
    #delete $ENV{PERL5LIB};
} 
&Main() unless caller();

END {
   footer(); 
   write_stdout_log($LOGFILENAME);
   local $?;
}

##  The current PERL5LIB causes issues.
##  Issue-343 ljames cleaning out lint and also make this code more standard
##  BEGIN {delete $ENV{PERL5LIB}}

#variables
my $result;
my @liberty;
my $liberty;
my $max_var_1;
my $max_var_2;
my $min_var_1;
my $min_var_2;
my %PinHash;

my @ViewList;
my %TypeCount;
my $MAXLIBDELAY = 2e-9;   ##  Delays greater than this get flagged.
my $MINLIBDELAY = 0;   ##  Delays less than this get flagged.
my $MAXLIBTRAN = 1e-9;   ##  Delays greater than this get flagged.
my $MINLIBTRAN = 0;   ##  Delays less than this get flagged.
my $MINLIBSnH = -1e-9;  ##  Setup/hold less than this get flagged.
my $MAXLIBSnH = 1e-9;  ##  Setup/hold greater than this get flagged.
my $timingdata ={};        
my $this_table = "";

sub Main(){
    my @saved_args = @ARGV;  # make a copy for usage stats
    my ($opt_nousage, $values, @liberty) = process_cmd_line_args();

    unless( $main::DEBUG || $opt_nousage){
        utils__script_usage_statistics($PROGRAM_NAME, $VERSION, \@saved_args);
    }

    my $status = ReadLiberty(\@liberty, $values);

    exit(0);
} # End Main

sub usage($)
{
    my $exit_status = shift;

    my $verbose_level = 1;
    my $message_text  = "Script $RealBin/$RealScript\n";

    # ljames 11/1/2022 added the -input option because without it, for
    # some unknown reason (maybe $0 got messed up) it was not able to
    # find the script.
    pod2usage({
        -input  => "$RealBin/$RealScript",
        -message => $message_text ,
        -exitval => $exit_status,
        -verbose => $verbose_level,
        });

    exit($exit_status);
}

sub GetValueFromPair($)
{
    my $pair = shift;

    if ($pair =~ m/(\S+)\s*:\s*(\S+)/){
        return $2;
    }else{ 
        return ; # a simple return returns undef
    }
}

sub StdDir($)
{
    my $dir = shift;
    if (!(defined $dir)) {return $dir}
    $dir = lc $dir;

    if    ($dir eq "in")    { return "input" }
    elsif ($dir eq "i")     { return "input" }
    elsif ($dir eq "o")     { return "output" }
    elsif ($dir eq "b")     { return "io" }
    elsif ($dir eq "out")   { return "output" }
    elsif ($dir eq "ioput") { return "io" }
    elsif ($dir eq "inout") { return "io" }
    else                    { return $dir}
}

sub defineWithDefault($$)
{
    my $default = shift;
    my $value   = shift;

    if (defined $value){
        return $value;
    }else{
        return $default;
    }
}

sub ReadLiberty($$)
{
    my $aref_liberty = shift;
    my $values       = shift;

    if (! $aref_liberty || scalar( @$aref_liberty)==0 ) {
        wprint "No liberty file specified";
        return 1;
    }   ##  No args specified.
    my $ViewIdx=0;
    my @filelist;
    foreach my $file (@$aref_liberty){
        push(@filelist, glob($file));
    }

    my $Nfiles = @filelist;
    if ($Nfiles == 0) {print "Warning:  No files found \"@$aref_liberty\"\n"; return}

    foreach my $liberty_file (@filelist)
    {
        if (!(-r $liberty_file) ){
            wprint("Liberty file \"$liberty_file\" cannot be read\n");
            next;
        }
        iprint("Reading $liberty_file\n"); 
        my $parser         = new Liberty::Parser; 
        my $library_group  = $parser->read_file($liberty_file);
        my $lib_name       = $parser->get_group_name($library_group);
        #checkLibname($lib_name, $liberty_file);

        my $leakage_power_unit = $parser->get_simple_attr_value($library_group, "leakage_power_unit");
        my @opconds = $parser->get_groups_by_type($library_group, "operating_conditions"); 
        my $Ncond   = @opconds;
        my $opcond_defined = ($Ncond > 0);   ## At least one operating condition.
        my $tree_type_defined = $opcond_defined;
        foreach my $opcond (@opconds ){
            if (!(defined $parser->get_simple_attr_value($opcond, "tree_type") )){
                $tree_type_defined = 0;
            }
        }

        my $default_max_capacitance = GetValueFromPair(
            $parser->get_attr_with_value($library_group, "default_max_capacitance"));
        my $default_max_transition = GetValueFromPair(
            $parser->get_attr_with_value($library_group, "default_max_transition"));

        ##  Get all the lookup table templates
        my $tableHash = {};
        my @tables    = $parser->get_groups_by_type($library_group, "lu_table_template"); 
        my $Ntable    = @tables;
        foreach my $table (@tables)
        {
            my $table_name = $parser->get_group_name($table);
            iprint( "Looking up table $table_name\n");
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
        $time_unit =~ m/^(\d+)([a-zA-Z]+)/;
        if ($2 eq "ns" ){
            $time_unit = "${1}e-9";
        } elsif ($2 eq "ps"){
            $time_unit = "${1}e-12";
        } else {
            print "Error:  Unrecognized time unit \"$time_unit\"\n";
        }

        #my $cell_group = $parser->locate_cell($library_group, $macro);
        ## Maddeningly difficult to determine if the cell name provided is actually found; locate_cell returns a defined cell_group even if it's not there
        ##   and can't figure out a way to determine it's validity without triggering an exception.
        ##   This seems to work.
        my $cell_group = $parser->locate_group_by_type($library_group, "cell");
        my $cell_name  = $parser->get_group_name($cell_group);
        my $cell_leakage_power = GetValueFromPair(
            $parser->get_attr_with_value($cell_group, "cell_leakage_power"));
        my $areaval    = $parser->get_attr_with_value($cell_group, "area");

        my $area = GetValueFromPair($areaval);
        $area    = sprintf("%.6f", $area);

        my @pins = $parser->get_groups_by_type($cell_group, "pin"); 

        #make sure the first four exist, if not then give the value none
        if ($values) {
            printf ("%-30s\t%10s\t%10s\t%15s\t%20s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\n","pin_name","direction","pincap","related_pin","timing_type","{rise_cnstr}","{fall_cnstr}","{cell_rise}","{cell_fall}","{rise_tran}","{fall_tran}");
        } else {
            printf ("%-30s\t%10s\t%15s\t%20s\n","pin_name","direction","related_pin","timing_type");
        }

        foreach my $pin (sort @pins)
        {
            my $timing_count = 0;
            my $pin_name = $parser->get_group_name($pin);
            my $direction = StdDir($parser->get_simple_attr_value($pin, "direction"));
            my $pincap = GetValueFromPair($parser->get_attr_with_value($pin, "capacitance"));
            my $related_power = $parser->get_simple_attr_value($pin, "related_power_pin");
            my $related_ground = $parser->get_simple_attr_value($pin, "related_ground_pin");
            my $max_capacitance = defineWithDefault($default_max_capacitance, GetValueFromPair($parser->get_attr_with_value($pin, "capacitance")));
            my $max_transition = defineWithDefault($default_max_transition, GetValueFromPair($parser->get_attr_with_value($pin, "max_transition")));
            #print ">>> $pin_name:  max_cap: $max_capacitance, max_tran: $max_transition\n";
            my @timings = $parser->get_groups_by_type($pin, "timing");
            #$parser->print_timing_arc($pin);
            foreach my $timing (sort @timings) {
                my $related_pin   = $parser->get_simple_attr_value($timing, "related_pin");
                my $timing_type   = $parser->get_simple_attr_value($timing, "timing_type");
                my $group_extract = $parser->extract_group($timing,$timing_type);
                my $index2 = ${timing_type}."index_2";
                my $index3 = ${timing_type}."index_3";

                if ($group_extract =~ /${index3}/ ) {
                } elsif ($group_extract =~ /${index2}/) {
                    $timingdata->{"rise_constraint"} = $parser->get_lookup_table_center($timing, "rise_constraint");
                    $timingdata->{"fall_constraint"} = $parser->get_lookup_table_center($timing, "fall_constraint");
                    $timingdata->{"cell_rise"}       = $parser->get_lookup_table_center($timing, "cell_rise");
                    $timingdata->{"cell_fall"}       = $parser->get_lookup_table_center($timing, "cell_fall");
                    $timingdata->{"rise_transition"} = $parser->get_lookup_table_center($timing, "rise_transition");
                    $timingdata->{"fall_transition"} = $parser->get_lookup_table_center($timing, "fall_transition");
                }else{
                    #print "\t\t $pin_name $timing_type DOES NOT HAVE index 2\n";
                    $timingdata->{"rise_constraint"} = "N/A";
                    $timingdata->{"fall_constraint"} = "N/A";
                    $timingdata->{"cell_rise"}       = "N/A";
                    $timingdata->{"cell_fall"}       = "N/A";
                    $timingdata->{"rise_transition"} = "N/A";
                    $timingdata->{"fall_transition"} = "N/A";
                    #print "#"x80; print "\n$group_extract";print "#"x80; print "\n";
                    my @extract_fields = split ("$timing_type",$group_extract);
                    $this_table = "";
                    my $this_table_type = "";
                    my $thevalues = "";
                    foreach my $this_field (@extract_fields) {
                        #print "$this_field";
                        if ($this_field =~ /^\s*(\w+)\s+\((scalar)\)\s+\{\s*$/) {
                            $this_table = $1;
                            $this_table_type = $2;
                        }elsif ($this_field =~ /^\s*(\w+)\s+\(([fr]_itrans)\)\s+\{\s*$/) {
                            $this_table = $1;
                            $this_table_type = $2;
                        }elsif ($this_field =~/^\s*values\s*\(\s*\"(.*)\"\s*\)\s*\;\s*$/) {
                            $thevalues = $1 ;
                        }
                    }            
                    my @thevalues   = split (",",$thevalues);
                    my $arraySize   = @thevalues;
                    my $arrayMiddle = int(($arraySize/2)+($arraySize%2)-1);
                    
                    $timingdata->{$this_table} = $thevalues[$arrayMiddle];
                    $timingdata->{"OTHER_THING"} = $thevalues[$arrayMiddle];
                }
                #make sure the first four exist, if not then give the value none
                if ($pin_name eq "")    { $pin_name    = "none"; }
                if ($direction eq "")   { $direction   = "none"; }
                if ($pincap eq "")      { $pincap      = "none"; }
                if ($related_pin eq "") { $related_pin = "none"; } 
                if ($timing_type eq "") { $timing_type = "none"; }
                if ($values) {
                    printf("%-30s\t%10s\t%10s\t%15s\t%20s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\n",
                        $pin_name, $direction, $pincap, $related_pin,
                        $timing_type,
                        $timingdata->{rise_constraint},
                        $timingdata->{fall_constraint},
                        $timingdata->{cell_rise},
                        $timingdata->{cell_fall},
                        $timingdata->{rise_transition},
                        $timingdata->{fall_transition});
                } else {
                    printf("%-30s\t%10s\t%15s\t%20s\n",$pin_name, $direction,
                        $related_pin, $timing_type);
                }
        ##        print "$pin_name,\t\t$direction,\t$pincap,\t$related_pin,\t$timing_type,\t$timingdata->{rise_constraint},\t$timingdata->{fall_constraint},\t$timingdata->{cell_rise},\t$timingdata->{cell_fall},\t$timingdata->{rise_transition},\t$timingdata->{fall_transition}\n";
                $timing_count++;
            } #foreach sort @timings


            if ($direction ne "internal"){
                #StorePin($pin_name, $direction, "signal", $related_power, $related_ground, $pincap, $pintimings);
                $PinHash{$pin_name}->[$ViewIdx]->{DIR} = $direction;
                $PinHash{$pin_name}->[$ViewIdx]->{TYPE} = "signal";
                $PinHash{$pin_name}->[$ViewIdx]->{RELATED_POWER} = $related_power;
                $PinHash{$pin_name}->[$ViewIdx]->{RELATED_GROUND} = $related_ground;
                $PinHash{$pin_name}->[$ViewIdx]->{PINCAP} = $pincap;
                $PinHash{$pin_name}->[$ViewIdx]->{MAX_CAPACITANCE} = $max_capacitance;
                $PinHash{$pin_name}->[$ViewIdx]->{MAX_TRANSITION} = $max_transition;
            }

            if ($timing_count == 0) {
                viprint($VERBOSITY, "NoTiming $pin_name,$direction,$pincap\n");
            }
        } # foreach @pins

        my @pg_pins = $parser->get_groups_by_type($cell_group, "pg_pin"); 
        foreach my $pg_pin (@pg_pins ){
            my $pin_name = $parser->get_group_name($pg_pin);
            my $pg_type = $parser->get_simple_attr_value($pg_pin, "pg_type");
            my $pg_dir = StdDir($parser->get_simple_attr_value($pg_pin, "direction"));
            #StorePin($pin_name, $pg_dir, StdType($pg_type), undef, undef );
        }
        my @buses = $parser->get_groups_by_type($cell_group, "bus");
        foreach my $bus (sort @buses ){
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
            my $bit_from  = $parser->get_attr_with_value($g, "bit_from");
            my $bit_to    = $parser->get_attr_with_value($g, "bit_to");
            $bit_width    = GetValueFromPair($bit_width);
            $bit_from     = GetValueFromPair($bit_from);
            $bit_to       = GetValueFromPair($bit_to);
            my @buspins    = $parser->get_groups_by_type($bus, "pin");
            my $bustimings = $parser->get_groups_by_type($bus, "timing");
            my $pin_name   = $parser->get_group_name($bus);
            my @timings    = $parser->get_groups_by_type($bus, "timing");

            #StorePin("$bus_name\[$bit_from:$bit_to\]", $direction, "signal", $related_power, $related_ground, $buscap, $bustimings);
            my $theBusName = "$bus_name\[$bit_from:$bit_to\]";
            $PinHash{$theBusName}->[$ViewIdx]->{DIR} = $direction;
            $PinHash{$theBusName}->[$ViewIdx]->{TYPE} = "signal";
            $PinHash{$theBusName}->[$ViewIdx]->{RELATED_POWER} = $related_power;
            $PinHash{$theBusName}->[$ViewIdx]->{RELATED_GROUND} = $related_ground;
            $PinHash{$theBusName}->[$ViewIdx]->{PINCAP} = $buscap;
            $PinHash{$theBusName}->[$ViewIdx]->{MAX_CAPACITANCE} = $bus_max_capacitance;
            $PinHash{$theBusName}->[$ViewIdx]->{MAX_TRANSITION} = $bus_max_transition;

            my $Nbuspins = @buspins;
            foreach my $pin (sort @buspins){
                my $timing_count = 0;
                my $pin_name = $parser->get_group_name($pin);
                if ($pin_name =~ m/^$bus_name[\[<]/)
                {
                    ##  Process any bus-nested pin statements.
                    my $direction      = StdDir($parser->get_simple_attr_value($pin, "direction"));
                    my $related_power  = $parser->get_simple_attr_value($pin, "related_power_pin");
                    my $related_ground = $parser->get_simple_attr_value($pin, "related_ground_pin");
                    my $pincap         = GetValueFromPair($parser->get_attr_with_value($pin, "capacitance"));
                    #my $pintimings = GetTiming($parser, $pin);
                    my $pin_name = $parser->get_group_name($pin);
                    my @timings  = $parser->get_groups_by_type($pin, "timing");
        #            if ($direction ne "internal") {StorePin($pin_name, $direction, "signal", $related_power, $related_ground)}
                    #if ($direction ne "internal") {CheckBusPin($pin_name, $direction, "signal", $related_power, $related_ground, $pincap, $pintimings)}
                    my $max_capacitance = defineWithDefault($bus_max_capacitance, GetValueFromPair($parser->get_attr_with_value($pin, "max_capacitance")));
                    my $max_transition = defineWithDefault($bus_max_transition, GetValueFromPair($parser->get_attr_with_value($pin, "max_transition")));
                    $PinHash{$pin_name}->[$ViewIdx]->{MAX_CAPACITANCE} = $max_capacitance;
                    $PinHash{$pin_name}->[$ViewIdx]->{MAX_TRANSITION}  = $max_transition;
                    #addPinAttr($pin_name, "MAX_CAPACITANCE", $max_capacitance);
                    #addPinAttr($pin_name, "MAX_TRANSITION", $max_transition);

                    foreach my $timing (@timings ){
                        my $related_pin = $parser->get_simple_attr_value($timing, "related_pin");
                        my $timing_type = $parser->get_simple_attr_value($timing, "timing_type");
                        if ($timing_type eq "min_pulse_width" || 
                            $timing_type eq "minimum_period"  || 
                            $timing_type eq "max_clock_tree_path" ||
                            $timing_type eq "min_clock_tree_path" ) {
                            next ;
                        }
                        $timingdata->{"rise_constraint"} = $parser->get_lookup_table_center($timing, "rise_constraint");
                        $timingdata->{"fall_constraint"} = $parser->get_lookup_table_center($timing, "fall_constraint");
                        $timingdata->{"cell_rise"}       = $parser->get_lookup_table_center($timing, "cell_rise");
                        $timingdata->{"cell_fall"}       = $parser->get_lookup_table_center($timing, "cell_fall");
                        $timingdata->{"rise_transition"} = $parser->get_lookup_table_center($timing, "rise_transition");
                        $timingdata->{"fall_transition"} = $parser->get_lookup_table_center($timing, "fall_transition");
                        #make sure the first four exist, if not then give the value none
                        if ($pin_name eq "")    { $pin_name    = "none"; }
                        if ($direction eq "")   { $direction   = "none"; }
                        if ($pincap eq "")      { $pincap      = "none"; }
                        if ($related_pin eq "") { $related_pin = "none"; } 
                        if ($timing_type eq "") { $timing_type = "none"; }

                        if ($values) {
                            printf("%-30s\t%10s\t%10s\t%15s\t%20s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\n",
                                $pin_name, $direction, $pincap, $related_pin,
                                $timing_type,
                                $timingdata->{rise_constraint},
                                $timingdata->{fall_constraint},
                                $timingdata->{cell_rise},
                                $timingdata->{cell_fall},
                                $timingdata->{rise_transition},
                                $timingdata->{fall_transition});
                        } else {
                            printf("%-30s\t%10s\t%15s\t%20s\n",
                                $pin_name, $direction, $related_pin, $timing_type);
                        }
                        $timing_count++;
                    }
                    if ($timing_count == 0) {
                        viprint( $VERBOSITY, "No Timing for $pin_name, $direction, $pincap\n");
                    }
                }else{
                    print "ERROR: Pin $pin_name of bus $bus_name has name mismatch\n";
                }
            } # foreach sort @buspins
        } # foreach @buses
        
        my $rec = {};
        $rec->{FILENAME}           = $liberty_file;
        $rec->{AREA}               = $area;
        $rec->{TYPE}               = "liberty";
        $rec->{PARSER}             = $parser;
        $rec->{TIME_UNIT}          = $time_unit;
        $rec->{LEAKAGE_POWER_UNIT} = $leakage_power_unit;
        $rec->{CELL_LEAKAGE_POWER} = $cell_leakage_power;
        $rec->{OPCOND_DEFINED}     = $opcond_defined;
        $rec->{TREE_TYPE_DEFINED}  = $tree_type_defined;

        $rec->{DEFAULT_MAX_CAPACITANCE} = $default_max_capacitance;
        $rec->{DEFAULT_MAX_TRANSITION}  = $default_max_transition;

        $rec->{TABLES} = $tableHash;

        $ViewList[$ViewIdx++] = $rec;
        $TypeCount{liberty}++;

        #print Dumper($rec);
    } # foreach @filelist


    # Some values from Liberty::Parser 

    #Pclk,max_clock_tree_path
    #print $parser->extract_group($timing,$timing_type);
    #    max_clock_tree_pathtiming () {
    #  max_clock_tree_pathtiming_type : "max_clock_tree_path";
    #  max_clock_tree_pathtiming_sense : "negative_unate";
    #  max_clock_tree_pathcell_rise (f_itrans) {
    #    max_clock_tree_pathindex_1 ( "0.000000, 0.002000, 0.005000, 0.010000, 0.020000, 0.040000, 0.080000");
    #    max_clock_tree_pathvalues ( "0.398017, 0.398694, 0.399710, 0.401403, 0.404613, 0.410738, 0.420307");
    #  max_clock_tree_path}
    #max_clock_tree_path}

    #print $parser->extract_group_1($timing,$timing_type);
    #max_clock_tree_pathtiming () {
    #  max_clock_tree_pathtiming_type : "max_clock_tree_path";
    #  max_clock_tree_pathtiming_sense : "negative_unate";
    #

    #$parser->print_attrs($timing);
    #timing_type
    #timing_sense

    #print $parser->get_attr_with_value($timing,"timing_type");
    #timing_type : "max_clock_tree_path";
}

sub process_cmd_line_args(){
    my ($opt_help,    $opt_verbosity, $opt_debug, 
        $opt_nousage, $opt_values,    @opt_liberty);

    my $status = GetOptions(
        "liberty=s@" => \@opt_liberty,
        "values"     => \$opt_values,
        "help"       => \$opt_help,
        "verbosity=i"=> \$opt_verbosity,
        "debug=i"    => \$opt_debug,
        "nousage"    => \$opt_nousage,
        );
    $main::VERBOSITY = $opt_verbosity if ( $opt_verbosity );
    $main::DEBUG     = $opt_debug     if ( $opt_debug );
    usage(0) if ( $opt_help);
    #usage(1) unless(@ARGV);

    return($opt_nousage, $opt_values, @opt_liberty);
}
1;


__END__

=head1 NAME
 
 NicksLibertyParser.pl

=head1 VERSION
 2022.11

=head1 ABSTRACT

    A synopsis of the new script

=head1 DESCRIPTION

Provide an overview of functionality and purpose of
this script

=head1 OPTIONS

=head2 ARGS

=over 8

=item B<-h> send for help (just spits out this POD by default, but we can 
chose something else if we like 

=back

=head3 other arguments and flags that are valid

=cut

