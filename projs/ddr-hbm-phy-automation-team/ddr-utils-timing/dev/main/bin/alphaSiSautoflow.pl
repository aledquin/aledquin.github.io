#!/depot/perl-5.14.2/bin/perl
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
use Carp qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );
use Capture::Tiny qw/capture/;
use List::Util qw( min max );

use lib "$RealBin/../lib/perl";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;


#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR;              # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PREFIX       = "ddr-utils-timing";
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "$PROGRAM_NAME.log";
our $VERSION      = get_release_version();             # Syntax: YYYYww##[.#] optional day 1-7
# The work week number can be found in
# your outlook calendar. The days are 1=sunday
# 2=monday ... 7=saturday

#--------------------------------------------------------------------#

BEGIN { our $AUTHOR = 'bhattach'; header(); }
&Main();
END {
    write_stdout_log("${PROGRAM_NAME}.log");
    footer();

}

#ShowUsage("$RealBin/$RealScript") unless(@ARGV);
#&ShowUsage("$RealBin/$RealScript") if ($help);;


sub Main {
    my $config;
    my $pvtconfig;

    my $opt_help;
    my $opt_debug;
    my $opt_verbosity;

    my @orig_argv = @ARGV;
    my $opt_nousage;
    my $ScriptPath = "";

    foreach (my @toks) {$ScriptPath .= "$_/"}
    $ScriptPath = abs_path($ScriptPath);
    ($config,$pvtconfig,$opt_help,$opt_nousage) = process_cmd_line_args();

    unless( $opt_nousage or $main::DEBUG ) {
        utils__script_usage_statistics( "$PROGRAM_NAME", $main::VERSION, \@orig_argv );
    }

#my $ArgOK = 1;
#$ArgOK &= CheckRequiredArg($config, "config");
#$ArgOK &= CheckRequiredArg($pvtconfig, "pvtconfig");

#if (!$ArgOK) {die "Exiting on missing required arguments\n"}

#my $FileOK = 1;
#$FileOK &= CheckFileRead($config);
#$FileOK &= CheckFileRead($pvtconfig);

#if (!$FileOK) {die "Exiting on unreadable file(s)\n"}
    my @pvtList ;
    my @config = read_file($config);
    my @PVT = read_file($pvtconfig);

    foreach my $line (@config) {
        # print "$line \n";
        my @content = split ('"',$line);
        my $pvtNum = $content[1];
        my @arraypvt = $content[1];
        my $other_content = $content[0];

        my @data = split (',',$other_content);
        my $macro = $data[0];
        my $char = $data[1];
        my $re_char = $data[2];
        my $re_post = $data[3];

        #logic for char
        if ( ($char =~/Y/) || ($char =~/Yes/) || ($char =~/yes/) || ($char =~/y/) || ($char =~/YES/) ) {
            my $pvtupadate = "$macro/run_$macro.csh";	
            run_system_cmd ("sed -i 's/-pvtNum.*/-pvtNum $pvtNum/g' $pvtupadate","$VERBOSITY");
            iprint("Submitting characterization jobs for Macro $macro \n");
            my ($print_cmd, $mesage) = run_system_cmd ("cd $macro;/bin/csh run_$macro.csh;cd ../","$VERBOSITY");
            iprint($print_cmd); ### Check later
            iprint ("Submitting Characterization jobs for the macro $macro \n\n\n\n");

        } 
        elsif ( ($re_char =~/Y/) || ($re_char =~/Yes/) || ($re_char =~/yes/) || ($re_char =~/y/) || ($re_char =~/YES/) ) {
            if(length($pvtNum) > 1) {
                @pvtList = split (",", $pvtNum);
            } else {
                @pvtList = $pvtNum;
            }
            my $count = 1;
            my $length = scalar(@pvtList); 
            foreach my $line2 (@PVT) {

                my $i = 0;
                if ($line2 =~ /^\s*create_operating_condition\s+(\S+)/) {
                    while ($i < $length) {
                        chomp ($pvtList[$i]);
                        if ($count == $pvtList[$i]) {
                            my($print_cmd, $mesage) = run_system_cmd ("cd $macro/char_$1;sed -i '/^/d' $macro.rechar;$macro/char_$1;sed -i '/^/d' $macro.repost;echo 1 >> $macro.rechar;qsub -P bnormal run_char.csh","$VERBOSITY");
                            iprint($print_cmd);
                            iprint ("Submitting Re-Characterization for the macro $macro for the given PVT $1\n\n\n\n");
                            last; 
                        } 
                        # else {
                        # eprint ("The indiex for the PVT number $pvtList[$i] is not matching, please check the config file for the macro $macro and could not proceed for Re-Char \n\n");
                        #  last;
                        # }
                        $i = $i + 1;
                    }
                    $count = $count + 1;
                }
            }
        } # re-char      
        elsif ( ($re_post =~/Y/) || ($re_post =~/Yes/) || ($re_post =~/yes/) || ($re_post =~/y/) || ($re_post =~/YES/) ) {
            if(length($pvtNum) > 1) {
                @pvtList = split (",", $pvtNum);
            } else {
                @pvtList = $pvtNum;
            }
            my $count = 1;
            my $length = scalar(@pvtList); 
            foreach my $line2 (@PVT) {

                my $i = 0;
                if ($line2 =~ /^\s*create_operating_condition\s+(\S+)/) {
                    while ($i < $length) {
                        chomp ($pvtList[$i]);
                        if ($count == $pvtList[$i]) {
                            my($print_cmd, $mesage) = run_system_cmd ("cd $macro/char_$1;sed -i '/^/d' $macro.repost;sed -i '/^/d' $macro.rechar;echo 1 >> $macro.repost;qsub -P bnormal run_char.csh","$VERBOSITY");
                            iprint($print_cmd);
                            iprint ("Submitting Re-Post Processing for the macro $macro for the given PVT $1\n\n\n\n");
                            last; 
                        } 
                        # else {
                        # eprint ("The indiex for the PVT number $pvtList[$i] is not matching, please check the config file for the macro $macro and could not proceed for Re-Char \n\n");
                        #  last;
                        # }
                        $i = $i + 1;
                    }
                    $count = $count + 1;
                }
            }
        } # re-char      
    } #foreach config
} #main sub

