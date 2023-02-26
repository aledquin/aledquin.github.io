#!/depot/perl-5.14.2/bin/perl
###############################################################################
#
# Name    : alphaSummarizeNtWarnings.pl
# Author  : N/A
# Date    : N/A
# Purpose : N/A
#
# Modification History
# 			2022-05-26 12:38:49 => Adding Perl template. HSW.
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

use Data::Dumper;
use Getopt::Long;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

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
#                                                 											   			    #
#####################################################################################################################################################################                            


my $waivelist;
my $opt_help;
my $load_limit = 1;
my $slope_limit = 1;
my $debug;
# Get options
#GetOptions("help|h"	  => \$opt_help,
#	         "waive=s" 	 => \$waivelist,
#           "lth=s" => \$load_limit,
#           "sth=s" => \$slope_limit,
#	  );

#&usage if ( $opt_help );

sub Main() {
($debug,$waivelist,$load_limit,$slope_limit,$opt_help)
            = process_cmd_line_args();
	    
    
my %waives;
if ( defined $waivelist ) {
    foreach my $waiver ( split /\s+/, $waivelist ) { 
	$waives{$waiver} = {};
    }	
} 

#opening timing directory 
die "Can't find the timing directory\n" if  ( ! -d "timing");
opendir ( TIMINGDIR , "timing" ) or die "Can't open timing directory for read \n";
my @run_dirs = readdir (TIMINGDIR);

my @etm_logs;
my @internal_logs;

foreach my $run_dir ( @run_dirs ) { 
    my $cur_dir = "timing/".$run_dir;
    next if ( $run_dir =~ /^\.+$/);
    next if ( ! -d $cur_dir ); 
    
    if ( $cur_dir =~ /_etm$/ ) { 
	push @etm_logs , "${cur_dir}/timing.log";
    } elsif ( $cur_dir =~ /_internal$/ ) { 
	push @internal_logs , "${cur_dir}/timing.log";
    }
}

&process_warnings ( "etm", \@etm_logs , \%waives );
&process_warnings ( "internal", \@internal_logs , \%waives );
}


