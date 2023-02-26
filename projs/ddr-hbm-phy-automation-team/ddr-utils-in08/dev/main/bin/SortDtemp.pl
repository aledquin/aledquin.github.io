#!/depot/perl-5.14.2/bin/perl
    
#Develpoed by Dikshant Rohatgi(dikshant@synopsys.com)
#Sort the devices in .tmideg files whose dtemp is greater than 20C
#Should be run when inside stress folder
#To run the script: <script_path> <year directory>
use warnings;
use strict;

use Getopt::Long;
use Data::Dumper;
use Capture::Tiny qw/capture/;
use List::MoreUtils qw(uniq);
use File::Basename;
use Cwd;

use FindBin qw( $RealBin $RealScript );
use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#
##  Constants
use constant LOG_INFO => 0;
use constant LOG_WARNING => 1;
use constant LOG_ERROR => 2;
use constant LOG_FATAL => 3;
use constant LOG_RAW => 4;

#----------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG         = NONE;
our $VERBOSITY     = NONE;
our $TESTMODE      = undef;
our $PROGRAM_NAME  = $RealScript;
our $LOGFILENAME   = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION       = get_release_version();
#----------------------------------#

BEGIN {
    our $AUTHOR='dikshant';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
END {
    local $?;   ## adding this will pass the status of failure if the script
                ## does not compile; otherwise this will always return 0
    footer();
    write_stdout_log("$LOGFILENAME");
}


sub Main {
    utils__script_usage_statistics( $PROGRAM_NAME, $VERSION);
    if ($ARGV[0] == "-help") {
        iprint("Script used to sort Dtemp value from emir ascii files\n");
	      exit(0);
    }
    my $path=$ARGV[0];
    my $log="SortedDtempFiles_$path";
   
    #if(! -d $path) { print "$path Doesn't Exist\nExiting\n";exit -1;}
    my @tmi_files=glob("$path/*tmideg*");
    my %output_hash;
    my @out_lines;
    foreach my $file (sort @tmi_files) {
        my $corner_name=(split "/",$file)[-1];
        my $flag=0;
        push(@out_lines, "IN $corner_name\n" );
        push(@out_lines, "\tDevice_Name\t\tdtemperature\n" );
        foreach my $input ( read_file($file) ){
            if( $input =~ m/^\d+/) {
                my $line=$input;
                my $device_name=(split /\s+/,$line)[1];
                my $dtemp=(split /\s+/,$line)[2];
                $dtemp =~ s/\*//g;
                if($dtemp > 20) {
                    push(@out_lines, "\t$device_name\t\t$dtemp\n" );
                    $output_hash{$device_name}{$corner_name}=$dtemp;
                    $flag=1;
                }
            } else {
                next;
            }    
        }  ## END foreach
        push(@out_lines, "\tN/A" ) if($flag ne 1); 
        push(@out_lines, "\n");
    }  ## END foreach
    push(@out_lines, "************************"x10 );
    push(@out_lines, "\nSUMMARY:\n" );
    push(@out_lines, "\tDevice_Name\t\tCorner_Name\t\tMax_Dtemp\n");
    foreach my $dname (sort (keys %output_hash)) {
        my $max_value=0;
        my $corner;
        my $device;
        foreach my $cname (sort keys %{$output_hash{$dname}}) {
        if($max_value < $output_hash{$dname}{$cname}) {
            $max_value=$output_hash{$dname}{$cname};
            $corner=$cname;
            $device=$dname;
        } else {
            next;
        }
        }
        push(@out_lines, "\t$device\t\t$corner\t\t$max_value\n");
    }
    write_file(\@out_lines, "$path/$log" );
}
