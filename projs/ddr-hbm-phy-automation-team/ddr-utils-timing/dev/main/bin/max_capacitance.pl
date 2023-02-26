#!/depot/perl-5.14.2/bin/perl

#use strict;
#use warnings;
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Cwd;
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
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#

use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);

BEGIN { our $AUTHOR='IN08 Timing team'; header(); } 
&Main();
END {
   write_stdout_log( $LOGFILENAME );
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}


#use lib '/remote/cad-rep/projects/alpha/alpha_common/bin';
#use lib '/depot';
use English;
use Time::localtime;
use Data::Dumper ;
use Liberty::Parser; 
use Parse::Liberty;
use File::Temp qw/ tempfile tempdir /;
use File::Copy;
use File::Find;
use lib "$RealBin/../lib/perl/PDF";
use lib "$RealBin/../lib/perl/Chart";
use PDF::Create;
use Chart::Gnuplot;





sub Main {

my $ScriptPath = "";
foreach (my @toks) {$ScriptPath .= "$_/"}
$ScriptPath = abs_path($ScriptPath);
my $lib = "";
my $opt_help = "";
($lib, $opt_help) = process_cmd_line_args();


my ($bus_max_capacitance, $bus_max_transition, $bus_name, @buspins, $pinInfo, $related_ground, $related_power, $status, $this_table, $timing_count, $timingdata);
#my @arr_lib = `ls $lib/*.lib`;
my ($arr_lib, $stderr) = run_system_cmd("ls $lib/*.lib", $VERBOSITY);
my @arr_lib = split("\n",$arr_lib);
chomp @arr_lib;

#open(my $log, ">","grep_result/max_capacitance.log") or print "Could not open file $!\n";

my @log;
push @log, "corner pin_name related_pin timing_type timing_sense min_delay_flag max_capacitance index_2 status\n";
#`cd $lib`;


foreach my $libname (@arr_lib) {
#print $log "$libname\n";
my @split_lib = split /\//,$libname;
#print "$split_lib[-1]\n";
my @extract_corner = split /_/, $split_lib[-1];


my $liberty_file = $libname;
if (!(-r $liberty_file)) {Util::Messaging::wprint("Warning:  Liberty file \"$liberty_file\" cannot be read\n"); next}	
#print $log "lib"


my $parser = new Liberty::Parser; 
my $library_group  = $parser->read_file($liberty_file);
my $lib_name = $parser->get_group_name($library_group);
my $cell_group = $parser->locate_group_by_type($library_group, "cell");
my $cell_name = $parser->get_group_name($cell_group);
my @pins = $parser->get_groups_by_type($cell_group, "pin"); 
my $default_max_capacitance = GetValueFromPair($parser->get_attr_with_value($library_group, "default_max_capacitance"));
my $default_max_transition = GetValueFromPair($parser->get_attr_with_value($library_group, "default_max_transition"));


foreach my $pin (sort @pins) {
	my $pin_name = $parser->get_group_name($pin);
    my $direction = StdDir($parser->get_simple_attr_value($pin, "direction"));
    my $pincap = GetValueFromPair($parser->get_attr_with_value($pin, "capacitance"));
    my $max_capacitance = defineWithDefault($default_max_capacitance, GetValueFromPair($parser->get_attr_with_value($pin, "max_capacitance")));
    my $max_transition = defineWithDefault($default_max_transition, GetValueFromPair($parser->get_attr_with_value($pin, "max_transition")));
	$pincap = "N/A" if ( ! $pincap);
    $direction = "N/A" if ( ! $direction);

    $pinInfo->{$pin_name}{direction}=$direction;
    $pinInfo->{$pin_name}{pincap}=$pincap;
    $pinInfo->{$pin_name}{related_power}=$related_power;	
    $pinInfo->{$pin_name}{related_ground}=$related_ground;
    $pinInfo->{$pin_name}{max_capacitance}=$max_capacitance;
    $pinInfo->{$pin_name}{max_transition}=$max_transition;			

	my @timings = $parser->get_groups_by_type($pin, "timing");
#	print "direction: $direction\n";
	if ($direction eq "output") {
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
            		my @arc_types = ( "rise_constraint" , "fall_constraint" , "cell_rise" , "cell_fall" , "rise_transition" , "fall_transition");
            		my $cur_arc;
            		foreach my $arc_type ( @arc_types ) { 
            		    $cur_arc = $parser->locate_group_by_type($timing, $arc_type);
                        if ($cur_arc != 0) {
                        my @arr_index1 = $parser->get_lookup_table_index_1($cur_arc);
            	    	my @arr_index2 = $parser->get_lookup_table_index_2($cur_arc);
                        if ($max_capacitance == $arr_index2[4]) {
						$status = "PASS" ;
					} else {
						$status = "FAIL" ;
					}
                        push @log, "$extract_corner[-2] $pin_name $related_pin $timing_type $timing_sense $min_delay_flag $max_capacitance $arr_index2[4] $status\n";
            	    }
            		}			    

            	} else {
            		Util::Messaging::wprint("$pin_name $timing_type DOES NOT HAVE index 2\n");
            		$timingdata->{"index1"} = "N/A";
            		$timingdata->{"index2"} = "N/A";		
            		#print "#"x80; print "\n$group_extract";print "#"x80; print "\n";
            		
            	    }
            	    #make sure the first four exist, if not then give the value none
            	    if ($pin_name eq "")    { $pin_name    = "none"; }
            	    if ($direction eq "")   { $direction   = "none"; }
            	    if ($pincap eq "")      { $pincap	   = "none"; }
            	    if ($related_pin eq "") { $related_pin = "none"; } 
            	    if ($timing_type eq "") { $timing_type = "none"; }
        	    
#            	    print "$pin_name $related_pin $timing_type $timing_sense $min_delay_flag $max_capacitance $arr_index2[2]\n";
            	    $timing_count++;
            	}
	}

}