sub process_warnings { 
    my $type = shift;
    my $timing_log_ref = shift;
    my $waive_ref = shift;
    my %waives = %$waive_ref;
    my @timing_logs = @$timing_log_ref;
    
    if ( $#timing_logs >= 0 ) { 
	      iprint ("$type log files are: \n");
        foreach my $log ( @timing_logs ) { 
    	    iprint ("$log\n");;
        }
      
        iprint ("processing $type log files ...\n");
        iprint ("log file: ${type}_timing_report.csv\n");
      
    	my %warnings;
		my %errors;
        foreach my $log ( @timing_logs ) { 
            $log =~ /timing\/(\S+)\/timing\.log/;    #timing/Run_ffg0p88v0c_internal/timing.log
            my $corner = $1;
          
            #open ( my $LOG ,"<" ,$log ) or die "Can't open log file $log \n";
	    my @LOG = read_file("$log");
            foreach my $line (@LOG) {
      		chomp ( $line );
      		if ( $line =~ /^Warning:.*\((\S+)\)$/ ) { 
      		    if ( exists $waives{$1} ) { 
      			if ( exists $waives{$1}{$type} ) { 		
      			    $waives{$1}{$type} +=1;
      			} else { 
      			    $waives{$1}{$type} = 1;
      			}					
      		    } else { 	
      			if ( exists $warnings{$1} ) { 
      			    push @{$warnings{$1}{"warnings"}{$corner}}, $line;
      			    $warnings{$1}{"count"} += 1;
      			} else { 
      			    $warnings{$1}{"warnings"}{$corner} = [$line];	    
      			    $warnings{$1}{"count"} = 1;
      			}
      		    }
      		}  elsif ( $line =~ /^Error:.*\((\S+)\)$/ ) { 
      		    if ( exists $waives{$1} ) { 
      			if ( exists $waives{$1}{$type} ) { 		
      			    $waives{$1}{$type} +=1;
      			} else { 
      			    $waives{$1}{$type} = 1;
      			}					
      		    } else { 	
      			if ( exists $errors{$1} ) { 
      			    push @{$errors{$1}{"errors"}{$corner}}, $line;
      			    $errors{$1}{"count"} += 1;
      			} else { 
      			    $errors{$1}{"error"}{$corner} = [$line];	    
      			    $errors{$1}{"count"} = 1;
      			}
      		    }
      		}

            }
        }

        #open ( my $LOG, ">","${type}_timing_report.csv" ) or die "Can't open ${type}_timing_log.rpt file for write\n";
#        print $LOG "Warning Summary\n";
#        print $LOG "Warning Code, Count\n";
        my $LOG1 = "Warning Summary\nWarning Code, Count\n";
        my $status1 = write_file($LOG1, "${type}_timing_report.csv");
        foreach my $warning ( keys %warnings ) { 
           # print $LOG "$warning, $warnings{$warning}{'count'}\n";
	    my $status2 = write_file("$warning, $warnings{$warning}{'count'}\n","${type}_timing_report.csv",">");
        }
        my $error_head = "\n\nError Summary\nError Code, Count\n";
        write_file($error_head, "${type}_timing_report.csv",">");
        foreach my $error ( keys %errors ) {  
	        write_file("$error, $errors{$error}{'count'}\n","${type}_timing_report.csv",">");
        }
      
        my @waivelist = keys %waives;
        if ( $#waivelist >= 0 ) { 
            my $LOG2 = "\n\nList of waived warning/error\nCode, Count";  
        my $status3 = write_file($LOG2, "${type}_timing_report.csv",">");

          foreach my $waive ( keys %waives ) { 
          if ( exists $waives{$waive}{$type} ) { 
               my $status4 = write_file("$waive, $waives{$waive}{$type}\n", "${type}_timing_report.csv",">");
          } else { 
            my $status5 = write_file( "$waive, 0\n","${type}_timing_report.csv",">");   
          }
            }
        } else { 
            my $status6 = write_file( "\n\nNo waived Warnings/Error\n","${type}_timing_report.csv",">");   
        }


        if ( (exists $warnings{"DELC-109"}) and (! exists $waives{"DELC-109"} )) { 
          my $LOG3 = "\n\n\nDELC-109 warning summary: \nLoad limit is $load_limit\nSlope limit is $slope_limit\nprocessing DELC-109 warnings ...\n\n\n";

          my $status7 = write_file( $LOG3,"${type}_timing_report.csv",">");   

          #print Dumper $warnings{"DELC-109"};
          my %delc_109 = %{$warnings{"DELC-109"}{"warnings"}};
          my %delc_109_load_max;
          my %delc_109_load_min;
          my %delc_109_slope_max;
          my %delc_109_slope_min;

          foreach my $corner ( keys (%delc_109)) { 
              foreach my $warning ( @{$delc_109{$corner}} ) { 
                if ( $warning =~ /cell (\S+) at instance (\S+) for .* from model pin (\S+) to pin (\S+) : (\S+) load (\S+) > maximum load (\S+)/ ) {
                  my ($cell , $instance , $from_pin , $to_pin, $direction , $value , $max_value) = ($1 , $2 , $3 , $4 , $5 , $6, $7);
                  $max_value =~ s/[\.\,]$//;
                  if ( exists $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}) {
                    if ( $value - $max_value > $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} ) { 
                      $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'load'} = $value;
                      $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'max_load'} = $max_value;
                      $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} = $value - $max_value;    
                      $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} = $corner;    
                    }
                  } else { 
                      $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'load'} = $value;
                      $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'max_load'} = $max_value;
                      $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} = $value - $max_value;    
                      $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} = $corner;    
                  }
                }

                if ( $warning =~ /cell (\S+) at instance (\S+) for .* from model pin (\S+) to pin (\S+) : (\S+) load (\S+) < minimum load (\S+)/ ) {
                  my ($cell , $instance , $from_pin , $to_pin, $direction , $value , $min_value) = ($1 , $2 , $3 , $4 , $5 , $6, $7);
                  $min_value =~ s/[\.\,]$//;
                  if ( exists $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}) {
                    if ( $min_value - $value > $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} ) { 
                      $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'load'} = $value;
                      $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'min_load'} = $min_value;
                      $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} = $min_value - $value;    
                      $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} = $corner;    
                    }
                  } else { 
                      $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'load'} = $value;
                      $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'min_load'} = $min_value;
                      $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} = $min_value - $value;    
                      $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} = $corner;    
                  }
                }

                                                 
                
                if ( $warning =~ /cell (\S+) at instance (\S+) for .* from model pin (\S+) to pin (\S+) : (\S+) slope (\S+) > maximum slope (\S+)/ ) {
                  my ($cell , $instance , $from_pin , $to_pin, $direction , $value , $max_value) = ($1 , $2 , $3 , $4 , $5 , $6, $7);
                  $max_value =~ s/[\.\,]$//;
                  if ( exists $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}) {
                    if ( $value - $max_value > $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} ) { 
                      $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'slope'} = $value;
                      $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'max_slope'} = $max_value;
                      $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} = $value - $max_value;    
                      $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} = $corner;    
                    }
                  } else { 
                      $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'slope'} = $value;
                      $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'max_slope'} = $max_value;
                      $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} = $value - $max_value;    
                      $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} = $corner;    
                  }
                }

                if ( $warning =~ /cell (\S+) at instance (\S+) for .* from model pin (\S+) to pin (\S+) : (\S+) slope (\S+) < minimum slope (\S+)/ ) {
                  my ($cell , $instance , $from_pin , $to_pin, $direction , $value , $min_value) = ($1 , $2 , $3 , $4 , $5 , $6, $7);
                  $min_value =~ s/[\.\,]$//;
                  if ( exists $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}) {
                    if ( $min_value - $value > $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} ) { 
                      $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'slope'} = $value;
                      $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'min_slope'} = $min_value;
                      $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} = $min_value - $value;    
                      $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} = $corner;    
                    }
                  } else { 
                      $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'slope'} = $value;
                      $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'min_slope'} = $min_value;
                      $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} = $min_value - $value;    
                      $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} = $corner;    
                  }
                }

              }
          }

          
          foreach my $cell ( sort (keys %delc_109_load_max)) { 
            foreach my $instance ( sort (keys %{$delc_109_load_max{$cell}})) {
              foreach my $from_pin ( sort (keys %{$delc_109_load_max{$cell}{$instance}})) {
                foreach my $to_pin ( sort (keys %{$delc_109_load_max{$cell}{$instance}{$from_pin}} )) {
                  foreach my $direction ( sort (keys %{$delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}} )) {
                    if ( $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} > $load_limit ) { 
                      my $LOG4 = "DELC-109,  load maximum violation at $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} corner, Warning: Timing model index out of range for cell ${cell} at instance ${instance} for delay arc from model pin ${from_pin} to pin ${to_pin} : ${direction} load $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'load'} > maximum load $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'max_load'} : difference is $delc_109_load_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'}. \n";
                      my $status8 = write_file( $LOG4,"${type}_timing_report.csv",">");   
		    }
                  }                
                }
              }
            }
          }
            

          foreach my $cell ( sort (keys %delc_109_load_min)) { 
            foreach my $instance ( sort (keys %{$delc_109_load_min{$cell}})) {
              foreach my $from_pin ( sort (keys %{$delc_109_load_min{$cell}{$instance}})) {
                foreach my $to_pin ( sort (keys %{$delc_109_load_min{$cell}{$instance}{$from_pin}} )) {
                  foreach my $direction ( sort (keys %{$delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}} )) {
                    if ( $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} > $load_limit ) { 
                      my $LOG5 =  "DELC-109, load minimum violation at $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} corner, Warning: Timing model index out of range for cell ${cell} at instance ${instance} for delay arc from model pin ${from_pin} to pin ${to_pin} : ${direction} load $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'load'} < minimum load $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'min_load'} : difference is $delc_109_load_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'}. \n";
                      my $status10 = write_file( $LOG5,"${type}_timing_report.csv",">");   
                    }
                  }
                }
              }
            }
          }


          foreach my $cell ( sort (keys %delc_109_slope_max)) { 
            foreach my $instance ( sort (keys %{$delc_109_slope_max{$cell}})) {
              foreach my $from_pin ( sort (keys %{$delc_109_slope_max{$cell}{$instance}})) {
                foreach my $to_pin ( sort (keys %{$delc_109_slope_max{$cell}{$instance}{$from_pin}} )) {
                  foreach my $direction ( sort (keys %{$delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}} )) {
                    if ( $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} > $slope_limit ) { 
                      my $LOG6 = "DELC-109, slope maximum violation at $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} corner, Warning: Timing model index out of range for cell ${cell} at instance ${instance} for constraint arc from model pin ${from_pin} to pin ${to_pin} : ${direction} slope $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'slope'} > maximum slope $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'max_slope'} : difference is $delc_109_slope_max{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'}. \n";
                      my $status12 = write_file( $LOG6,"${type}_timing_report.csv",">");   
                    }
                  }                
                }
              }
            }
          }
            

          foreach my $cell ( sort (keys %delc_109_slope_min)) { 
            foreach my $instance ( sort (keys %{$delc_109_slope_min{$cell}})) {
              foreach my $from_pin ( sort (keys %{$delc_109_slope_min{$cell}{$instance}})) {
                foreach my $to_pin ( sort (keys %{$delc_109_slope_min{$cell}{$instance}{$from_pin}} )) {
                  foreach my $direction ( sort (keys %{$delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}} )) {
                    if ( $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'} > $slope_limit ) { 
                      my $LOG7 = "DELC-109, slope  minimum violation at $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'corner'} corner, Warning: Timing model index out of range for cell ${cell} at instance ${instance} for constraint arc from model pin ${from_pin} to pin ${to_pin} : ${direction} slope $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'slope'} > maximum slope $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'min_slope'} : difference is $delc_109_slope_min{$cell}{$instance}{$from_pin}{$to_pin}{$direction}{'diff'}. \n";
                      my $status14 = write_file( $LOG7,"${type}_timing_report.csv",">");   
                    }
                  }                
                }
              }
            }
          }
            

          #print Dumper \%delc_109_load_max;
          #print Dumper \%delc_109_load_min;
          #print Dumper \%delc_109_slope_max;
          #print Dumper \%delc_109_slope_min;

        }


      	
    my $LOG8 = "\n\nList of warnings per etm corner\nWarning Code, ETM Corner, Warning Message\n";

	my $status16 = write_file( $LOG8,"${type}_timing_report.csv",">");        
        foreach my $warning_type ( keys %warnings ) { 
            next if ( $warning_type eq "DELC-109");
      	    foreach my $corner ( keys %{$warnings{$warning_type}{"warnings"}} ) { 
      		    foreach my $warning (&uniq (@{$warnings{$warning_type}{"warnings"}{$corner}}) ) { 
      			     my $status17 = write_file( "$warning_type, $corner, $warning\n","${type}_timing_report.csv",">");
      		    }
      	    }
            write_file("\n","${type}_timing_report.csv",">");
        }
    my $write_error = "\n\nList of errors per etm corner\nError Code, ETM Corner, Error Message\n";
	write_file( $write_error,"${type}_timing_report.csv",">");        
        foreach my $error_type ( keys %errors ) { 
            next if ( $error_type eq "DELC-109");
      	    foreach my $corner ( keys %{$errors{$error_type}{"errors"}} ) { 
      		    foreach my $error (&uniq (@{$errors{$error_type}{"errors"}{$corner}}) ) { 
      			     write_file( "$error_type, $corner, $error\n","${type}_timing_report.csv",">"); ;
      		    }
      	    }
        }
      	#close ($LOG);
    } else { 
	     my $status19 = write_file( "No $type timing.log files found to process...\n","${type}_timing_report.csv",">");
    }


}	


