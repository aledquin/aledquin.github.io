#!/depot/perl-5.14.2/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Path;
use Cwd;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use File::Basename qw( dirname );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

##  Constants
our $LOG_INFO = 0;
our $LOG_WARNING = 1;
our $LOG_ERROR = 2;
our $LOG_FATAL = 3;
our $LOG_RAW = 4;

our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $PROGRAM_NAME = $RealScript;
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';

BEGIN { our $AUTHOR='dikshant'; header(); }
Main() unless caller();
END {
	write_stdout_log( $LOGFILENAME );
    local $?;   # to prevent the exit() status from getting modified
    footer();
}


#--------------------------------------------------------------------------
sub write_lines{
    print_function_header();
    my $flavor = shift;
    my @list   = @{ shift(@_) };

    dprint( LOW, "\$flavor = $flavor \n" );
    dprint( LOW, "\@list   = " . join(', ', @list) ."\n" );

	  my @file_content;

    # If the list is not empty, add lines, else issue warning
    if( $#list >= 0 ){
	      push(@file_content, "set$flavor { " . join(' ' , @list) );
	      push(@file_content, " }\n");
    }else{
        wprint( "    No $flavor...\n" );
    }

    print_function_footer();
    return( @file_content );
}

#----------------------------------------------------------------------
sub create_supply_file{
    print_function_header();
    my @powernets = @_;

    my(@lines);
    push(@lines, "### Power Supply Net ###\n");

    if( $#powernets >= 0 ){
        push(@lines, write_lines( '_supply_net' ,\@powernets) );
	    
        for ( my $i=0; $i<=$#powernets; $i++ ){
            my $pwr = '$vcore';
            if( $powernets[$i] eq "VDD" ){
	              $pwr = '$vcore';
	          }elsif( $powernets[$i] eq "VDDQ" ){
	              $pwr = '$vio';
	          }
	          push(@lines, "set_voltage $pwr $powernets[$i]\n");
        }
    }else{
        wprint( "    No POWERNETs...\n" );
    }
    push(@lines, "\n");

    print_function_footer();
    return( @lines );
}

