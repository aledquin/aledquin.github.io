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
use Cwd qw( abs_path getcwd );
use Cwd;
use Carp qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = FALSE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#
our $LOGFILENAME = getcwd() . "/${PROGRAM_NAME}.log";
BEGIN { our $AUTHOR='Multiple Authors'; header(); } 
&Main();
END {
   write_stdout_log("${LOGFILENAME}");
   footer(); 
   utils__script_usage_statistics( "$PREFIX-$RealScript", $VERSION);
}

use Data::Dumper;
use Getopt::Long;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

#
##  Constants
our $LOG_INFO = 0;
our $LOG_WARNING = 1;
our $LOG_ERROR = 2;
our $LOG_FATAL = 3;
our $LOG_RAW = 4;



#####################################################################################################################################################################


my ($debug,$opt_help);

sub Main {

($debug,$opt_help)
            = process_cmd_line_args();    

    if ( $opt_help ) {
        usage();
    }

## parse input file
my($in_file) = @ARGV;
if (not defined $in_file) {
    wprint ("Wrong args: try $0 <Verilog netlist>\n");
    exit;
}

## Welcome
my $config_file = $0;
$config_file =~ s/\.pl/.cfg/;
my $out_file="./pin_info.txt";
iprint ("Generating pin info file $out_file from verilog file $in_file and config file $config_file...\n");

## local variables
my($eg_power_affix, $eg_power_name, $sg_power_name, $gnd_name);
my($found_module, $pin_dir, $pin_name, $pin_type, $msb, $lsb, $is_bus, $power, $gnd);

## read config file
#my $CFH = "";
#open ($CFH,"<","$config_file")	|| die "Can't find or open config file: $config_file\n";
my @CFH = read_file("$config_file");

foreach (@CFH){
    ## prune comments
    s/\#.*//;
    ## pin suffix/prefix for eg power
    if(/^\s*eg_power_affix\s*\=\s*(\w+)\s*$/){
	$eg_power_affix = $1;
    }
    ## eg power pin
    elsif(/^\s*eg_power_name\s*\=\s*(\w+)\s*$/){
	$eg_power_name = $1;
    }
    ## sg power pin
    elsif(/^\s*sg_power_name\s*\=\s*(\w+)\s*$/){
	$sg_power_name = $1;
    }
    ## ground pin
    elsif(/^\s*gnd_name\s*\=\s*(\w+)\s*$/){
	$gnd_name = $1;
    }
    ## ignore comment/blank lines
    elsif(/^\s*$/){
    }
    else{
	eprint ("ERROR: Config file $config_file:$. contains illegal line:\n$_");
	exit 1;
    }
} ## end while(<CFH>){

## open input files
#my ($IFH,$OFH) = "";
#open($IFH,"<","$in_file")	|| die "Can't find or open input file: $in_file\n";
my @IFH = read_file("$in_file");
#open($OFH,">","$out_file")		|| die ("Can't open output file: $out_file");

## read input file
foreach (@IFH) {
    ## recongize module declaration and write header
    if(/^\s*module\s+(\S+)\s*\(/) {
	my $found_module = $1;
	#print $OFH "##<cellname cell_x_dim_um cell_y_dim_um>\n";
	#print $OFH "<$found_module x_dim_um y_dim_um>\n";
	#print $OFH "##| name | direction | bus | msb | lsb | type | related_power_pin | related_ground_pin |\n";
	my $OFH1 = write_file("##<cellname cell_x_dim_um cell_y_dim_um>\n","pin_info.txt");
	my $OFH2 = write_file("<$found_module x_dim_um y_dim_um>\n","pin_info.txt",">");
	my $OFH3 = write_file("##| name | direction | bus | msb | lsb | type | related_power_pin | related_ground_pin |\n","pin_info.txt",">");

	iprint ("  Found module: $found_module\n");

    }
    ## recognize pin info
    elsif((defined $found_module) && (/^\s*(input|output|inout)\s*(\[(\d+)\:(\d+)\])?\s*(\S+)\s*;/)){
	$pin_dir=$1;
	$pin_name = $5;

	## bus pin?
	if(defined $2){
	    $msb = $3;
	    $lsb = $4;
	    $is_bus= 'Y';
	}
	else{
	    $msb = '-';
	    $lsb = '-';
	    $is_bus= 'N';
	}

	## sg power pin?
	if( $pin_name eq $sg_power_name ){
	    $power = '-';
	    $gnd = '-';
	    $pin_type = 'PWR';
	}
	## eg power pin?
	elsif( $pin_name eq $eg_power_name ){
	    $power = '-';
	    $gnd = '-';
	    $pin_type = 'PWR';
	}
	## ground pin?
	elsif( $pin_name eq $gnd_name ){
	    $power = '-';
	    $gnd = '-';
	    $pin_type = 'GND';
	}
	## eg related signal pin?
	elsif( $pin_name=~/^$eg_power_affix\_|\_$eg_power_affix$/ ){
	    $power = $eg_power_name;
	    $gnd = $gnd_name;
	    $pin_type = '-';
	}
	## eg related signal for active low pins
	elsif( $pin_name=~/^$eg_power_affix\_|\_${eg_power_affix}X$/ ){
	    $power = $eg_power_name;
	    $gnd = $gnd_name;
	    $pin_type = '-';
	}
	## otherwise, assume signal pin
	else{
	    $power = $sg_power_name;
	    $gnd = $gnd_name;
	    $pin_type = '-';
	}

	## write pin info
	#print $OFH "| $pin_name | $pin_dir | $is_bus | $msb | $lsb | $pin_type | $power | $gnd |\n";
	my $OFH4 = write_file("| $pin_name | $pin_dir | $is_bus | $msb | $lsb | $pin_type | $power | $gnd |\n","pin_info.txt");

    } ## end elsif((defined $found_module) && (/^\s*(input|output|inout)\s*(\[(\d+)\:(\d+)\])?\s*(\S+)\s*;/)){

    ## end of module
    elsif (/^\s*endmodule/) {
	undef $found_module;
    }
    ## ignore other lines...
} ## end while (<IFH>) {

## close files

## all done
nprint ("All done.\n");
}


sub process_cmd_line_args(){
    my ($debug,$opt_help,$opt_dryrun,$opt_debug,$opt_verbosity);


    my $success = GetOptions(
               "help|h"          => \$opt_help,
               "dryrun!"         => \$opt_dryrun,
               "debug=i"         => \$opt_debug,
               "verbosity=i"     => \$opt_verbosity
        );


    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    &usage(0) if $opt_help;
    &usage(1) unless( $success );

    return ($opt_debug,$opt_help)	

}

sub usage($) {
my $exit_status = shift || '0';
    my $USAGE = <<EOusage;

    The script generate the pin info file from the provided verilog file and config file.
    Usage
    scriptpath/create_pin_info.pl -<verilog_file>
EOusage

    nprint ("$USAGE");
    exit($exit_status);    
}
