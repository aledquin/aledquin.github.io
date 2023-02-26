#!/depot/perl-5.14.2/bin/perl
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

#####################################################################################################################################################################
                                   							    	    #
#                                                                                                							            #
# Description: Evaluates and groups timing.log warnings for both etm and internal NT runs             							            #
#                                                                                                						            	    #
# Developer: Vache Galstyan (Synopsys Armenia, SG) 	                                         							    	    #
# Email:     vache@synopsys.com                                                                  							    	    #
#                                                                                                							    	    #
# Rev History   :                                                                                  							            #            
#  Version        |     Date    |    Who   |            What                                            							            #          
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------  #                    
#   1.0           | 15 Nov 2016 |   vache  |        - Initial Release.						                                                    #                    
#   1.0_patch1    | 17 Jan 2017 |   vache  |        - Added separate summarize functionality for DELC-109 warnings.                                                 #                    
#                                                   - Warnings are separated as folows:        									    #
#                                                   - load maximum violations ( reports warning with maximum mismatch per arc )					    #
#                                                   - load minimum violations ( reports warning with maximum mismatch per arc )					    #
#                                                   - slope maximum violations ( reports warning with maximum mismatch per arc )				    #
#                                                   - slope minimum violations ( reports warning with maximum mismatch per arc )				    #
#                                                   - Added load_limit and slope_limit arguments to specify threshold for DELC-109 warnings.      		    #
#						    - Reports only uniq warnings per warning code for each corner ( Despite DELC-109 ).      			    #
#   1.1           | 29 oct 2022 |  juliano |        - Clean-up lint errs, minor formatting changes.
#                                                 											   			    #
#####################################################################################################################################################################                            

use Data::Dumper;
use Getopt::Long;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

#my $result = GetOptions(
#		     "h" => \$help,
#		     "help" => \$help
#		     );

#if ($help) {ShowUsage();}

#sub ShowUsage {
#    print "-I- Script used to check xtalk\n";
#    exit;
#}

my ($debug,$opt_help);