#-------------------------------------------------------------
sub Main {
    my ( $opt_pininfo ) = process_cmd_line_args();

    my $path = '../timing/src/';
    #   $path = '.';
    my $port_file       = "$path/port_setup.tcl";
    my $munge_file      = "$path/Munge_nanotime.cfg";
    my $pwr_supply_file = "$path/pwr_supply.tcl";

    ## welcome
    iprint( "Converting $opt_pininfo pin info file to $port_file port setup and to $munge_file munge config...\n" );

    my $href = parse_pininfo_file( $opt_pininfo );

    my @lines_port_file;
	  push(@lines_port_file, write_lines( ' NON_CLOCK_INPUTS' , \@{ $href->{non_clk_inputs} } ) );
	  push(@lines_port_file, write_lines( ' OUTPUTS'          , \@{ $href->{outputs}        } ) );
	  push(@lines_port_file, write_lines( ' INPUTS'           , \@{ $href->{inputs}         } ) );
	  push(@lines_port_file, write_lines( ' CLOCK_INPUTS'     , \@{ $href->{clk_inputs}     } ) );
	  push(@lines_port_file, write_lines( ' INOUTS'           , \@{ $href->{inouts}         } ) );    
	  push(@lines_port_file, write_lines( ' POWERNET'         , \@{ $href->{powernets}      } ) );
    push(@lines_port_file, "\n");

    write_file(\@lines_port_file,$port_file);
    #----------------------------------------
    # Need to adjust user_setting.tcl file when there's an INOUT port
    if( $#{ $href->{inouts} } >= 0 ){
        iprint "    Update user_setting.tcl...\n";
        run_system_cmd( "sed -e 's/INOUT_status 0/INOUT_status 1/' $path/user_setting.tcl > $path/temp.tcl","$VERBOSITY" );
        run_system_cmd( "mv ../timing/src/temp.tcl ../timing/src/user_setting.tcl","$VERBOSITY" );
    }

    #----------------------------------------
    ## write power supply file

    iprint( "For $pwr_supply_file, finding POWERNETS...\n" );
    my @lines_pwr_supply_file = create_supply_file( @{ $href->{'powernets'} } );

    write_file(\@lines_pwr_supply_file, $pwr_supply_file);

    #----------------------------------------
    #  Write the munge file
    #----------------------------------------

    ## write munge config file
    iprint "  Writing $munge_file munge config...\n";
    my @lines_munge_file;
    my @keys;

    my $header_string = get_header_string();
    push(@lines_munge_file, $header_string);

    #------------------------------------
    ## write cell areas
    @keys = sort keys %{ $href->{areas} };
    if( @keys ){
        iprint "    Writing cell areas...\n";
    }
    foreach my $cell ( @keys ){
        push(@lines_munge_file, "\ncell_area $href->{areas}{$cell} $cell\n");
    }

    push(@lines_munge_file, "\n");

    #------------------------------------
    ## write pg_pin info
    @keys = sort keys %{ $href->{'pg_info'} };
    if( @keys ){
        iprint "    Writing pg pin information...\n";
    }
    foreach my $pwr_name ( @keys ){
        push(@lines_munge_file, "pg_pin $pwr_name $href->{'pg_info'}{$pwr_name} \n");
    }    
 
    push(@lines_munge_file, "\n");   

    #------------------------------------
    ## write add_vmap info
    if( @keys ){
        if( exists $href->{pg_info}{VDD}){
            iprint " we have VDD in pg_pin, no necessary to add_vmap...\n";
        }else{
            iprint "    Writing add_vmap information...\n";
            push(@lines_munge_file, "add_vmap VDD PWR \n");
        }
    }
  
    push(@lines_munge_file, "\n");   

    #------------------------------------
    ## write add_pin_info
    @keys = sort keys %{ $href->{related_powers} };
    if( @keys ){
        iprint "    Writing add_pin_info...\n";
    }
    foreach my $port_name ( @keys ){
        my $pwr = $href->{related_powers}{$port_name}; 
        my $gnd = $href->{related_grounds}{$port_name}; 
        push(@lines_munge_file, "add_pin_info $port_name $pwr $gnd\n" );
    }

    push(@lines_munge_file, "\n");

    #------------------------------------
    ## write add_bus_info
    @keys = sort keys %{ $href->{related_bus_powers} };
    if( @keys ){
        iprint "    Writing add_bus_info...\n";
    }
    foreach my $port_name ( @keys ){
        my $pwr = $href->{related_bus_powers}{$port_name}; 
        my $gnd = $href->{related_bus_grounds}{$port_name}; 
        my $msb = $href->{bus_msb}{$port_name};
        my $lsb = $href->{bus_lsb}{$port_name};
        my $dir = $href->{bus_dir}{$port_name};
	      push(@lines_munge_file, "add_bus_info $port_name $msb $lsb $dir $pwr $gnd\n" );
    }

    ## close files
    push(@lines_munge_file, "\n");
    write_file(\@lines_munge_file, $munge_file);

    exit(0);
}

