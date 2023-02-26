#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

use File::Basename;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd;
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $PREFIX       = "ddr-utils-timing";
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11';
#--------------------------------------------------------------------#

use Capture::Tiny qw/capture/;
use File::Basename qw(dirname basename);
use FindBin qw($RealBin $RealScript);

BEGIN { our $AUTHOR='IN08 Timing team'; header(); } 
&Main();
END {
   write_stdout_log($LOGFILENAME);
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}

sub Main {
    my $beol;
    my @corner;
    my $corner;
    my $curr_corner;
    my @fields = ();
    my ($hr, $dir);
    my $mosparam;
    my $mostype;
    my $R;
    my ($str_param,$str);
    my $temp;
    my $val;
    my $vdd;
    my $vds;
    my $vdsat;
    my $veff;
    my $vgs;
    my $vth;
    my @device_alias;
    my @device_arr;
    my $found_hdr;
    my @mosparam_arr;
    my $n;
    my $num_params;
    my %val;
    my $valid;
    my @orig_argv = @ARGV;
    my $opt_nousage;
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    ($opt_nousage) = process_cmd_line_args();
    unless( $opt_nousage or $main::DEBUG ) {
         utils__script_usage_statistics( "$PROGRAM_NAME", $main::VERSION, \@orig_argv );
    }
    my @read_device = read_file("device.list");
    my $device_cnt = 0;    
    foreach my $FILE (@read_device) {
        chomp $FILE;
        @fields = split /[ ]+/, $FILE;
        $device_arr[$device_cnt] = $fields[0];
        $device_alias[$device_cnt] = $fields[1];
        $device_cnt++;
    }    
    my($stdout1, $stderr1) = capture { run_system_cmd("rm ./results/op_summary_device.csv","$VERBOSITY"); };
    my @FILEOUT = ();
    
    for ( my $m=0; $m<$device_cnt; $m++) {
    
    my $device = $device_arr[$m];
    
    push @FILEOUT, ",,,,\n";
    push @FILEOUT, ",,,,\n";
    push @FILEOUT, ",,,,\n";
    push @FILEOUT, "$device -- $device_alias[$m],,,\n";
    my @read_corner = read_file("corner_list.txt");
    my $idx=0;
    
    foreach my $FILE (@read_corner) {
        chomp $FILE;
        if ($_ !~ /^\*/) {
            $corner[$idx] = $FILE;
            $idx++;
        }
    }
    my $num = $idx;
    my $end = 0;
    $idx = 0;
    my $found_measure = 0;
    my $found_param_col = 0;
    my $found_trans = 0;
    my $found_op = 0;
    
    my $hdr_str = "";
    my @FILEOUT = ();
    while ($end == 0) {
    
        $curr_corner = $corner[$idx];
    
        @fields = split /_/, $curr_corner;
        $corner = $fields[0];
        $R = $fields[1];
        $vdd = $fields[2];
        $beol = $fields[3];
        $temp = $fields[4];
    
        $dir = "Run_${corner}_${R}_${vdd}_${beol}_${temp}";
        my @read_out = read_file("$dir/out.dp0");
    #    print FILE "*****************************\n";
    #    print FILE "Corner = $dir\n";
    #    print FILE "*****************************\n";
        my $str = $dir;
        $str_param = "";
        $found_trans = 0;
        $found_op = 0;
        my $hdr_flag = 0;
        my $hdr_str = "";
        my $val_str = "";
        my $done = 0;
        
        ##print FILE ",,,,,,,,\n";
        ##print FILE "${dir},,,,,\n";
    
        $valid = 0;
        my $j=0;
    
        foreach my $DATAFILE (@read_out) {    
            chomp $DATAFILE;        
            if ($DATAFILE =~ /mosfets/) {
                if ($done == 1) {
                    $found_op = 1;
                }
                $done = 1;
            }    
            if ($found_op == 1) {                
                if (($found_trans == 1) && ($DATAFILE =~ /^$/)) {
                    $found_trans = 0;
                    if ($mostype eq "pch") {
                        $veff = -1*($vgs-$vth)*1e3; #in mV
                        $hr = -1*($vds-$vdsat)*1e3;
                    } else {
                        $veff = ($vgs-$vth)*1e3; #in mV
                        $hr = ($vds-$vdsat)*1e3;
                    }
                    if ($valid == 1) {
                        $mosparam_arr[$j] = "veff";
                        $val{$curr_corner}[$j] = $veff;                    
                        $mosparam_arr[$j+1] = "hr";
                        $val{$curr_corner}[$j+1] = $hr;                    
                        $j=$j+2;
                        $num_params = $j;
                        $valid = 0;
                    }
                }
       
                if ($found_trans == 1) {
                    @fields = split /[ ]+/, $DATAFILE;
                    $mosparam = $fields[1];
                    $val = $fields[2];
                    if ($mosparam eq "vgs") {
                        $vgs = $val;
                        $vgs =~ s/a/e-18/;
                        $vgs =~ s/f/e-15/;
                        $vgs =~ s/p/e-12/;
                        $vgs =~ s/n/e-9/;
                        $vgs =~ s/u/e-6/;
                        $vgs =~ s/m/e-3/;
                    }
                    if ($mosparam eq "vth") {
                        $vth = $val;
                        $vth =~ s/a/e-18/;
                        $vth =~ s/f/e-15/;
                        $vth =~ s/p/e-12/;
                        $vth =~ s/n/e-9/;
                        $vth =~ s/u/e-6/;
                        $vth =~ s/m/e-3/;
                    }
                    if ($mosparam eq "vds") {
                        $vds = $val;
                        $vds =~ s/a/e-18/;
                        $vds =~ s/f/e-15/;
                        $vds =~ s/p/e-12/;
                        $vds =~ s/n/e-9/;
                        $vds =~ s/u/e-6/;
                        $vds =~ s/m/e-3/;
                    }
                    if ($mosparam eq "vdsat") {
                        $vdsat = $val;
                        $vdsat =~ s/a/e-18/;
                        $vdsat =~ s/f/e-15/;
                        $vdsat =~ s/p/e-12/;
                        $vdsat =~ s/n/e-9/;
                        $vdsat =~ s/u/e-6/;
                        $vdsat =~ s/m/e-3/;
                    }
                    if ($mosparam eq "model") {
                        if ($val =~ /nch/) {
                            $mostype = "nch";
                        } else {
                            $mostype = "pch";
                        }
                    }
                    #print "MOS PARAM = $mosparam\n";
                    #print "VALUE = $val\n";
                    if (($mosparam eq "element") && ($val eq $device)) {
                        $valid = 1;
                        #print "Found it\n";
                            
                    }
                    if (($mosparam eq "region") || ($mosparam eq "id") || ($mosparam eq "vgs") || ($mosparam eq "vds") || ($mosparam eq "vth") || ($mosparam eq "vdsat") || ($mosparam eq "gm") || ($mosparam eq "gds")) {
                        if ($valid == 1)  {
                            $mosparam_arr[$j] = $mosparam;
                            $val{$curr_corner}[$j] = $val;                    
                            $j++;
                        }
                    }
                }    
                if ($_ =~ /subckt/) {
                    $found_trans = 1;
                }
            }
        }
        if ($idx >= ($num-1)) {
            $end = 1;
        }
        $idx++;
    }
    $found_hdr = 0;
    
    ##print out the transistor info as a function of corner
    for ($n=0; $n<$num_params; $n++) {
        $str = "$mosparam_arr[$n]";
        $hdr_str = "";
        for (my $k=0; $k<$idx; $k++) {
            $str = $str . ",$val{$corner[$k]}[$n]";
            $hdr_str = $hdr_str . ",$corner[$k]";
        }
        if ($found_hdr == 0) {
            push @FILEOUT, "$hdr_str\n";
            $found_hdr = 1;
        }
        push @FILEOUT, "$str\n";
    }
    
    }
    my $writefile_out = Util::Misc::write_file(\@FILEOUT, "./results/op_summary_device.csv");
}


sub print_usage {
    my $exit_status = shift;
    my $ScriptPath = shift;
    my $message_text = "Current script path:  $ScriptPath\n";
     pod2usage({
        -message => $message_text ,
        -exitval => $exit_status,
        -verbose => 0,
        }
    );
}

sub process_cmd_line_args(){
    my ( $opt_help, $opt_nousage, $opt_dryrun, 
         $opt_debug,  $opt_verbosity );

    my $success = GetOptions(
        "help"        => \$opt_help,           # Prints help
        "nousage"     => \$opt_nousage,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "dryrun!"      => \$opt_dryrun,
     );

    if((defined $opt_dryrun) && ($opt_dryrun == 1)){
        $main::TESTMODE = TRUE;
    }

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );

    ## quit with usage message, if usage not satisfied
    &print_usage(0, "$RealBin/$PROGRAM_NAME") if $opt_help;
    &print_usage(1, "$RealBin/$PROGRAM_NAME") unless( $success );
    #&usage(1) unless( defined $opt_projSPEC );
   return( $opt_nousage );
};
