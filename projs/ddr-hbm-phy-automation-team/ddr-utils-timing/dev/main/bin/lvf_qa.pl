#!/depot/perl-5.14.2/bin/perl


#################################################################
## Author        : Nandagopan G                                 #
## Functionality : LVF QA                                       # 
#################################################################



use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd;
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $PREFIX       = "ddr-utils-timing";
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#



use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);


utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);

#########################################################################
BEGIN { our $AUTHOR='DA WG'; header(); } 
&Main();
END {
   write_stdout_log("$LOGFILENAME");
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}


sub Main {

my $FR;
my $macro;
my $mode;
my $p;
my $path;
my $tool;
my $log;
my $macro_txt;
my @mismatched_details = ();
my @mismatched_pg_details = ();
my @mismatched_transistor_etm = ();
my $mismatched_transistor_etm;
my @mismatched_transistor_internal = ();
my $mismatched_transistor_internal;
my $missing_ocv;
my $missing_pg_ocv;
my $txt;



if ($ARGV[0] eq "" | $ARGV[1] eq "" | $ARGV[2] eq "")
{
  Util::Messaging::eprint("Usage : lvf_qa.pl <path till macro directory> <macro name/mode.txt path> <sis/nt/lvf>\n");
  exit(0);
}


$path = $ARGV[0];
#print  "$ARGV[0]\n";
chomp ($path);

if (defined $path && $path eq "\-help")
{
  Util::Messaging::iprint("Usage : lvf_qa.pl <path till macro directory> <macro name/mode.txt path> <sis/nt/lvf>\n");
  exit(0);
}
$mode = $ARGV[1];
chomp($mode);
$tool = $ARGV[2];
chomp ($tool);

my @log;
my @missing_ocv;
my @missing_pg_ocv;



if($tool eq "lvf") {

$txt = $ARGV[1];
chomp ($txt);
Util::Messaging::iprint("$txt\n");

my @macro_file = read_file("$txt");



run_system_cmd ("rm -rf LVF_REPORT; mkdir LVF_REPORT", "$VERBOSITY");
run_system_cmd ("rm -rf pvt", "$VERBOSITY");
#sleep 2;
#run_system_cmd ("touch LVF_REPORT/missing_ocv.txt LVF_REPORT/missing_ocv_pg.txt");

run_system_cmd ("touch LVF_REPORT/pass_rate.txt LVF_REPORT/pass_rate_pg.txt", "$VERBOSITY");

push @missing_ocv,  "Cell name,pin/related_pin,when,timing_type,Group/Attribute,lib#1,line_num1,line_num2\n";
push @missing_pg_ocv,  "Cell name,pin/related_pin,when,timing_type,Group/Attribute,lib#1,line_num1,line_num2\n";


foreach my $macro (@macro_file) {
	Util::Messaging::iprint("$macro\n");
	push @log,  "$macro\n";
	run_system_cmd ("ls $macro/lib/*.lib | cut -d '.' -f1 | rev | cut -d '_' -f1 | rev > LVF_REPORT/pvt", "$VERBOSITY"); 
	my @FR1 = read_file("LVF_REPORT/pvt");
	push @missing_ocv,  "Details for macro $macro:\n" if($macro =~ /merge/);
	push @missing_pg_ocv,  "Details for macro $macro:\n" if($macro =~ /merge/);
	@mismatched_details = ();
	@mismatched_pg_details = ();
	push @mismatched_transistor_etm,  "Details of macro $macro:\n"if($macro !~ /merge/) ;
	push @mismatched_transistor_internal,  "Details of macro $macro:\n"if($macro !~ /merge/) ;
	foreach my $p (@FR1) {
    	chomp ($p);
		if ($macro =~ /merge/) {
###########################################################ocv################################################################################################
			
    		push @missing_ocv,  "$p\n";
			push @missing_pg_ocv,  "$p\n";
			@mismatched_details = run_system_cmd ("cat $macro/lib/libEdit/\*_mismatched.csv | egrep -v 'min_pulse_width|rise_tran|fall_tran|Cell name\,pin\/related_pin|List of timing arcs mismatched' ", "$VERBOSITY");
			if (@mismatched_details = "") {
				push @missing_ocv,  "Info: No missing ocv.\n";
			} else {
				push @missing_ocv,  "Error: missing ocv details:\n";
				push @missing_ocv,  "@mismatched_details";
			}

			@mismatched_pg_details = run_system_cmd ("cat $macro/lib_pg/libEdit/\*_mismatched.csv | egrep -v 'min_pulse_width|rise_tran|fall_tran|Cell name\,pin\/related_pin|List of timing arcs mismatched' ", "$VERBOSITY");
			if (@mismatched_pg_details = "") {
				push @missing_pg_ocv,  "Info: No missing ocv.\n";
			} else {
				push @missing_pg_ocv,  "Error: missing ocv details:\n";
				push @missing_pg_ocv,  "@mismatched_pg_details";
			}
###########################################################ocv################################################################################################

###########################################################mismatched_transistor################################################################################################
       	    		
		} else {
			
			if(-d "$macro/timing/Run_${p}_etm") {
				if(-e "$macro/timing/Run_${p}_etm/variation.rpt" ) {
					push @mismatched_transistor_etm,  "$p\n";
					@mismatched_transistor_etm =  `sed -n '/Unmatched /,/1/p' $macro/timing/Run_${p}_etm/variation.rpt | grep -v 'Unmatched' | awk '{print \$2}' | grep -v '-' | grep -v 'modelname' | grep -v '\\.'`;
					chomp @mismatched_transistor_etm;
					if(@mismatched_transistor_etm eq "") {
						push @mismatched_transistor_etm,  "Info: No mismatched transistor found.\n";
					} else {
						push @mismatched_transistor_etm,  "Error: mismatched transistor: @mismatched_transistor_etm\n";
					}
				} else {
					Util::Messaging::eprint("Error: $macro/timing/Run_${p}_etm/variation.rpt not created.\n");
					push @mismatched_transistor_etm,  "Error: $p: variation.rpt not created.Skipping check\n";
					push @log,  "Error: $macro/timing/Run_${p}_etm/variation.rpt not created.\n";
				} 
			} else {
				Util::Messaging::eprint("Error: $macro/timing/Run_${p}_etm directory does not exist.\n");
				push @log,  "Error: $macro/timing/Run_${p}_etm directory does not exist.\n";
			}
			
			if(-d "$macro/timing/Run_${p}_internal") {
				if(-e "$macro/timing/Run_${p}_internal/variation.rpt" ) {
					push @mismatched_transistor_internal,  "$p:\n";
    				@mismatched_transistor_internal =  run_system_cmd ("sed -n '/Unmatched /,/1/p' $macro/timing/Run_${p}_internal/variation.rpt | grep -v 'Unmatched' | awk '{print \$2}' | grep -v '-' | grep -v 'modelname' ", "$VERBOSITY");
					if(@mismatched_transistor_internal eq "") {
						push @mismatched_transistor_internal,  "Info: No mismatched transistor found.\n";
					} else {
						push @mismatched_transistor_internal,  "Error: mismatched transistor: @mismatched_transistor_internal\n";
					}
				} else {
					Util::Messaging::eprint("Error: $macro/timing/Run_${p}_internal/variation.rpt not created.\n");
					push @mismatched_transistor_internal,  "Error: $p: variation.rpt not created.Skipping check\n";
					push @log,  "Error: $macro/timing/Run_${p}_internal/variation.rpt not created.\n";
				}
			} else {
				Util::Messaging::eprint("Error: $macro/timing/Run_${p}_internal directory does not exist.\n");
				push @mismatched_transistor_internal,  "Error: $macro/timing/Run_${p}_internal directory does not exist.skipping check\n";
				push @log,  "Error: $macro/timing/Run_${p}_internal directory does not exist.\n";
			}
		}
	}
	push @mismatched_transistor_etm,  "\n";
	push @mismatched_transistor_internal,  "\n";
###########################################################mismatched_transistor################################################################################################

#################################################################pass rate################################################################################################
	my @FR2 = read_file("LVF_REPORT/pvt");
	run_system_cmd ("echo '$macro:' >> LVF_REPORT/pass_rate.txt", "$VERBOSITY") if ($macro =~ /merge/); 
	run_system_cmd ("echo '$macro:' >> LVF_REPORT/pass_rate_pg.txt", "$VERBOSITY") if ($macro =~ /merge/);
	foreach my $p (@FR2) {
		chomp ($p);
		if ($macro =~ /merge/) {
		run_system_cmd ("echo '$p:' >> LVF_REPORT/pass_rate.txt", "$VERBOSITY");
		run_system_cmd ("echo '$p:' >> LVF_REPORT/pass_rate_pg.txt", "$VERBOSITY");
		run_system_cmd ("cat $macro/lib/libEdit/*${p}*summary.csv* | grep -i 'pass rate' | egrep 'LVF|Cell' >> LVF_REPORT/pass_rate.txt", "$VERBOSITY");
		run_system_cmd ("cat $macro/lib_pg/libEdit/*${p}*summary.csv* | grep -i 'pass rate' | egrep 'LVF|Cell' >> LVF_REPORT/pass_rate_pg.txt", "$VERBOSITY");
		}
	}			
#	run_system_cmd ("rm -rf LVF_REPORT/pvt");
}
#################################################################pass rate################################################################################################

} else {
$macro = $ARGV[1];

chomp ($macro);

#$tool = $ARGV[2];

run_system_cmd ("cd $path/$macro", "$VERBOSITY");

run_system_cmd ("rm -rf LVF_REPORT; mkdir LVF_REPORT", "$VERBOSITY");


run_system_cmd ("rm -rf pvt", "$VERBOSITY");
run_system_cmd ("ls lib/*.lib | cut -d '.' -f1 | rev | cut -d '_' -f1 | rev > LVF_REPORT/pvt", "$VERBOSITY");
my @FR3 = read_file("LVF_REPORT/pvt");

if ($tool eq "sis")
{
  run_system_cmd ("echo 'Cell name,pin/related_pin,when,timing_type,Group/Attribute,lib#1,line_num1,line_num2' > LVF_REPORT/missing_ocv.txt", "$VERBOSITY");
  run_system_cmd ("echo 'Cell name,pin/related_pin,when,timing_type,Group/Attribute,lib#1,line_num1,line_num2' > LVF_REPORT/missing_ocv_pg.txt", "$VERBOSITY");
  #open ($FR, "<LVF_REPORT/pvt");
  foreach my $p(@FR3)
  {
    chomp ($p);
    run_system_cmd ("echo '$p' >> LVF_REPORT/missing_ocv.txt", "$VERBOSITY");
    run_system_cmd ("echo '$p' >> LVF_REPORT/missing_ocv_pg.txt", "$VERBOSITY");
    run_system_cmd ("cat lib/${macro}*${p}*mismatched.csv | egrep -v 'min_pulse_width|Cell name\,pin\/related_pin|List of timing arcs mismatched' >> LVF_REPORT/missing_ocv.txt", "$VERBOSITY");
    run_system_cmd ("cat lib_pg/${macro}*${p}*mismatched.csv | egrep -v 'min_pulse_width|Cell name\,pin\/related_pin|List of timing arcs mismatched' >> LVF_REPORT/missing_ocv_pg.txt", "$VERBOSITY");
  }
}

elsif ($tool eq "nt")
{
  Util::Messaging::iprint("tool used is $tool\n");
  run_system_cmd ("echo 'Cell name,pin/related_pin,when,timing_type,Group/Attribute,lib#1,line_num1,line_num2' > LVF_REPORT/missing_ocv.txt", "$VERBOSITY");
  run_system_cmd ("echo 'Cell name,pin/related_pin,when,timing_type,Group/Attribute,lib#1,line_num1,line_num2' > LVF_REPORT/missing_ocv_pg.txt", "$VERBOSITY");
  run_system_cmd ("touch LVF_REPORT/mismatched_transistor_etm.txt LVF_REPORT/mismatched_transistor_internal.txt", "$VERBOSITY");

  foreach my $p(@FR3)
  {
    chomp ($p);
    run_system_cmd ("echo '$p' >> LVF_REPORT/missing_ocv.txt", "$VERBOSITY");
    run_system_cmd ("echo '$p' >> LVF_REPORT/missing_ocv_pg.txt", "$VERBOSITY");
    run_system_cmd ("echo '$p:' >> LVF_REPORT/mismatched_transistor_etm.txt", "$VERBOSITY");
    run_system_cmd ("echo '$p' >> LVF_REPORT/mismatched_transistor_internal.txt", "$VERBOSITY");
    run_system_cmd ("cat lib/${macro}*${p}*mismatched.csv | egrep -v 'min_pulse_width|rise_tran|fall_tran|Cell name\,pin\/related_pin|List of timing arcs mismatched' >> LVF_REPORT/missing_ocv.txt", "$VERBOSITY");
    run_system_cmd ("cat lib_pg/${macro}*${p}*mismatched.csv | egrep -v 'min_pulse_width|rise_tran|fall_tran|Cell name\,pin\/related_pin|List of timing arcs mismatched' >> LVF_REPORT/missing_ocv_pg.txt", "$VERBOSITY");
    run_system_cmd ("sed -n '/Unmatched /,\$p' timing/Run_${p}_etm/variation.rpt | grep -v 'Unmatched' | awk '{print \$2}' | grep -v '-' | grep -v 'modelname' | grep -v 'min' | grep -v 'max' | grep -v '^\$' | sort -u >> LVF_REPORT/mismatched_transistor_etm.txt", "$VERBOSITY");
    run_system_cmd ("sed -n '/Unmatched /,\$p' timing/Run_${p}_internal/variation.rpt | grep -v 'Unmatched' | awk '{print \$2}' | grep -v '-' | grep -v 'modelname' | grep -v 'min' | grep -v 'max' | grep -v '^\$' | sort -u >> LVF_REPORT/mismatched_transistor_internal.txt", "$VERBOSITY");
    run_system_cmd ("echo '\n' >> LVF_REPORT/mismatched_transistor_etm.txt", "$VERBOSITY");
    run_system_cmd ("echo '\n' >> LVF_REPORT/mismatched_transistor_internal.txt", "$VERBOSITY");
  }
}




run_system_cmd ("touch LVF_REPORT/pass_rate.txt LVF_REPORT/pass_rate_pg.txt", "$VERBOSITY");

foreach my $p (@FR3)
{
  chomp ($p);
  run_system_cmd ("echo '$p' >> LVF_REPORT/pass_rate.txt", "$VERBOSITY");
  run_system_cmd ("echo '$p' >> LVF_REPORT/pass_rate_pg.txt", "$VERBOSITY");
  run_system_cmd ("cat lib/${macro}*${p}*summary.csv* | grep -i 'pass rate' | egrep 'LVF|Cell' | grep -v '100\%' >> LVF_REPORT/pass_rate.txt", "$VERBOSITY");
  run_system_cmd ("cat lib_pg/${macro}*${p}*summary.csv* | grep -i 'pass rate' | egrep 'LVF|Cell' | grep -v '100\%' >> LVF_REPORT/pass_rate_pg.txt", "$VERBOSITY");
}  


run_system_cmd ("rm -rf LVF_REPORT/pvt", "$VERBOSITY");
}

    my $Wstatus1 = write_file(\@log,"lcdl_lvf_qa.log");
	
	my $Wstatus2 = write_file(\@missing_ocv,"./LVF_REPORT/missing_ocv.txt");

    my $Wstatus3 = write_file(\@missing_pg_ocv,"./LVF_REPORT/missing_ocv_pg.txt");

    my $Wstatus4 = write_file(\@mismatched_transistor_etm,"./LVF_REPORT/mismatched_transistor_etm.txt");

    my $Wstatus5 = write_file(\@mismatched_transistor_internal,"./LVF_REPORT/mismatched_transistor_internal.txt");
}
