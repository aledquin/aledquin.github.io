#!/depot/perl-5.14.2/bin/perl
#!/depot/perl-5.8.0/bin/perl
###############################################################################
#
# Name    : alphaSortingAgingData.pl
# Author  : N/A
# Date    : N/A
# Purpose : N/A
#
# Modification History
#             2022-05-26 12:38:49 => Adding Perl template. HSW.
###############################################################################
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use Getopt::Long;
use File::Basename qw(dirname basename);
use File::Spec::Functions qw( catfile );
use Cwd qw( cwd abs_path getcwd );
use Carp qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PREFIX       = "ddr-utils";
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version();
#--------------------------------------------------------------------#

BEGIN {
    our $AUTHOR = 'Multiple Authors';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
END {
    footer();
    write_stdout_log( $LOGFILENAME );
    utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION );
}


#---------------------
# GLOBAL Vars
#---------------------
    my( $DATA1, $DATA2, $DATA3 );
    my(
        @tmilist, @tmi2list 
    );
#---------------------


#-----------------------------------------------------------
sub Main(){
    my @orig_argv = @ARGV;

    my $opt_nousage =  process_cmd_line_args();
    unless( $main::DEBUG or $opt_nousage) {
        utils__script_usage_statistics( $RealScript, $VERSION, \@orig_argv);
    }

    my( @radeg_files, @deg2_files, @tmilist1);

    my $d = cwd; #storing directory path
    opendir(D, $d) || die "Can't open directory $d: $!\n";

    #Try to grep if its TMI Flow and have *#2.tmideg2_* files
    @tmilist = `ls | grep "#2.tmideg2_"`;
    if (( @tmilist == 0 )) { 
        @tmi2list = `ls | grep "tmideg"`; #greping TMI Degradation files
    }

    if ( (@tmi2list == 0 ) ) {
        @radeg_files = grep {/radeg/} readdir(D); #greping the MOSRA degradation files
    }
    closedir(D);

    my $date_time=`date +"%F%T"`;
    chomp($date_time);

    if (( @tmilist == 0 )) {
        @tmilist1 = sort by_number @tmi2list;
    }
    else {
        @tmilist1 = sort by_number @tmilist;
    }


    if (!(@radeg_files == 0 )){
        @deg2_files = sort by_number @radeg_files;
    }

    if( !(@tmilist1 == 0) ){
        #File:-3 to contain the detailed data of the devices violating the Aging criteria for every corner files.
        open($DATA1, ">>", "Sorted_degradation_detailed_data_$date_time.csv"); # nolint open

        #File:-2 to contain the Violations with Device Names and Violation Values. 
        open($DATA2, ">>", "Sorted_degradation_data_$date_time.csv"); # nolint open

        #File:-1 to report Pass/Fail status across all the corners.
        open($DATA3, ">>", "Report_Status_$date_time.csv"); # nolint open

        print "Please Open the following files for more information :\n $d/Sorted_degradation_data_$date_time.csv - File Contains the data of the devices violating the criteria *dvtlin > 100mv || dids  > 10% || didlin > 10% * \n $d/Report_Status_$date_time.csv - File give the details for Pass/Fail Status across each corner \n $d/Sorted_degradation_detailed_data_$date_time.csv - File Contains the detailed data of the devices violating the Aging criteria for every corner file \n";
    }

    if( !(@deg2_files == 0) ){
        print "Please Open the following files for more information :\n $d/Sorted_degradation_data_$date_time.csv - File Contains the data of the devices violating the criteria *delvth <100mv || dids  < 10%* \n $d/Report_Status_$date_time.csv - File give the details for Pass/Fail Status across each corner \n";
        #File to store data
        open ($DATA1, ">>", "Sorted_degradation_data_$date_time.csv"); # nolint open
        #File to store data
        open ($DATA2, ">>", "Report_Status_$date_time.csv"); # nolint open
    }

    if( !(@tmilist1 == 0 ) ){
        TMI_Sorted_data( @tmilist1 );
    }
    
    if( !(@deg2_files == 0 ) ){
        MOSRA_Sorted_data( @deg2_files );
    }

    return();
} # END Main

