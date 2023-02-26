#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Cwd;
use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#----------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG               = NONE;
our $VERBOSITY           = NONE;
our $TESTMODE            = undef;
our $PROGRAM_NAME        = $RealScript;
our $LOGFILENAME         = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION             = get_release_version();
our $AUTO_APPEND_NEWLINE = 1;
#----------------------------------#

BEGIN {
    our $AUTHOR='Multiple';
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

our ( $WR, $model_name, $flag1, $filename );
#-----------------------------------------------------------------
sub Main(){
    utils__script_usage_statistics( $PROGRAM_NAME, $VERSION );

    unlink "dcck_model_input.txt";
    my $file = $ARGV[0];
    use File::Copy;
    unlink "dynamic_circuit_check.inc.backup";
    copy( "dynamic_circuit_check.inc", "dynamic_circuit_check.inc.backup" ) or die "Copy failed: $!";
    print "Backing up dynamic_circuit_check.inc...\n";
    sleep(2);
    print "backup of dynamic_circuit_check.inc completed.\n";
    print "Please enter the CDL netlist path:\n";
    my $input = <STDIN>;

    #open(STDOUT,"| tee -ai .tempfile");
    open( STDOUT, ".tempfile" ); # nolint open<
    system("$RealBin/findmodelnames.pl $input");  # nolint
    close(STDOUT);
    open( my $writefile, ">", "dcck_model_input.txt" ) or die "Could not open file '$file' $!";  # nolint
    print $writefile "*** LV Devices\n";
    my @arr;
    my @arr2;
    foreach my $line ( read_file(".tempfile") ){
        chomp($line);
        my @fields = split /:/, $line;
        push @arr, $fields[0];
    }
    @arr = uniq(@arr);
    foreach my $q (@arr) {
        if ( $q =~ /lv/ ) {
            print $writefile "$q\n";
        }
        elsif ( $q =~ /svt/ ) {
            print $writefile "$q\n";
        }
        else { push @arr2, $q }
    }
    print $writefile "*** HV Devices\n";
    @arr2 = uniq(@arr2);
    foreach my $s (@arr2) {
        print $writefile "$s\n";
    }
    close $writefile;
    my $flag  = 0;
    my $cnt   = 0;
    my $start = 0;
    my $pathfound;
    
    open( $WR, ">", $file ) or die "Could not open file '$file' $!"; # nolint
    foreach my $line ( read_file("./$file") ){
        if ( $line =~ m/^\*\*\* / ) {
            $start = 1;
            next;
        }
        if ( $start == 0 ) {
            print $WR $line;
        }
        if ( $start == 2 ) {
            print $WR $line;
        }
    }

    $flag  = 0;
    $flag1 = 0;
    ##  $file= open( my $fh, "<", "dcck_model_input.txt" )
    foreach my $temp ( read_file('dcck_model_input.txt') ){
        if ( $flag1 == 1 ) {
            $model_name = $temp;
            chomp($model_name);
            #	print $WR "HV device: $model_name\n";
            HV_Devices();
        }

        if ( $temp =~ m/HV Devices/ ) {
            $flag  = 0;
            $flag1 = 1;
        }

        if ( $flag == 1 ) {
            $model_name = $temp;
            chomp($model_name);
            #	print $WR "LV Device: $model_name\n";
            LV_Devices();
        }

        if ( $temp =~ /LV Devices/ ) {
            $flag = 1;
        }
    }  # END foreach 

    foreach my $tempfile ( read_file("./$file") ){
        my $end;
        if ( $tempfile =~ m/DC path check/i ) {
            $end = 1;
        }
        if ( $end == 1 ) {
            print $WR "$tempfile";
        }
    }

    unlink ".tempfile";
    return();
}

#-----------------------------------------------------------------
sub uniq {
    my %seen;
    grep {!$seen{$_}++} @_;
}

#-----------------------------------------------------------------
sub LV_Devices {
    print $WR "*** $model_name\n";
    print $WR "*Condition 1\n";
    print $WR ".chkdevop type=m model=$model_name vgs=(xlv_c1_sob_min, xlv_c1_sob_max) period=xc1_tth\n";
    print $WR ".chkdevop type=m model=$model_name vds=(xlv_c1_sob_min, xlv_c1_sob_max) period=xc1_tth\n";
    print $WR ".chkdevop type=m model=$model_name vgd=(xlv_c1_sob_min, xlv_c1_sob_max) period=xc1_tth\n";
    print $WR "\n*Condition 2\n";
    print $WR ".chkdevop type=m model=$model_name vgs=(xlv_c2_sob_min, xlv_c2_sob_max) period=xc2_tth\n";
    print $WR ".chkdevop type=m model=$model_name vds=(xlv_c2_sob_min, xlv_c2_sob_max) period=xc2_tth\n";
    print $WR ".chkdevop type=m model=$model_name vgd=(xlv_c2_sob_min, xlv_c2_sob_max) period=xc2_tth\n";
    print $WR "\n";
}

#-----------------------------------------------------------------
sub HV_Devices {
    print $WR "\n*** $model_name\n";
    print $WR "\n*Condition 1\n";
    print $WR ".chkdevop type=m model=$model_name vgs=(xhv_c1_sob_min, xhv_c1_sob_max) period=xc1_tth\n";
    print $WR ".chkdevop type=m model=$model_name vds=(xhv_c1_sob_min, xhv_c1_sob_max) period=xc1_tth\n";
    print $WR ".chkdevop type=m model=$model_name vgd=(xhv_c1_sob_min, xhv_c1_sob_max) period=xc1_tth\n";
    print $WR "\n*Condition 2\n";
    print $WR ".chkdevop type=m model=$model_name vgs=(xhv_c2_sob_min, xhv_c2_sob_max) period=xc2_tth\n";
    print $WR ".chkdevop type=m model=$model_name vds=(xhv_c2_sob_min, xhv_c2_sob_max) period=xc2_tth\n";
    print $WR ".chkdevop type=m model=$model_name vgd=(xhv_c2_sob_min, xhv_c2_sob_max) period=xc2_tth\n";
    print $WR "\n";
}

