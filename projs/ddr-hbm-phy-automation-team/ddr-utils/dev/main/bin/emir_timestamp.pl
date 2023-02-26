#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use Cwd;
use Getopt::Long;
use File::Basename;
use File::Copy;
use File::Basename;
use Cwd 'abs_path';
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = NONE;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';

##  Constants
our $LOG_INFO = 0;
our $LOG_WARNING = 1;
our $LOG_ERROR = 2;
our $LOG_FATAL = 3;
our $LOG_RAW = 4;
#--------------------------------------------------------------------#
BEGIN {
    our $AUTHOR='DDR DA WG';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
END {
    footer();
    write_stdout_log("$LOGFILENAME");
}



sub Main {
    $|=1;
    my $flag=0;
    utils__script_usage_statistics( $RealScript, $VERSION);
    my ($project, $inc, $runDir) = process_cmd_line_args();

    my @toks = split(/\//, $project);
    my $productName = $toks[0];
    my $projectName = $toks[1];
    my $projectRel = $toks[2];
    my $projectRelistcompareut = substr $projectRel,3;
    iprint ("##############################################################################################\n");
    iprint ("productName = $productName\nprojectName =$projectName\nprojectRel = $projectRel\n");
    iprint ("##############################################################################################\n\n");

    #############################################gz######################################################
    #print "$inc\n";
#    open($gz,"<","$inc") or die "Could not open file $!";
    my @bbsimlines = Util::Misc::read_file("$inc");
	my ($incfile, $block, $sp_inc , $INCLUDE, $datfile, $icc_raw_file, $gzfilename) = "";
    foreach my $findgzfile (@bbsimlines) {
    	chomp $findgzfile;
    	if ($findgzfile =~ /^GDS\s+(.*)/){
    		$incfile = $1;
    	}
    	if ($findgzfile =~ /^BLOCK\s+(.*)/){
    		$block = $1;
    	}
    	if ($findgzfile =~ /^SPICE_COMMAND_FILE\s+(.*)/){
    		$sp_inc = $1;
    	}
    	if ($findgzfile =~ /^INCLUDE\s+all\s+(.*)/){
    		$INCLUDE = $1;
    	}
    }


    #my @p4check = `p4 print //wwcad/msip/projects/$productName/$projectName/latest/design/sim/$block/circuit/$sp_inc`;
	my $p4check = Util::P4::print_p4_file("//wwcad/msip/projects/$productName/$projectName/latest/design/sim/$block/circuit/$sp_inc");
	my @p4check = split("\n",$p4check);

    foreach my $findatfile (@p4check) {
    	if($findatfile =~ /^\.include '(.*)'/) {
    #		$datfile =~ s/\.include //;
    		$datfile = $1;
    	}
    }
    #print "$datfile\n";
    #my @findfile_icc_raw = `p4 print //wwcad/msip/projects/$productName/$projectName/latest/design/sim/$block/circuit/project/${datfile}`;
	my $findfile_icc_raw = Util::P4::print_p4_file("//wwcad/msip/projects/$productName/$projectName/latest/design/sim/$block/circuit/project/${datfile}");
    if ($findfile_icc_raw =~ /^\.include '(.*)'/) {
    	$icc_raw_file = $1 ;
    #	print "$icc_raw_file\n";
    }

    #my $temp_iccraw_file = "/remote/us01home57/snehar/design/sim_datecheck/dwc_lpddr5xmphy_lstx_acx2_ew_ideal_RCc.raw";
    my $timeoficcraw = localtime((stat($icc_raw_file))[9]);
    my ($ftimeoficcraw, $stdval1) =  run_system_cmd("echo $timeoficcraw | cut -d ' ' -f2,3", $VERBOSITY);
    #my $timeoficcraw = -C $temp_timeoficcraw;
    iprint("Info: ${datfile} file timestamp is $ftimeoficcraw\n");


    ########################################inc########################################
    #my @p4incfile = `p4 print //wwcad/msip/projects/$project/design/sim/$block/include/$INCLUDE`;
	my $p4incfile = Util::P4::print_p4_file("//wwcad/msip/projects/$project/design/sim/$block/include/$INCLUDE");
	my @p4incfile = split("\n", $p4incfile);
    foreach my $findatfile_inc (@p4incfile) {
    	if($findatfile_inc =~ /-file (.*).gz/) {
    		$gzfilename = "$1.gz";

    #		$gzfilename = "/remote/us01home57/snehar/design/sim_datecheck/dwc_lpddr5xmphy_lstx_acx2_ew_rcc_typical_t105_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z.spf.gz";
    	}
    }
    my $statgzfilename = localtime((stat($gzfilename))[9]);
    my ($fstatgzfilename, $stdval2) = run_system_cmd("echo $statgzfilename | cut -d ' ' -f2,3", $VERBOSITY);
    iprint("Info: $block gz file inside sp file timestamp is $fstatgzfilename\n");

    ###############################
    my $incfile_stat = localtime((stat($incfile))[9]);
    my ($fincfile_stat, $stdval3) = run_system_cmd("echo $incfile_stat | cut -d ' ' -f2,3", $VERBOSITY);
    my @split_incfile = split/\//, $incfile;
    iprint("Info: $split_incfile[-1] file timestamp inside inc file is $fincfile_stat\n");

    if ($ftimeoficcraw eq $fstatgzfilename && $fstatgzfilename eq $fincfile_stat) {
    	iprint("Info: All three files have been generated on same day.\n");
    } else {
    	eprint("Error: Files stale\n");
    }


}



sub process_cmd_line_args(){
    my ($opt_help, $opt_dryrun, $opt_debug, $opt_verbosity, $project, $inc, $runDir);
    my $success = GetOptions(
                             "help"           => \$opt_help,
                             "project=s"      => \$project,
                             "inc=s"          => \$inc,
                             "runDir=s"       => \$runDir,
							 "debug=i"        => \$opt_debug,
							 "verbosity=i"    => \$opt_verbosity,
							 "dryrun!"        => \$opt_debug
							       
	); 

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    return ($project, $inc, $runDir); 
} 

sub usage($) {
    my $exit_status = shift || 0;
    iprint("Usage: <scriptName> -project <> -inc <>  - runDir\n");
    exit($exit_status);
}
