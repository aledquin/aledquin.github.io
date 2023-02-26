#!/depot/perl-5.14.2/bin/perl 

use strict;
use warnings;
use Getopt::Long;
use Cwd 'abs_path';
use Pod::Usage;
use File::Copy;
use List::MoreUtils qw(zip);
use Clone 'clone';
use List::MoreUtils qw/uniq/;
use Capture::Tiny qw/capture/;
use File::Compare;
use Array::Diff;
use File::Spec::Functions qw( catfile );
use Cwd     qw( getcwd abs_path );
use Carp    qw( cluck confess croak );
use FindBin qw( $RealBin $RealScript );

use lib "$RealBin/../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

#--------------------------------------------------------------------#
our $STDOUT_LOG; # Initiailized in the BEGIN block
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $TESTMODE     = undef;
our $PROGRAM_NAME = $RealScript;
our $LOGFILENAME  = getcwd() . "/$PROGRAM_NAME.log";
our $VERSION      = get_release_version() || '2022.11'; 
#--------------------------------------------------------------------#

BEGIN {
    our $AUTHOR='snehar juliano ljames';
    #$STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
    $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
    header();
}
&Main() unless caller();
END {
    local $?;   ## adding this will pass the status of failure if the script
                ## does not compile; otherwise this will always return 0
#    write_stdout_log( $LOGFILENAME ); ## snehar has commented this as Designer wants following: Short description printed on screen and detailed version in log file. Also, single log file.
    footer();
}

#------------------------------------------------------------------------------
#  script usage message
#------------------------------------------------------------------------------
sub usage($) {
    my $exit_status = shift;

    print << "EOP" ;
Description

USAGE : $PROGRAM_NAME [options] -bbsim <arguement>

------------------------------------
Required Args:
------------------------------------
-bbsim     <arg>  

------------------------------------
Optional Args:
------------------------------------
-help             print this screen
-localpath <arg>
-verbosity  <#>    print additional messages ... includes details of system calls etc. 
                   Must provide integer argument -> higher values increases verbosity.
-debug      <#>    print additional diagnostic messagess to debug script
                   Must provide integer argument -> higher values increases messages.

EOP

        dprint(LOW, "write_stdout_log " . getcwd() . "/autosmoke.log");
    write_stdout_log("autosmoke.log");
    exit $exit_status ;
} # usage()