#------------------------------------------------------------------
sub get_header_string(){
    print_function_header();

    my $header_string = <<"MHEADER";
## Munge_nanotime.pl config
# ## Available commands
# report_level 3
#         ## define reporting level
#         ## 0(Error,Warning),
#         ## 1(Error,Warning,Info. DEFAULT level),
#         ## 2(Error,Warning,Info lists modifications in pin_hash),
#         ## 3(print only command Description, but do not run it)
# 
# d <pin_name>
#         ## delete pin
# 
# r <related_pin_name> <pin_name>
#         ## remove timing arc
# 
# s <old_pin_name> <new_pin_name>
#         ## rename pin
# 
# m <old_related_pin_name> <new_related_pin_name> <pin_name>
#         ## rename related pin
# 
# delete_min_delay <true/false>
#         ## delete all timing arcs where min_delay_flag is true/false
# 
# add_pin <pin_name> <direction>  <capacitance> <max_capacitance> <min_capacitance> <max_transition> <min_transition> [*_capacitance_range_en]
#         ## add pin
#         ## use NONE value if <capacitance> <max_capacitance> <min_capacitance>
#         ## <max_transition> <min_transition> values are unknown
#         ## The last switch is optional, se it to cap_range_en to have
#         ## rise_capacitance_range,fall_capacitance_range attributes extracted to out .lib
# 
# add_bus <pin_name> <left_bit> <right_bit> <direction>  <capacitance> <max_capacitance> <min_capacitance> <max_transition> <min_transition>
#         ## add bus(array) of pins
#         ## use NONE value if <capacitance> <max_capacitance> <min_capacitance>
#         ## <max_transition> <min_transition> values are unknown
#         ## The last switch is optional, se it to cap_range_en to have
#         ## rise_capacitance_range,fall_capacitance_range attributes extracted to out .lib
# 
# change_dir <pin_name> <direction>
#         ## change pin direction
# 
# mark_clock <pin_name>
#         ## mark pin as a clock pin
# 
#         ##############################################################
#         ## use NONE value if timing_type or timing_sense attribute is missing in timing arc
#         ## eg. mod_timing_type_sense rx_ana_word_clk rx_m  rising_edge NONE falling_edge NONE
#         ##############################################################
# u <pin_name> <related_pin_name>  <timing_type2> <timing_sense2>  <timing_type1> <timing_sense1>  <new_timing_type> <new_timing_sense>
#         ## combine two timing arcs into one timing arc,
#         ## use NONE value if timing_type or timing_sense attribute is missing in timing arc
#         ## timing arc will be deleted if <timing_type2> == <timing_type1>, and <timing_sense2> == <timing_sense1>
# 
# split_arc <in_pin> <rel_pin> <old_timing_type> <old_timing_sense> <new_rise_timing_type> <new_rise_timing_sense> <new_fall_timing_type> <new_fall_timing_sense>
#         ## split one timing arc into two timing arcs
#         ## use NONE value if timing_type or timing_sense attribute is missing in timing arc
# 
# mod_timing_type_sense <pin_name> <related_pin_name>  <old_timing_type> <old_timing_sense> <new_timing_type> <new_timing_sense>
#         ## modify timing_type, timing_sense attributes in timing arc
#         ## use NONE value if timing_type or timing_sense attribute is missing in timing arc
# 
# copy_lut <pin_name> <related_pin_name>  <timing_type> <timing_sense> <rise/fall>
#         ## copy rise lookup tables to fall tables, and visa versa
#         ## use NONE value if timing_type or timing_sense attribute is missing in timing arc
# 
# copy_pin <source_pin_name> <new_pin_name> <dont_copy_timing/copy_timing>
#         ## Copy <source_pin_name> pin block to <new_pin_name>,  if <source_pin_name> exists.
#         ## The whole content of <new_pin_name> will be overwritten if it already exists
#         ## Do not copy pin timing blocks when timing_copy_option is dont_copy_timing.
#         ## Copy timing blocks when copy_timing.
#
# pg_pin <pin_name> <PWR/GND>
#         ## Change power pin from regular pin port to pg_pin
#	
# cell_area <cell_area_umsq>
#         ## Add area in cell information
#	
# add_pin_info <pin_name> <related_pwr_pin> <related_gnd_pin>
#         ## Add related power or ground pin information to each pin
#
# add_bus_info <bus_name> <msb> <lsb> <direction> <related_pwr_pin> <related_gnd_pin>
#         ## Add related information to each bus
#
# add_vmap <pin_name> <PWR/GND>
#         ## Add voltage map
MHEADER

    print_function_footer();
    return( $header_string )
}

#------------------------------------------------------------------
sub parse_pininfo_line($){
    print_function_header();
    my $line = shift;

    # parse line from pininfo file
    my @fields    = split(/,/, $line);

    my $pin_name  = $fields[0];
    my $pin_dir   = $fields[1];
    my $is_bus    = $fields[9];
    my $pwr_name  = "";
    
    $pin_name =~ m/\[(\d+):(\d+)\]/;
    my $msb = NULL_VAL;
       $msb = $1  if( defined $1 && isa_int($1) );
    my $lsb = NULL_VAL;
       $lsb = $2  if( defined $2 && isa_int($2) );
    if( isa_int($msb) && isa_int($lsb) ){
        if( $msb < $lsb ){
           my $tmp = $msb;
           $msb = $lsb;
           $lsb = $tmp;
        }
    }
    my $pin_type       = $fields[2];
    my $related_power  = $fields[5];
    my $related_ground = $fields[4];

    dprint(LOW, "pin_name => '$pin_name'\n" );
    dprint(LOW, "pin_dir  => '$pin_dir'\n" );
    dprint(LOW, "is_bus   => '$is_bus'\n" );
    dprint(LOW, "msb      => '$msb'\n" );
    dprint(LOW, "lsb      => '$lsb'\n" );
    dprint(LOW, "pin_type => '$pin_type'\n" );
    dprint(LOW, "rel_gnd  => '$related_ground'\n" );
    dprint(LOW, "rel_pwr  => '$related_power'\n" );
    prompt_before_continue( LOW );
    
    print_function_footer();
    return( $pin_name, $pin_dir, $pin_type, $is_bus, 
            $msb, $lsb, $related_power, $related_ground );
}