my @buses = $parser->get_groups_by_type($cell_group, "bus");
foreach my $pin (sort @buspins)
{
    my $timing_count = 0;
    my $pin_name = $parser->get_group_name($pin);
    if ($pin_name =~ m/^$bus_name[\[<]/)
    {
	##  Process any bus-nested pin statements.
	my $direction = StdDir($parser->get_simple_attr_value($pin, "direction"));
	my $related_power = $parser->get_simple_attr_value($pin, "related_power_pin");
	my $related_ground = $parser->get_simple_attr_value($pin, "related_ground_pin");
	my $pincap = GetValueFromPair($parser->get_attr_with_value($pin, "capacitance"));
	#my $pintimings = GetTiming($parser, $pin);
	my $pin_name = $parser->get_group_name($pin);
#    print "pin_name : $pin_name\n";
	my @timings = $parser->get_groups_by_type($pin, "timing");
	my $max_capacitance = defineWithDefault($bus_max_capacitance, GetValueFromPair($parser->get_attr_with_value($pin, "max_capacitance")));
	my $max_transition = defineWithDefault($bus_max_transition, GetValueFromPair($parser->get_attr_with_value($pin, "max_transition")));
	$pinInfo->{$pin_name}{direction}=$direction;
	$pinInfo->{$pin_name}{pincap}=$pincap;
	$pinInfo->{$pin_name}{related_power}=$related_power;	
	$pinInfo->{$pin_name}{related_ground}=$related_ground;
	$pinInfo->{$pin_name}{max_capacitance}=$max_capacitance;
	$pinInfo->{$pin_name}{max_transition}=$max_transition;
#	print "direction: $direction\n";
	}
}
}

if (! -d "./grep_result") {
    mkdir("./grep_result");
}

if ( ! -f "./grep_result/max_capacitance.log") {
    run_system_cmd("touch ./grep_result/max_capacitance.log", $VERBOSITY);
}

my $writefile_out = Util::Misc::write_file(\@log,"./grep_result/max_capacitance.log");

Util::Messaging::iprint("Run complete\n");

}




sub GetValueFromPair
{
    my $Pair = shift;
    if ($Pair =~ m/(\S+)\s*:\s*(\S+)/) {return $2} else  {return}
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

sub defineWithDefault
{
    my $default = shift;
    my $value = shift;

    if (defined $value) {return $value} else {return $default}
}

sub createString { 

    my @arr_ref = @_;
    #print "-----------------\n";
    
    my $string = "{";

    foreach my $arrref ( @arr_ref ) { 
	#print "bbb $arrref\n";
	if ( $arrref == "N/A" ) { 
	    return "N/A";
	}
	$string = $string."(";
	foreach my $number  ( @$arrref ) { 
	    $string = $string."$number,";
	}
	$string = $string.")";
    }
    $string = $string."}";
    return $string;
}

sub print_usage {
    my $ScriptPath = shift;
    Util::Messaging::nprint("Current script path:  $ScriptPath\n");
    pod2usage(0);
}

sub process_cmd_line_args(){
    my ( $opt_lib, $opt_help, $opt_dryrun, 
         $opt_debug,  $opt_verbosity );

    my $success = GetOptions(
        "lib=s"    => \$opt_lib,
        "help"        => \$opt_help,           # Prints help
     );

    if( defined $opt_dryrun ){
        $main::TESTMODE = TRUE;
    }

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    &print_usage("$RealBin/$PROGRAM_NAME") if $opt_help;
    &print_usage("$RealBin/$PROGRAM_NAME") unless( $success );
    #&usage(1) unless( defined $opt_projSPEC );
   return( $opt_lib, $opt_help );
};

