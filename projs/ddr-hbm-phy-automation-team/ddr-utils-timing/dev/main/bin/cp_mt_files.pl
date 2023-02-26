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
##------------------------------------------------------------------
##  Gather run statistics for the script
##     First argument is name of the script.
##     Second argument is the script version. (ie. 2022ww10)
##     Third argument (optional) is an aref, used
##          to capture the cmd line arguments and log them.
##------------------------------------------------------------------
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

#-------------------------
#  Constants
#-------------------------
our $LOG_INFO    = 0;
our $LOG_WARNING = 1;
our $LOG_ERROR   = 2;
our $LOG_FATAL   = 3;
our $LOG_RAW     = 4;
#-------------------------

my ($debug,$opt_help);

#-------------------------------------------------
sub Main {
    ## get specified args
    #my($success, $help);
    #$success = GetOptions("help!"             => \$help,

    ## quit with usage message, if usage not satisfied
    #&usage if ($success != 1);
    #&usage if ($#ARGV != 1);
    #&usage if $help;
    
    ($debug,$opt_help)
            = process_cmd_line_args();    

    if ( $opt_help ) {
        usage();
    }
    ## local vars
    my (@mtfiles, $file, $filename, %data, $mos, $vddval, $temp, $corner, $prefix);
    my ($target_folder, $target_file, $target_path);
    my @testbench = qw(tb_ddrphy_bdl_dlyin_table_post 
      tb_ddrphy_bdl_pinCap_post tb_ddrphy_bdl_pwr_post);
    my @testbench2 = qw(tb_ddrphy_bdl_dlyin_swp_post tb_ddrphy_bdl_dti_swp_post);
    my $total_swp = 64;
    ## welcome
    iprint ("Collecting .mt* data to each corner folder ...\n");

    ## find .mt* files

    if (@mtfiles = glob("$ARGV[0]/*/*.mt*")) {
         nprint (" Reading ".($#mtfiles+1)." .mt* files...\n");
    }
    else{
         eprint (" ERROR: Found none .mt* files in $ARGV[0]\n");
         exit 1;
    }

    $target_folder = $ARGV[1];

    ## loop through each mt file
    foreach my $file (sort (@mtfiles)) {
        ## grab file basename
        $filename = basename($file);
        ## grab corner number of filenmae
        if ($filename =~ /^(.*).mt(\d*)$/) {
            $data{$file}->{'filename'}  = basename($file);
            $data{$file}->{'prefix'}    = $1;
            $data{$file}->{'cornernum'} = $2;
            ## open file
            foreach my $line ( read_file($file) ){
                if( $line =~ m/^.TITLE ''(.*)''/) {
                    my $title = $1;
                    if( $title =~ m/\s+moslvt_(\S+)\s+.*\s+/ ){
                        $mos = $1;
                         #if ($mos !~/g/){
                        # $mos = $1.g;
                        # print "$mos\n";
                        # }
                    }
                    if( $title =~ m/\s+([01]\d*).([0-9]\d*)\s+[01]\d*.[0-9]\d*\s+(-?)([0-9]\d*)/ ){
                        $vddval = "$1p$2v";
                         if( $3 eq '-' ){
                             $temp = "n$4c";
                         }
                         else{
                             $temp = "$4c";
                         }
                    }
                    $corner = "${mos}${vddval}${temp}";
               }
            }  # END foreach $line
        }  # END if $filename
        foreach my $tb (sort (@testbench)) {
            if ($data{$file}->{'prefix'} eq $tb){
                $target_file = "$target_folder$corner/$data{$file}->{prefix}.mt0";
                $target_path = "$target_folder$corner";
                nprint ("copy $file to $target_file\n");

                ## copy files from data folder to target folder
                my $cmd = "mkdir -p $target_path && cp $file $target_file";
                my ($stdout,$stderr) = run_system_cmd("$cmd","$VERBOSITY");
            }
        }  # END foreach my $tb
        foreach my $tb2 (sort (@testbench2)){
            if ($data{$file}->{'prefix'} eq $tb2){
                my $swpround = int($data{$file}->{'cornernum'}/$total_swp);
                my $target_cornernum = $data{$file}->{'cornernum'} - $swpround*$total_swp;
                $target_file = "$target_folder$corner/$data{$file}->{prefix}.mt$target_cornernum";
                $target_path = "$target_folder$corner";
                nprint ("copy $file to $target_file\n");
          
                ## copy files from data folder to target folder
                my $cmd2 = "mkdir -p $target_path && cp $file $target_file";
                my ($stdout1,$stderr1) = run_system_cmd("$cmd2","$VERBOSITY");
            }
        }  # END foreach my $tb2
    }  # END  foreach my $file 

    ## create soft link to sss folder
    my $cmd = "ln -sf $corner $target_folder/sss";
    nprint ("$cmd");
    my ($stdout2,$stderr2) = run_system_cmd("$cmd","$VERBOSITY");
    iprint ("\n ALL DONE... \n");
}  ## END MAIN


#-------------------------------------------------
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

#-------------------------------------------------
sub usage($) {
my $exit_status = shift || '0';
    my $USAGE = <<EOusage;

Description
  A script to collect csv files into one final csv file for T7tc only.

  Note: this script will overwrite output files with each run

USAGE : collect_csv [options] <dir where .mt* files sit>

command line options:
-help             print this screen

Assumptions:
- output file (csv file) will use the same file basename as .mt* files. 
EOusage

    nprint ("$USAGE");
    exit($exit_status);    
}