#--------------------------------------------------------------
sub by_number {
    my ( $anum ) = $a =~ /(\d+)$/;
    my ( $bnum ) = $b =~ /(\d+)$/;
    ( $anum || 0 ) <=> ( $bnum || 0 );
}

#--------------------------------------------------------------
sub TMI_Sorted_data {
    my @tmilist11=@_;

    my $m=0;
    my $i=0;
    my $j=0;
    my @arr2;
    my $num;
    my $first=0;
    my $file_name;
    my $flagR2=0;
    my $max_dtemp_overall;
    my $device_name_overall;
    my $tmideg_dtemp;
    my $max_idsat_overall;
    my $device_name_idsat_overall;
    my $tmideg_idsat;
    my $max_idlin_overall;
    my $device_name_idlin_overall;
    my $tmideg_idlin;
    my $max_vtlin_overall;
    my $device_name_vtlin_overall;
    my $tmideg_vtlin;
    
    my $dtemp_pos;
    foreach my $file ( @tmilist11 ){
        my ( $max_dtemp, $max_idsat, $max_idlin, $max_vtlin );
        my ( $idsat_pos, $idlin_pos, $vtlin_pos );
        # For excluding .xml extension files which get also grepped
        next if($file =~ m/xml/ );
        print $DATA1 "File Name is : $file\n" ; 
        print $DATA2 "File Name is : $file : ";
        print $DATA3 "File Name is : $file :  ";
        print $DATA1 "Devices with didsat(HCI+BTI,%) > 10% or didlin(HCI+BTI,%) > 10% or dvtlin(HCI+BTI,V)>100mV :->\n" ;
        print $DATA1 "\n\n"; 
        my $flag=0;
        my $str = $file;
        my $str_sample=$str;
        if ( $first == 0) {
        $file_name = $str_sample;
            $file_name =~ s/(\d+)$//g ;
            $first =1;
            ($str_sample) = ($str_sample =~ /(\d+)$/);
            $i=$str_sample;
        }
        ($str) = ($str =~ /(\d+)$/);
        while( $str != $i ){
            $arr2[$j] = $i;
            $j=$j+1;
            $i=$i+1;
        }    
        my $n=0; my $c=0;
        my $flagR=0;
        my $flagR1=0;
        my ( $device_name, $device_name_idsat, $device_name_idlin, $device_name_vtlin );
        my $device_name1="$file";        
        foreach my $line ( read_file($file) ){
            if ($flagR == 1 ) {
                my @arr = split (" ",$line);
                if($flagR1 == 0 ) {
                    if ( !($dtemp_pos eq "") ) {
                        $max_dtemp = $arr[$dtemp_pos];
                    }
                    $max_idsat = $arr[$idsat_pos];
                    $max_idlin = $arr[$idlin_pos];
                    $max_vtlin = $arr[$vtlin_pos];
                    $device_name = $arr[1];
                    $device_name_idsat = $arr[1];
                    $device_name_idlin = $arr[1];
                    $device_name_vtlin = $arr[1];
                    $flagR1=1;
                }
                if ( !($dtemp_pos eq "") ) {
                    if($max_dtemp < $arr[$dtemp_pos] ){
                        $max_dtemp   = $arr[$dtemp_pos];
                        $device_name = $arr[1];
                    }
                }
                if($max_idsat < $arr[$idsat_pos] ){
                    $max_idsat = $arr[$idsat_pos];
                    $device_name_idsat = $arr[1];
                }
                if($max_idlin < $arr[$idlin_pos] ){
                    $max_idlin = $arr[$idlin_pos];
                    $device_name_idlin = $arr[1];
                }
                if($max_vtlin < $arr[$vtlin_pos] ){
                    $max_vtlin = $arr[$vtlin_pos];
                    $device_name_vtlin = $arr[1];
                }
                if ( $arr[$idsat_pos] > 10 || $arr[$idlin_pos] > 10 || $arr[$vtlin_pos] > 0.1 ){
                    #Checking the conditions for idsat, Idlin, Vtlin for grepping out the devices 
                    if ($c == 0 ){
                        print $DATA2 "\n";
                        if ( !($dtemp_pos eq "") ) {
                            print $DATA2 "Instance\tdtemperature\tdidsat(HCI+BTI,%)\tdidlin(HCI+BTI,%)\tdvtlin(HCI+BTI,V)\n";
                        }
                        else {
                            print $DATA2 "Instance\tdidsat(HCI+BTI,%)\tdidlin(HCI+BTI,%)\tdvtlin(HCI+BTI,V)\n";
                        }
                        $c=1;
                    }
                    if ( !($dtemp_pos eq "") ) {
                        print $DATA2 "$arr[1]\t$arr[$dtemp_pos]\t$arr[$idsat_pos]\t$arr[$idlin_pos]\t$arr[$vtlin_pos]\n";
                    }
                    else {
                        print $DATA2 "$arr[1]\t$arr[$idsat_pos]\t$arr[$idlin_pos]\t$arr[$vtlin_pos]\n";
                    }
                    my $data_value = $line;
                    $data_value =~ s/\s+/\t/g;
                    print $DATA1 "$data_value\n";
                    $flag=1;
                }
            }
            if ($line =~ m/Rank/ ) {
                 my $heading = "$line";
                 $heading =~ s/\s+/\t/g;
                 print $DATA1 "$heading\n"; #Printing the header in file
                 my @arr_head = split (" ",$line);
                 my $h=0;
                 my $dtemp_flag=0;
                 foreach my $i (@arr_head) {
                     if ( $i =~ m/didsat/ && $i =~ m/(HCI\+BTI)/ ) {
                         $idsat_pos=$h;
                     }
                     if ( $i =~ m/didlin/ && $i =~ m/(HCI\+BTI)/ ) {
                         $idlin_pos=$h;
                     }
                     if ( $i =~ m/dvtlin/ && $i =~ m/(HCI\+BTI)/ ) {
                          $vtlin_pos=$h;
                     }
                     if ( $i =~ m/dtemperature/){
                         $dtemp_pos=$h;
                         $dtemp_flag=1;
                     }
                     $h=$h+1;
                 }
                 if ( $dtemp_flag == 0) {
                     $dtemp_pos="";
                 }
                 $flagR=1;
             }
             $n=$n+1;
        }  ## END foreach
        if($flagR2 == 0 ) {
             $max_dtemp_overall = $max_dtemp;
             $max_idsat_overall = $max_idsat;
             $max_idlin_overall = $max_idlin;
             $max_vtlin_overall = $max_vtlin;
             $device_name_overall = $device_name;
              $tmideg_dtemp="$device_name1";
             $device_name_idsat_overall = $device_name_idsat;
             $tmideg_idsat="$device_name1";
             $device_name_idlin_overall = $device_name_idlin;
             $tmideg_idlin="$device_name1";
             $device_name_vtlin_overall = $device_name_vtlin;
             $tmideg_vtlin="$device_name1";
             $flagR2=1;
        }
        if ( !($dtemp_pos eq "") ) {
            if($max_dtemp_overall < $max_dtemp ){
                $max_dtemp_overall = $max_dtemp;
                $device_name_overall = $device_name;
                $tmideg_dtemp="$device_name1";
            }
        }
        if($max_idsat_overall < $max_idsat ){
            $max_idsat_overall = $max_idsat;
            $device_name_idsat_overall = $device_name_idsat;
            $tmideg_idsat="$device_name1";
        }
        if($max_idlin_overall < $max_idlin ){
            $max_idlin_overall = $max_idlin;
            $device_name_idlin_overall = $device_name_idlin;
            $tmideg_idlin="$device_name1";
        }
        if($max_vtlin_overall < $max_vtlin ){
            $max_vtlin_overall = $max_vtlin;
            $device_name_vtlin_overall = $device_name_vtlin;
            $tmideg_vtlin="$device_name1";
        }
        if ($flag == 0) {
            print $DATA1 "Info : No Device Violation Found\n\n";
            print $DATA2 "Info : No Device Violation Found\n";
            print $DATA3 "STATUS   :\tPASS\n";
        }
        print $DATA1 "\n\n";
        if ( !($dtemp_pos eq "") ) {
        print $DATA1 "In this Corner File Maximum dtemperature : $max_dtemp || Device Name :  $device_name\n\n"; }
        print $DATA1 "In this Corner File Maximum Idsat : $max_idsat || Device Name :  $device_name_idsat\n\n";
        print $DATA1 "In this Corner File Maximum Idlin : $max_idlin || Device Name :  $device_name_idlin\n\n";
        print $DATA1 "In this Corner File Maximum Vtlin : $max_vtlin || Device Name :  $device_name_vtlin\n\n";
        print $DATA2 "************************************************************************************\n\n";
        if ($flag == 1 ) {
            print $DATA3 "STATUS   :\tFAIL\n";
            print $DATA2 "\n\n";
            if ( !($dtemp_pos eq "") ) {
            print $DATA2 "In this Corner File Maximum dtemperature : $max_dtemp || Device Name :  $device_name\n\n"; }
            print $DATA2 "In this Corner File Maximum Idsat(HCI+BTI): $max_idsat || Device Name :  $device_name_idsat\n\n";
            print $DATA2 "In this Corner File Maximum Idlin(HCI+BTI) : $max_idlin || Device Name :  $device_name_idlin\n\n";
            print $DATA2 "In this Corner File Maximum Vtlin(HCI+BTI) : $max_vtlin || Device Name :  $device_name_vtlin\n\n";
            print $DATA2 "**********************************************************************************************\n\n";
        }
        $i=$i+1;
    } # END foreach $file 

    #*******************To check if any Corner files get missed out in between**********************************#
    my $len1=@arr2;
    if ($len1 > 0) {
        print $DATA3 "The missing corners/files are : \n";
        for (my $k =0; $k<$len1; $k++) {
            print  $DATA3 "$file_name$arr2[$k]\n";
        }
    }
    else {
        print  $DATA3 "All corners files are present \n";
    }
    #*************************************************************************************************************#
    if ( !($dtemp_pos eq "") ) {
        print $DATA1 "Overall Maximum dtemperature : $max_dtemp_overall || Device Name :  $device_name_overall || Present in Corner  file :$tmideg_dtemp\n\n";
        print $DATA2 "Overall Maximum dtemperature : $max_dtemp_overall || Device Name :  $device_name_overall || Present in Corner  file :$tmideg_dtemp\n\n";
    }
    print $DATA1 "Overall Maximum Idsat(HCI+BTI) : $max_idsat_overall || Device Name :  $device_name_idsat_overall || Present in Corner file :$tmideg_idsat\n\n";
    print $DATA1 "Overall Maximum Idlin(HCI+BTI) : $max_idlin_overall || Device Name :  $device_name_idlin_overall || Present in Corner file : $tmideg_idlin\n\n";
    print $DATA1 "Overall Maximum Vtlin(HCI+BTI) : $max_vtlin_overall || Device Name :  $device_name_vtlin_overall || Present in Corner file :$tmideg_vtlin\n\n";
    print $DATA2 "Overall Maximum Idsat(HCI+BTI) : $max_idsat_overall || Device Name :  $device_name_idsat_overall || Present in Corner file :$tmideg_idsat\n\n";
    print $DATA2 "Overall Maximum Idlin(HCI+BTI) : $max_idlin_overall || Device Name :  $device_name_idlin_overall || Present in Corner file : $tmideg_idlin\n\n";
    print $DATA2 "Overall Maximum Vtlin(HCI+BTI) : $max_vtlin_overall || Device Name :  $device_name_vtlin_overall || Present in Corner file : $tmideg_vtlin\n\n";
    close($DATA1);
    close($DATA2);
    close ($DATA3);

} # END sub TMI_Sorted_data 

