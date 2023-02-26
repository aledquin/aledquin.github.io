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
use List::Util qw( first );
use Scalar::Util qw{ looks_like_number };
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
our $VERSION      = get_release_version();
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
#--------------------------------------------------------------------#

utils__script_usage_statistics( $PROGRAM_NAME, $VERSION);

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

if (!GetOptions( "help|h"         => \$opt_help,
                  "arclist=s"      => \$arcarguement,
                 "cornerlist=s"   => \$cornerlist,
                 "csv=s"          => \$csvfile,
                 "csvdir=s"       => \$csvdir,
                 "voltage=s"        => \$voltage,
                 "arcfile=s"      => \$arcfile,
                 "bbsim=s"       => \$bbsim
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
if(defined $opt_help) {}

if(!defined $voltage) {my $voltage = "vdd_core"}

if(!defined $csvfile) {
if(!defined $csvdir) {my $csvdir = "csvfiles"}
@csvfiles = glob ("${csvdir}/*.csv");
my $no_of_corner = @csvfiles;
} else {
    @csvfiles = Tokenify($csvfile);
}
print "CSV file : @csvfiles\n";
foreach my $csv (@csvfiles) {
#    push @screen_arc_all, `cut -d ',' -f 1,2,15-19 $csv \| sort -u`;
    my ($stdout1, $stderr1,$tempcsv) = capture { run_system_cmd   ("cut -d ',' -f 1,2,15-19 $csv \| sort -u", "$VERBOSITY");};
    my @split_tempcsv = split /\n/, $tempcsv;
    foreach my $push_split_tempcsv (@split_tempcsv) {
        push @screen_arc_all, $push_split_tempcsv;  
    }
#    my testsplice = splice()
}
chomp @screen_arc_all;
#print "$screen_arc_all[1]\n";
    if (defined $arcfile) {
        if(-e $arcfile) {
            my @ip_array = read_file($arcfile);
            # open($ip, "<", "$arcfile")  or die "Can't open $arcfile file to read\n";
            foreach my $ipline (@ip_array){
            # while ($ipline = <$ip>) {
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
#            close $ipline;
        } else { print "Please define arc file.\n"; exit; }
    } else { print "Error: Insufficient arguements\n"; exit; }

foreach my $bbsimfile (@bbsimlist) {
    chomp @bbsimlist;   
    my $corner_name = findcornerfile($bbsimfile);
    chomp $corner_name;
    foreach my $arc_value (@screen_arc) {
        my @split_arc_value = split /,/,  $arc_value;
        $split_arc_value[4] =~ s/^ssg/ss/g;
        $split_arc_value[4] =~ s/^ffg/ff/g;
        $split_arc_value[4] =~ s/^ttg/tt/g;
        $corner_val_hash{$corner_name}{$split_arc_value[4]}{"output_load_$split_arc_value[0]"} = $split_arc_value[2];
        $corner_val_hash{$corner_name}{$split_arc_value[4]}{"input_transition_$split_arc_value[1]"} = $split_arc_value[3];
        $corner_val_hash{$corner_name}{$split_arc_value[0]}{$split_arc_value[1]}{$split_arc_value[4]}{output_load} = $split_arc_value[2];
        $corner_val_hash{$corner_name}{$split_arc_value[0]}{$split_arc_value[1]}{$split_arc_value[4]}{input_transition} = $split_arc_value[3];
#       print "\$corner_val_hash{$corner_name}{$split_arc_value[4]}{output_load_$split_arc_value[0]} = $split_arc_value[2] \n";
    }
    print "Corner file name: $corner_name\n";
    my ($stdout2, $stderr2) = capture { run_system_cmd   ("mv $corner_name ${corner_name}_backup", "$VERBOSITY");};
    my ($stdout3, $stderr3) = capture { run_system_cmd   ("sed -i '/^\$/d' ${corner_name}_backup", "$VERBOSITY");};
#    exit;
    sleep 3;
    # open(my $writecorner,">","${corner_name}") or die "Can't open $corner_name file to read\n";
    my $corner_name_backup = "${corner_name}_backup";
    my @corner_arr = read_file ($corner_name_backup);
    my $corner_name_file = "${corner_name}";
    my @writecorner;
    # open(my $ip,"<","${corner_name}_backup") or die "Can't open $corner_name file to read\n";
    @lib_function = ();
    @temp_function = ();
    @param_function = ();
    @corner_function = ();
    @append = ();
    @extract_param = ();
    my @writercorner = ();

        # while (my $readcorner = <$ip>) {
        foreach my $readcorner (@corner_arr){
            $readcorner =~ s/^\s+//g;
            unless($readcorner =~ /^#/) {
                $temp = $. if ($readcorner =~ /TEMP/);
                $voltage_line = $. if ($readcorner =~ /$voltage/);
                push @lib_function,$readcorner if ($readcorner =~ /^tsmc5ff12 LIB/);
                push @temp_function,$readcorner if ($readcorner =~ /^tsmc5ff12 TEMP/);
                push @param_function,$readcorner if ($readcorner =~ /^tsmc5ff12 PARAM/);
                push @corner_function,$readcorner if ($readcorner =~ /^tsmc5ff12 CORNER/);
                if($readcorner =~ /^tsmc5ff12 CORNER/) {
                    $foundappendline = 1;
                }
            }
        }
        
        foreach my $ln (@lib_function){
            push (@writercorner, "$ln\n");
        }
        # print $writecorner "@lib_function\n";
        foreach my $ln (@temp_function){
            push (@writercorner, "$ln");
        }
        # print $writecorner "@temp_function";
        foreach my $ln (@param_function){
            push (@writercorner, "$ln\n");
        }
        # print $writecorner "@param_function\n";
        $temp += 1; $voltage_line += 1;
        my $lib_function_length = @lib_function;
        my $temp_function_length = @temp_function;
        my $param_function_length = @param_function;

        foreach my $param (@param_function) {
            chomp $param;
            if($param =~ /input_transition/i || $param =~ /output_load/i) {
                @split_param = Tokenify($param);
                push @extract_param, $split_param[-1];
            }
        }
        foreach my $corner (@corner_function) {
            @append = ();
            chomp $corner;
            $corner =~ s/\h+/ /g;
            my @split_corner = Tokenify($corner);
            $split_corner[2] =~ s/.*\_//g;
            $split_corner[$voltage_line] =~ s/\./p/g;
            $split_corner[$temp] =~ s/-/n/g;
            $pvtvalue = "$split_corner[2]$split_corner[$voltage_line]v$split_corner[$temp]c";
            my $isnum = 0;
            foreach my $append_param (@extract_param) {
                my $digit = $corner_val_hash{$corner_name}{$pvtvalue}{$append_param};
                $isnum = looks_like_number( $digit );
                if($isnum == 1) { push  @append, $digit }
#               print "\$corner_val_hash{$corner_name}{$pvtvalue}{$append_param}\n";
            }
            if(scalar @append != 0) {
                push (@writecorner, "$corner @append \n");
                # print $writecorner "$corner @append \n";
            }
        }
        # close $writecorner;
        write_file(\@writercorner, $corner_name_file);
    }
}


sub Tokenify {
    ## Splits, stripping leading and trailing whitespace first to get clean tokens
    my $line = shift;
    $line =~ s/^\s*(.*)\s+$/$1/;
    return split(/\s+/, $line);
}


sub findcornerfile {
    my $bbsim = shift;
    my ($stdout0, $stderr1,$cornerline) = capture { run_system_cmd   ("grep '^CORNERS_LIST_FILE' $bbsim", "$VERBOSITY");};
    chomp $cornerline;
    if(defined $cornerline && $cornerline =~ /^CORNERS_LIST_FILE\s+(.*)/) {
        return "../corners/$1\n";
    }
}