#sub CheckRequiredArg
#{
#    my $ArgValue = shift;
#    my $ArgName = shift;
#    if (!defined $ArgValue)
#    {
#	eprint("Error:  Required argument \"$ArgName\" not supplied\n");
#	return 0;
#    }
#    return 1;
#}

sub CheckFileRead
{
    my $filename = shift;
    if (!(-r $filename))
    {
        eprint("Error: Cannot open $filename for read\n");
        return 0;
    }
    return 1;
}


sub print_usage($$) {
    my $script_path = shift;
    my $status      = shift;
    iprint << "EOP" ;

Description

USAGE : $PROGRAM_NAME -config <config-file> -pvtconfig <pvt_config_file>

------------------------------------
Required Args:
------------------------------------
-config    <arg>  
-pvtconfig     <arg>

The config file (a csv file) should look like this
------------------------------------
Macro,Char,Re-Char,Re-Post,PVT
macro_1,Y,,,"1,2,3,4,5"
macro_2,,Yes,,"3,4,8"
macro_3,,,y,"1,3,5"
macro_4,yes,,,"1"
macro_5,NA,N,N,na
------------------------------------

Pleas provide the SiS_configure_pvt.tcl file as pvtconfig file.


------------------------------------
Optional Args:
------------------------------------
-help             iprint this screen
-verbosity  <#>    iprint additional messages ... includes details of system calls etc. 
                   Must provide integer argument -> higher values increases verbosity.
-debug      <#>    iprint additional diagnostic messagess to debug script
                   Must provide integer argument -> higher values increases messages.
------------------------------------------
EOP

    pod2usage({
            -pathlist => "$RealBin",
            -exitval => $status,
            -verbose => 1 });
}


sub process_cmd_line_args(){
    my ( $config, $pvtconfig, $opt_help, $opt_nousage, $opt_dryrun, $opt_debug, $opt_verbosity );

    my $success = GetOptions(
        "config=s"      => \$config,
        "pvtconfig=s"   => \$pvtconfig,
        "help"        => \$opt_help,           # Prints help
        "nousage"     => \$opt_nousage,
        "debug=i"     => \$opt_debug,
        "verbosity=i" => \$opt_verbosity,
        "dryrun!"     => \$opt_dryrun,
    );

    if((defined $opt_dryrun) && ($opt_dryrun == 1)){
        $main::TESTMODE = TRUE;
    }

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    &print_usage(0, "$RealBin/$PROGRAM_NAME") unless( $success );
    &print_usage(1, "$RealBin/$PROGRAM_NAME") if $opt_help;
    #&usage(1) unless( defined $opt_projSPEC );
    return( $config, $pvtconfig, $opt_help, $opt_nousage, $opt_dryrun, $opt_debug, $opt_verbosity );
};