#--------------------------------------------------------------
sub MOSRA_Sorted_data {
    my @degradation_files = @_;

    my( $max_vth_overall, $max_ids_overall );
    my $first=0;
    my $first_time=0;
    my $i=0; my $j=0;
    my @arr2;
    my $num;
    my $file_name;

    my $related_corner_file;
    my( $related_device_vt_overall, $related_device_ids_overall );
    foreach my $file (@degradation_files) {
        print $DATA1 "Corner File : $file\n\n";
        print $DATA2 "Corner File : $file\n";
        my $str= $file;
        my $str_sample=$str;
        if ( $first == 0) {
            $file_name = $str_sample;
            $file_name =~ s/(\d+)$//g ;
            $first =1;
            ($str_sample) = ($str_sample =~ /(\d+)$/);
            $i=$str_sample;
        }
        ($str) = ($str =~ /(\d+)$/);
        while ( $str != $i ) {
            $arr2[$j] = $i;
            $j=$j+1;
            $i=$i+1;
        }
        my @data=();
        my $value;
        my $first=0;
        my( $related_device_vt, $related_device_ids );
        my( $ids, $max_vth, $max_ids );
        foreach my $line ( read_file($file) ){
            my( $vt, $ids, $max_vth, $max_ids );
            my( $device, $device_name );
            if ( $line =~ m/Device Type/ ) {
                $device_name=$device;
                chomp($device_name);
            }
            elsif ( $line =~ m/delvth/ ) {
                my $vth=$line;
                chomp($vth);
                my @v = split(/=/,$vth);
                $vt=$v[1];
            }
            elsif ( $line =~ m/dids/ ) {
                my $id=$line;
                chomp($id);
                my @i = split /=/,$id;
                $ids=$i[1];
                chop($ids);
                if ( $first == 0 ) {
                    $max_vth=$vt;
                    $max_ids=$ids;
                    $related_device_vt="$device_name";
                    $related_device_ids="$device_name";
                    $first=1;
                }
                if ( $first == 1 ) {
                    if ( $max_vth < $vt ) {
                        $max_vth=$vt;
                        $related_device_vt="$device_name";
                    }
                    if ( $max_ids < $ids ) {
                        $max_ids=$ids;
                        $related_device_ids="$device_name";
                    }
                }
                my $deltai=abs($ids-100);
                if ( $vt > 0.1 || $deltai > 100 ) {
                    $value="$device_name\t$vt\t$ids\n";
                    push @data,$value; 
                }
            }
            else {
                $device=$line;
            }
        } # END foreach
        my $len=@data;
        if ( $len == 0 ) {
            print $DATA1 "Info : No Device Violation Found\n\n";
            print $DATA2 "STATUS   :\tPASS\n\n";
        }
        else {
            print $DATA1 "Device_Name\tdelvth0\tdids\n";
            print $DATA1 "@data\n\n";
            print $DATA2 "STATUS   :\tFAIL\n\n";
        }
        if ( $first_time == 0 ) {
            $max_vth_overall=$max_vth;
            $max_ids_overall=$max_ids;
            $related_device_vt_overall="$related_device_vt";
            $related_device_ids_overall="$related_device_ids";
            $related_corner_file="$file";
            $first_time=1;
        }
        if ( $first_time == 1 ) {
            if ( $max_vth_overall < $max_vth ) {
                $max_vth_overall=$max_vth;
                $related_device_vt_overall="$related_device_vt";
                $related_corner_file="$file";
            }
            if ( $max_ids < $ids ) {
                $max_ids_overall=$max_ids;
                $related_device_ids_overall="$related_device_ids";
                $related_corner_file="$file";
            }
        }
        print $DATA1 "In this Corner File Maximum delvth : $max_vth || Device Name :  $related_device_vt\n\n";
        print $DATA1 "In this Corner File Maximum dids : $max_ids || Device Name :  $related_device_ids\n\n";
        print $DATA1 "***********************************************************************************************************************\n\n";
    }  # END  foreach my $file (@degradation_files)

    #*******************To check if any Corner files get missed out in between**********************************#
    my $len1=@arr2;
    if ($len1 > 0) {
        print  $DATA2 "The missing corners/files are : \n";
        for (my $k =0; $k<$len1; $k++) {
            print  $DATA3 "$file_name$arr2[$k]\n";
        }
    }
    else {
        print  $DATA2 "All corners files are present \n";
    }
    #***********************************************************************************************************#
    print $DATA1 "\n\n\n\n";
    print $DATA1 "Overall Maximum delvth : $max_vth_overall || Device Name :  $related_device_vt_overall || Related Corner File : $related_corner_file \n\n";
    print $DATA1 "Overall Maximum dids : $max_ids_overall || Device Name :  $related_device_ids_overall  || Related Corner File : $related_corner_file \n\n";
    
} # END sub MOSRA_Sorted_data

