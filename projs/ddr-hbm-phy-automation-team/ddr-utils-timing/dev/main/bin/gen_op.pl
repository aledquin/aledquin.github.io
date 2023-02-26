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
   write_stdout_log("$LOGFILENAME");
   local $?;   ## adding this will pass the status of failure if the script
               ## does not compile; otherwise this will always return 0
   footer(); 
}

sub Main {
    my $beol;
    my @corner;
    my $corner;
    my $curr_corner;
    my $dir;
    my @fields;
    my $hdr_flag;
    my $hr;
    my $mosparam;
    my $mostype;
    my $R;
    my $str;
    my $str_param;
    my $temp;
    my $val;
    my $val_str;
    my $vdd;
    my $vds;
    my $vdsat;
    my $veff;
    my $vgs;
    my $vth;
    my $help;
    my @orig_argv = @ARGV;
    my $opt_nousage;
    my $ScriptPath = "";
    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    my $opt_help = "";
    ($opt_nousage) = process_cmd_line_args();
    unless( $opt_nousage or $main::DEBUG ) {
        utils__script_usage_statistics( "$PROGRAM_NAME", $main::VERSION, \@orig_argv );
    }
    run_system_cmd("rm ./results/op_summary.csv", "$VERBOSITY");
    my @read_corner = read_file("corner_list.txt");
#    open my $file, "<", "corner_list.txt" or die $!;
    my $idx=0;
    foreach my $file (@read_corner) {
        chomp $file;
        $corner[$idx] = $file;
        $idx++;
    }    
    my $num = $idx;    
    my $end = 0;
    my $idx = 0;
    my $found_measure = 0;
    my $found_param_col = 0;
    my $found_trans = 0;
    my $found_op = 0;
    my $hdr_str = "";
    my @op = ();
#    open my $FILE, ">", "./results/op_summary.csv" or die $!;
    
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
#        open my $DATAFILE, "<", "$dir/out.dp0" or die $!;
    
    #    push @op, "*****************************\n";
    #    push @op, "Corner = $dir\n";
    #    push @op, "*****************************\n";
        $str = $dir;
        $str_param = "";
        $found_trans = 0;
        $found_op = 0;
        $hdr_flag = 0;
        $hdr_str = "";
        $val_str = "";
        my $done = 0;
        
#        open my $FILE_LOCAL, ">", "${dir}/op_summary.csv" or die $!;
        my @FILE_LOCAL = ();
        push @op, ",,,,,,,,\n";
        push @op, "${dir},,,,,\n";
    
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
                    if ($hdr_flag == 0) {
                        push @op, "$hdr_str,veff,hdrm\n";
                        push @FILE_LOCAL, "$hdr_str,veff,hdrm\n";
                        $hdr_flag = 1;
                    }
                    push @op, "$val_str,${veff}m,${hr}m\n";
                    push @FILE_LOCAL, "$val_str,${veff}m,${hr}m\n";
                    $hdr_str = "";
                    $val_str = "";
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
                    if (($mosparam eq "subckt") || ($mosparam eq "element") || ($mosparam eq "region") || ($mosparam eq "id") || ($mosparam eq "vgs") || ($mosparam eq "vds") || ($mosparam eq "vth") || ($mosparam eq "vdsat") || ($mosparam eq "gm") || ($mosparam eq "model") || ($mosparam eq "gds")) {
                        $hdr_str = $hdr_str . ",$mosparam";
                        $val_str = $val_str . ",$val";
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
        my $writefile_out = Util::Misc::write_file(\@FILE_LOCAL, "${dir}/op_summary.csv");
    }       
    my $writefile_out0 = Util::Misc::write_file(\@op, "./results/op_summary.csv");
    }

sub print_usage {
    my $exit_status = shift;
    my $ScriptPath = shift;
    my $message_text = "This is script to read file corner.txt and populate op_summary.csv file.\n";
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
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    &print_usage(0, "$RealBin/$PROGRAM_NAME") if $opt_help;
    &print_usage(1, "$RealBin/$PROGRAM_NAME") unless( $success );
    #&usage(1) unless( defined $opt_projSPEC );
   return( $opt_nousage );
};