#-------------------------------------------------------------------------------
sub Main {
    my @p4list = ();
    my @p4list_names;
    my @split_filter;
    my @copy_argv = @ARGV;  # keep this here cause GetOpts modifies ARGV
    
    #--------------------------------------------------------------------
    my ($opt_nousage, $opt_localpath, $opt_bbsim_p4) = 
        process_cmd_line_args();

    #--------------------------------------------------------------------
    unless ( $main::DEBUG or $opt_nousage) {
        utils__script_usage_statistics( $PROGRAM_NAME, $VERSION, \@copy_argv );
    }

    unless( defined $opt_localpath ){
        $opt_localpath = ".." ;
        dprint(LOW, getcwd() . " is your present cwd, and setting opt_localpath to '..'\n");
    }

    my @extract_bbsim_name = split /\//, $opt_bbsim_p4;
    my $bbsim = $extract_bbsim_name[-1];
    my $extraArgs = "";
    $extraArgs .= " -debug $DEBUG" if ( $DEBUG );
    $extraArgs .= " -verbosity $VERBOSITY" if ( $VERBOSITY);

    my ($stdout_err, $run_status) = 
        run_system_cmd("$RealBin/bbSim_file_tree $bbsim $extraArgs", $VERBOSITY);
    @p4list = read_file( "file_tree.log" );
    chomp @p4list;   # remove linefeed in every element of the array
    if( scalar @p4list == 0 ){
        dprint(LOW, "write_stdout_log " . getcwd() . "/autosmoke.log");
        write_stdout_log("autosmoke.log");
        fatal_error( "bbSim_file_tree script not run properly please check -bbSim argument.\n" );
        exit;
    }
    my $path = $opt_bbsim_p4;
    $path =~ s/bbSim\/.*//g;
    foreach my $filter_list ( @p4list ){
        if($filter_list =~ /\.\.\//) {
            $filter_list =~ s/\.\.\///g;
            @split_filter = split /\s/, $filter_list;
            dprint(MEDIUM, "$split_filter[-1]\n" );
            push(@p4list_names, $split_filter[-1] );
        }
    }
#    my @write_autosmoke = ();
    my ($exitvalue, $exitstatus,$status);
    dprint(LOW, "your current working dir is '" . getcwd() . "'\n");
    dprint(LOW, "Your P4CLIENT env var is '" . $ENV{'P4CLIENT'} . "'\n") if ( exists $ENV{'P4CLIENT'} );
    foreach my $p4files (@p4list_names) {
        my $pfile = "../$p4files";
        iprint("Checking '$p4files':\n" ); #s
        ($exitvalue, $exitstatus,$status) = capture { run_system_cmd("p4 opened -a $pfile", $VERBOSITY);  };
        chop $status;
        logger"-I- p4 status:$status.\n";
        my $p4_headModTime;
        ($exitvalue, $exitstatus, $p4_headModTime) = capture { run_system_cmd("p4 fstat -T headModTime $pfile", $VERBOSITY);  };
        $p4_headModTime = trim($p4_headModTime);
        if($p4_headModTime =~ /... headModTime/) {
            logger "-I- File exists in perforce.\n";
            $p4_headModTime =~ s/[^0-9]//g;
            my $ptime;
            ($exitvalue, $exitstatus, $ptime) = capture { run_system_cmd("date --date \@$p4_headModTime", $VERBOSITY);  };
            chomp $ptime;
            logger "-I- Timestamp: '$ptime'\n";
        } else {
            dprint(LOW, "exitvalue='$exitvalue' exitstatus='$exitstatus' headModTime='$p4_headModTime'\n");
            eprint "File not found in perforce. Please check again->\t '$pfile' \n";
            nprint "################################################################################\n\n";
            next;
        }
        my $filearr;
        ($exitvalue, $exitstatus, $filearr) = capture { run_system_cmd("p4 print -q $pfile", $VERBOSITY);  };
        my @filearray   = split /\n/, $filearr;
        if($p4files ne "") {
            my $lfile = "$opt_localpath/$p4files";
            if($p4files =~ /\.bbSim$/i) {
                unless( -e "$lfile" ){
                    eprint("bbsim file not found:\n\t '$lfile'.\n" ); 
                }
            }            
            if( -e "$lfile" ) {
                chomp $lfile;
                my @lines = read_file("$lfile");
                iprint( "File present locally. Find path at $lfile\n" );#s
                my $ltime = localtime((stat($lfile))[9]);
                logger "-I- Timestamp: '$ltime'\n";
                my ($common, $first, $second, $bool_lists_equiv) = compare_lists(\@filearray,\@lines);
                my @firstonly = @$first;
                my @secondonly = @$second;
                my @common = @$common;
                if(scalar @firstonly == 0 && scalar @secondonly == 0) {
                    iprint( "P4 and local file is identical.\n" );#s
                    nprint "################################################################################\n\n";
                } else {
                    eprint("P4 and local file are different.\n");
                    logger "-E- extra lines in local file: @secondonly\n" if (scalar @secondonly ne 0);
                    logger "-E- missing lines in local file: @firstonly\n" if (scalar @firstonly ne 0);
                    nprint "################################################################################\n\n";
                }
#                my $diff = Array::Diff->diff(\@filearray, \@lines);
#                my $count = $diff->count;
#                my $added = $diff->added;
#                my $deleted = $diff->deleted;
#                if( $count ne 0 ) {
#                    my $msg = "Error:P4 and local file are different.\n";
#                       $msg .= "extra lines in local file: @{$added}\n" if (scalar @{$added} ne 0);
#                       $msg .= "missing lines in local file: @{$deleted}\n" if (scalar @{$deleted} ne 0);
#                    eprint( $msg );
#                    iprint "################################################################################\n\n";
#                } else {
#                    iprint( "P4 and local file is identical.\n" );
#                    nprint "################################################################################\n\n";
#                }
            } else {
                eprint( "File does not exist in local area:\t '$lfile' \n" );
                nprint "################################################################################\n\n";
            }
        }
    }
        dprint(LOW, "write_stdout_log " . getcwd() . "/autosmoke.log");
    write_stdout_log("autosmoke.log");
    unlink "file_tree.log";
} # End MAIN

sub process_cmd_line_args() {
    ## get specified args
    my( $opt_dryrun,    $opt_nousage,   $opt_help,  $opt_debug,  
        $opt_verbosity, $opt_localpath, $opt_bbsim, $opt_p4ws);

    my $success = GetOptions(
       "help!"       => \$opt_help,
       "p4ws=s"      => \$opt_p4ws,
       "localpath=s" => \$opt_localpath,
       "dryrun!"     => \$opt_dryrun,
       "bbsim=s"     => \$opt_bbsim,
       "nousage"     => \$opt_nousage,
       "debug=i"     => \$opt_debug,
       "verbosity=i" => \$opt_verbosity,
    );

    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    $main::TESTMODE  = 1              if( defined $opt_dryrun    );

    ## quit with usage message, if usage not satisfied
    &usage(0) if $opt_help;
    &usage(1) unless( $success );
    &usage(0) unless( defined $opt_bbsim );

    return( $opt_nousage, $opt_localpath, $opt_bbsim );
}


1;