#------------------------------------------------------------------------------
# 
#------------------------------------------------------------------------------
sub process_cmd_line_args() {
    ## get specified args
    my( $opt_nousage, $opt_help, $opt_debug, $opt_verbosity);

    my $success = GetOptions(
       "help!"       => \$opt_help,
       "nousage"     => \$opt_nousage,
       "debug=i"     => \$opt_debug,
       "verbosity=i" => \$opt_verbosity,
    );

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );

    ## quit with usage message, if usage not satisfied
    &usage(0) if $opt_help;
    &usage(1) unless( $success );

    return( $opt_nousage );
}

#-----------------------------------------------------------
sub usage($){
    my $exitval = shift;

    print << "EOP" ;
#*********************** SCRIPT DESCRIPTION ********************************#
#   Script Name : Sorted_Aging_data.pl #
#   This Script Generates three files in the current working directory for TMI Flow, and Only two files (The First two) for MOSRA Flow:

#   1) Report_Status_\$date_time.csv
#           : Where the variable \$date_time will contain date and time at which it will be created, e.g. : Report_Status_2018-09-2112:16:52.csv
#           : Will list the results in Pass/Fail Manner for the files.
#           : Fail : for those files which have atleast one device which matches the  criteria i.e. idsat(HCI+BTI) > 10% or idlin (HCI+BTI) > 10% or dvtlin > 100mV
#           : Pass : for those files which have none of the devices following the criteria i.e. idsat(HCI+BTI) > 10% or idlin (HCI+BTI) > 10% or dvtlin > 100mV
#           : If any of the files/corners is missing in sorted order, than it will display at the end, for which no data/device is present else it will display "All corners/files are present"
#    2) Sorted_degradation_data_\$date_time.csv   
#           : Where the variable \$date_time will contain date and time at which it will be created, e.g. : Sorted_degradation_data_2018-09-2112:16:52.csv
#           : Will list out all devices names with parameters whose idsat(HCI+BTI) > 10% or idlin (HCI+BTI) > 10% or dvtlin > 100mV
#           : Will list out only the HCI+BTI values of idsat or idlin or dvtlin
#           : For files with no device of above criteria will only message : No device found 
#           : Will list out Max dtemp and device associated with it at the end.
#    3) Sorted_degradation_detailed_data_\$date_time.csv
#           : Where the variable \$date_time will contain date and time at which it will be created, e.g. : sorted_degradation_data_2018-09-2112:16:52
#           : This file will store all information about devices that includes dtemperature. didsat, didlin, dvtlin for HCI+BTI, HCI. BTI.
#           : Will list out all devices names with parameters whose idsat(HCI+BTI) > 10% or idlin (HCI+BTI) > 10% or dvtlin > 100mV
#           : Will Also list out maximum dtemperauture and device associated with it at end
#           : If no devices is found in any file, Than simply message will pop up No device found for above criteria.
#
#    Note : The results are in Sorted order according to corner files.
#    Contact: Rishabh Pathak rishabp\@synopsys.com
#*********************** SCRIPT DESCRIPTION ********************************#
EOP

    exit( $exitval );
}