sub Main {

($debug,$opt_help)
            = process_cmd_line_args();    

    if ( $opt_help ) {
        usage();
    }
    
my $xtalk_criteria = $ARGV[0]; 
## xtalk ratio to delay "xtalk/delay" 
## Timing arcs are flagged when the ratio exceeds the specified value

my $xrate_criteria = $ARGV[1];
## Transition time thershold, Unit is ns, 
## Timing arcs are flagged when the transition exceeds the specified value


my $inputFilesDir = $ARGV[2];

my $output_dir = $ARGV[3];
my @inputFilesList = run_system_cmd("ls $inputFilesDir/*/*.paths",$VERBOSITY);

my $block_name = $ARGV[4];

my %inputFiles = "";

foreach my $files (@inputFilesList) {
#map {&abs_path("$files") => 1,} 
chomp $files; 
my $abs_path = &abs_path($files);
if(!(-e &abs_path($files))) {
    #eprint ("\e[31mError:\e[0m The file \"",&abs_path($files),"\" doesn't exist\n");
	
    eprint ("Error:The file \",$abs_path,\" doesn't exist\n");
} else {
    $inputFiles{$abs_path} = 1;
}

}
my %fdb;
foreach my $paths_file (keys %inputFiles){
	my $corner_name = $paths_file;
	$corner_name =~s/\S+\/(\S+)\/\S+?$/$1/;
	my $item      = undef;
	my $pathId    = undef;
	my $startpoint= undef;
	my $endpoint  = undef;
	my $pathType  = undef;
	$fdb{$paths_file}{"corner"} = $corner_name;

  my @lines = read_file( $paths_file );
  foreach my $currentLine ( @lines ){
		if($currentLine =~ m/^Item:\s+(\d+)/){
			$item = $1;
		} elsif($currentLine =~ m/^Path\s+ID:\s+(\d+)/){
			$pathId = $1;
		} elsif($currentLine =~ m/^Startpoint:\s+(.*)/){
			$startpoint = $1;
		} elsif($currentLine =~ m/^Endpoint:\s+(.*)/){
			$endpoint = $1;
		} elsif($currentLine =~ m/^Path\s+Type:\s+(.*)/){
			$pathType = $1;
		}
		my @timing_path_lines = ();
		if((defined $item) && (defined $pathId) && (defined $startpoint) && (defined $endpoint) && (defined $pathType)) {
			  $fdb{$paths_file}{$pathId}{"item"}       = $item;
			  $fdb{$paths_file}{$pathId}{"startpoint"} = $startpoint;
			  $fdb{$paths_file}{$pathId}{"endpoint"}   = $endpoint;
			  $fdb{$paths_file}{$pathId}{"pathType"}   = $pathType;
			
			  $item = undef;
        foreach my $inTimingPath ( @lines ){
				    if($inTimingPath =~/^Item:\s+(\d+)/){
					    $item = $1;
					    last;
				    }
				    push (@timing_path_lines,$inTimingPath);
			  }
		
		}
		my $numOfPaths = 0;
		my $totalDelay = undef;
		my $totalXtalk = undef;
		my @paths_data = ();
		my $i = 0;
		my @line_split = ();
		foreach my $path_line ( @timing_path_lines ){
			my $path         = undef;	  		  
			my $incr         = undef;
			my $wireDelay    = undef;
			my $coeffAdj     = undef;
			my $coeffRatio   = undef;
			my $xtalkDelta   = undef;
			my $trans        = undef;
			my $fTrans       = undef;
			my $railVoltage  = undef;
			my $finalVoltage = undef;
			my $cap          = undef;
			my $nt           = undef;
			my $pointNet     = undef; 
			
			if( $path_line =~ m/^--/ ){
				next;
			}
			
			if($path_line =~ /^\s*Path\s+Incr/){
				my $path_line_space = $path_line;
				$path_line_space=~s/Adjust//;
				$path_line_space=~s/\s+/ /;
				$path_line_space=~s/^\s+//;

				$path_line_space=~s/\s+$//;
				@line_split = split(" ",$path_line_space);
				next;
				
			}
			my $path_line_values = $path_line;
			$path_line_values=~s/\s+/ /;
			$path_line_values=~s/^\s+//;

			$path_line_values=~s/\s+$//;
			my @line_split_values = split(" ",$path_line_values);
			
			for(my $i = 0; $i < scalar(@line_split); $i++){
				if(defined $line_split_values[$i]){
					if($line_split[$i] =~/Path/){
						$path = $line_split_values[$i];
					} elsif($line_split[$i] =~/Incr/){
						$incr = $line_split_values[$i];
					} elsif($line_split[$i] =~/Delay/){
						$wireDelay = $line_split_values[$i];
					} elsif($line_split[$i] =~/adj/){
						$coeffAdj = $line_split_values[$i];
					} elsif($line_split[$i] =~/ratio/){
						$coeffRatio = $line_split_values[$i];
					} elsif($line_split[$i] =~/Delta/){
						$xtalkDelta = $line_split_values[$i];
					} elsif($line_split[$i] =~/\bTrans/){
						$trans = $line_split_values[$i];
						
					} elsif($line_split[$i] =~/FTrans/){
						$fTrans = $line_split_values[$i];
					} elsif($line_split[$i] =~/Voltage/ && !(defined $railVoltage)){
						$railVoltage = $line_split_values[$i];
					} elsif($line_split[$i] =~/Voltage/){
						$finalVoltage = $line_split_values[$i];
					} elsif($line_split[$i] =~/Cap/){
						$cap = $line_split_values[$i];
					} elsif($line_split[$i] =~/NT/){
						$nt = $line_split_values[$i];
					}
				
				}
				if(defined $nt){
					my $pointNetInt = '';
					
					for(my $j = $i+1; $j < scalar(@line_split_values); $j++){
						$pointNetInt =$pointNetInt. " ". $line_split_values[$j];
					}
#					print $pointNet, "\n";
					
					$pointNet = $pointNetInt;
				}
				
			
			}
			
			if((defined $path ) && (defined $incr ) && (defined $wireDelay ) && (defined $coeffAdj ) && (defined $xtalkDelta ) && (defined $trans ) && (defined $fTrans ) && (defined $railVoltage ) && (defined $finalVoltage ) && (defined $cap ) && (defined $nt ) && (defined $pointNet) ){
				$fdb{$paths_file}{$pathId}{"path"}[$i] =  $path;
				$fdb{$paths_file}{$pathId}{"incr"}[$i] =  $incr;
				$fdb{$paths_file}{$pathId}{"wireDelay"}[$i] =  $wireDelay;
				$fdb{$paths_file}{$pathId}{"coeffAdj"}[$i] =  $coeffAdj;
				#$fdb{$paths_file}{$pathId}{"coeffRatio"}[$i] =  $coeffRatio;
				$fdb{$paths_file}{$pathId}{"xtalkDelta"}[$i] =  $xtalkDelta;
				$fdb{$paths_file}{$pathId}{"trans"}[$i] =  $trans;
				
				$fdb{$paths_file}{$pathId}{"fTrans"}[$i] =  $fTrans;
				$fdb{$paths_file}{$pathId}{"railVoltage"}[$i] =  $railVoltage;
				$fdb{$paths_file}{$pathId}{"finalVoltage"}[$i] =  $finalVoltage;
				$fdb{$paths_file}{$pathId}{"cap"}[$i] =  $cap;
				$fdb{$paths_file}{$pathId}{"nt"}[$i] =  $nt;
				
				$pointNet=~s/\,/ /g;
				$fdb{$paths_file}{$pathId}{"pointNet"}[$i] =  $pointNet;
				
				$i++;
				$path		     = undef;
				$incr		     = undef;
				$wireDelay	     = undef;
				$coeffAdj	     = undef;
				$coeffRatio	     = undef;
				$xtalkDelta	     = undef;
				$trans  	     = undef;
				$fTrans 	     = undef;
				$railVoltage	     = undef;
				$finalVoltage	     = undef;
				$cap		     = undef;
				$nt		     = undef;
				$pointNet	     = undef;
				
				
			}
			if($path_line =~ /(\S+)\s+\S+\s+(\S+)\s+Total\s*$/){
				$totalDelay = $1;
				$totalXtalk = $2;
				my $xtalkProp;
				if($totalXtalk > 1){  ##Setting delay threshold of 1ps
				
					if($totalDelay-$totalXtalk != 0){
						#$xtalkProp = $totalXtalk/($totalDelay-$totalXtalk);
						$xtalkProp = ($totalXtalk/$totalDelay)*100;
					} else {
						$xtalkProp = 100;
					}
				#print "$xtalkProp \n";
					$fdb{$paths_file}{$pathId}{"xtalkProp"}[$numOfPaths] = $xtalkProp;
					$fdb{$paths_file}{$pathId}{"totalxtalk"}[$numOfPaths] = $totalXtalk;
					$fdb{$paths_file}{$pathId}{"totaldelay"}[$numOfPaths] = $totalDelay;
					$numOfPaths++;
				}
				else {
					$xtalkProp = 0;
				}
			}
					
		}
		if((defined $pathId) && (defined $startpoint) && (defined $endpoint) && (defined $pathType)) {
	       	        $pathId = undef;
	       	        $startpoint = undef;
       		        $endpoint = undef;
       	        	$pathType = undef;

		}

	}  ## END  foreach my $currentLine 
}



my $violated_xrate_count = 0;
my $violated_xtalk_count = 0;
my ($XRATE,$XTALK) = "";
#open($XRATE, ">",$output_dir/${block_name}_violated_internal_transition_report.csv") || die "Error: Can't create violated_xrate_report.csv file $!\n";
#open($XTALK, ">",$output_dir/${block_name}_violated_xtalk_report.csv") || die "Error: Can't create violated_xtalk_report.csv file $!\n";

#print $XTALK "Corner,Path ID, Startpoint, Endpoint,Total xtalk, Total delay, xtalk/(delay-xtalk)\n";
#print $XRATE "Corner,Path ID, Startpoint, Endpoint,Transition, PointNet\n";

my $XTALK1 = write_file("Corner,Path ID, Startpoint, Endpoint,Total xtalk, Total delay, xtalk/(delay-xtalk)\n", "$output_dir/${block_name}_violated_internal_transition_report.csv");

my $XRATE1 = write_file("Corner,Path ID, Startpoint, Endpoint,Transition, PointNet\n","$output_dir/${block_name}_violated_internal_transition_report.csv");

foreach my $key_file (keys %fdb) {
	
	my $corner = $fdb{$key_file}{"corner"};
	foreach my $key_id (keys %{$fdb{$key_file}}){
		if($key_id eq "corner"){
			next;
		}
		my $j=0;
		foreach my $trans (@{$fdb{$key_file}{$key_id}{"trans"}}){
			
			if($trans >= $xrate_criteria){
				#print "$corner    trans = $trans, on path $key_id", "\n";
				#print $XRATE "$corner,$key_id,$fdb{$key_file}{$key_id}{\"startpoint\"},$fdb{$key_file}{$key_id}{\"endpoint\"},$trans,${$fdb{$key_file}{$key_id}{\"pointNet\"}}[$j]\n";
				my  $XRATE2 =  write_file("$corner,$key_id,$fdb{$key_file}{$key_id}{\"startpoint\"},$fdb{$key_file}{$key_id}{\"endpoint\"},$trans,${$fdb{$key_file}{$key_id}{\"pointNet\"}}[$j]\n","$output_dir/${block_name}_violated_internal_transition_report.csv",">");
				$j++;
				$violated_xrate_count++;
			}
		}
		my $i = 0;
		foreach my $xtalk_prop (@{$fdb{$key_file}{$key_id}{"xtalkProp"}}){
			#print "$xtalk_prop\n";
			if(abs($xtalk_prop) >= $xtalk_criteria){
				#print $XTALK "$corner,$key_id,$fdb{$key_file}{$key_id}{\"startpoint\"},$fdb{$key_file}{$key_id}{\"endpoint\"},${$fdb{$key_file}{$key_id}{\"totalxtalk\"}}[$i],${$fdb{$key_file}{$key_id}{\"totaldelay\"}}[$i],$xtalk_prop\n";
				my $XTALK2 =  write_file("$corner,$key_id,$fdb{$key_file}{$key_id}{\"startpoint\"},$fdb{$key_file}{$key_id}{\"endpoint\"},${$fdb{$key_file}{$key_id}{\"totalxtalk\"}}[$i],${$fdb{$key_file}{$key_id}{\"totaldelay\"}}[$i],$xtalk_prop\n","$output_dir/${block_name}_violated_internal_transition_report.csv",">");
				#print $xtalk_prop," \" $key_id \" \n";
				$violated_xtalk_count++;
			}
			$i++;
		}
	}
}

if($violated_xrate_count == 0) {
	my $XRATE3 =  write_file("No violations found\n","$output_dir/${block_name}_violated_internal_transition_report.csv",">");
}

if($violated_xtalk_count == 0) {
	my $XTALK3 = write_file("No violations found\n","$output_dir/${block_name}_violated_internal_transition_report.csv",">");
}

close $XTALK;
close $XRATE;

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

    Script used to check xtalk.
EOusage

    nprint ("$USAGE");
    exit($exit_status);    
}