#------------------------------------------------------------------
sub parse_pininfo_file($){
    print_function_header();
    my $opt_pininfo = shift;
    my $port_name;
    
    my ( %bus_msb, %bus_lsb, %pg_info, %bus_dir );
    my ( %related_bus_powers, %related_bus_grounds );
    my ( %related_powers, %related_grounds, %areas );
    my @clk_inputs = ();
    my @inputs     = ();
    my @powernets  = ();
    my @gndnets    = ();
    my @inouts     = ();
    my @outputs    = ();
    my @non_clk_inputs = ();
    
    #------------------------------------------
    #  read pin info file ... 
    #------------------------------------------
    my @IFH_array = read_file( $opt_pininfo );
    my $fields_header_row = shift( @IFH_array );  # do nothing with this
    #------------------------------------------
    #     sample content below
    #------------------------------------------
    # name,direction,pin_type,related_clock_pin,related_ground_pin,related_power_pin,derating_factor,desc,donot_repeat,is_bus,is_true_core_ground,lsb,max_capacitive_load,max_voltage,min_capacitive_load,msb,nominal_voltage,package_pin,related_select_pin,synlibchecker_waive,cellname,cell_x_dim_um,cell_y_dim_um
    # BP_DQ0,IO,general_signal,-,VSS,VDDQ,-,-,-,n,-,-,-,-,-,-,-,-,-,-,dwc_lpddr5xphycover_dx4_top_ew,262.905,224.28
    # BP_DQ1,IO,general_signal,-,VSS,VDDQ,-,-,-,n,-,-,-,-,-,-,-,-,-,-,dwc_lpddr5xphycover_dx4_top_ew,262.905,224.28
    # RxDQSInX8T,I,general_signal,-,VSS,VDD,-,-,-,n,-,-,-,-,-,-,-,-,-,-,dwc_lpddr5xphycover_dx4_top_ew,262.905,224.28
    # RxDQSX8C,O,general_signal,-,VSS,VDD,-,-,-,n,-,-,-,-,-,-,-,-,-,-,dwc_lpddr5xphycover_dx4_top_ew,262.905,224.28
    # RxDQSX8T,O,general_signal,-,VSS,VDD,-,-,-,n,-,-,-,-,-,-,-,-,-,-,dwc_lpddr5xphycover_dx4_top_ew,262.905,224.28
    # TIELO_RxDQSInX8,O,general_signal,-,VSS,VDD,-,-,-,n,-,-,-,-,-,-,-,-,-,-,dwc_lpddr5xphycover_dx4_top_ew,262.905,224.28
    # VDD,I,primary_power,-,-,-,-,-,-,n,-,-,-,-,-,-,-,-,-,-,dwc_lpddr5xphycover_dx4_top_ew,262.905,224.28
    # VDDQ,I,primary_power,-,-,-,-,-,-,n,-,-,-,-,-,-,-,-,-,-,dwc_lpddr5xphycover_dx4_top_ew,262.905,224.28
    # VIO_PwrOk,I,general_signal,-,VSS,VDDQ,-,-,-,n,-,-,-,-,-,-,-,-,-,-,dwc_lpddr5xphycover_dx4_top_ew,262.905,224.28
    # VSS,I,primary_ground,-,-,-,-,-,-,n,-,-,-,-,-,-,-,-,-,-,dwc_lpddr5xphycover_dx4_top_ew,262.905,224.28
    # csrReserved[3:0],I,general_signal,-,VSS,VDD,-,-,-,y,-,0,-,-,-,3,-,-,-,-,dwc_lpddr5xphy_ato_ew,183.12,74.36
    ## loop through input file
    foreach my $line (@IFH_array) {
        my $pwr_name;
        $line =~ s/\#.*//; ## prune comments
        my ( $pin_name, $pin_dir, $pin_type, $is_bus, 
        $msb, $lsb, $related_power, $related_ground ) = parse_pininfo_line( $line );
        
    	  ## for busses
    	  if($is_bus =~ m/^y|Y$/ ){
    	      ## construct port name
    	      #  1. strip bus if it's part of pin name
    	      #  2. append bus to pin name
    	      $pin_name  =~ s/\[\d+:\d+\]//;
    	      $port_name = "$pin_name\[$msb\:$lsb\]";
    
    	      ## determine if bus increments or decrements
    		    $bus_msb{"$pin_name"} = $msb;
    		    $bus_lsb{"$pin_name"} = $lsb;
    	      $bus_dir{"$pin_name"} = $pin_dir;    	   	    
    	      $related_bus_powers{"$pin_name"}  = $related_power;
    	      $related_bus_grounds{"$pin_name"} = $related_ground;
    	  }elsif($pin_type=~/power/i or $pin_type=~/ground/i){
        	  $pwr_name           = $pin_name;
        	  $pg_info{$pin_name} = $pin_type;
    	  }else{
            ## just use pin name
        	  $port_name = $pin_name ;

            ## store related powers
        	  $related_powers{$pin_name}  = $related_power;
        	  $related_grounds{$pin_name} = $related_ground;
    	  }
    
        ## recognize inputs
    		if( $pin_dir =~ m/^I$/i ){
    	    	if( $pin_type=~/clk/i ){
    				    push(@clk_inputs, $port_name );
    				    push(@inputs, $port_name );
            }elsif( $pin_type =~ m/primary_power/i  ){
    				    push(@powernets, $pwr_name );
            }elsif( $pin_type =~ m/primary_ground/i ){
    				    push(@gndnets,   $pwr_name );
    	    	}else{
    				    push(@non_clk_inputs, $port_name );
    				    push(@inputs, $port_name );
    	    	}
    		}elsif( $pin_dir =~ m/^IO$/ ){
    	    	push( @inouts, $port_name );
    		}elsif( $pin_dir =~ m/^O$/ ){
    	      push @outputs, $port_name;
    		}else{
    	      eprint( "Unrecognized pin direction '$pin_dir' for pin '$pin_name'. \n" );
    		    exit 1;
    	  }
        if( $line =~ /,([^,]+),(\d+\.\d+),(\d+\.\d+)$/ ){
    	      my $cell = $1;
    	      my $x    = $2 || 0;
    	      my $y    = $3 || 0;
    	      dprint(LOW, "cell name (x,y) => $cell ($x , $y)\n" );
    	      $areas{$cell} = $x * $y;
    	      ## check area
    	      if( $areas{$cell} <= 0 ){
    	          wprint( "\nArea $areas{$cell} for cell $cell from pin info is not positive:\n  $line\n" );
    	      }
        }else{
    		    eprint( "Illegal line in input file '$opt_pininfo':\n\t$line\n" );
    		    #exit 1;
        }
    } ## end foreach

	my %hash = (
		'bus_msb'    => \%bus_msb, 
		'bus_lsb'    => \%bus_lsb, 
		'pg_info'    => \%pg_info, 
		'bus_dir'    => \%bus_dir, 
		'areas'      => \%areas, 
		'inputs'     => \@inputs, 
		'gndnets'    => \@gndnets,
		'inouts'     => \@inouts, 
		'outputs'    => \@outputs,
		'powernets'  => \@powernets, 
		'clk_inputs' => \@clk_inputs, 
		'non_clk_inputs'      => \@non_clk_inputs, 
		'related_powers'      => \%related_powers, 
		'related_grounds'     => \%related_grounds, 
		'related_bus_powers'  => \%related_bus_powers, 
		'related_bus_grounds' => \%related_bus_grounds, 
	);
	
	print_function_footer();
	return( \%hash );
}