sub uniq {
    my %seen;
   # grep !$seen{$_}++, @_;
    grep {!$seen{$_}++} @_;

}

sub process_cmd_line_args(){
    my ($debug,$waivelist,$load_limit,$slope_limit,$opt_help,$opt_dryrun,$opt_debug,$opt_verbosity);
    my $success = GetOptions(
               "help|h"          => \$opt_help,
               "waive=s"         => \$waivelist,
               "dryrun!"         => \$opt_dryrun,
               "debug=i"         => \$opt_debug,
               "verbosity=i"     => \$opt_verbosity,
               "lth=s"           => \$load_limit,
               "sth=s"           => \$slope_limit,
        );
    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );
	$load_limit  = 1                  if( not defined $load_limit    );
	$slope_limit  = 1                  if( not defined $slope_limit    );

    &usage(0) if $opt_help;
    &usage(1) unless( $success );

    return ($opt_debug,$waivelist,$load_limit,$slope_limit,$opt_help)	
}      

sub usage($) {
my $exit_status = shift || '0';
    my $USAGE = <<EOusage;

    Script to summarize timing.log warnings according to their warning codes.
    Run directory: Nt run directory of current cell, must contain "timing" folder with ETM and Internal run directories 
    
    help|h: display script manual
    waive: specify waivable warning codes

    Usage: alphaSummarizeNtWarnings.pl [-h|-help]

    -h or -help  this help message
    -waive 

    Run Example:
    ./alphaSummarizeNtWarnings.pl -waive="DELC-109 MXTR-022"

EOusage

    nprint ("$USAGE");
    exit;
    
}
