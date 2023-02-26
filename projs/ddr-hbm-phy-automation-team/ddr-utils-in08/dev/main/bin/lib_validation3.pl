#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;

use English;
use Getopt::Long;
use Cwd;
use Pod::Usage;
use Time::localtime;
use Data::Dumper ;
use Liberty::Parser; 
use Parse::Liberty;
use File::Temp qw/ tempfile tempdir /;
use File::Find;
use Getopt::Long;
use Text::CSV;
use List::MoreUtils qw(:all);
use List::MoreUtils qw{ uniq };
use Sort::Fields;
use File::Copy qw{ move };
use Scalar::Util qw{ looks_like_number };
use List::MoreUtils qw(first_index indexes);
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $PREFIX       = "ddr-utils-in08";
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#


my %checkfile;
my @bbsimlist;
my @screen_arc_all = ();
my @screen_arc = ();
my %output_load_hash;
my %input_transition_hash;
my $opt_help;
my $arcarguement;
my $cornerlist;
my $csvfile;
my $csvdir;
my $voltage;
my $arcfile;
my $bbsim;
my @csvfiles = ();
my %corner_val_hash = ();
my @append = ();
my @corner_function = ();
my @extract_param = ();
my $foundappendline;
my $freq_val;
my $ip;
my @lib_function = ();
my @param_function = ();
my @pin_name = ();
my $pvtvalue;
my @split_param = ();
my @temp_function = ();
my $temp;
my $voltage_line;
my $ipline;
my $tempcsv;
my %data_val_hash;
my @split_mt0_line;
my @index_mt0_line = ();
my @write_array = ();
my %mt0_val_hash = ();
my %mt_hash = ();
if (!GetOptions( "help|h"         => \$opt_help,
                 "csv=s"          => \$csvfile,
                 "csvdir=s"       => \$csvdir,
                 "arcfile=s"      => \$arcfile,
                 "voltage=s"        => \$voltage
                     )) {
    print STDERR &usage;
    exit -1;
}
BEGIN {
    our $AUTHOR='Sneha Raghunath';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main();
END {
   footer();
   write_stdout_log( $LOGFILENAME );
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
}
sub Main(){
    utils__script_usage_statistics( "$PREFIX-$PROGRAM_NAME", $VERSION);
if(defined $opt_help) {}
if(!defined $csvfile) {
if(!defined $csvdir) {my $csvdir = "csvfiles"}
if(!defined $voltage) {my $voltage = "vdd_core"}
@csvfiles = glob ("${csvdir}/*.csv");
my $no_of_corner = @csvfiles;
} else {
    @csvfiles = Tokenify($csvfile);
}
push @write_array, "pin_name,related_pin,timing_type,timing_sense,min_delay_flag,direction,cell_rise,cell_fall,rise_constraint,fall_constraint,rise_transition,fall_transition,index1,index2,output_load(fF),input_transition(ps),corner,voltage,temperature,cell_rise_mt,cell_fall_mt,abs_diff_rise,percentage_diff_rise,abs_diff_fall,percentage_diff_fall\n";
#iprint "CSV file : @csvfiles\n";
foreach my $csv (@csvfiles) {
    if(-e $csv) {
        iprint "Reading csv file: $csv\n";
    } else {eprint "csv file $csv not found.\n"; exit;}
    my ($stdout1, $stderr1,$tempcsv) = capture { run_system_cmd   ("cut -d ',' -f 1-19 $csv \| sort -u \| awk -F ',' '\$5==\"False\" && \$4==\"positive_unate\" || \$4==\"N/A\"' ", "$VERBOSITY");};
    my @split_tempcsv = split /\n/, $tempcsv;
    foreach my $push_split_tempcsv (@split_tempcsv) {
        push @screen_arc_all, $push_split_tempcsv;  
    }
}
    if (defined $arcfile) {
        if(-e $arcfile) {
            iprint "Reading arcfile file: $arcfile\n";
            my @ip_array = read_file($arcfile);
                foreach my $ipline (@ip_array) {
                if($ipline !~ /^#/) {
                    my @split_bbsim = split/\:/, $ipline;
                    my $bbsim = $split_bbsim[0];
                    push @bbsimlist, $bbsim;
                    my @arclist = Tokenify($split_bbsim[1]);
                    foreach my $arc (@arclist) {
                        chomp $arc;
                        push @screen_arc, grep { /$arc/ } @screen_arc_all;
                    }
                }
            }
        } else { eprint "Please define arc file.\n"; exit; }
    } else { eprint "Error: Insufficient arguements\n"; exit; }
foreach my $bbsimfile (@bbsimlist) {
    chomp @bbsimlist;  
    if(-e $bbsimfile) {
        iprint "Reading bbsim file: $bbsimfile\n";
    } else { eprint "bbSim file not found.\n"; exit; }

    my ($tb,@data_name_mt) = finddatafile($bbsimfile);
#    iprint "tb: $tb @data_name_mt\n";
    my $corner_name = findcornerfile($bbsimfile);
    if(-e "$corner_name") {
    iprint "Reading corner file: $corner_name\n";
    } else {iprint "File $corner_name not found.\n"; exit;}
    chomp $corner_name;
    chomp @data_name_mt;
    my @read_corner_file = read_file("${corner_name}");
    my @lib_function = ();
    my @temp_function = ();
    my @param_function = ();
    my @corner_function = ();
    my $count = 0;
    @read_corner_file = grep {!/^#/} @read_corner_file;
    @read_corner_file = grep {!($_ =~ /^\s*$/)} @read_corner_file;

        foreach my $readcorner (@read_corner_file) {
                $count++;
#                print "$count $readcorner\n";
                if ($readcorner =~ /TEMP/) {$temp = $count}
                if ($readcorner =~ /$voltage/) {$voltage_line = $count}
                push @lib_function,$readcorner if ($readcorner =~ /^tsmc5ff12 LIB/);
                push @temp_function,$readcorner if ($readcorner =~ /^tsmc5ff12 TEMP/);
                push @param_function,$readcorner if ($readcorner =~ /^tsmc5ff12 PARAM/);
                push @corner_function,$readcorner if ($readcorner =~ /^tsmc5ff12 CORNER/);
                if($readcorner =~ /^tsmc5ff12 CORNER/) {
                    $foundappendline = 1;
            }
        }
        $voltage_line += 1; $temp += 1;
        my $lib_function_length = @lib_function;
        my $temp_function_length = @temp_function;
        my $param_function_length = @param_function;
        my $i = 0;
        my %rev_mt_hash = ();
    foreach my $corner (@corner_function) {
            chomp $corner;
            $corner =~ s/\h+/ /g;
            my @split_corner = Tokenify($corner);
            $split_corner[2] =~ s/.*\_//g; 
            $split_corner[$voltage_line] =~ s/\./p/g;
            $split_corner[$temp] =~ s/-/n/g;
            $pvtvalue = "$split_corner[2]$split_corner[$voltage_line]v$split_corner[$temp]c";
            $mt_hash{"$tb.mt$i"} = $pvtvalue;
#            print "$pvtvalue = $split_corner[2] $voltage_line $split_corner[$voltage_line]v $temp $split_corner[$temp]c\n";
            $i++;
        }

        foreach my $data_name(@data_name_mt) {
            my @split_mts = split /\//, $data_name;
            my $tb_mt_filename = $split_mts[-1];
            my @read_mt0 = read_file($data_name);
            @read_mt0 = @read_mt0[-2..-1];
            s{^\s+|\s+$}{}g foreach @read_mt0;
            s{\s+|\s+$}{ }g foreach @read_mt0;
            my @split_header = split / /, $read_mt0[0];
            my @split_value = split / /, $read_mt0[1];
#           print "@read_mt0\n";
            if($#split_header != $#split_value) {
                eprint "Error: All values not defined for $data_name\n"; exit;
            }
            my @array3 = map { $split_header[$_]." ".$split_value[$_] } 0..$#split_value;
            my $pvt = $mt_hash{$tb_mt_filename};
            for (my $i = 0; $i <= $#split_value; $i = $i + 1) {
                if( !(looks_like_number($split_header[$i]) )) {
                $split_value[$i] = $split_value[$i] * '1e12' if ($split_value[$i] !~ /error/);
            }
                $mt0_val_hash{$split_header[$i]}{$pvt} = $split_value[$i];                     
#               print "\$mt0_val_hash{$split_header[$i]}{$pvt} = $split_value[$i]\n" if ($split_header[$i] =~ /cell/);
            }
    }        
    foreach my $arc_value (@screen_arc) {
#        print "$arc_value\n";
        my @split_arc_value = split /,/,  $arc_value;
        $split_arc_value[16] =~ s/^ssg/ss/g;
        $split_arc_value[16] =~ s/^ffg/ff/g;
        $split_arc_value[16] =~ s/^ttg/tt/g;
        my $cell_rise = "cell_rise_$split_arc_value[0]_$split_arc_value[1]";
        my $cell_fall = "cell_fall_$split_arc_value[0]_$split_arc_value[1]";
        $data_val_hash{$cell_rise}{$split_arc_value[16]} = $split_arc_value[6];
        $data_val_hash{$cell_fall}{$split_arc_value[16]} = $split_arc_value[7];
        my $lc_cell_rise = lc($cell_rise);
        my $lc_cell_fall = lc($cell_fall);
#        print "\$lc_cell_fall = $lc_cell_fall\n";
#       print "\$data_val_hash{cell_rise_$split_arc_value[0]_$split_arc_value[1]}{$split_arc_value[16]} = $split_arc_value[6] \n";
#       print "\$mt_val_hash{$lc_cell_rise}{$split_arc_value[16]} =  $mt0_val_hash{$lc_cell_rise}{$split_arc_value[16]}\n";
#       print "\$data_val_hash{cell_fall_$split_arc_value[0]_$split_arc_value[1]}{$split_arc_value[16]} = $split_arc_value[7] \n";   
#       print "\$absolute_cell_rise_diff = $data_val_hash{$cell_rise}{$split_arc_value[16]} - $mt0_val_hash{$lc_cell_rise}{$split_arc_value[16]}\n";
        my $absolute_cell_rise_diff = $data_val_hash{$cell_rise}{$split_arc_value[16]} - $mt0_val_hash{$lc_cell_rise}{$split_arc_value[16]};
        my $absolute_cell_fall_diff = $data_val_hash{$cell_fall}{$split_arc_value[16]} - $mt0_val_hash{$lc_cell_fall}{$split_arc_value[16]};
        my $percentage_cell_rise_diff = ($absolute_cell_rise_diff/$data_val_hash{$cell_rise}{$split_arc_value[16]})*100;
        my $percentage_cell_fall_diff = ($absolute_cell_fall_diff/$data_val_hash{$cell_fall}{$split_arc_value[16]})*100;
#       print "\$absolute_cell_rise_diff = $data_val_hash{$cell_rise}{$split_arc_value[16]} - $mt0_val_hash{$cell_rise}{$split_arc_value[16]}\n";
#       print "\$absolute_cell_fall_diff = $data_val_hash{$cell_fall}{$split_arc_value[16]} - $mt0_val_hash{$cell_fall}{$split_arc_value[16]}\n";
#       print "$arc_value,$mt0_val_hash{$cell_rise},$mt0_val_hash{$cell_fall},$absolute_cell_rise_diff,$percentage_cell_rise_diff\n";
       push @write_array, "$arc_value,$mt0_val_hash{$lc_cell_rise}{$split_arc_value[16]},$mt0_val_hash{$lc_cell_fall}{$split_arc_value[16]},$absolute_cell_rise_diff,$percentage_cell_rise_diff,$absolute_cell_fall_diff,$percentage_cell_fall_diff";
    }
    iprint "Writing to csv file: final_comparison.csv.\n";
    write_file(\@write_array, "final_comparison.csv");

    }
}
#my $num = '1.9849e-10';
#my $num_dec = $num * '10e12';
#my $num_dec = sprintf("%.20f", $num);
#print "\nnum = $num_dec\n";


sub Tokenify {
    ## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = shift;
    $line =~ s/^\s*(.*)\s+$/$1/;
    return split(/\s+/, $line);
}



sub finddatafile {
    my $bbSim = shift;
    my @mt_files =();
    my ($sp_name,$spfile_name);
    my ($stdout0, $stderr0,$dataline) = capture { run_system_cmd   ("grep '^TESTBENCH' $bbSim", "$VERBOSITY");};
    my ($stdout1, $stderr1,$spiceline) = capture { run_system_cmd   ("grep '^SPICE_COMMAND_FILE' $bbSim", "$VERBOSITY");};
    chomp $dataline;
    if(defined $dataline && $dataline =~ /^TESTBENCH\s+(.*)/) {
#        print "$1\n";
        @mt_files = glob "../data/$1/*.mt*";
    }
    if(defined $spiceline && $spiceline =~ /^SPICE_COMMAND_FILE\s+(.*).sp/) {
        $spfile_name = $1;
        if($spfile_name =~ /^\.\.\/circuit\/(.*)/ || $spfile_name =~ /^\//) {
            my @split_sp_file = split /\//, $spfile_name;
            $sp_name =  $split_sp_file[-1];
#            print "\$sp_name = $sp_name\n";
        } else { $sp_name = $spfile_name;  }
    }
    return ($sp_name, @mt_files); #else { return undef }
}



sub findcornerfile {
    my $bbsim = shift;
    my ($stdout0, $stderr1,$cornerline) = capture { run_system_cmd   ("grep '^CORNERS_LIST_FILE' $bbsim", "$VERBOSITY");};
    chomp $cornerline;
    if(defined $cornerline && $cornerline =~ /^CORNERS_LIST_FILE\s+(.*)/) {
        my $corner_file = $1;
        if($corner_file =~ /^\.\.\// || $corner_file =~ /^\//) {
            return "$corner_file";
        } else { return "../corners/$corner_file"; }
    }
}







