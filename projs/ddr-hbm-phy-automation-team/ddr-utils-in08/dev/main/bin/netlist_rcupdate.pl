#!/depot/perl-5.14.2/bin/perl
##
## Created by Anil Saini, 2021-11-04
## To update the cap/res in post-layout netlist 
## Provide the net name and cap/res mutiplication factor in run file
## This script will multiple the R and C with provided multiplication factor for given nets. 

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Path;
use Cwd;


use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../lib/perl/";
use Util::Misc;

our $LOG_INFO = 0;
our $LOG_WARNING =  1;
our $LOG_ERROR = 2;
our $LOG_FATAL = 3;
our $LOG_RAW = 4;

our $PROGRAM_NAME = $RealScript;
our $VERSION      = get_release_version();
our $DEBUG        = 0;
our $VERBOSITY    = 0;

utils__script_usage_statistics( $PROGRAM_NAME, $VERSION);

sub usage {
    print << "EOP" ;
.......................................................................................................................................
Description	: A script to update the R and C for specific nets. Provide the cap/res mutiplication factor for each net in run file.

USAGE		: netlist_rcupdate.pl <run file> <spf file>

Example		: netlist_rcupdate.pl run_file dwc_lpddr5xphy_rxac_ew_rcc_typical_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z.spf
output  	: dwc_lpddr5xphy_rxac_ew_rcc_typical_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_update.spf

Run file format- 
nets:XIafe.XIodd.innp:scan_mode
cap_mult:0.5:0.2
res_mult:0.4:0.6

command line options:
-help             print this screen
-h                print this screen
.......................................................................................................................................
EOP
exit ;
}

# Get options
my $opt_help='';
GetOptions("help|h"	  => \$opt_help,
		  );
&usage if ( $opt_help );	  
#########################
if ($#ARGV < 1){
	print  "NETLIST_EDITOR>>\tNeed atleast two arguments \nNETLIST_EDITOR>>\tPlease provide runfile followed by spf file\n\n";
	exit
}

my $run_file=shift;
my $spf_file=shift;
chomp($run_file);chomp($spf_file);

sub Main {
	
	my @nets=''; my @cap_mult=''; my @res_mult='';
	my $net=''; my $line=''; my @column_cap=''; my @column_res='';
	my $update_cap='';my $update_res=''; my $column_res4 = '';

	my @run_file_arr = read_file($run_file);

	foreach my $line (@run_file_arr){       
		$line=~ s/\n$//g;
		$line=~ s/^\s*//g;
		if($line=~m /nets/gi ){
			@nets=split(":",$line) ;
			shift(@nets);
		}
		if($line =~m /cap_mult/gi ){
	    	@cap_mult=split(":",$line) ;
			shift(@cap_mult);
		}
		if($line =~m /res_mult/gi ){
	   		@res_mult=split(":",$line) ;
			shift(@res_mult);
		}
	}

	print "Enter the value corresponds to technology : 0 for Intel ; 1 for Other and press enter => ";
	my $tech = <STDIN>;

	my $filename = basename($spf_file);
	$filename =~s/(.*).spf(.*)$/$1/;
	my $updated_spf="$filename\_update.spf" ;
	system "rm -rf $updated_spf";

	my $index="";my $index_net='';my $index_orig='';my $flag_net=0; my @nets_orig=@nets;

	##########################################################################################################
	my @data_array = ();
	my @spf_file_array =  read_file($spf_file);
	foreach my $line (@spf_file_array){
		if ($line =~m/\|NET/){
			push(@data_array, "$line\n");
			$line =~s/(.*)(NET)(\s)(.*)(\s)(.*)/$4/;
			if (grep { /$line/ } @nets){
				($index) = grep { $nets[$_] eq $line } (0 .. @nets-1);
				($index_orig) = grep { $nets_orig[$_] eq $line } (0 .. @nets_orig-1);
				$flag_net=1 ;
				$index_net=$index;
				$index='';
				splice @nets,$index_net,1;
			}
			else{
			$flag_net=0 ;
			}
		}
		elsif ($line =~m/Instance Section/){
			$flag_net=0;
			push(@data_array, "$line\n");
		}
		elsif (($line =~m/^C/)&&($flag_net==1)){
			@column_cap = (split / /,$line,4);
			$update_cap=$column_cap[3]*$cap_mult[$index_orig]; 
			push (@data_array, "$column_cap[0] $column_cap[1] $column_cap[2] $update_cap\n");
			@column_cap='';
		}
		elsif (($line =~m/^R/)&&($flag_net==1)){
			if ($tech==0){
				@column_res = (split / /,$line,4);
				$update_res=$column_res[3]*$res_mult[$index_orig]; 
				push (@data_array, "$column_res[0] $column_res[1] $column_res[2] $update_res\n");
				@column_res='';
			}
			else{
				@column_res = (split / /,$line,7);
				if(exists($column_res[4])&&($column_res[4]=~m/(R=)/)){
					$column_res4 = $column_res[4];
					$column_res4 =~s/(R=)(.*)/$2/;
					$update_res=$column_res4*$res_mult[$index_orig];
					if ((exists($column_res[5]))&&(exists($column_res[6]))){
						push (@data_array, "$column_res[0] $column_res[1] $column_res[2] $column_res[3] R=$update_res $column_res[5] $column_res[6]\n");
					}
					else{
						push (@data_array, "$column_res[0] $column_res[1] $column_res[2] $column_res[3] R=$update_res\n");
					}
				}
				else{
					push (@data_array, "$line\n");
				}
				@column_res='';
				$column_res4 = '';
			}
		}	
		else{
			push (@data_array, "$line\n");
		}		
	}	
	write_file(\@data_array, $updated_spf);

	print "Updated netlist : $updated_spf\n";
}
&Main();