#--------------------------------------------------------------------------
sub process_cmd_line_args(){
    print_function_header();
    my ( $opt_verbosity, $opt_debug, $opt_help, $opt_nousage, $opt_pininfo);

    my $result = GetOptions(
		  "pininfo=s"       => \$opt_pininfo,
          "verbosity=i"     => \$opt_verbosity,
          "debug=i"         => \$opt_debug,
          "help"            => \$opt_help, 
          "nousage"         => \$opt_nousage,
    );

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );

    ## quit with usage message, if usage not satisfied
    &usage(0) if $opt_help;
    &usage(1) unless( $result );
    &usage(1) unless( defined $opt_pininfo );

	unless( $opt_nousage) {
       utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@ARGV);
    }

	print_function_footer();
    return( $opt_pininfo );
}

#------------------------------------------------------------------------------
#  script usage message
#------------------------------------------------------------------------------
sub usage($) {
    my $exit_status = shift;

    print << "EOP" ;
Description
  A script to 

USAGE : $PROGRAM_NAME [options] -pininfo pininfo_filename

------------------------------------
Required Args:
------------------------------------
-pininfo  <pininfo_filename>    project SPEC (i.e. <project_type>/<project>/<CD_rel> )


------------------------------------
Optional Args:
------------------------------------
-help           Print this screen
-verbosity  <#>    print additional messages ... includes details of system calls etc. 
                   Must provide integer argument -> higher values increases verbosity.
-debug      <#>    print additional diagnostic messagess to debug script
                   Must provide integer argument -> higher values increases messages.

EOP

    exit $exit_status ;
} # usage()

#dprint(NONE, "\%areas => ". scalar(Dumper \%areas) ."\n" );
